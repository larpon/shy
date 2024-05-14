# vmon

A V module for asynchronously watching for file changes in a directory.
The module is essentially a wrapper for [septag/dmon](https://github.com/septag/dmon).
It works for Windows, macOS and Linux.

Currently `vmon` offers a few additional features over the code in `dmon`.

* Automatic shared access to the user data in the callback thread (via `sync.Mutex`)
* Automatic init/free of memory resources on clean program exits

# Install

```bash
v install https://github.com/Larpon/vmon
```

# Usage

For example usage see `examples/watch_and_wait`

```v
v run ~/.vmodules/vmon/examples/watch_and_wait
```

To watch a directory asynchronously for *file* changes simply do:
```v
import os
import vmon

fn watch_callback(watch_id vmon.WatchID, action vmon.Action, root_path string, file_path string, old_file_path string, user_data voidptr) {
	// ... do stuff here
}

fn main() {
	vmon.watch(os.home_dir(), watch_callback, 0, voidptr(0)) or { panic(err) }
	// ... do stuff here, wait or block the main thread, e.g.:
	time.sleep(10 * time.second)
}
```

Since the file watching is running in it's own thread remember to block your main thread while watching for changes, otherwise the app will exit immediately.

# Notes

Please note that [septag/dmon](https://github.com/septag/dmon) is [licensed](https://github.com/septag/dmon#license-bsd-2-clause) under BSD 2-clause
while the V wrapper code is licensed under MIT.

Please also note that your user need correct file permission access
to the directories you're trying to watch. So watching a place
like `/tmp` on Unix isn't always possible since this is usually owned by root.
However, you're usually allowed to make subdirectories in `/tmp` which can be watched.

Also please note that currently you won't receive events from changes to *directories* in the
watched path since this is not supported in the C project we rely on.
