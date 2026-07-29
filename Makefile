PREFIX = miyoomini
DEFCONFIG=../br2miyoomini/configs/miyoomini_defconfig
EXTERNALS=../br2miyoomini ../br2sanetime ../br2games ../br2directfb2 ../br2chenxing ../br2dgppkg
TOOLCHAIN = arm-buildroot-linux-gnueabihf_sdk-buildroot.tar.gz

.PHONY: all \
	bootstrap \
	sdl2-directfb-fixup

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
