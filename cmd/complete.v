// Copyright (c) 2019-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
//
// Utility functions helping integrate with various shell auto-completion systems.
// The install process and communication is inspired from that of [kitty](https://sw.kovidgoyal.net/kitty/#completion-for-kitty)
// This method avoids writing and maintaining external files on the user's file system.
// The user will be responsible for adding a small line to their .*rc - that will ensure *live* (i.e. not-static)
// auto-completion features.
//
// # bash
// To install auto-completion for shy in bash, simply add this code to your `~/.bashrc`:
// `source /dev/stdin <<<"$(shy complete setup bash)"`
// On more recent versions of bash (>3.2) this should suffice:
// `source <(shy complete setup bash)`
//
// # fish
// For versions of fish <3.0.0, add the following to your `~/.config/fish/config.fish`
// `shy complete setup fish | source`
// Later versions of fish source completions by default.
//
// # zsh
// To install auto-completion for shy in zsh - please add the following to your `~/.zshrc`:
// ```
// autoload -Uz compinit
// compinit
// # Completion for shy
// shy complete setup zsh | source /dev/stdin
// ```
// Please note that you should let shy load the zsh completions after the call to compinit
//
// # powershell
// To install auto-complete for shy in PowerShell, simply do this
// `shy complete setup powershell >> $PROFILE`
// and reload profile
// `& $PROFILE`
// If `$PROFILE` doesn't exist, create it before running the above
// `New-Item -Type File -Force $PROFILE`
//
module main

import os

const auto_complete_shells = ['bash', 'fish', 'zsh', 'powershell'] // list of supported shells

const shyexe = os.getenv('SHY_EXE')
const help_text = "Usage:
  shy complete [options] [SUBCMD] QUERY...

Description:
  Tool for bridging auto completion between various shells and shy

Supported shells:
  bash, fish, zsh, powershell

Examples:
  Echo auto-detected shell install script to STDOUT
    shy complete
  Echo specific shell install script to STDOUT
    shy complete setup bash
  Auto complete input `shy tes`*USER PUSHES TAB* (in Bash compatible format).
  This is not meant for manual invocation - it's called by the relevant
  shell via the script installed with `shy complete` or `shy complete setup SHELL`.
    shy complete bash shy tes

Options:
  -h, --help                Show this help text.

SUBCMD:
  setup     : setup [SHELL] - returns the code for completion setup for SHELL
  bash      : [QUERY]       - returns Bash compatible completion code with completions computed from QUERY
  fish      : [QUERY]       - returns Fish compatible completion code with completions computed from QUERY
  zsh       : [QUERY]       - returns ZSH  compatible completion code with completions computed from QUERY
  powershell: [QUERY]       - returns PowerShell compatible completion code with completions computed from QUERY"

// Snooped from shy.v
const auto_complete_commands = [
	// tools in one .v file
	'complete',
	'export',
	'test-cleancode',
	// commands
	'run',
	'doctor',
]
// Entries in the flag arrays below should be entered as is:
// * Short flags, e.g.: "-v", should be entered: '-v'
// * Long flags, e.g.: "--version", should be entered: '--version'
// * Single-dash flags, e.g.: "-version", should be entered: '-version'
const auto_complete_flags = [
	// V related flags
	'-autofree',
	'-gc',
	'-g',
	'-cg',
	'-prod',
	'-showcc',
	// shy flags
	'--verbosity',
	'-v',
	'--version',
	'--assets',
	'-a',
	'--flag',
	'-f',
	'--cflag',
	'-c',
	'--gles',
	'--help',
	'-h',
	'--nocache',
	'--output',
	'-o',
]
const auto_complete_flags_complete = [
	'--help',
	'-h',
]
const auto_complete_flags_export = [
	'--help',
	'-h',
]

// auto_complete prints auto completion results back to the calling shell's completion system.
// auto_complete acts as communication bridge between the calling shell and V's completions.
fn auto_complete(args []string) {
	if args.len <= 1 || args[0] != 'complete' {
		if args.len == 1 {
			shell_path := os.getenv('SHELL')
			if shell_path.len > 0 {
				shell_name := os.file_name(shell_path).to_lower()
				if shell_name in auto_complete_shells {
					println(setup_for_shell(shell_name))
					exit(0)
				}
				eprintln('Unknown shell ${shell_name}. Supported shells are: ${auto_complete_shells}')
				exit(1)
			}
			eprintln('auto completion require arguments to work.')
		} else {
			eprintln('auto completion failed for "${args}".')
		}
		exit(1)
	}
	sub := args[1]
	sub_args := args[1..]
	match sub {
		'setup' {
			if sub_args.len <= 1 || sub_args[1] !in auto_complete_shells {
				eprintln('please specify a shell to setup auto completion for (${auto_complete_shells}).')
				exit(1)
			}
			shell := sub_args[1]
			println(setup_for_shell(shell))
		}
		'bash' {
			if sub_args.len <= 1 {
				exit(0)
			}
			mut lines := []string{}
			list := auto_complete_request(sub_args[1..])
			for entry in list {
				lines << "COMPREPLY+=('${entry}')"
			}
			println(lines.join('\n'))
		}
		'fish', 'powershell' {
			if sub_args.len <= 1 {
				exit(0)
			}
			mut lines := []string{}
			list := auto_complete_request(sub_args[1..])
			for entry in list {
				lines << '${entry}'
			}
			println(lines.join('\n'))
		}
		'zsh' {
			if sub_args.len <= 1 {
				exit(0)
			}
			mut lines := []string{}
			list := auto_complete_request(sub_args[1..])
			for entry in list {
				lines << 'compadd -U -S' + '""' + ' -- ' + "'${entry}';"
			}
			println(lines.join('\n'))
		}
		'-h', '--help' {
			println(help_text)
		}
		else {}
	}
	exit(0)
}

// append_separator_if_dir is a utility function.that returns the input `path` appended an
// OS dependant path separator if the `path` is a directory.
fn append_separator_if_dir(path string) string {
	if os.is_dir(path) && !path.ends_with(os.path_separator) {
		return path + os.path_separator
	}
	return path
}

// nearest_path_or_root returns the nearest valid path searching
// backwards from `path`.
fn nearest_path_or_root(path string) string {
	mut fixed_path := path
	if !os.is_dir(fixed_path) {
		fixed_path = path.all_before_last(os.path_separator)
		if fixed_path == '' {
			fixed_path = '/'
		}
	}
	return fixed_path
}

// auto_complete_request retuns a list of completions resolved from a full argument list.
fn auto_complete_request(args []string) []string {
	// Using space will ensure a uniform input in cases where the shell
	// returns the completion input as a string (['v','run'] vs. ['v run']).
	split_by := ' '
	request := args.join(split_by)
	mut do_home_expand := false
	mut list := []string{}
	// new_part := request.ends_with('\n\n')
	mut parts := request.trim_right(' ').split(split_by)
	if parts.len <= 1 { // 'v <tab>' -> top level commands.
		for command in auto_complete_commands {
			list << command
		}
	} else {
		mut part := parts.last().trim(' ')
		mut parent_command := ''
		for i := parts.len - 1; i >= 0; i-- {
			if parts[i].starts_with('-') {
				continue
			}
			parent_command = parts[i]
			break
		}
		if part.starts_with('-') { // 'v [subcmd] -<tab>' or 'v [subcmd] --<tab>'-> flags.
			get_flags := fn (base []string, flag string) []string {
				mut results := []string{}
				for entry in base {
					if entry.starts_with(flag) {
						results << entry
					}
				}
				return results
			}

			match parent_command {
				'complete' { // 'shy complete -<tab>'
					list = get_flags(auto_complete_flags_complete, part)
				}
				'export' { // 'shy export -<tab>'
					list = get_flags(auto_complete_flags_export, part)
				}
				else {
					for flag in auto_complete_flags {
						if flag.starts_with(part) { // 'v -<char(s)><tab>' -> flags matching "<char(s)>".
							list << flag
						}
					}
				}
			}
			// Clear the list if the result is identical to the part examined
			// (the flag must have already been completed)
			if list.len == 1 && part == list[0] {
				list.clear()
			}
		} else {
			match part {
				'help' { // 'v help <tab>' -> top level commands except "help".
					list = auto_complete_commands.filter(it != part && it != 'complete')
				}
				else {
					// 'v <char(s)><tab>' -> commands matching "<char(s)>".
					// Don't include if part matches a full command - instead go to path completion below.
					for command in auto_complete_commands {
						if part != command && command.starts_with(part) {
							list << command
						}
					}
				}
			}
		}
		// Nothing of value was found.
		// Mimic shell dir and file completion
		if list.len == 0 {
			mut ls_path := '.'
			mut collect_all := part in auto_complete_commands
			mut path_complete := false
			do_home_expand = part.starts_with('~')
			if do_home_expand {
				add_sep := if part == '~' { os.path_separator } else { '' }
				part = part.replace_once('~', os.home_dir().trim_right(os.path_separator)) + add_sep
			}
			is_abs_path := part.starts_with(os.path_separator) // TODO Windows support for drive prefixes
			if part.ends_with(os.path_separator) || part == '.' || part == '..' {
				// 'v <command>(.*/$|.|..)<tab>' -> output full directory list
				ls_path = '.' + os.path_separator + part
				if is_abs_path {
					ls_path = nearest_path_or_root(part)
				}
				collect_all = true
			} else if !collect_all && part.contains(os.path_separator) && os.is_dir(os.dir(part)) {
				// 'v <command>(.*/.* && os.is_dir)<tab>'  -> output completion friendly directory list
				if is_abs_path {
					ls_path = nearest_path_or_root(part)
				} else {
					ls_path = os.dir(part)
				}
				path_complete = true
			}

			entries := os.ls(ls_path) or { return list }
			mut last := part.all_after_last(os.path_separator)
			if is_abs_path && os.is_dir(part) {
				last = ''
			}
			if path_complete {
				path := part.all_before_last(os.path_separator)
				for entry in entries {
					if entry.starts_with(last) {
						list << append_separator_if_dir(os.join_path(path, entry))
					}
				}
			} else {
				// Handle special case, where there is only one file in the directory
				// being completed - if it can be resolved we return that since
				// handling it in the generalized logic below will result in
				// more complexity.
				if entries.len == 1 && os.is_file(os.join_path(ls_path, entries[0])) {
					mut keep_input_path_format := ls_path
					if !part.starts_with('./') && ls_path.starts_with('./') {
						keep_input_path_format = keep_input_path_format.all_after('./')
					}
					return [os.join_path(keep_input_path_format, entries[0])]
				}
				for entry in entries {
					if collect_all || entry.starts_with(last) {
						list << append_separator_if_dir(entry)
					}
				}
			}
		}
	}
	if do_home_expand {
		return list.map(it.replace_once(os.home_dir().trim_right(os.path_separator), '~'))
	}
	return list
}

fn setup_for_shell(shell string) string {
	mut setup := ''
	match shell {
		'bash' {
			setup = '
_shy_completions() {
	local src
	local limit
	# Send all words up to the word the cursor is currently on
	let limit=1+\$COMP_CWORD
	src=\$(${shyexe} complete bash \$(printf "%s\\n" \${COMP_WORDS[@]: 0:\$limit}))
	if [[ \$? == 0 ]]; then
		eval \${src}
		#echo \${src}
	fi
}

complete -o nospace -F _shy_completions shy
'
		}
		'fish' {
			setup = '
function __shy_completions
	# Send all words up to the one before the cursor
	${shyexe} complete fish (commandline -cop)
end
complete -f -c shy -a "(__shy_completions)"
'
		}
		'zsh' {
			setup = '
#compdef shy
_shy() {
	local src
	# Send all words up to the word the cursor is currently on
	src=\$(${shyexe} complete zsh \$(printf "%s\\n" \${(@)words[1,\$CURRENT]}))
	if [[ \$? == 0 ]]; then
		eval \${src}
		#echo \${src}
	fi
}
compdef _shy shy
'
		}
		'powershell' {
			setup = '
Register-ArgumentCompleter -Native -CommandName v -ScriptBlock {
	param(\$commandName, \$wordToComplete, \$cursorPosition)
		${shyexe} complete powershell "\$wordToComplete" | ForEach-Object {
			[System.Management.Automation.CompletionResult]::new(\$_, \$_, \'ParameterValue\', \$_)
		}
}
'
		}
		else {}
	}
	return setup
}

fn main() {
	args := os.args[1..]
	// println('"$args"')
	auto_complete(args)
}
