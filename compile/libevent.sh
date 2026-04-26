#! /usr/bin/env bash

cd temp

tar xvfz ../../../download/libevent-2.1.12-stable.tar.gz

cd libevent-2.1.12-stable

./autogen.sh
./configure \
    --disable-openssl \
    --disable-samples \
    --disable-libevent-regress \
    --prefix=$PWD/../../libs/libevent-2.1.12-stable \
    CFLAGS="-Wno-incompatible-pointer-types" \
    $1
make $2
make install
