#!/bin/sh
# agents-control installer.
#
#   curl -fsSL https://raw.githubusercontent.com/patrickfleith/agents-control/main/install.sh | sh
#
# Fetches the toolkit, puts `agents-control` on your PATH, and installs the
# setup skill where Claude Code, Codex and Cursor each look for it.
# Re-running is the update path.
set -eu

REPO_SLUG="patrickfleith/agents-control"
REF="${AGENTS_CONTROL_REF:-main}"
HOME_DIR="${AGENTS_CONTROL_HOME:-$HOME/.agents-control}"
BIN_DIR="${AGENTS_CONTROL_BIN_DIR:-$HOME/.local/bin}"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  B=$(printf '\033[1m'); R=$(printf '\033[0m')
  RED=$(printf '\033[31m'); YEL=$(printf '\033[33m'); GRN=$(printf '\033[32m')
else
  B=''; R=''; RED=''; YEL=''; GRN=''
fi

step() { printf '%s%s%s\n' "$B" "$*" "$R"; }
ok()   { printf '  %s+%s %s\n' "$GRN" "$R" "$*"; }
warn() { printf '  %s!%s %s\n' "$YEL" "$R" "$*" >&2; }
die()  { printf '%serror:%s %s\n' "$RED" "$R" "$*" >&2; exit 1; }

command -v git >/dev/null 2>&1 || die "git is required."

TMP=$(mktemp -d) || die "could not create a temp directory"
cleanup() { rm -r -f "$TMP"; }
trap cleanup EXIT INT TERM

# ---------------------------------------------------------------- fetch

step "Fetching agents-control ($REF)"
FETCHED=""
# AGENTS_CONTROL_SOURCE installs from a local checkout instead of GitHub.
# The test harness and CI use it; it also lets you install a fork or a
# work-in-progress branch you haven't pushed.
if [ -n "${AGENTS_CONTROL_SOURCE:-}" ]; then
  [ -f "$AGENTS_CONTROL_SOURCE/bin/agents-control" ] \
    || die "AGENTS_CONTROL_SOURCE=$AGENTS_CONTROL_SOURCE is not an agents-control checkout"
  tar c -C "$AGENTS_CONTROL_SOURCE" --exclude=./.git . | tar x -C "$TMP"
  if git -C "$AGENTS_CONTROL_SOURCE" rev-parse --short HEAD >/dev/null 2>&1; then
    printf '%s (local)\n' "$(git -C "$AGENTS_CONTROL_SOURCE" rev-parse --short HEAD)" \
      > "$TMP/.agents-control-version"
  else
    printf 'local\n' > "$TMP/.agents-control-version"
  fi
  FETCHED=local
  REF="local:$AGENTS_CONTROL_SOURCE"
fi
if [ -z "$FETCHED" ] && command -v curl >/dev/null 2>&1; then
  if curl -fsSL "https://github.com/$REPO_SLUG/archive/refs/heads/$REF.tar.gz" \
       | tar xz -C "$TMP" --strip-components=1 2>/dev/null; then
    FETCHED=tarball
  fi
fi
if [ -z "$FETCHED" ]; then
  # Tarball URLs only resolve for branches; a tag or sha needs a clone.
  if git clone --quiet --depth 1 --branch "$REF" \
       "https://github.com/$REPO_SLUG" "$TMP/clone" 2>/dev/null; then
    # Move the tracked files and .git separately: a single mv with both globs
    # fails wholesale when one of them matches nothing.
    mv "$TMP/clone"/* "$TMP/" 2>/dev/null || true
    mv "$TMP/clone/.git" "$TMP/" 2>/dev/null || true
    rmdir "$TMP/clone" 2>/dev/null || true
    FETCHED=clone
  fi
fi
[ -n "$FETCHED" ] || die "could not download $REPO_SLUG at ref '$REF'. Check the ref and your network."
[ -f "$TMP/bin/agents-control" ] || die "the download is missing bin/agents-control — is '$REF' a valid ref?"

if [ ! -f "$TMP/.agents-control-version" ]; then
  if git -C "$TMP" rev-parse --short HEAD >/dev/null 2>&1; then
    git -C "$TMP" rev-parse --short HEAD > "$TMP/.agents-control-version"
  else
    printf '%s\n' "$REF" > "$TMP/.agents-control-version"
  fi
fi
ok "downloaded $(cat "$TMP/.agents-control-version")"

# ---------------------------------------------------------------- install

step "Installing to $HOME_DIR"
mkdir -p "$(dirname "$HOME_DIR")"
if [ -e "$HOME_DIR" ]; then
  rm -r -f "$HOME_DIR.previous"
  mv "$HOME_DIR" "$HOME_DIR.previous"
fi
mv "$TMP" "$HOME_DIR"
trap - EXIT INT TERM
chmod +x "$HOME_DIR/bin/agents-control"
rm -r -f "$HOME_DIR.previous"
ok "toolkit installed"

# ---------------------------------------------------------------- PATH

step "Putting agents-control on your PATH"
mkdir -p "$BIN_DIR"
rm -f "$BIN_DIR/agents-control"
if ln -s "$HOME_DIR/bin/agents-control" "$BIN_DIR/agents-control" 2>/dev/null; then
  ok "$BIN_DIR/agents-control"
else
  cp "$HOME_DIR/bin/agents-control" "$BIN_DIR/agents-control"
  chmod +x "$BIN_DIR/agents-control"
  ok "$BIN_DIR/agents-control (copied — this filesystem has no symlinks)"
fi

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) warn "$BIN_DIR is not on your PATH. Add this to your shell profile:"
     printf '\n      export PATH="%s:$PATH"\n\n' "$BIN_DIR" ;;
esac

# ---------------------------------------------------------------- skill

# The setup skill goes into every tool's personal skills directory, so it is
# invocable whichever agent you happen to open. `.agents/skills` covers Codex
# and Cursor; Claude Code reads only `.claude/skills`.
step "Installing the setup skill"
SRC_SKILL="$HOME_DIR/.agents/skills/agents-control"
[ -d "$SRC_SKILL" ] || die "the download is missing .agents/skills/agents-control"

for dest in "$HOME/.agents/skills/agents-control" "$HOME/.claude/skills/agents-control"; do
  mkdir -p "$(dirname "$dest")"
  rm -r -f "$dest"
  if ln -s "$SRC_SKILL" "$dest" 2>/dev/null; then
    ok "$dest"
  else
    cp -R "$SRC_SKILL" "$dest"
    ok "$dest (copied)"
  fi
done

# ---------------------------------------------------------------- report

printf '\n'
step "Done. In the repo you want to bring under agents-control:"
printf '\n'
printf '  %-14s %s\n' "Claude Code" "/agents-control"
printf '  %-14s %s\n' "Codex" "\$agents-control"
printf '  %-14s %s\n' "Cursor" '"set up agents-control here"'
printf '\n'
printf '  or run it yourself:  agents-control init\n'
printf '\n'
printf '  Re-run this installer to update. See %s\n' "https://github.com/$REPO_SLUG"
