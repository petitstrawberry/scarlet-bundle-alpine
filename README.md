# scarlet-bundle-alpine

Alpine Linux userspace producer for [Scarlet](https://github.com/petitstrawberry/Scarlet).
This repository is separate from `scarlet-bundle-linux`, which continues to
produce the Buildroot userspace. The first target is an AArch64 rootfs with
Alpine's Chromium package and its JavaScript engine.

## Build

On an AArch64 host with Docker (or an x86_64 Docker host with arm64 emulation):

```sh
ARCH=aarch64 PROFILE=chromium VERSION=v0.1.0 \
  bash producer/tools/build_rootfs.sh
```

The script uses Alpine 3.23 `main` and `community`, verifies packages using
Alpine's signing keys, and writes
`producer/artifacts/rootfs-aarch64-v0.1.0.tar.zst`. It also records installed
package versions at `/usr/share/scarlet/apk-packages.txt` inside the archive.
The rootfs includes `chromium`, `chromium-swiftshader`, CA certificates, and
fonts. `PROFILE=base` builds a small ABI smoke-test rootfs with `-base-` in
its artifact name.

The archive uses the same `tar-zst`, one-component-stripped layout as Scarlet's
current Linux bundle. Until an Alpine release is published and its SHA-256 is
pinned in Scarlet, use an isolated Scarlet image manifest to consume a local
artifact. Do not replace the published Buildroot rootfs solely on the basis of
artifact creation.

## Scarlet bring-up

The Scarlet Linux view is named `linux-aarch64`. Its `/dev`, `/tmp`, `/home`,
`/root`, and `/shared` directories are bound to the native view. The generated
`/etc/resolv.conf` points to the native network configuration through
`/scarlet/etc/resolv.conf`.

Run `bash producer/tests/check_artifact.sh` on the archive and
`bash producer/tests/smoke_chromium.sh` on the generated staging directory.
The latter verifies JavaScript in a Linux container, not Scarlet compatibility.
Then run `/bin/busybox` and `/usr/bin/chromium --version` through `abi-run`.
Then try Chromium on the existing Wayland bridge:

```sh
abi-run linux-aarch64 /usr/bin/chromium \
  --no-sandbox --ozone-platform=wayland --disable-gpu \
  --user-data-dir=/tmp/chromium-profile https://www.youtube.com/
```

Set `WAYLAND_DISPLAY=wayland-0` and `XDG_RUNTIME_DIR=/tmp` in the Scarlet shell
before launching. These flags are a first launch probe, not a verified
YouTube playback recipe. Scarlet still needs browser-driven ABI fixes, Wayland
surface validation, and a Linux audio compatibility path. The current
`scarlet-bundle-linux` release remains the default until those checks pass.

## Repository layout

- `producer/tools/build_rootfs.sh`: Alpine package installation and archive
  generation.
- `producer/tests/`: artifact checks.
- `producer/artifacts/`: ignored local release candidates.
- `bundles/rootfs/`: reserved for a hash-pinned release manifest after the
  first runtime validation.
