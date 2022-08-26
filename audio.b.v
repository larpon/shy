// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

import miniaudio as ma

pub struct Audio {
	ShyStruct // Implementation specific
mut:
	engines []Engine
}

// Implementation of public API

// init initializes the audio system.
pub fn (mut a Audio) init() ! {
	// Initialize default playback engine
	ma_engine := &ma.Engine{}
	// TODO with gc_boehm the following output:
	// GC Warning: Repeated allocation of very large block (appr. size 397312):
	//    May lead to memory leak and poor performance
	if ma.engine_init(ma.null, ma_engine) != .success {
		return error('failed to initialize audio engine')
	}
	a.engines << Engine{
		shy: a.shy
		e: ma_engine
	}
}

pub fn (mut a Audio) shutdown() ! {
	for mut engine in a.engines {
		engine.shutdown()!
	}
}

pub fn (a &Audio) load(id string, path string) ! {
	mut e := a.engine(0)
	s := e.load_file(path)!
	e.sounds[id] = s
}

pub fn (a &Audio) play(id string) {
	e := a.engine(0) // TODO
	if sound := e.sounds[id] {
		ma.sound_start(sound)
	}
}

pub fn (a &Audio) stop(id string) {
	e := a.engine(0) // TODO
	if sound := e.sounds[id] {
		ma.sound_stop(sound)
	}
}

// Internals

fn (a &Audio) engine(id u16) Engine {
	return a.engines[0]
}

// Internal representation of an engine
struct Engine {
	ShyStruct
	e &ma.Engine
mut:
	sounds map[string]&ma.Sound // sounds belonging to the ma.Engine instance.
}

fn (mut e Engine) shutdown() ! {
	for _, sound in e.sounds {
		ma.sound_uninit(sound)
	}
	ma.engine_uninit(e.e)
}

fn (e &Engine) load_file(path string) !&ma.Sound {
	sound := &ma.Sound{}
	if ma.sound_init_from_file(e.e, path.str, 0, ma.null, ma.null, sound) != .success {
		return error(@STRUCT + '.' + @FN + ' failed to load sound "$path"')
	}
	return sound
}
