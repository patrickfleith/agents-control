# Usage

## One private folder

Each checkout has its own `docs-agents-private/`:

```text
docs-agents-private/
  AGENTS.md       personal instructions and document guide
  PRD.md          goals, requirements and users
  STACK.md        technology choices
  ROADMAP.md      upcoming work
  DECISIONS.md    decisions and their reasons
  TASKS.md        personal tasks
  CHANGELOG.md    changes worth remembering
```

Setup adds `/docs-agents-private/` to the repository's local Git exclusion file.
It preserves the project's instructions, docs, skills and `.gitignore`.
No profiles, shared folders or project configuration are needed.
Linked worktrees get separate notes. Moving a checkout preserves its setup.

Keep goals and requirements in PRD, upcoming work in ROADMAP, and concrete
personal work in TASKS. Record decisions with their reasons so another session
can follow them. Agents read the relevant files instead of every document.

## Optional documents

Create these only when the work needs them:

| Document | Purpose |
| --- | --- |
| IDEAS.md | Ideas to consider |
| CONCERNS.md | Risks to investigate |
| QUESTIONS.md | Open questions and answers |
| GLOSSARY.md | Project terms |
| SUM.md | User manual |
| EVALUATIONS.md | AI evaluation guide |
| TESTS.md | Test guide |
| UXUI.md | Interface guidelines |
| DEPLOYMENT.md | Release and operations guide |
| features/<slug>/FRD.md | Feature requirements |
| features/<slug>/PLAN.md | Implementation plan for substantial work |

Templates ship with the toolkit. `ac-write-manual` carries its own manual template.
Document paths come from `agents-control resolve DOC`. Resolving a path does
not create a document. Existing entries keep their IDs and stay in their file.

## Commands

| Command | Result |
| --- | --- |
| `agents-control init` | Create missing starter files and the local Git exclusion |
| `agents-control context` | Print private instructions and the current folder location |
| `agents-control resolve TASKS` | Print the absolute path to TASKS.md |
| `agents-control resolve TASKS --read` | Print existing contents, or nothing when absent |
| `agents-control guard-index` | Fail if private files are in the Git index |
| `agents-control doctor` | Check setup, exclusion and Git tracking |
| `agents-control doctor --skills-only` | Check the toolkit's personal skill sources |
| `agents-control version` | Print the installed version |

Commands work from any subdirectory. Context prints nothing in an unconfigured
checkout or outside Git. Writing workflows require setup and never fall back
to repository docs. Init is safe to rerun and preserves existing private notes.

Git exclusions prevent ordinary staging. They do not untrack existing files or
prevent `git add -f`. `ac-commit` checks the complete index before each commit.
If private files were forced into the index, review them and remove them from
tracking with `git rm --cached` before committing. These files remain readable
to local tools; the folder name and Git exclusion are not access controls.

## Installation and discovery

Installed code lives in `~/.agents-control/toolkit/`. Skills are copies under
`~/.agents/skills/ac-*` and `~/.claude/skills/ac-*`. The installer adds one
managed context block to personal Codex and Claude instructions, preserving
surrounding text. For Codex it uses a nonempty `AGENTS.override.md` when present,
otherwise `AGENTS.md`. Cursor User Rules require the manual paste described in
the README. Native discovery depends on the host loading personal instructions;
the explicit `agents-control context` request works as a fallback.

Updates check ownership before replacing generated code and skills. Locally
edited skills and conflicting files stop the install with their path. Review
and move them aside before retrying. Symlinked personal instructions stay intact;
add the loader to their intended source manually.

To install from this checkout:

```sh
AGENTS_CONTROL_SOURCE="$PWD" sh install.sh
```

The installer also accepts `AGENTS_CONTROL_REF` for a branch or tag,
`AGENTS_CONTROL_HOME`, `AGENTS_CONTROL_USER_HOME`, `AGENTS_CONTROL_CODEX_HOME`
and `AGENTS_CONTROL_BIN_DIR` for isolated installation or testing.
These settings do not change the private project folder.

## Upgrade from an older layout

Reinstall, then run `agents-control init` in your project. The new release keeps
old private folders, registrations and team artifacts intact. It uses only
`docs-agents-private/` and does not load old routing configuration.

Move your old private Markdown files and feature folders into the new folder
after reviewing name conflicts. Keep the new private `AGENTS.md`; copy useful
personal instructions into it. For a nested layout, move the contents of the old
`docs/` folder. Old external notes under `~/.agents-control/repos/` remain intact.
Ask your agent to help with the move if needed.

The installer retires its old unedited personal `agents-control` setup skill.
The setup skill is now `ac-init`. Edited old skills are preserved and reported.
This release does not remove existing repository team files. Review any removal
separately. Moving a tracked document cannot remove its earlier Git history.

## Development

Run shell syntax checks and the behavior suite:

```sh
for file in install.sh bin/agents-control lib/context.sh lib/install.sh tests/test-install.sh; do
  sh -n "$file" || exit
done
./bin/agents-control doctor --skills-only
sh tests/test-install.sh
```

CI runs these checks on Linux and macOS. Tests use disposable repositories and
personal install directories, including linked worktrees and space-containing paths.
