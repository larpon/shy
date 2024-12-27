# Static link SDL2 installed via brew

```bash
v -prod -d sdl_no_compile_flags -cflags "$(sdl2-config --cflags)" -cflags "$(sdl2-config --static-libs)" .
```

Distribution
https://discourse.libsdl.org/t/deploying-for-macos-how-are-we-supposed-to-do-it/23897/5

.app bundle
https://tmewett.com/making-macos-bundle-info-plist/

.dmg building
https://github.com/create-dmg/create-dmg/tree/master

# Test Retina on non-retina

(From https://www.insidegeek.net/turning-a-non-apple-monitor-into-a-retina-display/)

For the Terminal users (Method 2 - The fast way)

You can also enable HiDPI modes, without running any additional software, via Terminal.
Before doing so, it might be worth backing up `/Library/Preferences/com.apple.windowserver.plist`

Note: Remember to logout and back in, for the changes to take effect.

```bash
// To enable
sudo defaults write /Library/Preferences/com.apple.windowserver.plist DisplayResolutionEnabled -bool true

// To disable
sudo defaults delete /Library/Preferences/com.apple.windowserver.plist DisplayResolutionEnabled
```
