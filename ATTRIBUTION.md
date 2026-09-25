# Third-party packages

The rootfs archive contains Alpine Linux packages. They keep their own
licenses; this repository's license covers only the producer scripts and
documentation. `/lib/apk/db/installed` inside each archive records package
metadata, and `/usr/share/scarlet/apk-packages.txt` lists the installed
versions. The source recipes are in Alpine's
[aports repository](https://gitlab.alpinelinux.org/alpine/aports).

Before publishing a release asset, review the exact package list and source
availability for its selected versions.

The bundle also layers the SHA-256-pinned AArch64 Mozc server archive from
`scarlet-bundle-linux` v0.1.0. It was built from Mozc source with an OSS
dictionary embedded in the server, using a musl toolchain. The standalone
archive is not an Alpine package and keeps its upstream licenses and build
provenance in `scarlet-bundle-linux`.
