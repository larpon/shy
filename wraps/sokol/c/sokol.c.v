// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
module c

#flag -I @VMODROOT/thirdparty/sokol
#flag -I @VMODROOT/thirdparty/sokol/util

#flag freebsd -I /usr/local/include
#flag darwin -fobjc-arc
#flag linux -lX11 -lGL
#flag freebsd -L/usr/local/lib -lX11 -lGL
#flag openbsd -L/usr/X11R6/lib -lX11 -lGL
// #flag windows -lgdi32

// Note that -lm is needed *only* for sokol_gl.h's usage of sqrtf(),
// but without -lm, this fails:
// `v -cc gcc ~/.vmodules/sdl/examples/sdl_opengl_and_sokol/`
// With tcc, this succeeds with or without -lm:
// `v ~/.vmodules/sdl/examples/sdl_opengl_and_sokol/`
$if !tinyc {
	#flag linux -lm
}

$if prod {
	#define NDEBUG 1
}

$if debug {
	#define _DEBUG 1
}

// METAL
$if macos {
	$if metal ? {
		#flag -DSOKOL_METAL
		#flag -framework Metal -framework Cocoa -framework MetalKit -framework QuartzCore
	} $else {
		#flag darwin -DSOKOL_GLCORE -framework OpenGL -framework Cocoa -framework QuartzCore
	}
}
$if ios {
	#flag -DSOKOL_METAL
	#flag -framework Foundation -framework Metal -framework MetalKit -framework UIKit
}

$if wasm32_emscripten {
	#flag -DSOKOL_GLES3
	#flag -DSOKOL_NO_ENTRY
	#flag -s ERROR_ON_UNDEFINED_SYMBOLS=0
	#flag -s USE_WEBGL2=1
	$if !prod {
		#flag -s ASSERTIONS=1
	}
	$if prod {
		#flag -s ASSERTIONS=0
	}
	// See https://emscripten.org/docs/tools_reference/settings_reference.html#modularize
	// NOTE: that it makes it impossible to use `v -os wasm32_emscripten -o file.html program.v`, due to:
	// https://github.com/emscripten-core/emscripten/issues/7950
	// #flag -s MODULARIZE
}

// OPENGL
#flag linux -DSOKOL_GLCORE
#flag freebsd -DSOKOL_GLCORE
#flag openbsd -DSOKOL_GLCORE
//#flag darwin -framework OpenGL -framework Cocoa -framework QuartzCore
// D3D
#flag windows -DSOKOL_GLCORE
//#flag windows -DSOKOL_D3D11
// for simplicity, all header includes are here because import order matters and we dont have any way
// to ensure import order with V yet
//
// TODO should not be defined for android graphic (apk/aab using sokol) builds, but we have no ways to undefine
//#define SOKOL_NO_ENTRY
#flag linux   -DSOKOL_NO_ENTRY
#flag darwin  -DSOKOL_NO_ENTRY
#flag windows -DSOKOL_NO_ENTRY
#flag windows -DSOKOL_WIN32_FORCE_MAIN
#flag freebsd -DSOKOL_NO_ENTRY
#flag openbsd -DSOKOL_NO_ENTRY
#flag solaris -DSOKOL_NO_ENTRY
// TODO end

#flag linux -ldl

/*
TODO
$if gcboehm ? {
	#define SOKOL_MALLOC GC_MALLOC
	#define SOKOL_CALLOC(n,m) GC_MALLOC((n)*(m))
	#define SOKOL_REALLOC GC_REALLOC
	#define SOKOL_FREE GC_FREE
}
*/

#define SOKOL_IMPL
#define SOKOL_NO_DEPRECATED
#include "sokol_gfx.h"

#define SOKOL_GL_IMPL
#include "util/sokol_gl.h"
// #include "sokol_v.post.h"

// sokol_fontstash.h support
#define SOKOL_FONTSTASH_IMPL
#include "util/sokol_fontstash.h"
