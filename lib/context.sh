# Private document paths. POSIX shell and Git only.
AC_CORE='PRD STACK ROADMAP DECISIONS TASKS CHANGELOG'
AC_SKILLS='ac-init ac-log ac-decide ac-glossary ac-write-manual ac-commit ac-unslop'
ac_die() { printf 'error: %s\n' "$*" >&2; exit 1; }
ac_exists() { [ -e "$1" ] || [ -L "$1" ]; }

ac_text_path() {
  [ -n "$1" ] || ac_die 'empty path'
  if printf '%s' "$1" | LC_ALL=C grep '[[:cntrl:]]' >/dev/null; then
    ac_die 'paths cannot contain control characters'
  fi
  case /${1#/}/ in */../*|*/./*|*//*) ac_die "invalid path: $1" ;; esac
}
# Refuse symlinks at every component, including missing destinations.
ac_safe_path() {
  ac_text_path "$1"
  case $1 in /*) ;; *) ac_die "expected an absolute path: $1" ;; esac
  ac_path=$1
  while [ "$ac_path" != / ]; do
    [ ! -L "$ac_path" ] || ac_die "symlink path is unsupported: $ac_path"
    ac_path=$(dirname "$ac_path")
    if ac_exists "$ac_path" && [ ! -d "$ac_path" ]; then
      ac_die "parent is not a directory: $ac_path"
    fi
  done
}
ac_load() {
  AC_REPO=$(git rev-parse --show-toplevel 2>/dev/null) || return 1
  AC_REPO=$(cd "$AC_REPO" && pwd -P) || ac_die 'cannot read checkout root'
  ac_text_path "$AC_REPO"
  AC_PRIVATE=$AC_REPO/docs-agents-private
  ac_common=$(git rev-parse --git-common-dir) || ac_die 'cannot find Git metadata'
  AC_COMMON=$(cd "$ac_common" && pwd -P) || ac_die 'cannot read Git metadata'
  AC_EXCLUDE=$AC_COMMON/info/exclude
  ac_safe_path "$AC_PRIVATE"
  if ac_exists "$AC_PRIVATE" && [ ! -d "$AC_PRIVATE" ]; then
    ac_die 'docs-agents-private must be a directory'
  fi
}
ac_registered() {
  ac_safe_path "$AC_PRIVATE/AGENTS.md"
  [ -f "$AC_PRIVATE/AGENTS.md" ] &&
    grep -Fxq '<!-- agents-control:private -->' "$AC_PRIVATE/AGENTS.md"
}
ac_require_setup() {
  ac_registered || ac_die 'run agents-control init in this checkout first'
}
ac_doc() (
  ac_name=${1%.md}
  case $ac_name in
    PRD|STACK|ROADMAP|DECISIONS|TASKS|CHANGELOG|SUM|GLOSSARY|EVALUATIONS|TESTS|UXUI|DEPLOYMENT|IDEAS|CONCERNS|QUESTIONS)
      printf '%s.md\n' "$ac_name" ;;
    features/*/FRD|features/*/PLAN)
      ac_slug=${ac_name#features/}; ac_slug=${ac_slug%/*}
      case $ac_slug in ''|*[!a-zA-Z0-9_-]*) ac_die 'feature names use letters, numbers, hyphens or underscores' ;; esac
      printf '%s.md\n' "$ac_name" ;;
    *) ac_die "unknown document: $1" ;;
  esac
)
ac_guard_index() {
  ac_index=$(git -C "$AC_REPO" ls-files -- ':(icase,literal)docs-agents-private') || ac_die 'cannot read Git index'
  [ -z "$ac_index" ] || ac_die "private documents are in the Git index. Remove them from tracking before committing:\n$ac_index"
}
ac_context() {
  ac_registered || return 0
  printf 'Private agents-control context for %s\nDocuments: %s\n\n' "$AC_REPO" "$AC_PRIVATE"
  cat "$AC_PRIVATE/AGENTS.md"
}
