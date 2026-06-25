# Stage 05 — Documentation

Generate README files and Ballerina Central publishing documentation.

Skip this stage if `docs` is in `EXCLUDED_STAGES`.

---

## Step 1: Gather context

Collect the following (already in context from prior stages):
- `SPEC_METADATA`: title, version, description, paths, schemas
- `OUTPUT_DIR` contents: file list
- `LICENSE_HEADER`: license text (if set)
- `EXAMPLE_DIR` file list (from stage 04)

Do **not** re-read the entire source files — use the structured metadata and file paths only.

---

## Step 2: Generate connector README

Read `<skill-root>/templates/readme_template.md` as the scaffold.

Fill in placeholders using `SPEC_METADATA`:
- `<API_TITLE>` → `SPEC_METADATA.title`
- `<API_VERSION>` → `SPEC_METADATA.version`
- `<API_DESCRIPTION>` → first 3 sentences of `SPEC_METADATA.description` (or a generated summary)
- `<API_URL>` → first entry in `SPEC_METADATA.servers` (if available)
- `<MODULE_NAME>` → `BAL_PACKAGE`
- `<ORG>` → `BAL_ORG`
- `<!-- OPERATIONS_TABLE -->` → table rows for up to 10 key operations from `SPEC_METADATA.paths`
- `<!-- LICENSE_HEADER -->` → `LICENSE_HEADER` text if provided, otherwise omit the license section entirely

Write to `<OUTPUT_DIR>/README.md`.

---

## Step 3: Generate Module.md (Ballerina Central)

Read `<skill-root>/templates/module_readme_template.md` as the scaffold.

Fill in placeholders using `SPEC_METADATA` and stage context:
- `<BAL_ORG>/<BAL_PACKAGE>` → from shared state
- `<API_TITLE>`, `<API_URL>`, `<API_VERSION>` → from `SPEC_METADATA`
- `AI_GENERATED_OVERVIEW` → 3–5 sentence description of what this connector does
- `AI_GENERATED_SETUP` → concise auth/config steps based on spec security schemes (3–5 bullets)
- `AI_GENERATED_QUICKSTART` → one representative code snippet from `EXAMPLE_DIR` if available, otherwise generate one inline
- `AI_GENERATED_EXAMPLES` → table of generated examples with one-liner descriptions

Write to `<OUTPUT_DIR>/Module.md`.

---

## Step 4: Generate sub-READMEs

### Tests README

Read `<skill-root>/templates/tests_readme_template.md` as the scaffold.

Fill in `AI_GENERATED_TESTING_APPROACH` with a short description of what the test suite covers (derived from the client method names in `CLIENT_ANALYSIS.methods` if available, or from `SPEC_METADATA.paths`).

Write to `<OUTPUT_DIR>/tests/README.md`.

### Examples README

Read `<skill-root>/templates/examples_readme_template.md` as the scaffold.

Fill in:
- `<BAL_ORG>/<BAL_PACKAGE>` → from shared state
- Example table rows — one row per subdirectory in `EXAMPLE_DIR`
- Auth field names from `SPEC_METADATA.securitySchemes`

Write to `<EXAMPLE_DIR>/README.md`.

### Per-example READMEs (optional — generate if time permits)

For each example subdirectory that does not already have a `README.md`, read `<skill-root>/templates/example_readme_template.md` and fill in:
- `<EXAMPLE_TITLE>` → human-readable name from the directory kebab slug
- `AI_GENERATED_DESCRIPTION` → 2–3 sentences describing the use case

---

## Step 5: Stage completion

Print:
```
✓ Documentation complete
  README.md:         <OUTPUT_DIR>/README.md
  Module.md:         <OUTPUT_DIR>/Module.md
  tests/README.md:   <OUTPUT_DIR>/tests/README.md
  examples/README.md: <EXAMPLE_DIR>/README.md
```

Then print the **Final Run Summary** from `references/workflows.md` (section: "Final Summary Format"), filled in with actual values.
