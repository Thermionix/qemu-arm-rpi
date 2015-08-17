#!/bin/bash

qemu-system-arm \
-cpu arm1176 \
-m 256 \
-M versatilepb \
-no-reboot \
-serial stdio \
-net nic -net user \
-append "root=/dev/mmcblk0p2 rootfstype=ext4 rw panic=1 console=ttyAMA0" \
-drive if=sd,cache=writeback,file=arch-linux-rPI.img \
-kernel kernel-qemu

