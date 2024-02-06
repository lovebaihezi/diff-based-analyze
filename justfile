build:
  zig build

release:
  zig build -Doptimize=ReleaseSafe

install: release
  cp zig-out/bin/analysis-ir ~/.local/bin
  cp zig-out/bin/versions ~/.local/bin
