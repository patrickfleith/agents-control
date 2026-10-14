#!/bin/sh
# End-to-end private setup and installer behavior in disposable directories.
set -eu
SRC=$(cd "$(dirname "$0")/.." && pwd -P)
WORK=$(mktemp -d)
WORK=$(cd "$WORK" && pwd -P)
trap 'rm -rf "$WORK"' EXIT HUP INT TERM
export AGENTS_CONTROL_SOURCE=$SRC
export AGENTS_CONTROL_USER_HOME=$WORK/user
export AGENTS_CONTROL_HOME=$WORK/state
export AGENTS_CONTROL_CODEX_HOME=$WORK/user/.codex
export AGENTS_CONTROL_BIN_DIR=$WORK/user/bin
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.invalid
export GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.invalid
# Host-level ignores must not change the expected Git behavior.
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.excludesFile GIT_CONFIG_VALUE_0=/dev/null
PASS=0
fatal() { printf 'FAIL: %s\n' "$*" >&2; cat "$WORK/last.log" >&2; exit 1; }
run() { "$@" > "$WORK/last.log" 2>&1 || fatal "command failed: $*"; }
reject() { if "$@" > "$WORK/last.log" 2>&1; then fatal "command unexpectedly succeeded: $*"; fi; }
has() { grep -Fq "$2" "$1" || fatal "missing text in $1: $2"; }
absent() { [ ! -e "$1" ] && [ ! -L "$1" ] || fatal "unexpected path: $1"; }
same() { cmp -s "$1" "$2" || fatal "files differ: $1 $2"; }
ok() { PASS=$((PASS+1)); printf 'ok %s - %s\n' "$PASS" "$*"; }
new_repo() { REPO=$WORK/$1; mkdir -p "$REPO"; cd "$REPO"; git init -q; }

mkdir -p "$AGENTS_CONTROL_CODEX_HOME" "$WORK/user/.claude" "$WORK/state/repos/keep"
printf 'my global instructions without LF' > "$AGENTS_CONTROL_CODEX_HOME/AGENTS.md"
printf 'my Claude instructions\n' > "$WORK/user/.claude/CLAUDE.md"
printf 'old private data\n' > "$WORK/state/repos/keep/note"
run sh "$SRC/install.sh"
AC=$WORK/user/bin/agents-control
run "$AC" version
has "$AGENTS_CONTROL_CODEX_HOME/AGENTS.md" 'my global instructions without LF'
has "$WORK/user/.claude/CLAUDE.md" 'my Claude instructions'
has "$WORK/state/repos/keep/note" 'old private data'
for skill in ac-init ac-log ac-decide ac-glossary ac-write-manual ac-commit ac-unslop; do
  has "$WORK/user/.agents/skills/$skill/SKILL.md" "name: $skill"
  has "$WORK/user/.claude/skills/$skill/SKILL.md" "name: $skill"
done
absent "$WORK/user/.agents/skills/log"
absent "$WORK/user/.agents/skills/agents-control"
[ -f "$WORK/user/.agents/skills/ac-write-manual/assets/SUM.md" ] || fatal 'missing manual asset'
run "$AC" doctor --skills-only --strict
cp "$AGENTS_CONTROL_CODEX_HOME/AGENTS.md" "$WORK/global.before"
cp "$AGENTS_CONTROL_HOME/install.tsv" "$WORK/record.before"
run sh "$SRC/install.sh"
same "$AGENTS_CONTROL_CODEX_HOME/AGENTS.md" "$WORK/global.before"
same "$AGENTS_CONTROL_HOME/install.tsv" "$WORK/record.before"
# Claude instructions may contain only the generated block, with no preamble.
# Also exercise removal of the former owned setup name.
. "$SRC/lib/context.sh"
. "$SRC/lib/install.sh"
ac_block "$WORK/user/.claude/CLAUDE.md" > "$WORK/block-only"
cp "$WORK/block-only" "$WORK/user/.claude/CLAUDE.md"
mkdir "$WORK/user/.agents/skills/agents-control"
printf 'old owned setup skill\n' > "$WORK/user/.agents/skills/agents-control/SKILL.md"
printf '%s\tD\t%s\n' "$WORK/user/.agents/skills/agents-control" "$(ac_fingerprint "$WORK/user/.agents/skills/agents-control" D)" >> "$AGENTS_CONTROL_HOME/install.tsv"
run sh "$SRC/install.sh"
same "$WORK/block-only" "$WORK/user/.claude/CLAUDE.md"
absent "$WORK/user/.agents/skills/agents-control"
ok 'install and update keep personal guidance, private data and all six ac- workflows'

new_repo 'project with spaces'
printf 'team guidance\n' > AGENTS.md
printf 'team Claude guidance\n' > CLAUDE.md
printf 'team readme\n' > README.md
printf 'team ignore\n' > .gitignore
mkdir -p .agents/skills/log .claude/skills/log
printf 'team skill\n' > .agents/skills/log/SKILL.md
printf 'team adapter\n' > .claude/skills/log/SKILL.md
git add -A
git commit -qm initial
printf 'unrelated exclusion without LF' >> .git/info/exclude
cp .git/info/exclude "$WORK/exclude.before"
git status --porcelain > "$WORK/status.before"
run "$AC" init
git status --porcelain > "$WORK/status.after"
same "$WORK/status.before" "$WORK/status.after"
git diff --exit-code || fatal 'project files changed'
absent .agents-control
for doc in AGENTS PRD STACK ROADMAP DECISIONS TASKS CHANGELOG; do
  [ -f "docs-agents-private/$doc.md" ] || fatal "missing $doc"
done
absent docs-agents-private/GLOSSARY.md
has .git/info/exclude '/docs-agents-private/'
has .git/info/exclude 'unrelated exclusion without LF'
printf 'personal task\n' >> docs-agents-private/TASKS.md
cp docs-agents-private/TASKS.md "$WORK/tasks.before"
cp .git/info/exclude "$WORK/exclude.after"
run "$AC" init
same docs-agents-private/TASKS.md "$WORK/tasks.before"
same .git/info/exclude "$WORK/exclude.after"
run "$AC" doctor
mkdir subdir
cd subdir
[ "$("$AC" resolve TASKS)" = "$REPO/docs-agents-private/TASKS.md" ] || fatal 'wrong path from subdirectory'
"$AC" resolve TASKS --read > "$WORK/task-read"
has "$WORK/task-read" 'personal task'
[ "$("$AC" resolve GLOSSARY --path)" = "$REPO/docs-agents-private/GLOSSARY.md" ] || fatal 'wrong optional path'
absent "$REPO/docs-agents-private/GLOSSARY.md"
[ "$("$AC" resolve features/retry/PLAN)" = "$REPO/docs-agents-private/features/retry/PLAN.md" ] || fatal 'wrong feature path'
"$AC" context > "$WORK/context"
has "$WORK/context" "$REPO/docs-agents-private"
ok 'setup is local, excluded, idempotent and readable from subdirectories'

cd "$REPO"
printf 'code change\n' > public.txt
git add -A
run "$AC" guard-index
git ls-files > "$WORK/staged"
if grep -Fq docs-agents-private "$WORK/staged"; then fatal 'private docs staged normally'; fi
git add -f docs-agents-private/TASKS.md
git ls-files --stage > "$WORK/index.before"
reject "$AC" guard-index
reject "$AC" doctor
git ls-files --stage > "$WORK/index.after"
same "$WORK/index.before" "$WORK/index.after"
git commit -qm 'forced tracking for regression'
reject "$AC" init
git rm --cached -q docs-agents-private/TASKS.md
run "$AC" guard-index
ok 'guard catches forced staging and tracked notes, preserves index, and allows tracking removal'

# A moved checkout needs no registry or reattachment.
cd "$WORK"
mv 'project with spaces' 'moved project'
cd 'moved project'
"$AC" context > "$WORK/moved-context"
has "$WORK/moved-context" "$WORK/moved project/docs-agents-private"
run "$AC" doctor
ok 'moving a checkout keeps context available without registration'

new_repo worktrees
git commit --allow-empty -qm initial
git worktree add -qb other "$WORK/other tree"
run "$AC" init
first=$("$AC" resolve TASKS)
cd "$WORK/other tree"
run "$AC" init
second=$("$AC" resolve TASKS)
[ "$first" != "$second" ] || fatal 'worktrees share notes'
printf 'other note\n' >> "$second"
if grep -Fq 'other note' "$first"; then fatal 'worktree notes mixed'; fi
git add -f docs-agents-private/TASKS.md
cd "$REPO"
reject "$AC" init
cd "$WORK/other tree"
git rm --cached -q docs-agents-private/TASKS.md
run "$AC" init
ok 'linked worktrees keep separate notes and protect tracked files before adding common exclusions'

new_repo unconfigured
"$AC" context > "$WORK/empty"
[ ! -s "$WORK/empty" ] || fatal 'context leaked into an unconfigured checkout'
reject "$AC" resolve TASKS
reject "$AC" doctor
for option in --profile=private --profile=team --private-dir=custom --adopt; do reject "$AC" init "$option"; done
for action in share migrate adapters update recover; do reject "$AC" "$action"; done
reject "$AC" resolve features/../../PLAN
reject "$AC" resolve TASKS --scope=shared
cd "$WORK"
"$AC" context > "$WORK/nonrepo"
[ ! -s "$WORK/nonrepo" ] || fatal 'nonrepository context was not empty'
ok 'unconfigured context is empty and removed choices fail clearly'

new_repo tracked
mkdir docs-agents-private
printf 'team-owned file\n' > docs-agents-private/TASKS.md
git add -A
git commit -qm initial
cp .git/info/exclude "$WORK/tracked-exclude.before"
reject "$AC" init
same .git/info/exclude "$WORK/tracked-exclude.before"
has docs-agents-private/TASKS.md 'team-owned file'
absent docs-agents-private/AGENTS.md
ok 'setup refuses a tracked private-folder name before changing anything'

new_repo symlinks
mkdir "$WORK/outside"
ln -s "$WORK/outside" docs-agents-private
reject "$AC" init
reject "$AC" context
absent "$WORK/outside/AGENTS.md"
rm docs-agents-private
mkdir docs-agents-private
ln -s "$WORK/outside/task" docs-agents-private/TASKS.md
reject "$AC" init
absent docs-agents-private/AGENTS.md
rm docs-agents-private/TASKS.md
run "$AC" init
ln -s "$WORK/outside" docs-agents-private/features
reject "$AC" resolve features/retry/PLAN
rm .git/info/exclude
ln -s "$WORK/outside/exclude" .git/info/exclude
reject "$AC" init
absent "$WORK/outside/exclude"
ok 'symlink folders, documents, feature paths and exclusion files cannot redirect writes'

new_repo interrupted
run "$AC" init
rm docs-agents-private/AGENTS.md docs-agents-private/STACK.md
printf 'surviving private task\n' >> docs-agents-private/TASKS.md
run "$AC" init
has docs-agents-private/TASKS.md 'surviving private task'
run "$AC" doctor
printf '\n!/docs-agents-private/\n' >> .git/info/exclude
reject "$AC" doctor
run "$AC" init
run "$AC" doctor
ok 'rerunning init completes partial setup and repairs a removed exclusion'

printf 'user edit\n' >> "$WORK/user/.agents/skills/ac-log/SKILL.md"
cp "$WORK/user/.agents/skills/ac-log/SKILL.md" "$WORK/edited.before"
cp "$WORK/state/install.tsv" "$WORK/owned.before"
reject sh "$SRC/install.sh"
same "$WORK/user/.agents/skills/ac-log/SKILL.md" "$WORK/edited.before"
same "$WORK/state/install.tsv" "$WORK/owned.before"
cp "$SRC/skills/ac-log/SKILL.md" "$WORK/user/.agents/skills/ac-log/SKILL.md"
printf '\nmy tail without LF' >> "$AGENTS_CONTROL_CODEX_HOME/AGENTS.md"
cp "$AGENTS_CONTROL_CODEX_HOME/AGENTS.md" "$WORK/tail.before"
run sh "$SRC/install.sh"
same "$AGENTS_CONTROL_CODEX_HOME/AGENTS.md" "$WORK/tail.before"
mkdir -p "$WORK/user/.agents/skills/ac-init/assets"
printf 'local resource\n' > "$WORK/user/.agents/skills/ac-init/assets/note"
reject sh "$SRC/install.sh"
has "$WORK/user/.agents/skills/ac-init/assets/note" 'local resource'
ok 'installer refuses edited skills and resources before updates and preserves guidance bytes'

# Existing repository team artifacts and old private data are not migration targets.
new_repo legacy
mkdir -p docs-agents-local .agents-control
printf 'old private note\n' > docs-agents-local/TASKS.md
printf 'team configuration\n' > .agents-control/team.conf
cp docs-agents-local/TASKS.md "$WORK/legacy.before"
cp .agents-control/team.conf "$WORK/team.before"
run "$AC" init
same docs-agents-local/TASKS.md "$WORK/legacy.before"
same .agents-control/team.conf "$WORK/team.before"
"$AC" context > "$WORK/legacy.context"
if grep -Fq 'old private note' "$WORK/legacy.context"; then fatal 'legacy private data loaded automatically'; fi
ok 'legacy files are preserved and never selected through hidden configuration'
printf '\n%s behavior checks passed\n' "$PASS"
