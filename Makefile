PREFIX = miyoomini
DEFCONFIG=../br2miyoomini/configs/miyoomini_defconfig
EXTERNALS=../br2miyoomini ../br2sanetime ../br2games ../br2directfb2
TOOLCHAIN = arm-buildroot-linux-gnueabihf_sdk-buildroot.tar.gz

define clean_pkg
        rm -rf $(1)/output/build/$(2)/
endef

define update_git_package
	@echo updating git package $(1)
	- git -C $(DLDIR)/$(1)/git clean -fd
	- git -C $(DLDIR)/$(1)/git checkout master
	- git -C $(DLDIR)/$(1)/git reset --hard origin/master
	- git -C $(DLDIR)/$(1)/git branch -D $(2)
	- git -C $(DLDIR)/$(1)/git fetch --force --all --tags
	- rm -f $(DLDIR)/$(1)/*.tar.gz
endef

.PHONY: all \
	bootstrap

all: buildroot

bootstrap.stamp:
	git submodule init
	git submodule update
	touch bootstrap.stamp

./br2secretsauce/common.mk: bootstrap.stamp

include ./br2secretsauce/common.mk
