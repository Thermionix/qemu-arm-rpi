#!/bin/sh -ex
set -e

command -v mkfs.vfat > /dev/null || { echo "## please install mkfs.vfat (pkg dosfstools)" ; exit 1 ; }

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

TMP_BOOT=/tmp/arch-boot
TMP_ROOT=/tmp/arch-root

echo "Mounting $LOOP_BOOT at $TMP_BOOT"
mkdir -p $TMP_BOOT
sudo mount $LOOP_BOOT $TMP_BOOT

echo "Mounting $LOOP_ROOT at $TMP_ROOT"
mkdir -p $TMP_ROOT
sudo mount $LOOP_ROOT $TMP_ROOT

echo "Extracting ArchLinuxARM files to root"
sudo bsdtar -xpf ArchLinuxARM-rpi-latest.tar.gz -C $TMP_ROOT

sudo sed -i "s/ defaults / defaults,noatime /" $TMP_ROOT/etc/fstab

#sudo sed -e '/^\/usr\/lib\/arm-linux-gnueabihf\/libcofi_rpi.so/ s/^/#/' -i $TMP_ROOT/etc/ld.so.preload

#cat << EOF | sudo tee $TMP_ROOT/etc/udev/rules.d/90-qemu.rules 
#KERNEL=="sda", SYMLINK+="mmcblk0"
#KERNEL=="sda?", SYMLINK+="mmcblk0p%n"
#KERNEL=="sda2", SYMLINK+="root"
#EOF

sudo mv $TMP_ROOT/boot/* $TMP_BOOT/
sudo umount $TMP_BOOT $TMP_ROOT

sudo losetup -d $LOOP
sudo rm -r $TMP_BOOT $TMP_ROOT
