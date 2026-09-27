# FFmpeg (DamukoPla 用の fork)

[DamukoPla](https://github.com/adamusorange/DamukoPla) が同梱する FFmpeg のソースとビルドの置き場所。
上流は https://github.com/FFmpeg/FFmpeg 。

This is a fork of FFmpeg used by DamukoPla. The only change is `MAX_SLICES` raised to 256 for the
H.264 hwaccels. Binaries are LGPL-2.1+ builds; their exact sources are the tags listed below.

## 上流からの変更

| タグ | 内容 |
|---|---|
| `n9.0.1-damuko-9b0578816c` | 上流の `9b0578816c` (release/9.0) そのまま。比較用 |
| `n9.0.1-damuko-9b0578816c-slices256` | 上に `libavcodec/h264dec.h` の `MAX_SLICES` を 32 から 256 にする 1 行を足したもの |

- `MAX_SLICES` は D3D11VA / DXVA2 / D3D12VA の H.264 が 1 枚の絵で受け取るスライスの上限。
  超えた分は警告なしに捨てられ、絵の下側が欠ける
  ([DamukoPla#77](https://github.com/adamusorange/DamukoPla/issues/77))
- LAV Filters の FFmpeg (`8e3fff75` "h264: increase MAX_SLICES to 256") と同じ変更
- 変更を載せる枝は `damuko/release-9.0`

## ビルド

GitHub Actions で組み、リリースに上げる。この枝 (`damukopla`) にはワークフローだけを置く。

1. `Copy build image` (`copy-image.yml`): BtbN/FFmpeg-Builds のビルド用イメージを、この fork の ghcr へ写す。
   出た digest を `build.yml` の `BUILD_IMAGE` に書く
2. `Build FFmpeg` (`build.yml`): 入力のタグを、BtbN/FFmpeg-Builds のスクリプト (コミットで固定) で組む。
   スクリプトは改造せず、ソースの取得元だけを `FFMPEG_REPO_OVERRIDE` / `GIT_BRANCH_OVERRIDE` で差し替える

リリースには zip と、ソースのコミット・スクリプトのコミット・イメージの digest・zip の SHA-256 を書いた `.json` を置く。

## ライセンス

FFmpeg のソースは上流と同じく LGPL-2.1+ (一部 GPL)。リリースのビルドは LGPL 構成
(`--enable-gpl` / `--enable-nonfree` なし)。ワークフローのファイルも同じ条件で扱ってよい。
