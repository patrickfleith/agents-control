# AGENTS.md

Instructions for AI coding agents (Claude Code, Codex, and any tool that reads
`AGENTS.md`) working in this repo. Claude loads it via `@AGENTS.md` in
`CLAUDE.md`; other tools read this file directly. It is loaded every session —
this is the whole mechanism, so keep it compact and current.

## How to work here

- **What this is:** <one line — what this project is and who it's for>.
- Before acting, consult the relevant project doc below.
- Keep changes minimal and in the style of the surrounding code.

## Project docs

Project docs live in `docs/` (feature docs under `docs/features/<slug>/`).
Not all exist in every repo — the core set is created at setup, the rest are
added on demand. If a doc doesn't exist yet, don't fabricate one — ask, or
create it with the relevant skill.

| Doc          | Path                         | What it captures |
|--------------|------------------------------|------------------|
| Readme       | README.md                    | Entry point to the project. |
| Product spec | docs/PRD.md                  | Product-level requirements, business context, user needs. |
| Stack        | docs/STACK.md                | Frameworks, libraries, tools. |
| Roadmap      | docs/ROADMAP.md              | Upcoming features, rework, fixes. |
| Decisions    | docs/DECISIONS.md            | Pending (TBD) and settled decisions. |
| Tasks        | docs/TASKS.md                | Repo-level todo dump. |
| Changelog    | docs/CHANGELOG.md            | Notable changes per released version. |
| Manual (SUM) | docs/SUM.md                  | Install + usage guide for end users. |
| Glossary     | docs/GLOSSARY.md             | Canonical term definitions. |
| Ideas        | docs/IDEAS.md                | Captured ideas / possibilities to explore. |
| Concerns     | docs/CONCERNS.md             | Risks and concerns to investigate. |
| Questions    | docs/QUESTIONS.md            | Open questions + answers once resolved. |
| Evaluations  | docs/EVALUATIONS.md          | How AI/ML features are evaluated. |
| Tests        | docs/TESTS.md                | Test guide for non-AI/ML parts. |
| UX/UI        | docs/UXUI.md                 | UX/UI guidelines and rules. |
| Feature spec | docs/features/<slug>/FRD.md  | Feature-level requirements. |
| Impl plan    | docs/features/<slug>/PLAN.md | Multi-session implementation plan for a feature. |

## Capabilities

Skills are auto-discovered from `.claude/skills/` — you don't document them here.
Installed by the agents-control setup: `commit`, `log`, `decide`, `glossary`,
`write-manual`.
