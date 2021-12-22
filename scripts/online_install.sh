#!/bin/bash

version=$1
shift

if [ $(id -u) -ne 0 ]; then
    echo "Please run with sudo!"
    exit 1
fi

wget https://github.com/mannheim-network/spacex-script/archive/v$version.tar.gz
if [ $res -ne 0 ]; then
    echo "Download v$version.tar.gz failed"
    exit 1
fi

tar -xvf v$version.tar.gz
if [ $res -ne 0 ]; then
    echo "Unzip v$version.tar.gz failed"
    rm v$version.tar.gz
    exit 1
fi

./spacex-script-$version/install.sh $@
if [ $res -ne 0 ]; then
    echo "Install spacex node $version failed"
    rm v$version.tar.gz
    rm -rf spacex-script-$version
    exit 1
fi

rm v$version.tar.gz
rm -rf spacex-script-$version
exit 0
