#!/usr/bin/env bash
#
# build.sh
# MRzefv / AVX512 generated dylib build script
#
# CI toolchain:
#   macOS
#   Xcode / iPhoneOS SDK
#   Apple clang
#   lipo
#   ldid (installed by GitHub Actions)
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
SOURCE_DIR="${ROOT_DIR}/Sources"
SOURCE_FILE="${SOURCE_DIR}/${TARGET_NAME}.m"
HEADER_FILE="${SOURCE_DIR}/${TARGET_NAME}.h"
SESSION_ID="${MRZEFV_SESSION_ID:-unknown}"
BUILD_ID="${MRZEFV_BUILD_ID:-unknown}"
fail() {
    echo
    echo "ERROR: $*" >&2
    exit 1
}
echo "========================================"
echo " MRzefv Generated Dylib Build"
echo "========================================"
echo "Target:       ${TARGET_NAME}"
echo "Minimum iOS: ${MIN_IOS_VERSION}"
echo "Session:      ${SESSION_ID}"
echo "Build ID:     ${BUILD_ID}"
echo
# ------------------------------------------------------------
# Toolchain
# ------------------------------------------------------------
command -v xcrun >/dev/null 2>&1 \
    || fail "xcrun is not available"
command -v lipo >/dev/null 2>&1 \
    || fail "lipo is not available"
command -v otool >/dev/null 2>&1 \
    || fail "otool is not available"
command -v file >/dev/null 2>&1 \
    || fail "file is not available"
command -v zip >/dev/null 2>&1 \
    || fail "zip is not available"
CLANG="$(xcrun --sdk iphoneos -f clang)"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
LDID="$(command -v ldid || true)"
[[ -x "$CLANG" ]] \
    || fail "Apple clang was not found"
[[ -d "$SDK" ]] \
    || fail "iPhoneOS SDK was not found: ${SDK}"
[[ -n "$LDID" ]] \
    || fail "ldid is not installed. GitHub Actions must install ldid before running build.sh."
echo "Toolchain:"
echo "  clang: ${CLANG}"
echo "  SDK:   ${SDK}"
echo "  ldid:  ${LDID}"
echo
echo "Apple toolchain:"
xcodebuild -version || true
echo
echo "Clang:"
"$CLANG" --version | head -n 1
echo
echo "ldid:"
"$LDID" --version || true
# ------------------------------------------------------------
# Project validation
# ------------------------------------------------------------
echo
echo "[1/9] Validating generated project"
[[ -f "${ROOT_DIR}/manifest.json" ]] \
    || fail "manifest.json not found"
[[ -f "$HEADER_FILE" ]] \
    || fail "${HEADER_FILE} not found"
[[ -f "$SOURCE_FILE" ]] \
    || fail "${SOURCE_FILE} not found"
echo "✓ manifest.json"
echo "✓ ${HEADER_FILE}"
echo "✓ ${SOURCE_FILE}"
if [[ -d "${ROOT_DIR}/Resources" ]]; then
    echo "✓ Resources/"
else
    echo "• Resources/ not present"
fi
# ------------------------------------------------------------
# Build directories
# ------------------------------------------------------------
echo
echo "[2/9] Preparing build directories"
rm -rf "$BUILD_DIR"
rm -rf "$PACKAGES_DIR"
mkdir -p \
    "${BUILD_DIR}/arm64" \
    "${BUILD_DIR}/arm64e" \
    "$PACKAGES_DIR"
ARM64_DIR="${BUILD_DIR}/arm64"
ARM64E_DIR="${BUILD_DIR}/arm64e"
ARM64_OBJ="${ARM64_DIR}/${TARGET_NAME}.o"
ARM64E_OBJ="${ARM64E_DIR}/${TARGET_NAME}.o"
ARM64_DYLIB="${ARM64_DIR}/${TARGET_NAME}.dylib"
ARM64E_DYLIB="${ARM64E_DIR}/${TARGET_NAME}.dylib"
FINAL_DYLIB="${PACKAGES_DIR}/${TARGET_NAME}.dylib"
FINAL_ZIP="${PACKAGES_DIR}/${TARGET_NAME}.zip"
echo "✓ build/"
echo "✓ packages/"
# ------------------------------------------------------------
# Compiler flags
# ------------------------------------------------------------
COMMON_CFLAGS=(
    -fobjc-arc
    -fblocks
    -fmodules
    -isysroot "$SDK"
    -miphoneos-version-min="$MIN_IOS_VERSION"
    -I"$SOURCE_DIR"
    -Wall
    -Wextra
    -Wno-deprecated-declarations
    -Wno-nullability-completeness
)
COMMON_LDFLAGS=(
    -dynamiclib
    -isysroot "$SDK"
    -miphoneos-version-min="$MIN_IOS_VERSION"
    -install_name "@rpath/${TARGET_NAME}.dylib"
    -Wl,-headerpad_max_install_names
    -Wl,-search_paths_first
    -framework Foundation
    -framework UIKit
)
# ------------------------------------------------------------
# arm64
# ------------------------------------------------------------
echo
echo "[3/9] Compiling arm64"
"$CLANG" \
    "${COMMON_CFLAGS[@]}" \
    -arch arm64 \
    -c "$SOURCE_FILE" \
    -o "$ARM64_OBJ"
echo "✓ ${ARM64_OBJ}"
echo
echo "[4/9] Linking arm64"
"$CLANG" \
    "${COMMON_LDFLAGS[@]}" \
    -arch arm64 \
    "$ARM64_OBJ" \
    -o "$ARM64_DYLIB"
echo "✓ ${ARM64_DYLIB}"
# ------------------------------------------------------------
# arm64e
# ------------------------------------------------------------
echo
echo "[5/9] Compiling arm64e"
"$CLANG" \
    "${COMMON_CFLAGS[@]}" \
    -arch arm64e \
    -c "$SOURCE_FILE" \
    -o "$ARM64E_OBJ"
echo "✓ ${ARM64E_OBJ}"
echo
echo "[6/9] Linking arm64e"
"$CLANG" \
    "${COMMON_LDFLAGS[@]}" \
    -arch arm64e \
    "$ARM64E_OBJ" \
    -o "$ARM64E_DYLIB"
echo "✓ ${ARM64E_DYLIB}"
# ------------------------------------------------------------
# Universal dylib
# ------------------------------------------------------------
echo
echo "[7/9] Creating universal dylib"
lipo \
    -create \
    "$ARM64_DYLIB" \
    "$ARM64E_DYLIB" \
    -output "$FINAL_DYLIB"
echo "✓ ${FINAL_DYLIB}"
# ------------------------------------------------------------
# Verification before signing
# ------------------------------------------------------------
echo
echo "========================================"
echo " PRE-SIGN VERIFICATION"
echo "========================================"
echo
echo "File:"
file "$FINAL_DYLIB"
echo
echo "Architectures:"
lipo -info "$FINAL_DYLIB"
echo
echo "Install name:"
otool -D "$FINAL_DYLIB"
echo
echo "Linked libraries:"
otool -L "$FINAL_DYLIB" || true
# ------------------------------------------------------------
# ldid
# ------------------------------------------------------------
echo
echo "[8/9] Signing with ldid"
echo "Using:"
echo "  ${LDID}"
"$LDID" -S "$FINAL_DYLIB"
echo "✓ Ad-hoc signature applied"
echo
echo "Signature:"
"$LDID" -e "$FINAL_DYLIB" || true
# ------------------------------------------------------------
# Metadata
# ------------------------------------------------------------
echo
echo "[9/9] Creating package"
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
  "sdk": "iphoneos",
  "compiler": "Apple Clang",
  "installName": "@rpath/${TARGET_NAME}.dylib",
  "signing": "ldid",
  "status": "built"
}
EOF
echo "✓ ${BUILD_INFO}"
rm -f "$FINAL_ZIP"
(
    cd "$PACKAGES_DIR"
    zip -q \
        "$TARGET_NAME.zip" \
        "$TARGET_NAME.dylib" \
        "build-info.json"
)
echo "✓ ${FINAL_ZIP}"
# ------------------------------------------------------------
# Final verification
# ------------------------------------------------------------
echo
echo "========================================"
echo " FINAL BUILD"
echo "========================================"
echo
echo "Dylib:"
ls -lh "$FINAL_DYLIB"
echo
echo "ZIP:"
ls -lh "$FINAL_ZIP"
echo
echo "Architectures:"
lipo -info "$FINAL_DYLIB"
echo
echo "Final file:"
file "$FINAL_DYLIB"
echo
echo "========================================"
echo " BUILD COMPLETE"
echo "========================================"
echo
echo "Output:"
echo "  ${FINAL_DYLIB}"
echo "  ${FINAL_ZIP}"
echo "  ${BUILD_INFO}"
echo
 
