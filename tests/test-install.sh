#!/bin/sh
# Isolated behavior tests; no personal HOME or CODEX_HOME changes.
set -eu
SRC=$(cd "$(dirname "$0")/.." && pwd -P)
WORK=$(mktemp -d)
WORK=$(cd "$WORK" && pwd -P)
trap 'rm -rf "$WORK"' EXIT HUP INT TERM
PASS=0
AC=$SRC/bin/agents-control
export AGENTS_CONTROL_HOME=$WORK/state
export AGENTS_CONTROL_USER_HOME=$WORK/user
export AGENTS_CONTROL_CODEX_HOME=$WORK/user/.codex
export AGENTS_CONTROL_BIN_DIR=$WORK/user/bin
export AGENTS_CONTROL_SOURCE=$SRC
ok() { PASS=$((PASS+1)); printf 'ok %s - %s\n' "$PASS" "$*"; }
fatal() { printf 'FAIL: %s\n' "$*" >&2; [ ! -f "$WORK/last.log" ] || tail -n 30 "$WORK/last.log" >&2; exit 1; }
run() { "$@" > "$WORK/last.log" 2>&1 || fatal "command failed: $*"; }
reject() { if "$@" > "$WORK/last.log" 2>&1; then fatal "command unexpectedly succeeded: $*"; fi; }
has() { grep -Fq -- "$2" "$1" || fatal "missing text $2 in $1"; }
absent() { [ ! -e "$1" ] && [ ! -L "$1" ] || fatal "unexpected path: $1"; }
same() { cmp -s "$1" "$2" || fatal "files differ: $1 $2"; }
new_repo() {
  REPO=$WORK/$1
  mkdir -p "$REPO"
  git -C "$REPO" init -q
  git -C "$REPO" config user.email test@example.invalid
  git -C "$REPO" config user.name Test
  git -C "$REPO" config commit.gpgsign false
  git -C "$REPO" config core.hooksPath /dev/null
  cd "$REPO"
}
preview_apply() {
  run "$@"
  token=$(awk '/^Precondition token:/ {print $3}' "$WORK/last.log")
  [ -n "$token" ] || fatal "preview token missing"
  run "$@" --apply --expect="$token"
}

mkdir -p "$AGENTS_CONTROL_CODEX_HOME"
printf 'existing global override\n' > "$AGENTS_CONTROL_CODEX_HOME/AGENTS.override.md"
run sh "$SRC/install.sh"
[ -x "$AGENTS_CONTROL_BIN_DIR/agents-control" ] || fatal "launcher missing"
[ -f "$AGENTS_CONTROL_USER_HOME/.agents/skills/ac-log/SKILL.md" ] || fatal "personal workflow missing"
has "$AGENTS_CONTROL_USER_HOME/.agents/skills/ac-log/SKILL.md" 'name: ac-log'
has "$AGENTS_CONTROL_CODEX_HOME/AGENTS.override.md" 'existing global override'
has "$AGENTS_CONTROL_CODEX_HOME/AGENTS.override.md" 'agents-control context'
absent "$AGENTS_CONTROL_CODEX_HOME/AGENTS.md"
ok "installer preserves effective personal guidance and installs namespaced skills"
mkdir -p "$AGENTS_CONTROL_HOME/repos/sentinel"
printf 'personal data\n' > "$AGENTS_CONTROL_HOME/repos/sentinel/notes"
run sh "$SRC/install.sh"
has "$AGENTS_CONTROL_HOME/repos/sentinel/notes" 'personal data'
[ "$(grep -c '^<!-- agents-control:start -->$' "$AGENTS_CONTROL_CODEX_HOME/AGENTS.override.md")" = 1 ] || fatal "duplicate global loader"
ok "installer reruns preserve data and avoid duplicate loader blocks"

legacy_global=$WORK/legacy-global
mkdir -p "$legacy_global/state/bin" "$legacy_global/state/repos/keep" "$legacy_global/user/.agents/skills/agents-control"
printf 'legacy launcher\n' > "$legacy_global/state/bin/agents-control"
printf 'unowned setup skill\n' > "$legacy_global/user/.agents/skills/agents-control/SKILL.md"
printf 'private data\n' > "$legacy_global/state/repos/keep/notes"
reject env AGENTS_CONTROL_HOME="$legacy_global/state" AGENTS_CONTROL_USER_HOME="$legacy_global/user" AGENTS_CONTROL_CODEX_HOME="$legacy_global/user/.codex" AGENTS_CONTROL_BIN_DIR="$legacy_global/user/bin" sh "$SRC/install.sh"
has "$legacy_global/state/bin/agents-control" 'legacy launcher'
preview_apply env AGENTS_CONTROL_HOME="$legacy_global/state" AGENTS_CONTROL_USER_HOME="$legacy_global/user" AGENTS_CONTROL_CODEX_HOME="$legacy_global/user/.codex" AGENTS_CONTROL_BIN_DIR="$legacy_global/user/bin" sh "$SRC/install.sh" --adopt
[ -L "$legacy_global/state/bin/agents-control" ] || fatal "legacy launcher entry point did not convert"
run "$legacy_global/state/bin/agents-control" version
has "$legacy_global/state/repos/keep/notes" 'private data'
ok "legacy global conflicts need an adoption preview and preserve the launcher entry point and data"

new_repo private
printf 'team instructions\n' > AGENTS.md
printf 'team Claude instructions\n' > CLAUDE.md
printf 'existing readme\n' > README.md
printf 'existing excludes\n' > .gitignore
mkdir -p .agents/skills/log
printf -- '---\nname: log\ndescription: An existing team workflow.\n---\ncustom skill\n' > .agents/skills/log/SKILL.md
git add -A
git commit -qm initial
git status --porcelain > "$WORK/status.before"
run "$AC" init
git status --porcelain > "$WORK/status.after"
same "$WORK/status.before" "$WORK/status.after"
has AGENTS.md 'team instructions'
has CLAUDE.md 'team Claude instructions'
absent .agents-control
private_tasks=$("$AC" resolve TASKS --path)
private_root=$(dirname "$(dirname "$private_tasks")")
for doc in PRD STACK ROADMAP DECISIONS TASKS CHANGELOG; do [ -f "$private_root/docs/$doc.md" ] || fatal "missing personal core $doc"; done
printf 'personal task sentinel\n' >> "$private_tasks"
run "$AC" init
has "$private_tasks" 'personal task sentinel'
"$AC" context > "$WORK/context"
has "$WORK/context" "$private_root/docs"
ok "private setup and reruns leave the tracked team tree unchanged"

mkdir -p sub/dir
cd sub/dir
[ "$("$AC" resolve TASKS --path)" = "$private_tasks" ] || fatal "subdirectory resolver drift"
run "$AC" guard-index
run "$AC" migrate --profile=selected
token=$(awk '/^Precondition token:/ {print $3}' "$WORK/last.log")
run "$AC" migrate --profile=selected --apply --expect="$token"
preview_apply "$AC" migrate --profile=private
cd "$REPO"
ok "subdirectory resolution uses the physical Git worktree"
reject "$AC" migrate --profile=selected --private-dir=docs-agents-shared
reject "$AC" migrate --shared-dir=../escape
ln -s "$WORK" bad-path
reject "$AC" migrate --shared-dir=bad-path/shared
rm bad-path
ok "overlaps, traversal, and symlink destinations are rejected"

ideas=$("$AC" resolve IDEAS --path)
cat > "$ideas" <<'DOC'
# Ideas

## Keep
personal secret

## Publish
shared explanation
### Detail
nested context
~~~
## Fake heading
~~~

## Tail
another secret
DOC
cat > "$WORK/expected-private" <<'DOC'
# Ideas

## Keep
personal secret

## Tail
another secret
DOC
cp "$ideas" "$WORK/ideas.before"
run "$AC" share "$ideas" --to=IDEAS --section=Publish
same "$ideas" "$WORK/ideas.before"
absent docs-agents-shared
token=$(awk '/^Precondition token:/ {print $3}' "$WORK/last.log")
printf 'newer edit\n' >> "$ideas"
reject "$AC" share "$ideas" --to=IDEAS --section=Publish --apply --expect="$token"
has "$ideas" 'newer edit'
absent docs-agents-shared
cp "$WORK/ideas.before" "$ideas"
preview_apply "$AC" share "$ideas" --to=IDEAS --section=Publish
same "$ideas" "$WORK/expected-private"
has docs-agents-shared/IDEAS.md 'shared explanation'
has docs-agents-shared/IDEAS.md 'nested context'
if grep -q 'personal secret\|another secret' docs-agents-shared/IDEAS.md; then fatal "unselected content leaked"; fi
[ "$("$AC" resolve IDEAS --path)" = "$ideas" ] || fatal "section sharing changed the default"
[ "$("$AC" resolve IDEAS --read | wc -l | tr -d ' ')" = 2 ] || fatal "split document read candidates missing"
ok "section sharing previews without writes, rejects stale inputs, and preserves unselected bytes"

questions=$("$AC" resolve QUESTIONS --path)
printf '# Questions\n\n## Q-101\nPublic question\n' > "$questions"
preview_apply "$AC" share "$questions" --to=QUESTIONS
absent "$questions"
has docs-agents-shared/QUESTIONS.md 'Public question'
[ "$("$AC" resolve QUESTIONS --path)" = "$REPO/docs-agents-shared/QUESTIONS.md" ] || fatal "whole-doc routing not saved"
ok "whole-doc sharing moves content and saves its selected-mode destination"

printf '## Same\na\n## Same\nb\n' > "$private_root/docs/CONCERNS.md"
reject "$AC" share "$private_root/docs/CONCERNS.md" --to=CONCERNS --section=Same
printf '# Concerns\n\n## Missing reference\n[private][ref]\n' > "$private_root/docs/CONCERNS.md"
reject "$AC" share "$private_root/docs/CONCERNS.md" --to=CONCERNS
printf '# Concerns\n\n[private](%s)\n' "$private_tasks" > "$private_root/docs/CONCERNS.md"
reject "$AC" share "$private_root/docs/CONCERNS.md" --to=CONCERNS
ok "ambiguous headings and unresolved or private references are rejected"

printf '## Separate\nAdditional public detail\n' > "$private_root/docs/CONCERNS.md"
preview_apply "$AC" share "$private_root/docs/CONCERNS.md" --to=IDEAS --merge
has docs-agents-shared/IDEAS.md 'Additional public detail'
printf '## Separate\nDuplicate\n' > "$private_root/docs/CONCERNS.md"
reject "$AC" share "$private_root/docs/CONCERNS.md" --to=IDEAS --merge
ok "explicit merges show a diff and reject duplicate identifiers or headings"

printf '# Concerns\nRecover me\n' > "$private_root/docs/CONCERNS.md"
run "$AC" share "$private_root/docs/CONCERNS.md" --to=CONCERNS
token=$(awk '/^Precondition token:/ {print $3}' "$WORK/last.log")
reject env AGENTS_CONTROL_TEST_FAIL_AFTER=1 "$AC" share "$private_root/docs/CONCERNS.md" --to=CONCERNS --apply --expect="$token"
[ -f docs-agents-shared/CONCERNS.md ] || fatal "fault did not reach the first checkpoint"
[ -f "$private_root/docs/CONCERNS.md" ] || fatal "source removed before destination was secure"
reject "$AC" migrate --profile=private --apply --expect=invalid
run "$AC" recover --restore
absent docs-agents-shared/CONCERNS.md
has "$private_root/docs/CONCERNS.md" 'Recover me'
ok "interrupted sharing blocks mutations and restores content"

run "$AC" share "$private_root/docs/CONCERNS.md" --to=CONCERNS
token=$(awk '/^Precondition token:/ {print $3}' "$WORK/last.log")
reject env AGENTS_CONTROL_TEST_FAIL_AFTER=1 "$AC" share "$private_root/docs/CONCERNS.md" --to=CONCERNS --apply --expect="$token"
printf 'newer destination edit\n' >> docs-agents-shared/CONCERNS.md
reject "$AC" recover --resume
has docs-agents-shared/CONCERNS.md 'newer destination edit'
printf '# Concerns\nRecover me\n' > docs-agents-shared/CONCERNS.md
run "$AC" recover --resume
absent "$private_root/docs/CONCERNS.md"
has docs-agents-shared/CONCERNS.md 'Recover me'
ok "recovery detects newer edits and resumes reconciled operations"

preview_apply "$AC" migrate --profile=private
has docs-agents-shared/IDEAS.md 'shared explanation'
[ "$("$AC" resolve PRD --path)" = "$private_root/docs/PRD.md" ] || fatal "private transition routes shared by mistake"
preview_apply "$AC" migrate --profile=selected
# The team explicitly resolves its same-name conflict before adopting the toolkit.
mv .agents/skills/log .agents/skills/team-existing
sed 's/^name: log$/name: team-existing/' .agents/skills/team-existing/SKILL.md > "$WORK/renamed-skill"
cp "$WORK/renamed-skill" .agents/skills/team-existing/SKILL.md
preview_apply "$AC" migrate --profile=team
[ -f .agents-control/team.conf ] || fatal "team adoption missing"
absent .claude/skills/team-existing
run "$AC" adapters
run "$AC" doctor --strict
ok "private to selected to team migration preserves shared and private content"
team_dir=$REPO
team_tasks=$("$AC" resolve TASKS --path)
printf 'shared team agreement\n' >> docs-agents-shared/DECISIONS.md
printf '\nteam guidance outside block\n' >> AGENTS.md
preview_apply "$AC" migrate --profile=private
has AGENTS.md 'team guidance outside block'
has docs-agents-shared/DECISIONS.md 'shared team agreement'
[ -f .agents-control/team.conf ] || fatal "personal withdrawal removed team configuration"
preview_apply "$AC" migrate --profile=selected
preview_apply "$AC" migrate --profile=team
ok "team withdrawal and return preserve colleagues' artifacts"

# New team setup has no user-level CLI dependency after cloning.
git add -A
git commit -qm 'team setup'
git clone -q "$REPO" "$WORK/clone"
cd "$WORK/clone"
env AGENTS_CONTROL_HOME="$WORK/no-local-state" sh .agents-control/context.sh resolve PRD > "$WORK/clone-resolve"
has "$WORK/clone-resolve" "$WORK/clone/docs-agents-shared/PRD.md"
env AGENTS_CONTROL_HOME="$WORK/no-local-state" sh .agents-control/context.sh guard-index
reject env AGENTS_CONTROL_HOME="$WORK/no-local-state" sh .agents-control/context.sh resolve TASKS --scope=private
[ -f .agents/skills/write-manual/assets/SUM.md ] || fatal "required skill asset missing in clone"
absent "$WORK/no-local-state"
ok "fresh clone resolves shared docs and skill assets without personal state or a global CLI"

cd "$team_dir"
run "$AC" adapters --mode=symlink
[ -L .claude/skills/commit ] || fatal "symlink conversion failed"
run "$AC" adapters --mode=copy
[ ! -L .claude/skills/commit ] || fatal "copy conversion failed"
printf 'user adapter edit\n' >> .claude/skills/commit/SKILL.md
cp .claude/skills/commit/SKILL.md "$WORK/adapter-edited"
reject "$AC" adapters
same .claude/skills/commit/SKILL.md "$WORK/adapter-edited"
cp .agents/skills/commit/SKILL.md .claude/skills/commit/SKILL.md
run "$AC" doctor --strict
ok "adapter modes persist and edited owned adapters are preserved"

mkdir -p .agents/skills/custom/assets
printf -- '---\nname: custom\ndescription: A custom team workflow.\n---\nCustom body\n' > .agents/skills/custom/SKILL.md
printf 'custom resource\n' > .agents/skills/custom/assets/data
run "$AC" adapters
has .claude/skills/custom/assets/data 'custom resource'
rm -rf .agents/skills/custom
run "$AC" adapters
absent .claude/skills/custom
ok "custom team skills receive owned adapters and unedited stale adapters are removed"

printf 'changed skill asset\n' >> .agents/skills/write-manual/assets/SUM.md
cp .agents/skills/write-manual/assets/SUM.md "$WORK/asset.before"
reject "$AC" update
same .agents/skills/write-manual/assets/SUM.md "$WORK/asset.before"
cp "$SRC/.agents/skills/write-manual/assets/SUM.md" .agents/skills/write-manual/assets/SUM.md
ok "whole-directory ownership catches edited supporting resources"

# Custom paths and both task owners.
new_repo 'team with spaces'
run "$AC" init --profile=team --shared-dir='team docs/shared' --private-dir="$WORK/personal notes" --team-tasks
[ -f 'team docs/shared/PRD.md' ] || fatal "custom shared path missing"
[ -f "$WORK/personal notes/docs/TASKS.md" ] || fatal "custom private path missing"
absent 'team docs/shared/TASKS.md'
printf '# Team tasks\n' > 'team docs/shared/TASKS.md'
reject "$AC" resolve TASKS
"$AC" resolve TASKS --scope=shared --path > "$WORK/task-path"
has "$WORK/task-path" "$REPO/team docs/shared/TASKS.md"
ok "space-containing paths work and optional team tasks require an explicit owner"

# Folder-only migration, preserving doc bytes.
new_repo rename
run "$AC" init --profile=team
private_tasks=$("$AC" resolve TASKS --path)
printf 'private rename sentinel\n' >> "$private_tasks"
preview_apply "$AC" migrate --private-dir="$WORK/renamed private"
has "$WORK/renamed private/docs/TASKS.md" 'private rename sentinel'
preview_apply "$AC" migrate --shared-dir='renamed shared'
[ -f 'renamed shared/PRD.md' ] || fatal "shared rename lost docs"
has AGENTS.md 'renamed shared/PRD.md'
has README.md '<renamed shared/PRD.md>'
ok "same-mode private and shared path changes preserve docs and update manifests"

# Reject a full-tree pre-staged leak, even when ordinary staging uses public paths.
new_repo indexed
mkdir -p subdir
cd subdir
run "$AC" init --private-dir=personal
cd "$REPO"
has .git/info/exclude '/personal/'
mkdir -p public
printf 'public work\n' > public/change
git add -f personal/docs/TASKS.md
git add public/change
git ls-files --stage > "$WORK/index.before"
reject "$AC" guard-index
cd subdir
reject "$AC" guard-index
cd "$REPO"
git ls-files --stage > "$WORK/index.after"
same "$WORK/index.before" "$WORK/index.after"
git commit -qm 'existing tracked private file'
git rm --cached -q personal/docs/TASKS.md
run "$AC" guard-index
ok "index guard catches previously staged private blobs and permits explicit tracking removal"

# Linked-worktree registrations and common exclusions.
new_repo worktrees
git commit -q --allow-empty -m initial
git worktree add -qb other "$WORK/other-worktree"
run "$AC" init
first_tasks=$("$AC" resolve TASKS --path)
cd "$WORK/other-worktree"
run "$AC" init
second_tasks=$("$AC" resolve TASKS --path)
[ "$first_tasks" != "$second_tasks" ] || fatal "worktrees share a personal workspace"
reject "$AC" migrate --private-dir="$REPO/.git/personal"
printf 'tracked shared material\n' > reserved.md
git add reserved.md
cd "$REPO"
reject "$AC" migrate --private-dir=reserved.md
ok "linked worktrees have distinct private workspaces and reject shared exclusion conflicts"

# Every legacy transition requires explicit choices; tracked sources remain visible for removal.
for profile in private selected team; do
  new_repo "legacy-$profile"
  mkdir -p .agents docs-agents
  printf '{"adapter_mode":"copy","skills":[]}\n' > .agents/agents-control.json
  printf '# Product\nlegacy content\n' > docs-agents/PRD.md
  printf '# Concerns\nunclassified legacy content\n' > docs-agents/CONCERNS.md
  git add -A; git commit -qm legacy
  reject "$AC" init
  if [ "$profile" = private ]; then destination=private; else destination=shared; fi
  preview_apply "$AC" migrate --profile="$profile" --doc=PRD:"$destination" --from=legacy
  if [ "$destination" = private ]; then moved=$("$AC" resolve PRD --scope=private --path)
  else moved=$("$AC" resolve PRD --scope=shared --path); fi
  has "$moved" 'legacy content'
  absent docs-agents/PRD.md
  "$AC" resolve CONCERNS --read > "$WORK/legacy-reads"
  has "$WORK/legacy-reads" 'unclassified'
  has "$WORK/legacy-reads" "$REPO/docs-agents/CONCERNS.md"
  has docs-agents/CONCERNS.md 'unclassified legacy content'
  reject "$AC" guard-index
  git add -u -- docs-agents/PRD.md
  run "$AC" guard-index
  ok "legacy to $profile migration previews selected content and reports required tracking removal"
done

new_repo conflict
mkdir -p .agents/skills/log
printf 'unowned team workflow\n' > .agents/skills/log/SKILL.md
reject "$AC" init --profile=team
has .agents/skills/log/SKILL.md 'unowned team workflow'
absent .agents-control/team.conf
ok "same-name unowned team skill conflicts fail before applying any planned setup"
run "$AC" init --profile=team --adopt
has .agents/skills/log/SKILL.md 'unowned team workflow'
absent .agents-control/team.conf
token=$(awk '/^Precondition token:/ {print $3}' "$WORK/last.log")
run "$AC" init --profile=team --adopt --apply --expect="$token"
has .agents/skills/log/SKILL.md 'name: log'
printf 'new guidance outside block without LF' >> AGENTS.md
run "$AC" recover --restore
has .agents/skills/log/SKILL.md 'unowned team workflow'
has AGENTS.md 'new guidance outside block without LF'
absent .agents-control/team.conf
ok "explicit adoption requires its preview token and restore preserves unrelated guidance"
run "$AC" init --profile=private
tasks=$("$AC" resolve TASKS --path)
registration=$(dirname "$(dirname "$tasks")")
printf 'schema=9\n' >> "$registration/repo.conf"
reject "$AC" resolve TASKS
ok "malformed or unsupported configuration never falls back to a write destination"

new_repo unicode
run "$AC" init
ideas=$("$AC" resolve IDEAS --path)
printf '# Réflexions\r\n\r\n## Garder\r\nprivé\r\n\r\n## Publier\r\npartagé\r\n\r\n## Fin\r\nsecret sans LF' > "$ideas"
printf '# Réflexions\r\n\r\n## Garder\r\nprivé\r\n\r\n## Fin\r\nsecret sans LF' > "$WORK/unicode-remainder"
preview_apply "$AC" share "$ideas" --to=IDEAS --section=Publier
same "$ideas" "$WORK/unicode-remainder"
has docs-agents-shared/IDEAS.md 'partagé'
ok "Unicode, CRLF, and a missing final newline keep exact private remainder bytes"

concerns=$("$AC" resolve CONCERNS --path)
printf '# Concerns\n[ref]: https://example.invalid\n\n## Publish\n[ref]\n' > "$concerns"
reject "$AC" share "$concerns" --to=CONCERNS --section=Publish
printf '# Concerns\n[See](#publish)\n\n## Publish\npublic detail\n' > "$concerns"
reject "$AC" share "$concerns" --to=CONCERNS --section=Publish
printf '# Concerns\n```bad`info\n## Publish\npublic detail\n```\n' > "$concerns"
reject "$AC" share "$concerns" --to=CONCERNS --section=Publish
ok "shortcut references, remainder dependencies, and malformed fences stop section moves"

questions=$("$AC" resolve QUESTIONS --path)
printf '# Questions\npublic then private\n' > "$questions"
preview_apply "$AC" share "$questions" --to=QUESTIONS
preview_apply "$AC" migrate --doc=QUESTIONS.md:private --from=shared
[ "$("$AC" resolve QUESTIONS --path)" = "$questions" ] || fatal "private doc move retained its shared write default"
has "$questions" 'public then private'
ok "whole-doc withdrawal updates selected routing without losing content"

for boundary in 1 2 3; do
  new_repo "checkpoint-$boundary"
  run "$AC" init
  concerns=$("$AC" resolve CONCERNS --path)
  printf '# Concerns\ncheckpoint content\n' > "$concerns"
  run "$AC" share "$concerns" --to=CONCERNS
  token=$(awk '/^Precondition token:/ {print $3}' "$WORK/last.log")
  reject env AGENTS_CONTROL_TEST_FAIL_AFTER="$boundary" "$AC" share "$concerns" --to=CONCERNS --apply --expect="$token"
  reject env AGENTS_CONTROL_HOME="$WORK/different-state" "$AC" guard-index
  reject env AGENTS_CONTROL_HOME="$WORK/different-state" "$AC" init
  run "$AC" recover --restore
  absent docs-agents-shared/CONCERNS.md
  has "$concerns" 'checkpoint content'
  [ "$("$AC" resolve CONCERNS --path)" = "$concerns" ] || fatal "restore lost private routing"
done
ok "every sharing write boundary restores content and blocks other state roots while pending"

new_repo direct-transitions
run "$AC" init
preview_apply "$AC" migrate --profile=team
preview_apply "$AC" migrate --profile=selected
preview_apply "$AC" migrate --profile=private
has .agents-control/team.conf 'schema=1'
ok "direct private-to-team and team-to-selected transitions preserve team adoption"

new_repo exclusions
printf 'unrelated ignore\n' >> .git/info/exclude
run "$AC" init --private-dir='notes [x] *'
git check-ignore -q -- 'notes [x] */docs/TASKS.md' || fatal "private ignore did not escape glob characters"
printf 'outside ignore without LF' >> .git/info/exclude
run "$AC" migrate --private-dir="$WORK/moved-private"
token=$(awk '/^Precondition token:/ {print $3}' "$WORK/last.log")
run "$AC" migrate --private-dir="$WORK/moved-private" --apply --expect="$token"
has .git/info/exclude 'unrelated ignore'
has .git/info/exclude 'outside ignore without LF'
if grep -Fq '/notes' .git/info/exclude; then fatal "retired private ignore was not removed"; fi
printf 'outside ignore without LF' > "$WORK/no-lf"
tail -c 25 .git/info/exclude > "$WORK/exclude-tail"
same "$WORK/no-lf" "$WORK/exclude-tail"
run "$AC" migrate --profile=selected
token=$(awk '/^Precondition token:/ {print $3}' "$WORK/last.log")
mkdir -p .git/agents-control.lock
printf '%s\n' "$$" > .git/agents-control.lock/pid
reject "$AC" migrate --profile=selected --apply --expect="$token"
[ "$(cat .git/agents-control.lock/pid)" = "$$" ] || fatal "failed operation removed another lock"
rm -rf .git/agents-control.lock
ok "private path moves clear exact exclusions and preserve unrelated bytes and lock ownership"

new_repo legacy-symlinks
mkdir -p .agents docs-agents
printf '{"adapter_mode":"symlink"}\n' > .agents/agents-control.json
printf '# Product\nlegacy symlink mode\n' > docs-agents/PRD.md
preview_apply "$AC" migrate --profile=team --doc=PRD:shared --from=legacy
[ -L .claude/skills/log ] || fatal "legacy symlink mode was not retained"
tasks=$("$AC" resolve TASKS --path)
registration=$(dirname "$(dirname "$tasks")")
same .agents/agents-control.json "$registration/state/legacy-adapter.json"
ok "legacy adapter choice imports without modifying its archived state"

new_repo generated-safety
run "$AC" init --profile=team
printf 'outside guide without LF' >> AGENTS.md
preview_apply "$AC" migrate --shared-dir='docs & links|literal'
has README.md '<docs & links|literal/PRD.md>'
printf 'outside guide without LF' > "$WORK/guide-tail.expected"
tail -c 24 AGENTS.md > "$WORK/guide-tail"
same "$WORK/guide-tail.expected" "$WORK/guide-tail"
ln -s "$WORK" 'docs & links|literal/IDEAS.md'
reject "$AC" resolve IDEAS --scope=shared
reject "$AC" resolve IDEAS --read
rm 'docs & links|literal/IDEAS.md'
mkdir -p .agents/skills/odd
printf -- '---\nname: odd\ndescription: Test resource validation.\n---\n' > .agents/skills/odd/SKILL.md
newline_resource=$(printf 'bad\nname')
touch ".agents/skills/odd/$newline_resource"
reject "$AC" adapters
rm -rf .agents/skills/odd
reject "$AC" init --shared-docs=PRD.md
reject "$AC" context --profile=private
reject "$AC" migrate --section=missing
reject "$AC" migrate --shared-dir=.agents/hidden
reject "$AC" recover --resume --restore
rm .agents-control/team.conf
mkdir .agents-control/team.conf
reject "$AC" resolve PRD
ok "literal path rewriting, managed-block bytes, symlink leaves, and invalid arguments are protected"

new_repo reattach
run "$AC" init --profile=selected --shared-dir='chosen shared'
private_tasks=$("$AC" resolve TASKS --path)
questions=$("$AC" resolve QUESTIONS --path)
printf '# Questions\nreattach sentinel\n' > "$questions"
preview_apply "$AC" share "$questions" --to=QUESTIONS
registration=$(basename "$(dirname "$(dirname "$private_tasks")")")
mv "$REPO" "$WORK/reattached"
REPO=$WORK/reattached
cd "$REPO"
"$AC" context > "$WORK/moved-context"
[ ! -s "$WORK/moved-context" ] || fatal "moved checkout was guessed automatically"
preview_apply "$AC" migrate --attach="$registration"
[ "$("$AC" resolve TASKS --path)" = "$private_tasks" ] || fatal "reattachment lost private workspace"
[ "$("$AC" resolve QUESTIONS --path)" = "$REPO/chosen shared/QUESTIONS.md" ] || fatal "reattachment lost custom sharing directory"
has 'chosen shared/QUESTIONS.md' 'reattach sentinel'
ok "explicit moved-checkout reattachment retains private data and selected sharing choices"

new_repo pending-marker
ln -s "$WORK/marker-target" .git/agents-control.pending
reject "$AC" init
reject "$AC" guard-index
absent "$WORK/marker-target"
rm .git/agents-control.pending
printf 'existing file\n' > occupied
reject "$AC" init --profile=selected --shared-dir=occupied
has occupied 'existing file'
reject "$AC" init --private-dir=DOCS-AGENTS-SHARED
reject "$AC" init --shared-dir=.AGENTS/hidden
reject "$AC" init --private-dir="$REPO/.git/personal"
if [ -d .GIT ]; then reject "$AC" init --private-dir="$REPO/.GIT/personal"; fi
ok "invalid pending markers and non-directory storage never get overwritten"

# Installer update after a real private workspace exists.
run sh "$SRC/install.sh"
has "$AGENTS_CONTROL_HOME/repos/sentinel/notes" 'personal data'
new_repo unconfigured
"$AC" context > "$WORK/empty-context"
[ ! -s "$WORK/empty-context" ] || fatal "personal context leaked into an unconfigured repository"
reject "$AC" init --profile=unknown
reject "$AC" update --force
cd "$SRC"
run "$AC" doctor --skills-only --strict
reject "$AC" init
ok "read-only unconfigured context, option guards, toolkit self-guard, and portability checks pass"

printf '\n%s behavior checks passed\n' "$PASS"
