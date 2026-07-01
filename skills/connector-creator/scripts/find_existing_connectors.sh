#!/usr/bin/env bash
# Find existing Ballerina connector directories under CWD.
# A connector directory is one containing a client.bal with actual API methods (apiCount > 0).
# Prints one absolute path per result (the containing directory).
set -euo pipefail

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

find "$(pwd)" -name "client.bal" | while read -r f; do
  dir="$(dirname "$f")"
  api_count=$(python3 "$SKILL_ROOT/scripts/analyze_client.py" "$f" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('apiCount',0))" 2>/dev/null || echo 0)
  if [ "$api_count" -gt 0 ]; then
    echo "$dir"
  fi
done
