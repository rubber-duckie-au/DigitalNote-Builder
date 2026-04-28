#! /usr/bin/env bash

#! /usr/bin/env bash

# Compile libevent 2.1.12 with modern compilers.
#
# Two fixes for GCC 14+/15+ which promote several warnings to default errors:
#   1. --disable-samples / --disable-libevent-regress skip the test/example
#      programs (sample/http-server.c trips -Werror=incompatible-pointer-types
#      on MinGW64 because evutil_socket_t is intptr_t/64-bit but the sample
#      declares signal handlers with int/32-bit). The library itself is fine.
#   2. -Wno-error=... in CFLAGS, in case any other translation unit in the
#      library proper trips the same family of errors on a future compiler.
#
# Args:
#   $1 = extra configure flags (e.g. for cross-compile)
#   $2 = make parallel flags (e.g. "-j 4")

cd temp

tar xvfz ../../../download/libevent-2.1.12-stable.tar.gz

cd libevent-2.1.12-stable

./autogen.sh

./configure \
    --disable-openssl \
    --disable-samples \
    --disable-libevent-regress \
    --prefix=$PWD/../../libs/libevent-2.1.12-stable \
    $1 \
    CFLAGS="-Wno-error=incompatible-pointer-types -Wno-incompatible-pointer-types -Wno-error=implicit-function-declaration -Wno-implicit-function-declaration -Wno-error=int-conversion -Wno-int-conversion"

make $2
make install