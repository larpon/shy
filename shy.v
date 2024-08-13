// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import flag
import term
import shy.cli

const c_embedded_shy_sixel_logo = $embed_file('assets/images/shy.six')

fn main() {
	args := arguments()

	// Collect user flags in an extended manner.
	// Start with defaults -> merge over SHY_FLAGS -> merge over cmdline flags -> merge .shy entries.
	mut opt := cli.Options{}

	// Run any sub-commands if found on the spot if found in args
	cli.run_subcommand(args, '-nocache' in args) or {
		eprintln(err)
		exit(1)
	}

	/* TODO: (lmp) .shy should be first, then env then flags, right?
	opt.extend_from_dot_shy() or {
		eprintln('Error while parsing `.shy`: ${err}')
		eprintln('Use `${cli.exe_short_name} -h` to see all flags')
		exit(1)
	}
	*/

	opt = cli.options_from_env(opt) or {
		eprintln('Error while parsing `SHY_FLAGS`: ${err}')
		eprintln('Use `${cli.exe_short_name} -h` to see all flags')
		exit(1)
	}

	opt = cli.args_to_options(args, opt) or {
		eprintln('Error while parsing arguments: ${err}')
		eprintln('Use `${cli.exe_short_name} -h` to see all flags')
		exit(1)
	}

	if opt.show_version {
		println('${cli.exe_short_name} ${cli.exe_version}')
		exit(0)
	}

	if opt.dump_usage {
		if term.supports_sixel() {
			println(c_embedded_shy_sixel_logo.to_bytes().bytestr())
		}
		println(flag.to_doc[cli.Options](
			name:        cli.exe_short_name
			version:     '${cli.exe_version} (${cli.exe_git_hash})'
			description: cli.exe_description
			options:     flag.DocOptions{
				compact: true
			}
		)!)
		exit(0)
	}

	// All flags after this requires an input argument
	if args.len == 1 {
		eprintln('No arguments given')
		eprintln('Use `shy -h` to see all flags')
		exit(1)
	}

	cli.validate_input(opt.input)!

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
