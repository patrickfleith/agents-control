#!/bin/sh
# End-to-end tests for install.sh and bin/agents-control.
# No framework: every check is a shell assertion. Run from anywhere:
#
#   sh tests/test-install.sh
#
set -eu

SRC=$(cd "$(dirname "$0")/.." && pwd -P)
WORK=$(mktemp -d)
PASS=0
FAIL=0

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  RED=$(printf '\033[31m'); GRN=$(printf '\033[32m'); B=$(printf '\033[1m'); R=$(printf '\033[0m')
else
  RED=''; GRN=''; B=''; R=''
fi

cleanup() { rm -r -f "$WORK"; }
trap cleanup EXIT INT TERM

group() { printf '\n%s%s%s\n' "$B" "$*" "$R"; }
pass()  { PASS=$((PASS + 1)); printf '  %sok%s   %s\n' "$GRN" "$R" "$*"; }
fail()  { FAIL=$((FAIL + 1)); printf '  %sFAIL%s %s\n' "$RED" "$R" "$*"; }

check()      { if [ "$1" = 0 ]; then pass "$2"; else fail "$2"; fi }
assert_file() { if [ -f "$1" ]; then pass "$2"; else fail "$2 (missing: $1)"; fi }
assert_link() { if [ -L "$1" ]; then pass "$2"; else fail "$2 (not a symlink: $1)"; fi }

# ---------------------------------------------------------------- install

group "install.sh"

export HOME="$WORK/home"
export AGENTS_CONTROL_HOME="$HOME/.agents-control"
export AGENTS_CONTROL_BIN_DIR="$HOME/.local/bin"
export AGENTS_CONTROL_SOURCE="$SRC"
mkdir -p "$HOME"

if sh "$SRC/install.sh" > "$WORK/install.log" 2>&1; then
  pass "install.sh succeeds"
else
  fail "install.sh failed"
  cat "$WORK/install.log"
  exit 1
fi

AC="$AGENTS_CONTROL_BIN_DIR/agents-control"
if [ -x "$AC" ]; then pass "CLI is executable on PATH"; else fail "CLI not executable at $AC"; fi

# The setup skill must land where each tool looks: .agents/skills for Codex
# and Cursor, .claude/skills for Claude Code.
assert_file "$HOME/.agents/skills/agents-control/SKILL.md" "setup skill readable via ~/.agents/skills (Codex, Cursor)"
assert_file "$HOME/.claude/skills/agents-control/SKILL.md" "setup skill readable via ~/.claude/skills (Claude Code)"

"$AC" version > /dev/null 2>&1
check $? "agents-control version runs"

# Re-running is the documented update path.
if sh "$SRC/install.sh" > "$WORK/install2.log" 2>&1; then
  pass "install.sh is idempotent"
else
  fail "second install.sh run failed"
  cat "$WORK/install2.log"
fi

# ---------------------------------------------------------------- init

group "init"

REPO="$WORK/target"
mkdir -p "$REPO"
git -C "$REPO" init --quiet
git -C "$REPO" config user.email test@example.com
git -C "$REPO" config user.name Test

cd "$REPO"
"$AC" init > "$WORK/init.log" 2>&1
check $? "init succeeds in a fresh git repo"

assert_file "$REPO/AGENTS.md" "AGENTS.md created"
assert_file "$REPO/CLAUDE.md" "CLAUDE.md created"
if grep -q '^@AGENTS\.md$' "$REPO/CLAUDE.md"; then
  pass "CLAUDE.md imports AGENTS.md"
else
  fail "CLAUDE.md does not import AGENTS.md"
fi

for s in commit log decide glossary write-manual unslop; do
  assert_file "$REPO/.agents/skills/$s/SKILL.md" "skill $s installed"
done
for d in PRD STACK ROADMAP DECISIONS TASKS CHANGELOG; do
  assert_file "$REPO/docs-agents/$d.md" "doc $d.md scaffolded"
done
assert_file "$REPO/README.md" "README.md scaffolded (part of the MVP core)"

# The setup skill is user-level; it must not be copied into target repos.
if [ -e "$REPO/.agents/skills/agents-control" ]; then
  fail "the agents-control setup skill leaked into the target repo"
else
  pass "setup skill not copied into the target repo"
fi

# ---------------------------------------------------------------- adapters

group "adapters (symlink mode)"

assert_link "$REPO/.claude/skills/commit" "adapter is a per-skill symlink"
if [ -L "$REPO/.claude/skills" ]; then
  fail ".claude/skills is a directory symlink (undocumented in Claude Code)"
else
  pass ".claude/skills is a real directory"
fi
assert_file "$REPO/.claude/skills/commit/SKILL.md" "Claude Code can read a skill through the adapter"

# Adapters must survive a clone, since cloud sessions read the checkout.
git -C "$REPO" add -A > /dev/null 2>&1
git -C "$REPO" commit --quiet -m "agents-control" > /dev/null 2>&1
git clone --quiet "$REPO" "$WORK/clone" 2>/dev/null
assert_file "$WORK/clone/.claude/skills/commit/SKILL.md" "adapter still resolves after a git clone"

# ---------------------------------------------------------------- idempotency

group "idempotency"

printf -- '- [ ] sentinel task\n' >> "$REPO/docs-agents/TASKS.md"
printf 'my own readme\n' > "$REPO/README.md"
cp "$REPO/AGENTS.md" "$WORK/agents.before"
"$AC" init > "$WORK/init2.log" 2>&1
check $? "init runs a second time"

if grep -q 'sentinel task' "$REPO/docs-agents/TASKS.md"; then
  pass "existing doc content survives a re-run"
else
  fail "re-running init clobbered docs-agents/TASKS.md"
fi
if cmp -s "$WORK/agents.before" "$REPO/AGENTS.md"; then
  pass "AGENTS.md untouched on a re-run"
else
  fail "re-running init rewrote AGENTS.md"
fi
if grep -q 'my own readme' "$REPO/README.md"; then
  pass "an existing README.md survives init"
else
  fail "init clobbered an existing README.md"
fi

# ---------------------------------------------------------------- copy mode

group "copy mode"

"$AC" adapters --mode=copy > "$WORK/copy.log" 2>&1
check $? "adapters --mode=copy succeeds"
if [ -L "$REPO/.claude/skills/commit" ]; then
  fail "adapter is still a symlink after --mode=copy"
else
  pass "adapter is a real directory in copy mode"
fi
assert_file "$REPO/.claude/skills/commit/SKILL.md" "copied adapter has a SKILL.md"

# Once recorded, copy mode must stick — a teammate on macOS regenerating
# adapters must not silently flip a Windows-friendly repo back to symlinks.
"$AC" adapters > "$WORK/copy2.log" 2>&1
if [ -L "$REPO/.claude/skills/commit" ]; then
  fail "a bare 'adapters' run flipped copy mode back to symlinks"
else
  pass "copy mode persists across a bare 'adapters' run"
fi

# Drift is what copy mode risks; doctor must catch it and adapters must fix it.
printf '\ndrifted\n' >> "$REPO/.agents/skills/commit/SKILL.md"
if "$AC" doctor --strict > "$WORK/drift.log" 2>&1; then
  fail "doctor --strict passed despite a drifted copy"
else
  pass "doctor --strict catches a drifted copy"
fi
"$AC" adapters > /dev/null 2>&1
if cmp -s "$REPO/.agents/skills/commit/SKILL.md" "$REPO/.claude/skills/commit/SKILL.md"; then
  pass "adapters re-copies the drifted skill"
else
  fail "adapters did not refresh the drifted copy"
fi

"$AC" adapters --mode=symlink > /dev/null 2>&1
assert_link "$REPO/.claude/skills/commit" "adapters --mode=symlink converts back"

# ---------------------------------------------------------------- doctor

group "doctor"

"$AC" doctor --strict > "$WORK/doctor.log" 2>&1
check $? "doctor --strict passes on a healthy repo"
if grep -q "Claude Code" "$WORK/doctor.log" && grep -q "Codex" "$WORK/doctor.log" && grep -q "Cursor" "$WORK/doctor.log"; then
  pass "doctor reports all three tools"
else
  fail "doctor output is missing a tool"
fi

# A broken symlink is the failure mode of symlink mode; it must be named.
rm -f "$REPO/.claude/skills/log"
ln -s ../../.agents/skills/does-not-exist "$REPO/.claude/skills/log"
if "$AC" doctor --strict > "$WORK/broken.log" 2>&1; then
  fail "doctor --strict passed with a broken adapter symlink"
else
  pass "doctor --strict fails on a broken adapter symlink"
fi
if grep -q "broken symlink" "$WORK/broken.log"; then
  pass "doctor names the broken symlink"
else
  fail "doctor did not explain the broken symlink"
fi
"$AC" adapters > /dev/null 2>&1

# A CLAUDE.md without the import is silent breakage: Claude Code reads the
# file, finds nothing, and never sees the manifest.
printf '# notes\n' > "$REPO/CLAUDE.md"
if "$AC" doctor --strict > "$WORK/noimport.log" 2>&1; then
  fail "doctor --strict passed with a CLAUDE.md that has no import"
else
  pass "doctor --strict catches a CLAUDE.md missing @AGENTS.md"
fi
printf '@AGENTS.md\n' > "$REPO/CLAUDE.md"

# Frontmatter outside the spec works in Claude Code and nowhere else.
mkdir -p "$REPO/.agents/skills/nonportable"
{ printf -- '---\n'
  printf 'name: nonportable\n'
  printf 'description: A skill with a Claude-only frontmatter key.\n'
  printf 'argument-hint: "[thing]"\n'
  printf -- '---\n\nBody.\n'; } > "$REPO/.agents/skills/nonportable/SKILL.md"
if "$AC" doctor --strict > "$WORK/frontmatter.log" 2>&1; then
  fail "doctor --strict passed with non-spec frontmatter"
else
  pass "doctor --strict flags non-spec frontmatter"
fi
rm -r -f "$REPO/.agents/skills/nonportable"
"$AC" adapters > /dev/null 2>&1

# A stale adapter must be removed, not left pointing at a deleted skill.
if [ -e "$REPO/.claude/skills/nonportable" ]; then
  fail "adapters left a stale entry for a removed skill"
else
  pass "adapters removes the adapter for a removed skill"
fi

# ---------------------------------------------------------------- guards

group "guards"

mkdir -p "$WORK/notarepo"
cd "$WORK/notarepo"
if "$AC" init > "$WORK/norepo.log" 2>&1; then
  fail "init ran outside a git repo"
else
  pass "init refuses to run outside a git repo"
fi

# The toolkit is a source, not a target.
TOOLKIT="$WORK/toolkit-clone"
mkdir -p "$TOOLKIT"
git -C "$TOOLKIT" init --quiet
git -C "$TOOLKIT" remote add origin https://github.com/patrickfleith/agents-control.git
cd "$TOOLKIT"
if "$AC" init > "$WORK/selfinit.log" 2>&1; then
  fail "init ran inside the agents-control toolkit repo"
else
  pass "init refuses to run inside the toolkit repo"
fi

# ---------------------------------------------------------------- summary

printf '\n%s%s passed, %s failed%s\n' "$B" "$PASS" "$FAIL" "$R"
[ "$FAIL" -eq 0 ]
