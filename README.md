# agents-control

Take back the control of your coding agents.

**What it is:** a lightweight, tool-agnostic system that keeps your project's
context in a small set of human-readable markdown docs and gives your coding
agent a **manifest** so it always knows which file holds what — plus skills that
route work into the right file.

Works the same in **Claude Code**, **Codex** (local and cloud) and **Cursor**.

## Quickstart

### 1. Install once

```bash
curl -fsSL https://raw.githubusercontent.com/patrickfleith/agents-control/main/install.sh | sh
```

This fetches the toolkit to `~/.agents-control`, puts `agents-control` on your
`PATH`, and installs the setup skill where each tool looks for it
(`~/.agents/skills/` for Codex and Cursor, `~/.claude/skills/` for Claude Code).
Re-run it any time to update.

### 2. Set up a repo

In the repository you want to bring under agents-control, ask your agent:

| Tool        | How to invoke                |
|-------------|------------------------------|
| Claude Code | `/agents-control`            |
| Codex       | `$agents-control`            |
| Cursor      | "set up agents-control here" |

The agent runs `agents-control init` to scaffold the files, then does the part a
script can't: reads your codebase, writes a real project description into
`AGENTS.md`, fills `STACK.md` with what you actually use, and prunes the manifest
to the docs this project will really have.

Prefer to do it yourself? `agents-control init` is the whole scaffolding step.

Then commit `.agents/`, `.claude/`, `AGENTS.md`, `CLAUDE.md` and `docs-agents/` —
cloud sessions read the skills from your checked-out repository.

### 3. Use it day to day

Your agent reads `AGENTS.md` every session and knows where each doc lives. Drive
the docs with the bundled skills:

| Skill          | What it does                                             |
|----------------|----------------------------------------------------------|
| `commit`       | Turn uncommitted work into atomic, conventional commits. |
| `log`          | Append to STACK / TASKS / IDEAS / CONCERNS / QUESTIONS.  |
| `decide`       | Record and manage decisions in DECISIONS.                |
| `glossary`     | Add and refine canonical terms in GLOSSARY.              |
| `write-manual` | Write or update the user manual (SUM) from the codebase. |

Invoke them as `/name` in Claude Code, `$name` in Codex, or by asking in plain
language in Cursor.

## How it works

### The problem it solves

The problem is not the number of docs — it's that each doc lacks a defined
**name/location** and a clear **purpose** the agent can recognise on sight. The
fix is one **manifest** that pins each doc's name, path and what it's for, plus
skills that route work into the right file consistently. Instructions live in
**one** file, `AGENTS.md`, with a generated one-line Claude Code adapter — so the
setup works without maintaining two brains.

### Two kinds of awareness

| Kind | Examples | How the agent learns about it |
|---|---|---|
| **Capabilities** | skills, slash commands, subagents, hooks, MCP servers | **Auto-discovered by the tool.** Commit portable skills in `.agents/skills/`; Codex and Cursor discover that path natively, locally and after a cloud task checks out the repo. Claude Code reads only `.claude/skills/`, so agents-control generates one entry there per skill. |
| **Docs (your markdown)** | PRD, STACK, TASKS, DECISIONS… | **NOT understood automatically.** The tool sees the file exists but not what it's for. **This is the only thing the manifest is for.** |

### The awareness chain

Every session, each tool auto-loads its instruction file into context — no
command, no action:

```
Claude Code                       Codex (local + cloud) · Cursor
-----------                       -----------------------------
CLAUDE.md  ──(@import)──▶ AGENTS.md ◀── read directly
                             │
                             ▼
                   [DOC MANIFEST section]
              "here are the docs + what each is for"
```

- **Claude Code** always reads `CLAUDE.md` at startup → it is one line,
  `@AGENTS.md`, which pulls the whole file in. It never reads `AGENTS.md` itself.
- **Codex and Cursor** read `AGENTS.md` directly at startup; Codex cloud tasks
  receive it when they check out the repository.
- All three therefore see the manifest **every session, automatically**. That
  *is* the mechanism — the file that's always loaded contains the manifest.

| Tool        | Instructions               | Skills                                |
|-------------|----------------------------|---------------------------------------|
| Codex       | `AGENTS.md`                | `.agents/skills/`                     |
| Cursor      | `AGENTS.md`                | `.agents/skills/`                     |
| Claude Code | `CLAUDE.md` → `@AGENTS.md` | `.claude/skills/` → `.agents/skills/` |

### The layout

```
AGENTS.md        ← instructions + the manifest table (the brain)
docs-agents/     ← the actual doc content, names fixed by the manifest
.agents/skills/  ← canonical, committed skills — the single source of truth
CLAUDE.md        ← generated Claude Code adapter: one line, "@AGENTS.md"
.claude/skills/  ← generated Claude Code adapter: one entry per skill
```

The two `.claude/` entries are **generated, not authored** — never edit them by
hand. Write skills in `.agents/skills/` and run `agents-control adapters`.

Two directories is the minimum, not a redundancy: Codex reads `.agents/skills/`
and never `.claude/skills/`, Claude Code reads `.claude/skills/` and never
`.agents/skills/`, and only Cursor reads both. But there is still just one copy
of every skill — the `.claude/` entries are symlinks into `.agents/skills/`.

### The manifest

The manifest is a compact table inside `AGENTS.md`: each doc's name, path and
what it captures — no permission or ownership columns. It tells the agent
**which file holds what**, so it reads and routes work to the right place. Edit
etiquette is handled by the skills and by the human staying in the loop, not by
per-doc rules.

```markdown
## Project docs

Project docs live in `docs-agents/` (feature docs under `docs-agents/features/<slug>/`).
Not all exist in every repo — the core set is created at setup, the rest are
added on demand. If a doc doesn't exist yet, don't fabricate one — ask, or
create it with the relevant skill.

| Doc          | Path                     | What it captures                             | Skill    |
|--------------|--------------------------|----------------------------------------------|----------|
| Product spec | docs-agents/PRD.md       | Product-level requirements & context.        | —        |
| Tech stack   | docs-agents/STACK.md     | Frameworks, libraries, tools.                | `log`    |
| Roadmap      | docs-agents/ROADMAP.md   | Upcoming features, rework, fixes.            | —        |
| Decisions    | docs-agents/DECISIONS.md | Pending (TBD) and settled decisions.         | `decide` |
| Tasks        | docs-agents/TASKS.md     | Repo-level todo dump.                        | `log`    |
| Changelog    | docs-agents/CHANGELOG.md | Notable changes per released version.        | —        |
| …            | …                        | (one row per doc — full set in the template) | …        |
```

### Why there is no separate `INDEX.md`

Claude Code can follow `@docs-agents/INDEX.md` imports, but **Codex does not
follow `@path` imports** — it only concatenates `AGENTS.md` files. A separate
manifest file would therefore be invisible to Codex. So the manifest lives as a
**section inside `AGENTS.md`**: compact, always loaded, cross-tool safe. A
human-facing table of contents, if ever wanted, is just a section in this
README — not part of the agent's awareness path.

### Two rules that keep it honest

1. **The mechanical work belongs to a script, not a model.** `agents-control
   init` places every file identically no matter which agent is driving; the
   setup skill is left with only the judgment — what the project is, what it's
   built with, which docs it will use.
2. **Skills stay inside the [Agent Skills](https://agentskills.io) spec
   frontmatter** (`name`, `description`, `license`, `compatibility`, `metadata`,
   `allowed-tools`). Anything beyond it works in Claude Code and is silently
   ignored elsewhere — exactly the asymmetry this design exists to prevent.

## Commands

| Command                   | What it does                                                          |
|---------------------------|-----------------------------------------------------------------------|
| `agents-control init`     | Scaffold this repo: skills, docs, `AGENTS.md`, `CLAUDE.md`, adapters. |
| `agents-control adapters` | Regenerate `.claude/skills/`. Run after adding or renaming a skill.   |
| `agents-control doctor`   | Show what each tool will discover, and flag what's broken.            |
| `agents-control update`   | Refresh toolkit skills in this repo; never touches your docs.         |

`doctor` is the one worth knowing. It answers "is this repo actually set up for
all three tools?" — catching the failures that are otherwise silent: a
`CLAUDE.md` that exists but lacks the `@AGENTS.md` import, an adapter that broke
on a Windows clone, a skill you added without an adapter, frontmatter that Claude
Code accepts and the others ignore.

```
  TOOL          INSTRUCTIONS             SKILLS
  Claude Code   CLAUDE.md -> AGENTS.md   5 from .claude/skills/
  Codex         AGENTS.md                5 from .agents/skills/
  Cursor        AGENTS.md                5 from .agents/skills/
```

Add `--strict` to make it exit non-zero — useful in CI.

### Symlinks and Windows

By default the Claude Code adapter is one symlink per skill, so
`.agents/skills/` stays the single source of truth. Where symlinks aren't
available — a Windows checkout with `core.symlinks=false` — `init` falls back to
real copies, and the choice is recorded so re-running `adapters` keeps it.

The mode is decided on the machine that runs `init`. If a symlink-mode repo is
later cloned somewhere symlinks don't work, `doctor` reports the broken adapters
and `agents-control adapters --mode=copy` converts the repo for everyone.

## Project docs

**MVP core, created at setup:** README · PRD · STACK · ROADMAP · DECISIONS ·
TASKS · CHANGELOG. Everything else is created **on demand** by the skills — you
don't scaffold what you won't use.

Status: ✅ a skill handles file operations · 🚧 partial, `log` can append but a
dedicated *manage* skill is still needed · 🔴 template exists, no skill yet.

| Doc         | Status | Skill          |
|-------------|--------|----------------|
| SUM         | ✅     | `write-manual` |
| DECISIONS   | ✅     | `decide`       |
| GLOSSARY    | ✅     | `glossary`     |
| IDEAS       | ✅     | `log`          |
| CONCERNS    | ✅     | `log`          |
| STACK       | 🚧     | `log`          |
| TASKS       | 🚧     | `log`          |
| QUESTIONS   | 🚧     | `log`          |
| README      | 🔴     | —              |
| PRD         | 🔴     | —              |
| ROADMAP     | 🔴     | —              |
| FRD         | 🔴     | —              |
| PLAN        | 🔴     | —              |
| EVALUATIONS | 🔴     | —              |
| TESTS       | 🔴     | —              |
| CHANGELOG   | 🔴     | —              |
| UXUI        | 🔴     | —              |
| DEPLOYMENT  | 🔴     | —              |

What each doc is for is described in
[`agents-control-initial-idea.md`](agents-control-initial-idea.md).

## Development status

Early / MVP. The shared core (`AGENTS.md` + manifest + `docs-agents/`) and the
workflow skills in `.agents/skills/` are portable across Claude Code, Codex
(local and cloud) and Cursor.

The original brief this grew from — written before any of it was built — is kept
in [`agents-control-initial-idea.md`](agents-control-initial-idea.md).

## Contributing

```bash
sh tests/test-install.sh                             # end-to-end: install, init, adapters, doctor
./bin/agents-control doctor --skills-only --strict   # skill portability lint
```

Skills must stay within the Agent Skills spec frontmatter (see rule 2 above);
`doctor` fails on anything else.

## License

See [LICENSE](LICENSE).
