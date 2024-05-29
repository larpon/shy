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
