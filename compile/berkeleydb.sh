#! /usr/bin/env bash

# Compile BerkeleyDB 6.2.32 (released 2016) with modern compilers.
#
# GCC 14+ promoted -Werror=incompatible-pointer-types and
# -Werror=implicit-function-declaration to default errors. BDB 6.2.32 has
# old K&R-style function declarations and incompatible pointer casts that
# trigger both. We pass -Wno-error=... to demote them back to warnings,
# AND -Wno-... to silence the noise.
# -Wno-error=int-conversion is also added defensively for GCC 16+.
#
# Args:
#   $1 = build subdirectory (build_unix or build_windows)
#   $2 = extra configure flags (e.g. "--enable-mingw" for Windows)
#   $3 = make parallel flags (e.g. "-j 4")

cd temp

tar xvfz ../../../download/db-6.2.32.NC.tar.gz

cd db-6.2.32.NC/

patch -s -p0 < ../../../../patch/patch-src_dbinc_atomic.h

cd $1

BDB_CFLAGS="-Wno-error=implicit-function-declaration -Wno-implicit-function-declaration \
-Wno-error=incompatible-pointer-types -Wno-incompatible-pointer-types \
-Wno-error=int-conversion -Wno-int-conversion"

BDB_CXXFLAGS="-Wno-error=implicit-function-declaration -Wno-implicit-function-declaration \
-Wno-error=incompatible-pointer-types -Wno-incompatible-pointer-types"

../dist/configure \
    --enable-cxx \
    --disable-shared \
    --disable-replication \
    --prefix=$PWD/../../../libs/db-6.2.32.NC \
    $2 \
    CFLAGS="$BDB_CFLAGS" \
    CXXFLAGS="$BDB_CXXFLAGS"

make $3
make install