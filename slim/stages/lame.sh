#!/bin/bash
# BtbN の scripts.d/50-libmp3lame.sh と同じ組み方。正式リリースの tarball は configure を含む。
# 使うのはエンコーダーだけなので、フロントエンドとデコーダーは組まない (libiconv も要らない)

ffbuild_dockerbuild() {
    tar xf /slim/sources/lame.tar.* --strip-components=1

    export CFLAGS="$CFLAGS -DNDEBUG"
    ./configure --prefix="$FFBUILD_PREFIX" --host="$FFBUILD_TOOLCHAIN" \
        --disable-shared --enable-static --disable-cpml --disable-frontend --disable-decoder
    make -j"$(nproc)"
    make install DESTDIR="$FFBUILD_DESTDIR"
}
