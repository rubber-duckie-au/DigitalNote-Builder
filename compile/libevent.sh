#! /usr/bin/env bash

cd temp

tar xvfz ../../../download/libevent-2.1.12-stable.tar.gz

cd libevent-2.1.12-stable

./autogen.sh
./configure --disable-openssl --disable-samples --disable-libevent-regress --prefix=$PWD/../../libs/libevent-2.1.12-stable $1 CFLAGS="-Wno-incompatible-pointer-types"
make $2
make install
