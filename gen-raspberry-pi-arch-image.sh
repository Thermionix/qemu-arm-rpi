#!/bin/sh -ex
set -e

IMAGE=arch-linux-rPI.img

if [ ! -f "ArchLinuxARM-rpi-latest.tar.gz" ]; then
  wget -N http://archlinuxarm.org/os/ArchLinuxARM-rpi-latest.tar.gz
fi

truncate -s 2G $IMAGE

LOOP=`sudo losetup -f --show $IMAGE`

sleep 1
echo "Partitioning $LOOP"

sudo parted -s $LOOP mklabel msdos
sudo parted -s $LOOP unit MiB mkpart primary fat32 -- 1 32
sudo parted -s $LOOP set 1 boot on
sudo parted -s $LOOP unit MiB mkpart primary ext2 -- 32 -1
sudo parted -s $LOOP print

sleep 3

LOOP_BOOT="$LOOP"p1
LOOP_ROOT="$LOOP"p2

echo $LOOP_BOOT

echo "Formatting $LOOP_BOOT boot partition"
sudo mkfs.vfat -n SYSTEM $LOOP_BOOT

echo "Formatting $LOOP_ROOT root partition"
sudo mkfs.ext4 -L root -b 4096 -E stride=4,stripe_width=1024 $LOOP_ROOT

sleep 1

echo "Mounting $LOOP_BOOT as boot"
mkdir -p arch-boot
sudo mount $LOOP_BOOT arch-boot

echo "Mounting $LOOP_ROOT as root"
mkdir -p arch-root
sudo mount $LOOP_ROOT arch-root

echo "Extracting ArchLinuxARM files to root"
sudo bsdtar -xpf ArchLinuxARM-rpi-latest.tar.gz -C arch-root

sudo sed -i "s/ defaults / defaults,noatime /" arch-root/etc/fstab

cat | sudo tee arch-root/etc/udev/rules.d/90-qemu.rules <<EOF 
KERNEL=="sda", SYMLINK+="mmcblk0"
KERNEL=="sda?", SYMLINK+="mmcblk0p%n"
KERNEL=="sda2", SYMLINK+="root"
EOF

sudo mv arch-root/boot/* arch-boot/
sudo umount arch-boot arch-root

sudo losetup -d $LOOP
sudo rm -r arch-boot arch-root
