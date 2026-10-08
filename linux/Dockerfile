# linux64 のビルド用イメージ。写した BtbN のイメージから派生させる。
#
# BtbN の最新は nv-codec-headers 13.1 (ドライバー 610 以上) で組むので、Windows 版の slim と同じ
# 13.0.19.1 (ドライバー 570 以上) に差し替える。ヘッダーと .pc だけなので、ほかの依存と構成 (FF_CONFIGURE) は
# BtbN のまま。ビルドの文脈はワークフローのコミットの根 (slim/ の段と、取った tarball を使う)
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY slim /slim
COPY linux /linux
RUN bash /linux/build-deps.sh && rm -rf /slim /linux
