#!/bin/bash
# BtbN の scripts.d/50-ffnvcodec.sh と同じ組み方 (ヘッダーと .pc を置くだけ)。
# NVENC の本体はドライバーの DLL で、実行時に読み込む。SDK 13.0 はドライバー 570 以上で動く

ffbuild_dockerbuild() {
    tar xf /slim/sources/ffnvcodec.tar.* --strip-components=1

    make PREFIX="$FFBUILD_PREFIX" DESTDIR="$FFBUILD_DESTDIR" install
}
