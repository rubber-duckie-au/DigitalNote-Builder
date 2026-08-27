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


# GMP: provided by libgmp-dev system package (see CI update.sh)
# No need to compile from source

../../compile/berkeleydb.sh "build_unix" "" $JOBS_FLAG
../../compile/boost.sh "address-model=64 toolset=gcc $JOBS_FLAG"
../../compile/libevent.sh "" $JOBS_FLAG
../../compile/miniupnpc.sh "libminiupnpc.a" $JOBS_FLAG
../../compile/openssl.sh "linux-x86_64" $JOBS_FLAG
../../compile/qrencode.sh "" $JOBS_FLAG
# v2.0.0.9: migrated to Qt6.  The Qt5 flags do not carry over -- qt6.sh
# expresses the same intent as CMake feature flags internally.  qttools is a
# SEPARATE build and is REQUIRED: it provides lrelease, and the .qm files
# lrelease generates are gitignored build artifacts, so a fresh clone cannot
# build the wallet without it.
../../compile/qt6.sh "" $JOBS_FLAG
../../compile/qt6_tools.sh "" $JOBS_FLAG
