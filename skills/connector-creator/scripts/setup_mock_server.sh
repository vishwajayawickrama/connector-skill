#!/usr/bin/env bash
# Set up the mock.server module in a Ballerina connector workspace.
# Mirrors test_generator/mock_service_generator.bal:setupMockServerModule logic.
#
# Usage: setup_mock_server.sh <output_dir>
# Steps:
#   1. bal add mock.server
#   2. Remove auto-generated scaffold files (stub generation is done by generate_mock_stub.sh)

set -euo pipefail

OUTPUT_DIR="${1:?Usage: setup_mock_server.sh <output_dir>}"
MODULE_DIR="$OUTPUT_DIR/modules/mock.server"

cd "$OUTPUT_DIR"

echo ">>> Adding mock.server module..."
bal add mock.server

# Remove auto-generated scaffold files from bal add
if [ -d "$MODULE_DIR/tests" ]; then
  echo ">>> Removing auto-generated tests/ directory..."
  rm -rf "$MODULE_DIR/tests"
fi

if [ -f "$MODULE_DIR/mock.server.bal" ]; then
  echo ">>> Removing placeholder mock.server.bal..."
  rm -f "$MODULE_DIR/mock.server.bal"
fi

echo "✓ mock.server module initialised at $MODULE_DIR"
