#!/bin/bash
# WebAssembly 向けの FFmpeg を Emscripten で組む。BtbN のスクリプトは wasm を持たないので、ここで組む。
# 外部ライブラリは使わず、静的ライブラリ 4 本 (avformat・avcodec・swresample・avutil) にする。
#
# 引数: <FFmpeg のソース> <作業の置き場> <出力の置き場>
#   作業の置き場は空であること
# 環境変数:
#   FF_CONFIGURE  部品の選び方 (configure.txt を展開したもの)
#   emcc ほか Emscripten の道具が PATH にあること (ワークフローが版を固定した emsdk を入れる)
# 出力: <出力>/include、<出力>/lib/lib*.a、<作業>/configure-command.txt (configure に渡した引数)
set -euo pipefail

src="$(realpath "$1")"
work="$(realpath -m "$2")"
out="$(realpath -m "$3")"
: "${FF_CONFIGURE:?}"

mkdir -p "$work"
if [[ -n "$(ls -A "$work")" ]]; then
    echo "作業の置き場が空ではありません: ${work}"
    exit 1
fi

emcc --version | head -1

# 向け先とツールチェーン。部品の選び方は FF_CONFIGURE (後に書いた引数が勝つので、後ろに置く)。
# -msimd128 は wasm の SIMD (Safari 16.4 から)。FFmpeg の simd128 の実装はいまは HEVC のデコーダーだけ
args=(
    --prefix="$work/install"
    --target-os=none --arch=wasm --enable-cross-compile
    --cc=emcc --cxx=em++ --ar=emar --ranlib=emranlib --nm=emnm
    --extra-cflags="-O3 -msimd128" --extra-ldflags="-O3"
)
set -f
# shellcheck disable=SC2206 # FF_CONFIGURE は空白で区切り、引用符を持たない
args+=($FF_CONFIGURE)
set +f
# 記録用。引用が要る引数だけを引用する
command=./configure
for arg in "${args[@]}"; do
    if [[ "$arg" =~ ^[A-Za-z0-9_./=,:+@-]+$ ]]; then
        command+=" ${arg}"
    else
        command+=" $(printf '%q' "$arg")"
    fi
done
echo "$command" > "$work/configure-command.txt"

mkdir "$work/ffmpeg"
cd "$work/ffmpeg"
emconfigure "$src/configure" "${args[@]}"
emmake make -j"$(nproc)"
emmake make install

# 版の表示はタグで決まる (git describe)。DamukoPla の取り込みは版の表示がタグで始まることを確かめる
grep FFMPEG_VERSION libavutil/ffversion.h

rm -rf "$out"
mkdir -p "$out/lib"
cp -a "$work/install/include" "$out/"
find "$work/install/lib" -maxdepth 1 -name 'lib*.a' -exec cp {} "$out/lib/" \;
ls -l "$out/lib"
