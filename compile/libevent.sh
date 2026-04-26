#! /usr/bin/env bash

cd temp

tar xfz ../../../download/libevent-2.1.12-stable.tar.gz

cd libevent-2.1.12-stable

./autogen.sh
./configure --disable-openssl --prefix=$PWD/../../libs/libevent-2.1.12-stable $1
make $2
make install
