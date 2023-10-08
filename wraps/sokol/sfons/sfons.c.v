module sfons

import shy.wraps.fontstash
import shy.wraps.sokol.f
import shy.wraps.sokol.memory

[markused]
const default_allocator = Allocator{
	alloc_fn: memory.salloc
	free_fn: memory.sfree
	user_data: voidptr(0x100005f0)
}

/*
sfonst_allocator_t

    Used in sfons_desc_t to provide custom memory-alloc and -free functions
    to sokol_fontstash.h. If memory management should be overridden, both the
    alloc and free function must be provided (e.g. it's not valid to
    override one function but not the other).

    NOTE that this does not affect memory allocation calls inside
    fontstash.h
*/
[typedef]
struct C.sfons_allocator_t {
	// void* (*alloc)(size_t size, void* user_data);
	alloc_fn memory.FnAllocatorAlloc
	// alloc fn (size usize, user_data voidptr) voidptr
	// void (*free)(void* ptr, void* user_data);
	free_fn memory.FnAllocatorFree
	// free      fn (ptr voidptr, user_data voidptr)
	user_data voidptr
}

pub type Allocator = C.sfons_allocator_t

[typedef]
struct C.sfons_desc_t {
	width     int       // initial width of font atlas texture (default: 512, must be power of 2)
	height    int       // initial height of font atlas texture (default: 512, must be power of 2)
	allocator Allocator = sfons.default_allocator // optional memory allocation overrides
}

pub type Desc = C.sfons_desc_t

// SOKOL_FONTSTASH_API_DECL FONScontext* sfons_create(const sfons_desc_t* desc);
fn C.sfons_create(const_desc &Desc) &fontstash.Context
fn C.sfons_destroy(ctx &fontstash.Context)
fn C.sfons_rgba(r u8, g u8, b u8, a u8) u32
fn C.sfons_flush(ctx &fontstash.Context)

// keep v from warning about unused imports
const used_import = f.used_import + fontstash.used_import + 1

[inline]
pub fn create(const_desc &Desc) &fontstash.Context {
	return C.sfons_create(const_desc)
}

[inline]
pub fn destroy(ctx &fontstash.Context) {
	C.sfons_destroy(ctx)
}

[inline]
pub fn rgba(r u8, g u8, b u8, a u8) u32 {
	return C.sfons_rgba(r, g, b, a)
}

[inline]
pub fn flush(ctx &fontstash.Context) {
	C.sfons_flush(ctx)
}
