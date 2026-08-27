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
# The other FEATURE_* flags trim components we do not ship; lrelease, lupdate
# and lconvert are the only reason this module is built at all.
cmake -S . -B build \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_PREFIX_PATH="$PREFIX" \
	-DCMAKE_INSTALL_PREFIX="$PREFIX" \
	-DBUILD_SHARED_LIBS=OFF \
	-DQT_BUILD_EXAMPLES=OFF \
	-DQT_BUILD_TESTS=OFF \
	-DFEATURE_designer=OFF \
	-DFEATURE_assistant=OFF \
	-DFEATURE_qtattributionsscanner=OFF \
	-DFEATURE_qtdiag=OFF \
	-DFEATURE_qtplugininfo=OFF \
	-DFEATURE_qdoc=OFF \
	-DFEATURE_clang=OFF \
	-DFEATURE_clangcpp=OFF \
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
for t in lrelease lupdate lconvert; do
	if [ -x "$PREFIX/bin/${t}" ] || [ -x "$PREFIX/bin/${t}.exe" ]; then
		printf '    %-12s OK\n' "$t"
	else
		printf '    %-12s MISSING  <-- the wallet build will fail without lrelease\n' "$t"
	fi
done
echo
