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

Read `templates/readme_template.md` as the scaffold.

Fill in placeholders using `SPEC_METADATA`:
- `<API_TITLE>` → `SPEC_METADATA.title`
- `<API_VERSION>` → `SPEC_METADATA.version`
- `<API_DESCRIPTION>` → first 3 sentences of `SPEC_METADATA.description` (or a generated summary)
- `<API_URL>` → first entry in `SPEC_METADATA.servers` (if available)
- `<MODULE_NAME>` → snake_case of `SPEC_METADATA.title`
- `<!-- OPERATIONS_TABLE -->` → table rows for up to 10 key operations from `SPEC_METADATA.paths`
- `<!-- LICENSE_HEADER -->` → `LICENSE_HEADER` text if provided, otherwise omit the license section entirely

Write to `<OUTPUT_DIR>/README.md`.

---

## Step 3: Generate Module.md (Ballerina Central)

`Module.md` is the API overview displayed on Ballerina Central. Generate it with:

```markdown
## Overview

<3–5 sentence description of what this connector does, derived from SPEC_METADATA>

## Compatibility

| Ballerina Language Version | API Version |
|---------------------------|-------------|
| Swan Lake               | <API_VERSION> |

## Setup Guide

<concise auth/config steps — 3-5 bullet points based on spec security schemes>

## Usage

<one representative code snippet from EXAMPLE_DIR if available, otherwise generate one inline>
```

Write to `<OUTPUT_DIR>/Module.md`.

---

## Step 4: Generate sub-READMEs

### Tests README
Write `<OUTPUT_DIR>/tests/README.md`:
```markdown
# Tests

This directory contains the test suite for the <API_TITLE> connector.

## Running Tests

```bash
bal test
```

## Mock Server

Tests use a local mock server (`modules/mock.server`) that simulates the <API_TITLE> API.
No external network access is required.
```

### Examples README
Write `<EXAMPLE_DIR>/README.md`:
```markdown
# Examples

This directory contains Ballerina usage examples for the <API_TITLE> connector.

| Example | Description |
|---------|-------------|
<one row per file in EXAMPLE_DIR>

## Prerequisites

Set the following in `Config.toml`:
```toml
# <Required config values from spec security schemes>
```

## Running an Example

```bash
cd examples/<example-name>
bal run
```
```

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
