// Copyright(C) 2021-2022 Lars Pontoppidan. All rights reserved.
import shy.wraps.vmon
import os
import time

fn watch_callback(watch_id vmon.WatchID, action vmon.Action, root_path string, file_path string, old_file_path string, user_data voidptr) {
	// Don't cast and use if user_data is null
	// This is only needed since we use the same
	// watch_callback for multiple watchers
	if !isnil(user_data) {
		mut ts := unsafe { &TestStruct(user_data) }
		ts.i++
		println('${ts}'.replace('\n', ' ').replace('    ', '')) // flatten output
	}

	base_msg := 'Watcher id ${watch_id} in "${root_path}" got ${action} event'
	match action {
		.create {
			println('${base_msg} "${file_path}"')
		}
		.delete {
			println('${base_msg} "${file_path}"')
		}
		.modify {
			println('${base_msg} "${file_path}"')
		}
		.move {
			println('${base_msg} "${old_file_path}" to "${file_path}"')
		}
	}
}

struct TestStruct {
mut:
	i int
}

fn test_watch_and_unwatch() {
	flags := u32(vmon.WatchFlag.recursive) | u32(vmon.WatchFlag.follow_symlinks)

	mut ts := &TestStruct{}

	path := os.join_path(os.temp_dir(), 'watch_test')
	path2 := os.join_path(path, '2')
	path3_base := os.join_path(path, '3')
	path3 := os.join_path(path3_base, '4', '5', '6', '7')
	path_src := os.join_path(path, 'test')
	path_dst := os.join_path(path, 'test_test')

	fpath_src := os.join_path(path2, 'ftest')
	fpath_dst := os.join_path(path2, 'ftest_test')

	os.rmdir_all(path) or {}
	os.mkdir_all(path2) or {}
	vmon.watch(path, watch_callback, flags, ts) or { panic(err) }
	// time.sleep(25 * time.millisecond)

	// os.rm(path_src) or { panic(err) }

	mut f := os.create(path_src) or { panic(err) }
	f.close()
	time.sleep(25 * time.millisecond)

	// TODO new dirs goes unnoticed in the C code
	os.mkdir(os.join_path(path, 'dir')) or { panic(err) }

	// println(os.ls(path) or { []string{} })

	f = os.create(fpath_src) or { panic(err) }
	f.close()
	time.sleep(25 * time.millisecond)

	os.mv(fpath_src, fpath_dst) or { panic(err) }
	time.sleep(25 * time.millisecond)

	os.mv(path_src, path_dst) or { panic(err) }
	time.sleep(25 * time.millisecond)

	os.mv(path_dst, path_src) or { panic(err) }
	time.sleep(25 * time.millisecond)

	os.rm(path_src) or { panic(err) }
	time.sleep(25 * time.millisecond)

	os.mkdir(path_src) or { panic(err) }
	// time.sleep(25 * time.millisecond)
	// println('os.create( $path_src + test )')
	f = os.create(os.join_path(path_src, 'test')) or { panic(err) }
	f.close()
	time.sleep(25 * time.millisecond)

	os.mkdir_all(path3) or {}
	path3_watch_id := vmon.watch(path3, watch_callback, flags, unsafe { nil }) or { panic(err) }
	time.sleep(25 * time.millisecond)

	f = os.create(os.join_path(path3, 'test')) or { panic(err) }
	f.close()
	time.sleep(25 * time.millisecond)

	vmon.unwatch(path3_watch_id)

	// This produces a panic since the dir doesn't exist when the thread finally calls the callback
	// vmon.watch(os.join_path(path3,'test'), watch_callback, flags, voidptr(0)) or { panic(err) }

	vmon.watch(path3, watch_callback, flags, unsafe { nil }) or { panic(err) }

	os.rmdir_all(path3_base) or { panic(err) }

	time.sleep(250 * time.millisecond)
	unsafe {
		free(ts)
	}
}
