libgit_version := "1.7.2"
libgit2_tar    := "v" + libgit_version + ".tar.gz"
libgit2_url    := "https://github.com/libgit2/libgit2/archive/refs/tags/" + libgit2_tar
zlib_version   := "1.3.1"
libz_tar       := "zlib-" + zlib_version + ".tar.gz"
libz_url       := "https://github.com/madler/zlib/releases/download/v" + zlib_version + "/" + libz_tar
infer_version  := "1.1.0"
pmd_version    := "7.0.0"
zig_target     := "native-native-musl"

# Install libgit2
init: install-libgit2 install-zlib

init-infer:
  wget "https://github.com/facebook/infer/releases/download/v{{ infer_version }}/infer-linux64-v{{ infer_version }}.tar.xz"
  tar xf infer-linux64-v{{ infer_version }}.tar.xz

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

# build example tests under tests folder by using meson
build-examples:
  cd ./tests/
  CFLAGS="-Dtarget={{zig_target}}" CC="clang-16" CXX="clang++-16" meson setup build --wipe
  ninja -C build

# fetch {{libgit_version}} tar from 
install-libgit2:
  wget {{libgit2_url}}
  tar xf {{libgit2_tar}}

build-libgit2:
  rm -rf libgit2-build
  CC="zig cc" CXX="zig c++" cmake -GNinja -Blibgit2-build -DCMKAE_C_FLAGS="-Dtarget={{zig_target}}" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTS=OFF -DBUILD_CLAR=OFF libgit2-{{libgit_version}}
  ninja -C libgit2-build
  cmake --install libgit2-build --prefix libgit2

install-zlib:
  wget {{libz_url}}
  tar xf {{libz_tar}}

build-zlib:
  rm -rf zlib-build zlib
  CC="zig cc" CXX="zig c++" cmake -GNinja -Bzlib-build -DCMAKE_C_FLAGS="-Dtarget={{zig_target}}" -DCMAKE_BUILD_TYPE=Release -DZLIB_BUILD_EXAMPLES=OFF -DCMAKE_INSTALL_PREFIX=$PWD/zlib zlib-{{zlib_version}}
  cmake --build zlib-build
  mkdir zlib
  mv zlib-build/libz.a zlib

update-stringzilla:
  cd src
  wget https://raw.githubusercontent.com/ashvardanian/StringZilla/main/include/stringzilla/stringzilla.h
  mv stringzilla.h src
  zig translate-c src/stringzilla.h -I/usr/include > src/stringzilla.zig

install-pmd:
  wget https://github.com/pmd/pmd/releases/download/pmd_releases%2F{{pmd_version}}/pmd-dist-{{pmd_version}}-bin.zip
  unzip pmd-dist-{{pmd_version}}-bin.zip
  rm pmd-dist-{{pmd_version}}-bin.zip
