#!/bin/bash
# wasm の configure の要約が、決めた構成になっているかを確かめる (slim/check-configure.sh の wasm 版)。
# 引数: build.sh の出力 (configure が出す要約を含む)
#
# 要らないものが入っていないことは一覧を丸ごと比べる。要るものが外れていないことは、
# 警告 (求めたものが外れると出る) が無いことと、ここの一覧の両方で見る。
# --fatal-warnings は --disable-pthreads のスレッドの警告で必ず止まるので使わず、その警告だけを許す。
set -euo pipefail
log="$1"
fail=0

# 見出しの次の行から空行までを、1 語ずつ並べる
section() {
    awk -v h="$1" '
        $0 == h { on = 1; next }
        on && /^[[:space:]]*$/ { exit }
        on { for (i = 1; i <= NF; i++) print $i }
    ' "$log" | sort
}

# 見出しの一覧が、期待する語 (空白区切り) とちょうど同じであること
expect_exactly() {
    local actual expected
    actual="$(section "$1" | xargs)"
    expected="$(tr ' ' '\n' <<< "$2" | sed '/^$/d' | sort | xargs)"
    if [[ "$actual" != "$expected" ]]; then
        echo "::error::$1 が想定と違います: [$actual] (想定 [$expected])"
        fail=1
    fi
}

# 要約の 1 行 (項目と値) があること
expect_line() {
    if ! grep -Eq "^$1 +$2\$" "$log"; then
        echo "::error::$1 が $2 ではありません"
        fail=1
    fi
}

if ! grep -q '^External libraries:$' "$log"; then
    echo "::error::configure の要約が出力にありません"
    exit 1
fi

allowed_warning='WARNING: Threading support was disabled or is not available on the target platform.'
while IFS= read -r line; do
    if [[ "$line" != "$allowed_warning"* ]]; then
        echo "::error::configure の警告: ${line}"
        fail=1
    fi
done < <(grep '^WARNING:' "$log" || true)

expect_exactly 'External libraries:' ''
expect_exactly 'External libraries providing hardware acceleration:' ''
expect_exactly 'Libraries:' 'avcodec avformat avutil swresample'
expect_exactly 'Programs:' ''
expect_exactly 'Enabled hwaccels:' ''
expect_exactly 'Enabled protocols:' ''
expect_exactly 'Enabled filters:' ''
expect_exactly 'Enabled indevs:' ''
expect_exactly 'Enabled outdevs:' ''
expect_exactly 'Enabled demuxers:' 'aac avi flac matroska mov mp3 mpegts ogg wav'
expect_exactly 'Enabled muxers:' 'mov mp4'
expect_exactly 'Enabled encoders:' 'aac'
expect_exactly 'Enabled decoders:' '
    aac ac3 alac dca eac3 flac mp2 mp3 opus pcm_f32le pcm_s16le pcm_s24le truehd vorbis'
expect_exactly 'Enabled parsers:' 'aac ac3 av1 dca flac h264 hevc mlp mpegaudio opus vorbis'
# vp9_superframe は mp4 の muxer が引き込む
expect_exactly 'Enabled bsfs:' 'aac_adtstoasc extract_extradata vp9_superframe'

expect_line 'ARCH' 'wasm \(generic\)'
expect_line 'threading support' 'no'
expect_line 'network support' 'no'
expect_line 'debug symbols' 'no'
expect_line 'static' 'yes'
expect_line 'shared' 'no'

exit "$fail"
