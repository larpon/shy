// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package
module utils

import term

const term_has_color_support = term.can_show_color_on_stderr() && term.can_show_color_on_stdout()

pub enum MessageKind {
	neutral
	error
	warning
	notice
	details
}

@[params]
pub struct Details {
pub:
	details string
}

// shy_error prints `msg` prefixed with `error:` in red + `details` to STDERR.
pub fn shy_error(msg string, details Details) {
	eprintln('${color(.error, bold('error:'))} ${msg}')
	if details.details != '' {
		eprintln('${color(.details, bold('details:'))}\n${format_details(details.details)}')
	}
}

// shy_warning prints `msg` prefixed with `error:` in yellow + `details` to STDERR.
pub fn shy_warning(msg string, details Details) {
	eprintln('${color(.warning, bold('warning:'))} ${msg}')
	if details.details != '' {
		eprintln('${color(.details, bold('details:'))}\n${format_details(details.details)}')
	}
}

// shy_notice prints `msg` prefixed with `notice:` in magenta + `details` to STDERR.
// shy_notice can be disabled with `-d shy_no_notice` at compile time.
@[if !shy_no_notices ?]
pub fn shy_notice(msg string, details Details) {
	println('${color(.notice, bold('notice:'))} ${msg}')
	if details.details != '' {
		eprintln('${color(.details, bold('details:'))}\n${format_details(details.details)}')
	}
}

fn format_details(s string) string {
	return '  ${s.replace('\n', '\n  ')}'
}

fn bold(msg string) string {
	if !term_has_color_support {
		return msg
	}
	return term.bold(msg)
}

fn color(kind MessageKind, msg string) string {
	if !term_has_color_support {
		return msg
	}
	return match kind {
		.error {
			term.red(msg)
		}
		.warning {
			term.yellow(msg)
		}
		.notice {
			term.magenta(msg)
		}
		.details {
			term.bright_blue(msg)
		}
		else {
			msg
		}
	}
}
