module c

import sokol.c as sc

pub const used_import = 1 + sc.used_import

#flag -I @VMODROOT/c/sokol_gp

#include "sokol_gp.h"
