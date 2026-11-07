<h1 align="center">agents-control</h1>

<p align="center">
  <strong>Stay in charge of your work with coding agents.</strong>
</p>

<p align="center">
  <a href="https://github.com/patrickfleith/agents-control/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/patrickfleith/agents-control/actions/workflows/ci.yml/badge.svg"></a>
  <a href="LICENSE"><img alt="MIT license" src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
  <img alt="macOS and Linux" src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey.svg">
</p>

Coding agents write code fast. Keeping the work organized is still your job.
Goals and decisions end up scattered across chats and loose notes. It gets
hard to see what was decided, why, and what to do next.

agents-control gives you a personal notes folder in each project for goals,
decisions and planned work. You and your agents read and update the same
notes. You set the direction and make the decisions. Your agents are told to
work from the notes and record what changed.

**On your own project**, review the plan before your agent starts and check
what changed afterward.

**In a team repository**, keep personal notes for your part of the work. Setup
tells Git to ignore the notes folder, so your teammates have no extra files to
review. Nobody else needs to install anything.

<p align="center">
  <img src="docs/images/how-it-works.svg" width="820" alt="You set goals, make decisions and review the work. These go into your project notes: goals, decisions, tasks, ideas and questions. Your agents, such as Claude Code, Codex and Cursor, read the notes to follow the plan and update them with what changed. Git ignores your notes folder by default.">
</p>

[Quickstart](#quickstart) · [Workflows](#4-use-the-workflows) · [How it works](#how-it-works)

## What you get

- **Use the same notes across tools.** Set up Claude Code, Codex or Cursor to
  read and update them.
- **Notes you can read and edit.** Open the Markdown files in your editor.
- **Runs locally.** A small command-line tool and a few agent instructions.
  There is no service to host.

## An example

The `ac-decide` workflow records decisions and their reasons. Tell your agent:
*"Use ac-decide to record our choice of SQLite for the cache. We don't want to
run a database server."*

The agent adds this entry (shortened here) to `DECISIONS.md` in your notes folder:

```markdown
### DEC-004 — SQLite for the cache

**Decision:** Store the cache in SQLite.

**Rationale:** We don't want to run a separate database server.
```

Then ask: *"Plan the cache work using SQLite. Wait for my review before coding.
Record what changed when you're done."*

If your needs change, use `ac-decide` again to revise the decision and record
why.

## Why not keep a notes file myself?

You can. agents-control creates a set of notes in each project and gives your
agents instructions for finding and updating them. The `ac-commit` workflow
tells your agent to check that no private notes are staged before it commits.

Good to know: the notes stay in one folder on one computer. agents-control does
not sync or back them up.

## Quickstart

Requires macOS or Linux, Git, curl, and a coding agent that can read local files.

### 1. Install once

```sh
curl -fsSL https://raw.githubusercontent.com/patrickfleith/agents-control/main/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
```

Add the PATH setting to your shell configuration for future terminals.
For Cursor, see [agent setup](#agent-setup).

### 2. Set up a project

Inside your project's Git checkout:

```sh
cd /path/to/your/project
agents-control init
```

This creates your Git-excluded `docs-agents-private/` folder and starter documents.

### 3. Fill your project context

Ask your agent:

> Use ac-init to fill my private project context from the codebase. Ask me about
> goals or requirements you cannot establish.

### 4. Use the workflows

Name a workflow in your request:

| Skill | Use it to |
| --- | --- |
| `ac-init` | Set up and fill private project context |
| `ac-log` | Capture a task, idea, technology choice, concern or question |
| `ac-decide` | Record, revise or revoke a decision with its rationale |
| `ac-glossary` | Define project terms and resolve conflicting meanings |
| `ac-write-manual` | Write or update a private user manual from the codebase |
| `ac-commit` | Organize code changes into atomic conventional commits |
| `ac-unslop` | Keep writing clear and concise |

Try these requests:

> Use ac-log to add a task: test retry behavior when the service is unavailable.

> Use ac-decide to record that we chose SQLite for the local cache because we
> need persistence without running a separate database service.

> Use ac-log to capture a concern: retrying a payment request could create a
> duplicate charge.

> Use ac-commit to organize these changes into commits.

## Details

### How it works

agents-control stores ordinary Markdown in `docs-agents-private/`, beside your
code. A small CLI handles setup and document paths. Personal `ac-` skills help
your agent keep the notes useful as you work. A skill is a reusable set of
instructions for a specific task.

Setup adds the folder to `.git/info/exclude`, the local Git exclusion file,
and preserves existing project files. Skills live in your user skill folders.
The writing workflows resolve private document paths before editing. `ac-commit`
checks the Git index for private files before each commit.

### Agent setup

For Codex and Claude Code, the installer adds personal skills and instructions
that ask the agent to load your project context. For Cursor, paste
`~/.agents-control/cursor-user-rule.md` into User Rules.

If your agent does not load the context automatically, ask:

> Run agents-control context and read the private documents relevant to this task.

Check your setup with:

```sh
agents-control doctor
```

For a local checkout of agents-control, see the
[local installation instructions](docs/usage.md#installation-and-discovery).

### What lives in the private folder?

```text
your-project/
  docs-agents-private/
    AGENTS.md       Personal instructions and document guide
    PRD.md          Project goals, requirements and users
    STACK.md        Technology choices
    ROADMAP.md      Upcoming work
    DECISIONS.md    Decisions and their reasons
    TASKS.md        Personal tasks
    CHANGELOG.md    Changes worth remembering
```

`init` creates the structure. You and your agent supply the project knowledge.
Rerunning setup preserves your existing notes. Linked worktrees share the private
folder in the main checkout, so notes survive when you remove a worktree.

Optional documents cover ideas, concerns, questions, terminology, a user manual,
tests, evaluations, interface guidelines and deployment. Larger features can have
their own requirements and implementation plan. Create these only when needed;
the [document guide](docs/usage.md#optional-documents) lists the available types.

### How context carries forward

At the start of a session, `agents-control context` returns personal instructions
and the private folder's location. Your agent reads the documents relevant to its
task. As you work, use the skills to capture decisions, questions and follow-up
work. The next session can pick up those files.

Keep notes current and focused. A short explanation of a decision or a concrete
next step is usually more useful than a transcript of the conversation.

### Updates and further reading

Rerun the installer to update. Your private notes stay in the main checkout. Locally
edited skills or conflicting files stop the update so you can review them.

- [Commands and document types](docs/usage.md)
- [Installation and context discovery](docs/usage.md#installation-and-discovery)
- [Upgrade from an older layout](docs/usage.md#upgrade-from-an-older-layout)
- [Development checks](docs/usage.md#development)

Licensed under [MIT](LICENSE).
