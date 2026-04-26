#! /usr/bin/env bash

cd temp

tar -xjvf ../../../download/gmp-6.2.1.tar.bz2

cd gmp-6.2.1

./configure --prefix=$PWD/../../libs/gmp-6.2.1 $1
make $2
make install
