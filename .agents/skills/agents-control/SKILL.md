---
name: agents-control
description: Set up the agents-control system in the current repo — run the installer to scaffold docs-agents/, the project skills and the AGENTS.md manifest, then fill them in from the actual codebase. Use when the user says "set up agents-control", "bootstrap this repo", "scaffold the agent docs", or "init agents-control here".
---

# agents-control (setup)

Bring the **current repo** under agents-control: `AGENTS.md` with a filled-in
manifest, `docs-agents/`, and the project skills in `.agents/skills/`, plus the
`.claude/skills/` adapter Claude Code needs.

`agents-control init` does the file placement. Your job is everything it can't
decide for itself: what this project *is*, what it's built with, and which docs
it will actually use. Don't re-do by hand what the command already did.

## 1. Scaffold

Run the installer from the repo root:

```bash
agents-control init
```

If it isn't on PATH, try `~/.agents-control/bin/agents-control init`. If that's
missing too, the user hasn't installed the toolkit — offer the one-liner and stop:

```bash
curl -fsSL https://raw.githubusercontent.com/patrickfleith/agents-control/main/install.sh | sh
```

It refuses to run outside a git repo, and refuses to run inside the
agents-control toolkit itself. Both are correct — report and stop, don't work
around them.

Read its output before continuing. It reports every file it skipped because one
already existed; those are the files you must **not** overwrite below.

## 2. Read the repo

**Brownfield** — code already present. Read enough to describe it accurately:
entry points, `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml`, the
test runner, the framework. Preserve any existing `README.md` and the repo's own
`docs/` — agents-control writes to `docs-agents/`, never to `docs/`.

**Greenfield** — empty or near-empty. Ask 2–3 short questions: what is this, who
is it for, what's the stack going to be. Don't invent answers.

## 3. Fill in what the scaffold left blank

- **`AGENTS.md`** — replace `<one line — what this project is and who it's for>`
  with a real sentence. Add manifest rows for docs the repo already had, and
  delete rows for docs this project won't use. A row that points at a file that
  will never exist is worse than no row.
- **`docs-agents/STACK.md`** — replace the sample bullets with what you actually
  detected. Only what's really in use; no aspirational entries.
- **`docs-agents/PRD.md`** — seed it from what you learned in step 2, or leave
  the template and say so. Don't fabricate requirements.

Leave the other doc types (FRD, PLAN, GLOSSARY, SUM, IDEAS, CONCERNS, QUESTIONS,
EVALUATIONS, TESTS, UXUI, DEPLOYMENT) uncreated. They're added on demand by
`log` / `decide` / `glossary` / `write-manual`.

## 4. Verify and report

```bash
agents-control doctor
```

Show the user its table — what Claude Code, Codex and Cursor will each discover —
and resolve any warnings before you finish. Then tell them:

- which files you created and which you left alone,
- to commit `.agents/`, `.claude/`, `AGENTS.md`, `CLAUDE.md` and `docs-agents/`,
  because cloud sessions read the skills from the checked-out repository,
- that skills are invoked as `/name` in Claude Code, `$name` in Codex, and by
  asking in plain language in Cursor.
