#! /usr/bin/bash

mkdir -p temp
mkdir -p libs

echo "Starting macOS library compilation - $(date)"

bash ../../compile/berkeleydb.sh "build_unix" "" $1

bash ../../compile/boost.sh "address-model=64 toolset=clang $1"

bash ../../compile/gmp.sh "" $1

bash ../../compile/leveldb.sh $1

bash ../../compile/libevent.sh "" $1

bash ../../compile/miniupnpc.sh "libminiupnpc.a" $1

bash ../../compile/openssl.sh "darwin64-x86_64-cc" $1

bash ../../compile/qrencode.sh "" $1

bash ../../compile/secp256k1.sh "" $1

bash ../../compile/qt.sh "" $1

echo "All macOS libraries compiled successfully - $(date)"
