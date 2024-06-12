// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import os
import flag
import term
import shy.cli

const c_embedded_shy_sixel_logo = $embed_file('assets/images/shy.six')

fn main() {
	// Run any sub-commands on the spot if found in args
	cli.run_subcommand(os.args) or {
		eprintln(err)
		exit(1)
	}
	// Collect user flags in an extended manner.
	// Start with defaults -> merge over SHY_FLAGS -> merge over cmdline flags -> merge .shy entries.
	mut opt := cli.Options{}
	mut fp := &flag.FlagParser(unsafe { nil })

	opt = cli.options_from_env(opt) or {
		eprintln('Error while parsing `SHY_FLAGS`: ${err}')
		eprintln('Use `${cli.exe_short_name} -h` to see all flags')
		exit(1)
	}

	opt, fp = cli.args_to_options(os.args, opt) or {
		eprintln('Error while parsing `os.args`: ${err}')
		eprintln('Use `${cli.exe_short_name} -h` to see all flags')
		exit(1)
	}

	if opt.dump_usage {
		if term.supports_sixel() {
			println(c_embedded_shy_sixel_logo.to_bytes().bytestr())
		}
		println(fp.usage())
		exit(0)
	}

	// All flags after this requires an input argument
	if fp.args.len == 0 {
		eprintln('No arguments given')
		eprintln('Use `shy -h` to see all flags')
		exit(1)
	}

	// TODO
	if opt.additional_args.len > 1 {
		if opt.additional_args[0] == 'xxx' {
			// xxx_arg := opt.additional_args[1]
			exit(1)
		}
	}

	// Call the doctor at this point
	if opt.additional_args.len > 0 {
		if opt.additional_args[0] == 'doctor' {
			cli.doctor(opt)
			exit(0)
		}
	}

	input := fp.args.last()
	opt.input = input

	cli.validate_input(opt.input)!

	opt.extend_from_dot_shy() or {
		eprintln('Error while parsing `.shy`: ${err}')
		eprintln('Use `${cli.exe_short_name} -h` to see all flags')
		exit(1)
	}

	// Validate environment after options and input has been resolved
	opt.validate_env() or { panic(err) }

	// input_ext := os.file_ext(opt.input)
	if opt.verbosity > 2 {
		dump(opt)
	}

	// `shy /path/to/some/v/source/code`
	opt.shy_v() or {
		eprintln('Error while building V code: ${err}')
		exit(1)
	}
}
