#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

destinations="$(xcodebuild -project gamman.xcodeproj -scheme gamman -showdestinations 2>/dev/null || true)"

destination_id="$(
  printf '%s\n' "$destinations" \
    | grep 'platform:iOS Simulator' \
    | grep -v 'placeholder' \
    | sed -n 's/.*id:\([^,}]*\).*/\1/p' \
    | head -n 1 \
    | tr -d ' ' \
    || true
)"

if [[ -z "$destination_id" ]]; then
  echo "No iOS Simulator destination found for scheme 'gamman'." >&2
  echo "$destinations" >&2
  exit 1
fi

printf 'platform=iOS Simulator,id=%s\n' "$destination_id"
