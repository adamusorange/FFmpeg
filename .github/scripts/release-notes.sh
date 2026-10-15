#!/bin/bash
# リリースの説明を標準出力に出す。build.yml・build-android.yml・build-wasm.yml が使う。
# どの向け先を組んだときも同じ文にする (後から組んだものが上書きするため)。
# 環境変数: GITHUB_REPOSITORY、SOURCE_TAG、SOURCE_COMMIT、ADDIN
set -euo pipefail
: "${GITHUB_REPOSITORY:?}" "${SOURCE_TAG:?}" "${SOURCE_COMMIT:?}" "${ADDIN:?}"

echo "FFmpeg の LGPL ビルド (\`${ADDIN}\` 系)。"
echo
echo "- ソース: [\`${SOURCE_TAG}\`](https://github.com/${GITHUB_REPOSITORY}/tree/${SOURCE_COMMIT}) (\`${SOURCE_COMMIT}\`)"
echo "- 組み方: Windows と Linux は [BtbN/FFmpeg-Builds](https://github.com/BtbN/FFmpeg-Builds) のスクリプトをそのまま使用。"
echo "  Android は Android NDK、WebAssembly は Emscripten で組む (この fork の \`damukopla\` 枝の \`android/\`・\`wasm/\`)"
echo "- スクリプトのコミット・ビルド用イメージ・NDK や emsdk の版は、資産ごとの \`.json\` にある"
echo
echo "資産名で見分けます。"
echo
echo "- \`...-win64-lgpl-shared-${ADDIN}.zip\` (Windows、full): BtbN の構成のまま"
echo "- \`...-win64-lgpl-shared-${ADDIN}-slim.zip\` (Windows、slim): DamukoPla が使う部品だけに絞った構成。"
echo "  依存 (dav1d・soxr・zlib・nv-codec-headers・Opus・LAME) を正式リリースから組み直したイメージで組む。"
echo "  同じタグを構成を変えて組み直したものは \`-slim-r<版>\` で、版の大きいものが新しい"
echo "  構成と依存はこの fork の \`damukopla\` 枝の \`slim/\` にある"
echo "- \`...-linux64-lgpl-${ADDIN}.tar.xz\` (Linux x86-64、static、full): BtbN の構成のまま (nv-codec-headers だけ 13.0.19.1 に差し替え)。"
echo "  DamukoPla のメディアサーバーが変換に使う \`ffmpeg\` の CLI"
echo "- \`...-android-arm64-lgpl-shared-${ADDIN}-slim.tar.xz\` (Android arm64-v8a、slim): \`slim\` と同じ部品の選び方で、"
echo "  hwaccel と変換の部品を持たない LGPL の .so 6 本。依存 (dav1d・soxr・zlib) は \`slim\` と同じ tarball から静的に抱える。"
echo "  DamukoPla の Android 版が使う。構成はこの fork の \`damukopla\` 枝の \`android/\` にある"
echo "- \`...-wasm32-lgpl-static-${ADDIN}.tar.xz\` (WebAssembly、静的ライブラリ): 分離・fMP4 への詰め直し・音声の作り直しに要る部品だけの"
echo "  LGPL の .a 4 本 (avformat・avcodec・swresample・avutil)。映像のデコーダーとスレッドを持たない。"
echo "  DamukoPla のブラウザ版が、自前のコードと別の wasm に繋ぐ。構成はこの fork の \`damukopla\` 枝の \`wasm/\` にある"
echo
echo "上流の FFmpeg からの変更点は、ソースのタグと上流の差分で確かめられます。"
echo "資産ごとの \`.json\` に、ソース・スクリプト・イメージ (NDK・emsdk)・configure の引数・依存とアーカイブの SHA-256 を記録しています。"
