#!/usr/bin/env bash
#
# build.sh
# MRzefv / AVX512 generated dylib build entry point
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

TARGET_NAME="${TARGET_NAME:-MRzefvGenerated}"
BUILD_DIR="${BUILD_DIR:-build}"
DIST_DIR="${DIST_DIR:-dist}"

echo "========================================"
echo " MRzefv Generated Build"
echo "========================================"
echo "Target: ${TARGET_NAME}"
echo "Root:   ${ROOT_DIR}"
echo

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

command -v make >/dev/null 2>&1 || fail "make is not available"

if [[ -z "${THEOS:-}" ]]; then
    fail "THEOS environment variable is not configured"
fi

[[ -d "$THEOS" ]] || fail "THEOS directory does not exist: $THEOS"

[[ -f "Makefile" ]] || fail "Makefile not found"
[[ -f "manifest.json" ]] || fail "manifest.json not found"
[[ -f "Sources/${TARGET_NAME}.m" ]] || fail "Generated Objective-C source not found"
[[ -f "Sources/${TARGET_NAME}.h" ]] || fail "Generated Objective-C header not found"

echo "[1/6] Validating generated project"
echo "✓ Makefile"
echo "✓ manifest.json"
echo "✓ ${TARGET_NAME}.h"
echo "✓ ${TARGET_NAME}.m"

echo
echo "[2/6] Preparing build directories"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$DIST_DIR"

echo "✓ Clean build directory"

echo
echo "[3/6] Building with Theos"

make clean || true
make package

echo
echo "[4/6] Locating generated artifacts"

DYLIB_PATH=""

while IFS= read -r candidate; do
    if [[ -z "$DYLIB_PATH" ]]; then
        DYLIB_PATH="$candidate"
    fi
done < <(find . \
    -type f \
    -name "${TARGET_NAME}.dylib" \
    -not -path "./.git/*" \
    -not -path "./${DIST_DIR}/*" \
    2>/dev/null)

if [[ -z "$DYLIB_PATH" ]]; then
    fail "Theos build completed but ${TARGET_NAME}.dylib was not found"
fi

echo "✓ Found: ${DYLIB_PATH}"

mkdir -p "$DIST_DIR"

cp "$DYLIB_PATH" "$DIST_DIR/${TARGET_NAME}.dylib"

echo
echo "[5/6] Creating build metadata"

BUILD_INFO="${DIST_DIR}/build-info.json"

cat > "$BUILD_INFO" <<EOF
{
  "target": "${TARGET_NAME}",
  "generator": "AVX512/MRzefv",
  "sessionID": "${MRZEFV_SESSION_ID:-unknown}",
  "status": "built"
}
EOF

echo "✓ ${BUILD_INFO}"

echo
echo "[6/6] Creating artifact archive"

(
    cd "$DIST_DIR"

    rm -f "${TARGET_NAME}.zip"

    zip -q -r \
        "${TARGET_NAME}.zip" \
        "${TARGET_NAME}.dylib" \
        "build-info.json"
)

echo "✓ ${DIST_DIR}/${TARGET_NAME}.zip"

echo
echo "========================================"
echo " BUILD COMPLETE"
echo "========================================"
echo
echo "Dylib:"
echo "  ${DIST_DIR}/${TARGET_NAME}.dylib"
echo
echo "ZIP:"
echo "  ${DIST_DIR}/${TARGET_NAME}.zip"
echo
echo "Build info:"
echo "  ${DIST_DIR}/build-info.json"
echo
