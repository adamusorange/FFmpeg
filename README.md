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

GitHub Actions で組み、リリースに上げる。この枝 (`damukopla`) にはワークフローと、構成のファイルだけを置く。

1. `Copy build image` (`copy-image.yml`): BtbN/FFmpeg-Builds のビルド用イメージを、この fork の ghcr へ写す。
   出た digest を `build.yml` の `BUILD_IMAGE` に書く
2. `Build FFmpeg` (`build.yml`): 入力のタグを、BtbN/FFmpeg-Builds のスクリプト (コミットで固定) で組む。
   スクリプトは改造せず、ソースの取得元を `FFMPEG_REPO_OVERRIDE` / `GIT_BRANCH_OVERRIDE` で差し替える。
   向け先 (`target`) と構成 (`config`) を選ぶ
3. `Build FFmpeg for Android` (`build-android.yml`): 入力のタグを、Android NDK で Android (arm64-v8a) 向けに組む。
   BtbN のスクリプトは Android を持たないので、`android/` のスクリプトで組む
4. `Build FFmpeg for WebAssembly` (`build-wasm.yml`): 入力のタグを、Emscripten で WebAssembly 向けに組む (`wasm/` のスクリプト)

| 向け先 | 構成 | 中身 | 資産名 | DamukoPla での使い道 |
|---|---|---|---|---|
| `win64` | `slim` | DamukoPla が使う部品だけ (`slim/configure.txt`) | `ffmpeg-<版>-win64-lgpl-shared-9.0-slim.zip` | 同梱する |
| `win64` | `full` | BtbN の `win64-lgpl-shared` の構成のまま | `ffmpeg-<版>-win64-lgpl-shared-9.0.zip` | 見本を作る道具 (同梱しない) |
| `linux64` | `full` | BtbN の `linux64-lgpl` (static) の構成のまま | `ffmpeg-<版>-linux64-lgpl-9.0.tar.xz` | メディアサーバー (x86-64) が変換に使う `ffmpeg` の CLI (DamukoPla#148) |
| `android-arm64` | `slim` | `slim` と同じ部品の選び方で、hwaccel と変換の部品を持たない (`android/configure.txt`) | `ffmpeg-<版>-android-arm64-lgpl-shared-9.0-slim.tar.xz` | Android 版が同梱する (DamukoPla#151) |
| `wasm32` | `wasm` | 分離・fMP4 への詰め直し・音声の作り直しの部品だけ (`wasm/configure.txt`) | `ffmpeg-<版>-wasm32-lgpl-static-9.0.tar.xz` | ブラウザ版の `player.wasm` に繋ぐ (DamukoPla#202) |

`linux64` は `full` だけを組む (`slim/` は mingw-w64 の構成)。サーバーは `ffmpeg` を子プロセスで回すだけなので、
1 つの実行ファイルで済む static にした。
BtbN の最新のイメージは nv-codec-headers 13.1 (NVIDIA のドライバー 610 以上) で組むので、`linux/Dockerfile` で
`slim` と同じ 13.0.19.1 (ドライバー 570 以上) に差し替えた派生イメージで組む (ヘッダーだけなので、ほかは BtbN のまま)。

`slim` は、写したイメージから `slim/Dockerfile` で派生イメージを作って組む。

- BtbN が組んだ依存を消し、`slim/sources.txt` の依存 (dav1d・soxr・zlib・nv-codec-headers・Opus・LAME) を正式リリースの tarball
  (SHA-256 で固定) から組み直す。組み方は `slim/stages/`。soxr は OpenMP なし
- 環境変数 `FF_CONFIGURE` を `slim/configure.txt` に差し替える (BtbN の `build.sh` はコンテナの中でこれを展開する)。
  `--fatal-warnings` で、要求した部品が外れたら configure で止める
- 組んだあと `slim/check-configure.sh` で、configure の要約 (外部ライブラリ・hwaccel・プロトコル・スレッドなど) を確かめる
- コンパイラと mingw-w64 はイメージのもの

`android-arm64` は `build-android.yml` が、ランナーに NDK を入れて組む (`android/build.sh`)。

- NDK と API レベルは DamukoPla の Android 版 (NDK r29 = 29.0.14206865、`minSdk` 35、arm64-v8a だけ) に合わせ、
  ワークフローで固定する。NDK の zip は SHA-256 で確かめる
- 依存 (dav1d・soxr・zlib) は `slim/sources.txt` と同じ tarball・SHA-256 から、NDK の clang で静的ライブラリに組んで .so に抱える。
  zlib は configure、soxr は CMake の NDK ツールチェーン (OpenMP なし)、dav1d は meson のクロスファイル
- 出すのは LGPL の .so 6 本 (avcodec・avformat・avutil・avfilter・swresample・swscale) とヘッダー。
  映像のハードウェアのデコードは DamukoPla が MediaCodec を FFmpeg を通さずに使うので、hwaccel は持たない。
  FFmpeg のソフトウェアデコードは、ハードウェアで解けない形式 (H.264 10 ビットなど) の逃げ道
- 部品: デマルチプレクサーとデコーダーはすべて。プロトコルは `file` だけ (再生は自前の `AVIOContext` で読む)。
  フィルタは `atempo`・`dynaudnorm`・`aresample`・`aformat`・`format`・`scale`。変換の部品 (NVENC・Opus・MP3) は持たない。
  `mpeg4` のエンコーダーと `mp4` の mux は単体テストが見本を作るのに使うので残す (外しても約 470 KB しか減らない)
- 外部ライブラリの iconv は bionic (libc) のもの。configure は `--disable-autodetect` でも libc の iconv を探す
- 組んだあと `android/check-configure.sh` で configure の要約を、`android/check-libs.sh` で .so を確かめる。
  .so は、名前と SONAME が版の付かない `lib<名前>.so` (Gradle が APK に入れられるのはこの形だけ)、
  NEEDED が 6 本どうしと libc・libm・libdl だけ、LOAD セグメントの整列が 16 KB (Android 15 以降)、
  テキストの再配置 (TEXTREL) が無いこと、記号とデバッグ情報が落ちていることを見る
- アーカイブ (tar.xz) の中身は `include/`・`lib/` (.so 6 本)・`LICENSE.txt` (LGPL 3)

`wasm32` は `build-wasm.yml` が、ランナーに emsdk を入れて組む (`wasm/build.sh`)。

- emsdk は DamukoPla の `build-web.ps1` と同じ 6.0.12 に、タグのコミットごとワークフローで固定する。`--arch=wasm`、`-O3 -msimd128`
- DamukoPla のブラウザ版は、映像を解かずに fMP4 へ詰め直して MSE に渡し、解く・鳴らすは OS に任せる (DamukoPla の plan 11.8)。
  FFmpeg が受け持つのは分離・詰め直しと、端末が鳴らせない音声を AAC に作り直すことだけ
- 出すのは LGPL の静的ライブラリ 4 本 (avformat・avcodec・swresample・avutil) とヘッダー。自前のコードと別の wasm に繋ぐ。
  外部ライブラリは使わない (Matroska・MOV の zlib で縮めたヘッダーは読めない)
- 部品
  - 分離: Matroska・WebM、MP4・MOV・M4A、MPEG-TS・M2TS、AVI と、音楽の MP3・AAC・FLAC・Ogg・WAV
  - パーサー: 映像は H.264・HEVC・AV1・VP9、音声は下のデコーダーの形式
  - bsf: `extract_extradata` (MPEG-TS などで映像の extradata を拾う)、`aac_adtstoasc`・`vp9_superframe` (mp4 の muxer が差し込む)
  - mux は `mp4`、エンコーダーは `aac`、デコーダーは音声だけ (AAC・AC-3・E-AC-3・MP3・MP2・Opus・Vorbis・FLAC・ALAC・PCM・TrueHD・DTS)。
    映像のデコーダー・プロトコル・avfilter・swscale は持たない
- スレッドは使わない (`--disable-pthreads`)。そのため configure が必ずスレッドの警告を出し、`--fatal-warnings` は使えない。
  `wasm/check-configure.sh` が、その警告のほかに WARNING が無いことと、要約の一覧を確かめる
- libc の iconv は `--disable-iconv` で外す (字幕の文字コードの変換に使うもので、字幕は解かない)
- アーカイブ (tar.xz) の中身は `include/`・`lib/` (.a 4 本)・`LICENSE.txt` (LGPL 3)

同じタグを構成を変えて組み直すとき (DamukoPla#147 で変換の部品を足したときなど) は、入力の `revision` に版を入れる。`slim`・`android-arm64`・`wasm32` の資産名に `-r<版>` が付き (`...-9.0-slim-r2.zip`)、前の資産と並ぶ。DamukoPla の取り込みは版の大きいものを選ぶ。

リリースにはアーカイブ (Windows は zip、Linux・Android・wasm は tar.xz) と、構成・ソースのコミット・スクリプトのコミット・イメージの digest
(Android は NDK の版と zip の SHA-256、wasm は emsdk の版とコミット)・configure の引数・依存の版と SHA-256・アーカイブの SHA-256 を書いた `.json` を置く。
Android と wasm の `.json` にはライブラリごとの大きさと SHA-256 も書く。
リリースのタグはソースのタグと同じで、向け先と構成の違うものを同じリリースに並べる。
同じタグを組み直しても、既にある資産は上書きしない。

試しの組 (部品を外したときの大きさや LTO を量るもの) は、`extra_configure` で `slim` (Android は `android`、wasm は `wasm`) の configure に引数を足し、
`publish` を外して回す。リリースには上げず、アーカイブ・`.json`・ビルドのログを Actions の成果物として残す。
`extra_configure` の `--disable-<種類>=<名前>` で外す部品は、`slim/configure.txt` (`android/configure.txt`・`wasm/configure.txt`) の `--enable-<種類>=...` から
抜いてから渡す (`.github/scripts/compose-configure.sh`。残すと configure が「Disabled ... because」と警告し、`--fatal-warnings` で止まる)。
記号を残した組 (`--disable-stripping`) を作れば、DLL の記号表から部品ごとの大きさを見積もれる。

## FFmpeg を更新するとき

1. 上流の新しいコミットから枝を切り、`damuko/release-9.0` の変更を載せ直す (上流に入った直しは外す)
2. タグを打つ。名前は `n<版>-damuko-<上流のコミット>[-<変更>]` とし、`n<版>-` で始める
   (FFmpeg は `git describe` で版の表示を決め、DamukoPla の取り込みは版の表示がタグで始まることを確かめる)
3. ビルド用イメージを新しくするなら `Copy build image` を回し、`build.yml` の `BUILD_IMAGE` を書き換える。
   BtbN のスクリプトのコミット (`BTBN_COMMIT`) も、そのイメージを作ったものに合わせる
4. `Build FFmpeg` をタグを指定して、`win64` の `slim` と `full`、`linux64` の `full` の 3 回回す。比較用の組は `prerelease` を立てる。
   `Build FFmpeg for Android` もタグを指定して回す。DamukoPla の Android 版の NDK や `minSdk` を変えたら、
   `build-android.yml` の `NDK_VERSION`・`NDK_URL`・`NDK_SHA256`・`ANDROID_API` を合わせる
   (`NDK_SHA256` は zip を落として取り、Google の SDK の一覧 `repository2-3.xml` の SHA-1 と照らす)
   `Build FFmpeg for WebAssembly` もタグを指定して回す。DamukoPla の emsdk の版を変えたら、`build-wasm.yml` の
   `EMSDK_VERSION`・`EMSDK_COMMIT` (`git ls-remote --tags https://github.com/emscripten-core/emsdk.git <版>`) を合わせる
   `slim/sources.txt` の依存も、新しいリリースがあれば版と SHA-256 を書き換える
   依存の版を上げたら、DamukoPla の `modules\player\third_party\ffmpeg-deps-licenses` の許諾文も
   同じ tarball から取り直す (DamukoPla の `scripts\pack.ps1` が版の食い違いで止まる)
5. DamukoPla 側で `modules\player\scripts\fetch-ffmpeg.ps1` を回して取り込む (Android は `android\third_party\ffmpeg`、wasm は `web\third_party\ffmpeg` へ)

## ライセンス

FFmpeg のソースは上流と同じく LGPL-2.1+ (一部 GPL)。リリースのビルドは LGPL 構成
(`--enable-gpl` / `--enable-nonfree` なし)。ワークフローのファイルも同じ条件で扱ってよい。
`slim` が静的に取り込む依存は dav1d (BSD-2-Clause)・soxr (LGPL-2.1+)・zlib (Zlib)・Opus (BSD-3-Clause)・LAME (LGPL-2.0+)、ヘッダーだけの nv-codec-headers (MIT)。
Android の組が静的に取り込むのは、そのうち dav1d・soxr・zlib。
その許諾文は DamukoPla の配布物 (`runtimes\win-x64\FFMPEG-DEPS-NOTICE.txt`) に入れている。
