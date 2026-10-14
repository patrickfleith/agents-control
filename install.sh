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
USER_ROOT="${AGENTS_CONTROL_USER_HOME:-$HOME}"
HOME_DIR="${AGENTS_CONTROL_HOME:-$USER_ROOT/.agents-control}"
BIN_DIR="${AGENTS_CONTROL_BIN_DIR:-$USER_ROOT/.local/bin}"

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
    cp -RP "$TMP/clone/." "$TMP/"
    rm -rf "$TMP/clone"
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

# Installed code and private data have separate lifetimes.
FETCH_DIR=$TMP
AC_CONTEXT_LIBRARY=1
. "$FETCH_DIR/lib/context.sh"
. "$FETCH_DIR/lib/operations.sh"
mkdir -p "$USER_ROOT"
AC_REPO=$(cd "$USER_ROOT" && pwd -P)
AC_HOME=$(ac_absolute "$HOME_DIR")
HOME_DIR=$AC_HOME
BIN_DIR=$(ac_absolute "$BIN_DIR")
AC_TEAM=; AC_LOCAL=; AC_REGISTRY=; AC_PRIVATE=
AC_ACTION=install
AC_NO_GIT=1
INSTALL_ADOPT=; AC_APPLY=; AC_EXPECT=; AC_RECOVERY=
for option in "$@"; do
  case $option in
    --adopt) INSTALL_ADOPT=1 ;;
    --apply) AC_APPLY=1 ;;
    --expect=*) AC_EXPECT=${option#--expect=} ;;
    --resume|--restore) [ -z "$AC_RECOVERY" ] || die "choose one recovery direction"; AC_RECOVERY=${option#--} ;;
    *) die "installer options: --adopt [--apply --expect=TOKEN], --resume, --restore" ;;
  esac
done
AC_ADOPT=$INSTALL_ADOPT
[ -z "$AC_EXPECT" ] || [ -n "$AC_APPLY" ] || die "--expect requires --apply"
[ -z "$AC_RECOVERY" ] || [ -z "$INSTALL_ADOPT$AC_APPLY$AC_EXPECT" ] || die "recovery takes no other options"
ac_operation_paths() {
  AC_COMMON=$HOME_DIR
  AC_JOURNAL=$HOME_DIR/operations/install/current
  AC_LOCK=$HOME_DIR/install.lock
  AC_PENDING=
}
ac_begin
trap 'rm -rf "$AC_TMP" "$FETCH_DIR"; if [ -n "$AC_LOCK_HELD" ]; then rm -rf "$AC_LOCK_HELD"; fi' EXIT
ac_operation_paths
mkdir -p "$HOME_DIR"
if [ -n "$AC_RECOVERY" ]; then
  ac_recover
  exit 0
fi
[ ! -f "$AC_JOURNAL/pending" ] || ac_die "installer recovery required: rerun install.sh --resume or --restore"

AC_OWNER_FILE=$HOME_DIR/install.tsv
AC_OWNER_ROOT=$AC_REPO
AC_OWNER_PORTABLE=
ac_owner_init
# The downloaded Git metadata is not part of the installed code.
rm -rf "$FETCH_DIR/.git"
runtime=$AC_TMP/runtime
mkdir -p "$runtime/bin" "$runtime/lib" "$runtime/.agents/skills"
cp "$FETCH_DIR/bin/agents-control" "$runtime/bin/"
cp "$FETCH_DIR/lib/context.sh" "$FETCH_DIR/lib/operations.sh" "$FETCH_DIR/lib/markdown.awk" "$FETCH_DIR/lib/replace.awk" "$runtime/lib/"
cp -RP "$FETCH_DIR/templates" "$runtime/templates"
cp "$FETCH_DIR/install.sh" "$FETCH_DIR/.agents-control-version" "$runtime/"
for runtime_doc in README.md LICENSE; do
  [ ! -f "$FETCH_DIR/$runtime_doc" ] || cp "$FETCH_DIR/$runtime_doc" "$runtime/"
done
mkdir -p "$runtime/docs"
cp "$FETCH_DIR/docs/usage.md" "$runtime/docs/"
for runtime_skill in agents-control $AC_SKILLS; do
  cp -RP "$FETCH_DIR/.agents/skills/$runtime_skill" "$runtime/.agents/skills/"
done
ac_plan "$HOME_DIR/toolkit" "$runtime" D owned

# Preserve the established executable and setup-skill entry points.
plan_link() {
  link_target=$1; link_source=$2
  link_payload=$AC_TMP/link.$AC_ITEM_NUMBER
  ln -s "$link_source" "$link_payload"
  if [ -L "$link_target" ]; then
    old_link=$(readlink "$link_target")
    case $old_link in
      "$HOME_DIR/bin/agents-control"|"$HOME_DIR/toolkit/bin/agents-control")
        previous_adopt=$AC_ADOPT; AC_ADOPT=1
        ac_plan "$link_target" "$link_payload" L owned
        AC_ADOPT=$previous_adopt
        return ;;
    esac
  fi
  ac_plan "$link_target" "$link_payload" L owned
}
plan_link "$BIN_DIR/agents-control" "$HOME_DIR/toolkit/bin/agents-control"
if [ ! -e "$HOME_DIR/bin/agents-control" ] || [ -L "$HOME_DIR/bin/agents-control" ] || [ -n "$INSTALL_ADOPT" ]; then
  plan_link "$HOME_DIR/bin/agents-control" "$HOME_DIR/toolkit/bin/agents-control"
else
  warn "preserved the old launcher at $HOME_DIR/bin/agents-control; PATH uses the new toolkit"
fi

for skill in agents-control $AC_SKILLS; do
  if [ "$skill" = agents-control ]; then name=$skill; else name=ac-$skill; fi
  source=$FETCH_DIR/.agents/skills/$skill
  payload=$AC_TMP/skill.$name
  cp -RP "$source" "$payload"
  if [ "$skill" != agents-control ]; then
    sed "s/^name: $skill$/name: $name/" "$source/SKILL.md" > "$payload/SKILL.md"
    printf '\nThis personal workflow requires a registered worktree. Run agents-control context\nand stop with setup guidance if no personal registration exists.\n' >> "$payload/SKILL.md"
  fi
  for skills_dir in "$AC_REPO/.agents/skills" "$AC_REPO/.claude/skills"; do
    destination=$skills_dir/$name
    # A known legacy per-skill link can be replaced without touching its target.
    if [ "$name" = agents-control ] && [ -L "$destination" ]; then
      case $(readlink "$destination") in
        "$HOME_DIR/.agents/skills/agents-control"|"$HOME_DIR/toolkit/.agents/skills/agents-control")
          AC_ADOPT=1 ;;
      esac
    fi
    ac_plan "$destination" "$payload" D owned
    AC_ADOPT=$INSTALL_ADOPT
  done
done

cat > "$AC_TMP/loader" <<'DOC'
<!-- agents-control:start -->
## Personal agents-control context

When starting repository work, run agents-control context once if the CLI is
available. It returns additional guidance only for an explicitly registered
worktree. Preserve the project's instructions. If personal context is unavailable,
do not invent private paths or write private material to shared docs.

Personal workflow names use the ac- prefix. Resolve destinations before writing
and keep edits to existing entries in the file that contains them.
<!-- agents-control:end -->
DOC
CODEX_DIR=${AGENTS_CONTROL_CODEX_HOME:-${CODEX_HOME:-$AC_REPO/.codex}}
CODEX_DIR=$(ac_absolute "$CODEX_DIR")
if [ -s "$CODEX_DIR/AGENTS.override.md" ]; then codex_guidance=$CODEX_DIR/AGENTS.override.md
else codex_guidance=$CODEX_DIR/AGENTS.md; fi
for guidance in "$codex_guidance" "$AC_REPO/.claude/CLAUDE.md"; do
  if [ -L "$guidance" ]; then
    warn "preserved symlinked personal guidance: $guidance; add the loader to its intended source manually"
  else ac_plan "$guidance" "$AC_TMP/loader" B owned; fi
done
ac_plan "$HOME_DIR/cursor-user-rule.md" "$AC_TMP/loader" F owned
ac_owner_finish
ac_preview
if [ -n "$INSTALL_ADOPT" ] && [ -z "$AC_APPLY" ]; then exit 0; fi
if [ -z "$AC_APPLY" ]; then AC_EXPECT=$AC_TOKEN; fi
ac_apply

step "Installed agents-control"
ok "$BIN_DIR/agents-control"
printf 'Cursor: add the contents of %s/cursor-user-rule.md to User Rules.\n' "$HOME_DIR"
printf 'Codex and Claude personal loader blocks were preserved or installed.\n'
printf 'In a repository: agents-control init --profile=private|selected|team\n'
printf 'Re-run this installer to update owned code and skills; private workspaces stay intact.\n'
case ":$PATH:" in *":$BIN_DIR:"*) ;; *) warn "$BIN_DIR is not on PATH" ;; esac
