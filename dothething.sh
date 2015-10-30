#!/bin/bash
# install arch without intervention

###################################################
# PLANNED CHANGES:                                #
# * FDE support                                   #
# * cmdline args to run one step instead of all   #
# * custom partition layouts                      #
# * sfdisk instead of parted?                     #
#                                                 #
###################################################

HOSTNAME="loki" # only need short form
LOCALE="en_US.UTF-8" # :911:
TIMEZONE="America/New_York" # :911:
PARTCMD="/usr/bin/parted -s /dev/sda"

init ()
{
    # if ping check fails setup the network yourself
    # TODO: this, but a lot better
    PING=$(/usr/bin/ping -c 3 8.8.8.8 | grep 'received' | awk -F',' '{ print $2 }' | awk '{ print $1 }')

    if [[ $PING -eq 0 ]]; then
        echo "the system is down"
        read -p "start wifi-menu to establish a connection? [y/n]: " wmexec
        if [ "$wmexec" == "y" ]; then
            /usr/bin/sudo /usr/bin/wifi-menu
            # ping check again
            PING2=$(/usr/bin/ping -c 3 8.8.8.8 | grep 'received' | awk -F',' '{ print $2 }' | awk '{ print $1 }')
            if [[ $PING2 -eq 0 ]]; then
                echo "network is still not configured. bailing out; please configure it manually."
                exit 1
            else
                echo "good to go!"
            fi
        fi
    else
        echo "the system is up"
    fi
}

partition ()
{
    # we assume a few things here
    # 1) the disk we're installing to is /dev/sda
    # 2) the disk is big enough for 8gb swap
    # 3) the system isn't uefi
    # 4) the system has 8gb of RAM
    # 5) that i know how to properly partition a disk

    ####################
    # 512MB | /boot    #
    # 8GB   | swap     #
    # rest  | /        #
    ####################
    # if this doesn't work for you, alter it
    # TODO: this could possibly be done a lot better with sfdisk
    echo "partitioning using the following layout:"
    echo "512MB | /boot"
    echo "8GB   | swap"
    echo "rest  | /"
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
    # mirrorlist setup first
    echo "setting up our mirrorlist using reflector..."
    /usr/bin/pacman --noconfirm -Syy ; /usr/bin/pacman --noconfirm -S reflector
    /usr/bin/cp -v -f /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
    # use --verbose for testing
    /usr/bin/reflector --verbose --country 'United States' -l 20 -p http --sort rate --save /etc/pacman.d/mirrorlist
    /usr/bin/pacman --noconfirm -Syy

    # install base, base-devel, and some other stuff
    echo "bootstrapping..."
    /usr/bin/pacstrap /mnt base base-devel vim zsh git screen irssi

    # generate an fstab using uuids
    echo "generating an fstab..."
    /usr/bin/genfstab -U /mnt > /mnt/etc/fstab

    # make sure it's alright
    /usr/bin/cat /mnt/etc/fstab

    # if genfstab is wrong, allow changes to be made
    # TODO: clean these conditional statements up, they suck
    read -p "does this look correct? [y/n]: " ans
    if [ "$ans" == "n" ]; then
        /usr/bin/nano -w /mnt/etc/fstab
    else
        echo "good to know"
    fi

    # just in case...
    read -p "done making changes? [y/n]: " isdone
    if [ "$isdone" == "n" ]; then
        /usr/bin/nano -w /mnt/etc/fstab
        exit 0
    else
        exit 0
    fi
}

prepare ()
{
    #TODO: properly run commands within chroot
}
