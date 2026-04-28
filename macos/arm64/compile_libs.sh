#! /usr/bin/env bash
# DigitalNote v2.0.0.7 — macOS Apple Silicon (arm64) library build
#
# This compiles all native libraries DigitalNote needs into ./libs/.
# Run from this directory after ./update.sh (which installs Homebrew deps).
#
# Usage:
#   ./compile_libs.sh                  # serial build
#   ./compile_libs.sh "-j 8"           # parallel with 8 jobs
#
# $1 is forwarded to each compile script as the make-args (-j N).
#
# Architecture-specific points for arm64:
#   * openssl.sh target = darwin64-arm64-cc (native Apple Silicon)
#   * qt.sh extra flag  = QMAKE_APPLE_DEVICE_ARCHS=arm64 (Qt 5.15.7's configure
#     defaults to x86_64 even on Apple Silicon hosts; this forces native arm64)
 
mkdir -p temp
mkdir -p libs
 
# GMP: provided by Homebrew (brew install gmp via update.sh).
# No need to compile from source.
 
bash ../../compile/berkeleydb.sh "build_unix" "" $1
bash ../../compile/boost.sh      "address-model=64 toolset=clang $1"
bash ../../compile/leveldb.sh    $1
bash ../../compile/libevent.sh   "" $1
bash ../../compile/miniupnpc.sh  "libminiupnpc.a" $1
bash ../../compile/openssl.sh    "darwin64-arm64-cc" $1
bash ../../compile/qrencode.sh   "" $1
bash ../../compile/secp256k1.sh  "" $1
bash ../../compile/qt.sh         "QMAKE_APPLE_DEVICE_ARCHS=arm64" $1
 