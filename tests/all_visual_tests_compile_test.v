// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
import os

const vexe = os.real_path(os.getenv_opt('VEXE') or { @VEXE })

const visual_tests_dir = os.join_path(@VMODROOT, 'tests', 'visual')

fn test_all_visual_tests_compile() {
	os.execute_or_panic('${vexe} should-compile-all -c "${visual_tests_dir}"')
}
