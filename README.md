# connector-skill

A Claude Code skill that generates complete Ballerina connectors from OpenAPI specifications. It runs a five-stage pipeline — sanitize → client → tests → examples → docs — and produces a production-ready connector package.

---

## Prerequisites

| Requirement | Install |
|---|---|
| [Claude Code](https://claude.ai/code) | Download from claude.ai/code |
| Ballerina CLI (`bal`) | `brew install ballerina` or from [ballerina.io](https://ballerina.io/downloads/) |
| `bal openapi` tool | `bal tool pull openapi` |
| Python 3.8+ | `brew install python` or system Python |
| Git | Pre-installed on most systems |

Verify after install:

```bash
bal openapi --version
python3 --version
```

---

## Install

Clone this repo and symlink the skill into Claude Code's global skill directory:

```bash
git clone https://github.com/vishwajayawickrama/connector-skill \
  ~/.claude/skills/connector-skill-repo

ln -s ~/.claude/skills/connector-skill-repo/skills/connector-creator \
  ~/.claude/skills/connector-creator
```

Verify:

```bash
ls ~/.claude/skills/connector-creator/SKILL.md
```

Claude Code loads skills from `~/.claude/skills/` automatically — start a new session and the skill is available immediately.

### Updating

```bash
cd ~/.claude/skills/connector-skill-repo
git pull
```

No reinstall needed — the symlink always points at the latest cloned state.

---

## Usage

Start a Claude Code session in the directory where you want the connector generated (or where one already exists), then invoke the skill directly:

```
/connector-creator
```

Or describe your goal in natural language:

```
Generate a Ballerina connector from this OpenAPI spec: ./hubspot-files.yaml
```

The skill runs through these stages in order:

| Stage | What it produces |
|---|---|
| 0 — Setup | Validates environment, collects config |
| 1 — Sanitize | Flattens and aligns the spec, enhances operationIds and descriptions |
| 2 — Client | Generates `client.bal`, `types.bal`, `utils.bal` |
| 3 — Tests | Generates mock server + test suite |
| 4 — Examples | Generates runnable usage examples |
| 5 — Docs | Generates `README.md`, `Module.md`, `sanitations.md` |

Any stage can be skipped by listing it in `EXCLUDED_STAGES` during setup. The skill will pause between stages and ask for confirmation when `INTERACTIVE_MODE` is enabled.

---

## Project structure

```
skills/
  connector-creator/
    SKILL.md              # Skill manifest and entry point
    stages/               # One file per pipeline stage
    scripts/              # Python + shell scripts for deterministic operations
    templates/            # Markdown scaffolds for generated docs
    references/           # Fix procedure, workflow rules
```
