#! /usr/bin/env bash

# Compile Boost 1.91.0.
#
# v2.0.9 prereq bump (1.80.0 -> 1.91.0): 1.83 is chosen deliberately -- new enough
# to be a current-ish Boost, old enough to PREDATE the API removals the codebase
# would otherwise hit: the 1.85 filesystem removals (is_regular, copy_directory,
# copy_option, convenience.hpp, path_traits.hpp, path-from-container) and the 1.89
# asio deadline_timer / libboost_system-stub removals.  See v209-TODO Section 6b for
# the deferred "Boost modernization" port that a jump to 1.88+ would require.
#
# The cxxflags= suppressions below are RETAINED (not dropped at 1.83):
#   * -Wno-enum-constexpr-conversion -- Boost's MPL headers
#     (boost/mpl/aux_/integral_wrapper.hpp) underflow enum values via
#     static_cast<T>(value - 1).  This is NOT fixed by any Boost version; it is a
#     Clang hardening (Clang 16+ promoted it to a hard error; still bites Boost MPL
#     under Clang 17/18).  The flag downgrades it back to a warning -- the upstream
#     recommended mitigation.  Required for the macos runners' Clang toolchain.
#   * -Wno-deprecated-builtins / -Wno-deprecated-declarations / -Wno-unused-but-set-
#     variable and the libc++ CXX17-removed feature macros -- keep Boost's own b2
#     self-build clean across MinGW / GCC / Clang.  GCC silently ignores unknown
#     -Wno-* flags, so applying them universally is safe.
#
# Args:
#   $1 = extra b2 args (e.g. "address-model=64 toolset=clang -j 4")

cd temp

tar xfz ../../../download/boost_1_91_0.tar.gz

cd boost_1_91_0

./bootstrap.sh mingw

# Compiler flags to suppress Boost-vs-modern-Clang diagnostics.
# Each must be its own argument when passed to b2 (b2 parses cxxflags=
# tokens individually, no quoting/joining).
BOOST_CXXFLAGS="cxxflags=-Wno-enum-constexpr-conversion \
cxxflags=-Wno-deprecated-builtins \
cxxflags=-Wno-deprecated-declarations \
cxxflags=-Wno-unused-but-set-variable \
cxxflags=-D_LIBCPP_ENABLE_CXX17_REMOVED_UNARY_BINARY_FUNCTION \
cxxflags=-D_LIBCPP_ENABLE_CXX17_REMOVED_FEATURES"

./b2 install --prefix=$PWD/../../libs/boost_1_91_0 --with-chrono --with-filesystem --with-program_options --with-thread variant=release link=static threading=multi runtime-link=static stage $BOOST_CXXFLAGS $1
