# Plan for private use, sharing, and team adoption

Status: implemented; local automated verification passed on 2026-10-14. Native
discovery remains partly unverified. Live Claude Code and Cursor checks remain
pending at the user's request.
Requirements: [IMPORTANT.md](IMPORTANT.md).

## The collaboration model

Use two scopes: private working material and shared project knowledge. The three
installation modes are presets over those scopes. They reuse the same commands,
path resolver, skills, and file operations.

Humans choose priorities, approve project decisions, and review changes. Agents
read the relevant context, implement bounded tasks, run appropriate checks, and
prepare reviewable changes. Shared docs, instructions, configuration, and skills
change through the team's normal Git review process.

For substantial work, use one owner and one branch or worktree per task. Define
the outcome and acceptance checks before implementation. Keep temporary planning
private by default. Share decisions and working agreements that teammates need.
Keep small tasks lightweight. A feature document is useful only when the work
needs a plan that survives across sessions.

## Chosen defaults

- Keep private material outside the checkout by default. Use a workspace under
  `~/.agents-control/repos/<id>/`, registered to an exact Git worktree root.
- Keep shared docs in `docs-agents-shared/`. Allow a custom repo-relative path.
- Keep one maintained copy of shared content. Sharing moves the selected content
  into the shared folder. Later edits happen there.
- Preserve existing project files and team guidance. Create a root `README.md`
  only in team setup and only when it is missing.
- Keep personal tasks private. Offer a separate shared `TASKS.md` at team setup.
- Keep feature `FRD.md` and `PLAN.md` private by default, including in team mode.
- Keep optional docs on demand. A shared default does not create a document.
- Preserve the personal setup skill's invocation and installation support.
- Use copies for new shared skill adapters by default so clones need no symlink
  support. Retain `--mode=symlink|copy` and existing recorded adapter choices.

External private storage replaces the earlier recommendation to put everything
under `.agents-control/private/` inside the checkout. It avoids ordinary Git
staging and linked-worktree exclusion conflicts. Configured private locations
inside the checkout remain supported with the checks below.

## Modes and configuration authority

| Mode | New-entry default | Shared artifacts created by setup |
| --- | --- | --- |
| Private | Private | None |
| Selected | Private, except whole doc types explicitly routed to shared | Selected Markdown docs only |
| Team | Approved shared doc types; other material private | Shared docs, instructions, workflow skills, adapters, and portable configuration |

The repository's adoption and an individual's choice are separate:

- A tracked `.agents-control/team.conf` means the repository has team adoption.
  It owns shared paths, shared doc defaults, and the shared adapter choice.
- A private `repo.conf` records the developer's worktree, personal mode, private
  location, and selected-sharing choices. It never goes into the shared config.
- A fresh team clone with no personal registration uses shared configuration.
  It neither creates a personal workspace nor guesses another developer's paths.
- An individual's switch to private or selected mode changes personal routing.
  It preserves team configuration, docs, instructions, skills, and adapters.
- Team withdrawal is a deliberate project change reviewed through Git. It is
  separate from an individual's mode change.

When team configuration exists, every mode reuses its shared directory. A local
choice cannot redirect the team's shared files. Local mode controls new personal
entries; an explicit request to edit an existing shared entry still edits that
entry in place. Renaming the team's shared folder is an explicit project change
that updates the portable configuration and shared references together.

In team mode, setup choices for `IDEAS.md`, `CONCERNS.md`, `QUESTIONS.md`, and
the optional team task list are team defaults. Private and selected setup choices
are personal. Explicit requests can choose a scope without changing any default.
Personal preferences supplement project guidance. Report conflicting instructions.

## Layout and a small configuration format

The shared team layout is:

    AGENTS.md                         existing guidance + managed shared manifest
    CLAUDE.md                         compatible shared import where needed
    docs-agents-shared/                maintained shared Markdown
    .agents/skills/                    six team workflow skills and their assets
    .claude/skills/                    adapters for team skills
    .agents-control/team.conf          portable team choices
    .agents-control/context.sh         portable context/path resolver
    .agents-control/managed.tsv        ownership of generated shared artifacts

The default personal layout is:

    ~/.agents-control/toolkit/         installed toolkit code
    ~/.agents-control/repos/<id>/
        repo.conf                     worktree registration and personal choices
        AGENTS.md                     personal instructions and private manifest
        docs/                         personal Markdown
        state/                        ownership, retired private paths, recovery

Keep installed code and personal data in separate directories. Updating the
toolkit must never replace the parent containing registrations or private docs.
Preserve the existing launcher and setup-skill entry points during conversion.

Use a versioned, line-oriented `key=value` format. Parse a whitelist of keys,
split at the first equals sign, and preserve values containing spaces. Never
source or evaluate a configuration file. Reject duplicate keys, invalid values,
unknown schema versions, and missing required configuration before writing.

Shared configuration needs only the schema version, shared directory, shared doc
types, and adapter mode. Presence of the file expresses team adoption. Toolkit
versions belong in the installed version file; generated-file fingerprints belong
in the ownership record.

Personal configuration records the physical worktree root, mode, private
directory, and selected-sharing directory and doc choices where relevant.
Use a path digest and length as the registration ID, check the stored root for
collisions, and match the exact worktree path. Repository
names and remote URLs are insufficient identifiers. Report moved checkouts and
allow explicit reattachment. Give different worktrees separate private workspaces
by default.

Validate all configured and owned paths. Support spaces. Reject control
characters, path traversal, Git metadata destinations, overlapping private and
shared storage, and symlink escapes. Shared paths must stay inside the checkout.
Configuration errors stop the operation; they never redirect a write elsewhere.

## Document defaults

| Document | Team destination | Creation |
| --- | --- | --- |
| Root README.md | Shared project entry point | Only if missing |
| PRD.md, STACK.md, ROADMAP.md, DECISIONS.md, CHANGELOG.md | Shared | Core set at setup |
| Personal TASKS.md | Private | At personal setup |
| Team TASKS.md | Shared | Offered at setup; create when first used |
| SUM.md, GLOSSARY.md, EVALUATIONS.md, TESTS.md, UXUI.md, DEPLOYMENT.md | Shared | On demand |
| IDEAS.md, CONCERNS.md, QUESTIONS.md | Ask at setup; private default | On demand |
| features/<slug>/FRD.md and PLAN.md | Private | On demand |

Private and selected setup create the current six-doc core in personal storage.
Selected sharing publishes only explicit selections. Team setup never publishes an
existing private document merely because its type has a shared default.

## Discovery and portable skills

Use a small personal instruction block that asks the agent to run
`agents-control context` once when starting repository work. The command returns
additional guidance and document locations only for the registered worktree.
It is read-only and does nothing for an unconfigured repository.

Use the tool's supported personal instruction location. Preserve its existing
content and settings. For Cursor, provide the block for User Rules if there is
no supported installer API. Do not add hooks, watchers, or tool launch wrappers.
An explicit request to load personal context is the fallback when a host does
not load its personal instructions. Setup must report which path was verified.

Install personal toolkit workflows with an `ac-` prefix, such as `ac-log` and
`ac-decide`, to reduce collisions with repository skills. Generate those names
from the same skill sources. Their instructions check worktree registration
before use. Team skills keep the existing six names. Preserve unrelated personal
skills; any remaining same-name conflict requires an explicit resolution.

Ship one resolver source, `lib/context.sh`. The global CLI uses it. Team setup
also installs it as `.agents-control/context.sh`, so checked-in skills can call
it with POSIX shell without a global CLI, personal state, or toolkit checkout.
Prefer the repository's installed resolver for its shared config. Version the
config contract and check compatibility.

Package required templates inside the skill that uses them. In particular,
`write-manual` must carry its SUM template as a relative asset. All shared
skill resources and adapters must resolve after cloning. Shared adapters must
never point outside the checkout or into personal storage.

Shared manifests contain shared locations only. Private manifests come from the
personal context command. Local private files are available only where that
workspace is accessible and permitted by the host. Remote sessions use shared
context unless personal context is explicitly provided there.

Verify actual discovery separately from file placement. Deferred live checks do
not establish host behavior:

| Tool | Verification |
| --- | --- |
| Codex | Add a managed block to the effective instruction file under CODEX_HOME, usually ~/.codex/AGENTS.md or its existing override. Preserve existing guidance. Never use a repository AGENTS.override.md as an additive private file. Test same-name skills and subdirectory launches. |
| Claude Code | Add a managed block to ~/.claude/CLAUDE.md. Preserve its existing guidance and avoid a repository CLAUDE.local.md loader that changes native AGENTS.md discovery. Test projects with only AGENTS.md and projects with existing CLAUDE.md. |
| Cursor | Verify User Rules loading, the private context request, existing project rules, and personal versus remote skill availability. |

Reference documentation checked on 2026-10-13:
[Codex instructions](https://learn.chatgpt.com/docs/agent-configuration/agents-md),
[Codex skills](https://learn.chatgpt.com/docs/build-skills),
[Claude memory](https://code.claude.com/docs/en/memory),
[Cursor rules](https://cursor.com/docs/rules),
[Cursor skills](https://cursor.com/docs/skills).
Record tested host versions and session evidence. File-placement tests alone do
not establish discovery or instruction precedence.

## Writing and sharing

The resolver distinguishes reading from writing:

- For a new entry, resolve the doc type, explicit scope if supplied, and the
  applicable mode default. Return one concrete destination and its visibility.
- For an existing entry, list relevant private and shared documents and locate
  the requested identifier or heading. Edit the containing file. Ask when
  multiple matches exist. Never recreate a moved entry in its former location.
- Personal and team task lists are distinct. Use the stated owner; ask when
  both destinations exist and ownership is unclear.
- A request for unavailable private storage stops with setup guidance. A fresh
  clone must not write personal material into shared docs as a fallback.

Whole-doc sharing can change that doc type's selected-mode default to shared.
Section sharing leaves the default private unless the user chooses otherwise.
Search the relevant files for existing entries; keep no section-routing database.
Duplicate identifiers require explicit disambiguation. Do not renumber entries
or rewrite references silently.

Sharing supports whole documents and exact ATX Markdown heading selections,
including nested headings. Define a section as its heading through the next
heading of the same or higher level. Ignore heading-like text inside backtick or
tilde fenced code and indented code. Reject missing, duplicate, overlapping, or
unsupported selections.

Preview the shared addition and private removal together. Destination conflicts
stop the operation. An explicit merge requires a reviewed diff through the same
apply mechanism. Preserve unrelated sections byte for byte.

Check relative links, reference definitions, footnotes, anchors, and identifiers
affected by a move. Include dependencies only when explicitly selected. Reject
unresolved dependencies and links into personal storage. Complex restructuring
requires a separately reviewed edit before retrying the move.

The private source may contain a link to its shared destination. Shared content
must have no link back to private storage. After sharing, the shared file is the
maintained copy. There are no publication snapshots or synchronization jobs.

## Ownership, updates, and Git

Track ownership only for generated artifacts: resolver copies, toolkit skills,
adapters, and marked instruction blocks. Documents and surrounding team guidance
remain user content. Explicitly selected content moves may edit those documents.
Automatic updates never replace them.

Record paths, artifact kinds, and fingerprints of the last generated bytes.
Cover every file in a generated skill directory, including assets and scripts.
For symlinks, record the target. For instruction blocks, record only the managed
body and preserve surrounding bytes. Portable records describe shared artifacts;
personal records stay outside Git.

Replace or remove a generated artifact only if ownership and its current
fingerprint match. Otherwise show the conflict and preserve it. A legacy name
list is insufficient proof of ownership. Adoption or replacement of uncertain
legacy artifacts requires an explicit preview. Remove the blanket overwrite
behavior from adapters, global installation, and update --force.

External private storage needs no Git exclusions. For configured private storage
inside the checkout, check both the index and HEAD before creating files. Manage
only a marked block of escaped, root-anchored private paths in Git's exclude file.
Preserve all unrelated entries.

Linked worktrees share info/exclude. Inspect all linked worktrees, including
unregistered ones, for tracking and team configuration. Reject private path
choices that would hide shared material in another worktree. Serialize exclusion
updates and preserve all registered entries. Recommend external storage when
choices conflict; do not introduce worktree-specific Git configuration.

The commit skill checks the complete index before each commit, including content
staged before invocation. Block private blobs at current and retired private
paths. Allow deliberate staged deletions that remove tracking. On a conflict,
stop with a diagnostic and preserve the index. Never silently unstage user work.
No share or migration operation automatically stages, commits, or pushes.

## One preview and recovery mechanism

Sharing, migration, path changes, and explicit ownership adoption reuse one
operation mechanism. Preview reads existing state and prints the proposed diff,
file moves, generated changes, exclusions, tracking effects, and apply command.
Preview creates temporary scratch files outside the checkout and cleans them up.
It changes no persistent project files, private data, configuration, or Git state.

Apply requires the preview's precondition token. Recheck relevant source and
destination bytes, configuration, ownership, and index entries under a repository
operation lock. Reject a stale preview. Permit only one toolkit mutation at a
time across linked worktrees.

Use the same operation arguments for preview and apply. The command previews by
default; the printed apply command adds `--apply --expect=<token>`. No saved
preview database is needed.

Before changing files, save affected originals and intended results in the
external private recovery area. Keep temporary private content outside the
checkout. Write destinations through temporary files, remove selected sources
only after verifying destination bytes, and checkpoint each completed operation.
Advance configuration and ownership only after all required changes succeed.

Retain the last completed recovery record. An interrupted operation blocks new
mutations until resumed or restored. Recovery compares current files with the
recorded original and intended bytes; newer user edits require an explicit
resolution. Never restore a backup over those edits.

Recovery must preserve unrelated changes in files containing managed blocks,
unrelated Git exclusions, and unrelated staged work. Report required tracking
changes and exact paths to stage. Keep retired private paths in local bookkeeping
until tracking has been removed.

## Migration behavior

Support legacy-to-private, legacy-to-selected, legacy-to-team, every pair of new
modes, and same-mode path or destination changes.

Treat existing docs as unclassified until the user chooses their destination.
Known legacy adapter settings can be imported, but filenames and skill names do
not establish ownership or sharing permission. Preserve the old layout until an
explicit migration applies.

A personal mode change preserves the team's shared setup. It neither removes
team documents nor creates private copies of their content. The developer can
keep new personal material in their workspace and continue reading shared docs.
Moving shared content back to private storage is a separate explicit project
change with the same preview and recovery rules.

Explain that exclusions affect staging, not access control. Previously shared
content remains in Git history and existing clones. Private also means local
working material; it does not promise confidentiality from the host agent.

## Implementation sequence

1. **Verify discovery.** Test the personal context block and skill names in the
   three supported tools, including existing instructions and remote limitations.
   Keep unverified host behavior pending when the user explicitly defers live checks.
2. **Build the common contract.** Add the data parser, worktree registration,
   resolver, portable helper distribution, and skill assets. Prove that a fresh
   team clone resolves shared docs without the global toolkit.
3. **Implement safe setup and updates.** Add `--profile=private|selected|team`;
   retain `--mode=symlink|copy` for adapters. A new unconfigured repo defaults to
   private; reruns retain their recorded profile. Team clones retain team
   configuration. Protect global code, personal data, team files, and edits.
4. **Route workflows.** Update setup, log, decide, glossary, write-manual, and
   commit. Generate correct manifests and template links. Add context and resolve
   commands, with visibility and ambiguity in their results.
5. **Add content operations.** Implement share, migrate, and recover through the
   common preview/apply mechanism. Cover whole docs, bounded sections, ownership
   adoption, tracking reports, individual withdrawal, and path changes.
6. **Validate and document.** Extend the existing shell fixtures and macOS/Linux
   CI. Update README, CLI help, setup guidance, and templates. Show exactly which
   files a team or selected-sharing setup should commit.

Keep POSIX shell, Git, and existing basic utilities. Use small helpers only where
they remove duplication or make responsibilities clearer. Add no runtime or test
framework unless a required operation cannot be implemented clearly with them.
Avoid background services, automatic watchers, per-section registries, and
automatic Git commits.

## Acceptance checks

- [x] All three modes, legacy migrations, pairwise transitions, same-mode changes,
  custom paths, subdirectory invocation, and reruns preserve content.
- [x] Two linked worktrees have separate external private workspaces. Conflicting
  in-checkout exclusions cannot hide shared material.
- [x] A fresh team clone can use shared skills and required assets with no global
  CLI, private configuration, personal instructions, or symlink support.
- [x] Selected shared docs remain ordinary Markdown readable without installation.
- [x] Automatic updates preserve unowned and edited files, whole skill resources,
  existing guidance, personal skills, and unrelated exclusions.
- [x] Sharing and migration preserve unselected bytes, reject ambiguous headings
  and identifiers, handle supported code fences, and detect reference conflicts.
- [x] Stale previews, every sharing write checkpoint, operation locks, and
  recovery after newer user edits preserve content in the behavior checks.
- [x] Inject failures at every generated setup and installer checkpoint, and
  kill a fixture writer during directory replacement. Recovery preserves newer
  edits and removes verified staging files.
- [x] Private material staged before commit invocation is blocked. Planned removal
  from tracking is allowed. Unrelated staged work remains intact.
- [x] Private data and registrations survive global toolkit updates.
- [x] Malformed configuration, unsupported versions, spaces in paths, symlink
  escapes, and missing private storage produce clear results without fallback writes.
- [ ] Real sessions verify personal and team discovery in each supported tool;
  documented local and remote limits match those checks.
- [x] Every requirement in IMPORTANT.md maps to an implementation step and a
  behavior check. Deferred live discovery remains visible in the status report.


## Implementation notes

The CLI and the clone helper share `lib/context.sh`. `lib/operations.sh` handles
ownership, previews, locking, writes, and recovery. The two AWK helpers select
bounded Markdown sections and replace literal path references. There is no new
runtime, watcher, synchronization service, or per-section database.

Unselected legacy docs remain readable as unclassified candidates after migration;
they require a chosen destination before editing. Doctor reports stale legacy
paths in preserved project guidance.

Code and personal data have separate installer ownership. Team config contains
no private paths. Registration IDs use the physical worktree path's checksum and
length, with an exact-root collision check. Config is data and is never sourced.
Shared docs cannot use tool metadata folders. Paths may contain spaces; symlink
ancestors and leaves are rejected for document access. Existing directory paths
use their physical spelling. Case-only scope overlaps are rejected. Git index
queries use the worktree root, and private exclusions use the physical common
Git directory even when commands run from a subdirectory.

Shared-folder changes update the generated manifest, portable configuration,
and literal README references. Additional user-owned references remain subject
to review. Change a folder and move individual documents in separate previews;
old and new storage roots cannot contain one another. Moving an in-checkout
private root stops if it contains extra material outside docs and AGENTS.md.
That material needs an explicit move first.

Generated ownership and configuration writes run after content writes. A pending
marker in the common Git directory also blocks other state roots and linked
worktrees after an interruption. Recovery keeps user edits outside managed blocks
and refuses changed affected content. Directory replacement retains the original
in a recorded staging directory until publication. Recovery validates staging
contents before cleanup. A no-op rerun retains the previous recovery record. An
unclean process kill may require checking and removing its stale lock before
recovery.

## Discovery evidence and remaining live work

On 2026-10-14, an isolated Codex CLI 0.162.1 session loaded a repository AGENTS.md
marker and followed its instruction to read an additional context file. This
proves that fixture's repository discovery and additional-file access. It does
not prove the final personal loader, same-name skill selection, subdirectory
precedence, or remote behavior.

Claude Code 2.1.263 reported expired OAuth credentials. Cursor desktop 3.18.25
had no authenticated agent session. The user explicitly chose to leave these
live checks pending. No login restoration or personal installation was performed.
The automated installer fixtures verify file placement and preservation only.

Remaining live checks are the final personal loader and `ac-` skill selection in
Codex; AGENTS-only and existing-CLAUDE projects in Claude Code; User Rules,
project rules, and personal skill selection in Cursor; and the documented limits
in remote sessions. Run them after authentication is available.

## Requirement coverage

The 39 behavior groups live in `tests/test-install.sh`. The recovery matrix in
`tests/test-recovery.sh` covers all 24 generated setup checkpoints, all 21 installer
checkpoints, and a killed directory writer. These checks map the requirements in
IMPORTANT.md to the implementation:

Both suites passed locally on macOS on 2026-10-14. Shell and AWK syntax checks,
all seven skill validations, strict skill portability checks, and whitespace
checks also passed. CI runs both suites on macOS and Ubuntu; that matrix was not
executed as part of the local verification.

| Requirement | Implementation | Behavior checks |
| --- | --- | --- |
| Explicit profiles and recorded destinations | `init`, `repo.conf`, `team.conf`, resolver | Private, selected, team, direct transitions, subdirectory launches, reruns |
| Apply scope to docs, manifests, skills, and adapters | Personal loaders and `ac-` workflows; shared manifest and portable skills | Tracked-tree preservation, explicit selections, cloned team helper and assets |
| Scope-aware setup and writing workflows | Revised setup, log, decide, glossary, manual, and commit skills | Skill validation, resolver destinations, task owner ambiguity, index guard |
| Preserve local exclusions and avoid hiding team files | Owned escaped exclude block; index, HEAD, and linked-worktree checks | Glob paths, unrelated bytes, path retirement, linked-worktree conflict |
| Explain staging and confidentiality limits | Usage guide ownership and Git guidance | Indexed private blobs rejected; staged removals allowed; index unchanged |
| Preserve existing guidance, skills, and docs | Block ownership and full-directory fingerprints | Existing global/project guidance, unowned conflicts, edited adapters and assets |
| Local versus clone artifacts | External registrations; portable team helper and resources | Unregistered context is empty; clone needs no local state or global CLI |
| Legacy to every profile | Explicit `migrate --doc` choices and mode import | Legacy private, selected, team, archived symlink choice |
| Every profile transition | Personal routing separate from team adoption | Pairwise transitions preserve shared files and personal content |
| Choose docs or sections to move | `share`, `migrate --doc`, exact ATX selection | Whole-doc moves, selected routing, fenced sections, Unicode and CRLF bytes |
| Preserve content and resolve destination conflicts | Explicit merge; ambiguity and dependency checks | Duplicate IDs, full and shortcut references, remainder dependencies, private links |
| Update paths and related artifacts | Folder migration and generated setup | Custom roots, shared README links, manifests, private exclusions |
| Review changes and tracking before apply | Diff preview and precondition token | Preview has no persistent writes; stale input rejection; tracking diagnostics |
| Personal withdrawal preserves team use | Local profile changes leave team artifacts | Team-to-private and team-to-selected checks |
| Previously shared history remains | Usage guide migration and Git guidance | Commands preserve staging and do not rewrite Git history |
| Rerun and recover safely | Common lock, external journal, pending marker, checked recovery | Installer reruns, interruption checkpoints, newer edits, other state roots, lock ownership |
| Native personal and shared discovery | Installer loader placement and explicit fallback | Automated placement passes; authenticated live checks remain pending |
