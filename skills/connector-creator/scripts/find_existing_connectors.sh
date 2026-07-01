#!/usr/bin/env bash
# Find existing Ballerina connector directories under CWD.
# Prints one absolute path per result (the containing directory).
set -euo pipefail
find "$(pwd)" -name "client.bal" | while read -r f; do
  dirname "$f"
done
