#! /usr/bin/env bash

mkdir -p temp
mkdir -p libs

echo "Starting library compilation - $(date)"

../../compile/berkeleydb.sh "build_unix" "" $1

../../compile/boost.sh "address-model=64 toolset=gcc $1"

../../compile/gmp.sh "" $1

../../compile/libevent.sh "" $1

../../compile/miniupnpc.sh "libminiupnpc.a" $1

../../compile/openssl.sh "linux-x86_64" $1

../../compile/qrencode.sh "" $1

../../compile/qt.sh "-bundled-xcb-xinput -fontconfig -system-freetype" $1

echo "All libraries compiled successfully - $(date)"
