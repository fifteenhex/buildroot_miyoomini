PREFIX = miyoomini
DEFCONFIG=../br2miyoomini/configs/miyoomini_defconfig
EXTERNALS=../br2miyoomini ../br2sanetime ../br2games ../br2directfb2 ../br2chenxing ../br2dgppkg
TOOLCHAIN = arm-buildroot-linux-gnueabihf_sdk-buildroot.tar.gz

.PHONY: all \
	bootstrap \
	sdl2-directfb-fixup \
	qemu \
	qemu-run

all: sdl2-directfb-fixup

bootstrap.stamp:
	vcs import --input miyoomini.repos .
	touch bootstrap.stamp

bootstrap: bootstrap.stamp

./br2secretsauce/common.mk: bootstrap.stamp
./br2directfb2/buildhack.mk: bootstrap.stamp

include ./br2secretsauce/common.mk
include ./br2directfb2/buildhack.mk

# SDL2 configures before directfb2 has finished staging - a Buildroot external
# can't inject a dependency into the bundled sdl2 package - so on the first pass
# SDL2 is built without the DirectFB video driver. Rebuild SDL2 against the
# staged directfb2 and then everything that links it (buildhack.mk), and
# regenerate the images.
sdl2-directfb-fixup: buildroot
	$(MAKE) rebuild_sdl2
	$(MAKE) rebuild_sdl2_rdeps
	$(MAKE) buildroot

# --- Optional: build the mstar QEMU fork and smoke-test with a direct kernel boot ---
#
# The 'miyoomini' machine model lives in the upstream QEMU fork (branch
# mstar-clean). These targets are NOT part of the default build; run them
# explicitly:
#
#   make qemu       # clone + build qemu-system-arm with the miyoomini machine
#   make qemu-run   # boot the freshly built kernel + rootfs directly (-kernel)
#
# qemu-run does a *direct kernel boot*: it loads output/images/zImage and the
# DTB straight into the machine and mounts the EROFS rootfs from the SD image,
# bypassing the mask ROM / SPL / U-Boot chain. Override QEMU_DISPLAY=none for a
# headless run.
QEMU_REPO    = https://github.com/fifteenhex/qemu.git
QEMU_BRANCH  = mstar-clean
QEMU_DIR     = $(PWD)/qemu
QEMU_BIN     = $(QEMU_DIR)/build/qemu-system-arm
QEMU_IMAGES  = $(PWD)/buildroot/output/images
QEMU_DTB     = mstar-infinity2m-ssd202d-miyoo-mini.dtb
QEMU_DISPLAY ?= gtk
QEMU_APPEND  = console=ttyS0,38400 root=/dev/mmcblk0p2 rootfstype=erofs ro rootwait

$(QEMU_DIR):
	git clone --depth 1 --branch $(QEMU_BRANCH) $(QEMU_REPO) $(QEMU_DIR)

$(QEMU_BIN): | $(QEMU_DIR)
	cd $(QEMU_DIR) && ./configure --target-list=arm-softmmu --disable-docs && \
		$(MAKE) -C build -j$(shell nproc)

qemu: $(QEMU_BIN)

qemu-run: $(QEMU_BIN)
	$(QEMU_BIN) -M miyoomini -m 128M \
		-kernel $(QEMU_IMAGES)/zImage \
		-dtb $(QEMU_IMAGES)/$(QEMU_DTB) \
		-append "$(QEMU_APPEND)" \
		-drive if=sd,format=raw,file=$(QEMU_IMAGES)/sdcard.img \
		-serial mon:stdio -display $(QEMU_DISPLAY)
