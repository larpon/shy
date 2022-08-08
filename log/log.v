// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module log

import term
import strings

const (
	label_info     = 'INFO'
	label_warn     = 'WARN'
	label_error    = 'ERROR'
	label_debug    = 'DEBUG'
	label_critical = 'CRITICAL'
	default_flags  = $if prod {
		Flag.log | .std_err | .error | .critical
	} $else {
		Flag.log | .std_err | .info | .warn | .error | .critical
	}
)

[flag]
pub enum Flag {
	log // On / off switch
	// Outputs
	std_err
	std_out
	buffer // Exposed buffer
	// User log categories
	info
	warn
	error
	debug
	critical
	// Flood control
	flood
}

fn (lf Flag) clean_str() string {
	return lf.str().all_after('{.').trim_right('}')
}

// Log makes it possible to categorize and color log entries
pub struct Log {
mut:
	flags  Flag = log.default_flags
	buffer strings.Builder = strings.new_builder(4096)
}

pub fn (l Log) buffer() string {
	return l.buffer.after(0)
}

pub fn (l Log) print_status(prefix string) {
	l.redirect(term.colorize(term.blue, prefix + ' ') +
		term.colorize(term.white, 'solid.Log.flags ') + l.status_string())
}

pub fn (l Log) status_string() string {
	return l.flags.clean_str().replace('.', '')
}

fn (l Log) redirect(str string) {
	if !l.flags.has(.log) {
		return
	}
	l.force_redirect(str)
}

fn (l Log) force_redirect(str string) {
	if l.has(.std_err) {
		eprintln(str)
	}
	if l.has(.std_out) {
		println(str)
	}
}

pub fn (l Log) all(flags Flag) bool {
	return l.flags.all(flags)
}

pub fn (l Log) has(flags Flag) bool {
	return l.flags.has(flags)
}

pub fn (mut l Log) set(flags Flag) {
	l.flags.set(flags)
}

pub fn (mut l Log) clear_and_set(flags Flag) {
	l.flags = Flag(0) // clear all flags
	l.flags.set(flags)
}

pub fn (mut l Log) on(flag Flag) {
	if !l.has(flag) {
		l.flags.set(flag)
		l.debug(flag.clean_str() + '${l.changes(flag)}')
	}
}

pub fn (mut l Log) off(flag Flag) {
	if l.has(flag) {
		l.flags.clear(flag)
		if flag == .log {
			// A last goodbye
			l.force_redirect(term.bright_magenta('DEBUG ') + flag.clean_str() + ' off')
		} else {
			l.debug(flag.clean_str() + '${l.changes(flag)}')
		}
	}
}

pub fn (mut l Log) toggle(flag Flag) {
	l.flags.toggle(flag)
	l.debug(flag.clean_str() + '${l.changes(flag)}')
}

fn (l Log) changes(flag Flag) string {
	if l.flags.has(.log) {
		return if l.has(flag) { ' on' } else { ' off' }
	}
	return ''
}

//

[if !no_log ?]
pub fn (mut l Log) info(str string) {
	if l.flags.has(.info) {
		if l.flags.has(.buffer) {
			l.buffer.writeln(log.label_info + ' ' + str)
		}
		maybe_colored := term.colorize(term.blue, log.label_info + ' ')
		l.redirect(maybe_colored + str)
	}
}

[if !no_log ?]
pub fn (mut l Log) warn(str string) {
	if l.flags.has(.warn) {
		if l.flags.has(.buffer) {
			l.buffer.writeln(log.label_warn + ' ' + str)
		}
		maybe_colored := term.colorize(term.yellow, log.label_warn + ' ')
		l.redirect(maybe_colored + str)
	}
}

[if !no_log ?]
pub fn (mut l Log) error(str string) {
	if l.flags.has(.error) {
		if l.flags.has(.buffer) {
			l.buffer.writeln(log.label_error + ' ' + str)
		}
		maybe_colored := term.colorize(term.bright_red, log.label_error + ' ')
		l.redirect(maybe_colored + str)
	}
}

[if !no_log ?]
pub fn (mut l Log) critical(str string) {
	if l.flags.has(.critical) {
		if l.flags.has(.buffer) {
			l.buffer.writeln(log.label_critical + ' ' + str)
		}
		maybe_colored := term.colorize(term.red, log.label_critical + ' ')
		l.redirect(maybe_colored + str)
	}
}

[if debug && !no_log ?]
pub fn (mut l Log) debug(str string) {
	if l.flags.has(.debug) {
		if l.flags.has(.buffer) {
			l.buffer.writeln(log.label_debug + ' ' + str)
		}
		maybe_colored := term.colorize(term.bright_magenta, log.label_debug + ' ')
		l.redirect(maybe_colored + str)
	}
}

// Group

[if !no_log ?]
pub fn (mut l Log) ginfo(group string, str string) {
	if l.flags.has(.info) {
		if l.flags.has(.buffer) {
			l.buffer.writeln(log.label_info + ' $group ' + str)
		}
		maybe_colored := term.colorize(term.blue, log.label_info + ' ') +
			term.colorize(term.white, '$group ')
		l.redirect(maybe_colored + str)
	}
}

[if !no_log ?]
pub fn (mut l Log) gwarn(group string, str string) {
	if l.flags.has(.warn) {
		if l.flags.has(.buffer) {
			l.buffer.writeln(log.label_warn + ' $group ' + str)
		}
		maybe_colored := term.colorize(term.yellow, log.label_warn + ' ') +
			term.colorize(term.white, '$group ')
		l.redirect(maybe_colored + str)
	}
}

[if !no_log ?]
pub fn (mut l Log) gerror(group string, str string) {
	if l.flags.has(.error) {
		if l.flags.has(.buffer) {
			l.buffer.writeln(log.label_error + ' $group ' + str)
		}
		maybe_colored := term.colorize(term.bright_red, log.label_error + ' ') +
			term.colorize(term.white, '$group ')
		l.redirect(maybe_colored + str)
	}
}

[if !no_log ?]
pub fn (mut l Log) gcritical(group string, str string) {
	if l.flags.has(.critical) {
		if l.flags.has(.buffer) {
			l.buffer.writeln(log.label_critical + ' $group ' + str)
		}
		maybe_colored := term.colorize(term.red, log.label_critical + ' ') +
			term.colorize(term.white, '$group ')
		l.redirect(maybe_colored + str)
	}
}

[if debug && !no_log ?]
pub fn (mut l Log) gdebug(group string, str string) {
	if l.flags.has(.debug) {
		if l.flags.has(.buffer) {
			l.buffer.writeln(log.label_debug + ' $group ' + str)
		}
		maybe_colored := term.colorize(term.bright_magenta, log.label_debug + ' ') +
			term.colorize(term.white, '$group ')
		l.redirect(maybe_colored + str)
	}
}

//
pub fn (mut l Log) free() {
	// l.gdebug(@STRUCT+'.'+@FN,'freeing buffer...')
	unsafe { l.buffer.free() }
}
