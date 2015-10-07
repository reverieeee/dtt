#!/bin/bash
# install arch without intervention

HOSTNAME="loki" # only need short form
LOCALE="en_US.UTF-8" # :911:
TIMEZONE="America/Detroit" # :911:
ARCH="$(uname -m)"
PARTCMD="/usr/bin/parted -s /dev/sda"

init ()
{
    # if ping check fails setup the network yourself
    PING=$(/usr/bin/ping -c 3 8.8.8.8 | grep 'received' | awk -F',' '{ print $2 }' | awk '{ print $1 }') # this is ugly

    if [[ $PING -eq 0 ]]; then
        echo "the system is down"
        echo "set up your network manually"
        exit 1
    else
        echo "the system is up"
        # while we're at it do some stuff to make life easier
        /usr/bin/pacman --noconfirm -Syy ; /usr/bin/pacman --noconfirm -S reflector
    fi
}

partition ()
{
    # we assume a few things here
    # 1) the disk we're installing to is /dev/sda
    # 2) the disk is at least 500gb in size
    # 3) the system isn't uefi
    # 4) the system has 8gb of RAM
    # 5) that i know how to properly partition a disk

    ###################
    # 512MB /boot
    # 8GB swap
    # rest of disk /
    ###################
    # if this doesn't work for you, alter it
    $PARTCMD -a optimal mklabel msdos
    $PARTCMD -a optimal unit mb mkpart primary ext4 1 513
    $PARTCMD set 1 boot on
    $PARTCMD -a optimal unit mb mkpart primary linux-swap 513 8513
    $PARTCMD -a optimal unit mb mkpart primary ext4 8513 100%

    # create and mount filesystems
    /usr/bin/mkfs.ext4 -q /dev/sda1
    /usr/bin/mkswap /dev/sda2
    /usr/bin/swapon /dev/sda2
    /usr/bin/mkfs.ext4 -q /dev/sda3

    /usr/bin/mount /dev/sda3 /mnt
    /usr/bin/mkdir -v /mnt/boot
    /usr/bin/mount /dev/sda1 /mnt/boot
}

setup ()
{
    # mirrorlist setup goes first
    /usr/bin/cp -v -f /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
    /usr/bin/reflector --verbose --country 'United States' -l 20 -p http --sort rate --save /etc/pacman.d/mirrorlist
}
