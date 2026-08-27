#! /usr/bin/env bash

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


export TARGET_OS=NATIVE_WINDOWS

# gmp.sh here is the Windows-specific version that uses MSYS2 package
../../compile/berkeleydb.sh "build_windows" "--enable-mingw" $JOBS_FLAG
../../compile/boost.sh "toolset=gcc address-model=64 $JOBS_FLAG"
bash gmp.sh
../../compile/leveldb.sh $JOBS_FLAG
../../compile/libevent.sh "" $JOBS_FLAG
../../compile/miniupnpc.sh "libminiupnpc.a" $JOBS_FLAG
../../compile/openssl.sh "mingw64" $JOBS_FLAG
../../compile/qrencode.sh "" $JOBS_FLAG
../../compile/secp256k1.sh "" $JOBS_FLAG
../../compile/qt6.sh "-G Ninja" $JOBS_FLAG
../../compile/qt6_tools.sh "-G Ninja" $JOBS_FLAG