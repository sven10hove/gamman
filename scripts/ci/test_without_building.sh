#!/usr/bin/env bash
set -euo pipefail

DESTINATION="${1:-}"

if [[ -z "$DESTINATION" ]]; then
  echo "Usage: $0 \"platform=iOS Simulator,id=...\"" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/.build/derived-data}"
mkdir -p "$DERIVED_DATA_PATH"

xcodebuild \
  -project gamman.xcodeproj \
  -scheme gamman \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  test-without-building
