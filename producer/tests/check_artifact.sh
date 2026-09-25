#!/usr/bin/env bash
set -euo pipefail

archive="${1:?usage: check_artifact.sh <rootfs.tar.zst> [base|chromium]}"
profile="${2:-chromium}"
command -v docker >/dev/null || { echo 'Docker is required' >&2; exit 2; }
case "$profile" in base|chromium) ;; *) echo "Unknown profile: $profile" >&2; exit 2 ;; esac
archive_dir="$(cd "$(dirname "$archive")" && pwd)"
archive_name="$(basename "$archive")"
docker run --rm --platform linux/arm64 \
    --mount "type=bind,src=${archive_dir},dst=/artifacts,readonly" \
    -e ARCHIVE_NAME="$archive_name" -e PROFILE="$profile" \
    alpine:3.23 sh -eu -c '
        apk add --no-cache tar zstd >/dev/null
        tar -I zstd -tf "/artifacts/$ARCHIVE_NAME" | grep -qx "./lib/ld-musl-aarch64.so.1"
        tar -I zstd -tf "/artifacts/$ARCHIVE_NAME" | grep -qx "./etc/apk/world"
        if [ "$PROFILE" = chromium ]; then
            tar -I zstd -tf "/artifacts/$ARCHIVE_NAME" | grep -qx "./usr/bin/chromium"
            tar -I zstd -tf "/artifacts/$ARCHIVE_NAME" | grep -qx "./usr/lib/libstdc++.so.6"
        fi
    '
echo "Artifact structure OK: $archive"
