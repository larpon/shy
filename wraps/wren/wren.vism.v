// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module wren

// collect_garbage Immediately run the garbage collector to free unused memory.
pub fn (vm &VM) collect_garbage() {
	collect_garbage(vm)
}

// interpret Runs `source`, a string of Wren source code in a new fiber in `vm` in the
// interpret context of resolved `module`.
pub fn (vm &VM) interpret(const_module string, const_source string) WrenInterpretResult {
	return interpret(vm, const_module.str, const_source.str)
}

// make_call_handle Creates a handle that can be used to invoke a method with `signature` on
// make_call_handle using a receiver and arguments that are set up on the stack.
// This handle can be used repeatedly to directly invoke that method from C
// code using `wrenCall`.
// When you are done with this handle, it must be released using
// `wrenReleaseHandle`.
pub fn (vm &VM) make_call_handle(const_signature string) &Handle {
	return make_call_handle(vm, const_signature.str)
}

// call Calls `method`, using the receiver and arguments previously set up on the
// call stack.
// `method` must have been created by a call to `wrenMakeCallHandle`. The
// arguments to the method must be already on the stack. The receiver should be
// in slot 0 with the remaining arguments following it, in order. It is an
// error if the number of arguments provided does not match the method's
// signature.
// After this returns, you can access the return value from slot 0 on the stack.
pub fn (vm &VM) call(method &Handle) WrenInterpretResult {
	return call(vm, method)
}

// release_handle Releases the reference stored in `handle`. After calling this, `handle` can
// release_handle no longer be used.
pub fn (vm &VM) release_handle(handle &Handle) {
	release_handle(vm, handle)
}

// get_slot_count Returns the number of slots available to the current foreign method.
pub fn (vm &VM) get_slot_count() int {
	return get_slot_count(vm)
}

// ensure_slots Ensures that the foreign method stack has at least `numSlots` available for
// ensure_slots use, growing the stack if needed.
// Does not shrink the stack if it has more than enough slots.
// It is an error to call this from a finalizer.
pub fn (vm &VM) ensure_slots(num_slots int) {
	ensure_slots(vm, num_slots)
}

// get_slot_type Gets the type of the object in `slot`.
pub fn (vm &VM) get_slot_type(slot int) WrenType {
	return get_slot_type(vm, slot)
}

// get_slot_bool Reads a boolean value from `slot`.
// get_slot_bool It is an error to call this if the slot does not contain a boolean value.
pub fn (vm &VM) get_slot_bool(slot int) bool {
	return get_slot_bool(vm, slot)
}

// get_slot_bytes Reads a byte array from `slot`.
// get_slot_bytes The memory for the returned string is owned by Wren. You can inspect it
// while in your foreign method, but cannot keep a pointer to it after the
// function returns, since the garbage collector may reclaim it.
// Returns a pointer to the first byte of the array and fill `length` with the
// number of bytes in the array.
// It is an error to call this if the slot does not contain a string.
pub fn (vm &VM) get_slot_bytes(slot int, length &int) &char {
	return get_slot_bytes(vm, slot, length)
}

// get_slot_double Reads a number from `slot`.
// get_slot_double It is an error to call this if the slot does not contain a number.
pub fn (vm &VM) get_slot_double(slot int) f64 {
	return get_slot_double(vm, slot)
}

// get_slot_foreign Reads a foreign object from `slot` and returns a pointer to the foreign data
// get_slot_foreign stored with it.
// It is an error to call this if the slot does not contain an instance of a
// foreign class.
pub fn (vm &VM) get_slot_foreign(slot int) voidptr {
	return get_slot_foreign(vm, slot)
}

// get_slot_string Reads a string from `slot`.
// get_slot_string The memory for the returned string is owned by Wren. You can inspect it
// while in your foreign method, but cannot keep a pointer to it after the
// function returns, since the garbage collector may reclaim it.
// It is an error to call this if the slot does not contain a string.
pub fn (vm &VM) get_slot_string(slot int) string {
	chptr := get_slot_string(vm, slot)
	return unsafe { cstring_to_vstring(chptr) }
}

// get_slot_handle Creates a handle for the value stored in `slot`.
// get_slot_handle This will prevent the object that is referred to from being garbage collected
// until the handle is released by calling `wrenReleaseHandle()`.
pub fn (vm &VM) get_slot_handle(slot int) &Handle {
	return unsafe { &Handle(get_slot_handle(vm, slot)) }
}

// set_slot_bool Stores the boolean `value` in `slot`.
pub fn (vm &VM) set_slot_bool(slot int, value bool) {
	set_slot_bool(vm, slot, value)
}

// set_slot_bytes Stores the array `length` of `bytes` in `slot`.
// set_slot_bytes The bytes are copied to a new string within Wren's heap, so you can free
// memory used by them after this is called.
pub fn (vm &VM) set_slot_bytes(slot int, const_bytes &u8, length usize) {
	set_slot_bytes(vm, slot, const_bytes, length)
}

// set_slot_double Stores the numeric `value` in `slot`.
pub fn (vm &VM) set_slot_double(slot int, value f64) {
	set_slot_double(vm, slot, value)
}

// set_slot_new_foreign Creates a new instance of the foreign class stored in `classSlot` with `size`
// set_slot_new_foreign bytes of raw storage and places the resulting object in `slot`.
// This does not invoke the foreign class's constructor on the new instance. If
// you need that to happen, call the constructor from Wren, which will then
// call the allocator foreign method. In there, call this to create the object
// and then the constructor will be invoked when the allocator returns.
// Returns a pointer to the foreign object's data.
pub fn (vm &VM) set_slot_new_foreign(slot int, class_slot int, size usize) voidptr {
	return set_slot_new_foreign(vm, slot, class_slot, size)
}

// set_slot_new_list Stores a new empty list in `slot`.
pub fn (vm &VM) set_slot_new_list(slot int) {
	set_slot_new_list(vm, slot)
}

// set_slot_new_map Stores a new empty map in `slot`.
pub fn (vm &VM) set_slot_new_map(slot int) {
	set_slot_new_map(vm, slot)
}

// set_slot_null Stores null in `slot`.
pub fn (vm &VM) set_slot_null(slot int) {
	set_slot_null(vm, slot)
}

// set_slot_string Stores the string `text` in `slot`.
// set_slot_string The `text` is copied to a new string within Wren's heap, so you can free
// memory used by it after this is called. The length is calculated using
// `strlen()`. If the string may contain any null bytes in the middle, then you
// should use `wrenSetSlotBytes()` instead.
@[manualfree]
pub fn (vm &VM) set_slot_string(slot int, const_text string) {
	set_slot_string(vm, slot, const_text.str)
}

// set_slot_handle Stores the value captured in `handle` in `slot`.
// set_slot_handle This does not release the handle for the value.
pub fn (vm &VM) set_slot_handle(slot int, handle &Handle) {
	set_slot_handle(vm, slot, handle)
}

// get_list_count Returns the number of elements in the list stored in `slot`.
pub fn (vm &VM) get_list_count(slot int) int {
	return get_list_count(vm, slot)
}

// get_list_element Reads element `index` from the list in `listSlot` and stores it in
// get_list_element `elementSlot`.
pub fn (vm &VM) get_list_element(list_slot int, index int, element_slot int) {
	get_list_element(vm, list_slot, index, element_slot)
}

// set_list_element Sets the value stored at `index` in the list at `listSlot`,
// set_list_element to the value from `elementSlot`.
pub fn (vm &VM) set_list_element(list_slot int, index int, element_slot int) {
	set_list_element(vm, list_slot, index, element_slot)
}

// insert_in_list Takes the value stored at `elementSlot` and inserts it into the list stored
// insert_in_list at `listSlot` at `index`.
// As in Wren, negative indexes can be used to insert from the end. To append
// an element, use `-1` for the index.
pub fn (vm &VM) insert_in_list(list_slot int, index int, element_slot int) {
	insert_in_list(vm, list_slot, index, element_slot)
}

// get_map_count Returns the number of entries in the map stored in `slot`.
pub fn (vm &VM) get_map_count(slot int) int {
	return get_map_count(vm, slot)
}

// get_map_contains_key Returns true if the key in `keySlot` is found in the map placed in `mapSlot`.
pub fn (vm &VM) get_map_contains_key(map_slot int, key_slot int) bool {
	return get_map_contains_key(vm, map_slot, key_slot)
}

// get_map_value Retrieves a value with the key in `keySlot` from the map in `mapSlot` and
// get_map_value stores it in `valueSlot`.
pub fn (vm &VM) get_map_value(map_slot int, key_slot int, value_slot int) {
	get_map_value(vm, map_slot, key_slot, value_slot)
}

// set_map_value Takes the value stored at `valueSlot` and inserts it into the map stored
// set_map_value at `mapSlot` with key `keySlot`.
pub fn (vm &VM) set_map_value(map_slot int, key_slot int, value_slot int) {
	set_map_value(vm, map_slot, key_slot, value_slot)
}

// remove_map_value Removes a value from the map in `mapSlot`, with the key from `keySlot`,
// remove_map_value and place it in `removedValueSlot`. If not found, `removedValueSlot` is
// set to null, the same behaviour as the Wren Map API.
pub fn (vm &VM) remove_map_value(map_slot int, key_slot int, removed_value_slot int) {
	remove_map_value(vm, map_slot, key_slot, removed_value_slot)
}

// get_variable Looks up the top level variable with `name` in resolved `module` and stores
// get_variable it in `slot`.
pub fn (vm &VM) get_variable(const_module string, const_name string, slot int) {
	get_variable(vm, const_module.str, const_name.str, slot)
}

// has_variable Looks up the top level variable with `name` in resolved `module`,
// has_variable returns false if not found. The module must be imported at the time,
// use wrenHasModule to ensure that before calling.
pub fn (vm &VM) has_variable(const_module string, const_name string) bool {
	return has_variable(vm, const_module.str, const_name.str)
}

// has_module Returns true if `module` has been imported/resolved before, false if not.
pub fn (vm &VM) has_module(const_module string) bool {
	return has_module(vm, const_module.str)
}

// abort_fiber Sets the current fiber to be aborted, and uses the value in `slot` as the
// abort_fiber runtime error object.
pub fn (vm &VM) abort_fiber(slot int) {
	abort_fiber(vm, slot)
}

// get_user_data Returns the user data associated with the WrenVM.
pub fn (vm &VM) get_user_data() voidptr {
	return get_user_data(vm)
}

// set_user_data Sets user data associated with the WrenVM.
pub fn (vm &VM) set_user_data(user_data voidptr) {
	set_user_data(vm, user_data)
}
