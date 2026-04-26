#! /usr/bin/env bash

cd temp

tar xfz ../../../download/boost_1_80_0.tar.gz

cd boost_1_80_0

./bootstrap.sh mingw

./b2 install --prefix=$PWD/../../libs/boost_1_80_0 --with-chrono --with-filesystem --with-program_options --with-system --with-thread variant=release link=static threading=multi runtime-link=static stage $1
