module cli

import os
import shy.vxt

// doctor prints various useful information to the shell to aid
// diagnosticing the work environment.
pub fn doctor(opt Options) {
	env_vars := os.environ()

	// shy section
	println('${exe_short_name}
	Version ${exe_version} ${exe_git_hash}
	Path "${exe_dir}"')

	// Shell environment
	print_var_if_set := fn (vars map[string]string, var_name string) {
		if var_name in vars {
			println('\t${var_name}=' + os.getenv(var_name))
		}
	}
	println('env')
	for env_var in shy_env_vars {
		print_var_if_set(env_vars, env_var)
	}

	// Product section
	println('Product
	Output "${opt.output}"')

	// V section
	println('V
	Version ${vxt.version()} ${vxt.version_commit_hash()}
	Path "${vxt.home()}"')
	if opt.v_flags.len > 0 {
		println('\tFlags ${opt.v_flags}')
	}
	// Print output of `v doctor` if v is found
	if vxt.found() {
		println('')
		v_cmd := [
			vxt.vexe(),
			'doctor',
		]
		v_res := os.execute(v_cmd.join(' '))
		out_lines := v_res.output.split('\n')
		for line in out_lines {
			println('\t${line}')
		}
	}
}
