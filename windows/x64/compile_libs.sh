#! /usr/bin/env bash

mkdir -p temp
mkdir -p libs

export TARGET_OS=NATIVE_WINDOWS

# gmp.sh here is the Windows-specific version that uses MSYS2 package
../../compile/berkeleydb.sh "build_windows" "--enable-mingw" $1
../../compile/boost.sh "toolset=gcc address-model=64 $1"
bash gmp.sh
../../compile/leveldb.sh $1
../../compile/libevent.sh "" $1
../../compile/miniupnpc.sh "libminiupnpc.a" $1
../../compile/openssl.sh "mingw64" $1
../../compile/qrencode.sh "" $1
../../compile/secp256k1.sh "" $1
../../compile/qt.sh "-platform win32-g++" $1
