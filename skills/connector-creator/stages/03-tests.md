# Stage 03 — Tests

Generate the connector test suite including a mock server and a test file.

Skip this stage if `tests` is in `EXCLUDED_STAGES`.

---

## Step 1: Analyse the client

Run before generating anything — provides method signatures without reading client.bal inline:

```bash
python3 <skill-root>/scripts/analyze_client.py "<OUTPUT_DIR>/client.bal"
```

Store the JSON output as `CLIENT_ANALYSIS`. Fields used in this stage:
- `CLIENT_ANALYSIS.apiCount` — total number of operations
- `CLIENT_ANALYSIS.methods` — list of `{name, params, returnType}` objects
- `CLIENT_ANALYSIS.methodType` — `"remote"` or `"resource"`

---

## Step 1b: Operation count threshold

Parse operationIds from the aligned spec — these are the values `bal openapi --operations` requires:

```bash
python3 <skill-root>/scripts/parse_openapi_spec.py "<ALIGNED_SPEC>"
```

Store as `ALIGNED_SPEC_METADATA`. Extract the non-empty operationIds:
```
OPERATION_IDS = [p.operationId for p in ALIGNED_SPEC_METADATA.paths if p.operationId != ""]
```

> **Why re-parse the aligned spec**: Stage 01 may rename operationIds during AI-assisted enhancement. `SPEC_METADATA` from Stage 00 reflects the original spec and may be stale. The aligned spec is what `bal openapi` reads, so its operationIds are authoritative.

Compare `len(OPERATION_IDS)` against `MAX_OPERATIONS = 30`:

**If `len(OPERATION_IDS) <= 30`**: set `SELECTED_OPERATIONS = ""`. The full spec will be used for the mock stub.

**If `len(OPERATION_IDS) > 30`**: prompt the LLM with the full operationId list:

> Your response must be **ONLY a comma-separated list of operationIds with NO spaces** — no other text, no explanations.
> Select exactly 30 from the following list.
> Criteria: core CRUD, most frequently used, variety across resource types, search/discovery, lifecycle operations.
> OperationIds: `<OPERATION_IDS joined by comma>`

Example valid response: `getFile,listFiles,uploadFile,deleteFile,createFolder,...`

Store the result as `SELECTED_OPERATIONS`.

> `CLIENT_ANALYSIS` (from Step 1) is still used in Steps 2c and 3 for `methodType`, `configType`, and method signatures. Only the operation count and selection source changes to the spec.

---

## Step 2: Generate the mock server stub

### 2a: Set up the module

```bash
bash <skill-root>/scripts/setup_mock_server.sh "<OUTPUT_DIR>"
```

### 2b: Generate service stub from the spec

```bash
bash <skill-root>/scripts/generate_mock_stub.sh "<ALIGNED_SPEC>" "<OUTPUT_DIR>" "<SELECTED_OPERATIONS>" "<LICENSE_PATH>"
```

Pass `SELECTED_OPERATIONS` as the 3rd argument (empty string if not filtered) and `LICENSE_PATH` as the 4th argument (empty string if not set). The script appends `--operations` and `--license` only when the respective values are non-empty.

This runs `bal openapi -i <spec> -o modules/mock.server` (no `--mode` flag — produces a service stub, not a client). It renames `aligned_ballerina_openapi_service.bal` → `mock_server.bal` and removes the generated `client.bal`/`types.bal` from the mock module directory.

### 2c: Complete the stub — LLM fills in mock responses

Read these files into context:
1. `<OUTPUT_DIR>/modules/mock.server/mock_server.bal` — the generated stub (correct signatures, empty bodies)
2. `<OUTPUT_DIR>/modules/mock.server/utils.bal` — utility helpers generated alongside the stub
3. `<OUTPUT_DIR>/modules/mock.server/types.bal` — type definitions generated alongside the stub

Rewrite `mock_server.bal` completing every resource function body. The following rules are **all mandatory** — violations cause compilation failures:

**Output**: Raw Ballerina source code only. No conversational text, no explanations, no ` ```ballerina ` fences. Start with the first line of code and end with the last.

**Structural rules:**
- Preserve the copyright header from the stub exactly
- Keep `http:Listener ep0 = new (9090);` exactly as generated
- **DO NOT add a `public function init()` function** — the listener auto-starts when `bal test` runs; no init is needed or allowed
- Keep all resource function signatures exactly as generated — do not rename, reorder, or change parameter types
- **Fill every resource function body** — no empty bodies, no placeholder comments, no `panic`
  - If the success return type is a **data record** (e.g. `File|AnydataDefault`, `Folder|AnydataDefault`): return a fully populated mock record — never return `http:NO_CONTENT` for these
  - If the success return type is **`http:NoContent`** (DELETE or similar returning HTTP 204): return `http:NO_CONTENT` — this is the correct and only valid value
- Preserve all doc comments (`# ...`) above resource functions

**Data rules:**
- Return realistic, believable mock data (not empty strings, not zeros, not `""`)
- Use Ballerina mapping constructor expressions: `{fieldName: value}` — NOT JSON-style string keys
- **`@jsondata:Name` annotations**: when a record field has `@jsondata:Name {value: "json_name"}`, use the **Ballerina identifier** (the line below the annotation), NOT the annotation string value
  - Wrong: `{"tweet_count": 42}` — will NOT compile
  - Correct: `{tweetCount: 42}` — uses the Ballerina field name
- **`Type|record {}` union fields (BCE2523)**: any field whose declared type contains `|record {}` requires an explicit type cast on any mapping constructor assigned to it
  - Wrong: `idleSessionSignOut: {isEnabled: true}` — BCE2523, ambiguous type
  - Correct: `idleSessionSignOut: <MicrosoftGraphIdleSessionSignOut>{isEnabled: true}`
  - This rule applies at every nesting level

---

## Step 3: Generate test suite

Write `<OUTPUT_DIR>/tests/test.bal`. Provide the LLM with:
- `BAL_ORG`, `BAL_PACKAGE`
- Full content of `modules/mock.server/mock_server.bal` (the completed mock)
- The client's `init` method signature (from `CLIENT_ANALYSIS`)
- Referenced type definitions used in the init method
- Full `client.bal` content
- Full `types.bal` content
- `CLIENT_ANALYSIS.methodType` (`remote` or `resource`)

The following rules are **all mandatory**:

**Output**: Raw Ballerina source code only. No code fences. Start with the copyright header.

**Imports** (all required):
```ballerina
import ballerina/os;
import ballerina/test;
import <BAL_ORG>/<BAL_PACKAGE>.mock.server as _;
```
The `mock.server as _` import is what auto-starts the mock server — **do not** add `@test:BeforeSuite` or `@test:AfterSuite` to start or stop it.

**Environment setup**:
```ballerina
final boolean isLiveServer = os:getEnv("IS_LIVE_SERVER") == "true";
final string serviceUrl = isLiveServer ? "<real-api-base-url>" : "http://localhost:9090";
// Credentials as final vars from os:getEnv
final string token = isLiveServer ? os:getEnv("<CRED_ENV_VAR>") : "test_token";
```

**Client initialisation**: use the exact `init` method signature from `CLIENT_ANALYSIS`. Do not use a generic template — derive from the actual connector.

**Test functions**:
- One `@test:Config { groups: ["live_tests", "mock_tests"] }` function per endpoint in the mock server
- Method syntax:
  - Resource: `check client->/path/to/resource()`
  - Remote: `check client->methodName(param1, param2)`
- **Assertions**:
  - Single record response: `test:assertTrue(response?.data !is ());`
  - Array response: `test:assertTrue(response.data.length() > 0);`
  - Errors field: `test:assertTrue(response?.errors is ());`
  - No-body success (HTTP 202 etc.): declare result as `error?`, assert `test:assertTrue(response is ());`
- **`Type|record {}` union fields (BCE2523)**: same rule as mock server — any mapping constructor for a `Type|record {}` field must use an explicit type cast

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
