#! /usr/bin/env bash

mkdir download
cd download

wget https://download.qt.io/archive/qt/5.15/5.15.7/single/qt-everywhere-opensource-src-5.15.7.tar.xz
wget https://archives.boost.io/release/1.80.0/source/boost_1_80_0.tar.gz
wget https://www.openssl.org/source/old/1.1.1/openssl-1.1.1w.tar.gz
wget http://download.oracle.com/berkeley-db/db-6.2.32.NC.tar.gz
wget https://github.com/libevent/libevent/releases/download/release-2.1.12-stable/libevent-2.1.12-stable.tar.gz
wget http://miniupnp.free.fr/files/download.php?file=miniupnpc-2.2.8.tar.gz -O miniupnpc-2.2.8.tar.gz
wget https://github.com/fukuchi/libqrencode/archive/refs/tags/v4.1.1.tar.gz
#wget https://gmplib.org/download/gmp/gmp-6.2.1.tar.bz2