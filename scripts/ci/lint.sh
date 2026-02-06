#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

failures=0

check_no_match() {
  local description="$1"
  local pattern="$2"
  local scope="$3"
  local output_file

  output_file="$(mktemp)"

  if grep -RInE --include='*.swift' "$pattern" "$scope" >"$output_file"; then
    echo "Lint failed: $description"
    cat "$output_file"
    failures=1
  fi

  rm -f "$output_file"
}

echo "Running static lint checks..."

# Keep production sources free from debug prints.
check_no_match "debug print statements are not allowed in app sources" "print[[:space:]]*\\(" "gamman"

# Keep forced operations out of production code.
check_no_match "force try is not allowed in app sources" "\\btry!" "gamman"
check_no_match "force cast is not allowed in app sources" "\\bas!" "gamman"

# Keep whitespace clean in all Swift targets.
check_no_match "trailing whitespace is not allowed" "[[:blank:]]+$" "gamman"
check_no_match "trailing whitespace is not allowed" "[[:blank:]]+$" "gammanTests"
check_no_match "trailing whitespace is not allowed" "[[:blank:]]+$" "gammanUITests"

if [[ "$failures" -ne 0 ]]; then
  exit 1
fi

echo "Lint checks passed."
