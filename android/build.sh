#!/bin/bash
# Android (arm64-v8a) 向けの FFmpeg を NDK で組む。BtbN のスクリプトは Android を持たないので、ここで組む。
# 依存 (zlib・soxr・dav1d) を静的に組んでから、FFmpeg を LGPL の .so 6 本にする。
#
# 引数: <依存の tarball の置き場> <FFmpeg のソース> <作業の置き場> <出力の置き場>
#   tarball は <名前>.tar.xz か .tar.gz (ワークフローが SHA-256 を確かめて置く)。作業の置き場は空であること
# 環境変数:
#   ANDROID_NDK_ROOT  NDK (ワークフローが版を固定して置く)
#   ANDROID_API       API レベル (DamukoPla の minSdk)
#   ANDROID_DEPS      組む依存の名前 (slim/sources.txt の名前)。この順に組む
#   FF_CONFIGURE      部品の選び方 (configure.txt を展開したもの)
# 出力: <出力>/include、<出力>/lib/lib*.so、<作業>/configure-command.txt (configure に渡した引数)
set -euo pipefail

sources="$(realpath "$1")"
src="$(realpath "$2")"
work="$(realpath -m "$3")"
out="$(realpath -m "$4")"
: "${ANDROID_NDK_ROOT:?}" "${ANDROID_API:?}" "${ANDROID_DEPS:?}" "${FF_CONFIGURE:?}"

mkdir -p "$work"
if [[ -n "$(ls -A "$work")" ]]; then
    echo "作業の置き場が空ではありません: ${work}"
    exit 1
fi

tc="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin"
export CC="$tc/aarch64-linux-android${ANDROID_API}-clang"
export CXX="$tc/aarch64-linux-android${ANDROID_API}-clang++"
export AR="$tc/llvm-ar" NM="$tc/llvm-nm" RANLIB="$tc/llvm-ranlib" STRIP="$tc/llvm-strip"
"$CC" --version | head -1

# 依存は静的ライブラリにして .so に抱える。.so に入るので PIC で組む
deps="$work/deps"
mkdir -p "$deps"
# 組む機械の .pc を拾わない
export PKG_CONFIG_LIBDIR="$deps/lib/pkgconfig"
unset PKG_CONFIG_PATH

# slim/stages/zlib.sh と同じく、zlib の configure で組む
build_zlib() {
    CFLAGS="-O3 -fPIC" ./configure --prefix="$deps" --static
    make -j"$(nproc)"
    make install
}

# slim/stages/soxr.sh と同じく OpenMP なし。CMake は NDK のツールチェーンで組む
build_soxr() {
    # 古い cmake_minimum_required を、いまの CMake が受け付ける形にする
    sed -i 's/VERSION 3.1 /VERSION 3.1...3.10 /g' CMakeLists.txt
    cmake -S . -B build -G Ninja \
        -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake" \
        -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM="android-${ANDROID_API}" \
        -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$deps" -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DWITH_OPENMP=OFF -DWITH_LSR_BINDINGS=OFF \
        -DBUILD_TESTS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_SHARED_LIBS=OFF
    cmake --build build
    cmake --install build
}

# slim/stages/dav1d.sh と同じく、使わない道具とテストは組まない。meson はクロスファイルで NDK の clang を使う
build_dav1d() {
    cat > cross.meson << EOF
[binaries]
c = '${CC}'
cpp = '${CXX}'
ar = '${AR}'
strip = '${STRIP}'

[host_machine]
system = 'android'
cpu_family = 'aarch64'
cpu = 'armv8-a'
endian = 'little'
EOF
    meson setup build --cross-file=cross.meson \
        --prefix="$deps" --libdir=lib --buildtype=release --default-library=static -Db_staticpic=true \
        -Denable_tools=false -Denable_tests=false
    ninja -C build
    ninja -C build install
}

for name in $ANDROID_DEPS; do
    echo "== ${name}"
    tarball="$(find "$sources" -maxdepth 1 -name "${name}.tar.*" | head -1)"
    test -n "$tarball"
    mkdir "$work/$name"
    tar xf "$tarball" -C "$work/$name" --strip-components=1
    (cd "$work/$name" && "build_${name}") < /dev/null
done
find "$deps" -type f | sort

echo "== ffmpeg"
# 向け先とツールチェーン。部品の選び方は FF_CONFIGURE (後に書いた引数が勝つので、後ろに置く)
args=(
    --prefix="$work/install"
    --target-os=android --arch=aarch64 --enable-cross-compile --enable-pic
    --cc="$CC" --cxx="$CXX" --ar="$AR" --nm="$NM" --ranlib="$RANLIB" --strip="$STRIP"
    --pkg-config=pkg-config --pkg-config-flags=--static
    --extra-cflags="-I$deps/include" --extra-ldflags="-L$deps/lib"
    # configure は libsoxr を -lsoxr だけで確かめるが、静的な libsoxr は libm を要る
    --extra-libs=-lm
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
"$src/configure" "${args[@]}"
make -j"$(nproc)"
make install

# 版の表示はタグで決まる (git describe)。DamukoPla の取り込みは版の表示がタグで始まることを確かめる
grep FFMPEG_VERSION libavutil/ffversion.h

rm -rf "$out"
mkdir -p "$out/lib"
cp -a "$work/install/include" "$out/"
find "$work/install/lib" -maxdepth 1 -name 'lib*.so' -exec cp {} "$out/lib/" \;
ls -l "$out/lib"
