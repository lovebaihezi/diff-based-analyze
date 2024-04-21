set shell := ["bash", "-euo", "pipefail"] 

libgit_version  := "1.7.2"
libgit2_tar     := "v" + libgit_version + ".tar.gz"
libgit2_url     := "https://github.com/libgit2/libgit2/archive/refs/tags/" + libgit2_tar
zlib_version    := "1.3.1"
libz_tar        := "zlib-" + zlib_version + ".tar.gz"
libz_url        := "https://github.com/madler/zlib/releases/download/v" + zlib_version + "/" + libz_tar
infer_version   := "1.1.0"
pmd_version     := "7.0.0"
zig_target      := "native-native-musl"
pvs_name        := "pvs-studio-7.29.79138.387-x86_64"
pvs_tar         := pvs_name + ".tgz"
pvs_url         := "https://cdn.pvs-studio.com/" + pvs_tar
pvs_cre_type    := "Free"
pvs_credentials := "FREE-FREE-FREE-FREE"
coverity_url    := "https://scan.coverity.com/download/cxx/linux64"

install-tools: install-pmd install-infer install-pvs

install-deps: install-libgit2 install-zlib 

install-pvs:
  wget {{ pvs_url }}
  tar xf {{ pvs_tar }}

install-infer:
  wget "https://github.com/facebook/infer/releases/download/v{{ infer_version }}/infer-linux64-v{{ infer_version }}.tar.xz"
  tar xf infer-linux64-v{{ infer_version }}.tar.xz
  ls
  rm infer-linux64-v{{ infer_version }}.tar.xz
  file ./infer-linux64-v{{ infer_version }}/bin/infer
  ./infer-linux64-v{{ infer_version }}/bin/infer --version

install-pmd:
  wget https://github.com/pmd/pmd/releases/download/pmd_releases%2F{{pmd_version}}/pmd-dist-{{pmd_version}}-bin.zip
  unzip pmd-dist-{{pmd_version}}-bin.zip
  rm pmd-dist-{{pmd_version}}-bin.zip

run-infer path:
  infer-linux64-v{{infer_version}}/bin/infer --racerd-only --compilation-database {{ path }}

pvs_cre:
  {{ pvs_name }}/bin/pvs-studio-analyzer credentials PVS-Studio {{ pvs_cre_type }} {{ pvs_credentials }}

install-libgit2:
  wget {{libgit2_url}}
  tar xf {{libgit2_tar}}

install-zlib:
  wget {{libz_url}}
  tar xf {{libz_tar}}

config-examples:
  cmake -GNinja -Bexamples-build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Release tests 

# build example tests under tests folder by using meson
build-examples:
  time ninja -C examples-build

build-libgit2:
  rm -rf libgit2-build
  CC="zig cc" CXX="zig c++" cmake -GNinja -Blibgit2-build -DCMKAE_C_FLAGS="-Dtarget={{zig_target}}" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTS=OFF -DBUILD_CLAR=OFF libgit2-{{libgit_version}}
  ninja -C libgit2-build
  cmake --install libgit2-build --prefix libgit2

build-zlib:
  rm -rf zlib-build zlib
  CC="zig cc" CXX="zig c++" cmake -GNinja -Bzlib-build -DCMAKE_C_FLAGS="-Dtarget={{zig_target}}" -DCMAKE_BUILD_TYPE=Release -DZLIB_BUILD_EXAMPLES=OFF -DCMAKE_INSTALL_PREFIX=$PWD/zlib zlib-{{zlib_version}}
  cmake --build zlib-build
  mkdir zlib
  mv zlib-build/libz.a zlib

update-stringzilla:
  wget https://raw.githubusercontent.com/ashvardanian/StringZilla/main/include/stringzilla/stringzilla.h
  mv stringzilla.h src
  zig translate-c src/stringzilla.h -I/usr/include > src/stringzilla.zig

