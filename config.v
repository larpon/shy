// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

import os
import toml

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
	run    RunConfig
}

pub struct WindowConfig {
	title     string = 'Shy window'
	resizable bool   = true
	color     Color  = Color{0, 0, 0, 255}
}

pub struct RunConfig {
	update_rate         f64 = 60.0
	update_multiplicity u16 = 1
	lock_framerate      bool
	time_history_count  u16 = 4
}

pub struct RenderConfig {
	vsync VSync
	msaa  int = 4
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
	wc := WindowConfig{
		title: toml_wc.value('title').default_to('Shy window').string()
	}
	//
	toml_rc := toml_doc.value('shy.run')
	rc := RunConfig{
		update_rate: toml_rc.value('update_rate').default_to(60.0).f64()
		update_multiplicity: u16(toml_rc.value('update_multiplicity').default_to(1).int())
		lock_framerate: toml_rc.value('lock_framerate').default_to(false).bool()
		time_history_count: u16(toml_rc.value('time_history_count').default_to(4).int())
	}
	//
	toml_rend_c := toml_doc.value('shy.render')
	rend_c := RenderConfig{
		vsync: vsynctype_from_string(toml_rend_c.value('vsync').default_to('on').string())
		msaa: toml_rend_c.value('msaa').default_to(4).int()
	}
	return Config{
		run: rc
		render: rend_c
		window: wc
	}
}
