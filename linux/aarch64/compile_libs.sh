#! /usr/bin/env bash

mkdir -p temp
mkdir -p libs
mkdir -p config

export CC=aarch64-linux-gnu-gcc
export CXX=aarch64-linux-gnu-g++

echo 'using gcc : aarch64 : aarch64-linux-gnu-g++ ;' > config/user-config.jam

echo "===================================================="
echo "Starting aarch64 library compilation - $(date)"
echo "===================================================="

echo ">>> [1/8] BerkeleyDB..."
../../compile/berkeleydb.sh "build_unix" "--host aarch64-linux-gnu" $1
echo ">>> [1/8] BerkeleyDB DONE - $(date)"

echo ">>> [2/8] Boost..."
../../compile/boost.sh "--user-config=../../config/user-config.jam toolset=gcc-aarch64 architecture=arm address-model=64 target-os=linux $1"
echo ">>> [2/8] Boost DONE - $(date)"

echo ">>> [3/8] GMP..."
../../compile/gmp.sh "--host aarch64-linux-gnu" $1
echo ">>> [3/8] GMP DONE - $(date)"

echo ">>> [4/8] leveldb..."
../../compile/leveldb.sh $1
echo ">>> [4/8] leveldb DONE - $(date)"

echo ">>> [5/8] libevent..."
../../compile/libevent.sh "--host aarch64-linux-gnu" $1
echo ">>> [5/8] libevent DONE - $(date)"

echo ">>> [6/8] miniupnpc..."
../../compile/miniupnpc.sh "libminiupnpc.a" $1
echo ">>> [6/8] miniupnpc DONE - $(date)"

echo ">>> [7/8] OpenSSL..."
../../compile/openssl.sh "linux-aarch64" $1
echo ">>> [7/8] OpenSSL DONE - $(date)"

echo ">>> [8/8] qrencode..."
../../compile/qrencode.sh "--host aarch64-linux-gnu" $1
echo ">>> [8/8] qrencode DONE - $(date)"

echo ">>> [9/9] secp256k1..."
../../compile/secp256k1.sh "--host aarch64-linux-gnu" $1
echo ">>> [9/9] secp256k1 DONE - $(date)"

echo ">>> [Qt] Qt 5.15.7 (this takes 1-2 hours)..."
../../compile/qt.sh "-platform linux-g++ -xplatform linux-aarch64-gnu-g++ -bundled-xcb-xinput -fontconfig -system-freetype" ""
echo ">>> [Qt] Qt DONE - $(date)"

echo "===================================================="
echo "All aarch64 libraries compiled successfully - $(date)"
echo "===================================================="
