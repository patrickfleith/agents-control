# Agents Control

_The initial idea. Content preserved as originally written; only formatting has been applied._

## What I Want

I want an agentic coding setup that is easily understandable by contributors, maintainable and extensible, continuously in-sync with the repo, compact without excessive text, making sure developers trust the outcome, making developers feel in control, not being the bottleneck.

### Keywords

- Understandable
- Maintainable
- Controllable
- Extensible
- Trustable
- Minimal
- MVP

## To be defined

- What is user-triggered only?
- What can be also automatically changed by the model?
- How should it be organized in the repo? Probably in a local claude and .gitignore.
- What should I use and for what: Skills? Command? Agents? Rules?
- Are Hooks useful possibly?
- We probably want it to be connected to github or linear MCP.

## Capabilities

- First we make it work for claude, then also for codex.
- Made primarily for solo dev with occasional contributors.
- Commit commands, rules, styles.
- Code review capabilities.
- Documentation update.
- PR creations, PR reviews.

Claude or Codex must be aware of how to handle the various markdown files and what to do with them (read-only for information and context access, write, create), etc.

Must ultimately work at different stages of software development:

- **Greenfield work** — project creation.
- **Brownfield work** — existing project you jump in.

## Optional capabilities

Distinguish between throwaway vs production code.

- **Throwaway code** — experimental code for testing stuff, user research, quick analyses, demo features, etc. — so that code that don't need attention during a code review. Does not require thorough testing or evals etc.
- **Production code** — code that delivers the core of the value from the project. It must work, be maintained over time. It is more annoying if something breaks than for throwaway code.

## A set of human-friendly readable markdown files

- **README** — Entry point to the project.
- **SUM** — Software and User Manual covering installation guide, quickstart, and detailed usage guide per feature.
- **PRD** — Product Requirement Document describes the requirements at product level. Also contains high-level business context and motivation, user needs, etc.
- **STACK** — Project-level stack (frameworks, libraries, etc.).
- **ROADMAP** — Describes the overall project roadmap: upcoming features, things to work on, rework, improve, fix.
- **FRD** — Feature Requirement Document describes the requirements at feature level.
- **PLAN** — For difficult features, we may need an implementation plan. It is narrower than the roadmap as it targets a specific slice of the roadmap, but made to carry info across multiple sessions.
- **GLOSSARY** — Definition of the terms, disambiguated words, and how to interpret terms in the context of a given project.
- **IDEAS** — A set of ideas that needs to be captured before we forget them, a question to myself of a possibility, an investigation.
- **CONCERNS** — A set of concerns about the project, product, feature which might need to be investigated, or be helpful to capture to relate to bugs.
- **EVALUATIONS** — Specific for AI/ML projects. Describes how the product / features are evaluated.
- **TESTS** — Test Guide for traditional tests, the kind of tests that cover non-AI/ML parts.
- **QUESTIONS** — Questions (not decisions) that I may need to find an answer to (by doing some research, asking a colleague, etc.) that relate to some piece of the work (future work, ongoing or past implementation). Includes the answer once it was answered.
- **TASKS** — At repo level, dump your todos here; avoids having to bloat the context by looking up issues for small things.
- **DECISIONS** — Contains two broad sections: TBD (to be decided) with pending decisions, and then Decided. Captures meaningful decisions made over the course of the project (architecture decision, prioritization, tool, default value).
- **UXUI** — Optional. Contains guidelines and rules for maintaining a high bar for the user experience (even for a CLI tool) and user interface (best practices, rules, etc.).
- **CHANGELOG** — Should contain a chronological, human-readable list of notable changes made in each released version of the project.

---

# Architecture Summary (Claude + Codex compatible)

_Everything above is the original idea, kept verbatim. Everything below is the agreed core architecture from our discussion._

## Guiding principle

The problem is not the number of docs — it is that each doc lacks a defined **name/location** and a clear **purpose** the agent can recognize on sight. The fix is one **manifest** that pins each doc's name, path, and what it's for, plus skills that route work into the right file consistently. Instructions live in **one** file (`AGENTS.md`), with a thin Claude adapter — so the setup works in both Claude Code and Codex without maintaining two brains.

## Two kinds of "awareness"

| Kind | Examples | How the agent learns about it |
|---|---|---|
| **Capabilities** | skills, slash commands, subagents, hooks, MCP servers | **Auto-discovered by the tool.** Claude scans `.claude/skills`, `.claude/commands`, `.claude/agents`; Codex scans its own dirs. You never document these. |
| **Docs (your markdown)** | PRD, STACK, TASKS, DECISIONS… | **NOT understood automatically.** The tool sees the file exists but not what it's for. **This is the only thing the manifest is for.** |

## Awareness chain

Every session, each tool auto-loads its instruction file into context (no command, no action):

```
Claude Code                         Codex
-----------                         -----
CLAUDE.md  ──(@import)──▶ AGENTS.md ◀── read directly
                             │
                             ▼
                   [DOC MANIFEST section]
              "here are the docs + what each is for"
```

- **Claude** always reads `CLAUDE.md` at startup → it is one line, `@AGENTS.md`, which pulls the whole file in.
- **Codex** reads `AGENTS.md` directly at startup (open standard, also read by Cursor/Aider/Copilot).
- Both therefore see the manifest **every session, automatically**. That *is* the mechanism — the file that's always loaded contains the manifest.

## Why there is no separate `INDEX.md`

Claude can follow `@docs/INDEX.md` imports, but **Codex does not follow `@path` imports** — it only concatenates `AGENTS.md` files. A separate manifest file would therefore be invisible to Codex. So the manifest lives as a **section inside `AGENTS.md`** (compact table, always loaded, cross-tool safe). A human-facing table of contents, if ever wanted, is just a section in the README — not part of the agent's awareness path.

**MVP core (start lean, create the rest on demand):** README · PRD · STACK · ROADMAP · DECISIONS · TASKS · CHANGELOG.

## The core architecture: 3 files + a folder

```
AGENTS.md      ← instructions + the manifest table (the brain)
CLAUDE.md      ← one line: "@AGENTS.md"            (Claude adapter)
docs/          ← the actual doc content, names fixed by the manifest
.claude/       ← capabilities, auto-discovered (skills, commands, agents, hooks)
```

## How the manifest looks (a section inside `AGENTS.md`)

The manifest is a compact table: each doc's name, path, and what it captures — no
permission or ownership columns. It tells the agent **which file holds what**, so
it reads and routes work to the right place. Edit etiquette is handled by the
skills and by the human staying in the loop, not by per-doc rules.

```markdown
## Project docs

Project docs live in `docs/` (feature docs under `docs/features/<slug>/`).
Not all exist in every repo — the core set is created at setup, the rest are
added on demand. If a doc doesn't exist yet, don't fabricate one — ask, or
create it with the relevant skill.

| Doc          | Path              | What it captures                       |
|--------------|-------------------|----------------------------------------|
| Product spec | docs/PRD.md       | Product-level requirements & context.  |
| Tech stack   | docs/STACK.md     | Frameworks, libraries, tools.          |
| Roadmap      | docs/ROADMAP.md   | Upcoming features, rework, fixes.      |
| Decisions    | docs/DECISIONS.md | Pending (TBD) and settled decisions.   |
| Tasks        | docs/TASKS.md     | Repo-level todo dump.                  |
| Changelog    | docs/CHANGELOG.md | Notable changes per released version.  |
| …            | …                 | (one row per doc — full set in the template) |
```

Strategy: **Claude first, Codex later.** The shared core (`AGENTS.md` + manifest + `docs/`) is portable today; capabilities are ported per-tool as needed.
