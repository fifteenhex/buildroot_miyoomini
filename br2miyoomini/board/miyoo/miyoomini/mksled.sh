#!/bin/bash

dd if=/dev/zero of=miyoo283_fw.img bs=1K count=16
dd conv=notrunc if=bootscript.txt of=miyoo283_fw.img
