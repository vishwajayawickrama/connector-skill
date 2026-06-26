# Stage 02 — Client Generation

Generate a Ballerina client project from the aligned OpenAPI spec using the `bal openapi` tool, then compile and auto-fix any errors.

Skip this stage if `client` is in `EXCLUDED_STAGES`.
If skipped, verify that `<OUTPUT_DIR>/client.bal` already exists — halt if not.

---

## Step 1: Build the `bal openapi` command

Resolve the spec input file:
- Use `ALIGNED_SPEC` if set (populated by Stage 01 Step 3b — this is the `.json` path after YAML conversion).
- If `ALIGNED_SPEC` is not set (Stage 01 was skipped), run:
  ```bash
  bash <skill-root>/scripts/find_spec_output.sh "<SPEC_DIR>"
  ```
  and set `ALIGNED_SPEC` from the result before continuing.

Base command:
```
bal openapi -i <ALIGNED_SPEC> --mode client -o <OUTPUT_DIR>
```

> **Note**: `bal openapi --mode client` outputs `client.bal`, `types.bal`, and `utils.bal` into `<OUTPUT_DIR>`. It does **not** create or modify `Ballerina.toml` — that is handled in Stage 00.

Append options based on collected configuration:
- If `TAGS` is non-empty: add `--tags <tag>` for each tag
- If `OPERATIONS` is non-empty: add `--operations <id>` for each operation ID
- If `USE_REMOTE` is true: add `--client-methods remote`
- If `LICENSE_HEADER` is set: write the header text to a temp file and add `--license <temp-file>`

---

## Step 2: Run client generation

```bash
bash <skill-root>/scripts/run_bal_command.sh \
  "bal openapi -i <SPEC_DIR>/aligned_ballerina_openapi.yaml --mode client -o <OUTPUT_DIR> [OPTIONS]" \
  "<OUTPUT_DIR>"
```

### On success:
Verify that `<OUTPUT_DIR>/client.bal` and `<OUTPUT_DIR>/types.bal` were created. Print the file list.

### On failure:
`bal openapi` failures indicate spec or flag issues — do not attempt LLM fixes here. Print the error and ask:
> 1. Retry with different flags
> 2. Abort

---

## Step 3: Compile and fix

Run `bal build` in `<OUTPUT_DIR>`:

```bash
bash <skill-root>/scripts/run_bal_command.sh "bal build" "<OUTPUT_DIR>"
```

- Exit 0 → build clean, continue to completion
- Non-zero → invoke the **Fix Procedure** (`references/fix-procedure.md`) with `BUILD_DIR = <OUTPUT_DIR>`

---

## Step 4: Stage completion

Print:
```
✓ Client Generation complete
  client.bal:  <OUTPUT_DIR>/client.bal
  types.bal:   <OUTPUT_DIR>/types.bal
  build:       passed (fixed in <N> iteration(s) / clean)
```

If `INTERACTIVE_MODE` is true, pause and ask: "Proceed to Tests? [Y/n/q]"
