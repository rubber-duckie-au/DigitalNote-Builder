#! /usr/bin/env bash

mkdir -p temp
mkdir -p libs
mkdir -p config

export CC=aarch64-linux-gnu-gcc
export CXX=aarch64-linux-gnu-g++

echo 'using gcc : aarch64 : aarch64-linux-gnu-g++ ;' > config/user-config.jam

../../compile/berkeleydb.sh "build_unix" "--host aarch64-linux-gnu" $1
../../compile/boost.sh "--user-config=../../config/user-config.jam toolset=gcc-aarch64 architecture=arm address-model=64 target-os=linux $1"
../../compile/gmp.sh "--host aarch64-linux-gnu" $1
../../compile/leveldb.sh $1
../../compile/libevent.sh "--host aarch64-linux-gnu" $1
../../compile/miniupnpc.sh "libminiupnpc.a" $1
../../compile/openssl.sh "linux-aarch64" $1
../../compile/qrencode.sh "--host aarch64-linux-gnu" $1
../../compile/secp256k1.sh "--host aarch64-linux-gnu" $1
../../compile/qt.sh "-platform linux-g++ -xplatform linux-aarch64-gnu-g++ -bundled-xcb-xinput -fontconfig -system-freetype" ""
