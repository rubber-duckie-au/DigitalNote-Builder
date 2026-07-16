#! /usr/bin/env bash

cd temp

tar xfz ../../../download/openssl-3.5.7.tar.gz

cd openssl-3.5.7

#./Configure LIST

# NOTE (v2.0.9 prereq bump 1.1.1w -> 3.5.7):
#   * Do NOT add 'no-deprecated'.  The wallet still calls raw-EC/BN/ECDSA APIs
#     (ecwrapper.cpp [used by SMSG], stealth.cpp, smsg.cpp, cbignum*) and the
#     RIPEMD160() one-shot in hash.cpp.  Those are DEPRECATED but present in 3.x;
#     'no-deprecated' would remove them from the built library and break the link.
#     Deprecation warnings are suppressed source-side via OPENSSL_SUPPRESS_DEPRECATED
#     in DigitalNote_config.pri.
#   * 'make depend' was dropped: it is a 1.x-ism; OpenSSL 3.x's Configure generates
#     dependencies itself and the separate target is obsolete.
./Configure --prefix=$PWD/../../libs/openssl-3.5.7 no-zlib no-shared no-dso no-camellia no-capieng no-cast no-cms no-dtls1 no-gost no-idea no-md2 no-mdc2 no-rc5 no-rdrand no-rfc3779 no-sctp no-seed no-whirlpool no-rc2 no-rc4 no-ssl3 $1

make $2
make install
