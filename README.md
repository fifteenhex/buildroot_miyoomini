# Buildroot setup for Miyoo Mini

An integrated [Buildroot](https://buildroot.org) setup that builds a complete
Miyoo Mini image (rootfs, and eventually the kernel and u-boot) from this single
repo. Buildroot and the `BR2_EXTERNAL` trees are pulled in with
[vcs2l](https://pypi.org/project/vcs2l/) rather than git submodules.

## Building

Install the host dependencies (see `.github/workflows/build.yml` for the full
list) and `vcs2l`, then:

```sh
make bootstrap   # vcs import: clone buildroot + the externals (miyoomini.repos)
make             # build
```

The output lands in `buildroot/output/images`.

## Layout

- `br2miyoomini` — the board external: `configs/miyoomini_defconfig` and the
  board files (overlay, users, genimage/FIT config).
- `miyoomini.repos` — the vcs2l manifest of Buildroot + the externals
  (`br2secretsauce`, `br2directfb2`, `br2games`, `br2sanetime`, `br2chenxing`).
- `br2secretsauce/common.mk` — the build glue (`make` targets, ccache, dl dir).

## Status

Work in progress. The rootfs builds; the kernel and u-boot are currently
deferred (their old config had bit-rotted) and will be brought back next.
