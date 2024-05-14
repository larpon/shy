// Copyright(C) 2021-2022 Lars Pontoppidan. All rights reserved.
module c

// https://github.com/septag/dmon @ 57dc7bf

pub const used_import = 1 // TODO

#flag -I @VROOT/dmon
#flag darwin -framework CoreServices -framework CoreFoundation
//#flag darwin -lpthread
//#flag linux -lpthread

#define DMON_IMPL
#include "dmon.h"

// C definitions

// typedef struct { uint32_t id; } dmon_watch_id;
@[typedef]
struct C.dmon_watch_id {
pub:
	id u32
}

pub type WatchID = C.dmon_watch_id

// void dmon_init(void);
fn C.dmon_init()

pub fn doinit() {
	C.dmon_init()
}

// void dmon_deinit(void);
fn C.dmon_deinit()

pub fn deinit() {
	C.dmon_deinit()
}

// TODO pub type WatchFn = fn (watch_id WatchID, dmon_action action, const_rootdir &char, const_filepath &char, const_oldfilepath &char, user voidptr)

/*
dmon_watch_id dmon_watch(const char* rootdir,
                         void (*watch_cb)(dmon_watch_id watch_id, dmon_action action,
                                          const char* rootdir, const char* filepath,
                                          const char* oldfilepath, void* user),
                         uint32_t flags, void* user_data);
*/
pub fn C.dmon_watch(rootdir charptr, watch_cb voidptr, flags u32, user_data voidptr) C.dmon_watch_id

// TODO pub fn watch(root_dir string, watch_cb WatchFn)

// void dmon_unwatch(dmon_watch_id id);
pub fn C.dmon_unwatch(id C.dmon_watch_id)

/*
typedef enum dmon_watch_flags_t {
    DMON_WATCHFLAGS_RECURSIVE = 0x1,            // monitor all child directories
    DMON_WATCHFLAGS_FOLLOW_SYMLINKS = 0x2,      // resolve symlinks (linux only)
    DMON_WATCHFLAGS_OUTOFSCOPE_LINKS = 0x4,     // TODO: not implemented yet
    DMON_WATCHFLAGS_IGNORE_DIRECTORIES = 0x8    // TODO: not implemented yet
} dmon_watch_flags;
*/
/*
typedef enum dmon_action_t {
    DMON_ACTION_CREATE = 1,
    DMON_ACTION_DELETE,
    DMON_ACTION_MODIFY,
    DMON_ACTION_MOVE
} dmon_action;
*/
