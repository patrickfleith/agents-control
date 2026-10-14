# agents-control

agents-control is a lightweight toolkit for working with AI coding agents on
software projects. It organizes project goals, decisions, and tasks in readable
Markdown and gives agents a small set of workflows for keeping them up to date.

A new session, a different agent, or a new contributor should be able to
understand the project without reconstructing its history from old chats. You
keep control of the context, the decisions, and the changes you share.

Designed for workflows with **Codex, Claude Code, and Cursor**. See the
[integration guide](docs/usage.md#tool-integration-status) for setup and current
verification status.

[Quickstart](#quickstart) · [Setup options](#choose-your-setup) · [Usage guide](docs/usage.md)

## When it helps

Use agents-control when you want to:

- Carry requirements and decisions across coding sessions and different agents.
- Keep personal tasks and ideas while working in someone else's repository.
- Give occasional contributors or a team a common way to understand and maintain
  project knowledge.

It fits both new projects and existing codebases. You can start alone and add
shared workflows when the team wants them.

## The philosophy

- **Keep context readable.** Project knowledge lives in ordinary Markdown that
  people can inspect, edit, and review alongside code.
- **Keep humans in charge.** You choose priorities and approve decisions. Agents
  work on defined tasks and prepare changes for review.
- **Keep the system small.** Start with a few core documents. Add others when
  they serve a purpose, and keep each document focused on its job.
- **Share deliberately.** Personal work stays private by default. Publish what
  collaborators need, with one maintained version of shared content.

For substantial work, give each task one owner, a branch or worktree, and clear
acceptance checks.

## Quickstart

### 1. Install once

On macOS or Linux with Git available:

```sh
curl -fsSL https://raw.githubusercontent.com/patrickfleith/agents-control/main/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
```

This installs the CLI and personal agent skills. The PATH setting above applies
to your current shell; add it to your shell configuration for future sessions.
To install a version from your own checkout, follow the
[local installation instructions](docs/usage.md#install-from-a-local-checkout).

### 2. Set up a project

In the Git repository where you want to use it:

```sh
cd /path/to/your/project
agents-control init
```

The default is **private use**. It creates personal instructions and six starter
documents outside the checkout, preserving the team's files. You get places for
product requirements, the technology stack, a roadmap, decisions, tasks, and a
changelog.

The CLI creates the structure. To give it useful project context, ask your agent:

> Set up agents-control here in private mode. Run `agents-control context`,
> read the codebase, and fill my new product requirements and stack documents
> from the facts you can find. Ask about anything you cannot establish.

The setup skill is also available as `$agents-control` in Codex,
`/agents-control` in Claude Code, or "set up agents-control here" in Cursor.

For Cursor, paste `~/.agents-control/cursor-user-rule.md` into User Rules to
request personal context in future sessions. See
[agent setup and discovery](docs/usage.md#load-context-and-choose-a-destination)
for the tool-specific details.

### 3. Try an everyday workflow

Ask your agent:

> Use ac-log to add a personal task: add tests for retry behavior.

Then try recording a decision with `ac-decide` or defining a project term with
`ac-glossary`. These personal workflows find the right document through your
registered project context.

`agents-control doctor` checks your setup. It checks files and configuration;
[automatic tool discovery is still being verified](docs/usage.md#tool-integration-status).

## Choose your setup

| Profile | Intended use | What you share |
| --- | --- | --- |
| **Private**, the default | Use agents-control on your own in any Git repository | Nothing by default; personal docs and instructions stay outside the checkout |
| **Selected** | Keep your own workflow and publish useful project knowledge | Only the documents or sections you explicitly choose |
| **Team** | Adopt common documentation and agent workflows together | Shared docs, project instructions, skills, and portable configuration |

For a new setup, select a profile with `agents-control init --profile=selected`
or `agents-control init --profile=team`. Shared documents default to
`docs-agents-shared/`; you can choose another folder.

You can begin privately and change later with `agents-control migrate`.
Migration previews the changes before you apply them. Team adoption keeps
personal tasks and scratch material available, and one developer's return to
private use preserves the team's shared setup.

See [profile defaults](docs/usage.md#private-and-shared-scopes) and
[migration examples](docs/usage.md#migrate-profiles-and-paths).

## Work with your agent

A skill is a reusable set of instructions for a particular workflow. The toolkit
includes six. Personal skills use `ac-` names; a team setup installs the shorter
names in the repository.

| What you want to do | Personal skill | Team skill |
| --- | --- | --- |
| Capture a task, idea, concern, question, or technology choice | `ac-log` | `log` |
| Record, revise, or revisit a decision | `ac-decide` | `decide` |
| Define terms and resolve conflicting meanings | `ac-glossary` | `glossary` |
| Write or update the user manual from the codebase | `ac-write-manual` | `write-manual` |
| Organize changes into atomic conventional commits | `ac-commit` | `commit` |
| Keep written text clear and concise | `ac-unslop` | `unslop` |

Use the personal names for your own work and the repository's skills for shared
team work. State the audience when a task or document could belong in either
place. Agents resolve the destination before writing and edit existing entries
where they already live.

You can name the workflow in your request, as in the quickstart, or use your
tool's skill picker.

## How project context stays useful

Documents give each kind of information a home. `PRD.md` holds product
requirements, `STACK.md` describes technology choices, and `DECISIONS.md`
records why choices were made. A feature that spans several sessions can have
its own requirements and implementation plan. Optional documents appear when
needed.

A short **manifest** maps document names to their locations and purposes.
Agents use that map and the workflows to read relevant context and update the
right file. Team context travels with the repository; personal context comes
from `agents-control context` on your machine.

Sharing moves the chosen content into a shared document, where later edits
happen. Teammates can read that Markdown without installing agents-control.
Review shared documentation and instruction changes through your normal Git
process.

## Go further

- [What each document is for](docs/usage.md#document-catalogue)
- [Share a document or section](docs/usage.md#share-content)
- [Change profiles, paths, or an older installation](docs/usage.md#migrate-profiles-and-paths)
- [Recover an interrupted operation](docs/usage.md#recover-an-interrupted-operation)
- [Ownership, Git, and update behavior](docs/usage.md#ownership-git-and-updates)
- [Command and configuration reference](docs/usage.md#commands-and-configuration)
- [Development checks](docs/usage.md#verification-and-development)

Licensed under [MIT](LICENSE).
