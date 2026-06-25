# Stage 03 — Tests

Generate the connector test suite including a mock server and a test file.

Skip this stage if `tests` is in `EXCLUDED_STAGES`.

---

## Step 1: Analyse the client

Run before generating anything — provides method signatures without reading client.bal inline:

```bash
python3 <skill-root>/scripts/analyze_client.py "<OUTPUT_DIR>/client.bal"
```

Store the JSON output as `CLIENT_ANALYSIS`. Use `CLIENT_ANALYSIS.methods` for test generation.

---

## Step 2: Generate the mock server stub

### 2a: Set up the module

```bash
bash <skill-root>/scripts/setup_mock_server.sh "<OUTPUT_DIR>"
```

### 2b: Generate service stub from the spec

```bash
bash <skill-root>/scripts/generate_mock_stub.sh "<ALIGNED_SPEC>" "<OUTPUT_DIR>"
```

This runs `bal openapi -i <spec> -o modules/mock.server` (no `--mode` flag — matching connector-tool, which produces a service stub rather than a client). It renames `aligned_ballerina_openapi_service.bal` → `mock_server.bal` and removes the generated `client.bal`/`types.bal` from the mock module directory.

### 2c: Complete the stub — LLM fills in mock responses

Read both files:
1. `<OUTPUT_DIR>/modules/mock.server/mock_server.bal` — the generated stub (correct signatures, empty bodies)
2. `<OUTPUT_DIR>/types.bal` — the connector's Ballerina record type definitions

Rewrite `mock_server.bal` completing each resource function body:
- Keep `configurable int port = 9090` and the listener declaration exactly as generated
- Keep all resource function signatures exactly as generated — do not change them
- Return realistic mock data using mapping constructors `{}` with field names matching the Ballerina records in `types.bal`
- Do not add an `init()` function — the module listener auto-starts when `bal test` runs

**There must be NO `tests/mock_service.bal`.** The module service in `modules/mock.server/mock_server.bal` is the only mock.

---

## Step 3: Generate test suite

Write `<OUTPUT_DIR>/tests/test.bal` using `CLIENT_ANALYSIS.methods` (limit to 10 most representative):
- `@test:BeforeSuite` starts the mock server
- `@test:AfterSuite` stops the mock server
- One `@test:Config` function per method from `CLIENT_ANALYSIS.methods`
- Each test: call the client method, assert the return is not an error

Use exact method names and parameter types from `CLIENT_ANALYSIS.methods` — do not read client.bal directly.

---

## Step 4: Compile and fix

```bash
bash <skill-root>/scripts/run_bal_command.sh "bal build" "<OUTPUT_DIR>"
```

- Exit 0 → clean, continue
- Non-zero → invoke the **Fix Procedure** (`references/fix-procedure.md`) with `BUILD_DIR = <OUTPUT_DIR>`

---

## Step 5: Run tests

```bash
bash <skill-root>/scripts/run_bal_command.sh "bal test" "<OUTPUT_DIR>"
```

Test failures are **non-fatal** — record the result and continue. Print the test summary.

---

## Step 6: Stage completion

Print:
```
✓ Tests complete
  mock server: <OUTPUT_DIR>/modules/mock.server/mock_server.bal
  test suite:  <OUTPUT_DIR>/tests/test.bal
  build:       passed (fixed in <N> iteration(s) / clean)
  test run:    <N passing, M failing / skipped>
```

If `INTERACTIVE_MODE` is true, pause and ask: "Proceed to Examples? [Y/n/q]"
