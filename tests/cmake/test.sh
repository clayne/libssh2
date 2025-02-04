#!/bin/sh
#
# Copyright (C) Viktor Szakats
# SPDX-License-Identifier: BSD-3-Clause

set -eu

cd "$(dirname "$0")"

mode="${1:-all}"

if [ "${mode}" = 'all' ] || [ "${mode}" = 'FetchContent' ]; then
  rm -rf bld-fetchcontent
  cmake -B bld-fetchcontent \
    -DTEST_INTEGRATION_MODE=FetchContent \
    -DFROM_GIT_REPO="${PWD}/../.." \
    -DFROM_GIT_TAG="$(git rev-parse HEAD)"
  cmake --build bld-fetchcontent
fi

if [ "${mode}" = 'all' ] || [ "${mode}" = 'add_subdirectory' ]; then
  rm -rf libssh2; ln -s ../.. libssh2
  rm -rf bld-add_subdirectory
  cmake -B bld-add_subdirectory \
    -DTEST_INTEGRATION_MODE=add_subdirectory
  cmake --build bld-add_subdirectory
fi

if [ "${mode}" = 'all' ] || [ "${mode}" = 'find_package' ]; then
  rm -rf bld-libssh2
  cmake ../.. -B bld-libssh2
  cmake --build bld-libssh2
  cmake --install bld-libssh2 --prefix bld-libssh2/_pkg
  rm -rf bld-find_package
  cmake -B bld-find_package \
    -DTEST_INTEGRATION_MODE=find_package \
    -DCMAKE_PREFIX_PATH="${PWD}/bld-libssh2/_pkg/lib/cmake/libssh2"
  cmake --build bld-find_package
fi
