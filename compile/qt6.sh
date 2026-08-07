#! /usr/bin/env bash
#
# compile/qt6.sh -- STATIC Qt6 build (PROBE ONLY)
#
# ============================================================================
# THIS IS A VERIFICATION EXERCISE, NOT A RELEASE SCRIPT.
#
# It lives on the `qt6-probe` branch and must NOT be merged to master until
# the wallet's Qt6 API migration is done and all five targets build.  The
# release CI clones DigitalNote-Builder with no -b flag, so it always gets
# master -- that is what keeps this invisible to the release flow.  Do not
# add a ref parameter to the release workflows while this branch exists.
# ============================================================================
#
# WHAT CHANGED FROM qt.sh (Qt 5.15.7) AND WHY
#
# 1. ./configure IS GONE.  Qt6 builds with CMake.  The whole flag set had to
#    be re-expressed:
#       -static                -> -DBUILD_SHARED_LIBS=OFF
#       -release               -> -DCMAKE_BUILD_TYPE=Release
#       -prefix X              -> -DCMAKE_INSTALL_PREFIX=X
#       -qt-zlib etc           -> -DFEATURE_system_zlib=OFF (per feature)
#       -no-opengl             -> -DINPUT_opengl=no
#
#    >>> FEATURE_ vs QT_FEATURE_ -- THE TRAP THAT COST RUN 1 <<<
#    In Qt6, `FEATURE_<name>` is the USER INPUT variable and
#    `QT_FEATURE_<name>` is the INTERNAL COMPUTED RESULT.  Setting the
#    QT_-prefixed form does nothing: Qt recomputes and overwrites it.  And
#    because Qt's own build system DOES read those variables, CMake emits no
#    "unused variable" warning -- so there is no smoking gun.  Run 1 set
#    -DQT_FEATURE_opengl=OFF, Qt ignored it, auto-detected OpenGL, and the
#    functionality test failed at configure.
#    Value-type options (opengl is no/desktop/es2/dynamic, not a boolean) use
#    the `INPUT_<name>` form, which is exactly what Qt5's configure generated.
#    Note QT_BUILD_EXAMPLES / QT_BUILD_TESTS / QT_BUILD_BENCHMARKS ARE
#    correctly QT_-prefixed -- they are build options, not features.
#       -skip qtfoo            -> not needed; we build qtbase ALONE
#       -nomake tools/examples -> -DQT_BUILD_TOOLS_BY_DEFAULT / EXAMPLES=OFF
#       make && make install   -> cmake --build && cmake --install
#
# 2. WE BUILD qtbase ONLY, not qt-everywhere.
#    include/app/qt_settings.pri asks for: core gui widgets network
#    (printsupport is declared but ZERO files use QPrint* -- drop it).
#    All four live in qtbase.  The old -skip list existed because
#    qt-everywhere unpacks everything; building qtbase alone makes the
#    entire list unnecessary and cuts build time substantially.  That
#    matters: the release libs job is already provisioned at
#    timeout-minutes: 360, which is GitHub's 6-hour ceiling.
#
# 3. ALL EIGHT q*_p.h FORWARDING PATCHES ARE DELETED -- not ported.
#    qt.sh:23-32 copied shims into:
#       qtbase/include/QtFontDatabaseSupport/5.15.7/.../private
#       qtbase/include/QtEventDispatcherSupport/5.15.7/.../private
#       qtbase/include/QtWindowsUIAutomationSupport/5.15.7/.../private
#    Those were internal Qt5 "support" modules.  Qt6 FOLDED THEM INTO QtGui
#    and the platform plugins, and deleted src/platformsupport/ entirely.
#    The destination directories do not exist, so those cp lines would
#    ERROR, not silently no-op.  Whether static-Windows Qt6 has some
#    equivalent problem is UNKNOWN until this probe runs -- that is
#    precisely what target 2 is for.
#
# 4. THE libpng <fp.h> sed IS DROPPED.  qt.sh's own comment says "drop this
#    when Qt upgrades its bundled libpng to >= 1.6.40".  Qt6 does.  Left out
#    rather than carried as a no-op so nobody wonders whether it is load-
#    bearing.  If a macOS Clang build trips something similar, re-derive it
#    then -- do not assume this exact sed is the answer.
#
# 5. qiosurfacegraphicsbuffer.h (macOS cocoa) IS NOT CARRIED OVER.
#    It is a full modified upstream Qt source file, not a shim, so it cannot
#    be ported blind.  macOS is deliberately targets 3-4 in the probe order;
#    re-derive against Qt6's cocoa plugin when you get there.
#
# USAGE:  qt6.sh "<extra cmake args>" "<make -j flag>"
#         Mirrors qt.sh's two-argument shape so the per-target scripts read
#         the same way.
#
# ARTIFACTS ARE DISPOSABLE.  This proves the toolchain builds; it does not
# produce anything to keep.

set -euo pipefail

QT_VER="${QT_VER:-6.8.3}"
QT_SERIES="$(echo "$QT_VER" | cut -d. -f1,2)"

EXTRA_CMAKE="${1:-}"
MAKE_FLAG="${2:-}"

cd temp

TARBALL="../../../download/qtbase-everywhere-src-${QT_VER}.tar.xz"

if [ ! -f "$TARBALL" ]; then
	echo "ERROR: $TARBALL not found."
	echo "       Fetch it with download_qt6.sh (qtbase only, not qt-everywhere)."
	exit 1
fi

echo "==> extracting qtbase ${QT_VER}"
tar -xf "$TARBALL"

cd "qtbase-everywhere-src-${QT_VER}"

PREFIX="$PWD/../../libs/qt-${QT_VER}"

echo "==> configuring (static, qtbase only)"
echo "    prefix:      $PREFIX"
echo "    extra cmake: ${EXTRA_CMAKE:-<none>}"

# NOTE ON FEATURE FLAGS.  Qt5's -qt-zlib / -qt-libpng / -qt-libjpeg /
# -qt-freetype / -qt-pcre meant "use Qt's bundled copy, not the system one".
# The Qt6 equivalent is to turn the corresponding system_* feature OFF.
# Kept identical to the Qt5 build's intent so this probe isolates the
# TOOLCHAIN change rather than mixing in a dependency-sourcing change.
# shellcheck disable=SC2086
cmake -S . -B build \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX="$PREFIX" \
	-DBUILD_SHARED_LIBS=OFF \
	-DQT_BUILD_EXAMPLES=OFF \
	-DQT_BUILD_TESTS=OFF \
	-DQT_BUILD_BENCHMARKS=OFF \
	-DFEATURE_system_zlib=OFF \
	-DFEATURE_system_libpng=OFF \
	-DFEATURE_system_libjpeg=OFF \
	-DFEATURE_system_freetype=OFF \
	-DFEATURE_system_pcre2=OFF \
	-DFEATURE_sql=OFF \
	-DFEATURE_dbus=OFF \
	-DINPUT_opengl=no \
	$EXTRA_CMAKE

# ---------------------------------------------------------------------------
# Verify the feature flags actually took effect.
#
# This check exists because of the 2026-08-07 run-1 failure: the flags were
# originally written as -DQT_FEATURE_<name>, which Qt6 SILENTLY IGNORES (see
# the header note).  CMake issued no unused-variable warning, so the only
# symptom was OpenGL being auto-detected and its functionality test failing
# 23 seconds in.  Printing the resolved values means a wrong flag name shows
# up as a wrong VALUE here rather than as a mystery failure later.
# ---------------------------------------------------------------------------
echo
echo "==> resolved feature values (confirm these match intent)"
# Read CMakeCache.txt DIRECTLY.  Run 2 used `cmake -L -N build` here and got
# blank output for every feature: QT_FEATURE_* are INTERNAL cache entries, and
# `cmake -L` only lists non-advanced, non-internal ones (-LA does not help
# either).  Grepping the cache file is the only reliable read.
for f in opengl system_zlib system_libpng system_libjpeg system_freetype \
         system_pcre2 sql dbus static; do
	val="$(grep -E "^QT_FEATURE_${f}:" build/CMakeCache.txt 2>/dev/null | head -1 | cut -d= -f2-)"
	printf '    %-20s %s\n' "$f" "${val:-<not in cache>}"
done
echo
# Corroborating evidence that does not depend on the cache at all: if the
# bundled feature flags took effect, Qt builds its OWN copies and the names
# are unmistakable.  This is how run 2 was actually verified.
echo "==> bundled 3rd-party libs (presence proves FEATURE_system_*=OFF worked)"
ls "$PREFIX/lib" 2>/dev/null | grep -E "^libQt6Bundled" | sed 's/^/    /' || echo "    (none found)"
echo

echo "==> building"
# shellcheck disable=SC2086
cmake --build build $MAKE_FLAG

echo "==> installing to $PREFIX"
cmake --install build

echo
echo "==> qtbase ${QT_VER} static build COMPLETE"
echo "    prefix: $PREFIX"
ls -la "$PREFIX/lib" 2>/dev/null | head -20 || true
