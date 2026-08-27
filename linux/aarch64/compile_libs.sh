#! /usr/bin/env bash
# DigitalNote v2.0.0.7 — Linux aarch64 cross-compile library build.
#
# Cross-compiles all native libraries (built ON x86_64 host, FOR arm64
# target) into ./libs/. Run from this directory after ./update.sh.
#
# Usage:
#   ./compile_libs.sh                  # serial build
#   ./compile_libs.sh "-j 8"           # parallel with 8 jobs
#
# $JOBS_FLAG is forwarded to each compile script as the make-args (-j N).
#
# Toolchain expectations (set up by update.sh):
#   * gcc-aarch64-linux-gnu / g++-aarch64-linux-gnu installed
#   * dpkg --add-architecture arm64; arm64 dev libs (see update.sh)
#   * pkg-config configured for /usr/lib/aarch64-linux-gnu/

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

mkdir -p config

export CC=aarch64-linux-gnu-gcc
export CXX=aarch64-linux-gnu-g++

echo 'using gcc : aarch64 : aarch64-linux-gnu-g++ ;' > config/user-config.jam

../../compile/berkeleydb.sh "build_unix" "--host aarch64-linux-gnu" $JOBS_FLAG
../../compile/boost.sh "--user-config=../../config/user-config.jam toolset=gcc-aarch64 architecture=arm address-model=64 target-os=linux $JOBS_FLAG"
../../compile/leveldb.sh $JOBS_FLAG
../../compile/libevent.sh "--host aarch64-linux-gnu" $JOBS_FLAG
../../compile/miniupnpc.sh "libminiupnpc.a" $JOBS_FLAG
../../compile/openssl.sh "linux-aarch64" $JOBS_FLAG
../../compile/qrencode.sh "--host aarch64-linux-gnu" $JOBS_FLAG
../../compile/secp256k1.sh "--host aarch64-linux-gnu" $JOBS_FLAG
# GMP cross-compiled. --disable-assembly avoids gmp's hand-tuned aarch64
# asm needing a newer host as/ld than ubuntu-22.04 ships. Slight perf
# hit, but produces a clean static .a we can link.
../../compile/gmp.sh "--host=aarch64-linux-gnu --disable-assembly" $JOBS_FLAG
# ---------------------------------------------------------------------------
# Qt6 CROSS-COMPILE.  Structurally different from every other platform.
#
# Qt5 cross-compiled in ONE call: -platform linux-g++ -xplatform
# linux-aarch64-gnu-g++.  Qt6 CANNOT do that.  The target build has to RUN host
# tools (moc, rcc, uic) which cannot execute on aarch64, so a HOST Qt6 must be
# built FIRST and the target build pointed at it via QT_HOST_PATH.
#
# Hence TWO builds below, and roughly double the wall time.  That is why
# aarch64 was left until last in the migration.
#
# PKG_CONFIG_LIBDIR still points at arm64 multiarch paths so the TARGET build's
# feature tests resolve against the foreign-arch libs installed via apt :arm64.
# ---------------------------------------------------------------------------

# -- STAGE 1 of 2: HOST x86_64 Qt6, built only for its tools ----------------
# Separate prefix so it can never be mistaken for, or linked against by, the
# target build.  qt6.sh honours QT_PREFIX_OVERRIDE.
QT_HOST_PREFIX="$PWD/libs-host/qt-6.8.3"

QT_PREFIX_OVERRIDE="$QT_HOST_PREFIX" ../../compile/qt6.sh "" $JOBS_FLAG
QT_PREFIX_OVERRIDE="$QT_HOST_PREFIX" ../../compile/qt6_tools.sh "" $JOBS_FLAG

# -- STAGE 2 of 2: the aarch64 TARGET build, against stage 1 ----------------
PKG_CONFIG_LIBDIR=/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig \
PKG_CONFIG_SYSROOT_DIR=/ \
../../compile/qt6.sh "-DQT_HOST_PATH=$QT_HOST_PREFIX -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=aarch64 -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ -DCMAKE_FIND_ROOT_PATH=/usr/aarch64-linux-gnu -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY" $JOBS_FLAG

# NOTE: lrelease must come from the HOST build (stage 1) -- a cross-built
# lrelease cannot run on the build machine.  compile_app.sh puts the HOST
# prefix on PATH for exactly this reason.
