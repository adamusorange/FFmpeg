#!/bin/bash
# slim の configure の要約が、決めた構成になっているかを確かめる。
# 引数: build.sh の出力 (configure が出す要約を含む)
#
# 要らないものが入っていないことは一覧を丸ごと比べる。要るものが外れていないことは、
# --fatal-warnings (要求したものが外れると警告が出る) と、ここの両方で見る。
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

# 見出しの一覧に、期待する語がすべてあること
expect_contains() {
    local item
    for item in $2; do
        if ! section "$1" | grep -qx "$item"; then
            echo "::error::$1 に $item がありません"
            fail=1
        fi
    done
}

if ! grep -q '^External libraries:$' "$log"; then
    echo "::error::configure の要約が出力にありません"
    exit 1
fi

expect_exactly 'External libraries:' 'libdav1d libmp3lame libopus libsoxr zlib'
# cuda は NVENC が引き込む、実行時に読み込む CUDA の口 (SDK は要らない)
expect_exactly 'External libraries providing hardware acceleration:' 'cuda d3d11va ffnvcodec nvenc'
expect_exactly 'Libraries:' 'avcodec avfilter avformat avutil swresample swscale'
expect_exactly 'Enabled hwaccels:' '
    av1_d3d11va av1_d3d11va2 h264_d3d11va h264_d3d11va2 hevc_d3d11va hevc_d3d11va2
    mpeg2_d3d11va mpeg2_d3d11va2 vc1_d3d11va vc1_d3d11va2 vp9_d3d11va vp9_d3d11va2
    wmv3_d3d11va wmv3_d3d11va2'
expect_exactly 'Enabled protocols:' 'file pipe'
expect_exactly 'Enabled indevs:' ''
expect_exactly 'Enabled outdevs:' ''

# 選んだものが引き込む部品 (ffmpeg.exe が要るフィルタ、mpeg4 が要る h263 など) もあるので、
# ここは要るものがあることだけを見る
expect_contains 'Enabled filters:' 'aformat aresample atempo dynaudnorm format hwdownload hwupload scale scale_d3d11'
expect_contains 'Enabled encoders:' 'av1_nvenc flac h264_nvenc hevc_nvenc libmp3lame libopus mpeg4'
expect_contains 'Enabled muxers:' 'flac matroska mp3 mp4 ogg opus webm'

if ! grep -Eq '^threading support +w32threads$' "$log"; then
    echo "::error::スレッドの実装が w32threads ではありません"
    fail=1
fi

exit "$fail"
