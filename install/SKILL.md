---
name: agents-control
description: Set up the agents-control system in the current repo — fetches the toolkit from GitHub (patrickfleith/agents-control), installs the doc-maintenance skills, scaffolds docs/ from templates, and generates the AGENTS.md manifest + CLAUDE.md adapter. Use when the user says "set up agents-control", "bootstrap this repo", "scaffold the agent docs", or "init agents-control here".
disable-model-invocation: true
---

# agents-control (setup)

Bring the **current repo** under the agents-control system: the "3 files + a
folder" layout (`AGENTS.md` + `CLAUDE.md` + `docs/` + `.claude/skills/`), with a
correctly filled manifest. The user stays in control — show what you'll do, do
it, then report. Never overwrite existing files silently.

## 0. Guardrails

- Target = the current working directory. Confirm it's a git repo.
- **Refuse** if this *is* the agents-control toolkit repo itself (check
  `git remote -v` for `patrickfleith/agents-control`) — it's the source, not a target.
- If `AGENTS.md` or `CLAUDE.md` already exists, don't clobber — report and ask.

## 1. Fetch the toolkit from GitHub

Public repo, no auth needed. Download a shallow snapshot to a temp dir:

```bash
SRC="$(mktemp -d)/agents-control"
mkdir -p "$SRC"
curl -fsSL https://github.com/patrickfleith/agents-control/archive/refs/heads/main.tar.gz \
  | tar xz -C "$SRC" --strip-components=1
ls "$SRC"   # expect: .claude/ templates/ agents-control.md ...
```

If `curl` fails, fall back to `git clone --depth 1 https://github.com/patrickfleith/agents-control "$SRC"`.

## 2. Detect greenfield vs brownfield

- **Brownfield** — code already present. Read enough of it to fill `STACK.md`
  (detected language/frameworks/test runner) and to write an accurate one-liner
  in `AGENTS.md`. Preserve any existing `README.md`/`docs/`.
- **Greenfield** — empty/near-empty repo. Ask the user 2–3 quick questions
  (what is this, who's it for) to seed `README.md` and `AGENTS.md`.

## 3. Install capabilities and docs

Use no-clobber (`cp -n`) everywhere so existing files survive.

```bash
mkdir -p .claude/skills docs
cp -Rn "$SRC/.claude/skills/." .claude/skills/            # commit, log, decide, glossary, write-manual
for d in PRD STACK ROADMAP DECISIONS TASKS CHANGELOG; do  # MVP core only
  cp -n "$SRC/templates/docs/$d.md" "docs/$d.md"
done
[ -f README.md ] || cp -n "$SRC/templates/README.md" README.md
cp -n "$SRC/templates/AGENTS.md" AGENTS.md
[ -f CLAUDE.md ] || printf '@AGENTS.md\n' > CLAUDE.md
```

Leave the other doc types (FRD, PLAN, GLOSSARY, SUM, IDEAS, CONCERNS, QUESTIONS,
EVALUATIONS, TESTS, UXUI) uncreated — they're added on demand by `log`/`decide`/
`glossary`/`write-manual`, and the manifest note explains how to add rows.

## 4. Customize the generated files

- **AGENTS.md** — replace `<one line — what this project is…>` with a real
  description. Add rows for any docs that already existed in the repo, and
  remove rows for docs this project won't use.
- **STACK.md** (brownfield) — replace the sample bullets with what you detected.

## 5. Report

Show the file tree you created/updated and print the manifest table so the user
can eyeform-check it. Note which docs were skipped (already existed) and remind
them the remaining doc types are created on demand.
