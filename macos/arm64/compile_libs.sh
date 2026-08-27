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
# $JOBS_FLAG is forwarded to each compile script as the make-args (-j N).
#
# Architecture-specific points for arm64:
#   * openssl.sh target = darwin64-arm64-cc (native Apple Silicon)
#   * qt.sh extra flag  = QMAKE_APPLE_DEVICE_ARCHS=arm64 (Qt 5.15.7's configure
#     defaults to x86_64 even on Apple Silicon hosts; this forces native arm64)
 
mkdir -p temp
mkdir -p libs

# v2.0.0.9: default the job count instead of building serially.
#
# $JOBS_FLAG was forwarded straight through with NO default, so calling
# ./compile_libs.sh with no argument built everything single-threaded.
# compile_daemon.sh and compile_app.sh have auto-detected for a while; this
# brings compile_libs.sh in line, using the identical idiom.
#
# nproc on Linux, sysctl on macOS, fallback 2.  An explicit argument still
# wins, so existing callers passing "-j 4" are unaffected.
JOBS_FLAG="${1:--j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)}"

 
# GMP: built statically from source so the resulting daemon binary has no
# runtime dependency on Homebrew's libgmp.dylib. update.sh still installs
# Homebrew's gmp because secp256k1's ./configure picks up gmp.h from there
# during its own (separate) compile.
 
bash ../../compile/berkeleydb.sh "build_unix" "" $JOBS_FLAG
bash ../../compile/boost.sh      "address-model=64 toolset=clang $JOBS_FLAG"
bash ../../compile/leveldb.sh    $JOBS_FLAG
bash ../../compile/libevent.sh   "" $JOBS_FLAG
bash ../../compile/miniupnpc.sh  "libminiupnpc.a" $JOBS_FLAG
bash ../../compile/openssl.sh    "darwin64-arm64-cc" $JOBS_FLAG
bash ../../compile/qrencode.sh   "" $JOBS_FLAG
bash ../../compile/secp256k1.sh  "" $JOBS_FLAG
bash ../../compile/gmp.sh        "--with-pic" $JOBS_FLAG
# v2.0.0.9: migrated to Qt6.
#
# QMAKE_APPLE_DEVICE_ARCHS=arm64 was the Qt5 spelling; the CMake equivalent is
# CMAKE_OSX_ARCHITECTURES.  macos-14 runners are already arm64 so this is a
# NATIVE build, not a cross-build -- the flag is belt-and-braces.
# See macos/x64 for the -DFEATURE_framework=OFF rationale.
bash ../../compile/qt6.sh         "-DCMAKE_OSX_ARCHITECTURES=arm64 -DFEATURE_framework=OFF" $JOBS_FLAG
bash ../../compile/qt6_tools.sh   "-DCMAKE_OSX_ARCHITECTURES=arm64 -DFEATURE_framework=OFF" $JOBS_FLAG
 