# doit

Minimal to-do app for macOS 14+, inspired by Things 3.

## Build

Requires Swift 6 (Command Line Tools are enough, Xcode is not needed).

```sh
make run      # build and open build/Doit.app
make install  # copy to /Applications
make test
```

Tasks live in `~/Library/Application Support/doit/todos.json`. Use another file with `open build/Doit.app --args -storeURL /path/to/todos.json`.
