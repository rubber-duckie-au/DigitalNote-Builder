#! /usr/bin/env bash
 
# DigitalNote-2 is cloned inside the platform directory (e.g. windows/x64/)
# CWD = windows/x64/
# DigitalNote-2 = windows/x64/DigitalNote-2/
# libs/         = windows/x64/libs/
 
BIP39_DIR="$PWD/DigitalNote-2/src/bip39"
LIBS_DIR="$PWD/libs"
 
if [ ! -f "$BIP39_DIR/CMakeLists.txt" ]; then
    echo "ERROR: CMakeLists.txt not found at $BIP39_DIR"
    echo "       cd DigitalNote-2 && git submodule update --init --recursive"
    exit 1
fi
 
# Clean any previous failed build
rm -rf "$BIP39_DIR/build"
mkdir -p "$BIP39_DIR/build"
cd "$BIP39_DIR/build"
 
cmake "$BIP39_DIR"     -G "MinGW Makefiles"     -DCMAKE_INSTALL_PREFIX="$LIBS_DIR/mnemonic"     -DCMAKE_BUILD_TYPE=Release     -DOPENSSL_ROOT_DIR="$LIBS_DIR/openssl-1.1.1w"     -DOPENSSL_INCLUDE_DIR="$LIBS_DIR/openssl-1.1.1w/include"     -DOPENSSL_CRYPTO_LIBRARY="$LIBS_DIR/openssl-1.1.1w/lib/libcrypto.a"     -DOPENSSL_SSL_LIBRARY="$LIBS_DIR/openssl-1.1.1w/lib/libssl.a"
 
mingw32-make $2
cmake --install . --prefix "$LIBS_DIR/mnemonic"