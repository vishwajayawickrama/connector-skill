#!/usr/bin/env bash
# Generate a Ballerina service stub from an OpenAPI spec into the mock.server module.
# Mirrors test_generator/mock_service_generator.bal:generateMockServer logic.
#
# Usage: generate_mock_stub.sh <spec-path> <output-dir>
# The stub is written to <output-dir>/modules/mock.server/mock_server.bal
# Run setup_mock_server.sh first to initialise the module.

set -euo pipefail

SPEC_PATH="${1:?Usage: generate_mock_stub.sh <spec-path> <output-dir> [operations]}"
OUTPUT_DIR="${2:?Usage: generate_mock_stub.sh <spec-path> <output-dir> [operations]}"
OPERATIONS="${3:-}"   # optional: comma-separated operation IDs (used when spec has >30 operations)
MOCK_DIR="${OUTPUT_DIR}/modules/mock.server"

# Generate service stub — no --mode flag produces a service stub (not a client)
echo ">>> Running bal openapi to generate service stub..."
if [ -n "$OPERATIONS" ]; then
  echo ">>> Filtering to operations: ${OPERATIONS}"
  bal openapi -i "${SPEC_PATH}" -o "${MOCK_DIR}" --operations "${OPERATIONS}"
else
  bal openapi -i "${SPEC_PATH}" -o "${MOCK_DIR}"
fi

# Rename the generated service file to mock_server.bal
SERVICE_FILE="${MOCK_DIR}/aligned_ballerina_openapi_service.bal"
MOCK_FILE="${MOCK_DIR}/mock_server.bal"

if [ ! -f "${SERVICE_FILE}" ]; then
  echo "ERROR: Expected ${SERVICE_FILE} but it was not generated." >&2
  exit 1
fi

mv "${SERVICE_FILE}" "${MOCK_FILE}"
echo ">>> Renamed aligned_ballerina_openapi_service.bal → mock_server.bal"

# Remove files generated alongside the stub that are not needed in the mock module
rm -f "${MOCK_DIR}/client.bal" "${MOCK_DIR}/types.bal"

echo "✓ Stub written: ${MOCK_FILE}"
