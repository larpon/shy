// Copyright(C) 2019 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package
//
module main

import os
import flag
import shy.export
import shy.utils

pub const exe_version = '0.0.2' // version()

pub const exe_name = os.file_name(os.executable())
pub const exe_short_name = os.file_name(os.executable()).replace('.exe', '')
pub const exe_dir = os.dir(os.real_path(os.executable()))
pub const exe_args_description = 'input
or:    [options] input'

pub const exe_description = 'shy ${exe_short_name} <exporter> [options]
${exe_short_name} exports both plain V applications and shy-based applications.
The exporter is based on the `shy.export` module.

export can compile, package and deploy V apps for production use on a
wide range of platforms like:
Linux, macOS, Windows, Android and HTML5 (WASM).

Sub-commands:
  run                       Run the output package after successful export

Exporters:
  ${export.supported_exporters}'

pub struct Options {
pub:
	// These fields would make little sense to change during a run
	verbosity int @[repeats; short: v; xdoc: 'Verbosity level 1-3']
	//
	run     bool @[ignore]
	nocache bool @[xdoc: 'Do not use caching'] // defaults to false in os.args/flag parsing phase
	// echo and exit
	dump_usage   bool @[long: help; short: h; xdoc: 'Show this help message and exit']
	show_version bool @[long: version; xdoc: 'Output version information and exit']
	//
	exporter []string @[ignore]
}

pub fn args_to_options(arguments []string) !Options {
	if arguments.len <= 1 {
		return error('no arguments given')
	}

	mut args := arguments.clone()
	mut run := false
	for i, arg in args {
		if arg == 'run' {
			run = true
			args.delete(i)
			break
		}
	}
	mut exporter := []string{cap: 0}
	for i, arg in args {
		if arg in export.supported_exporters {
			exporter = args[i..].clone()
			args = args[..i].clone()
			break
		}
	}
	opt, _ := flag.to_struct[Options](args, skip: 1)!

	return Options{
		...opt
		run:      run
		exporter: exporter
	}
}

fn main() {
	opt := args_to_options(os.args) or {
		utils.shy_error('Error while parsing arguments: ${err}',
			details: 'Use `${exe_short_name} -h` to see all flags'
		)
		exit(1)
	}

	if opt.show_version {
		println('${exe_short_name} ${exe_version}')
		exit(0)
	}

	if opt.dump_usage {
		println(flag.to_doc[Options](
			name:        'shy ${exe_short_name}'
			version:     '${exe_version}'
			description: exe_description
			// options:     flag.DocOptions{
			// 	compact: true
			// }
		)!)
		exit(0)
	}

	if opt.exporter.len == 0 {
		utils.shy_error('No exporter defined', details: 'See `shy export -h` for help')
		exit(1)
	}

	mut export_result := export.Result{}
	match opt.exporter[0] {
		'appimage' {
			appimage_export_options := export.args_to_appimage_options(opt.exporter) or {
				utils.shy_error('Error getting AppImage options', details: '${err}')
				exit(1)
			}
			export_result = export.appimage(appimage_export_options) or {
				utils.shy_error('Error while exporting to AppImage', details: '${err}')
				exit(1)
			}
		}
		'wasm' {
			wasm_export_options := export.args_to_wasm_options(opt.exporter) or {
				utils.shy_error('Error getting wasm options', details: '${err}')
				exit(1)
			}
			export_result = export.wasm(wasm_export_options) or {
				utils.shy_error('Error while exporting to wasm', details: '${err}')
				exit(1)
			}
		}
		else {
			utils.shy_error('Unknown exporter "${opt.exporter[0]}"',
				details: 'Valid exporters: ${export.supported_exporters}'
			)
			exit(1)
		}
	}
	if export_result.output != '' {
		println(export_result.output)
	}
	exit(0)
}
