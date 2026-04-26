#! /usr/bin/env bash

cd temp

tar xvfz ../../../download/openssl-1.1.1w.tar.gz

cd openssl-1.1.1w

./Configure \
    --prefix=$PWD/../../libs/openssl-1.1.1w \
    --openssldir=$PWD/../../libs/openssl-1.1.1w/ssl \
    no-zlib no-shared no-dso no-camellia no-capieng no-cast no-cms \
    no-dtls1 no-gost no-idea no-md2 no-mdc2 no-rc5 no-rdrand no-rfc3779 \
    no-sctp no-seed no-whirlpool no-rc2 no-rc4 no-ssl3 $1

make depend
make $2
make install_sw
