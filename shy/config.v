// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

import os
import toml

pub const (
	defaults = Defaults{}
)

struct Defaults {
pub:
	render struct  {
	pub:
		update_rate         f64 = 60.0
		update_multiplicity u8  = 1
		lock_framerate      bool
		time_history_count  u8 = 4
		vsync               VSync
		msaa                int = 4
	}

	fonts struct  {
	pub:
		preallocate u8 = 4
	}

	font struct  {
	pub:
		name string = 'default'
		size f32    = 20
		// align TextAlign = .baseline | .left // TODO V BUG
	}

	audio struct  {
	pub:
		engines u8 = 1
	}

	input struct  {
	pub:
		mice bool = false // Support multiple mouse input devices
	}

	window struct  {
	pub:
		title     string = 'Shy Window'
		resizable bool   = true // Root window is resizable, can be toggled at run time
		color     Color  = Color{0, 0, 0, 255} // Default background color of the root window
	}
}

/*
const (
	const_default_config_text = $embed_file('shy.default.config.toml', .zlib).to_string()
	const_default_config = config_from_toml_text(shy.const_default_config_text) or { Config{} }
)
*/
pub enum VSync {
	on
	off
	adaptive
}

fn vsynctype_from_string(str string) VSync {
	return match str {
		'on' { .on }
		'off' { .off }
		'adaptive' { .adaptive }
		else { .on }
	}
}

[params]
pub struct Config {
	debug  bool
	window WindowConfig
	render RenderConfig
	input  InputConfig
}

[params]
pub struct WindowConfig {
	Rect
pub:
	title     string = shy.defaults.window.title
	resizable bool   = shy.defaults.window.resizable
	visible   bool   = true
	color     Color  = shy.defaults.window.color
	// TODO ? flags WindowFlag
	render RenderConfig
}

pub struct RenderConfig {
	update_rate         f64   = shy.defaults.render.update_rate
	update_multiplicity u8    = shy.defaults.render.update_multiplicity
	lock_framerate      bool  = shy.defaults.render.lock_framerate
	time_history_count  u8    = shy.defaults.render.time_history_count
	vsync               VSync = shy.defaults.render.vsync
	msaa                int   = shy.defaults.render.msaa
}

pub struct InputConfig {
	mice bool = shy.defaults.input.mice
}

pub fn config_from_toml_file(path string) ?Config {
	toml_text := os.read_file(path) or {
		return error(@MOD + '.' + @FN + ' Could not read "$path": "$err.msg()"')
	}
	return config_from_toml_text(toml_text)
}

pub fn config_from_toml_text(toml_text string) ?Config {
	toml_doc := toml.parse_text(toml_text)?
	toml_wc := toml_doc.value('shy.window')
	//
	toml_rend_c := toml_doc.value('shy.render')
	rend_c := RenderConfig{
		update_rate: toml_rend_c.value('update_rate').default_to(shy.defaults.render.update_rate).f64()
		update_multiplicity: u8(toml_rend_c.value('update_multiplicity').default_to(int(shy.defaults.render.update_multiplicity)).int())
		lock_framerate: toml_rend_c.value('lock_framerate').default_to(shy.defaults.render.lock_framerate).bool()
		time_history_count: u8(toml_rend_c.value('time_history_count').default_to(int(shy.defaults.render.time_history_count)).int())
		vsync: vsynctype_from_string(toml_rend_c.value('vsync').default_to('on').string())
		msaa: toml_rend_c.value('msaa').default_to(shy.defaults.render.msaa).int()
	}
	wc := WindowConfig{
		title: toml_wc.value('title').default_to(shy.defaults.window.title).string()
		resizable: toml_wc.value('resizable').default_to(shy.defaults.window.resizable).bool()
		render: rend_c
	}
	//
	toml_input_c := toml_doc.value('shy.input')
	input_c := InputConfig{
		mice: toml_input_c.value('mice').default_to(shy.defaults.input.mice).bool()
	}

	return Config{
		input: input_c
		render: rend_c
		window: wc
	}
}
