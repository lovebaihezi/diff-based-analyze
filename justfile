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
llvm_version    := "17.0.6"
llvm_url        := "https://github.com/llvm/llvm-project/releases/download/llvmorg-" + llvm_version + "/clang+llvm-" + llvm_version + "-x86_64-linux-gnu-ubuntu-22.04.tar.xz"
llvm_src_version:= "18.1.7"
llvm_src_url    := "https://github.com/llvm/llvm-project/releases/download/llvmorg-" + llvm_src_version + "/llvm-project-" + llvm_src_version + ".src.tar.xz"

install-tools: install-pmd install-infer install-pvs

install-deps: install-libgit2 install-zlib

install-llvm:
  wget {{llvm_url}}
  tar xf clang+llvm-{{llvm_version}}-x86_64-linux-gnu-ubuntu-22.04.tar.xz

fetch-llvm:
  wget {{llvm_src_url}}
  tar xf llvm-project-{{llvm_src_version}}.src.tar.xz

build-llvm:
  # cd llvm-project-{{llvm_src_version}}.src
  CC="$(pwd)/script/zig-cc" CXX="$(pwd)/script/zig-cxx" cmake -S llvm-project-{{llvm_src_version}}.src/llvm -G Ninja -B build -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_PROJECTS="llvm,clang,clang-tools-extra"
  ninja -C build

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
  cmake -GNinja -Bexamples-build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Release tests

# build example tests under tests folder by using meson
build-examples: config-examples
  time ninja -C examples-build

build-lib:
  clang++ -o compile2ir.o -c src/compile2ir.cpp
  ar rcs libcompile2ir.a compile2ir.o ./zlib/libz.a ./llvm/lib/libclangTooling.a ./llvm/lib/libclangFrontend.a ./llvm/lib/libclangFrontendTool.a ./llvm/lib/libclangDriver.a ./llvm/lib/libclangSerialization.a ./llvm/lib/libclangCodeGen.a ./llvm/lib/libclangParse.a ./llvm/lib/libclangSema.a ./llvm/lib/libclangStaticAnalyzerFrontend.a ./llvm/lib/libclangStaticAnalyzerCheckers.a ./llvm/lib/libclangStaticAnalyzerCore.a ./llvm/lib/libclangAnalysis.a ./llvm/lib/libclangARCMigrate.a ./llvm/lib/libclangRewrite.a ./llvm/lib/libclangRewriteFrontend.a ./llvm/lib/libclangEdit.a ./llvm/lib/libclangAST.a ./llvm/lib/libclangLex.a ./llvm/lib/libclangBasic.a ./llvm/lib/libLLVMCore.a ./llvm/lib/libLLVMCodeGen.a ./llvm/lib/libLLVMSupport.a ./llvm/lib/libLLVMCodeGenTypes.a ./llvm/lib/libLLVMIRReader.a ./llvm/lib/libLLVMIRPrinter.a ./llvm/lib/libLLVMCoverage.a

build-libgit2:
  rm -rf libgit2-build
  cmake -GNinja -Blibgit2-build -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTS=OFF -DBUILD_CLAR=OFF libgit2-{{libgit_version}}
  ninja -C libgit2-build
  cmake --install libgit2-build --prefix libgit2

build-zlib:
  rm -rf zlib-build zlib
  cmake -GNinja -Bzlib-build -DCMAKE_BUILD_TYPE=Release -DZLIB_BUILD_EXAMPLES=OFF -DCMAKE_INSTALL_PREFIX=$PWD/zlib zlib-{{zlib_version}}
  cmake --build zlib-build
  mkdir zlib
  mv zlib-build/libz.a zlib

update-stringzilla:
  wget https://raw.githubusercontent.com/ashvardanian/StringZilla/main/include/stringzilla/stringzilla.h
  mv stringzilla.h src
  zig translate-c src/stringzilla.h -I/usr/include > src/stringzilla.zig

fetch-cocci:
  git clone https://github.com/coccinelle/coccinellery
