// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import shy.wraps.miniaudio as ma
import v.embed_file

pub const max_audio_engine_instances = 255

pub struct Audio {
	ShyStruct
mut:
	// Implementation specific
	engine_id u8 // 256 audio engine instances must be enough, eh?!
	engines   map[u8]&AudioEngine
}

// Implementation of public API

// init initializes the audio system.
pub fn (mut a Audio) init() ! {
	a.shy.assert_api_init()
	a.shy.log.gdebug('${@STRUCT}.${@FN}', '')
	// Initialize default playback engine
	ma_engine := &ma.Engine{}
	// TODO with gc_boehm the following output:
	// GC Warning: Repeated allocation of very large block (appr. size 397312):
	//    May lead to memory leak and poor performance
	if ma.engine_init(ma.null, ma_engine) != .success {
		return error('failed to initialize audio engine')
	}
	a.engines[0] = &AudioEngine{
		shy: a.shy
		id: 0
		e: ma_engine
	}
}

pub fn (mut a Audio) new_engine() !&AudioEngine {
	a.shy.vet_issue(.warn, .hot_code, '${@STRUCT}.${@FN}', 'memory fragmentation can happen when allocating in hot code paths. It is, in general, better to pre-load data')
	if a.engine_id >= lib.max_audio_engine_instances - 1 {
		if a.engine_id == lib.max_audio_engine_instances - 1 {
			a.shy.log.gwarn('${@STRUCT}.${@FN}', 'creating last AudioEngine instance')
		} else {
			return error('the maximum amount of audio engines (${lib.max_audio_engine_instances}) is reached')
		}
	}
	ma_engine := &ma.Engine{}
	// TODO with gc_boehm the following output:
	// GC Warning: Repeated allocation of very large block (appr. size 397312):
	//    May lead to memory leak and poor performance
	if ma.engine_init(ma.null, ma_engine) != .success {
		return error('failed to initialize audio engine')
	}
	a.engine_id++
	engine := &AudioEngine{
		shy: a.shy
		id: a.engine_id
		e: ma_engine
	}
	a.engines[a.engine_id] = engine
	return engine
}

pub fn (mut a Audio) shutdown() ! {
	a.shy.assert_api_shutdown()
	a.shy.log.gdebug('${@STRUCT}.${@FN}', '')
	for _, mut engine in a.engines {
		engine.shutdown()!
	}
}

pub fn (a &Audio) engine(id u8) !&AudioEngine {
	return a.engines[id] or {
		return error('${@STRUCT}.${@FN}' + ': engine with id ${id} does not exist')
	}
}

// AudioEngine implementation

[heap]
pub struct AudioEngine {
	ShyStruct
	e &ma.Engine = null
pub:
	id u8
mut:
	sound_id u16
	sounds   map[u16]&ma.Sound   // sounds belonging to the ma.Engine instance.
	decoders map[u16]&ma.Decoder // sound decoders for sounds loaded from memory
}

pub fn (mut e AudioEngine) shutdown() ! {
	for _, sound in e.sounds {
		if !isnil(sound) {
			ma.sound_uninit(sound)
		}
	}
	e.sounds.clear()
	for _, decoder in e.decoders {
		if !isnil(decoder) {
			ma.decoder_uninit(decoder)
		}
	}
	e.decoders.clear()
	ma.engine_uninit(e.e)
}

// load loads an `AssetSource` with this `AudioEngine` and returns the ID of the sound.
pub fn (mut ae AudioEngine) load(source AssetSource) !u16 {
	ae.shy.vet_issue(.warn, .hot_code, '${@STRUCT}.${@FN}', 'memory fragmentation can happen when allocating in hot code paths. It is, in general, better to pre-load data.')
	ae.shy.log.gdebug('${@STRUCT}.${@FN}', 'loading "${source}"')
	s := match source {
		string {
			ae.load_file(source)!
		}
		embed_file.EmbedFileData {
			ae.load_bytes(source.to_bytes()) or {
				return error('${@STRUCT}.${@FN}: failed loading "${source}": ${err}')
			}
		}
	}
	ae.sound_id++
	ae.sounds[ae.sound_id] = s
	return ae.sound_id
}

fn (ae &AudioEngine) load_file(path string) !&ma.Sound {
	sound := &ma.Sound{}
	if ma.sound_init_from_file(ae.e, path.str, 0, ma.null, ma.null, sound) != .success {
		return error('${@STRUCT}.${@FN}: failed to load "${path}"')
	}
	return sound
}

fn (mut ae AudioEngine) load_bytes(bytes []u8) !&ma.Sound {
	sound := &ma.Sound{}

	decoder_config := ma.decoder_config_init(.f32, 2, 44100)
	// Init decoder
	decoder := &ma.Decoder{}
	if ma.decoder_init_memory(bytes.data, usize(bytes.len), &decoder_config, decoder) != .success {
		return error('${@STRUCT}.${@FN} failed to initialize decoder from memory data, maybe the format is not supported')
	}

	if ma.sound_init_from_data_source(ae.e, voidptr(decoder), 0, ma.null, sound) != .success {
		return error('${@STRUCT}.${@FN} failed to load sound from memory buffer')
	}
	// NOTE this is a bit hazardous since the sound id is handed out after this function
	ae.decoders[ae.sound_id + 1] = decoder
	return sound
}

// load_copies loads `copies` amount of copies of `path` into memory
// load_copies returns the ids of the firat and last copy loaded.
pub fn (mut ae AudioEngine) load_copies(source AssetSource, copies u8) !(u16, u16) {
	ae.shy.vet_issue(.warn, .hot_code, '${@STRUCT}.${@FN}', 'memory fragmentation can happen when allocating in hot code paths. It is, in general, better to pre-load data.')
	s := match source {
		string {
			ae.load_file(source)!
		}
		embed_file.EmbedFileData {
			ae.load_bytes(source.to_bytes()) or {
				return error('${@STRUCT}.${@FN}: failed loading "${source}": ${err}')
			}
		}
	}
	ae.sound_id++
	id_start := ae.sound_id
	ae.sounds[id_start] = s
	// See https://github.com/mackron/miniaudio/issues/517
	if copies > 1 {
		ae.shy.vet_issue(.warn, .misc, '${@STRUCT}.${@FN}', 'keep in mind that instancing the same sound (${source}) ${copies} times, also duplicate the memory for the sound ${copies} times')
		for _ in 0 .. copies {
			ae.shy.log.gdebug('${@STRUCT}.${@FN}', 'duplicating "${source}"')
			copy_sound := &ma.Sound{}
			ma.sound_init_copy(ae.e, s, 0, ma.null, copy_sound)
			ae.sound_id++
			ae.sounds[ae.sound_id] = copy_sound
		}
	}
	return id_start, ae.sound_id
}

pub fn (ae &AudioEngine) play(id u16) {
	sound_id := id
	if sound := ae.sounds[sound_id] {
		ae.shy.log.gdebug('${@STRUCT}.${@FN}', 'playing sound ${sound_id} via engine ${ae.id}')
		ma.sound_start(sound)
	}
}

pub fn (ae &AudioEngine) stop(id u16) {
	sound_id := id
	if sound := ae.sounds[sound_id] {
		ae.shy.log.gdebug('${@STRUCT}.${@FN}', 'stopping ${sound_id} in engine ${ae.id}')
		ma.sound_stop(sound)
	}
}

pub fn (ae &AudioEngine) is_playing(id u16) bool {
	sound_id := id
	if sound := ae.sounds[sound_id] {
		if ma.sound_is_playing(sound) == u32(ma.@true) {
			return true
		}
	}
	return false
}

pub fn (ae &AudioEngine) is_looping(id u16) bool {
	sound_id := id
	if sound := ae.sounds[sound_id] {
		if ma.sound_is_looping(sound) == u32(ma.@true) {
			return true
		}
	}
	return false
}

pub fn (ae &AudioEngine) set_looping(id u16, loop bool) {
	sound_id := id
	if sound := ae.sounds[sound_id] {
		ae.shy.log.gdebug('${@STRUCT}.${@FN}', 'set loop = ${loop} on sound ${sound_id} in engine ${ae.id}')
		b := if loop { ma.@true } else { ma.@false }
		ma.sound_set_looping(sound, u32(b))
	}
}

pub fn (ae &AudioEngine) set_pitch(id u16, pitch f32) {
	sound_id := id
	if sound := ae.sounds[sound_id] {
		ae.shy.log.gdebug('${@STRUCT}.${@FN}', 'set pitch = ${pitch:.3f} on sound ${sound_id} in engine ${ae.id}')
		ma.sound_set_pitch(sound, pitch)
	}
}

pub fn (ae &AudioEngine) set_master_volume(volume f32) {
	ma.engine_set_volume(ae.e, volume)
}

pub fn (ae &AudioEngine) set_volume(id u16, volume f32) {
	sound_id := id
	if sound := ae.sounds[sound_id] {
		ae.shy.log.gdebug('${@STRUCT}.${@FN}', 'set volume = ${volume:.3f} on sound ${sound_id} in engine ${ae.id}')
		ma.sound_set_volume(sound, volume)
	}
}

pub fn (ae &AudioEngine) seek_to_pcm_frame(id u16, frame u64) {
	sound_id := id
	if sound := ae.sounds[sound_id] {
		ae.shy.log.gdebug('${@STRUCT}.${@FN}', 'seek to PCM frame ${frame} on sound ${sound_id} in engine ${ae.id}')
		_ := ma.sound_seek_to_pcm_frame(sound, frame)
		// TODO check result?
	}
}

/*
pub fn (ae &AudioEngine) get_length(id u16) u64 {
	sound_id := id
	mut length := f32(0)
	if sound := ae.sounds[sound_id] {
		_ := ma.sound_get_length_in_seconds(sound, &length)
	}
	return length
}*/

pub fn (ae &AudioEngine) get_length_in_pcm_frames(id u16) u64 {
	sound_id := id
	mut length := u64(0)
	if sound := ae.sounds[sound_id] {
		_ := ma.sound_get_length_in_pcm_frames(sound, &length)
	}
	return length
}
