#! /usr/bin/env bash

# NOTE: for full symbols release modify \DigitalNote-2\include\compiler_settings.pri,
# Comment out "QMAKE_CXXFLAGS =" - change to "## QMAKE_CXXFLAGS =" 

export PATH="$PWD/libs/qt-6.8.3/bin:$PATH"

cd DigitalNote-2

qmake DigitalNote.app.pro USE_UPNP=1 USE_DBUS=1 USE_QRCODE=1 RELEASE=1 \
    "QMAKE_CXXFLAGS+=-O1 -g -ggdb3 -fno-omit-frame-pointer -fno-optimize-sibling-calls" \
    "QMAKE_CFLAGS+=-O1 -g -ggdb3 -fno-omit-frame-pointer -fno-optimize-sibling-calls" \
    "QMAKE_LFLAGS+=-g -ggdb3 -Wl,--build-id" \
    "QMAKE_LFLAGS_RELEASE=" \
    "QMAKE_STRIP=:" \
    "QMAKE_CXXFLAGS_RELEASE=" \
    "QMAKE_CFLAGS_RELEASE=" \

# Use first arg if given (e.g. "-j 8"), else auto-detect.
# nproc on Linux, sysctl on macOS, fallback 2.
make clean

touch src/version.cpp

JOBS_FLAG="${1:--j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)}"
make "$JOBS_FLAG"

# verify the build is symboled and not stripped
echo "=== symbol check ==="
EXE="DigitalNote-qt.exe"   # set to the REAL output path
if [ ! -f "$EXE" ]; then
    echo "ERROR: $EXE not found — adjust the path"
elif objdump -h "$EXE" 2>/dev/null | grep -q "\.debug_info"; then
    echo "OK: $EXE contains DWARF debug sections (.debug_info present)"
    echo "    debug section sizes:"
    objdump -h "$EXE" | grep "\.debug" | awk '{print "      "$2"  "$3" bytes"}'
else
    echo "WARNING: no .debug_info section — build is NOT symboled"
fi