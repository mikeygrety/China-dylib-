#!/usr/bin/env bash
#
# build.sh
# MRzefv / AVX512 generated dylib build script
#
# Builds the isolated generated Objective-C dylib using
# Apple's iPhoneOS SDK and clang.
#
# Output:
#   packages/MRzefvGenerated.dylib
#   packages/MRzefvGenerated.zip
#   packages/build-info.json
#
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"
TARGET_NAME="${OUT_NAME:-MRzefvGenerated}"
MIN_IOS_VERSION="${MIN_IOS_VERSION:-15.0}"
BUILD_DIR="${BUILD_DIR:-build}"
PACKAGES_DIR="${PACKAGES_DIR:-packages}"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
CLANG="$(xcrun --sdk iphoneos -f clang)"
LDID="$(command -v ldid || true)"
ARM64_DIR="${BUILD_DIR}/arm64"
ARM64E_DIR="${BUILD_DIR}/arm64e"
ARM64_OBJ="${ARM64_DIR}/${TARGET_NAME}.o"
ARM64E_OBJ="${ARM64E_DIR}/${TARGET_NAME}.o"
ARM64_DYLIB="${ARM64_DIR}/${TARGET_NAME}.dylib"
ARM64E_DYLIB="${ARM64E_DIR}/${TARGET_NAME}.dylib"
FINAL_DYLIB="${PACKAGES_DIR}/${TARGET_NAME}.dylib"
FINAL_ZIP="${PACKAGES_DIR}/${TARGET_NAME}.zip"
SESSION_ID="${MRZEFV_SESSION_ID:-unknown}"
BUILD_ID="${MRZEFV_BUILD_ID:-unknown}"
echo "========================================"
echo " MRzefv Generated Dylib Build"
echo "========================================"
echo "Target:       ${TARGET_NAME}"
echo "iOS minimum: ${MIN_IOS_VERSION}"
echo "SDK:          ${SDK}"
echo "Clang:        ${CLANG}"
echo "Session:      ${SESSION_ID}"
echo "Build ID:     ${BUILD_ID}"
echo
fail() {
    echo
    echo "ERROR: $*" >&2
    exit 1
}
command -v xcrun >/dev/null 2>&1 \
    || fail "xcrun is not available"
[[ -x "$CLANG" ]] \
    || fail "Apple clang was not found"
[[ -d "$SDK" ]] \
    || fail "iPhoneOS SDK was not found: $SDK"
[[ -f "manifest.json" ]] \
    || fail "manifest.json not found"
[[ -f "Sources/${TARGET_NAME}.h" ]] \
    || fail "Sources/${TARGET_NAME}.h not found"
[[ -f "Sources/${TARGET_NAME}.m" ]] \
    || fail "Sources/${TARGET_NAME}.m not found"
if [[ -z "$LDID" ]]; then
    fail "ldid is not installed"
fi
echo "[1/8] Validating project"
echo "✓ manifest.json"
echo "✓ Sources/${TARGET_NAME}.h"
echo "✓ Sources/${TARGET_NAME}.m"
echo
echo "[2/8] Preparing build directories"
rm -rf "$BUILD_DIR"
rm -rf "$PACKAGES_DIR"
mkdir -p \
    "$ARM64_DIR" \
    "$ARM64E_DIR" \
    "$PACKAGES_DIR"
echo "✓ Clean build directories"
COMMON_CFLAGS=(
    -fobjc-arc
    -fblocks
    -fmodules
    -isysroot "$SDK"
    -miphoneos-version-min="$MIN_IOS_VERSION"
    -I"$ROOT_DIR/Sources"
    -Wall
    -Wextra
    -Wno-deprecated-declarations
    -Wno-nullability-completeness
)
COMMON_LDFLAGS=(
    -dynamiclib
    -fobjc-arc
    -fblocks
    -isysroot "$SDK"
    -miphoneos-version-min="$MIN_IOS_VERSION"
    -install_name "@rpath/${TARGET_NAME}.dylib"
    -Wl,-headerpad_max_install_names
    -framework Foundation
    -framework UIKit
)
echo
echo "[3/8] Compiling arm64"
"$CLANG" \
    "${COMMON_CFLAGS[@]}" \
    -arch arm64 \
    -c \
    "Sources/${TARGET_NAME}.m" \
    -o "$ARM64_OBJ"
echo "✓ $ARM64_OBJ"
echo
echo "[4/8] Linking arm64 dylib"
"$CLANG" \
    "${COMMON_LDFLAGS[@]}" \
    -arch arm64 \
    "$ARM64_OBJ" \
    -o "$ARM64_DYLIB"
echo "✓ $ARM64_DYLIB"
echo
echo "[5/8] Compiling arm64e"
"$CLANG" \
    "${COMMON_CFLAGS[@]}" \
    -arch arm64e \
    -c \
    "Sources/${TARGET_NAME}.m" \
    -o "$ARM64E_OBJ"
echo "✓ $ARM64E_OBJ"
echo
echo "[6/8] Linking arm64e dylib"
"$CLANG" \
    "${COMMON_LDFLAGS[@]}" \
    -arch arm64e \
    "$ARM64E_OBJ" \
    -o "$ARM64E_DYLIB"
echo "✓ $ARM64E_DYLIB"
echo
echo "[7/8] Creating universal dylib"
lipo \
    -create \
    "$ARM64_DYLIB" \
    "$ARM64E_DYLIB" \
    -output "$FINAL_DYLIB"
echo "✓ $FINAL_DYLIB"
echo
echo "Signing dylib with ldid"
"$LDID" -S "$FINAL_DYLIB"
echo "✓ Ad-hoc signed"
echo
echo "Dylib information:"
file "$FINAL_DYLIB"
echo
lipo -info "$FINAL_DYLIB"
echo
echo "Install name:"
otool -D "$FINAL_DYLIB"
echo
echo "Linked libraries:"
otool -L "$FINAL_DYLIB" || true
echo
echo "[8/8] Creating build metadata"
BUILD_INFO="${PACKAGES_DIR}/build-info.json"
cat > "$BUILD_INFO" <<EOF
{
  "target": "${TARGET_NAME}",
  "generator": "AVX512/MRzefv",
  "sessionID": "${SESSION_ID}",
  "buildID": "${BUILD_ID}",
  "architecture": [
    "arm64",
    "arm64e"
  ],
  "minimumIOSVersion": "${MIN_IOS_VERSION}",
  "installName": "@rpath/${TARGET_NAME}.dylib",
  "signing": "ldid",
  "status": "built"
}
EOF
echo "✓ $BUILD_INFO"
echo
echo "Creating ZIP"
rm -f "$FINAL_ZIP"
(
    cd "$PACKAGES_DIR"
    zip -q \
        "$TARGET_NAME.zip" \
        "$TARGET_NAME.dylib" \
        "build-info.json"
)
echo "✓ $FINAL_ZIP"
echo
echo "========================================"
echo " BUILD COMPLETE"
echo "========================================"
echo
echo "Dylib:"
echo "  ${FINAL_DYLIB}"
echo
echo "ZIP:"
echo "  ${FINAL_ZIP}"
echo
echo "Metadata:"
echo "  ${BUILD_INFO}"
echo

This version no longer requires Theos. The GitHub runner supplies the Apple compiler/SDK through:

xcrun --sdk iphoneos -f clang
xcrun --sdk iphoneos --show-sdk-path

It also fixes the previous dist/ vs packages/ mismatch, so it lines up with the workflow you already have.

One important distinction: ldid -S here is ad-hoc signing, not an App Store/distribution certificate signature.
