#!/usr/bin/env bash
set -euo pipefail

# Build a musl Linux view for Scarlet. Docker executes target-architecture apk
# scripts; apk verifies every package against Alpine's signing keys.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ARCH="${ARCH:-aarch64}"
PROFILE="${PROFILE:-chromium}"
VERSION="${VERSION:-v0.1.0}"
ARTIFACT_DIR="${ARTIFACT_DIR:-${REPO_ROOT}/producer/artifacts}"
CACHE_DIR="${CACHE_DIR:-${REPO_ROOT}/producer/cache}"
ALPINE_BRANCH=v3.23
ALPINE_IMAGE='alpine:3.23@sha256:85fe1e81d6758c208f3e1eed4338a1997e19d4be002d4dd32d3100c9a8c010a0'

case "$ARCH" in
    aarch64) docker_platform=linux/arm64 ;;
    *) echo "Unsupported ARCH=$ARCH; the browser profile currently targets aarch64" >&2; exit 2 ;;
esac
case "$PROFILE" in
    base|chromium) ;;
    *) echo "Unsupported PROFILE=$PROFILE; choose base or chromium" >&2; exit 2 ;;
esac
case "$VERSION" in
    v[0-9]*.[0-9]*.[0-9]*) ;;
    *) echo "VERSION must look like v0.1.0" >&2; exit 2 ;;
esac
command -v docker >/dev/null || { echo 'Docker is required' >&2; exit 2; }

mkdir -p "$CACHE_DIR" "$ARTIFACT_DIR"
stage="$(mktemp -d "${CACHE_DIR}/rootfs-${ARCH}-${PROFILE}.XXXXXXXX")"
archive_name="rootfs-${ARCH}-${VERSION}"
if [[ "$PROFILE" == base ]]; then archive_name="rootfs-${ARCH}-base-${VERSION}"; fi
archive="${ARTIFACT_DIR}/${archive_name}.tar.zst"
if [[ -e "$archive" ]]; then
    echo "Refusing to overwrite $archive" >&2
    exit 2
fi

docker run --rm --platform "$docker_platform" \
    --mount "type=bind,src=${stage},dst=/out" \
    -e ALPINE_BRANCH="$ALPINE_BRANCH" -e PROFILE="$PROFILE" \
    "$ALPINE_IMAGE" sh -eu -c '
        mkdir -p /out/etc/apk /out/usr/share/scarlet
        cp -a /etc/apk/keys /out/etc/apk/
        printf "https://dl-cdn.alpinelinux.org/alpine/%s/main\nhttps://dl-cdn.alpinelinux.org/alpine/%s/community\n" "$ALPINE_BRANCH" "$ALPINE_BRANCH" > /out/etc/apk/repositories
        if [ "$PROFILE" = chromium ]; then
            set -- alpine-baselayout busybox ca-certificates chromium chromium-swiftshader font-dejavu
        else
            set -- alpine-baselayout busybox ca-certificates
        fi
        apk --root /out --initdb --no-cache add "$@"
        apk --root /out info -vv > /out/usr/share/scarlet/apk-packages.txt
        printf "Alpine %s (%s)\n" "$ALPINE_BRANCH" "$PROFILE" > /out/usr/share/scarlet/build.txt
        ln -s /scarlet/etc/resolv.conf /out/etc/resolv.conf
        mkdir -p /out/tmp /out/root /out/home /out/shared /out/dev
        test -x /out/lib/ld-musl-aarch64.so.1
        if [ "$PROFILE" = chromium ]; then test -x /out/usr/bin/chromium; fi
    '

docker run --rm --platform "$docker_platform" \
    --mount "type=bind,src=${stage},dst=/rootfs,readonly" \
    --mount "type=bind,src=${ARTIFACT_DIR},dst=/artifacts" \
    -e ARCHIVE_NAME="$archive_name" \
    "$ALPINE_IMAGE" sh -eu -c '
        apk add --no-cache tar zstd >/dev/null
        tar -C /rootfs --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
            -I "zstd -T2 -9" -cf "/artifacts/${ARCHIVE_NAME}.tar.zst" .
    '

if command -v shasum >/dev/null; then
    shasum -a 256 "$archive"
else
    sha256sum "$archive"
fi
echo "Rootfs stage: $stage"
echo "Artifact: $archive"
