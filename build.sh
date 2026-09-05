#!/usr/bin/env bash
# HMI Screens -- configure and build on Linux or macOS.
#
# Qt is found through CMAKE_PREFIX_PATH. Point QT_PREFIX at your kit,
# or leave it unset if Qt is already on the default search path.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${QT_PREFIX:=}"

args=(-S "$here" -B "$here/build" -G Ninja -DCMAKE_BUILD_TYPE=Release)
[ -n "$QT_PREFIX" ] && args+=(-DCMAKE_PREFIX_PATH="$QT_PREFIX")

cmake "${args[@]}"
cmake --build "$here/build" --parallel

echo
echo "Built: $here/build/hmi_screens"
