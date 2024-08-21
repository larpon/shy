// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module fetch

import runtime
import os
import sdl // TODO: only for loading asset paths on Android FIXME

const c_max_jobs = if $env('V_FETCH_MAX_JOBS') != '' { $env('V_FETCH_MAX_JOBS').u32() } else { 128 }
const c_max_threads = if $env('V_FETCH_MAX_THREADS') != '' {
	$env('V_FETCH_MAX_THREADS').u32()
} else {
	u32(max(runtime.nr_cpus() - 1, 1))
}

const c_chunk_size = u16(4 * 1024)

// const c_chunk_size = if $env('V_FETCH_CHUNK_SIZE') != '' {
// 	$env('V_FETCH_CHUNK_SIZE').u16()
// } else {
// 	u16(1024)
// }

@[flag]
pub enum LoadFlags {
	async
	stream
}

pub enum Status {
	unknown
	error
	running
	done
}

type Id = u32

pub struct Handle {
pub:
	id Id
}

// Loader can load binary data.
pub struct Loader {
mut:
	ids       u32
	job_count int
	job_queue []LoadJob
	ch_in     chan LoadJob
	ch_out    chan JobStatus
	threads   []thread = []thread{cap: int(fetch.c_max_threads)}
}

@[params]
pub struct LoadConfig {
pub:
	url   string
	flags LoadFlags = .async
}

pub struct Data {
pub:
	chunk [c_chunk_size]u8
	size  u16
}

struct LoadJob {
	id     u32
	config LoadConfig
}

struct JobStatus {
	id       u32
	progress f32
	status   Status
	data     Data
}

pub struct JobUpdate {
pub:
	id       u32
	progress f32
	status   Status
	data     Data
}

pub fn (mut l Loader) init() ! {
	// l.threads := []thread{cap: c_max_threads}
	for t in 0 .. fetch.c_max_threads {
		l.threads << spawn l.worker(t, l.ch_in, l.ch_out)
	}
}

pub fn (mut l Loader) shutdown() ! {
	l.ch_in.close()
	l.ch_out.close()
	l.threads.wait()
}

pub fn (mut l Loader) update() ?JobUpdate {
	// Send off workload to one of the worker threads
	for l.job_count < l.threads.len && l.job_queue.len > 0 {
		load_job := l.job_queue.pop()
		l.job_count++
		l.ch_in <- load_job
	}

	if l.job_count <= 0 {
		return none
	}
	// Try a pop from the channel
	mut job_status := JobStatus{}
	if l.ch_out.try_pop(mut job_status) == .success {
		// println('Job #${job_status.id} progress ${job_status.progress * 100}% status ${job_status.status}')
		if job_status.status == .done {
			l.job_count--
		}
		return JobUpdate{
			id:       job_status.id
			progress: job_status.progress
			status:   job_status.status
			data:     job_status.data
		}
	}
	return none
}

pub fn (mut l Loader) load(config LoadConfig) Handle {
	l.ids++
	l.job_queue << LoadJob{
		id:     l.ids
		config: config
	}
	return Handle{
		id: Id(l.ids)
	}
}

pub fn (l &Loader) workers() int {
	return l.threads.len
}

pub fn (l &Loader) queue() int {
	return l.job_queue.len
}

pub fn (l &Loader) jobs() int {
	return l.job_count
}

pub fn (l &Loader) is_working() bool {
	return l.job_count > 0 || l.job_queue.len > 0
}

pub fn (l &Loader) is_idle() bool {
	return l.job_count == 0 && l.job_queue.len == 0
}

fn (mut l Loader) worker(thread_id int, ch_in chan LoadJob, ch_out chan JobStatus) {
	for {
		job := <-ch_in or { break }

		url := job.config.url
		// println('Loader #${thread_id} worker took ${url}')
		mut bytes := []u8{}
		// TODO enable network fetching etc.
		source := url.all_after('://')
		if url.starts_with('file://') {
			$if android && !termux {
				if !source.starts_with('/') {
					bytes = sdl_read_bytes_from_apk(source) or {
						ch_out <- JobStatus{
							id:       job.id
							progress: 0
							status:   .error
						}
						println('ERROR Loader #${thread_id} ${url} error reading Android APK/AAB file')
						break
					}
				} else {
					ch_out <- JobStatus{
						id:       job.id
						progress: 0
						status:   .error
					}
					println('ERROR Loader #${thread_id} ${url} error reading file. Paths should be *relative* when loaded from an Android APK/AAB, "${source}" is not')
					break
				}
			} $else {
				if !os.is_file(source) {
					ch_out <- JobStatus{
						id:       job.id
						progress: 0
						status:   .error
					}
					println('ERROR Loader #${thread_id} ${url} is not as file')
					break
					// return error('${@STRUCT}.${@FN}: "${source}" does not exist on the file system')
				}
				bytes = os.read_bytes(source) or {
					ch_out <- JobStatus{
						id:       job.id
						progress: 0
						status:   .error
					}
					println('ERROR Loader #${thread_id} ${url} error reading file')
					break
					// return error('${@STRUCT}.${@FN}: "${source}" could not be loaded')
				}
			}

			bytes_total := bytes.len
			mut bytes_sent := 0
			for bytes_sent < bytes_total {
				mut chunk := [fetch.c_chunk_size]u8{}
				mut size := u16(0)
				mut one_byte := bytes[bytes_sent]
				for i := 0; i < fetch.c_chunk_size; i++ {
					chunk[i] = one_byte
					size++
					bytes_sent++
					if bytes_sent < bytes_total {
						one_byte = bytes[bytes_sent]
					} else {
						break
					}
				}

				if bytes_sent == bytes_total {
					// println('Loader #${thread_id} sending DONE data ${url}')
					ch_out <- JobStatus{
						id:       job.id
						progress: 1
						status:   .done
						data:     Data{
							chunk: chunk
							size:  size
						}
					}
					unsafe { bytes.free() } // TODO -autofree ??
					break
				}
				// println('Loader #${thread_id} sending data ${url}')
				ch_out <- JobStatus{
					id:       job.id
					progress: f32(bytes_sent) / f32(bytes_total)
					status:   .running
					data:     Data{
						chunk: chunk
						size:  size
					}
				}
			}
		} else {
			println('ERROR Loader #${thread_id} ${url} error something')
			ch_out <- JobStatus{
				id:       job.id
				progress: 0
				status:   .error
			}
		}

		/*
		for i in 0 .. 100 {
			ch_out <- JobStatus{
				id: job.id
				progress: f32(i)/100
				status: .running
			}
			time.sleep(100 * time.millisecond)
		}*/

		/*
		ch_out <- JobStatus{
			id: job.id
			progress: 1
			status: .done
		}*/
	}
}

// Helpers

fn max(x int, y int) int {
	if x > y {
		return x
	}
	return y
}

// TODO: FIXME
fn sdl_read_bytes_from_apk(source string) ![]u8 {
	$if android && !termux {
		// TODO: FIXME, this is a little messy
		rw := sdl.rw_from_file(source.str, 'rb'.str)
		if rw == sdl.null {
			error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
			return error('${@FN}:${@LINE}: "${source}" could not be opened via sdl.rw_from_file. SDL2 says: ${error_msg}')
		}
		len := rw.size()
		if len < 0 {
			error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
			return error('${@FN}:${@LINE}: size of "${source}" could not be read via rw.size(). SDL2 says: ${error_msg}')
		}
		mut bytes := []u8{len: int(len)}
		// just read everything it in one go for now
		chunks_per_read := len
		max_chunks_to_be_read := 1
		mut total_chunks_read := 0
		for {
			chunks_read := rw.read(bytes.data, usize(chunks_per_read), usize(max_chunks_to_be_read))
			total_chunks_read += int(chunks_read)
			if chunks_read <= 0 {
				break
			}
		}
		// NOTE: the rw.read function return 0 both on error and EOF...
		if total_chunks_read == 0 {
			error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
			return error('${@FN}:${@LINE}: "${source}" failed reading via rw.read. SDL2 says: ${error_msg}')
		}
		rw.close()
		return bytes
	}
	return error('${@FN}:${@LINE}: "${source}" failed reading. ${@FN} only works on Android, with sdl and only with apk/aab packages.')
}
