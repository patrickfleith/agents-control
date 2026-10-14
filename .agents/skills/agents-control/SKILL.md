---
name: agents-control
description: Set up agents-control in the current Git worktree with private use, selected shared docs, or team adoption. Use for "set up agents-control", "bootstrap this repo", "scaffold the agent docs", or "init agents-control here".
---

# Set up agents-control

Use the installed `agents-control` CLI for file operations. If it is absent from
PATH, try `~/.agents-control/toolkit/bin/agents-control`, then the established
`~/.agents-control/bin/agents-control` entry point. If none exists, report the
missing installation and provide the install command from the toolkit README.
Do not recreate the installer's files by hand or bypass the toolkit self-guard.

## Choose the scope

Honor the user's chosen profile. For new setup without an explicit choice, use
private. Explain that personal files stay outside the checkout; selected mode
shares only requested Markdown; team mode adds shared instructions and workflows.
If the request implies team adoption but is unclear, ask while inspecting the repo.
For team setup, clarify whether IDEAS, CONCERNS, QUESTIONS, or team tasks should
be shared when that choice matters. Their default is private. Optional docs stay
on demand. Use `--shared-docs` and `--team-tasks` for explicit choices.

Run `agents-control init --profile=private|selected|team` with the chosen paths.
Read the result before editing. Existing registrations keep their recorded mode;
use `migrate` to change it. Legacy layouts need explicit document destinations.
Sharing, migration, and uncertain ownership adoption preview first. Inspect the
concrete diff and repeat the same command with its `--apply --expect=TOKEN` when
that change is authorized. Stop on ownership conflicts and preserve edited files.

## Fill documents from the codebase

Read enough code and configuration to describe the project and its actual stack.
For an empty project, ask for the missing product and stack choices. Do not invent
requirements or decisions.

Resolve PRD and STACK before writing with `agents-control resolve DOC`. Use
`--read` to find existing entries and keep edits in their containing file. Fill
only newly created templates or documents the user asked to update. Preserve
existing README, instructions, skills, and unrelated docs. A team setup never
publishes existing private content merely because its type defaults to shared.

Generated manifest blocks belong to the CLI. Put project-specific instructions
outside those blocks. In private or selected use, personal guidance belongs in
the registered private AGENTS.md; in team use, shared guidance belongs in the
repository AGENTS.md. Never put private paths into shared instructions.

## Check and report

Run `agents-control doctor`. Resolve mechanical warnings within the chosen scope;
report conflicts needing a user decision. Doctor checks files, not live host
instruction precedence. Do not claim discovery was verified from placement alone.

Report the profile, concrete private and shared locations, changed shared paths,
and any required tracking removal. Private setup has nothing to commit. Selected
setup shares only the chosen Markdown. Team setup's exact shared files can be
reviewed and committed through the project's normal workflow; do not stage them
as part of setup unless requested.

The global installer adds personal loader instructions for Codex and Claude Code.
For Cursor, tell the user to paste the generated `cursor-user-rule.md` into User
Rules. Explicitly requesting `agents-control context` is the fallback when a host
does not load personal guidance. Private context requires accessible local storage;
remote sessions use checked-in team context unless personal context is supplied.

Personal workflows use `ac-` names and require a registered worktree. Team skills
use commit, log, decide, glossary, write-manual, and unslop. A fresh team clone uses
`sh .agents-control/context.sh` to resolve shared docs without the global CLI.
