libgit_version         := "1.7.2"
libgit2_tar            := "v" + libgit_version + ".tar.gz"
libgit2_url            := "https://github.com/libgit2/libgit2/archive/refs/tags/" + libgit2_tar

# Install libgit2, Install libclang
init: install-libgit2
  echo "done"

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

install-libgit2:
  wget {{libgit2_url}}
  tar xf {{libgit2_tar}}
  rm {{libgit2_tar}}
  cmake -GNinja -Bbuild -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DBUILD_CLAR=OFF libgit2-1.7.2
  cmake --build build
  sudo cmake --install build

update-stringzilla:
  cd src
  wget https://raw.githubusercontent.com/ashvardanian/StringZilla/main/include/stringzilla/stringzilla.h
  mv stringzilla.h src
  zig translate-c src/stringzilla.h -I/usr/include > src/stringzilla.zig

install-pmd:
  wget https://github.com/pmd/pmd/releases/download/pmd_releases%2F7.0.0/pmd-dist-7.0.0-bin.zip
  unzip pmd-dist-7.0.0-bin.zip
  rm pmd-dist-7.0.0-bin.zip
