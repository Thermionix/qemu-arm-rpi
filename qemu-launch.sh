#!/bin/bash

qemu-system-arm \
-cpu arm1176 \
-m 256 \
-M versatilepb \
-no-reboot \
-serial stdio \
-net nic -net user \
-append "root=/dev/sda2 rootfstype=ext4 rw panic=1 console=ttyAMA0" \
-hda arch-linux-rPI-20150815.img \
-kernel kernel-qemu

