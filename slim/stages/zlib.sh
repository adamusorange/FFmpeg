#!/bin/bash
# BtbN の scripts.d/20-zlib.sh と同じ組み方

ffbuild_dockerbuild() {
    tar xf /slim/sources/zlib.tar.* --strip-components=1

    ./configure --prefix="$FFBUILD_PREFIX" --static
    make -j"$(nproc)"
    make install DESTDIR="$FFBUILD_DESTDIR"
}
