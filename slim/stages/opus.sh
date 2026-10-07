#!/bin/bash
# BtbN の scripts.d/50-libopus.sh と同じ組み方。正式リリースの tarball は configure と DNN の重みを含むので、
# autogen.sh (重みを取りに行く) は回さない

ffbuild_dockerbuild() {
    tar xf /slim/sources/opus.tar.* --strip-components=1

    ./configure --prefix="$FFBUILD_PREFIX" --host="$FFBUILD_TOOLCHAIN" \
        --disable-shared --enable-static --disable-extra-programs --disable-doc
    make -j"$(nproc)"
    make install DESTDIR="$FFBUILD_DESTDIR"
}
