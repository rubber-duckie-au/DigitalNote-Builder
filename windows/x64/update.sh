#!/usr/bin/env bash

# DigitalNote v2.0.0.7 Windows MSYS2 MinGW64 build dependencies
#
# Run this once on a fresh MSYS2 MinGW64 install (or in CI's clean
# msys2/setup-msys2@v2 environment) before building DigitalNote-2.
#
# Package groups:
#
#   Build tools:
#     base-devel              - autoconf/make/grep/sed/tar/etc.
#     git, perl, bzip2        - source fetch + various build steps
#     libtool                 - libevent / qrencode autotools chain
#     make                    - GNU make for autotools-based libs
#     autoconf                - libevent / qrencode autogen.sh
#     automake                - provides aclocal (qrencode autogen.sh)
#     automake-wrapper        - autotools convention some scripts use
#     pkg-config              - libevent / qrencode dependency probing
#
#   Compiler & linker:
#     mingw-w64-x86_64-gcc        - g++ for compiling DigitalNote-2
#     mingw-w64-x86_64-gcc-libs   - libgcc_s_seh-1.dll, libstdc++-6.dll
#                                   (needed at runtime by Qt tools)
#     mingw-w64-x86_64-make       - mingw32-make, required by qmake
#                                   win32 Makefiles for the wallet
#                                   (handles del / *.bat command rules)
#
#   Static-library deps not built from source:
#     mingw-w64-x86_64-gmp        - GMP for crypto
#     mingw-w64-x86_64-pcre2      - PCRE2 (Qt requirement)
#     mingw-w64-x86_64-md4c       - libmd4c.a, link-time dep of Qt5
#                                   QtGui (rich-text / Markdown rendering
#                                   in QTextDocument)
#
#   Runtime DLLs needed by bundled Qt 5.15.7 static archive's tools
#   (lrelease.exe, moc.exe, etc.). Without these, tools fail to
#   launch with STATUS_DLL_NOT_FOUND (0xC0000135) when called by
#   make during the wallet build.
#     mingw-w64-x86_64-double-conversion  - libdouble-conversion.dll
#     mingw-w64-x86_64-zstd               - libzstd.dll
#     mingw-w64-x86_64-libwinpthread      - libwinpthread-1.dll
#
# --needed skips already-installed packages.
# --noconfirm avoids interactive prompts (safe in CI; on a dev machine
# you can remove it if you prefer to be asked).

pacman -S --needed --noconfirm \
    base-devel \
    git \
    perl \
    bzip2 \
    libtool \
    make \
    autoconf \
    automake \
    automake-wrapper \
    pkg-config \
    mingw-w64-x86_64-gcc \
    mingw-w64-x86_64-gcc-libs \
    mingw-w64-x86_64-make \
    mingw-w64-x86_64-pcre2 \
    mingw-w64-x86_64-gmp \
    mingw-w64-x86_64-md4c \
    mingw-w64-x86_64-double-conversion \
    mingw-w64-x86_64-zstd \
    mingw-w64-x86_64-libwinpthread