#! /usr/bin/env bash

cd temp

tar xfz ../../../download/openssl-1.1.1w.tar.gz

cd openssl-1.1.1w

#./Configure LIST

./Configure --prefix=$PWD/../../libs/openssl-1.1.1w no-zlib no-shared no-dso no-camellia no-capieng no-cast no-cms no-dtls1 no-gost no-idea no-md2 no-mdc2 no-rc5 no-rdrand no-rfc3779 no-sctp no-seed no-whirlpool no-rc2 no-rc4 no-ssl3 $1

make depend
make $2
make install
