#!/bin/bash

installdir=/opt/mannheim-network/spacex-script
bin_file=/usr/bin/spacex

if [ $(id -u) -ne 0 ]; then
    echo "Please run with sudo!"
    exit 1
fi

if [ -f "$bin_file" ]; then
    crust stop
    rm /usr/bin/spacex
fi

rm -rf $installdir
