# Kernel + boot-partition wiring notes

How the Linux kernel is built as part of this meta-repo and how its FIT is
landed in the FAT boot partition. (Reproducibility log for the 2026-07-29
"re-enable the kernel" work.)

## What was done

- `br2miyoomini/configs/miyoomini_defconfig`: re-enabled the kernel.
  - `BR2_LINUX_KERNEL_CUSTOM_GIT` at repo
    `https://github.com/linux-chenxing/linux.git`, branch `mstar_v6_5_reorder`
    - the known-good Linux 6.5 tree that boots the Miyoo Mini (SSD202D) in
    QEMU. For offline builds, override the repo URL (or use
    `LINUX_OVERRIDE_SRCDIR`) to point at a local checkout via `buildroot/local.mk`.
  - `zImage` image type, board `linux.config` as the custom kernel config,
    in-tree DTS `mstar-infinity2m-ssd202d-miyoo-mini`, DTB overlay support.
  - Re-enabled the genimage post-image step.
- `br2miyoomini/board/miyoo/miyoomini/kernel.its`: fixed the FIT `default`
  (it pointed at an undefined `midrived08`; only `midrived06` existed) to a
  single self-consistent `conf-0`. `/incbin/` paths stay `../../images/...`
  (see "gotcha" below).
- `br2miyoomini/board/miyoo/miyoomini/genimage.cfg`: while u-boot is
  deferred, the 256M FAT boot partition holds only `kernel.fit`. Restore the
  `ipl`, `u-boot.img` and `uboot.env` inputs once u-boot is wired.
- No `br2chenxing` change needed: its `select BR2_LINUX_KERNEL_DTS_SUPPORT`
  and kernel/u-boot default guards are keyed on `BR2_LINUX_KERNEL` /
  `BR2_TARGET_UBOOT`, so they activate automatically now that the kernel is
  enabled and stay off for u-boot.

## Build

Same args as the rootfs build. From `buildroot/`:

```sh
ARGS='BR2_DL_DIR=/workspace/src/buildroot_miyoomini/dl \
  BR2_EXTERNAL=../br2miyoomini:../br2sanetime:../br2games:../br2directfb2:../br2chenxing \
  BR2_CCACHE=y BR2_CCACHE_DIR=/workspace/src/buildroot_miyoomini/ccache \
  BR2_PER_PACKAGE_DIRECTORIES=y'
make $ARGS BR2_DEFCONFIG=../br2miyoomini/configs/miyoomini_defconfig defconfig
make $ARGS linux          # kernel + DTB -> output/images/{zImage,*.dtb}
make $ARGS                # full build incl. the genimage post-image step
```

Outputs: `output/images/{zImage, mstar-infinity2m-ssd202d-miyoo-mini.dtb,
kernel.fit, boot_part.img, sdcard.img}`.

Verify the FIT is in the FAT:

```sh
output/host/bin/dumpimage -l output/images/kernel.fit
MTOOLS_SKIP_CHECK=1 output/host/bin/mdir -i output/images/boot_part.img ::
```

## Gotchas learned

- **Enabling the kernel flips kernel-headers to "as-kernel" (6.5).** With no
  kernel, buildroot defaults `BR2_KERNEL_HEADERS` to a fixed version; with
  the kernel on, `BR2_KERNEL_HEADERS_AS_KERNEL=y` becomes the default, so the
  first full build after this change rebuilds the toolchain against the 6.5
  headers. Expected and correct (userspace headers match the running kernel),
  but it is a heavy rebuild.
- **FIT `/incbin/` paths are `../../images/...`, not `output/images/...`.**
  `support/scripts/genimage.sh` copies the `.its` to
  `$(BUILD_DIR)/genimage.tmp/fit.its` before running mkimage, and `dtc`
  resolves `/incbin/` relative to the `.its` file's own directory (not the
  cwd). From `output/build/genimage.tmp` that is `../../images`.
- **mkimage needs FIT_SIGNATURE support.** genimage's `fit` handler always
  passes `-r` to mkimage, which errors unless mkimage was built with
  signature support. `BR2_CHENXING` selects
  `BR2_PACKAGE_HOST_UBOOT_TOOLS_FIT_SIGNATURE_SUPPORT`, so the integrated
  build's mkimage handles it; a stale host mkimage built without it will
  fail here.
- **genimage `its = "<path>"`** is resolved as an implicit input file
  relative to `--inputpath` (`output/images`), hence the
  `../../../br2miyoomini/board/miyoo/miyoomini/kernel.its` path in
  genimage.cfg.

## Verification done (2026-07-29)

Because the shared `output/` tree was in active use by another session, the
kernel compile and FIT/FAT assembly were verified in an isolated scratch
build using the already-built `arm-buildroot-linux-gnueabihf` toolchain and
the host mkimage/genimage/mtools:

- Kernel + DTB compiled clean from `mstar_v6_5_reorder` with the board
  `linux.config` (`make olddefconfig` + `make zImage dtbs`): `zImage`
  (3.06 MiB) and `mstar-infinity2m-ssd202d-miyoo-mini.dtb` (31 KiB).
- `mkimage -f kernel.its kernel.fit` produced a valid FIT: `kernel-0`
  (ARM Linux kernel, load 0x22800000), `fdt-0` (the DTB, load 0x24000000),
  default `conf-0`.
- genimage placed `kernel.fit` in the 256M FAT `boot_part.img` (mdir shows
  `KERNEL.FIT`), and `sdcard.img` assembled as a bootable 256M FAT32
  (type 0xc) followed by two 512M Linux (0x83) rootfs partitions.

Still to do on a quiet shared tree: a full `make $ARGS` in `output/` (which
will rebuild the toolchain against 6.5 headers) to produce the images in the
canonical tree; and reviving u-boot so the boot partition also carries
ipl + u-boot.img + env.
