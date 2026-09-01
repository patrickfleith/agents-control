# agents-control

Take back control of your coding agents.

**What it is:** a tool-agnostic system that keeps your project context in a small
set of readable markdown docs. It gives your coding agent a **manifest** so the
agent knows which file holds what, plus skills that route work into the right
file.

Works the same in **Claude Code**, **Codex** (local and cloud) and **Cursor**.

## Quickstart

### 1. Install once

```bash
curl -fsSL https://raw.githubusercontent.com/patrickfleith/agents-control/main/install.sh | sh
```

This fetches the toolkit to `~/.agents-control`, puts `agents-control` on your
`PATH`, and installs the setup skill where each tool looks for it:
`~/.agents/skills/` for Codex and Cursor, `~/.claude/skills/` for Claude Code.
Re-run it any time to update.

### 2. Set up a repo

In the repository you want to bring under agents-control, ask your agent:

| Tool        | How to invoke                |
|-------------|------------------------------|
| Claude Code | `/agents-control`            |
| Codex       | `$agents-control`            |
| Cursor      | "set up agents-control here" |

The agent runs `agents-control init` to place the files, then does the part a
script cannot. It reads your codebase, writes a project description into
`AGENTS.md`, fills `STACK.md` with the frameworks and libraries you use, and cuts
manifest rows for docs this project will not have.

Prefer to do it yourself? `agents-control init` is the whole file-placement step.

Then commit `.agents/`, `.claude/`, `AGENTS.md`, `CLAUDE.md` and `docs-agents/`.
Cloud sessions read the skills from your checked-out repository.

### 3. Use it day to day

Your agent reads `AGENTS.md` every session and knows where each doc lives. Drive
the docs with the bundled skills:

| Skill          | What it does                                             |
|----------------|----------------------------------------------------------|
| `commit`       | Turn uncommitted work into atomic, conventional commits. |
| `log`          | Append to STACK / TASKS / IDEAS / CONCERNS / QUESTIONS.  |
| `decide`       | Record and manage decisions in DECISIONS.                |
| `glossary`     | Add and refine agreed terms in GLOSSARY.                 |
| `write-manual` | Write or update the user manual (SUM) from the codebase. |
| `unslop`       | Writing rules for anything an agent writes.              |

Invoke them as `/name` in Claude Code, `$name` in Codex, or by asking in plain
language in Cursor.

## How it works

### The problem it solves

Each doc lacks a fixed **name and location**, and a **purpose** the agent can
recognise on sight. The number of docs is not the problem. The fix is one
**manifest** that pins each doc's name, path and what it holds, plus skills that
route work into the right file. Instructions live in one file, `AGENTS.md`.
Claude Code reads that file through a generated one-line adapter, so you maintain
a single set of instructions.

### Two kinds of awareness

| Kind | Examples | How the agent learns about it |
|---|---|---|
| **Capabilities** | skills, slash commands, subagents, hooks, MCP servers | **Auto-discovered by the tool.** Commit portable skills in `.agents/skills/`; Codex and Cursor discover that path natively, locally and after a cloud task checks out the repo. Claude Code reads only `.claude/skills/`, so agents-control generates one entry there per skill. |
| **Docs (your markdown)** | PRD, STACK, TASKS, DECISIONS… | **NOT understood automatically.** The tool sees the file exists but not what it's for. **This is the only thing the manifest is for.** |

### The awareness chain

Every session, each tool loads its instruction file into context. No command, no
action:

```
Claude Code                       Codex (local + cloud) · Cursor
-----------                       -----------------------------
CLAUDE.md  ──(@import)──▶ AGENTS.md ◀── read directly
                             │
                             ▼
                   [DOC MANIFEST section]
              "here are the docs + what each is for"
```

- **Claude Code** always reads `CLAUDE.md` at startup. That file is one line,
  `@AGENTS.md`, which pulls in the whole manifest. It never reads `AGENTS.md`
  itself.
- **Codex and Cursor** read `AGENTS.md` directly at startup; Codex cloud tasks
  receive it when they check out the repository.
- All three see the manifest every session. The mechanism is simple: the file
  each tool always loads contains the manifest.

| Tool        | Instructions               | Skills                                |
|-------------|----------------------------|---------------------------------------|
| Codex       | `AGENTS.md`                | `.agents/skills/`                     |
| Cursor      | `AGENTS.md`                | `.agents/skills/`                     |
| Claude Code | `CLAUDE.md` → `@AGENTS.md` | `.claude/skills/` → `.agents/skills/` |

### The layout

```
AGENTS.md        ← instructions + the manifest table
docs-agents/     ← the doc content, names fixed by the manifest
.agents/skills/  ← committed skills, the one source of truth
CLAUDE.md        ← generated Claude Code adapter: one line, "@AGENTS.md"
.claude/skills/  ← generated Claude Code adapter: one entry per skill
```

A script generates the two `.claude/` entries. Never edit them by hand. Write
skills in `.agents/skills/` and run `agents-control adapters`.

Two directories is the minimum. Codex reads `.agents/skills/` and never
`.claude/skills/`. Claude Code reads `.claude/skills/` and never
`.agents/skills/`. Cursor reads both. Every skill still exists once on disk,
because the `.claude/` entries are symlinks into `.agents/skills/`.

### The manifest

The manifest is a compact table inside `AGENTS.md`: each doc's name, path and
what it captures. It has no permission or ownership columns. It tells the agent
**which file holds what**, so the agent reads and routes work to the right place.
The skills and the human in the loop handle edit etiquette, so the manifest
carries no per-doc rules.

```markdown
## Project docs

Project docs live in `docs-agents/` (feature docs under `docs-agents/features/<slug>/`).
Not all exist in every repo. `agents-control init` creates the core set, and the
skills add the rest on demand. If a doc does not exist yet, do not fabricate one.
Ask, or create it with the relevant skill.

| Doc          | Path                     | What it captures                            | Skill    |
|--------------|--------------------------|---------------------------------------------|----------|
| Product spec | docs-agents/PRD.md       | Product-level requirements & context.       | none     |
| Tech stack   | docs-agents/STACK.md     | Frameworks, libraries, tools.               | `log`    |
| Roadmap      | docs-agents/ROADMAP.md   | Upcoming features, rework, fixes.           | none     |
| Decisions    | docs-agents/DECISIONS.md | Pending (TBD) and settled decisions.        | `decide` |
| Tasks        | docs-agents/TASKS.md     | Repo-level todo dump.                       | `log`    |
| Changelog    | docs-agents/CHANGELOG.md | Notable changes per released version.       | none     |
| …            | …                        | one row per doc, full set in the template   | …        |
```

### Why there is no separate `INDEX.md`

Claude Code can follow `@docs-agents/INDEX.md` imports. **Codex does not follow
`@path` imports.** It only concatenates `AGENTS.md` files, so a separate manifest
file would be invisible to Codex. The manifest therefore lives as a **section
inside `AGENTS.md`**: compact, always loaded, safe across tools. If you ever want
a table of contents for humans, put it in this README. It is not part of the
agent's awareness path.

### Two rules that keep it honest

1. **The mechanical work belongs to a script.** `agents-control init` places
   every file the same way whatever agent drives it. The setup skill keeps only
   the judgment: what the project is, what it is built with, which docs it will
   use.
2. **Skills stay inside the [Agent Skills](https://agentskills.io) spec
   frontmatter:** `name`, `description`, `license`, `compatibility`, `metadata`,
   `allowed-tools`. Anything beyond that works in Claude Code, and the other
   tools drop it without an error. That asymmetry is what this design prevents.

## Commands

| Command                   | What it does                                                          |
|---------------------------|-----------------------------------------------------------------------|
| `agents-control init`     | Scaffold this repo: skills, docs, `AGENTS.md`, `CLAUDE.md`, adapters. |
| `agents-control adapters` | Regenerate `.claude/skills/`. Run after adding or renaming a skill.   |
| `agents-control doctor`   | Show what each tool will discover, and flag what's broken.            |
| `agents-control update`   | Refresh toolkit skills in this repo; never touches your docs.         |

`doctor` is the one worth knowing. It answers "is this repo set up for all three
tools?" and it catches the failures that raise no error: a `CLAUDE.md` that
exists but lacks the `@AGENTS.md` import, an adapter that broke on a Windows
clone, a skill you added without an adapter, frontmatter that Claude Code accepts
and the others ignore.

```
  TOOL          INSTRUCTIONS             SKILLS
  Claude Code   CLAUDE.md -> AGENTS.md   6 from .claude/skills/
  Codex         AGENTS.md                6 from .agents/skills/
  Cursor        AGENTS.md                6 from .agents/skills/
```

Add `--strict` to make it exit non-zero, which is what you want in CI.

### Symlinks and Windows

By default the Claude Code adapter is one symlink per skill, so `.agents/skills/`
stays the one source of truth. Where symlinks are not available, such as a
Windows checkout with `core.symlinks=false`, `init` falls back to real copies. It
records that choice, so re-running `adapters` keeps it.

The machine that runs `init` decides the mode. If you later clone a symlink-mode
repo somewhere symlinks do not work, `doctor` reports the broken adapters and
`agents-control adapters --mode=copy` converts the repo for everyone.

## Doc types and coverage

Docs sit at two levels:

- **Product level.** PRD says what the product is, for whom, and why. ROADMAP
  says what is coming. One of each per repo, in `docs-agents/`.
- **Feature level.** FRD holds the requirements for one feature. PLAN holds how
  to build it, for a feature big enough to need a plan that survives across
  sessions. One set per feature, in `docs-agents/features/<slug>/`.

Everything else is repo-level: STACK, DECISIONS, TASKS, GLOSSARY, CHANGELOG and
the rest live directly in `docs-agents/`.

**MVP core, created at setup:** README · PRD · STACK · ROADMAP · DECISIONS ·
TASKS · CHANGELOG. The skills create everything else on demand, so you never set
up what you will not use.

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
| README      | 🔴     | none           |
| PRD         | 🔴     | none           |
| ROADMAP     | 🔴     | none           |
| FRD         | 🔴     | none           |
| PLAN        | 🔴     | none           |
| EVALUATIONS | 🔴     | none           |
| TESTS       | 🔴     | none           |
| CHANGELOG   | 🔴     | none           |
| UXUI        | 🔴     | none           |
| DEPLOYMENT  | 🔴     | none           |

[`agents-control-initial-idea.md`](agents-control-initial-idea.md) describes what
each doc is for.

## Development status

Early / MVP. The shared core (`AGENTS.md` + manifest + `docs-agents/`) and the
workflow skills in `.agents/skills/` are portable across Claude Code, Codex
(local and cloud) and Cursor.

[`agents-control-initial-idea.md`](agents-control-initial-idea.md) keeps the
original brief, written before any of this existed.

## Contributing

```bash
sh tests/test-install.sh                             # end-to-end: install, init, adapters, doctor
./bin/agents-control doctor --skills-only --strict   # skill portability lint
```

Skills must stay within the Agent Skills spec frontmatter (see rule 2 above);
`doctor` fails on anything else.

## License

See [LICENSE](LICENSE).
