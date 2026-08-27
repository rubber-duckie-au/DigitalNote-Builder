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
# 8. >>> CORRECTED 2026-08-07: qtbase ALONE IS NOT ENOUGH FOR THE WALLET. <<<
#    The original version of this script built qtbase only, reasoning that the
#    wallet's qt_settings.pri asks for core/gui/widgets/network.  That reasoning
#    was incomplete -- it looked at the QT += modules and missed what the BUILD
#    itself needs:
#
#      a) lrelease.  include/app/qt_settings.pri has `CONFIG += lrelease` and
#         include/release.pri points QMAKE_LRELEASE at $$[QT_INSTALL_BINS].
#         lrelease lives in **qttools**, not qtbase.  Without it the wallet
#         build dies with "lrelease.exe is not recognized".
#         AND the .qm files it produces are **gitignored** (.gitignore:19 is
#         `*.qm`) -- they are BUILD ARTIFACTS, not committed files, so a fresh
#         clone has none and src/qt/bitcoin.qrc cannot resolve its
#         <file>../../.qm/bitcoin_*.qm</file> entries.  lrelease is REQUIRED.
#
#      b) dbus.  This script forced -DFEATURE_dbus=OFF.  Qt5's qt.sh passed NO
#         dbus flag at all and let configure auto-detect, so the Qt5 wallet
#         built with USE_DBUS=1 successfully.  Forcing it off made the Qt6
#         build differ from the Qt5 baseline in a way that broke
#         `QT += dbus` -- a self-inflicted difference, not a Qt6 limitation.
#         The flag is now REMOVED so Qt6 auto-detects exactly as Qt5 did.
#
#    Principle: when reproducing a build, match what the OLD build actually
#    DID, not what its config file appears to ask for.
#
# 7. macOS BUILDS FRAMEWORKS BY DEFAULT, even for a static build.
#    Run 5 (macOS Intel) linked static libs INSIDE framework bundles:
#        [ 38%] Linking CXX static library ../../lib/QtCore.framework/QtCore
#    i.e. lib/QtCore.framework/QtCore, with NO .a extension and NO "Qt6"
#    in the name.  The build was CORRECT; the report script's
#    `[ -f lib/libQt6Core.a ]` test simply could not see it and wrongly said
#    MISSING.  Qt5's -static implied no frameworks, so -DFEATURE_framework=OFF
#    is passed on macOS to match that baseline and keep all five targets
#    producing the same libQt6*.a layout.  probe-report.sh also detects the
#    framework layout as a safety net.
#
# 6. FEATURE_system_libpng / FEATURE_system_libjpeg ARE NOT VALID HERE.
#    Windows run 3 produced:
#        CMake Warning (unused-cli): Manually-specified variables were not
#        used by the project: FEATURE_system_libjpeg, FEATURE_system_libpng
#    Dropped rather than renamed.  Bundled is already the default when no
#    system copy is found -- Linux run 2 produced libQt6BundledLibpng.a with
#    the flag present-but-ignored, so removing it changes nothing.  The most
#    likely explanation is that JPEG/PNG image-format handling is not a
#    qtbase-level feature under this spelling (qtimageformats territory).
#    >>> ANSWERED by the run-5 cache dump: the real names are `system_jpeg`
#    >>> and `system_png` -- no `lib` prefix.  Both are now pinned OFF above.
#    >>> Discovered, not guessed: QT_FEATURE_LABEL_system_jpeg exists and
#    >>> QT_FEATURE_LABEL_system_libjpeg does not.
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

# ---------------------------------------------------------------------------
# MSYS2 / MinGW: pin the RESOURCE compiler to the MinGW64 toolchain.
#
# On a local msys2 build (2026-08-07) CMake resolved the C/C++ compilers
# correctly to C:/msys64/mingw64/bin/ but picked the RC compiler up from
# C:/msys64/usr/bin/windres.exe -- that is the MSYS *unix* binutils, not the
# MinGW64 cross toolchain.  Building Qt's .rc files with it failed:
#     <command-line>: warning: missing terminating " character
#     /usr/bin/windres: no resources
#     FAILED: src/tools/syncqt/.../syncqt_resource.rc.obj
# because the two windres builds differ in how they handle the quoting in
# defines like -DQT_NAMESPACE=\"\".
#
# CI never hit this: the MINGW64 shell puts /mingw64/bin ahead of /usr/bin, so
# the right windres won by PATH order.  A local shell with different PATH
# ordering does not get that for free -- hence pinning it explicitly rather
# than relying on lookup order.
#
# MSYS2 sets MINGW_PREFIX (= /mingw64 in the MINGW64 shell), which is the
# reliable way to locate the correct toolchain.
if [ -n "${MINGW_PREFIX:-}" ] && [ -x "${MINGW_PREFIX}/bin/windres.exe" ]; then
	case "$EXTRA_CMAKE" in
		*CMAKE_RC_COMPILER*) : ;;   # caller already chose one, respect it
		*) EXTRA_CMAKE="$EXTRA_CMAKE -DCMAKE_RC_COMPILER=${MINGW_PREFIX}/bin/windres.exe" ;;
	esac
	echo "==> pinned RC compiler: ${MINGW_PREFIX}/bin/windres.exe"
fi

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
	-DFEATURE_system_freetype=OFF \
	-DFEATURE_system_jpeg=OFF \
	-DFEATURE_system_png=OFF \
	-DFEATURE_system_pcre2=OFF \
	-DFEATURE_sql=OFF \
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
for f in opengl system_zlib system_freetype system_pcre2 system_jpeg \
         system_png sql dbus static framework; do
	# NOTE the `|| true`.  Without it this line KILLS THE SCRIPT under
	# `set -e`: when grep matches nothing it exits 1, and a command
	# substitution in an ASSIGNMENT propagates that status.  That is exactly
	# what happened on Windows run 3 -- configure had SUCCEEDED, then this
	# loop aborted the job at the first feature not present in the cache,
	# before `cmake --build` ever ran.  (Linux run 2 survived the same code
	# shape only because the substitution was an ARGUMENT to printf, whose
	# own exit status is what `set -e` sees.)
	val="$(grep -E "^QT_FEATURE_${f}:" build/CMakeCache.txt 2>/dev/null | head -1 | cut -d= -f2- || true)"
	printf '    %-20s %s\n' "$f" "${val:-<not in cache>}"
done
echo
# DISCOVERY: the real Qt6 feature names for image codecs.
#
# Run 3 showed FEATURE_system_libpng / FEATURE_system_libjpeg are NOT valid
# (CMake: "unused-cli").  Run 4 then exposed a genuine divergence: Windows
# produced libQt6BundledLibjpeg.a but LINUX DID NOT -- Linux built QJpegPlugin
# against a SYSTEM libjpeg from the runner.  For a static release build,
# silently linking whatever libjpeg happens to be installed on a CI runner is
# not acceptable; the Qt5 build forced bundled with -qt-libjpeg.
#
# Rather than guess at a rename, dump every cache entry whose name mentions
# jpeg or png.  Whatever comes back IS the correct flag name to pin.
echo "==> image-codec features present in the cache (find the right name to pin)"
grep -E "^QT_FEATURE_[A-Za-z0-9_]*(jpeg|png)" build/CMakeCache.txt 2>/dev/null \
	| sed 's/^/    /' || echo "    (none matched)"
echo

echo "==> building"
# shellcheck disable=SC2086
cmake --build build $MAKE_FLAG

echo "==> installing to $PREFIX"
cmake --install build

echo
echo "==> qtbase ${QT_VER} static build COMPLETE"
echo "    prefix: $PREFIX"
echo
# Moved here from just-after-configure (run 4 printed an empty list because
# $PREFIX/lib does not exist until `cmake --install` has run).
echo "==> bundled 3rd-party libs (presence proves the bundled flags took effect)"
ls "$PREFIX/lib" 2>/dev/null | grep -E "^libQt6Bundled" | sed 's/^/    /' || echo "    (none found)"
echo
echo "==> modules the wallet requires"
for m in Qt6Core Qt6Gui Qt6Widgets Qt6Network; do
	if [ -f "$PREFIX/lib/lib${m}.a" ]; then
		printf '    %-14s OK  %s\n' "$m" "$(du -h "$PREFIX/lib/lib${m}.a" | cut -f1)"
	else
		printf '    %-14s MISSING\n' "$m"
	fi
done
echo
echo "==> all static libs"
ls "$PREFIX/lib" 2>/dev/null | grep -E '\.a$' | sed 's/^/    /' || true
