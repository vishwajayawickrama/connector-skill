#!/usr/bin/env bash
# Locate the aligned or flattened OpenAPI spec output in a spec directory.
# Mirrors sanitizor/execute.bal:52-89 detection logic.
#
# Usage: find_spec_output.sh <spec_dir>
# Output (stdout): absolute path to the best available spec file
# Exit 1 if nothing found.

SPEC_DIR="${1:?Usage: find_spec_output.sh <spec_dir>}"

# Priority order: aligned first (JSON preferred), then flattened
CANDIDATES=(
  "aligned_ballerina_openapi.json"
  "aligned_ballerina_openapi.yaml"
  "aligned_ballerina_openapi.yml"
  "flattened_openapi.json"
  "flattened_openapi.yaml"
  "flattened_openapi.yml"
)

for name in "${CANDIDATES[@]}"; do
  path="$SPEC_DIR/$name"
  if [ -f "$path" ]; then
    echo "$(cd "$(dirname "$path")" && pwd)/$(basename "$path")"
    exit 0
  fi
done

echo "ERROR: No aligned or flattened spec found in $SPEC_DIR" >&2
echo "Expected one of: ${CANDIDATES[*]}" >&2
exit 1
