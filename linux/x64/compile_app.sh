#! /usr/bin/env bash

export PATH="$PWD/libs/qt-6.8.3/bin:$PATH"

cd DigitalNote-2

qmake DigitalNote.app.pro USE_UPNP=1 USE_DBUS=1 USE_QRCODE=1 USE_BUILD_INFO=1 RELEASE=1

# Use first arg if given (e.g. "-j 8"), else auto-detect.
# nproc on Linux, sysctl on macOS, fallback 2.
JOBS_FLAG="${1:--j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)}"
make "$JOBS_FLAG"
