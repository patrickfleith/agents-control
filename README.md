<h1 align="center">agents-control</h1>

<p align="center">
  <strong>Stop re-explaining your project to every coding agent.</strong><br>
  Keep goals, decisions and next steps in private Markdown beside your code.<br>
  Claude Code, Codex and Cursor read them. Your team's Git history stays clean.
</p>

<p align="center">
  <a href="https://github.com/patrickfleith/agents-control/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/patrickfleith/agents-control/actions/workflows/ci.yml/badge.svg"></a>
  <a href="LICENSE"><img alt="MIT license" src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
  <img alt="macOS and Linux" src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey.svg">
</p>

<p align="center">
  <a href="#quickstart">Quickstart</a> ·
  <a href="#4-use-the-workflows">Workflows</a> ·
  <a href="#how-it-works">How it works</a>
</p>

<p align="center">
  <img src="docs/images/how-it-works.svg" width="860" alt="In today's Claude Code session you tell the agent about a decision and a next step. Through the ac-decide and ac-log skills, the agent writes them to docs-agents-private/. In later sessions, any agent runs agents-control context and reads the same notes. The folder is listed in .git/info/exclude, so the team's commits contain no personal notes.">
</p>

## The problem

Every agent session starts cold. You explain the goal again, the stack again,
and why you already ruled out the obvious approach. Switch from Claude Code to
Codex and you explain it all a third time.

The usual fixes either leak or don't travel. A personal `AGENTS.md` or memory
bank sits in the repo, one `git add .` away from code review. Built-in
agent memory stays inside one tool.

## What agents-control gives you

- **Sessions that build on each other.** Each new session starts by reading
  your goals, decisions and open tasks. You add to them in one sentence:
  *"Use ac-decide to record that we chose SQLite for the cache."*
- **One context for every agent.** Claude Code, Codex and Cursor read the same
  files, so changing tools doesn't mean starting over. Cursor needs a one-time
  rule paste.
- **Notes that stay yours.** The folder is listed in `.git/info/exclude`, so
  `git add .` skips it, and `ac-commit` stops if private files are staged. Use it
  in any checkout, including client code and open-source projects, without asking
  anyone to adopt a tool.
- **Memory you can read.** Plain Markdown you can edit, prune or open in your
  editor. No database, no server, no network calls at runtime: a few hundred
  lines of shell and a set of `ac-` agent skills, installed once per machine.

### Why not just keep an ignored notes folder?

You can, and agents-control is not much more than that. It adds the parts you
would otherwise repeat in every project: an instruction that points each agent
at the notes, a document structure agents know how to use, skills that keep the
notes current, and an `ac-commit` workflow that refuses to commit private files.

| Approach | Out of the team repo | Works across agents | Structure and upkeep |
| --- | :---: | :---: | :---: |
| Committed `AGENTS.md` or memory bank | No | Yes | Manual |
| Built-in agent memory | Yes | No | Automatic, opaque |
| Ignored folder you set up yourself | Yes | If you tell them | Manual |
| **agents-control** | **Yes** | **Yes** | **Templates + `ac-` skills** |

**Limitation:** notes live in one checkout and are not synced or backed up. A
fresh clone on another machine starts empty.

### What a saved decision looks like

You say *"Use ac-decide to record that we chose SQLite for the local cache."*
The agent appends this to `docs-agents-private/DECISIONS.md`:

```markdown
### DEC-004 — SQLite for the local cache

Decided by: Author with Agent
Date: 2026-11-03 14:20

**Decision:** Store the local cache in SQLite.

**Rationale:** We need persistence without running a separate database service.
```

Next week, before Cursor touches the cache code, it reads this entry and builds
on the decision instead of proposing Redis.

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
