#! /usr/bin/env bash
#
# compile/qt6_tools.sh -- build qttools against an already-installed qtbase.
#
# ============================================================================
# WHY THIS EXISTS
#
# The wallet build REQUIRES lrelease, and lrelease ships in qttools, not
# qtbase.  Qt5 got it for free because compile/qt.sh unpacked qt-everywhere
# (which bundles every module) and never passed `-skip qttools`.  The Qt6
# probe built qtbase alone -- correct for proving the toolchain, wrong for
# building the wallet -- so lrelease was missing and compile_app.sh died with:
#
#     'C:/.../libs/qt-6.8.3/bin\lrelease.exe' is not recognized as an
#     internal or external command
#
# This is NOT optional and the .qm files cannot be shipped instead:
# .gitignore:19 is `*.qm`, so they are build artifacts.  A fresh clone has
# none, and src/qt/bitcoin.qrc references them explicitly
# (<file alias="ar">../../.qm/bitcoin_ar.qm</file>), so rcc would fail.
# lrelease must run at build time.
#
# ORDER: run compile/qt6.sh FIRST.  qttools is a Qt module and configures
# against an installed qtbase -- it cannot build standalone.
#
# INSTALLS INTO THE SAME PREFIX as qtbase, so $$[QT_INSTALL_BINS] resolves
# lrelease without any change to include/release.pri.
#
# USAGE:  qt6_tools.sh "<extra cmake args>" "<make -j flag>"
#         Same two-argument shape as qt6.sh.
# ============================================================================

set -euo pipefail

QT_VER="${QT_VER:-6.8.3}"

EXTRA_CMAKE="${1:-}"
MAKE_FLAG="${2:-}"

cd temp

TARBALL="../../../download/qttools-everywhere-src-${QT_VER}.tar.xz"

if [ ! -f "$TARBALL" ]; then
	echo "ERROR: $TARBALL not found."
	echo "       Run ./download.sh from the repository root (it fetches qtbase AND qttools)."
	exit 1
fi

# See qt6.sh for QT_PREFIX_OVERRIDE.  qttools MUST install alongside the qtbase
# it was configured against, so both scripts have to honour the same override.
if [ -n "${QT_PREFIX_OVERRIDE:-}" ]; then
	PREFIX="$QT_PREFIX_OVERRIDE"
else
	PREFIX="$PWD/../libs/qt-${QT_VER}"
fi

if [ ! -x "$PREFIX/bin/qmake" ] && [ ! -x "$PREFIX/bin/qmake.exe" ]; then
	echo "ERROR: no qtbase install found at $PREFIX"
	echo "       Run compile/qt6.sh first -- qttools configures against qtbase."
	exit 1
fi

echo "==> extracting qttools ${QT_VER}"
tar -xf "$TARBALL"

cd "qttools-everywhere-src-${QT_VER}"

# Same MinGW RC-compiler pin as qt6.sh -- see the long note there.  qttools
# builds Windows executables (lrelease.exe et al), each with version-info .rc
# resources, so it hits the identical /usr/bin/windres vs /mingw64/bin/windres
# trap.
if [ -n "${MINGW_PREFIX:-}" ] && [ -x "${MINGW_PREFIX}/bin/windres.exe" ]; then
	case "$EXTRA_CMAKE" in
		*CMAKE_RC_COMPILER*) : ;;
		*) EXTRA_CMAKE="$EXTRA_CMAKE -DCMAKE_RC_COMPILER=${MINGW_PREFIX}/bin/windres.exe" ;;
	esac
	echo "==> pinned RC compiler: ${MINGW_PREFIX}/bin/windres.exe"
fi

echo "==> configuring qttools"
echo "    qtbase prefix: $PREFIX"
echo "    extra cmake:   ${EXTRA_CMAKE:-<none>}"

# We only need the translation tools (lrelease / lupdate / lconvert).  Qt
# Designer, Assistant, Linguist's GUI, qdoc and the rest pull in extra
# dependencies (qtdeclarative for some) and are not used by the wallet build,
# so they are turned off.  If a future need appears, drop the relevant -D.
# shellcheck disable=SC2086
# NOTE: no comments inside the argument list below -- a '#' line between
# backslash continuations TRUNCATES the command and the remaining flags become
# stray commands.  bash -n does not catch it.
#
# FEATURE_qdoc=OFF / clang / clangcpp:
#   qdoc is the only qttools component that needs libclang, and we never build
#   documentation.  With it enabled, configure calls find_package(Clang), which
#   on the GitHub Ubuntu runners resolves a BROKEN clang-14 -- ClangConfig.cmake
#   is installed but the static libs it references are not -- and CMake aborts:
#       The imported target "clangBasic" references the file
#       "/usr/lib/llvm-14/lib/libclangBasic.a" but this file does not exist
#   Disabling qdoc removes the dependency rather than repairing the runner.
#
#   >>> FEATURE_qdoc=OFF ALONE IS NOT ENOUGH. <<<  qt_find_package(WrapLibClang)
#   runs while configure.cmake is being INCLUDED, at the START of feature
#   evaluation -- FEATURE_qdoc is only consulted AFTER the search has already
#   happened.  CMAKE_DISABLE_FIND_PACKAGE_* is what actually stops the search:
#   it makes find_package() return not-found immediately, so the broken
#   ClangConfig.cmake is never read.
#
#   The workflows ALSO delete the broken clang cmake directory before building.
#   Belt and braces: this flag depends on Qt's qt_find_package honouring the
#   standard CMake variable, which is not guaranteed across Qt versions.
#
# The other FEATURE_* flags trim components we do not ship; lrelease, lupdate
# and lconvert are the only reason this module is built at all.
#
# >>> DO NOT ADD -DFEATURE_linguist=OFF. <<<
#
# Tried 2026-08-27 and it was WRONG.  In Qt6 that feature gates the ENTIRE
# linguist module -- lrelease, lupdate and lconvert included, not just the Qt
# Linguist GUI.  The build succeeded and produced none of the three tools:
#     lrelease     MISSING
#     lupdate      MISSING
#     lconvert     MISSING
# There is no separate flag for the GUI alone.
#
# The problem it was meant to solve -- the aarch64 job's HOST build linking
# /usr/lib/aarch64-linux-gnu/libxkbcommon.so, "file in wrong format" -- was
# never a qttools problem.  That job installed the arm64 cross toolchain but
# NOT the host-arch GUI dev packages, so the only libxkbcommon on the system
# was the wrong architecture.  Fixed in ci-linux-aarch64.yml by installing the
# same host-arch dev packages ci-linux-x64.yml already had.
#
# pixeltool and distancefieldgenerator are GUI tools too, disabled for the same
# reason.
# v2.0.0.9: ALWAYS configure into a CLEAN build directory.
#
# `cmake -S . -B build` REUSES an existing build/ and its CMakeCache.txt.  That
# broke the aarch64 cross-build: stage 1 configures qttools for the HOST, stage 2
# reconfigures the SAME source tree for the target, and CMake reported
#
#     You have changed variables that require your cache to be deleted.
#     Configure will be re-run and you may have to reset some variables.
#     CMAKE_CXX_COMPILER= aarch64-linux-gnu-g++
#
# then re-ran with a half-cleared cache in which OpenGL had already been probed
# under HOST assumptions -- surfacing as
#     ERROR: The OpenGL functionality tests failed!
#
# CMake's own recovery is not sufficient here: feature results resolved during
# the first pass survive into the second.  Removing build/ makes each configure
# independent, which is the only way two different toolchains can share one
# extracted source tree.
#
# Cost is a full reconfigure each run; correctness is worth more than the
# seconds saved, and the compile itself is unaffected.
rm -rf build

cmake -S . -B build \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_PREFIX_PATH="$PREFIX" \
	-DCMAKE_INSTALL_PREFIX="$PREFIX" \
	-DBUILD_SHARED_LIBS=OFF \
	-DQT_BUILD_EXAMPLES=OFF \
	-DQT_BUILD_TESTS=OFF \
	-DFEATURE_designer=OFF \
	-DFEATURE_assistant=OFF \
	-DFEATURE_pixeltool=OFF \
	-DFEATURE_distancefieldgenerator=OFF \
	-DFEATURE_qtattributionsscanner=OFF \
	-DFEATURE_qtdiag=OFF \
	-DFEATURE_qtplugininfo=OFF \
	-DFEATURE_qdoc=OFF \
	-DFEATURE_clang=OFF \
	-DFEATURE_clangcpp=OFF \
	-DCMAKE_DISABLE_FIND_PACKAGE_Clang=ON \
	-DCMAKE_DISABLE_FIND_PACKAGE_WrapLibClang=ON \
	$EXTRA_CMAKE

echo "==> building qttools"
# shellcheck disable=SC2086
cmake --build build $MAKE_FLAG

echo "==> installing into $PREFIX"
cmake --install build

echo
echo "==> qttools ${QT_VER} COMPLETE"
echo
echo "==> translation tools (the reason this module is built)"
# This check is FATAL, deliberately.
#
# It previously only PRINTED "MISSING" and let the script succeed, so a qttools
# build that produced no lrelease would be cached as good and the failure would
# surface much later -- during the wallet build, as an unresolved .qm reference
# that points nowhere near the real cause.
#
# It also guards the FEATURE_* trimming above: if a future flag change removes
# a tool we actually need, this stops immediately instead of poisoning a cache.
missing=""

for t in lrelease lupdate lconvert; do
	if [ -x "$PREFIX/bin/${t}" ] || [ -x "$PREFIX/bin/${t}.exe" ]; then
		printf '    %-12s OK\n' "$t"
	else
		printf '    %-12s MISSING\n' "$t"
		missing="$missing $t"
	fi
done

if [ -n "$missing" ]; then
	echo
	echo "ERROR: qttools built but these tools are absent:$missing"
	echo "       The wallet build needs lrelease to generate .qm files from"
	echo "       src/qt/locale/*.ts.  Those .qm files are gitignored build"
	echo "       artifacts, so a fresh clone cannot resolve bitcoin.qrc without"
	echo "       them.  Check the FEATURE_* flags in this script."
	echo
	exit 1
fi
echo
