<img src="shy.svg" width="128"/>

# Shy

Aims to be an intuitive, opinionated and solid foundation for game development and
creative coding written in [V](https://vlang.io) with which you can easily build and distribute small
to medium sized 2D games or applications.

The `shy` project works both as a V module and a standalone CLI tool.

# Targets

Please note that export and developing/building/running from some
of these platforms are still work-in-progress, but we aim to support
a wide range of targets like the following:

Windows, macOS, Linux, Raspberry PI, Android, Web (WASM/emscripten) and likely more.

# Highlights

* Get your creative ideas up and running relatively quick.
* Rich examples directory.
* Live coding and runtime experimenting via V's `-live` flag.
* Animation and timer system - built right in.
* Easy timers with `shy.once(...)` or `shy.every(...)`.
* 2D shape drawing with several levels, layers of control and performance.
* 2D shape collision detection.
* 3D capable (via `sokol_gfx.h`)
* Multiple, runtime switchable, render modes (immediate, UI, step).
* Fairly sub-system agnostic. Bring your own ECS, physics engine etc.
* [WIP] Assets system for easy loading (and freeing) of all kinds of assets: binary blobs, images,
music, sounds etc.
* [WIP] Export to different platforms via the `shy export` command.
* [WIP] Intuitive Qt/Widgets/QML (scene graph) inspired `ui` module
  supporting *custom* UI items (currently full of BUGS).
* [WIP] ... much more :)

# Known downsides

The following points may turn you away from using `shy` at this point
in time so use `shy` at your own risk and expense.

* Multi-window rendering support has relatively low priority and may never be supported.
* The `shy.ui` module's design goals can not currently be met 100% due to
  very-hard-to-reproduce bugs in the V compiler - mileage may vary until these bugs are squashed.
* Exporting of finished games, for real world distribution, can currently be complex.
  It has high priority to get the exporters working as painless as possible but it takes time.
* No visual editor(s), at the moment. Hopefully it'll come quick when the `ui` module matures.
* Export currently requires to be done from the target platform(s).
* Documentation is far from complete. Use the `examples` for guidance.

# Install

## Dependencies

`shy` currently depend on `sdl` and `vab` official V modules.

```bash
v install sdl
```
The `sdl` dependency is needed for the default backend. It will likely
be moved to be part of another backend or opt-in once `shy` matures
but for now you'll need the SDL2 library at build and runtime.

```bash
v install vab
```
`vab` is used by `shy export` and *does not* require you to have Java nor
the Android SDK/NDK installed. `shy export` need only `vab` to be installed as a module.

However if you intend to export your shy creations to the Android platform the aforementioned
dependencies are thus needed at *runtime* for `vab` to work.

## Unix (Linux, macOS)
```bash
git clone git@github.com:Larpon/shy.git ~/.vmodules/shy
v ~/.vmodules/shy # Builds the `shy` CLI tool
```

## Windows
```bash
git clone git@github.com:Larpon/shy.git %USERPROFILE%/.vmodules/shy
v %USERPROFILE%\.vmodules\shy # Builds the `shy` CLI tool
```

## Symlink (optional)
You can symlink `shy` to your `$PATH` so it works as a global shell command.

```bash
sudo ln -s ~/.vmodules/shy/shy /usr/local/bin/shy
```

## Shell tab completion (optional)
You can install tab completions for your shell by [following the instructions
here](https://github.com/Larpon/shy/blob/fb26741/cmd/complete.v#L11-L38).
