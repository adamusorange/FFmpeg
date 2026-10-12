#!/bin/bash
# android の configure の要約が、決めた構成になっているかを確かめる (slim/check-configure.sh の Android 版)。
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

# iconv は bionic (libc) のもの。configure は --disable-autodetect でも libc の iconv を探す (字幕の文字コードの変換に使う)
expect_exactly 'External libraries:' 'iconv libdav1d libsoxr zlib'
expect_exactly 'External libraries providing hardware acceleration:' ''
expect_exactly 'Libraries:' 'avcodec avfilter avformat avutil swresample swscale'
expect_exactly 'Programs:' ''
expect_exactly 'Enabled hwaccels:' ''
expect_exactly 'Enabled protocols:' 'file'
expect_exactly 'Enabled indevs:' ''
expect_exactly 'Enabled outdevs:' ''
expect_exactly 'Enabled filters:' 'aformat aresample atempo dynaudnorm format scale'
# mpeg4 は h263 を、mp4 は mov を引き込む
expect_exactly 'Enabled encoders:' 'h263 mpeg4'
expect_exactly 'Enabled muxers:' 'mov mp4'

expect_line 'threading support' 'pthreads'
expect_line 'network support' 'no'
expect_line 'debug symbols' 'no'
expect_line 'strip symbols' 'yes'

exit "$fail"
