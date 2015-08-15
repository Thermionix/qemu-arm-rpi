#!/bin/sh -ex
set -e
losetup /dev/loop5 && exit 1 || true
image=arch-linux-rPI.img
if [ ! -f "ArchLinuxARM-rpi-latest.tar.gz" ]; then
  wget -N http://archlinuxarm.org/os/ArchLinuxARM-rpi-latest.tar.gz
fi
truncate -s 2G $image
losetup /dev/loop5 $image
parted -s /dev/loop5 mklabel msdos
parted -s /dev/loop5 unit MiB mkpart primary fat32 -- 1 32
parted -s /dev/loop5 set 1 boot on
parted -s /dev/loop5 unit MiB mkpart primary ext2 -- 32 -1
parted -s /dev/loop5 print
mkfs.vfat -n SYSTEM /dev/loop5p1
mkfs.ext4 -L root -b 4096 -E stride=4,stripe_width=1024 /dev/loop5p2
mkdir -p arch-boot
mount /dev/loop5p1 arch-boot
mkdir -p arch-root
mount /dev/loop5p2 arch-root
bsdtar -xpf ArchLinuxARM-rpi-latest.tar.gz -C arch-root
sed -i "s/ defaults / defaults,noatime /" arch-root/etc/fstab
mv arch-root/boot/* arch-boot/
umount arch-boot arch-root
losetup -d /dev/loop5
rm -r arch-boot arch-root
