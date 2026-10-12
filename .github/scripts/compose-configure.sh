#!/bin/bash
# configure の引数のファイル (slim/configure.txt、android/configure.txt) を 1 行に展開し、足す引数をつなぐ。
# 引数: <configure の引数のファイル> [足す引数 (空白区切り)]
# 出力: 標準出力に 1 行
#
# configure は、--enable-<種類>=<名前> で求めた部品が後から外れると「Disabled ... because」と警告し、
# --fatal-warnings で止まる。足す引数で外す部品 (--disable-<種類>=<名前>) は、元の構成の --enable-<種類>=... から抜いておく
set -euo pipefail

ff_configure="$(sed 's/#.*//' "$1" | xargs)"
extra_configure="${2:-}"

set -f
for extra in $extra_configure; do
    [[ "$extra" =~ ^--disable-([a-z]+)=(.+)$ ]] || continue
    kind="${BASH_REMATCH[1]}"
    IFS=',' read -ra names <<< "${BASH_REMATCH[2]}"
    rebuilt=()
    for arg in $ff_configure; do
        if [[ "$arg" != --enable-"$kind"=* ]]; then
            rebuilt+=("$arg")
            continue
        fi
        IFS=',' read -ra items <<< "${arg#*=}"
        kept=()
        for item in "${items[@]}"; do
            drop=
            for name in "${names[@]}"; do
                [[ "$item" == "$name" ]] && drop=1
            done
            [[ -n "$drop" ]] || kept+=("$item")
        done
        if (( ${#kept[@]} )); then
            rebuilt+=("--enable-${kind}=$(IFS=,; echo "${kept[*]}")")
        fi
    done
    ff_configure="${rebuilt[*]}"
done
set +f

# 後に書いた引数が勝つので、足す引数は末尾に置く
[[ -z "$extra_configure" ]] || ff_configure="${ff_configure} ${extra_configure}"
echo "$ff_configure"
