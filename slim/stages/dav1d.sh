#!/bin/bash
# BtbN の scripts.d/50-dav1d.sh と同じ組み方。使わない道具とテストは組まない

ffbuild_dockerbuild() {
    tar xf /slim/sources/dav1d.tar.xz --strip-components=1

    mkdir build && cd build

    meson setup --prefix="$FFBUILD_PREFIX" --buildtype=release --default-library=static \
        -Denable_tools=false -Denable_tests=false \
        --cross-file=/cross.meson ..
    ninja -j"$(nproc)"
    DESTDIR="$FFBUILD_DESTDIR" ninja install
}
