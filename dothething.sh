#!/bin/bash
# install arch without intervention

HOSTNAME="loki" # only need short form
LOCALE="en_US.UTF-8" # :911:
TIMEZONE="America/Detroit" # :911:

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
    fi
}
