#! /usr/bin/env bash

# v2.0.0.9 Qt6 cross-build: TWO prefixes exist here.
#
#   libs-host/qt-6.8.3  -- x86_64 HOST build.  Its lrelease/moc/rcc/uic RUN on
#                          this machine.  qmake must come from here too.
#   libs/qt-6.8.3       -- aarch64 TARGET build.  Its binaries CANNOT execute
#                          on the build host; only its libraries and headers
#                          are consumed, via the toolchain settings.
#
# Putting the TARGET bin/ on PATH would produce "cannot execute binary file"
# from lrelease.  Host first, deliberately.
export PATH="$PWD/libs-host/qt-6.8.3/bin:$PATH"

cd DigitalNote-2

qmake DigitalNote.app.pro USE_UPNP=1 USE_DBUS=1 USE_QRCODE=1 USE_BUILD_INFO=1 RELEASE=1

# Use first arg if given (e.g. "-j 8"), else auto-detect.
# nproc on Linux, sysctl on macOS, fallback 2.
JOBS_FLAG="${1:--j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)}"
make "$JOBS_FLAG"
