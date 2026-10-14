# agents-control

Private Markdown notes and personal skills for working with coding agents.
Keep project goals, decisions and tasks between sessions in
`docs-agents-private/`, inside your checkout and excluded from Git.

## Get started

Install once on macOS or Linux with Git:

```sh
curl -fsSL https://raw.githubusercontent.com/patrickfleith/agents-control/main/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
```

Add that PATH setting to your shell configuration if needed. Then, in a project:

```sh
agents-control init
```

Ask your agent:

> Use ac-init to set up agents-control here and fill my project context from the codebase.

Setup creates six documents: `PRD.md`, `STACK.md`, `ROADMAP.md`,
`DECISIONS.md`, `TASKS.md` and `CHANGELOG.md`, plus private instructions.
Your project files stay intact. The local exclusion goes into `.git/info/exclude`.

## Use it

| Request | Personal workflow |
| --- | --- |
| Set up private project context | `ac-init` |
| Capture a task, idea, concern, question or technology choice | `ac-log` |
| Record or revisit a decision | `ac-decide` |
| Define project terms | `ac-glossary` |
| Write or update a private user manual | `ac-write-manual` |
| Organize changes into conventional commits | `ac-commit` |
| Keep writing clear and concise | `ac-unslop` |

For example:

> Use ac-log to add a task: test retry behavior.

> Use ac-decide to record why we chose SQLite.

All document types remain available. Optional documents appear when needed.
Read and edit them yourself whenever you want.

The installer adds personal `ac-` skills and a context loader for Codex and
Claude Code. For Cursor, paste `~/.agents-control/cursor-user-rule.md` into
User Rules. If your agent does not load context automatically, ask it to run
`agents-control context`.

`agents-control doctor` checks the private folder and Git exclusion.
Rerun the installer to update the toolkit. Your notes stay in each checkout.

[Usage, document types and upgrading](docs/usage.md) · [MIT license](LICENSE)
