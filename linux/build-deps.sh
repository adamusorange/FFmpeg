#!/bin/bash
# nv-codec-headers を /slim/sources/ffnvcodec.tar.* (ワークフローが SHA-256 を確かめて置く) で差し替える。
# 組み方は slim と同じ段 (slim/stages/ffnvcodec.sh) を BtbN の run_stage で回す
set -euo pipefail

want="$(awk '$1 == "ffnvcodec" { print $2 }' /slim/sources.txt)"
test -n "$want"

rm -rf "$FFBUILD_PREFIX/include/ffnvcodec" "$FFBUILD_PREFIX/lib/pkgconfig/ffnvcodec.pc"
STAGENAME="linux-ffnvcodec" SELF="/slim/stages/ffnvcodec.sh" run_stage "/slim/stages/ffnvcodec.sh" < /dev/null
cp -a "$FFBUILD_DESTPREFIX"/. "$FFBUILD_PREFIX"
rm -rf "$FFBUILD_DESTDIR"

got="$(sed -n 's/^Version: *//p' "$FFBUILD_PREFIX/lib/pkgconfig/ffnvcodec.pc")"
if [[ "$got" != "$want" ]]; then
    echo "nv-codec-headers の版が違います: ${got} (求めたのは ${want})"
    exit 1
fi
echo "nv-codec-headers ${got}"
