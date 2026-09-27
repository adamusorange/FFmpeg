# FFmpeg (DamukoPla 用の fork)

[DamukoPla](https://github.com/adamusorange/DamukoPla) が同梱する FFmpeg のソースとビルドの置き場所。
上流は https://github.com/FFmpeg/FFmpeg 。

This is a fork of FFmpeg used by DamukoPla. The only functional change is `MAX_SLICES` raised to 256
for the H.264 hwaccels. Binaries are LGPL-2.1+ builds; their exact sources are the tags listed below.

## 上流からの変更

| タグ | 内容 |
|---|---|
| `n9.0.1-damuko-9b0578816c-oapvfix` | 上流の `9b0578816c` (release/9.0) に、上流の `a7502e5ff3` (openapv 1.1 で組めるようにする直し) を載せたもの。比較用 |
| `n9.0.1-damuko-9b0578816c-oapvfix-slices256` | 上に `libavcodec/h264dec.h` の `MAX_SLICES` を 32 から 256 にする 1 行を足したもの |

- `a7502e5ff3` は上流の release/9.0 にあるコミットの cherry-pick。ビルド用イメージの openapv が 1.1 に上がり、
  `9b0578816c` のままでは `liboapvenc.c` が組めないため
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
リリースのタグはソースのタグと同じ。同じタグを組み直しても、既にある資産は上書きしない。

## FFmpeg を更新するとき

1. 上流の新しいコミットから枝を切り、`damuko/release-9.0` の変更を載せ直す (上流に入った直しは外す)
2. タグを打つ。名前は `n<版>-damuko-<上流のコミット>[-<変更>]` とし、`n<版>-` で始める
   (FFmpeg は `git describe` で版の表示を決め、DamukoPla の取り込みは版の表示がタグで始まることを確かめる)
3. ビルド用イメージを新しくするなら `Copy build image` を回し、`build.yml` の `BUILD_IMAGE` を書き換える。
   BtbN のスクリプトのコミット (`BTBN_COMMIT`) も、そのイメージを作ったものに合わせる
4. `Build FFmpeg` をタグを指定して回す。比較用の組は `prerelease` を立てる
5. DamukoPla 側で `modules\player\scripts\fetch-ffmpeg.ps1` を回して取り込む

## ライセンス

FFmpeg のソースは上流と同じく LGPL-2.1+ (一部 GPL)。リリースのビルドは LGPL 構成
(`--enable-gpl` / `--enable-nonfree` なし)。ワークフローのファイルも同じ条件で扱ってよい。
