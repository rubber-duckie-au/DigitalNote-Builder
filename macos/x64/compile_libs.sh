#! /usr/bin/bash

mkdir -p temp
mkdir -p libs

echo "===================================================="
echo "Starting macOS library compilation - $(date)"
echo "===================================================="

echo ">>> [1/9] BerkeleyDB..."
bash ../../compile/berkeleydb.sh "build_unix" "" $1
echo ">>> [1/9] BerkeleyDB DONE - $(date)"

echo ">>> [2/9] Boost..."
bash ../../compile/boost.sh "address-model=64 toolset=clang $1"
echo ">>> [2/9] Boost DONE - $(date)"

echo ">>> [3/9] GMP..."
bash ../../compile/gmp.sh "" $1
echo ">>> [3/9] GMP DONE - $(date)"

echo ">>> [4/9] leveldb..."
bash ../../compile/leveldb.sh $1
echo ">>> [4/9] leveldb DONE - $(date)"

echo ">>> [5/9] libevent..."
bash ../../compile/libevent.sh "" $1
echo ">>> [5/9] libevent DONE - $(date)"

echo ">>> [6/9] miniupnpc..."
bash ../../compile/miniupnpc.sh "libminiupnpc.a" $1
echo ">>> [6/9] miniupnpc DONE - $(date)"

echo ">>> [7/9] OpenSSL..."
bash ../../compile/openssl.sh "darwin64-x86_64-cc" $1
echo ">>> [7/9] OpenSSL DONE - $(date)"

echo ">>> [8/9] qrencode..."
bash ../../compile/qrencode.sh "" $1
echo ">>> [8/9] qrencode DONE - $(date)"

echo ">>> [9/9] secp256k1..."
bash ../../compile/secp256k1.sh "" $1
echo ">>> [9/9] secp256k1 DONE - $(date)"

echo ">>> [Qt] Qt 5.15.7 (this takes 1-2 hours)..."
bash ../../compile/qt.sh "" $1
echo ">>> [Qt] Qt DONE - $(date)"

echo "===================================================="
echo "All macOS libraries compiled successfully - $(date)"
echo "===================================================="
