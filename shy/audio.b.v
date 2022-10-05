// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

import libs.miniaudio as ma

pub struct Audio {
	ShyStruct
mut:
	// Implementation specific
	engine_id u8
	engines   map[u8]&AudioEngine
}

// Implementation of public API

// init initializes the audio system.
pub fn (mut a Audio) init() ! {
	a.shy.assert_api_init()
	a.shy.log.gdebug('${@STRUCT}.${@FN}', 'hi')
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
	a.shy.log.gdebug('${@STRUCT}.${@FN}', 'bye')
	for _, mut engine in a.engines {
		engine.shutdown()!
	}
}

pub fn (a &Audio) engine(id u8) !&AudioEngine {
	return a.engines[id] or {
		return error('${@STRUCT}.${@FN}' + ': engine with id $id does not exist')
	}
}

// AudioEngine implementation

[heap]
pub struct AudioEngine {
	ShyStruct
	id u8
	e  &ma.Engine = null
mut:
	sound_id u16
	sounds   map[u16]&ma.Sound // sounds belonging to the ma.Engine instance.
}

pub fn (mut e AudioEngine) shutdown() ! {
	for _, sound in e.sounds {
		ma.sound_uninit(sound)
	}
	ma.engine_uninit(e.e)
}

fn (ae &AudioEngine) load_file(path string) !&ma.Sound {
	sound := &ma.Sound{}
	if ma.sound_init_from_file(ae.e, path.str, 0, ma.null, ma.null, sound) != .success {
		return error('${@STRUCT}.${@FN}' + ' failed to load sound "$path"')
	}
	return sound
}

pub fn (mut ae AudioEngine) load(path string) !u16 {
	ae.shy.vet_issue(.warn, .hot_code, '${@STRUCT}.${@FN}', 'memory fragmentation can happen when allocating in hot code paths. It is, in general, better to pre-load data.')
	ae.shy.log.gdebug('${@STRUCT}.${@FN}', 'loading "$path"')
	s := ae.load_file(path)!
	ae.sound_id++
	ae.sounds[ae.sound_id] = s
	return ae.sound_id
}

pub fn (mut ae AudioEngine) load_copies(path string, copies u8) !(u16, u16) {
	ae.shy.vet_issue(.warn, .hot_code, '${@STRUCT}.${@FN}', 'memory fragmentation can happen when allocating in hot code paths. It is, in general, better to pre-load data.')
	// See https://github.com/mackron/miniaudio/issues/517
	s := ae.load_file(path)!
	ae.sound_id++
	id_start := ae.sound_id
	ae.sounds[id_start] = s
	if copies > 1 {
		ae.shy.vet_issue(.warn, .misc, '${@STRUCT}.${@FN}', 'keep in mind that instancing the same sound ($path) $copies times, also duplicate the memory for the sound $copies times')
		for _ in 0 .. copies {
			ae.shy.log.gdebug('${@STRUCT}.${@FN}', 'duplicating "$path"')
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
		ae.shy.log.gdebug('${@STRUCT}.${@FN}', 'playing sound $sound_id via engine $ae.id')
		ma.sound_start(sound)
	}
}

pub fn (ae &AudioEngine) stop(id u16) {
	sound_id := id
	if sound := ae.sounds[sound_id] {
		ae.shy.log.gdebug('${@STRUCT}.${@FN}', 'stopping $sound_id in engine $ae.id')
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
		ae.shy.log.gdebug('${@STRUCT}.${@FN}', 'set loop = $loop on sound $sound_id in engine $ae.id')
		b := if loop { ma.@true } else { ma.@false }
		ma.sound_set_looping(sound, u32(b))
	}
}
