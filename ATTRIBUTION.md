# Third-party packages

The rootfs archive contains Alpine Linux packages. They keep their own
licenses; this repository's license covers only the producer scripts and
documentation. `/lib/apk/db/installed` inside each archive records package
metadata, and `/usr/share/scarlet/apk-packages.txt` lists the installed
versions. The source recipes are in Alpine's
[aports repository](https://gitlab.alpinelinux.org/alpine/aports).

Before publishing a release asset, review the exact package list and source
availability for its selected versions.
