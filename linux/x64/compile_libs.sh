#! /usr/bin/env bash

mkdir -p temp
mkdir -p libs

# GMP: provided by libgmp-dev system package (see CI update.sh)
# No need to compile from source

../../compile/berkeleydb.sh "build_unix" "" $1
../../compile/boost.sh "address-model=64 toolset=gcc $1"
../../compile/libevent.sh "" $1
../../compile/miniupnpc.sh "libminiupnpc.a" $1
../../compile/openssl.sh "linux-x86_64" $1
../../compile/qrencode.sh "" $1
# v2.0.0.9: migrated to Qt6.  The Qt5 flags do not carry over -- qt6.sh
# expresses the same intent as CMake feature flags internally.  qttools is a
# SEPARATE build and is REQUIRED: it provides lrelease, and the .qm files
# lrelease generates are gitignored build artifacts, so a fresh clone cannot
# build the wallet without it.
../../compile/qt6.sh "" $1
../../compile/qt6_tools.sh "" $1
