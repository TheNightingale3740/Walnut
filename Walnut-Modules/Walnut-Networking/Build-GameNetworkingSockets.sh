#!/usr/bin/env bash
#
# Rebuilds bin/MacOS/libGameNetworkingSockets_s.a from the vendored source tree.
#
# GameNetworkingSockets upstream ships no macOS binary (the vendored copies under
# bin/ are Windows .lib/.dll and a Linux x86-64 .so), so Walnut builds it from
# source. The source lives in vendor/GameNetworkingSockets/source, checked out
# from https://github.com/ValveSoftware/GameNetworkingSockets at v1.4.1 - the tag
# whose STEAMNETWORKINGSOCKETS_INTERFACE_VERSION matches the headers already
# vendored in ../include/steam (SteamNetworkingSockets012).
#
# Requirements:
#   brew install protobuf openssl@3
#
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
gns="$here/vendor/GameNetworkingSockets"
src="$gns/source"
build="$gns/build"

if [[ ! -d "$src" ]]; then
	echo "error: $src not found. Clone it with:" >&2
	echo "  git clone --depth 1 --branch v1.4.1 https://github.com/ValveSoftware/GameNetworkingSockets.git $src" >&2
	exit 1
fi

openssl_prefix="$(brew --prefix openssl@3)"

# GNS pins itself to C++11, but Homebrew's protobuf pulls in abseil, whose headers
# require C++17. Without this the build fails with
#   abseil/base/policy_checks.h: "C++ versions less than C++17 are not supported."
grep -q 'CXX_STANDARD 17' "$src/CMakeLists.txt" || {
	echo "patching $src/CMakeLists.txt: CXX_STANDARD 11 -> 17"
	perl -0pi -e 's/CXX_STANDARD 11/CXX_STANDARD 17/' "$src/CMakeLists.txt"
}

# protobuf 36 returns absl::string_view from GetTypeName(), which has no c_str().
grep -q 'std::string( msg.GetTypeName() ).c_str()' "$src/src/steamnetworkingsockets/steamnetworkingsockets_internal.h" || {
	echo "patching steamnetworkingsockets_internal.h: GetTypeName().c_str()"
	perl -0pi -e 's/msg\.GetTypeName\(\)\.c_str\(\)/std::string( msg.GetTypeName() ).c_str()/g' \
		"$src/src/steamnetworkingsockets/steamnetworkingsockets_internal.h"
}

cmake -S "$src" -B "$build" \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_OSX_ARCHITECTURES="$(uname -m)" \
	-DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
	-DOPENSSL_ROOT_DIR="$openssl_prefix" \
	-DUSE_CRYPTO=OpenSSL \
	-DUSE_CRYPTO25519=OpenSSL \
	-DUSE_STEAMWEBRTC=OFF \
	-DBUILD_TOOLS=OFF \
	-DBUILD_TESTS=OFF \
	-DBUILD_EXAMPLES=OFF \
	-DBUILD_SHARED_LIB=OFF \
	-DBUILD_STATIC_LIB=ON

cmake --build "$build" -j"$(sysctl -n hw.ncpu)"

mkdir -p "$gns/bin/MacOS"
cp "$build/src/libGameNetworkingSockets_s.a" "$gns/bin/MacOS/"

echo "built $gns/bin/MacOS/libGameNetworkingSockets_s.a"