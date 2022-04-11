PREFIX = miyoomini
DEFCONFIG=../br2miyoomini/configs/miyoomini_defconfig
EXTERNALS=../br2miyoomini ../br2sanetime ../br2games ../br2directfb2 ../br2chenxing
TOOLCHAIN = arm-buildroot-linux-gnueabihf_sdk-buildroot.tar.gz

.PHONY: all \
	bootstrap

all: buildroot

bootstrap.stamp:
	git submodule init
	git submodule update --depth=1
	touch bootstrap.stamp

bootstrap: bootstrap.stamp

./br2secretsauce/common.mk: bootstrap.stamp

include ./br2secretsauce/common.mk
