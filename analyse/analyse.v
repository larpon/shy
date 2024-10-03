// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module analyse

const hack = init()

fn init() &Analysis {
	$if !shy_analyse ? {
		return unsafe { nil }
	}
	return &Analysis{}
}

@[if shy_analyse ?]
struct Analysis {
mut:
	entries map[string]string
}

// taggged_count adds the `key` entry to the report, if not already there, and
// increase it's value by `amount`.
@[if shy_analyse ?]
fn tagged_count[T](tag string, key string, amount T) {
	mut a := unsafe { hack } // TODO
	nkey := '[${tag}]${key}'
	$if T is int {
		a.entries[nkey] = '${a.entries[nkey].int() + amount}'
	} $else $if T is u32 {
		a.entries[nkey] = '${a.entries[nkey].u32() + amount}'
	} $else $if T is i64 {
		a.entries[nkey] = '${a.entries[nkey].i64() + amount}'
	} $else $if T is u64 {
		a.entries[nkey] = '${a.entries[nkey].u64() + amount}'
	} $else $if T is f32 {
		a.entries[nkey] = '${a.entries[nkey].f32() + amount}'
	} $else $if T is f64 {
		a.entries[nkey] = '${a.entries[nkey].f64() + amount}'
	} $else {
		t := T{}
		panic('${@STRUCT}.${@FN}: ${typeof(t).name} is not supported')
	}
}

// count adds the `key` entry to the report, if not already there, and
// increase it's value by `amount`.
@[if shy_analyse ?]
pub fn count[T](key string, amount T) {
	tagged_count(@FN, key, amount)
}

// count_and_sum adds the `key` entry to the report, if not already there, and
// increase it's value by `amount`. `key` should end with `@<some key name>` denoting
// a group for the total sum of that group.
@[if shy_analyse ?]
pub fn count_and_sum[T](key string, amount T) {
	sum_key := key.all_after_last('@')
	if sum_key != '' {
		tagged_count[T]('sum', '@${sum_key}', amount)
	}
	count[T](key, amount)
}

@[if shy_analyse ?]
pub fn max[T](key string, amount T) {
	mut a := unsafe { hack } // TODO
	nkey := '[${@FN}]${key}'
	$if T is int {
		cur_amount := a.entries[nkey].int()
		if amount > cur_amount {
			a.entries[nkey] = '${amount}'
		}
	} $else $if T is u32 {
		cur_amount := a.entries[nkey].u32()
		if amount > cur_amount {
			a.entries[nkey] = '${amount}'
		}
	} $else $if T is i64 {
		cur_amount := a.entries[nkey].i64()
		if amount > cur_amount {
			a.entries[nkey] = '${amount}'
		}
	} $else $if T is u64 {
		cur_amount := a.entries[nkey].u64()
		if amount > cur_amount {
			a.entries[nkey] = '${amount}'
		}
	} $else $if T is f32 {
		cur_amount := a.entries[nkey].f32()
		if amount > cur_amount {
			a.entries[nkey] = '${amount}'
		}
	} $else $if T is f64 {
		cur_amount := a.entries[nkey].f64()
		if amount > cur_amount {
			a.entries[nkey] = '${amount}'
		}
	} $else {
		t := T{}
		panic('${@STRUCT}.${@FN}: ${typeof(t).name} is not supported')
	}
}

@[if shy_analyse ?]
pub fn min[T](key string, amount T) {
	mut a := unsafe { hack } // TODO
	nkey := '[${@FN}]${key}'
	$if T is int {
		cur_amount := a.entries[nkey].int()
		if amount < cur_amount {
			a.entries[nkey] = '${amount}'
		}
	} $else $if T is u32 {
		cur_amount := a.entries[nkey].u32()
		if amount < cur_amount {
			a.entries[nkey] = '${amount}'
		}
	} $else $if T is i64 {
		cur_amount := a.entries[nkey].i64()
		if amount < cur_amount {
			a.entries[nkey] = '${amount}'
		}
	} $else $if T is u64 {
		cur_amount := a.entries[nkey].u64()
		if amount < cur_amount {
			a.entries[nkey] = '${amount}'
		}
	} $else $if T is f32 {
		cur_amount := a.entries[nkey].f32()
		if amount < cur_amount {
			a.entries[nkey] = '${amount}'
		}
	} $else $if T is f64 {
		cur_amount := a.entries[nkey].f64()
		if amount < cur_amount {
			a.entries[nkey] = '${amount}'
		}
	} $else {
		t := T{}
		panic('${@STRUCT}.${@FN}: ${typeof(t).name} is not supported')
	}
}

// eprintln_report prints the report via `eprintln`.
@[if shy_analyse ?]
pub fn eprintln_report() {
	a := hack
	eprintln('--- analysis report ---')
	mut sorted_keys := a.entries.keys()
	sorted_keys.sort_with_compare(fn (a &string, b &string) int {
		ra := a.all_after(']')
		rb := b.all_after(']')
		if ra < rb {
			return -1
		}
		if ra > rb {
			return 1
		}
		return 0
	})
	mut key_max_len := 0
	for key in sorted_keys {
		k := key.all_before(']') + ']'
		runes_len := k.runes().len
		if runes_len > key_max_len {
			key_max_len = runes_len
		}
	}
	keys := sorted_keys.map(fn [key_max_len] (key string) string {
		mut tag := key.all_before(']') + '] '
		rest := key.all_after(']')
		tag_len := tag.len
		if tag_len < key_max_len + 1 {
			tag = tag + ' '.repeat(key_max_len + 1 - tag_len)
		}
		return '${tag}${rest}'
	})
	for i, key in sorted_keys {
		v := a.entries[key]
		k := keys[i]
		eprintln('${k}: ${v}')
	}
}
