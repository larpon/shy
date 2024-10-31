## Shy up

(Features available with latest build from source)

#### Notable changes

* Add support for `wasm32_emscripten` build target making it possible to target the Web via `emscripten`/`emcc`
* **WIP** Rewrite `shy export` internals
  - Exporting to an `AppImage` on Linux now works via `shy export appimage ...`
  - Exporting to the Web (via `emcc`) now works via `shy export wasm ...`

#### Breaking changes

To be able to support platforms that does not natively support V closures some changes where needed to allow event
callbacks to still be able to get to the user data (`&App` instance) without using closures.

Code before:
  `pub type OnEventFn = fn (Event) bool`
Code after:
  `pub type OnEventFn = fn (&Shy, Event) bool`

For `shy.once(...)` / `shy.every(...)`:

Code before:
  `pub type TimerFn = fn () bool`
Code after:
  `pub type TimerFn = fn (t &Timer) bool` (then `t.shy.app[App]()`).

Example:

```v
shy.once(fn (t &shy.Timer) {
  mut app := t.shy.app[App]()
  // Do something meaningful
})
```

For complex reasons, all user space `&App` structs now need to be declared as `pub` in order for Shy to
pass it as generic to C code callbacks. This has to do with the way generic
functions has to be passed to C callbacks in V.

## Shy 0.2.0
*29 May 2024*

#### Notable changes

Start using a change log.

Big memory leak clean up release to circumvent some internal V memory leaks.
It is now possible to visually see images that is not loaded correctly or still loading via the `Easy` functions. Same
with audio and sounds.

#### BUGS reported upstream

* V https://github.com/vlang/v/issues/21585
* V https://github.com/vlang/v/issues/21594

#### Breaking changes

* `Assets.get[T]/1` now uses a multi return `(T, AssetGetStatus)` instead of `!T` to circumvent V leaking memory

#### Commits

* assets: change (breaking) `get[T]/1` to use multi-return `(T, AssetGetStatus)`
* shy: add `version/0` function for runtime quering of shy version
* api: let `assets.init()!` run a little later, after gfx and audio init
* assets: add tiny error stand-in assets
* assets: add performance TODO to `get[T]/1` after a dreadful amount of V memory leak testing...
* easy: remove obsolete comment
* assets: fix error messages
* assets: fix `-gc none` shutdown crash, add `-d shy_debug_assets` comptime flag
* fetch: fix off-by-one bug in queue system
