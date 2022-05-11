# Install guide
I spent a frustrating amount of hours spanning over a week to study relevant
wiki-, man- and forum pages to get this running. At last, a working system!
This document will aid me as future reference to set up the following:
- luks2 full disk encryption
- btrfs
- swap file
- systemd-boot
- `sd-encrypt` mkinitcpio hook
- SSD TRIM support

This is not a step-by-step guide but an "alternative route" you take during the
official Arch Install. Just the differentialities are documented, in a
hopefully concise manner, with the relevant reading material per topic.

Keep in mind that this document is tailored to me and my machine's specific
needs and quirks.

## Network
Connect to network, update mirrorlist, sync database and updating btrfs-progs.

```
iwctl station DEVICE connect NETWORK
ping archlinux.org
reflector --sort rate --latest 10 --country Netherlands,Germany --save /etc/pacman.d/mirrorlist
pacman -Sy btrfs-progs
```

## Encryption
Follow Arch Installation guide until and including [1.9 Partition the disks](https://wiki.archlinux.org/title/Installation_guide#Partition_the_disks).

### Drive preparation
Skip this step if this isn't applicable to your situation/threat tolerance.

#### Securely wipe SSD
If you've never done this you may want to run a read/write benchmark before &
after :)

> On occasion, users may wish to completely reset the SSD to the initial
> "clean" state it was manufactured with, thus restoring it to its factory
> default write performance.

https://wiki.archlinux.org/title/Solid_state_drive/Memory_cell_clearing

#### Securely wipe HDD
https://wiki.archlinux.org/title/Dm-crypt/Drive_preparation#dm-crypt_wipe_on_an_empty_disk_or_partition

Wipe the temporary container afterwards.

### Creating encrypted partition
Create encrypted partition
https://wiki.archlinux.org/title/Dm-crypt/Device_encryption#Encrypting_devices_with_LUKS_mode

Open encrypted partition
https://wiki.archlinux.org/title/Dm-crypt/Device_encryption#Unlocking/Mapping_LUKS_partitions_with_the_device_mapper

## Creating filesystems

### Format btrfs
```
mkfs.btrfs -L LABEL /dev/mapper/NAME
```

### Format EFI System partition
```
mkfs.fat -F 32 /dev/sdXY
```

### Create subvolumes
Mount the decrypted btrfs partition.
```
mount /dev/mapper/NAME /mnt
```

Adjust these to your needs.
```
for i in {@,@home,@snapshots,@srv,@swap,@var_cache_pacman_pkg,@var_log,@var_spool,@var_tmp,@var_abs}
btrfs su cr /mnt/$i
```

Unmount.
```
umount /mnt
```
## Mounting btrfs subvolumes

### Mount root subvolume
Make sure these are the options you want.
```
mount -o noatime,compress=zstd,ssd,discard=async,space_cache=v2,subvol=@ /dev/mapper/NAME /mnt
```

### Create directories
```
mkdir -p /mnt/{home,boot,.snapshots,srv,swap,var/{cache/pacman/pkg,log,spool,tmp,abs}}
```

### Mount rest of the subvolumes and EFI partition
Use the same command as the one you used for the root subvolume. Omit the
options `compress,discard,autodefrag` for @swap.

For the EFI partition mount as usual:
```
mount /dev/sdXY /mnt/boot
```

## Create swapfile
```
cd /path/to/swapfile
truncate -s 0 ./swapfile
chattr +C ./swapfile
btrfs property set ./swapfile compression none

dd if=/dev/zero of=/swap/swapfile bs=1M count=8192 status=progress
chmod 600 /swap/swapfile
mkswap /swap/swapfile
swapon /swap/swapfile
```

Remove `discard,autodefrag,compression` options from fstab for swap the subvolume!

## Pacstrap
```
pacstrap /mnt base base-devel linux linux-firmware btrfs-progs neovim man-db man-pages git intel-ucode reflector tmux
```

## Fstab
```
genfstab -U /mnt >> /mnt/etc/fstab
```

## Chroot
```
arch-chroot /mnt
```

## Configurations
Continue Arch install from Time Zone to initramfs

## Initramfs
Backup the original mkinitcpio.conf and create a new one in
`/etc/mkinitcpio.conf`
```
BINARIES=(btrfs)
HOOKS=(systemd btrfs keyboard autodetect sd-vconsole modconf block sd-encrypt filesystems fsck)
```

`fsck` can be omitted with some extra configuration described [here](https://wiki.archlinux.org/title/Improving_performance/Boot_process#Filesystem_mounts). 

## Install bootloader
```
bootctl install
```

### Create loader
In `/boot/loader/loader.conf`
```
default  arch.conf
timeout  4
console-mode max
editor   no
```

In `/boot/loader/entries` create arch.conf and add the content below. Here we
enable hibernation and SSD TRIM.
```
title Arch Linux
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options rd.luks.name=ID_OF_BLOCK_DEVICE=MAPPER_NAME root=/dev/mapper/NAME rootflags=subvol=@ resume=/dev/mapper/NAME resume_offset=OFFSET rw rd.luks.options=discard
```

Use `blkid` to find the UUID of your block device (**note that you don't use
the UUID of the mapped device**) 

Follow this to find the offset:
https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate#Hibernation_into_swap_file_on_Btrfs

## Add a keymap layout in vconsole.conf
If you don't want to do this remove the `vconsole` hook from mkinit.cpio
otherwise the next step will output errors.

Example for US layout:
```
echo "KEYMAP=us" /etc/vconsole.conf
```

## Mkinitcpio
```
mkinitcpio -P
```

## Create a new user
```
useradd -s usr/bin/bash -U -G wheel,video -m --btrfs-subvolume-home myuser
```
