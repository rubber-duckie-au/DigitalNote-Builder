#! /usr/bin/env bash
# DigitalNote v2.0.0.7 — macOS Intel (x86_64) library build
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
# Architecture-specific points for x64:
#   * openssl.sh target = darwin64-x86_64-cc
#   * qt.sh has no extra flag — Qt 5.15.7's configure defaults to x86_64,
#     which is correct for Intel macs.
 
mkdir -p temp
mkdir -p libs
 
# GMP: built statically from source so the resulting daemon binary has no
# runtime dependency on Homebrew's libgmp.dylib. update.sh still installs
# Homebrew's gmp because secp256k1's ./configure picks up gmp.h from there
# during its own (separate) compile.
 
bash ../../compile/berkeleydb.sh "build_unix" "" $1
bash ../../compile/boost.sh      "address-model=64 toolset=clang $1"
bash ../../compile/leveldb.sh    $1
bash ../../compile/libevent.sh   "" $1
bash ../../compile/miniupnpc.sh  "libminiupnpc.a" $1
bash ../../compile/openssl.sh    "darwin64-x86_64-cc" $1
bash ../../compile/qrencode.sh   "" $1
bash ../../compile/secp256k1.sh  "" $1
bash ../../compile/gmp.sh        "--with-pic" $1
# v2.0.0.9: migrated to Qt6.
#
# -DFEATURE_framework=OFF: macOS Qt6 builds FRAMEWORKS by default even for a
# static build (lib/QtCore.framework/QtCore -- a static lib with no .a suffix).
# Qt5's -static implied no frameworks, so this keeps the output layout matching
# the other platforms and the existing .pri expectations.
#
# patch/qiosurfacegraphicsbuffer.h is deliberately NOT applied: the Qt6 cocoa
# plugin built clean without it in probe run 5.  If a cocoa build ever fails
# here, re-derive that patch against Qt6 rather than restoring the Qt5 copy.
bash ../../compile/qt6.sh         "-DFEATURE_framework=OFF" $1
bash ../../compile/qt6_tools.sh   "-DFEATURE_framework=OFF" $1