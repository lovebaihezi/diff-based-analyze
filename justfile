build:
  zig build

release:
  zig build -Doptimize=ReleaseSafe

install: release
  cp zig-out/bin/* ~/.local/bin

clean:
  rm -rf zig-cache
  rm -rf zig-out
