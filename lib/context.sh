#!/bin/sh
# Shared, read-only configuration and path resolution. Also runs from a clone.

AC_CORE="PRD STACK ROADMAP DECISIONS TASKS CHANGELOG"
AC_SHARED_DEFAULT="PRD STACK ROADMAP DECISIONS CHANGELOG SUM GLOSSARY EVALUATIONS TESTS UXUI DEPLOYMENT"
AC_SKILLS="commit log decide glossary write-manual unslop"
AC_TAB=$(printf '\t')

ac_die() { printf 'error: %s\n' "$*" >&2; exit 1; }
ac_exists() { [ -e "$1" ] || [ -L "$1" ]; }
ac_key() { awk -v key="$2" 'index($0,key "=")==1 {print substr($0,length(key)+2)}' "$1"; }

ac_text_path() (
  case $1 in ''|*"
"*|*"$AC_TAB"*) ac_die "invalid path: empty or contains a control character" ;; esac
  if printf '%s' "$1" | LC_ALL=C grep '[[:cntrl:]]' >/dev/null; then
    ac_die "paths cannot contain control characters"
  fi
  case /${1#/}/ in */../*|*/./*|*//*) ac_die "path traversal or empty path component: $1" ;; esac
)

# Resolve missing paths as well as existing ones, without following symlinks.
ac_absolute() (
  ac_text_path "$1"
  case $1 in /*) ac_path=$1 ;; *) ac_path=$AC_REPO/$1 ;; esac
  # macOS exposes these system directories through standard aliases.
  case $ac_path in
    /tmp/*) case $(readlink /tmp 2>/dev/null || :) in /private/tmp|private/tmp) ac_path=/private/tmp/${ac_path#/tmp/} ;; esac ;;
    /var/*) case $(readlink /var 2>/dev/null || :) in /private/var|private/var) ac_path=/private/var/${ac_path#/var/} ;; esac ;;
  esac
  ac_rest=${ac_path#/}
  ac_current=
  while [ -n "$ac_rest" ]; do
    case $ac_rest in */*) ac_part=${ac_rest%%/*}; ac_rest=${ac_rest#*/} ;;
      *) ac_part=$ac_rest; ac_rest= ;; esac
    ac_current=$ac_current/$ac_part
    [ ! -L "$ac_current" ] || ac_die "symlink path is unsupported: $ac_current"
    if [ -n "$ac_rest" ] && ac_exists "$ac_current" && [ ! -d "$ac_current" ]; then
      ac_die "path ancestor is not a directory: $ac_current"
    fi
  done
  # Use the filesystem's spelling for existing directories, including macOS
  # case aliases. Preserve the requested spelling of missing components.
  ac_base=$ac_path; ac_suffix=
  while [ ! -d "$ac_base" ]; do
    ac_suffix=/$(basename "$ac_base")$ac_suffix
    ac_base=$(dirname "$ac_base")
  done
  ac_base=$(cd "$ac_base" && pwd -P)
  printf '%s%s\n' "${ac_base%/}" "$ac_suffix"
)

ac_within() { case $1/ in "$2"/*) return 0 ;; *) return 1 ;; esac; }
ac_fold() { printf '%s' "$1" | LC_ALL=C tr '[:upper:]' '[:lower:]'; }
ac_overlap() (
  # Deny case-only scope distinctions even on a case-sensitive filesystem.
  ac_left=$(ac_fold "$1")
  ac_right=$(ac_fold "$2")
  ac_within "$ac_left" "$ac_right" || ac_within "$ac_right" "$ac_left"
)
ac_index_files() {
  git -C "${2:-$AC_REPO}" ls-files -- ":(icase,literal)$1" || ac_die "cannot read the Git index"
}

ac_doc() (
  ac_doc=${1%.md}
  case $ac_doc in
    README|PRD|STACK|ROADMAP|DECISIONS|TASKS|CHANGELOG|SUM|GLOSSARY|EVALUATIONS|TESTS|UXUI|DEPLOYMENT|IDEAS|CONCERNS|QUESTIONS)
      printf '%s.md\n' "$ac_doc" ;;
    features/*/FRD|features/*/PLAN)
      ac_slug=${ac_doc#features/}; ac_slug=${ac_slug%/*}
      case $ac_slug in ''|*[!a-zA-Z0-9_-]*) ac_die "invalid feature slug: $ac_slug" ;; esac
      printf '%s.md\n' "$ac_doc" ;;
    *) ac_die "unknown document: $1" ;;
  esac
)

ac_docs_valid() (
  case $1 in *[!a-zA-Z0-9_./\ -]*) ac_die "invalid document choice list" ;; esac
  ac_seen=" "
  for ac_name in $1; do
    ac_doc "$ac_name" >/dev/null
    case $ac_name in *.md) ac_die "document choices use names without .md: $ac_name" ;; esac
    case $ac_seen in *" $ac_name "*) ac_die "duplicate document choice: $ac_name" ;; esac
    ac_seen="$ac_seen$ac_name "
  done
)

ac_config_valid() (
  [ -f "$1" ] && [ ! -L "$1" ] || ac_die "configuration must be a regular file: $1"
  ac_absolute "$1" >/dev/null
  awk -v kind="$2" '
    /^[[:space:]]*#/ || /^$/ {next}
    {
      pos=index($0,"="); if (!pos) exit 1
      key=substr($0,1,pos-1)
      if (seen[key]++) exit 1
      if (key!="schema" && key!="shared_dir" && key!="shared_docs" && !(kind=="team" && key=="adapter_mode") &&
          !(kind=="personal" && (key=="repo_root" || key=="profile" || key=="private_dir"))) exit 1
    }
    END {if (!seen["schema"] || !seen["shared_dir"] || !seen["shared_docs"] ||
      (kind=="team" && !seen["adapter_mode"]) ||
      (kind=="personal" && (!seen["repo_root"] || !seen["profile"] || !seen["private_dir"]))) exit 1}
  ' "$1" || ac_die "invalid or duplicate configuration keys: $1"
  [ "$(ac_key "$1" schema)" = 1 ] || ac_die "unsupported configuration schema: $1"
  ac_shared=$(ac_key "$1" shared_dir)
  ac_text_path "$ac_shared"
  case $(ac_fold "$ac_shared") in /*|.git|.git/*|.agents|.agents/*|.claude|.claude/*|.cursor|.cursor/*|.agents-control|.agents-control/*)
    ac_die "shared_dir must be a repository-relative docs folder outside tool metadata" ;;
  esac
  ac_absolute "$ac_shared" >/dev/null
  ac_docs_valid "$(ac_key "$1" shared_docs)"
  if [ "$2" = personal ]; then
    case $(ac_key "$1" profile) in private|selected|team) ;; *) ac_die "invalid personal profile" ;; esac
    case $(ac_key "$1" repo_root) in /*) ;; *) ac_die "repo_root must be absolute" ;; esac
    ac_text_path "$(ac_key "$1" repo_root)"
    ac_absolute "$(ac_key "$1" private_dir)" >/dev/null
  else
    case $(ac_key "$1" adapter_mode) in copy|symlink) ;; *) ac_die "invalid adapter_mode" ;; esac
  fi
)

ac_legacy_mode() (
  ac_state=$AC_REPO/.agents/agents-control.json
  if ac_exists "$ac_state"; then
    [ -f "$ac_state" ] && [ ! -L "$ac_state" ] || ac_die "legacy adapter state must be a regular file"
    ac_absolute "$ac_state" >/dev/null
    ac_count=$(awk '{
      rest=$0; while(match(rest,/"adapter_mode"/)) {count++; rest=substr(rest,RSTART+RLENGTH)}
    } END {print count+0}' "$ac_state")
    [ "$ac_count" -le 1 ] || ac_die "duplicate legacy adapter_mode"
    if [ "$ac_count" = 1 ]; then
      ac_mode=$(sed -n 's/.*"adapter_mode"[[:space:]]*:[[:space:]]*"\([a-z]*\)".*/\1/p' "$ac_state")
      case $ac_mode in copy|symlink) printf '%s\n' "$ac_mode"; exit 0 ;;
        *) ac_die "invalid legacy adapter_mode" ;;
      esac
    fi
  fi
  for ac_adapter in "$AC_REPO"/.claude/skills/*; do
    if [ -L "$ac_adapter" ]; then printf 'symlink\n'; exit 0; fi
    if [ -d "$ac_adapter" ]; then printf 'copy\n'; exit 0; fi
  done
  printf 'copy\n'
)

ac_load() {
  AC_REPO=$(git rev-parse --show-toplevel 2>/dev/null) || ac_die "not a Git worktree"
  AC_REPO=$(cd "$AC_REPO" && pwd -P)
  ac_common=$(git rev-parse --git-common-dir)
  AC_GIT_COMMON=$(cd "$ac_common" && pwd -P)
  AC_HOME=${AGENTS_CONTROL_HOME:-$HOME/.agents-control}
  AC_HOME=$(ac_absolute "$AC_HOME")
  ac_within "$AC_HOME" "$AC_REPO" && ac_die "AGENTS_CONTROL_HOME must be outside the checkout"
  ac_overlap "$AC_HOME" "$AC_GIT_COMMON" && ac_die "AGENTS_CONTROL_HOME overlaps Git metadata"
  AC_ALLOWED_EXCLUDE=$AC_GIT_COMMON/info/exclude
  AC_TEAM=$AC_REPO/.agents-control/team.conf
  AC_LOCAL=
  AC_REGISTRY=
  AC_PROFILE=unconfigured
  AC_PRIVATE=
  AC_SHARED=$(ac_absolute "$AC_REPO/docs-agents-shared")
  AC_SHARED_DOCS=
  AC_ADAPTER=copy
  AC_LEGACY=
  AC_LEGACY_LAYOUT=
  if ac_exists "$AC_REPO/.agents/agents-control.json" || ac_exists "$AC_REPO/.claude/skills/.agents-control-managed"; then
    AC_LEGACY_LAYOUT=1
  fi
  for ac_registration in "$AC_HOME"/repos/*/repo.conf; do
    [ -f "$ac_registration" ] || continue
    if [ "$(ac_key "$ac_registration" repo_root)" = "$AC_REPO" ]; then
      [ -z "$AC_LOCAL" ] || ac_die "multiple registrations for $AC_REPO"
      ac_config_valid "$ac_registration" personal
      AC_LOCAL=$ac_registration
      AC_REGISTRY=${ac_registration%/repo.conf}
      AC_PROFILE=$(ac_key "$AC_LOCAL" profile)
      AC_PRIVATE=$(ac_absolute "$(ac_key "$AC_LOCAL" private_dir)")
      AC_SHARED=$(ac_absolute "$(ac_key "$AC_LOCAL" shared_dir)")
      if [ "$AC_PROFILE" = selected ]; then AC_SHARED_DOCS=$(ac_key "$AC_LOCAL" shared_docs); fi
    fi
  done
  if ac_exists "$AC_TEAM"; then
    ac_config_valid "$AC_TEAM" team
    AC_SHARED=$(ac_absolute "$(ac_key "$AC_TEAM" shared_dir)")
    AC_ADAPTER=$(ac_key "$AC_TEAM" adapter_mode)
    if [ "$AC_PROFILE" = unconfigured ]; then AC_PROFILE=team; fi
    if [ "$AC_PROFILE" = team ]; then AC_SHARED_DOCS=$(ac_key "$AC_TEAM" shared_docs); fi
  elif [ "$AC_PROFILE" = team ]; then
    ac_die "team configuration is missing; restore it before writing"
  elif [ -n "$AC_LEGACY_LAYOUT" ]; then
    AC_ADAPTER=$(ac_legacy_mode)
  fi
  if [ -n "$AC_PRIVATE" ]; then
    if ac_exists "$AC_PRIVATE" && [ ! -d "$AC_PRIVATE" ]; then ac_die "private storage is not a directory"; fi
    if ac_overlap "$AC_PRIVATE" "$AC_SHARED"; then
      ac_die "private and shared locations overlap"
    fi
    ac_overlap "$AC_PRIVATE" "$AC_GIT_COMMON" && ac_die "private storage overlaps Git metadata"
    case $AC_PRIVATE in "$AC_REPO/.git"|"$AC_REPO/.git/"*) ac_die "private storage cannot use Git metadata" ;; esac
  fi
  ac_overlap "$AC_SHARED" "$AC_GIT_COMMON" && ac_die "shared storage overlaps Git metadata"
  if ac_exists "$AC_SHARED" && [ ! -d "$AC_SHARED" ]; then ac_die "shared storage is not a directory"; fi
  if [ "$AC_PROFILE" = unconfigured ] && [ -n "$AC_LEGACY_LAYOUT" ]; then
    AC_LEGACY=1
    AC_PROFILE=legacy
  fi
}

ac_shared_path() {
  if [ "$1" = README.md ]; then printf '%s/README.md\n' "$AC_REPO"
  else printf '%s/%s\n' "$AC_SHARED" "$1"; fi
}

# Output is visibility<TAB>absolute-path. --path prints only the path.
ac_resolve() (
  ac_rel=$(ac_doc "$1"); shift
  ac_scope=; ac_read=; ac_path_only=
  for ac_arg in "$@"; do
    case $ac_arg in --scope=private|--scope=shared) ac_scope=${ac_arg#--scope=} ;;
      --read) ac_read=1 ;; --path) ac_path_only=1 ;;
      *) ac_die "unknown resolve option: $ac_arg" ;; esac
  done
  ac_emit() {
    ac_result_path=$(ac_absolute "$2") || exit 1
    [ -z "$ac_read" ] || [ -f "$ac_result_path" ] || ac_die "document is not a regular file: $ac_result_path"
    if [ -n "$ac_path_only" ]; then printf '%s\n' "$ac_result_path"
    else printf '%s\t%s\n' "$1" "$ac_result_path"; fi
  }
  if [ -n "$ac_read" ]; then
    if [ -n "$AC_PRIVATE" ] && ac_exists "$AC_PRIVATE/docs/$ac_rel" && [ "$ac_scope" != shared ]; then
      ac_emit private "$AC_PRIVATE/docs/$ac_rel"
    fi
    ac_candidate=$(ac_shared_path "$ac_rel")
    if ac_exists "$ac_candidate" && [ "$ac_scope" != private ]; then ac_emit shared "$ac_candidate"; fi
    if [ -n "$AC_LEGACY_LAYOUT" ] && [ -z "$ac_scope" ] &&
       [ "$AC_SHARED" != "$AC_REPO/docs-agents" ] && ac_exists "$AC_REPO/docs-agents/$ac_rel"; then
      ac_emit unclassified "$AC_REPO/docs-agents/$ac_rel"
    fi
    exit 0
  fi
  [ "$AC_PROFILE" != unconfigured ] || ac_die "repository is unconfigured; run agents-control init"
  [ "$AC_PROFILE" != legacy ] || ac_die "legacy layout requires an explicit migration before writing"
  if [ -z "$ac_scope" ]; then
    ac_scope=private
    [ "$ac_rel" != README.md ] || ac_scope=shared
    case " $AC_SHARED_DOCS " in *" ${ac_rel%.md} "*) ac_scope=shared ;; esac
    if [ "$ac_rel" = TASKS.md ]; then
      ac_team_tasks=
      case " $AC_SHARED_DOCS " in *" TASKS "*) ac_team_tasks=1 ;; esac
      if [ -f "$AC_TEAM" ]; then
        case " $(ac_key "$AC_TEAM" shared_docs) " in *" TASKS "*) ac_team_tasks=1 ;; esac
      fi
      if [ -n "$ac_team_tasks" ] || [ -f "$(ac_shared_path TASKS.md)" ]; then
        ac_die "task ownership is ambiguous; choose --scope=private or --scope=shared"
      fi
      ac_scope=private
    fi
  fi
  if [ "$ac_scope" = private ]; then
    [ -n "$AC_PRIVATE" ] || ac_die "private workspace unavailable; run agents-control init"
    ac_emit private "$AC_PRIVATE/docs/$ac_rel"
  else ac_emit shared "$(ac_shared_path "$ac_rel")"; fi
)

ac_context() {
  [ -n "$AC_LOCAL" ] || return 0
  printf 'Personal agents-control context for %s\nProfile: %s\n' "$AC_REPO" "$AC_PROFILE"
  printf 'Private docs: %s/docs\nShared docs: %s\n' "$AC_PRIVATE" "$AC_SHARED"
  printf 'Project guidance still applies. Read documents only when relevant to the task.\n'
  if [ -f "$AC_PRIVATE/AGENTS.md" ]; then cat "$AC_PRIVATE/AGENTS.md"; fi
}

ac_guard_index() (
  ac_common=$AC_GIT_COMMON
  ! ac_exists "$ac_common/agents-control.pending" ||
    ac_die "an interrupted operation must be recovered before committing"
  ac_operation_id=$(printf '%s' "$ac_common" | cksum | awk '{print $1 "-" $2}')
  ! ac_exists "$AC_HOME/operations/$ac_operation_id/current/pending" ||
    ac_die "an interrupted operation must be recovered before committing"
  [ -n "$AC_PRIVATE" ] || exit 0
  if ac_within "$AC_PRIVATE" "$AC_REPO"; then
    ac_relative=${AC_PRIVATE#"$AC_REPO"/}
    ac_indexed=$(ac_index_files "$ac_relative") || exit 1
    [ -z "$ac_indexed" ] ||
      ac_die "private files remain in the complete Git index; stage their removal explicitly"
  fi
  if [ -f "$AC_REGISTRY/state/retired-private" ]; then
    while IFS= read -r ac_retired; do
      ac_text_path "$ac_retired"
      if ac_within "$ac_retired" "$AC_REPO"; then
        ac_relative=${ac_retired#"$AC_REPO"/}
        ac_indexed=$(ac_index_files "$ac_relative") || exit 1
        [ -z "$ac_indexed" ] ||
          ac_die "retired private file remains in the index: $ac_relative; stage its removal explicitly"
      fi
    done < "$AC_REGISTRY/state/retired-private"
  fi
)

if [ "${AC_CONTEXT_LIBRARY:-}" != 1 ]; then
  set -eu
  ac_command=${1:-context}; [ $# -eq 0 ] || shift
  ac_load
  case $ac_command in
    resolve) [ $# -gt 0 ] || ac_die "resolve requires a document"; ac_resolve "$@" ;;
    context) [ $# -eq 0 ] || ac_die "context takes no arguments"; ac_context ;;
    guard-index) [ $# -eq 0 ] || ac_die "guard-index takes no arguments"; ac_guard_index ;;
    *) ac_die "unknown context command: $ac_command" ;;
  esac
fi
