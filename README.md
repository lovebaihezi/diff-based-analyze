# [WIP] Single Thread Profile Guided Data Racing analyze

Still in progress.

## Build from source

** Use Master Branch of Zig to build **

The `build.zig` will dynamic link the `LLVM` and `libc`.

```
zig build -Doptimize=ReleaseSafe
```

Make sure you have `LLVM` installed locally

## Usage

```
clang -cc1 tests/basic.c -emit-llvm
cat tests/basic.ll | zig build run
```
