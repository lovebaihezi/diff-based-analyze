# [WIP] Single Thread Profile Guided Data Racing analyze

> [!NOTE]
> Still in progress.

## Build from source

** Use Master Branch of Zig to build **

The `build.zig` will dynamic link the `libgit2` and `libc`.

```
zig build -Doptimize=ReleaseSafe
```

Make sure you have `libgit2` and `infer` installed locally

## Usage

Currently not avaliable

## Todo

1. Add CI to build libgit2 static library for linking
