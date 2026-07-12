# agents-control

Take back the control of your coding agents.

**What it is:** a lightweight, tool-agnostic system that keeps your project's
context in a small set of human-readable markdown docs and gives your coding
agent (Claude Code, Codex, …) a **manifest** so it always knows which file holds
what — plus skills that route work into the right file. See
[`agents-control.md`](agents-control.md) for the full idea and architecture.

The whole system is **3 files + a folder**:

```
AGENTS.md    ← agent instructions + the doc manifest (the brain)
CLAUDE.md    ← one line, "@AGENTS.md" (Claude adapter; Codex reads AGENTS.md directly)
docs-agents/ ← the actual doc content (PRD, STACK, ROADMAP, DECISIONS, …)
.claude/     ← skills, auto-discovered by the tool
```

## Quickstart

### 1. Set it up in your repo

From inside the repo you want to bring under agents-control, make the setup
skill available to Claude Code, then run it:

```bash
# install the one-time setup skill (user-level, available in every repo)
mkdir -p ~/.claude/skills/agents-control
curl -fsSL https://raw.githubusercontent.com/patrickfleith/agents-control/main/install/SKILL.md \
  -o ~/.claude/skills/agents-control/SKILL.md
```

Then, in Claude Code opened at your target repo, invoke it:

```
/agents-control
```

or just ask: *"set up agents-control here"*. The skill will:

- fetch the toolkit from GitHub,
- detect greenfield (empty) vs brownfield (existing code),
- install the doc-maintenance skills into `.claude/skills/`,
- scaffold the MVP core docs (`PRD · STACK · ROADMAP · DECISIONS · TASKS · CHANGELOG`),
- generate `AGENTS.md` (with the manifest) + `CLAUDE.md`.

It never overwrites existing files silently — it shows what it'll do, does it,
then reports.

### 2. Use it day to day

Your agent now reads `AGENTS.md` every session and knows where each doc lives.
Drive the docs with the bundled skills (ask in plain language or use the slash
command):

| Skill           | What it does                                              |
|-----------------|----------------------------------------------------------|
| `commit`        | Turn uncommitted work into atomic, conventional commits. |
| `log`           | Append to STACK / TASKS / IDEAS / CONCERNS / QUESTIONS.   |
| `decide`        | Record and manage decisions in DECISIONS.                |
| `glossary`      | Add and refine canonical terms in GLOSSARY.              |
| `write-manual`  | Write or update the user manual (SUM) from the codebase. |

Other doc types (FRD, PLAN, GLOSSARY, SUM, IDEAS, CONCERNS, QUESTIONS,
EVALUATIONS, TESTS, UXUI) are created **on demand** by these skills — you don't
scaffold everything upfront.

## Development status

Early / MVP. **Claude first, Codex later** — the shared core (`AGENTS.md` +
manifest + `docs-agents/`) is portable today; per-tool capabilities are ported as
needed.

Doc coverage (✅ = a skill handles file ops · 🚧 = partial, needs a manage skill · 🔴 = not started):

- ✅ **SUM** (`write-manual`), **DECISIONS** (`decide`), **GLOSSARY** (`glossary`), **IDEAS** / **CONCERNS** (`log`)
- 🚧 **STACK**, **TASKS**, **QUESTIONS** — `log` can append, but a dedicated *manage* skill is still needed
- 🔴 **README**, **PRD**, **ROADMAP**, **FRD**, **PLAN**, **EVALUATIONS**, **TESTS**, **CHANGELOG**, **UXUI**, **DEPLOYMENT** — templates exist, no skill yet

Full status list and rationale live in [`agents-control.md`](agents-control.md).

## License

See [LICENSE](LICENSE).
