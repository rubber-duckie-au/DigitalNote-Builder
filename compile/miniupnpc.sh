#! /usr/bin/env bash

cd temp

tar xvfz ../../../download/miniupnpc-2.2.8.tar.gz

cd miniupnpc-2.2.8

make -f Makefile.mingw libminiupnpc.a $2

INSTALLPREFIX=$PWD/../../libs/miniupnpc-2.2.8

mkdir -p $INSTALLPREFIX/include/miniupnpc
mkdir -p $INSTALLPREFIX/lib

cp include/*h $INSTALLPREFIX/include/miniupnpc
cp $1 $INSTALLPREFIX/lib/
