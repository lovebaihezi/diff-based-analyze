# [WIP] Single Thread Profile Guided Data Racing analyze

Still in progress.

## Build from source

The `build.zig` will dynamic link the `LLVM` and `libc`.

```
nix develop
zig build -Doptimize=ReleaseSafe
```
