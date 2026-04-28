#! /usr/bin/env bash
 
# Compile libqrencode 4.1.1 with modern compilers.
#
# qrencode.c:932 does `return VERSION;` expecting VERSION to be a macro
# defined by autoconf via config.h. On newer autoconf + Clang (as on
# macOS Apple Silicon with Xcode 15), VERSION sometimes doesn't get
# emitted into config.h, causing:
#   qrencode.c:932:9: error: use of undeclared identifier 'VERSION'
# We define it explicitly via CFLAGS as a belt-and-braces fix.
#
# Args:
#   $1 = extra configure flags
#   $2 = make parallel flags
 
cd temp
 
tar xvfz ../../../download/v4.1.1.tar.gz
 
cd libqrencode-4.1.1
 
./autogen.sh
 
./configure \
    --enable-static \
    --disable-shared \
    --without-tools \
    --prefix=$PWD/../../libs/qrencode-4.1.1 \
    $1 \
    CFLAGS='-DVERSION=\"4.1.1\"'
 
make $2
make install