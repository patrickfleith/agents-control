<h1 align="center">agents-control</h1>

<p align="center">
  <strong>Private project memory for your coding agents.</strong><br>
  Goals, decisions and next steps in plain Markdown beside your code.<br>
  Shared by Claude Code, Codex and Cursor. Never committed to Git.
</p>

<p align="center">
  <a href="https://github.com/patrickfleith/agents-control/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/patrickfleith/agents-control/actions/workflows/ci.yml/badge.svg"></a>
  <a href="LICENSE"><img alt="MIT license" src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
  <img alt="macOS and Linux" src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey.svg">
</p>

<p align="center">
  <a href="#quickstart">Quickstart</a> ·
  <a href="#4-use-the-workflows">Workflows</a> ·
  <a href="#details">How it works</a>
</p>

<p align="center">
  <img src="docs/images/how-it-works.svg" width="860" alt="Today's Claude Code session saves decisions and next steps to docs-agents-private/. Later sessions in Codex and Cursor read the same notes. The folder is excluded from Git, so the team's history holds no personal notes.">
</p>

## The problem

Every agent session starts cold. You explain the goal again, the stack again,
and why you already ruled out the obvious approach. Switch from Claude Code to
Codex and you explain it all a third time.

The usual fixes have a cost. A long `AGENTS.md` or memory bank lands in the
team's repository, where your half-formed plans don't belong. Chat history is
tied to one tool and too long to reread.

## What agents-control gives you

- **Sessions that build on each other.** Your agent starts by reading the
  requirements, technology choices and decisions you saved last time, then picks
  up the next step.
- **One context for every agent.** Claude Code, Codex and Cursor read the same
  files, so changing tools doesn't mean starting over.
- **Notes that stay yours.** The folder is listed in `.git/info/exclude`. Use it
  in any checkout, including client code and open-source projects, without
  touching the team's files or asking anyone to adopt a tool.
- **Memory you can read.** Plain Markdown, no database or server. Edit a decision,
  delete a stale note, or open the files in your editor.

| Approach | Where the context lives | Shared across agents | Stays out of Git |
| --- | --- | :---: | :---: |
| Committed `AGENTS.md` / memory bank | In the team repository | ✓ | ✗ |
| Built-in agent memory | Inside one tool | ✗ | ✓ |
| **agents-control** | Local Markdown beside your code | ✓ | ✓ |

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
