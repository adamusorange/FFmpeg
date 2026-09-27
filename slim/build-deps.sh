#!/bin/bash
# slim の依存を、/slim/sources/<名前>.tar.xz から組んで $FFBUILD_PREFIX に入れる。
# Dockerfile から呼ぶ。tarball はワークフローが SHA-256 を確かめてから置く。
#
# 各段は BtbN の run_stage で回す (イメージに入っている)。BtbN の段と同じく、
# STAGE_CFLAGS を足し、.la を消し、静的ライブラリを strip する。
set -euo pipefail

# BtbN が組んだ依存を残すと、configure や pkg-config が取り違えるもとになる。
# mingw-w64 はここではなく sysroot にある。
rm -rf "$FFBUILD_PREFIX" "$FFBUILD_DESTDIR"
mkdir -p "$FFBUILD_PREFIX"

# 先に読み切る (組む道具に標準入力を食わせない)
mapfile -t names < <(awk '$1 !~ /^#/ && NF { print $1 }' /slim/sources.txt)
test "${#names[@]}" -gt 0

for name in "${names[@]}"; do
    STAGENAME="slim-$name" SELF="/slim/stages/$name.sh" run_stage "/slim/stages/$name.sh" < /dev/null
    cp -a "$FFBUILD_DESTPREFIX"/. "$FFBUILD_PREFIX"
    rm -rf "$FFBUILD_DESTDIR"
done

find "$FFBUILD_PREFIX" -type f | sort
