#!/bin/bash
# install arch without intervention

HOSTNAME="loki" # only need short form
LOCALE="en_US.UTF-8" # :911:
TIMEZONE="America/Detroit" # :911:
ARCH="$(uname -m)"

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
        /usr/bin/pacman --noconfirm -Syy && /usr/bin/pacman --noconfirm -S reflector
    fi
}

partition ()
{
    # we assume a few things here
    # 1) the disk we're installing to is /dev/sda
    # 2) the disk is at least 500gb in size
    # 3) the system isn't uefi
    # 4) that i know how to properly partition a disk

    ###################
    # 128MB /boot
    # 1GB swap
    # rest of disk /
    ###################
    # if this doesn't work for you, alter it
    # heredocs are fun
    /usr/bin/fdisk /dev/sda <<EOF
    o
    n
    p
    1

    +128M
    n
    p
    2

    +1G
    n
    p
    3


    w
    EOF
}
