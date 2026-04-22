#! /usr/bin/env bash
 
# GMP is provided by the MSYS2 mingw-w64-x86_64-gmp package.
# No need to compile from source - the package is already installed
# by update.sh and provides:
#   /mingw64/include/gmp.h
#   /mingw64/lib/libgmp.a
#
# DigitalNote_config.pri must point to:
#   DIGITALNOTE_GMP_INCLUDE_PATH = /mingw64/include
#   DIGITALNOTE_GMP_LIB_PATH     = /mingw64/lib
 
if [ ! -f "/mingw64/lib/libgmp.a" ]; then
    echo "GMP not found - installing via pacman..."
    pacman -S --noconfirm mingw-w64-x86_64-gmp
fi
 
echo "GMP ready: $(ls /mingw64/lib/libgmp.a)"
echo "GMP header: $(ls /mingw64/include/gmp.h)"