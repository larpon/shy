// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module log

import term
import strings

const label_info = 'INFO'
const label_warn = 'WARN'
const label_error = 'ERROR'
const label_notice = 'NOTICE'
const label_debug = 'DEBUG'
const label_critical = 'CRITICAL'
const default_flags = get_default_flags_workaround()

// TODO: WORKAROUND
@[markused]
fn todo_() {
	_ := default_flags
}

fn get_default_flags_workaround() Flag {
	return $if prod {
		Flag.log | .std_err | .error | .critical | .custom
	} $else {
		Flag.log | .std_err | .info | .notice | .warn | .error | .critical | .custom
	}
}

@[flag]
pub enum Flag {
	log // On / off switch
	// Outputs
	std_err
	std_out
	buffer // Exposed buffer
	// Log categories
	info
	warn
	error
	notice
	debug
	critical
	//
	custom
	// Flood control
	flood
}

fn (lf Flag) clean_str() string {
	return lf.str().all_after('{.').trim_right('}')
}

// Log makes it possible to categorize and color log entries
pub struct Log {
mut:
	flags  Flag            = default_flags
	buffer strings.Builder = strings.new_builder(4096)
}

pub fn (l &Log) buffer() string {
	return l.buffer.after(0)
}

fn no_color_fn(msg string) string {
	return msg
}

// TODO: use shy colors?
pub fn (l &Log) colorize(color string, msg string) string {
	mut colorized_msg := ''
	$if wasm32_emscripten {
		colorized_msg = msg
	} $else {
		mut cfn := no_color_fn
		cfn = match color {
			'red' {
				term.red
			}
			'bright_red' {
				term.bright_red
			}
			'blue' {
				term.blue
			}
			'yellow' {
				term.yellow
			}
			'green' {
				term.green
			}
			'white' {
				term.white
			}
			'bright_magenta' {
				term.bright_magenta
			}
			else {
				no_color_fn
			}
		}
		colorized_msg = term.colorize(cfn, msg)
	}
	return colorized_msg
}

pub fn (l &Log) print_status(prefix string) {
	l.redirect(l.colorize('blue', prefix + ' ') + l.colorize('white', 'Log.flags ') +
		l.status_string())
}

pub fn (l &Log) status_string() string {
	return l.flags.clean_str().replace('.', '')
}

fn (l &Log) redirect(str string) {
	if !l.flags.has(.log) {
		return
	}
	l.force_redirect(str)
}

fn (l &Log) force_redirect(str string) {
	if l.has(.std_err) {
		eprintln(str)
	}
	if l.has(.std_out) {
		println(str)
	}
}

pub fn (l &Log) all(flags Flag) bool {
	return l.flags.all(flags)
}

pub fn (l &Log) has(flags Flag) bool {
	return l.flags.has(flags)
}

pub fn (l &Log) set(flags Flag) {
	unsafe { l.flags.set(flags) }
}

pub fn (l &Log) clear_and_set(flags Flag) {
	unsafe {
		l.flags = Flag(0) // clear all flags
		l.flags.set(flags)
	}
}

pub fn (l &Log) on(flag Flag) {
	if !l.has(flag) {
		unsafe { l.flags.set(flag) }
		l.debug(flag.clean_str() + '${l.changes(flag)}')
	}
}

pub fn (l &Log) off(flag Flag) {
	if l.has(flag) {
		unsafe { l.flags.clear(flag) }
		if flag == .log {
			// A last goodbye
			maybe_colored := l.colorize('bright_magenta', 'DEBUG ')
			l.force_redirect(maybe_colored + flag.clean_str() + ' off')
		} else {
			l.debug(flag.clean_str() + '${l.changes(flag)}')
		}
	}
}

pub fn (l &Log) toggle(flag Flag) {
	unsafe { l.flags.toggle(flag) }
	l.debug(flag.clean_str() + '${l.changes(flag)}')
}

fn (l &Log) changes(flag Flag) string {
	if l.flags.has(.log) {
		return if l.has(flag) { ' on' } else { ' off' }
	}
	return ''
}

//

@[if !shy_no_log ?]
pub fn (l &Log) custom(id string, str string) {
	if l.flags.has(.custom) {
		if l.flags.has(.buffer) {
			unsafe {
				l.buffer.writeln(id + ' ' + str)
			}
		}
		maybe_colored := l.colorize('blue', id + ' ')
		l.redirect(maybe_colored + str)
	}
}

@[if !shy_no_log ?]
pub fn (l &Log) info(str string) {
	if l.flags.has(.info) {
		if l.flags.has(.buffer) {
			unsafe {
				l.buffer.writeln(label_info + ' ' + str)
			}
		}
		maybe_colored := l.colorize('blue', label_info + ' ')
		l.redirect(maybe_colored + str)
	}
}

@[if !shy_no_log ?]
pub fn (l &Log) warn(str string) {
	if l.flags.has(.warn) {
		if l.flags.has(.buffer) {
			unsafe {
				l.buffer.writeln(label_warn + ' ' + str)
			}
		}
		maybe_colored := l.colorize('yellow', label_warn + ' ')
		l.redirect(maybe_colored + str)
	}
}

@[if !shy_no_log ?]
pub fn (l &Log) error(str string) {
	if l.flags.has(.error) {
		if l.flags.has(.buffer) {
			unsafe {
				l.buffer.writeln(label_error + ' ' + str)
			}
		}
		maybe_colored := l.colorize('bright_red', label_error + ' ')
		l.redirect(maybe_colored + str)
	}
}

@[if !shy_no_log ?]
pub fn (l &Log) critical(str string) {
	if l.flags.has(.critical) {
		if l.flags.has(.buffer) {
			unsafe {
				l.buffer.writeln(label_critical + ' ' + str)
			}
		}
		maybe_colored := l.colorize('red', label_critical + ' ')
		l.redirect(maybe_colored + str)
	}
}

@[if !shy_no_log ?]
pub fn (l &Log) notice(str string) {
	if l.flags.has(.notice) {
		if l.flags.has(.buffer) {
			unsafe {
				l.buffer.writeln(label_notice + ' ' + str)
			}
		}
		maybe_colored := l.colorize('bright_magenta', label_notice + ' ')
		l.redirect(maybe_colored + str)
	}
}

@[if debug && !shy_no_log ?]
pub fn (l &Log) debug(str string) {
	if l.flags.has(.debug) {
		if l.flags.has(.buffer) {
			unsafe {
				l.buffer.writeln(label_debug + ' ' + str)
			}
		}
		maybe_colored := l.colorize('bright_magenta', label_debug + ' ')
		l.redirect(maybe_colored + str)
	}
}

// Group

@[if !shy_no_log ?]
pub fn (l &Log) gcustom(id string, group string, str string) {
	if l.flags.has(.custom) {
		if l.flags.has(.buffer) {
			unsafe {
				l.buffer.writeln(id + ' ${group} ' + str)
			}
		}
		maybe_colored := l.colorize('blue', id + ' ') + l.colorize('white', '${group} ')
		l.redirect(maybe_colored + str)
	}
}

@[if !shy_no_log ?]
pub fn (l &Log) ginfo(group string, str string) {
	if l.flags.has(.info) {
		if l.flags.has(.buffer) {
			unsafe {
				l.buffer.writeln(label_info + ' ${group} ' + str)
			}
		}
		maybe_colored := l.colorize('blue', label_info + ' ') + l.colorize('white', '${group} ')
		l.redirect(maybe_colored + str)
	}
}

@[if !shy_no_log ?]
pub fn (l &Log) gwarn(group string, str string) {
	if l.flags.has(.warn) {
		if l.flags.has(.buffer) {
			unsafe {
				l.buffer.writeln(label_warn + ' ${group} ' + str)
			}
		}
		maybe_colored := l.colorize('yellow', label_warn + ' ') + l.colorize('white', '${group} ')
		l.redirect(maybe_colored + str)
	}
}

@[if !shy_no_log ?]
pub fn (l &Log) gerror(group string, str string) {
	if l.flags.has(.error) {
		if l.flags.has(.buffer) {
			unsafe {
				l.buffer.writeln(label_error + ' ${group} ' + str)
			}
		}
		maybe_colored := l.colorize('bright_red', label_error + ' ') +
			l.colorize('white', '${group} ')
		l.redirect(maybe_colored + str)
	}
}

@[if !shy_no_log ?]
pub fn (l &Log) gcritical(group string, str string) {
	if l.flags.has(.critical) {
		if l.flags.has(.buffer) {
			unsafe {
				l.buffer.writeln(label_critical + ' ${group} ' + str)
			}
		}
		maybe_colored := l.colorize('red', label_critical + ' ') + l.colorize('white', '${group} ')
		l.redirect(maybe_colored + str)
	}
}

@[if !shy_no_log ?]
pub fn (l &Log) gnotice(group string, str string) {
	if l.flags.has(.notice) {
		if l.flags.has(.buffer) {
			unsafe {
				l.buffer.writeln(label_notice + ' ${group} ' + str)
			}
		}
		maybe_colored := l.colorize('bright_magenta', label_notice + ' ') +
			l.colorize('white', '${group} ')
		l.redirect(maybe_colored + str)
	}
}

@[if debug && !shy_no_log ?]
pub fn (l &Log) gdebug(group string, str string) {
	if l.flags.has(.debug) {
		if l.flags.has(.buffer) {
			unsafe {
				l.buffer.writeln(label_debug + ' ${group} ' + str)
			}
		}
		maybe_colored := l.colorize('bright_magenta', label_debug + ' ') +
			l.colorize('white', '${group} ')
		l.redirect(maybe_colored + str)
	}
}

//
pub fn (l &Log) shutdown() ! {
	l.gdebug('${@STRUCT}.${@FN}', '')
	unsafe { l.buffer.free() }
}
