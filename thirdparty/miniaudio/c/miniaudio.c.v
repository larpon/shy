// Copyright(C) 2019-2021 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package
// miniaudio https://github.com/dr-soft/miniaudio @ dbca7a3b (Version 0.10.42)
// is licensed under the unlicense and, are thus, in the public domain.
module c

pub const used_import = 1

#flag -I @VMODROOT/miniaudio
$if linux {
	#flag -lpthread -lm -ldl
}

$if macos {
	#flag -lpthread -lm
}

$if miniaudio_use_vorbis ? {
	#flag -D STB_VORBIS_HEADER_ONLY
	#include "extras/stb_vorbis.c" // Enables Vorbis decoding.
}

$if debug {
	#flag -D MA_DEBUG_OUTPUT
	#flag -D MA_LOG_LEVEL_VERBOSE
}

$if gcboehm ? {
	#define MA_MALLOC GC_MALLOC
	#define MA_REALLOC GC_REALLOC
	#define MA_FREE GC_FREE
}

// #flag -D MA_NO_PULSEAUDIO
#flag -D MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"

$if miniaudio_use_vorbis ? {
	// stb_vorbis implementation must come after the implementation of miniaudio.
	#insert @VMODROOT/undef_stb_vorbis.c
	#include "extras/stb_vorbis.c"
}
