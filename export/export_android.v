// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module export

fn export_android(opt Options) ! {
	mut gl_version := opt.gl_version
	match opt.format {
		.android_apk, .android_aab {
			if gl_version in ['3', '2'] {
				mut auto_gl_version := 'es2'
				if gl_version == '3' {
					auto_gl_version = 'es3'
				}
				if opt.verbosity > 0 {
					eprintln('Auto adjusting OpenGL version for Android from ${gl_version} to ${auto_gl_version}')
				}
				gl_version = auto_gl_version
			}
		}
		else {}
	}
	adjusted_options := Options{
		...opt
		gl_version: gl_version
	}
	if opt.verbosity > 3 {
		eprintln('--- ${@MOD}.${@FN} ---')
		eprintln(adjusted_options)
	}
}
