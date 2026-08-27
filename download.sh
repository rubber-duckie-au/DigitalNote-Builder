#! /usr/bin/env bash

mkdir -p download
cd download

# ---------------------------------------------------------------------------
# Qt.
#
# Qt6 is what all five platforms build against.  TWO modules are fetched and
# BOTH are required:
#   qtbase  -- core / gui / widgets / network, everything qt_settings.pri asks
#              for.  qt-everywhere for 6.x is ~1.5 GB and unpacks dozens of
#              modules the wallet never uses, so we take qtbase alone.
#   qttools -- provides lrelease.  NOT optional: qt_settings.pri sets
#              CONFIG += lrelease, and the .qm files it generates are gitignored
#              build artifacts, so a fresh clone cannot build without it.  Qt5
#              got lrelease for free from qt-everywhere; qtbase alone does not.
#
# Qt5 is still fetched because compile/qt.sh is retained for reference and to
# allow a fallback build while the Qt6 migration is being verified.  Once it is
# signed off, delete the Qt5 line and compile/qt.sh together.
#
# wget -c resumes a partial download and skips a complete one, so this script
# is safe to re-run.
# ---------------------------------------------------------------------------
QT5_VER="${QT5_VER:-5.15.7}"
QT6_VER="${QT6_VER:-6.8.3}"
QT6_SERIES="$(echo "$QT6_VER" | cut -d. -f1,2)"

# -- Qt5 (fallback only; no platform calls compile/qt.sh any more) ----------
wget -c "https://download.qt.io/archive/qt/5.15/${QT5_VER}/single/qt-everywhere-opensource-src-${QT5_VER}.tar.xz"

# -- Qt6 (ALL five platforms) -----------------------------------------------
wget -c "https://download.qt.io/archive/qt/${QT6_SERIES}/${QT6_VER}/submodules/qtbase-everywhere-src-${QT6_VER}.tar.xz"
wget -c "https://download.qt.io/archive/qt/${QT6_SERIES}/${QT6_VER}/submodules/qttools-everywhere-src-${QT6_VER}.tar.xz"

wget https://archives.boost.io/release/1.91.0/source/boost_1_91_0.tar.gz
wget https://github.com/openssl/openssl/releases/download/openssl-3.5.7/openssl-3.5.7.tar.gz
wget http://download.oracle.com/berkeley-db/db-6.2.32.NC.tar.gz
wget https://github.com/libevent/libevent/releases/download/release-2.1.12-stable/libevent-2.1.12-stable.tar.gz
wget http://miniupnp.free.fr/files/download.php?file=miniupnpc-2.2.8.tar.gz -O miniupnpc-2.2.8.tar.gz
wget https://github.com/fukuchi/libqrencode/archive/refs/tags/v4.1.1.tar.gz
#wget https://gmplib.org/download/gmp/gmp-6.2.1.tar.bz2