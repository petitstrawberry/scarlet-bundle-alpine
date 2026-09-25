#!/usr/bin/env bash
set -euo pipefail

stage="${1:?usage: smoke_chromium.sh <staged-rootfs-directory>}"
stage="$(cd "$stage" && pwd)"
test -x "$stage/usr/bin/chromium"

version="$(docker run --rm --platform linux/arm64 \
    --mount "type=bind,src=${stage},dst=/rootfs" \
    alpine:3.23 chroot /rootfs /usr/bin/chromium --version)"
case "$version" in Chromium*Alpine*) ;; *) echo "Unexpected version: $version" >&2; exit 1 ;; esac

dom="$(docker run --rm --privileged --platform linux/arm64 \
    --mount "type=bind,src=${stage},dst=/rootfs" \
    alpine:3.23 sh -eu -c '
        mount --bind /dev /rootfs/dev
        mount -t proc proc /rootfs/proc
        chroot /rootfs /usr/bin/chromium \
            --headless --no-sandbox --disable-gpu --disable-dev-shm-usage \
            --dump-dom "data:text/html,<script>document.write(1%2B1)</script>" \
            2>/dev/null
    ')"
case "$dom" in *'<body>2</body>'*) ;; *) echo "JavaScript smoke test failed: $dom" >&2; exit 1 ;; esac
echo "$version: JavaScript smoke test passed"
