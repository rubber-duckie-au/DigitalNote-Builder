#! /usr/bin/env bash

cd temp

tar xfz ../../../download/v4.1.1.tar.gz

cd libqrencode-4.1.1

./autogen.sh

./configure --enable-static --disable-shared --without-tools --prefix=$PWD/../../libs/qrencode-4.1.1 $1
make $2
make install
