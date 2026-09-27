# slim の構成のビルド用イメージ。写した BtbN のイメージから派生させる。
#
# BtbN が組んだ依存 (/opt/ffbuild) を消し、sources.txt の依存だけを正式リリースから組み直す。
# コンパイラと mingw-w64 はイメージのものをそのまま使う。
# FF_CONFIGURE ほかを差し替え、BtbN の build.sh がこの構成で組むようにする。
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG FF_CONFIGURE
COPY . /slim
RUN bash /slim/build-deps.sh && rm -rf /slim

# soxr は OpenMP なしで組むので、-lgomp / -pthread は要らない
ENV FF_CONFIGURE="${FF_CONFIGURE}" \
    FF_CFLAGS="" \
    FF_CXXFLAGS="" \
    FF_LDFLAGS="" \
    FF_LDEXEFLAGS="" \
    FF_LIBS=""
