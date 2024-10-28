set shell := ["bash", "-uc"]
libgit_version  := "1.7.2"
libgit2_tar     := "v" + libgit_version + ".tar.gz"
libgit2_url     := "https://github.com/libgit2/libgit2/archive/refs/tags/" + libgit2_tar
zlib_version    := "1.3.1"
libz_tar        := "zlib-" + zlib_version + ".tar.gz"
libz_url        := "https://github.com/madler/zlib/releases/download/v" + zlib_version + "/" + libz_tar
infer_version   := "1.1.0"
pmd_version     := "7.0.0"
zig_target      := "native-native-gnu"
pvs_name        := "pvs-studio-7.29.79138.387-x86_64"
pvs_tar         := pvs_name + ".tgz"
pvs_url         := "https://cdn.pvs-studio.com/" + pvs_tar
pvs_cre_type    := "Free"
pvs_credentials := "FREE-FREE-FREE-FREE"
coverity_url    := "https://scan.coverity.com/download/cxx/linux64"
llvm_url        := "https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.2/LLVM-19.1.2-Linux-X64.tar.xz"
llvm_src_version:= "18.1.8"
llvm_src_url    := "https://github.com/llvm/llvm-project/releases/download/llvmorg-" + llvm_src_version + "/llvm-project-" + llvm_src_version + ".src.tar.xz"

install-tools: install-pmd install-infer install-pvs

init-deps: install-libgit2 install-zlib install-llvm

install-deps: build-libgit2 build-zlib

mkpkgs:
  mkdir pkgs

install-llvm:
  rm -rf llvm
  wget {{llvm_url}}
  tar xf LLVM-19.1.2-Linux-X64.tar.xz
  mv LLVM-19.1.2-Linux-X64 llvm

install-pvs:
  wget {{ pvs_url }}
  tar xf {{ pvs_tar }}

install-infer:
  #!/usr/bin/env bash
  git clone https://github.com/facebook/infer.git
  cd infer
  # Compile Infer
  ./build-infer.sh clang
  # install Infer system-wide...
  cp -a infer/bin/* /usr/bin/
  cp -a infer/lib/* /usr/lib/
  infer --version

install-pmd:
  #!/usr/bin/env bash
  wget https://github.com/pmd/pmd/releases/download/pmd_releases%2F{{pmd_version}}/pmd-dist-{{pmd_version}}-bin.zip
  unzip pmd-dist-{{pmd_version}}-bin.zip
  rm pmd-dist-{{pmd_version}}-bin.zip

run-infer path:
  #!/usr/bin/env bash
  infer --racerd-only --compilation-database {{ path }}

pvs_cre:
  #!/usr/bin/env bash
  {{ pvs_name }}/bin/pvs-studio-analyzer credentials PVS-Studio {{ pvs_cre_type }} {{ pvs_credentials }}

install-libgit2:
  #!/usr/bin/env bash
  wget {{libgit2_url}}
  tar xf {{libgit2_tar}}

install-zlib:
  #!/usr/bin/env bash
  wget {{libz_url}}
  tar xf {{libz_tar}}

config-examples:
  #!/usr/bin/env bash
  echo $CC $CXX
  cmake -GNinja -Bexamples-build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Debug tests

# build example tests under tests folder by using meson
build-examples: config-examples
  time ninja -C examples-build

build-libgit2:
  rm -rf libgit2-build
  cmake -GNinja -Blibgit2-build -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTS=OFF -DBUILD_CLAR=OFF libgit2-{{libgit_version}}
  mold -run ninja -C libgit2-build

build-zlib:
  rm -rf zlib-build zlib
  cmake -GNinja -Bzlib-build -DCMAKE_BUILD_TYPE=Release -DZLIB_BUILD_EXAMPLES=OFF -DCMAKE_INSTALL_PREFIX=$PWD/zlib zlib-{{zlib_version}}
  mold -run ninja -C zlib-build

update-stringzilla:
  wget https://raw.githubusercontent.com/ashvardanian/StringZilla/main/include/stringzilla/stringzilla.h
  mv stringzilla.h src
  zig translate-c src/stringzilla.h -I/usr/include > src/stringzilla.zig

fetch-cocci:
  git clone https://github.com/coccinelle/coccinellery

fetch-micros:
  git clone https://github.com/microsoft/Detours
  git clone https://github.com/phusion/passenger
  git clone https://github.com/NVIDIA/DALI
  git clone https://github.com/lballabio/QuantLib
  git clone https://github.com/aircrack-ng/aircrack-ng
  git clone https://github.com/vmg/redcarpet
  git clone https://github.com/emcrisostomo/fswatch
  git clone https://github.com/wjakob/instant-meshes
  git clone https://github.com/jagt/clumsy
  git clone https://github.com/leethomason/tinyxml2
  git clone https://github.com/zcash/zcash
  git clone https://github.com/cuberite/cuberite
  git clone https://github.com/itinance/react-native-fs
  git clone https://github.com/Zelda64Recomp/Zelda64Recomp
  git clone https://github.com/immortalwrt/immortalwrt
  git clone https://github.com/visit1985/mdp
  git clone https://github.com/jbeder/yaml-cpp
  git clone https://github.com/gnuradio/gnuradio
  git clone https://github.com/mlpack/mlpack
  git clone https://github.com/guanzhi/GmSSL
  git clone https://github.com/NVIDIA/cccl
  git clone https://github.com/littlefs-project/littlefs
  git clone https://github.com/antirez/sds
  git clone https://github.com/rhasspy/piper

# Build Analysis Tool
build-all:
    CC=$PWD/llvm/bin/clang CXX=$PWD/llvm/bin/clang++ cmake \
      -GNinja \
      -Bbuild \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_PREFIX_PATH=$PWD/llvm
    ninja -C build

# Run Analysis Tests
run-analysis-tests:
    ./build/analysis/tests

# Clean up All local builds
clean-all:
    cmake --build build --target clean

# Clean up All local build everything
full-clean-all:
    rm -rf build

# Format the code
format:
    clang-format --style=file -i $(fd --extension cpp --extension hpp)
    # clang-format --style=file -i $(fd --extension c --extension h)
