# Changelog

## 1.0.0 (2026-06-17)


### Features

* **box:** add 'ls' and 'stop [--all]' commands ([ad79061](https://github.com/langdal/box/commit/ad79061435aead33c0229310681555eda00476be))
* initial import of box — a microVM agent sandbox on microsandbox ([6160f59](https://github.com/langdal/box/commit/6160f5999edf43f214d7c9a35e1e4f23025d8b1b))


### Bug Fixes

* **box:** always suppress AAAA in guest, drop the IPv6-route gate ([704bd12](https://github.com/langdal/box/commit/704bd12492cb95fd0c0d5f9d30b96b70e0e2a43a))
* **box:** default TMPDIR to host-backed /workspace/.tmp so pip has disk space ([90bb5d2](https://github.com/langdal/box/commit/90bb5d2b27b3181e20a68139599ab50f5e3139d8))
* **box:** disable guest IPv6 at boot (not just no-aaaa) ([88758ca](https://github.com/langdal/box/commit/88758cae05a828d31aac52adf973db5cf7d69347))
* **box:** forward guest DNS to public resolvers (VPN/WireGuard-proof) ([c6c2020](https://github.com/langdal/box/commit/c6c2020b9c15612e05ced144852a69ca6c07e100))
* **box:** IPv4-only via no-aaaa only; do NOT disable guest IPv6 ([0288906](https://github.com/langdal/box/commit/02889069612c253e8a59e843823665c221f2f282))
* **box:** persist root's home (history, git, ssh, Claude auth) on the box-home volume ([062dc66](https://github.com/langdal/box/commit/062dc662ddc63e51932bee2adf37656875ed6591))
* **box:** raise guest fs.file-max + inotify caps; allow sigstore egress ([9841b60](https://github.com/langdal/box/commit/9841b60be7a9b7dafdcc3dd5b7886ee5a090f1dc))
* **box:** raise guest open-file limit (fixes "Too many open files") ([9d0a672](https://github.com/langdal/box/commit/9d0a6729c3c091f9bac963bdf962c01154b24d01))
* **box:** require bash &gt;= 4, re-exec under a newer bash on macOS ([02f8203](https://github.com/langdal/box/commit/02f820362c26ce411f041e8fb8f9a5fb22fd75eb))
* **box:** run on stock macOS bash 3.2 (mapfile polyfill), drop bash&gt;=4 requirement ([3e44ec2](https://github.com/langdal/box/commit/3e44ec25ca871accad2ad4261fa7c921070e05b9))
* **box:** suppress AAAA in guest when it has no IPv6 egress ([bd42de1](https://github.com/langdal/box/commit/bd42de1379b06e0516afc375573748ac6422c76b))
