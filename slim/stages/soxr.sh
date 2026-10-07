#!/bin/bash
# BtbN の scripts.d/50-soxr.sh と同じ直しを当てる。違いは OpenMP を使わないこと。
# swresample は soxr にスレッドの数を渡さない (既定の 1 本) ので、OpenMP の有無で動きは変わらない。

ffbuild_dockerbuild() {
    tar xf /slim/sources/soxr.tar.* --strip-components=1

    # 古い cmake_minimum_required を、いまの CMake が受け付ける形にする
    sed -i 's/VERSION 3.1 /VERSION 3.1...3.10 /g' CMakeLists.txt

    # Windows でも .pc を作らせる
    sed -i 's/NOT WIN32/1/g' src/CMakeLists.txt

    mkdir build && cd build

    cmake -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX" \
        -DWITH_OPENMP=OFF -DWITH_LSR_BINDINGS=OFF \
        -DBUILD_TESTS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_SHARED_LIBS=OFF \
        ..
    make -j"$(nproc)"
    make install DESTDIR="$FFBUILD_DESTDIR"
}
