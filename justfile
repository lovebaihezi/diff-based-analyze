libgit_version         := "1.7.2"
libgit2_tar            := "v" + libgit_version + ".tar.gz"
libgit2_url            := "https://github.com/libgit2/libgit2/archive/refs/tags/" + libgit2_tar

infer_version          := 1.1.0

pmd_version            := "7.0.0"

# Install libgit2, Install libclang
init: install-libgit2

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
  CC="clang-18" CXX="clang++-18" meson setup build --wipe
  ninja -C build

# fetch {{libgit_version}} tar from 
install-libgit2:
  wget {{libgit2_url}}
  tar xf {{libgit2_tar}}
  rm {{libgit2_tar}}
  CC="clang-18" CXX="clang++-18" cmake -GNinja -Bbuild -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DBUILD_CLAR=OFF libgit2-1.7.2
  ninja -C build
  cmake --install build --prefix libgit2

update-stringzilla:
  cd src
  wget https://raw.githubusercontent.com/ashvardanian/StringZilla/main/include/stringzilla/stringzilla.h
  mv stringzilla.h src
  zig translate-c src/stringzilla.h -I/usr/include > src/stringzilla.zig

install-pmd:
  wget https://github.com/pmd/pmd/releases/download/pmd_releases%2F{{pmd_version}}/pmd-dist-{{pmd_version}}-bin.zip
  unzip pmd-dist-{{pmd_version}}-bin.zip
  rm pmd-dist-{{pmd_version}}-bin.zip
