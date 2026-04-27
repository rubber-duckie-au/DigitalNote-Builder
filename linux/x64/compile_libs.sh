#! /usr/bin/env bash

mkdir -p temp
mkdir -p libs

# GMP: provided by libgmp-dev system package (see CI update.sh)
# No need to compile from source

../../compile/berkeleydb.sh "build_unix" "" $1
../../compile/boost.sh "address-model=64 toolset=gcc $1"
../../compile/libevent.sh "" $1
../../compile/miniupnpc.sh "libminiupnpc.a" $1
../../compile/openssl.sh "linux-x86_64" $1
../../compile/qrencode.sh "" $1
../../compile/qt.sh "-bundled-xcb-xinput -fontconfig -system-freetype" $1
