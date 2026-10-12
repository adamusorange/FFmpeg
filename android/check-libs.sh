#!/bin/bash
# 組んだ .so が、APK に入れて Android 15 以降で読めるものかを確かめる。
# 引数: <lib の置き場 (lib*.so)>
# 環境変数: READELF (NDK の llvm-readelf)
#
# - 6 本だけで、名前と SONAME が版の付かない lib<名前>.so (Gradle が APK に入れられるのはこの形だけ)
# - NEEDED は 6 本どうしと、端末にある libc・libm・libdl だけ (依存は静的に抱える)
# - AArch64 で、LOAD セグメントの整列が 16 KB (Android 15 以降の 16 KB ページ)
# - テキストの再配置 (TEXTREL) が無い
# - 記号 (.symtab) とデバッグ情報が落ちている
set -euo pipefail
dir="$1"
: "${READELF:?}"
fail=0

error() {
    echo "::error::$*"
    fail=1
}

libs="avcodec avfilter avformat avutil swresample swscale"
expected_files="$(for l in $libs; do echo "lib${l}.so"; done | sort | xargs)"
actual_files="$(find "$dir" -mindepth 1 -maxdepth 1 -printf '%f\n' | sort | xargs)"
if [[ "$actual_files" != "$expected_files" ]]; then
    error "lib の中身が想定と違います: [${actual_files}] (想定 [${expected_files}])"
fi

allowed_needed=" libc.so libm.so libdl.so ${expected_files} "

for so in "$dir"/lib*.so; do
    name="$(basename "$so")"
    dynamic="$("$READELF" -dW "$so")"

    machine="$("$READELF" -hW "$so" | sed -n 's/^ *Machine: *//p')"
    [[ "$machine" == AArch64 ]] || error "${name}: AArch64 ではありません (${machine})"

    soname="$(sed -n 's/.*(SONAME) *Library soname: \[\(.*\)\]$/\1/p' <<< "$dynamic")"
    [[ "$soname" == "$name" ]] || error "${name}: SONAME が ${soname:-(なし)} です"

    needed="$(sed -n 's/.*(NEEDED) *Shared library: \[\(.*\)\]$/\1/p' <<< "$dynamic" | xargs)"
    for n in $needed; do
        [[ "$allowed_needed" == *" $n "* ]] || error "${name}: 想定しない NEEDED ${n} があります"
    done

    if grep -q '(TEXTREL)' <<< "$dynamic" || grep -Eq '\(FLAGS\).*TEXTREL' <<< "$dynamic"; then
        error "${name}: テキストの再配置 (TEXTREL) があります"
    fi

    # LOAD の行の末尾が整列 (Align)
    aligns="$("$READELF" -lW "$so" | awk '$1 == "LOAD" { print $NF }' | sort -u | xargs)"
    if [[ -z "$aligns" ]]; then
        error "${name}: LOAD セグメントが見つかりません"
    fi
    for a in $aligns; do
        (( a >= 0x4000 )) || error "${name}: LOAD セグメントの整列が 16 KB 未満です (${a})"
    done

    sections="$("$READELF" -SW "$so")"
    if grep -Eq ' \.(symtab|debug_[a-z_]+) ' <<< "$sections"; then
        error "${name}: 記号かデバッグ情報が残っています"
    fi

    printf '%-18s %10d bytes  SONAME %s  NEEDED %s  LOAD align %s\n' \
        "$name" "$(stat -c %s "$so")" "$soname" "$needed" "$aligns"
done

exit "$fail"
