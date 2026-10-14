#!/bin/sh
# Install user-level skills and personal context loaders. Rerun to update.
set -eu
[ "$#" -eq 0 ] || { printf 'error: installer takes no options\n' >&2; exit 1; }
command -v git >/dev/null 2>&1 || { printf 'error: Git is required\n' >&2; exit 1; }
umask 077
INSTALL_CWD=$(pwd -P)
TMP=$(mktemp -d)
LOCK_HELD=
trap 'rm -rf "$TMP"; if [ -n "$LOCK_HELD" ]; then rmdir "$LOCK_HELD"; fi' EXIT
trap 'exit 130' INT
trap 'exit 143' HUP TERM
REF=${AGENTS_CONTROL_REF:-main}
if [ -n "${AGENTS_CONTROL_SOURCE:-}" ]; then
  SOURCE=$(cd "$AGENTS_CONTROL_SOURCE" && pwd -P)
else
  SOURCE=$TMP/download
  git clone --quiet --depth 1 --branch "$REF" https://github.com/patrickfleith/agents-control.git "$SOURCE"
fi
[ -f "$SOURCE/skills/ac-init/SKILL.md" ] || { printf 'error: source is not a private agents-control release\n' >&2; exit 1; }
. "$SOURCE/lib/context.sh"
. "$SOURCE/lib/install.sh"
USER_ROOT=$(ac_install_path "${AGENTS_CONTROL_USER_HOME:-$HOME}")
AC_HOME=$(ac_install_path "${AGENTS_CONTROL_HOME:-$USER_ROOT/.agents-control}")
BIN_DIR=$(ac_install_path "${AGENTS_CONTROL_BIN_DIR:-$USER_ROOT/.local/bin}")
CODEX_DIR=$(ac_install_path "${AGENTS_CONTROL_CODEX_HOME:-${CODEX_HOME:-$USER_ROOT/.codex}}")
for directory in "$AC_HOME" "$BIN_DIR" "$CODEX_DIR"; do
  [ "$directory" != / ] || ac_die 'installation destination cannot be /'
  ac_safe_path "$directory"
done
[ "$AC_HOME" != "$SOURCE" ] || ac_die 'install data cannot replace the source checkout'
if [ -d "$AC_HOME/install.lock" ]; then ac_die "another install is running or stopped; inspect $AC_HOME/install.lock first"; fi
mkdir -p "$AC_HOME"
mkdir "$AC_HOME/install.lock" || ac_die 'another installer is running'
LOCK_HELD=$AC_HOME/install.lock
# Older operations need their old recovery tool before this installer can replace it.
for pending in "$AC_HOME/operations/install/current/pending" "$AC_HOME"/operations/*/current/pending; do
  [ ! -e "$pending" ] || ac_die 'finish the previous operation with the previous release before upgrading'
done
RECORD=$AC_HOME/install.tsv
ac_safe_path "$RECORD"
[ ! -e "$RECORD" ] || [ -f "$RECORD" ] || ac_die 'install.tsv must be a regular file'
if [ -f "$RECORD" ]; then
  awk -F '\t' '/^#/ {next} NF!=3 || seen[$1]++ || $2 !~ /^[FDLB]$/ || $3 !~ /^(file|dir|link|block):[0-9]+:[0-9]+$/ {exit 1}' "$RECORD" || ac_die 'invalid install ownership record'
  cp "$RECORD" "$TMP/record"
else printf '# agents-control ownership schema=1\n' > "$TMP/record"; fi
: > "$TMP/plan"
plan() {
  destination=$1; payload=$2; kind=$3
  ac_safe_path "$(dirname "$destination")"
  ac_text_path "$destination"
  current=$(ac_fingerprint "$destination" "$kind")
  expected=$(AC_LOOKUP=$destination awk -F '\t' '$1==ENVIRON["AC_LOOKUP"] {print $3}' "$TMP/record")
  if [ "$kind" = X ]; then
    [ "$current" != missing ] || return 0
    if [ -z "$expected" ] || [ "$current" != "$expected" ]; then
      printf 'Preserved old personal skill with local edits: %s\n' "$destination" >&2
      return 0
    fi
    next=missing
  else
    next=$(ac_fingerprint "$payload" "$kind")
    if [ "$current" != missing ] && [ "$current" != "$expected" ] && [ "$current" != "$next" ]; then
      ac_die "preserved conflicting or edited file: $destination. Move it aside after reviewing it, then rerun the installer"
    fi
  fi
  printf '%s\t%s\t%s\t%s\n' "$destination" "$payload" "$kind" "$current" >> "$TMP/plan"
  AC_LOOKUP=$destination awk -F '\t' '$1!=ENVIRON["AC_LOOKUP"]' "$TMP/record" > "$TMP/record.next"
  mv "$TMP/record.next" "$TMP/record"
  [ "$next" = missing ] || printf '%s\t%s\t%s\n' "$destination" "$kind" "$next" >> "$TMP/record"
}
RUNTIME=$TMP/runtime
mkdir "$RUNTIME"
for entry in bin lib templates skills docs install.sh README.md LICENSE; do cp -RP "$SOURCE/$entry" "$RUNTIME/"; done
git -C "$SOURCE" rev-parse --short HEAD > "$RUNTIME/.agents-control-version" 2>/dev/null || printf '%s\n' "$REF" > "$RUNTIME/.agents-control-version"
plan "$AC_HOME/toolkit" "$RUNTIME" D
ln -s "$AC_HOME/toolkit/bin/agents-control" "$TMP/launcher"
plan "$BIN_DIR/agents-control" "$TMP/launcher" L
for skill in $AC_SKILLS; do
  for directory in "$USER_ROOT/.agents/skills" "$USER_ROOT/.claude/skills"; do
    plan "$directory/$skill" "$RUNTIME/skills/$skill" D
  done
done
# Retire the former setup name only when it is still owned and unedited.
for directory in "$USER_ROOT/.agents/skills" "$USER_ROOT/.claude/skills"; do
  plan "$directory/agents-control" '-' X
done
cat > "$TMP/loader" <<'DOC'
<!-- agents-control:start -->
## Personal agents-control context

When starting repository work, run `agents-control context` once if available.
It prints personal guidance only for a checkout set up with `agents-control init`.
Follow the project's instructions. Use `ac-` workflows for private notes and
resolve their paths with `agents-control resolve DOC`. If context is unavailable,
do not write personal notes into repository docs or invent a private path.
<!-- agents-control:end -->
DOC
if [ -s "$CODEX_DIR/AGENTS.override.md" ]; then GUIDANCE=$CODEX_DIR/AGENTS.override.md
else GUIDANCE=$CODEX_DIR/AGENTS.md; fi
for guidance in "$GUIDANCE" "$USER_ROOT/.claude/CLAUDE.md"; do
  if [ -L "$guidance" ]; then
    printf 'Preserved symlinked personal instructions: %s. Add the loader from %s/cursor-user-rule.md manually.\n' "$guidance" "$AC_HOME" >&2
  else plan "$guidance" "$TMP/loader" B; fi
done
plan "$AC_HOME/cursor-user-rule.md" "$TMP/loader" F
# All conflicts have been checked before changing installed code or skills.
TAB=$(printf '\t')
while IFS="$TAB" read -r destination payload kind before; do
  [ "$(ac_fingerprint "$destination" "$kind")" = "$before" ] || ac_die "file changed during installation: $destination"
  mkdir -p "$(dirname "$destination")"
  if [ "$kind" = X ]; then rm -rf "$destination"; continue; fi
  stage=$(mktemp -d "$(dirname "$destination")/.agents-control-install.XXXXXX")
  if [ "$kind" = B ]; then ac_merge_block "$destination" "$payload" > "$stage/new"
  else cp -RP "$payload" "$stage/new"; fi
  if ac_exists "$destination"; then mv "$destination" "$stage/old"; fi
  if ! mv "$stage/new" "$destination"; then
    [ ! -e "$stage/old" ] || mv "$stage/old" "$destination"
    ac_die "could not install $destination"
  fi
  rm -rf "$stage"
done < "$TMP/plan"
cp "$TMP/record" "$RECORD"
printf 'Installed agents-control and personal ac- skills.\nIn a project: agents-control init\nCursor: paste %s/cursor-user-rule.md into User Rules.\nRerun this installer to update. Private documents stay in each checkout.\n' "$AC_HOME"
case ":$PATH:" in *":$BIN_DIR:"*) ;; *) printf 'Add %s to PATH.\n' "$BIN_DIR" ;; esac
