#!/bin/sh
# Fault injection against real setup/installer operations in isolated workspaces.
set -eu
SRC=$(cd "$(dirname "$0")/.." && pwd -P)
WORK=$(mktemp -d)
WORK=$(cd "$WORK" && pwd -P)
trap 'rm -rf "$WORK"' EXIT HUP INT TERM
AC=$SRC/bin/agents-control
export AGENTS_CONTROL_HOME=$WORK/state
export AGENTS_CONTROL_SOURCE=$SRC
export AGENTS_CONTROL_USER_HOME=$WORK/user
export AGENTS_CONTROL_CODEX_HOME=$WORK/user/.codex
export AGENTS_CONTROL_BIN_DIR=$WORK/user/bin
fatal() { printf 'FAIL: %s\n' "$*" >&2; tail -n 25 "$WORK/last.log" >&2; exit 1; }
run() { "$@" > "$WORK/last.log" 2>&1 || fatal "command failed: $*"; }
reject() { if "$@" > "$WORK/last.log" 2>&1; then fatal "command unexpectedly succeeded: $*"; fi; }
token() { awk '/^Precondition token:/ {print $3}' "$WORK/last.log"; }
same() { cmp -s "$1" "$2" || fatal "files differ: $1 $2"; }

mkdir "$WORK/project"
cd "$WORK/project"
git init -q
run "$AC" init
private_prd=$("$AC" resolve PRD --path)
cp "$private_prd" "$WORK/private.before"
git status --porcelain > "$WORK/tree.before"
run "$AC" migrate --profile=team
expect=$(token)
run "$AC" migrate --profile=team --apply --expect="$expect"
common=$(git rev-parse --git-common-dir)
common=$(cd "$common" && pwd -P)
operation_id=$(printf '%s' "$common" | cksum | awk '{print $1 "-" $2}')
journal=$AGENTS_CONTROL_HOME/operations/$operation_id/current
setup_count=$(wc -l < "$journal/items" | tr -d ' ')
run "$AC" recover --restore
boundary=1
while [ "$boundary" -le "$setup_count" ]; do
  run "$AC" migrate --profile=team
  expect=$(token)
  reject env AGENTS_CONTROL_TEST_FAIL_AFTER="$boundary" "$AC" migrate --profile=team --apply --expect="$expect"
  run "$AC" recover --restore
  same "$private_prd" "$WORK/private.before"
  git status --porcelain > "$WORK/tree.after"
  same "$WORK/tree.before" "$WORK/tree.after"
  [ ! -e .agents-control/team.conf ] || fatal "team config survived rollback"
  if [ $((boundary % 5)) = 0 ]; then printf 'setup checkpoints: %s/%s\n' "$boundary" "$setup_count"; fi
  boundary=$((boundary+1))
done
printf 'ok - all %s generated setup checkpoints restore the original tree and private data\n' "$setup_count"

run "$AC" migrate --profile=team
expect=$(token)
run "$AC" migrate --profile=team --apply --expect="$expect"
# Kill the writer after it moves the old directory, before publishing the new link.
reject env AGENTS_CONTROL_TEST_KILL_AFTER_REMOVE=1 "$AC" adapters --mode=symlink
[ ! -e .claude/skills/commit ] || fatal "kill did not reach directory replacement"
stage=$(awk -F '\t' 'NR==1 {print $2}' "$journal/staging")
[ -d "$stage/previous" ] || fatal "killed writer's original directory was not retained"
printf 'newer user edit\n' > "$stage/unrelated"
reject "$AC" recover --resume
[ -f "$stage/unrelated" ] || fatal "recovery deleted a newer staging edit"
rm "$stage/unrelated"
run "$AC" recover --resume
[ -L .claude/skills/commit ] || fatal "recovery did not publish the intended adapter"
[ ! -e "$stage" ] || fatal "verified staging files were left in the checkout"
run "$AC" doctor --strict
printf 'ok - killed directory writer recovers, preserves newer edits, and cleans verified staging\n'

global_root=$WORK/global-checkpoints
mkdir -p "$global_root/user/.codex" "$global_root/state/repos/keep"
printf 'original guidance without LF' > "$global_root/user/.codex/AGENTS.md"
cp "$global_root/user/.codex/AGENTS.md" "$WORK/guidance.before"
printf 'private data sentinel\n' > "$global_root/state/repos/keep/notes"
cp "$global_root/state/repos/keep/notes" "$WORK/data.before"
installer() {
  env AGENTS_CONTROL_HOME="$global_root/state" AGENTS_CONTROL_USER_HOME="$global_root/user" \
    AGENTS_CONTROL_CODEX_HOME="$global_root/user/.codex" AGENTS_CONTROL_BIN_DIR="$global_root/user/bin" \
    sh "$SRC/install.sh" "$@"
}
run installer --adopt
expect=$(token)
run installer --adopt --apply --expect="$expect"
install_count=$(wc -l < "$global_root/state/operations/install/current/items" | tr -d ' ')
run installer --restore
boundary=1
while [ "$boundary" -le "$install_count" ]; do
  run installer --adopt
  expect=$(token)
  reject env AGENTS_CONTROL_TEST_FAIL_AFTER="$boundary" AGENTS_CONTROL_HOME="$global_root/state" \
    AGENTS_CONTROL_USER_HOME="$global_root/user" AGENTS_CONTROL_CODEX_HOME="$global_root/user/.codex" \
    AGENTS_CONTROL_BIN_DIR="$global_root/user/bin" sh "$SRC/install.sh" --adopt --apply --expect="$expect"
  run installer --restore
  same "$global_root/user/.codex/AGENTS.md" "$WORK/guidance.before"
  same "$global_root/state/repos/keep/notes" "$WORK/data.before"
  [ ! -e "$global_root/state/toolkit" ] || fatal "toolkit survived installer rollback"
  [ ! -e "$global_root/state/install.tsv" ] || fatal "ownership committed before rollback"
  if [ $((boundary % 5)) = 0 ]; then printf 'installer checkpoints: %s/%s\n' "$boundary" "$install_count"; fi
  boundary=$((boundary+1))
done
printf 'ok - all %s installer checkpoints restore guidance and preserve personal data\n' "$install_count"
printf '\n3 recovery groups passed, covering %s setup and %s installer checkpoints and a killed writer\n' "$setup_count" "$install_count"
