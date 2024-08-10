// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

// KeyCode represents the internal code of a physical key
pub enum KeyCode {
	unknown      // 0
	@return      // '\r'
	escape       // '\033'
	backspace    // '\b'
	tab          // '\t'
	space        // ' '
	exclaim      // '!'
	quotedbl     // '"'
	hash         // '#'
	percent      // '%'
	dollar       // '$'
	ampersand    // '&'
	quote        // '\''
	leftparen    // '('
	rightparen   // ')'
	asterisk     // '*'
	plus         // '+'
	comma        // ','
	minus        // '-'
	period       // '.'
	slash        // '/'
	_0           // '0'
	_1           // '1'
	_2           // '2'
	_3           // '3'
	_4           // '4'
	_5           // '5'
	_6           // '6'
	_7           // '7'
	_8           // '8'
	_9           // '9'
	colon        // ':'
	semicolon    // ';'
	less         // '<'
	equals       // '='
	greater      // '>'
	question     // '?'
	at           // '@'
	leftbracket  // '['
	backslash    // '\\'
	rightbracket // ']'
	caret        // '^'
	underscore   // '_'
	backquote    // '`'
	a            // 'a'
	b            // 'b'
	c            // 'c'
	d            // 'd'
	e            // 'e'
	f            // 'f'
	g            // 'g'
	h            // 'h'
	i            // 'i'
	j            // 'j'
	k            // 'k'
	l            // 'l'
	m            // 'm'
	n            // 'n'
	o            // 'o'
	p            // 'p'
	q            // 'q'
	r            // 'r'
	s            // 's'
	t            // 't'
	u            // 'u'
	v            // 'v'
	w            // 'w'
	x            // 'x'
	y            // 'y'
	z            // 'z'
	//
	capslock
	//
	f1
	f2
	f3
	f4
	f5
	f6
	f7
	f8
	f9
	f10
	f11
	f12
	//
	printscreen
	scrolllock
	pause
	insert
	home
	pageup
	delete // '\177'
	end
	pagedown
	right
	left
	down
	up
	//
	numlockclear
	divide
	kp_multiply
	kp_minus
	kp_plus
	kp_enter
	kp_1
	kp_2
	kp_3
	kp_4
	kp_5
	kp_6
	kp_7
	kp_8
	kp_9
	kp_0
	kp_period
	//
	application
	power
	kp_equals
	f13
	f14
	f15
	f16
	f17
	f18
	f19
	f20
	f21
	f22
	f23
	f24
	execute
	help
	menu
	@select
	stop
	again
	undo
	cut
	copy
	paste
	find
	mute
	volumeup
	volumedown
	kp_comma
	equalsas400
	//
	alterase
	sysreq
	cancel
	clear
	prior
	return2
	separator
	out
	oper
	clearagain
	crsel
	exsel
	//
	kp_00
	kp_000
	thousandsseparator
	decimalseparator
	currencyunit
	currencysubunit
	kp_leftparen
	kp_rightparen
	kp_leftbrace
	kp_rightbrace
	kp_tab
	kp_backspace
	kp_a
	kp_b
	kp_c
	kp_d
	kp_e
	kp_f
	kp_xor
	kp_power
	kp_percent
	kp_less
	kp_greater
	kp_ampersand
	kp_dblampersand
	kp_verticalbar
	kp_dblverticalbar
	kp_colon
	kp_hash
	kp_space
	kp_at
	kp_exclam
	kp_memstore
	kp_memrecall
	kp_memclear
	kp_memadd
	kp_memsubtract
	kp_memmultiply
	kp_memdivide
	kp_plusminus
	kp_clear
	kp_clearentry
	kp_binary
	kp_octal
	kp_decimal
	kp_hexadecimal
	lctrl
	lshift
	lalt
	lgui
	rctrl
	rshift
	ralt
	rgui
	//
	mode
	//
	audionext
	audioprev
	audiostop
	audioplay
	audiomute
	mediaselect
	www
	mail
	calculator
	computer
	ac_search
	ac_home
	ac_back
	ac_forward
	ac_stop
	ac_refresh
	ac_bookmarks
	//
	brightnessdown
	brightnessup
	displayswitch
	kbdillumtoggle
	kbdillumdown
	kbdillumup
	eject
	sleep
	app1
	app2
	audiorewind
	audiofastforward
}

pub fn keycode_from_string(key_str string) KeyCode {
	mut str := key_str.to_lower()
	str = str.replace('keypad', 'kp')
	if !str.starts_with('kp') && !str.starts_with('ac') {
		str = str.replace('_', '').replace(' ', '')
	} else {
		str = str.replace(' ', '_')
	}
	str = str.replace('-', '')
	return match str {
		'unknown' { .unknown }
		'return' { .@return }
		'escape' { .escape }
		'backspace' { .backspace }
		'tab' { .tab }
		'space' { .space }
		'exclaim' { .exclaim }
		'quotedbl', 'doublequote' { .quotedbl }
		'hash' { .hash }
		'percent' { .percent }
		'dollar' { .dollar }
		'ampersand' { .ampersand }
		'quote' { .quote }
		'leftparen', 'lparen' { .leftparen }
		'rightparen', 'rparen' { .rightparen }
		'asterisk', 'star' { .asterisk }
		'plus' { .plus }
		'comma' { .comma }
		'minus' { .minus }
		'period' { .period }
		'slash' { .slash }
		'0' { ._0 }
		'1' { ._1 }
		'2' { ._2 }
		'3' { ._3 }
		'4' { ._4 }
		'5' { ._5 }
		'6' { ._6 }
		'7' { ._7 }
		'8' { ._8 }
		'9' { ._9 }
		'colon' { .colon }
		'semicolon' { .semicolon }
		'less' { .less }
		'equals' { .equals }
		'greater' { .greater }
		'question', 'questionmark' { .question }
		'at', '@' { .at }
		'leftbracket', 'lbracket' { .leftbracket }
		'backslash' { .backslash }
		'rightbracket', 'rbracket' { .rightbracket }
		'caret' { .caret }
		'underscore' { .underscore }
		'backquote' { .backquote }
		'a' { .a }
		'b' { .b }
		'c' { .c }
		'd' { .d }
		'e' { .e }
		'f' { .f }
		'g' { .g }
		'h' { .h }
		'i' { .i }
		'j' { .j }
		'k' { .k }
		'l' { .l }
		'm' { .m }
		'n' { .n }
		'o' { .o }
		'p' { .p }
		'q' { .q }
		'r' { .r }
		's' { .s }
		't' { .t }
		'u' { .u }
		'v' { .v }
		'w' { .w }
		'x' { .x }
		'y' { .y }
		'z' { .z }
		//
		'capslock' { .capslock }
		//
		'f1' { .f1 }
		'f2' { .f2 }
		'f3' { .f3 }
		'f4' { .f4 }
		'f5' { .f5 }
		'f6' { .f6 }
		'f7' { .f7 }
		'f8' { .f8 }
		'f9' { .f9 }
		'f10' { .f10 }
		'f11' { .f11 }
		'f12' { .f12 }
		//
		'printscreen' { .printscreen }
		'scrolllock' { .scrolllock }
		'pause' { .pause }
		'insert' { .insert }
		'home' { .home }
		'pageup' { .pageup }
		'delete' { .delete }
		'end' { .end }
		'pagedown' { .pagedown }
		'right' { .right }
		'left' { .left }
		'down' { .down }
		'up' { .up }
		//
		'numlockclear' { .numlockclear }
		'divide' { .divide }
		'kp_multiply' { .kp_multiply }
		'kp_minus' { .kp_minus }
		'kp_plus' { .kp_plus }
		'kp_enter' { .kp_enter }
		'kp_1' { .kp_1 }
		'kp_2' { .kp_2 }
		'kp_3' { .kp_3 }
		'kp_4' { .kp_4 }
		'kp_5' { .kp_5 }
		'kp_6' { .kp_6 }
		'kp_7' { .kp_7 }
		'kp_8' { .kp_8 }
		'kp_9' { .kp_9 }
		'kp_0' { .kp_0 }
		'kp_period' { .kp_period }
		//
		'application' { .application }
		'power' { .power }
		'kp_equals' { .kp_equals }
		'f13' { .f13 }
		'f14' { .f14 }
		'f15' { .f15 }
		'f16' { .f16 }
		'f17' { .f17 }
		'f18' { .f18 }
		'f19' { .f19 }
		'f20' { .f20 }
		'f21' { .f21 }
		'f22' { .f22 }
		'f23' { .f23 }
		'f24' { .f24 }
		'execute' { .execute }
		'help' { .help }
		'menu' { .menu }
		'select' { .@select }
		'stop' { .stop }
		'again' { .again }
		'undo' { .undo }
		'cut' { .cut }
		'copy' { .copy }
		'paste' { .paste }
		'find' { .find }
		'mute' { .mute }
		'volumeup' { .volumeup }
		'volumedown' { .volumedown }
		'kp_comma' { .kp_comma }
		'equalsas400' { .equalsas400 }
		//
		'alterase' { .alterase }
		'sysreq', 'sysrq' { .sysreq }
		'cancel' { .cancel }
		'clear' { .clear }
		'prior' { .prior }
		'return2' { .return2 }
		'separator' { .separator }
		'out' { .out }
		'oper' { .oper }
		'clearagain' { .clearagain }
		'crsel' { .crsel }
		'exsel' { .exsel }
		//
		'kp_00' { .kp_00 }
		'kp_000' { .kp_000 }
		'thousandsseparator' { .thousandsseparator }
		'decimalseparator' { .decimalseparator }
		'currencyunit' { .currencyunit }
		'currencysubunit' { .currencysubunit }
		'kp_leftparen' { .kp_leftparen }
		'kp_rightparen' { .kp_rightparen }
		'kp_leftbrace' { .kp_leftbrace }
		'kp_rightbrace' { .kp_rightbrace }
		'kp_tab' { .kp_tab }
		'kp_backspace' { .kp_backspace }
		'kp_a' { .kp_a }
		'kp_b' { .kp_b }
		'kp_c' { .kp_c }
		'kp_d' { .kp_d }
		'kp_e' { .kp_e }
		'kp_f' { .kp_f }
		'kp_xor' { .kp_xor }
		'kp_power' { .kp_power }
		'kp_percent' { .kp_percent }
		'kp_less' { .kp_less }
		'kp_greater' { .kp_greater }
		'kp_ampersand' { .kp_ampersand }
		'kp_dblampersand' { .kp_dblampersand }
		'kp_verticalbar' { .kp_verticalbar }
		'kp_dblverticalbar' { .kp_dblverticalbar }
		'kp_colon' { .kp_colon }
		'kp_hash' { .kp_hash }
		'kp_space' { .kp_space }
		'kp_at' { .kp_at }
		'kp_exclam' { .kp_exclam }
		'kp_memstore' { .kp_memstore }
		'kp_memrecall' { .kp_memrecall }
		'kp_memclear' { .kp_memclear }
		'kp_memadd' { .kp_memadd }
		'kp_memsubtract' { .kp_memsubtract }
		'kp_memmultiply' { .kp_memmultiply }
		'kp_memdivide' { .kp_memdivide }
		'kp_plusminus' { .kp_plusminus }
		'kp_clear' { .kp_clear }
		'kp_clearentry' { .kp_clearentry }
		'kp_binary' { .kp_binary }
		'kp_octal' { .kp_octal }
		'kp_decimal' { .kp_decimal }
		'kp_hexadecimal' { .kp_hexadecimal }
		'leftctrl', 'lctrl' { .lctrl }
		'leftshift', 'lshift' { .lshift }
		'leftalt', 'lalt' { .lalt }
		'leftgui', 'lgui' { .lgui }
		'rightctrl', 'rctrl' { .rctrl }
		'rightshift', 'rshift' { .rshift }
		'rightalt', 'ralt' { .ralt }
		'rightgui', 'rgui' { .rgui }
		//
		'mode' { .mode }
		//
		'audionext' { .audionext }
		'audioprev' { .audioprev }
		'audiostop' { .audiostop }
		'audioplay' { .audioplay }
		'audiomute' { .audiomute }
		'mediaselect' { .mediaselect }
		'www' { .www }
		'mail' { .mail }
		'calculator' { .calculator }
		'computer' { .computer }
		'ac_search', 'application control search' { .ac_search }
		'ac_home', 'application control home' { .ac_home }
		'ac_back', 'application control back' { .ac_back }
		'ac_forward', 'application control forward' { .ac_forward }
		'ac_stop', 'application control stop' { .ac_stop }
		'ac_refresh', 'application control refresh' { .ac_refresh }
		'ac_bookmarks', 'application control bookmarks' { .ac_bookmarks }
		//
		'brightnessdown' { .brightnessdown }
		'brightnessup' { .brightnessup }
		'displayswitch' { .displayswitch }
		'kbdillumtoggle' { .kbdillumtoggle }
		'kbdillumdown' { .kbdillumdown }
		'kbdillumup' { .kbdillumup }
		'eject' { .eject }
		'sleep' { .sleep }
		'app1' { .app1 }
		'app2' { .app2 }
		'audiorewind' { .audiorewind }
		'audiofastforward' { .audiofastforward }
		else { .unknown }
	}
}

pub fn (kc KeyCode) name() string {
	return match kc {
		.unknown { 'unknown' }
		.@return { 'return' }
		.escape { 'escape' }
		.backspace { 'backspace' }
		.tab { 'tab' }
		.space { 'space' }
		.exclaim { 'exclaim' }
		.quotedbl { 'double quote' }
		.hash { 'hash' }
		.percent { 'percent' }
		.dollar { 'dollar' }
		.ampersand { 'ampersand' }
		.quote { 'quote' }
		.leftparen { 'left paren' }
		.rightparen { 'right paren' }
		.asterisk { 'asterisk' }
		.plus { 'plus' }
		.comma { 'comma' }
		.minus { 'minus' }
		.period { 'period' }
		.slash { 'slash' }
		._0 { '0' }
		._1 { '1' }
		._2 { '2' }
		._3 { '3' }
		._4 { '4' }
		._5 { '5' }
		._6 { '6' }
		._7 { '7' }
		._8 { '8' }
		._9 { '9' }
		.colon { 'colon' }
		.semicolon { 'semi-colon' }
		.less { 'less' }
		.equals { 'equals' }
		.greater { 'greater' }
		.question { 'question' }
		.at { 'at' }
		.leftbracket { 'left bracket' }
		.backslash { 'backslash' }
		.rightbracket { 'right bracket' }
		.caret { 'caret' }
		.underscore { 'underscore' }
		.backquote { 'back quote' }
		.a { 'a' }
		.b { 'b' }
		.c { 'c' }
		.d { 'd' }
		.e { 'e' }
		.f { 'f' }
		.g { 'g' }
		.h { 'h' }
		.i { 'i' }
		.j { 'j' }
		.k { 'k' }
		.l { 'l' }
		.m { 'm' }
		.n { 'n' }
		.o { 'o' }
		.p { 'p' }
		.q { 'q' }
		.r { 'r' }
		.s { 's' }
		.t { 't' }
		.u { 'u' }
		.v { 'v' }
		.w { 'w' }
		.x { 'x' }
		.y { 'y' }
		.z { 'z' }
		//
		.capslock { 'caps lock' }
		//
		.f1 { 'f1' }
		.f2 { 'f2' }
		.f3 { 'f3' }
		.f4 { 'f4' }
		.f5 { 'f5' }
		.f6 { 'f6' }
		.f7 { 'f7' }
		.f8 { 'f8' }
		.f9 { 'f9' }
		.f10 { 'f10' }
		.f11 { 'f11' }
		.f12 { 'f12' }
		//
		.printscreen { 'print screen' }
		.scrolllock { 'scroll lock' }
		.pause { 'pause' }
		.insert { 'insert' }
		.home { 'home' }
		.pageup { 'page up' }
		.delete { 'delete' }
		.end { 'end' }
		.pagedown { 'page down' }
		.right { 'right' }
		.left { 'left' }
		.down { 'down' }
		.up { 'up' }
		//
		.numlockclear { 'num lock clear' }
		.divide { 'divide' }
		.kp_multiply { 'keypad multiply' }
		.kp_minus { 'keypad minus' }
		.kp_plus { 'keypad plus' }
		.kp_enter { 'keypad enter' }
		.kp_1 { 'keypad 1' }
		.kp_2 { 'keypad 2' }
		.kp_3 { 'keypad 3' }
		.kp_4 { 'keypad 4' }
		.kp_5 { 'keypad 5' }
		.kp_6 { 'keypad 6' }
		.kp_7 { 'keypad 7' }
		.kp_8 { 'keypad 8' }
		.kp_9 { 'keypad 9' }
		.kp_0 { 'keypad 0' }
		.kp_period { 'keypad period' }
		//
		.application { 'application' }
		.power { 'power' }
		.kp_equals { 'keypad equals' }
		.f13 { 'f13' }
		.f14 { 'f14' }
		.f15 { 'f15' }
		.f16 { 'f16' }
		.f17 { 'f17' }
		.f18 { 'f18' }
		.f19 { 'f19' }
		.f20 { 'f20' }
		.f21 { 'f21' }
		.f22 { 'f22' }
		.f23 { 'f23' }
		.f24 { 'f24' }
		.execute { 'execute' }
		.help { 'help' }
		.menu { 'menu' }
		.@select { 'select' }
		.stop { 'stop' }
		.again { 'again' }
		.undo { 'undo' }
		.cut { 'cut' }
		.copy { 'copy' }
		.paste { 'paste' }
		.find { 'find' }
		.mute { 'mute' }
		.volumeup { 'volume up' }
		.volumedown { 'volume down' }
		.kp_comma { 'keypad comma' }
		.equalsas400 { 'equalsas400' }
		//
		.alterase { 'alt erase' }
		.sysreq { 'sys req' }
		.cancel { 'cancel' }
		.clear { 'clear' }
		.prior { 'prior' }
		.return2 { 'return2' }
		.separator { 'separator' }
		.out { 'out' }
		.oper { 'oper' }
		.clearagain { 'clear again' }
		.crsel { 'crsel' }
		.exsel { 'exsel' }
		//
		.kp_00 { 'keypad 00' }
		.kp_000 { 'keypad 000' }
		.thousandsseparator { 'thousands separator' }
		.decimalseparator { 'decimalseparator' }
		.currencyunit { 'currency unit' }
		.currencysubunit { 'currency sub unit' }
		.kp_leftparen { 'keypad left paren' }
		.kp_rightparen { 'keypad right paren' }
		.kp_leftbrace { 'keypad left brace' }
		.kp_rightbrace { 'keypad right brace' }
		.kp_tab { 'keypad tab' }
		.kp_backspace { 'keypad backspace' }
		.kp_a { 'keypad a' }
		.kp_b { 'keypad b' }
		.kp_c { 'keypad c' }
		.kp_d { 'keypad d' }
		.kp_e { 'keypad e' }
		.kp_f { 'keypad f' }
		.kp_xor { 'keypad xor' }
		.kp_power { 'keypad power' }
		.kp_percent { 'keypad percent' }
		.kp_less { 'keypad less' }
		.kp_greater { 'keypad greater' }
		.kp_ampersand { 'keypad ampersand' }
		.kp_dblampersand { 'keypad double ampersand' }
		.kp_verticalbar { 'keypad vertical bar' }
		.kp_dblverticalbar { 'keypad double vertical bar' }
		.kp_colon { 'keypad colon' }
		.kp_hash { 'keypad hash' }
		.kp_space { 'keypad space' }
		.kp_at { 'keypad at' }
		.kp_exclam { 'keypad exclam' }
		.kp_memstore { 'keypad mem store' }
		.kp_memrecall { 'keypad mem recall' }
		.kp_memclear { 'keypad mem clear' }
		.kp_memadd { 'keypad mem add' }
		.kp_memsubtract { 'keypad mem subtract' }
		.kp_memmultiply { 'keypad mem multiply' }
		.kp_memdivide { 'keypad mem divide' }
		.kp_plusminus { 'keypad plus minus' }
		.kp_clear { 'keypad clear' }
		.kp_clearentry { 'keypad clear entry' }
		.kp_binary { 'keypad binary' }
		.kp_octal { 'keypad octal' }
		.kp_decimal { 'keypad decimal' }
		.kp_hexadecimal { 'keypad hexadecimal' }
		.lctrl { 'left ctrl' }
		.lshift { 'left shift' }
		.lalt { 'left alt' }
		.lgui { 'left gui' }
		.rctrl { 'right ctrl' }
		.rshift { 'right shift' }
		.ralt { 'right alt' }
		.rgui { 'right gui' }
		//
		.mode { 'mode' }
		//
		.audionext { 'audio next' }
		.audioprev { 'audio prev' }
		.audiostop { 'audio stop' }
		.audioplay { 'audio play' }
		.audiomute { 'audio mute' }
		.mediaselect { 'media select' }
		.www { 'www' }
		.mail { 'mail' }
		.calculator { 'calculator' }
		.computer { 'computer' }
		.ac_search { 'application control search' }
		.ac_home { 'application control home' }
		.ac_back { 'application control back' }
		.ac_forward { 'application control forward' }
		.ac_stop { 'application control stop' }
		.ac_refresh { 'application control refresh' }
		.ac_bookmarks { 'application control bookmarks' }
		//
		.brightnessdown { 'brightness down' }
		.brightnessup { 'brightness up' }
		.displayswitch { 'display switch' }
		.kbdillumtoggle { 'kbdillumtoggle' }
		.kbdillumdown { 'kbdillumdown' }
		.kbdillumup { 'kbdillumup' }
		.eject { 'eject' }
		.sleep { 'sleep' }
		.app1 { 'application 1' }
		.app2 { 'application 2' }
		.audiorewind { 'audio rewind' }
		.audiofastforward { 'audio fast forward' }
	}
}
