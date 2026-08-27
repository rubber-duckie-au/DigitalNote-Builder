#! /usr/bin/env bash
#
# download_qt6.sh -- fetch qtbase for the Qt6 probe (PROBE ONLY).
#
# Deliberately separate from download.sh so the probe cannot disturb the
# release download set.  Fetches qtbase AND qttools, not qt-everywhere: the wallet
# uses core / gui / widgets / network, all of which live in qtbase.
# (include/app/qt_settings.pri also lists printsupport, but ZERO files in
# src/qt/ use QPrint* -- that line should be deleted, not satisfied.)
#
# qt-everywhere for 6.x is ~1.5 GB and unpacks every module we then have to
# skip.  qtbase alone is a fraction of that, which is the point.

set -euo pipefail

QT_VER="${QT_VER:-6.8.3}"
QT_SERIES="$(echo "$QT_VER" | cut -d. -f1,2)"

mkdir -p download
cd download

BASE="https://download.qt.io/archive/qt/${QT_SERIES}/${QT_VER}/submodules"

# qtbase  -- core/gui/widgets/network, everything the wallet's QT += asks for.
# qttools -- **REQUIRED**, not optional: it provides lrelease.
#            include/app/qt_settings.pri sets `CONFIG += lrelease` and the .qm
#            files it generates are GITIGNORED (.gitignore:19 = `*.qm`), so they
#            are build artifacts.  src/qt/bitcoin.qrc references them directly,
#            so without lrelease a fresh clone cannot build at all.
#            Qt5 got this for free from qt-everywhere; qtbase alone does not.
for MOD in qtbase qttools; do
	FILE="${MOD}-everywhere-src-${QT_VER}.tar.xz"

	if [ -f "$FILE" ]; then
		echo "already have $FILE"
	else
		echo "fetching ${BASE}/${FILE}"
		wget "${BASE}/${FILE}"
	fi
done
