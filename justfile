build:
  zig build

release:
  zig build -Doptimize=ReleaseSafe

install: release
  cp zig-out/bin/* ~/.local/bin

debug: build
  cp zig-out/bin/* ~/.local/bin

clean:
  rm -rf zig-cache
  rm -rf zig-out
  rm ~/.local/bin/analysis

build-example-shared-var:
  clang tests/shared_var.c -fsanitize=address -fno-omit-frame-pointer -pthread -O3 -o main

build-examples: build-example-shared-var
  echo 'build done'

update-stringzilla:
  cd src
  wget https://raw.githubusercontent.com/ashvardanian/StringZilla/main/include/stringzilla/stringzilla.h
  mv stringzilla.h src
  zig translate-c src/stringzilla.h -I/usr/include > src/stringzilla.zig

install-pmd:
  wget https://github.com/pmd/pmd/releases/download/pmd_releases%2F7.0.0/pmd-dist-7.0.0-bin.zip
  unzip pmd-dist-7.0.0-bin.zip
  rm pmd-dist-7.0.0-bin.zip
