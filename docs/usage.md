# Usage guide

This guide covers setup choices, everyday commands, and the details of sharing,
migration, and recovery. For the purpose, philosophy, and first steps, start with
the [README](../README.md).

- [Installation and setup](#install-and-set-up)
- [Private and shared scopes](#private-and-shared-scopes)
- [Document catalogue](#document-catalogue)
- [Agent context and destinations](#load-context-and-choose-a-destination)
- [Sharing content](#share-content)
- [Migration](#migrate-profiles-and-paths)
- [Recovery](#recover-an-interrupted-operation)
- [Ownership, Git, and updates](#ownership-git-and-updates)
- [Commands and configuration](#commands-and-configuration)
- [Tool integration status](#tool-integration-status)
- [Development checks](#verification-and-development)

## Install and set up

```sh
curl -fsSL https://raw.githubusercontent.com/patrickfleith/agents-control/main/install.sh | sh
cd /path/to/project
agents-control init
```

The installer puts code in `~/.agents-control/toolkit/`, links the launcher into
`~/.local/bin/`, and installs personal skills in `~/.agents/skills/` and
`~/.claude/skills/`. Re-running it updates unchanged owned files and preserves
private workspaces. Add `~/.local/bin` to PATH if needed. The established
`~/.agents-control/bin/agents-control` entry point is retained.

`init` defaults to private use. It registers this exact Git worktree and creates
six personal documents outside the checkout. It preserves the team's README,
instructions, skills, configuration, and tracked files.

### Install from a local checkout

To install the version in your checkout, including uncommitted changes, run this
from the agents-control repository root:

```sh
AGENTS_CONTROL_SOURCE="$PWD" sh install.sh
```

Then change into the project where you want to use it. The toolkit repository
itself is not a setup target.

### Choose a profile

For a new setup, choose one of these commands:

```sh
agents-control init --profile=selected
agents-control init --profile=team
agents-control init --profile=team --shared-dir='team docs' --team-tasks
```

An agent can also run the setup skill: `$agents-control` in Codex,
`/agents-control` in Claude Code, or "set up agents-control here" in Cursor.
It reads the codebase and fills the chosen documents with facts. Existing
registrations retain their profile; use `migrate` to change it.

## Private and shared scopes

| Profile | New material | Setup creates |
| --- | --- | --- |
| Private | Private by default | External personal instructions and six personal docs |
| Selected | Private, except explicitly routed doc types | Personal setup; only requested docs become shared |
| Team | Approved shared types; other material stays private | Five shared core docs, team instructions, six skills, adapters, and portable configuration; personal tasks remain private |

The default layout is:

```text
~/.agents-control/
  toolkit/                    installed code
  repos/<id>/
    repo.conf                 exact worktree registration and personal choices
    AGENTS.md                 personal instructions and manifest
    docs/                     private Markdown
    state/                    ownership and retired private paths
  operations/                 local recovery records

project/
  docs-agents-shared/          selected or team Markdown
  AGENTS.md                   existing guidance plus a shared manifest in team mode
  CLAUDE.md                   existing guidance plus an AGENTS.md import if needed
  .agents/skills/             team workflows and their resources
  .claude/skills/             generated team adapters, copies by default
  .agents-control/
    team.conf                 team paths, doc defaults, adapter mode
    context.sh                portable read-only resolver
    managed.tsv               generated artifact ownership
```

Selected mode creates only the shared Markdown that you choose. A teammate can
read it without installing anything. Team setup creates PRD, STACK, ROADMAP,
DECISIONS, and CHANGELOG. It creates a root README only if one is missing.
SUM, GLOSSARY, EVALUATIONS, TESTS, UXUI, and DEPLOYMENT default to shared in team
mode and are created when needed. IDEAS, CONCERNS, QUESTIONS, and
`features/<slug>/FRD.md` and `PLAN.md` default to private. Choose additional
shared defaults with `--shared-docs="PRD STACK ROADMAP DECISIONS CHANGELOG SUM GLOSSARY EVALUATIONS TESTS UXUI DEPLOYMENT IDEAS"`.
`--team-tasks` enables a separate shared TASKS list without creating it yet.

Team configuration controls the shared folder. An individual's switch back to
private or selected use preserves every shared team artifact. Removing team
adoption is a separate project change reviewed in Git.

## Document catalogue

Each document has a specific job. The profile determines its destination;
optional documents appear when you need them.

| Document | What belongs here |
| --- | --- |
| `README.md` | The project's introduction, first steps, and links to further documentation |
| `PRD.md` | Product requirements, users, goals, and business context |
| `STACK.md` | Technology choices and what each is used for |
| `ROADMAP.md` | Upcoming features, improvements, and larger pieces of work |
| `DECISIONS.md` | Open decisions and choices already made, with their reasons |
| `TASKS.md` | Personal tasks or a separate, explicitly enabled team task list |
| `CHANGELOG.md` | Notable changes in released versions |
| `SUM.md` | The software user manual, covering installation and detailed usage |
| `GLOSSARY.md` | Agreed terms and their meanings |
| `IDEAS.md` | Possibilities worth keeping for later |
| `CONCERNS.md` | Risks and issues to investigate |
| `QUESTIONS.md` | Research questions and their answers |
| `EVALUATIONS.md` | How an AI or ML project evaluates model behavior |
| `TESTS.md` | How to run and interpret the project's tests |
| `UXUI.md` | User experience and interface guidelines |
| `DEPLOYMENT.md` | Build, release, environment, and rollback procedures |
| `features/<slug>/FRD.md` | Requirements for one feature |
| `features/<slug>/PLAN.md` | An implementation plan for work spanning sessions |

## Load context and choose a destination

The installer adds a managed loader block to Codex's effective personal
instruction file under `CODEX_HOME`, usually `~/.codex/AGENTS.md`, and to
`~/.claude/CLAUDE.md`. It preserves surrounding guidance and uses an existing
nonempty Codex `AGENTS.override.md` when present. Symlinked instruction files are
preserved and reported for manual integration.

For Cursor, paste `~/.agents-control/cursor-user-rule.md` into User Rules. The
installer does not change GUI settings. If a host does not load personal
instructions, explicitly ask the agent to run `agents-control context`.

`context` prints personal guidance only for a registered worktree. It makes no
changes and prints nothing for an unregistered checkout. Project instructions
still apply; report conflicts with personal preferences. Private context is
available only where its storage is accessible and the host permits reading it.
Remote agents use checked-in shared context unless you provide private context.

```sh
agents-control context
agents-control resolve DECISIONS
agents-control resolve TASKS --scope=private --path
agents-control resolve IDEAS --read
```

A new write resolves to a visibility and an absolute path. For an existing
entry, `--read` lists all relevant files; find the heading or identifier and edit
its containing file. Ask when it matches more than one file. Personal and team
tasks need an explicit owner when a shared task list is enabled or exists.
Unavailable private storage stops the write instead of redirecting it to shared
files. Root README resolves to the project's README by default.

A fresh team clone can resolve shared destinations without the installed CLI:

```sh
sh .agents-control/context.sh resolve PRD
sh .agents-control/context.sh resolve TASKS --scope=shared
sh .agents-control/context.sh guard-index
```

The clone carries skill resources, including the manual template. It has no
personal registration and cannot infer another developer's private paths.

## Share content

Sharing moves content. There is one maintained version, with no synchronization
service or section registry. Subsequent edits happen in the shared file.

```sh
agents-control share /absolute/private/docs/IDEAS.md --to=IDEAS --section='An idea'
# Inspect the diff, then repeat the same command:
agents-control share /absolute/private/docs/IDEAS.md --to=IDEAS --section='An idea' \
  --apply --expect=TOKEN
```

Whole-doc sharing also routes new entries of the destination type to shared in
selected mode. Section sharing keeps the private default. `--merge` explicitly
appends to an existing destination after checking for duplicate headings,
anchors, and identifiers. A source under the registered private docs folder can
be moved into any supported document type.

Section selection supports one exact ATX heading, its nested headings, and
backtick or tilde code fences. The unselected bytes stay intact. Ambiguous
headings, malformed fences, unresolved references, links to private files, and
links broken by relocation stop the operation. Complex Markdown may need a
manual edit before sharing; this is a bounded selector, not a Markdown editor.

## Migrate profiles and paths

```sh
agents-control migrate --profile=selected
agents-control migrate --profile=team
agents-control migrate --private-dir='/absolute/personal workspace'
agents-control migrate --shared-dir='team docs'
agents-control migrate --doc=IDEAS:shared --from=private --section='An idea'
agents-control migrate --doc=QUESTIONS:private --from=shared
```

Every migration previews first. Repeat it with `--apply --expect=TOKEN` to apply.
The token covers affected bytes, configuration, ownership, and relevant index
entries. Changed inputs require a new preview. Folder changes and individual doc
moves use separate previews. Folder changes preserve doc bytes; a shared-folder
rename updates team configuration, the shared manifest, and README path references.
Additional user-owned references should be reviewed in the diff.

### Migrate a legacy setup

Legacy `docs-agents/` content stays unclassified until you choose its destination:

```sh
agents-control migrate --profile=private --doc=PRD:private --from=legacy
agents-control migrate --profile=selected --doc=PRD:shared --from=legacy
agents-control migrate --profile=team --doc=PRD:shared --from=legacy
```

Repeat `--doc` for each choice. Legacy adapter mode is imported and its old state
is preserved. Unselected legacy documents remain visible as `unclassified` in `resolve --read`.
Choose their destination before editing. Review stale paths in preserved project
guidance explicitly; doctor reports them. Old names do not prove generated-file
ownership. Uncertain skills or managed blocks require an explicit `migrate --adopt`
or `init --adopt` preview; inspect exactly what it replaces before applying.
Edited owned artifacts always stop automatic replacement. Resolve them explicitly
before retrying.

Registrations use exact physical worktree roots; different worktrees get separate
private workspaces. If a checkout moves, use `migrate --attach=ID` to reattach its
registration explicitly. For private storage that moved inside the checkout,
pass its new `--private-dir` and review `--adopt` if ownership paths also changed.
A moved or missing registration is never guessed from the remote URL.

## Recover an interrupted operation

Apply stores originals and intended results in an external recovery record,
locks operations across linked worktrees, verifies writes, and checkpoints each
item. Interrupted operations block further mutations and commits:

```sh
agents-control recover --resume
agents-control recover --restore
```

Recovery checks all affected files first. It preserves newer edits outside
managed instruction or exclusion blocks and refuses to overwrite newer edits to
affected content. It also preserves the Git index. The last completed operation
remains recoverable until the next operation replaces its record. If a process
was killed without cleanup, check the PID in the reported lock before removing
a stale lock. Installer recovery uses `sh install.sh --resume` or `--restore`.
Uncertain global installation artifacts can be reviewed with
`sh install.sh --adopt`, then the same command with `--apply --expect=TOKEN`.
This also converts a preserved legacy regular launcher to the new entry point;
owned edits still stop replacement.

## Ownership, Git, and updates

`init`, `update`, and `adapters` apply safe generated changes directly. Sharing,
migration, and explicit adoption require a preview token. No CLI command stages,
commits, or pushes. Stage only the exact shared paths reported by the preview;
review instructions, skills, configuration, and documents as ordinary project
changes. Selected setup shares Markdown only. Private setup has nothing to commit.

Ownership records cover complete skill directories, including assets, symlink
targets, and managed instruction blocks. Automatic updates preserve unowned and
edited files. Write custom team skills in `.agents/skills/`, then explicitly run
`agents-control adapters`. Team setup avoids publishing untracked custom skills
through new adapters. Keep generated adapters unchanged; edit their source and
refresh. Custom skill resources must be real files for portable adapters. New
adapters use copies; `--mode=symlink` keeps repository-relative links.
`--force` no longer overwrites edits.

External private storage needs no Git exclusions. For an in-checkout private
folder, setup checks the index, HEAD, and linked worktrees, then manages only an
escaped block in the common Git exclude file. It preserves unrelated exclusions.
Already tracked private files require explicit removal from the index. The commit
workflow checks the complete index, including material staged before invocation,
and allows staged deletions that remove private tracking. It never unstages work.

Exclusions affect staging; they provide no access control. Agents with filesystem
access may read private files. Moving shared content to private storage cannot
remove it from Git history or existing clones.

## Commands and configuration

| Command | Use |
| --- | --- |
| `init` | Register and set up the current worktree |
| `context` | Read registered personal guidance |
| `resolve DOC` | Resolve a new write or list existing locations with `--read` |
| `guard-index` | Reject indexed private content or pending recovery |
| `share` | Preview a private-to-shared move |
| `migrate` | Preview profile, path, ownership, or content changes |
| `recover` | Resume or restore the last operation |
| `update` | Refresh unedited owned team skills and resolver |
| `adapters` | Refresh owned adapters for team and custom skills |
| `doctor` | Check configuration, resources, adapters, tracking, and recovery |
| `version` | Print the installed toolkit version |

Use `agents-control help` for options. `doctor --strict` fails on warnings;
`doctor --skills-only --strict` checks skill frontmatter without requiring setup.
Doctor checks files and configuration; it does not prove authenticated host discovery.

Configuration uses schema 1, whitelisted `key=value` lines, and no shell evaluation.
Team config contains `shared_dir`, `shared_docs`, and `adapter_mode`; personal
config adds `repo_root`, `profile`, and `private_dir`. Unknown keys, duplicates,
unsupported schemas, traversal, control characters, symlink paths, tool metadata
shared folders, and overlapping storage stop writes. Spaces are supported.

Installer options are environment variables: `AGENTS_CONTROL_REF`,
`AGENTS_CONTROL_SOURCE`, `AGENTS_CONTROL_HOME`, and `AGENTS_CONTROL_BIN_DIR`.
`AGENTS_CONTROL_HOME` also selects the CLI's external state root. Tests use
`AGENTS_CONTROL_USER_HOME` and `AGENTS_CONTROL_CODEX_HOME` to isolate installation;
normal installation honors `HOME` and `CODEX_HOME`.

## Tool integration status

The installer provides personal instructions and skills for Codex and Claude
Code, plus a User Rules snippet for Cursor. Team setup provides repository
instructions and portable skill files. These file layouts are covered by
automated tests.

Automatic discovery and instruction precedence still need live verification.
An isolated Codex CLI 0.162.1 fixture loaded repository instructions and read
additional context on 2026-10-14. Final personal loader behavior, personal skill
selection, subdirectory precedence, and remote discovery remain unverified.
Live checks for Claude Code 2.1.263 and Cursor 3.18.25 were deferred when their
local sessions required authentication.

Explicitly asking an agent to run `agents-control context` is the fallback for
loading personal instructions. Private context requires accessible local storage;
a remote session receives checked-in shared context unless you supply personal
context there.

## Verification and development

Run these commands from a source checkout:

```sh
sh tests/test-install.sh
sh tests/test-recovery.sh
./bin/agents-control doctor --skills-only --strict
```

The isolated tests cover installation, profiles, migrations, sharing, clone
portability, ownership, linked worktrees, index guards, and recovery. The recovery
suite injects failures at every generated setup and installer write checkpoint,
and kills a fixture writer during directory replacement. CI runs shell checks
and both suites on macOS and Ubuntu.

The runtime uses POSIX shell, Git, and basic command-line utilities. It has no
background service or synchronization process.

## License

See [LICENSE](../LICENSE).
