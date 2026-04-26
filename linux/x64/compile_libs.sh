#! /usr/bin/env bash

mkdir -p temp
mkdir -p libs

echo "===================================================="
echo "Starting library compilation - $(date)"
echo "===================================================="

echo ">>> [1/8] BerkeleyDB..."
../../compile/berkeleydb.sh "build_unix" "" $1
echo ">>> [1/8] BerkeleyDB DONE - $(date)"

echo ">>> [2/8] Boost..."
../../compile/boost.sh "address-model=64 toolset=gcc $1"
echo ">>> [2/8] Boost DONE - $(date)"

echo ">>> [3/8] GMP..."
../../compile/gmp.sh "" $1
echo ">>> [3/8] GMP DONE - $(date)"

echo ">>> [4/8] libevent..."
../../compile/libevent.sh "" $1
echo ">>> [4/8] libevent DONE - $(date)"

echo ">>> [5/8] miniupnpc..."
../../compile/miniupnpc.sh "libminiupnpc.a" $1
echo ">>> [5/8] miniupnpc DONE - $(date)"

echo ">>> [6/8] OpenSSL..."
../../compile/openssl.sh "linux-x86_64" $1
echo ">>> [6/8] OpenSSL DONE - $(date)"

echo ">>> [7/8] qrencode..."
../../compile/qrencode.sh "" $1
echo ">>> [7/8] qrencode DONE - $(date)"

echo ">>> [8/8] Qt 5.15.7 (this takes 1-2 hours)..."
../../compile/qt.sh "-bundled-xcb-xinput -fontconfig -system-freetype" $1
echo ">>> [8/8] Qt DONE - $(date)"

echo "===================================================="
echo "All libraries compiled successfully - $(date)"
echo "===================================================="
