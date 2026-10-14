#!/bin/sh
# Owned generated artifacts and one recoverable file-operation mechanism.

ac_checksum() { cksum | awk '{print $1 ":" $2}'; }
ac_block() (
  [ -f "$1" ] || exit 0
  awk '
    $0=="<!-- agents-control:start -->" || $0=="# agents-control:start" {
      if (active || seen++) exit 2; active=1
    }
    active {print}
    $0=="<!-- agents-control:end -->" || $0=="# agents-control:end" {
      if (!active) exit 2; active=0; finished=1
    }
    END {if (active || (seen && !finished)) exit 2}
  ' "$1" || ac_die "duplicate or damaged agents-control block: $1"
)

ac_fingerprint() (
  if [ "$2" = B ]; then
    ac_body=$(ac_block "$1") || exit 1
    if [ -z "$ac_body" ]; then printf 'missing\n'
    else printf 'block:%s\n' "$(printf '%s\n' "$ac_body" | ac_checksum)"; fi
  elif [ -L "$1" ]; then
    printf 'link:%s\n' "$(readlink "$1" | ac_checksum)"
  elif [ -f "$1" ]; then
    printf 'file:%s\n' "$(ac_checksum < "$1")"
  elif [ -d "$1" ]; then
    ac_tree=$1
    ac_manifest=$(cd "$ac_tree" && find . -exec sh -c '
      for member do
        [ "$member" != . ] || continue
        case $member in *"
"*) exit 1 ;; esac
        if printf "%s" "$member" | LC_ALL=C grep "[[:cntrl:]]" >/dev/null; then exit 1; fi
        printf "%s\t" "$member"
        if [ -L "$member" ]; then
          printf "link:"; readlink "$member" | cksum
        elif [ -f "$member" ]; then
          printf "file:"; cksum < "$member" || exit 1
        elif [ -d "$member" ]; then printf "directory\n"
        else exit 1; fi
      done
    ' sh {} +) || ac_die "cannot fingerprint directory or unsupported member: $ac_tree"
    printf 'dir:%s\n' "$(printf '%s\n' "$ac_manifest" | LC_ALL=C sort | ac_checksum)"
  elif ac_exists "$1"; then ac_die "unsupported file type: $1"
  else printf 'missing\n'; fi
)

# Replace only the generated block; all surrounding text stays user-owned.
ac_merge_block() (
  ac_original=$1; ac_replacement=$2
  if [ -f "$ac_original" ]; then
    ac_block "$ac_original" >/dev/null
    if [ -n "$(ac_block "$ac_original")" ]; then
      ac_range=$(LC_ALL=C awk '
        BEGIN {offset=0}
        $0=="<!-- agents-control:start -->" || $0=="# agents-control:start" {start=offset}
        {offset+=length($0)+1}
        $0=="<!-- agents-control:end -->" || $0=="# agents-control:end" {print start,offset}
      ' "$ac_original")
      IFS=' ' read -r ac_start ac_end <<RANGE
$ac_range
RANGE
      dd if="$ac_original" bs=1 count="$ac_start" 2>/dev/null
      cat "$ac_replacement"
      dd if="$ac_original" bs=1 skip="$ac_end" 2>/dev/null
    else
      cat "$ac_original"
      if [ -s "$ac_replacement" ]; then printf '\n'; cat "$ac_replacement"; fi
    fi
  else cat "$ac_replacement"; fi
)

ac_owner_key() (
  if [ "${AC_OWNER_PORTABLE:-}" = 1 ]; then
    ac_within "$1" "$AC_OWNER_ROOT" || ac_die "portable ownership cannot contain external paths"
    printf '%s\n' "${1#"$AC_OWNER_ROOT"/}"
  else printf '%s\n' "$1"; fi
)

ac_owner_expected() (
  [ -f "$AC_OWNER_FILE" ] || exit 0
  ac_lookup=$(ac_owner_key "$1")
  AC_LOOKUP=$ac_lookup awk -F '\t' '$1==ENVIRON["AC_LOOKUP"] {print $2 "\t" $3}' "$AC_OWNER_FILE"
)

ac_owner_init() {
  AC_OWNER_NEXT=$AC_TMP/owners.$AC_OWNER_NUMBER
  AC_OWNER_NUMBER=$((AC_OWNER_NUMBER + 1))
  if ac_exists "$AC_OWNER_FILE"; then
    [ -f "$AC_OWNER_FILE" ] && [ ! -L "$AC_OWNER_FILE" ] || ac_die "ownership record must be a regular file"
    awk -F '\t' '/^#/ {next} NF!=3 || seen[$1]++ || $2 !~ /^[FDLB]$/ || $3 !~ /^(file|dir|link|block):[0-9]+:[0-9]+$/ {exit 1}' "$AC_OWNER_FILE" ||
      ac_die "invalid ownership record: $AC_OWNER_FILE"
    cp "$AC_OWNER_FILE" "$AC_OWNER_NEXT"
  else printf '# agents-control ownership schema=1\n' > "$AC_OWNER_NEXT"; fi
}

ac_owner_record() {
  ac_record_key=$(ac_owner_key "$1")
  AC_LOOKUP=$ac_record_key awk -F '\t' '$1!=ENVIRON["AC_LOOKUP"]' "$AC_OWNER_NEXT" > "$AC_OWNER_NEXT.new"
  mv "$AC_OWNER_NEXT.new" "$AC_OWNER_NEXT"
  if [ "$3" != missing ]; then printf '%s\t%s\t%s\n' "$ac_record_key" "$2" "$3" >> "$AC_OWNER_NEXT"; fi
}

ac_begin() {
  umask 077
  AC_TMP=$(mktemp -d "${TMPDIR:-/tmp}/agents-control.XXXXXX")
  AC_TMP=$(cd "$AC_TMP" && pwd -P)
  ac_within "$AC_TMP" "$AC_REPO" && ac_die "temporary directory must be outside the checkout"
  AC_ITEMS=$AC_TMP/items
  : > "$AC_ITEMS"
  AC_LATE_PATHS=$AC_TMP/late-paths
  : > "$AC_LATE_PATHS"
  AC_ITEM_NUMBER=0
  AC_OWNER_NUMBER=0
  AC_LOCK_HELD=
  trap 'rm -rf "$AC_TMP"; if [ -n "$AC_LOCK_HELD" ]; then rm -rf "$AC_LOCK_HELD"; fi' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM HUP
}

ac_validate_target() (
  ac_text_path "$1"
  [ "$1" != / ] || ac_die "cannot operate on the filesystem root"
  ac_absolute "$(dirname "$1")" >/dev/null
  if ac_exists "$(dirname "$1")" && [ ! -d "$(dirname "$1")" ]; then ac_die "target parent is not a directory"; fi
  if [ "${AC_NO_GIT:-}" != 1 ] && ac_overlap "$1" "$AC_GIT_COMMON"; then
    [ "$1" = "$AC_ALLOWED_EXCLUDE" ] || ac_die "cannot edit Git metadata except the exclusion block"
  fi
  case $1 in "$AC_REPO/.git"|"$AC_REPO/.git/"*)
    [ "$1" = "${AC_ALLOWED_EXCLUDE:-}" ] || ac_die "cannot edit Git metadata except the exclusion block" ;;
  esac
)

# Content operations need an explicit selection; generated operations need ownership.
ac_plan() {
  ac_plan_target=$1; ac_plan_source=$2; ac_plan_kind=$3; ac_plan_owned=$4
  ac_validate_target "$ac_plan_target"
  if [ "$ac_plan_owned" = owned ] && [ "${AC_OWNER_PORTABLE:-}" = 1 ]; then
    [ "$(ac_absolute "$(dirname "$ac_plan_target")")" = "$(dirname "$ac_plan_target")" ] ||
      ac_die "portable generated path uses a filesystem case alias: $ac_plan_target"
  fi
  if [ "$ac_plan_kind" = B ] && [ -L "$ac_plan_target" ]; then
    ac_die "symlinked guidance preserved; integrate the block into its intended source explicitly: $ac_plan_target"
  fi
  if AC_LOOKUP=$ac_plan_target awk -F '\t' '$2==ENVIRON["AC_LOOKUP"] {found=1} END {exit !found}' "$AC_ITEMS"; then
    ac_die "operation targets a path twice: $ac_plan_target"
  fi
  ac_plan_before=$(ac_fingerprint "$ac_plan_target" "$ac_plan_kind")
  if [ "$ac_plan_owned" = owned ]; then
    ac_expected=$(ac_owner_expected "$ac_plan_target")
    if [ "$ac_plan_before" != missing ]; then
      if [ -z "$ac_expected" ]; then
        [ "${AC_ADOPT:-}" = 1 ] || ac_die "unowned generated artifact: $ac_plan_target; use an explicit migration --adopt preview"
      else
        ac_expected_kind=${ac_expected%%"$AC_TAB"*}
        ac_expected_fingerprint=${ac_expected#*"$AC_TAB"}
        if [ "$ac_expected_kind" = B ] && [ "$ac_plan_kind" != B ]; then ac_die "a managed block does not own its surrounding file"; fi
        [ "$ac_expected_fingerprint" = "$ac_plan_before" ] ||
          ac_die "edited generated artifact preserved: $ac_plan_target"
      fi
    fi
  fi
  AC_ITEM_NUMBER=$((AC_ITEM_NUMBER + 1))
  ac_plan_id=$AC_ITEM_NUMBER
  if [ "$ac_plan_kind" = B ]; then
    cp "$ac_plan_source" "$AC_TMP/body.$ac_plan_id"
    ac_merge_block "$ac_plan_target" "$ac_plan_source" > "$AC_TMP/after.$ac_plan_id"
    ac_plan_after=$(ac_fingerprint "$AC_TMP/after.$ac_plan_id" B)
  elif [ "$ac_plan_source" = - ]; then
    ac_plan_after=missing
  else
    cp -RP "$ac_plan_source" "$AC_TMP/after.$ac_plan_id"
    ac_plan_after=$(ac_fingerprint "$AC_TMP/after.$ac_plan_id" "$ac_plan_kind")
  fi
  if [ "$ac_plan_owned" = owned ]; then ac_owner_record "$ac_plan_target" "$ac_plan_kind" "$ac_plan_after"; fi
  if [ "$ac_plan_before" = "$ac_plan_after" ]; then return 0; fi
  printf '%s\t%s\t%s\t%s\t%s\n' "$ac_plan_id" "$ac_plan_target" "$ac_plan_kind" "$ac_plan_before" "$ac_plan_after" >> "$AC_ITEMS"
}

ac_owner_finish() {
  ac_late_plan "$AC_OWNER_FILE" "$AC_OWNER_NEXT" F content
}

ac_late_plan() {
  ac_plan "$@"
  printf '%s\n' "$1" >> "$AC_LATE_PATHS"
}

ac_operation_paths() {
  AC_COMMON=$AC_GIT_COMMON
  AC_ALLOWED_EXCLUDE=$AC_COMMON/info/exclude
  ac_id=$(printf '%s' "$AC_COMMON" | ac_checksum | tr : -)
  AC_JOURNAL=$AC_HOME/operations/$ac_id/current
  AC_LOCK=$AC_COMMON/agents-control.lock
  AC_PENDING=$AC_COMMON/agents-control.pending
}

ac_token() (
  printf '%s\n' "$AC_REPO" "$AC_ACTION"
  cat "$AC_ITEMS"
  while IFS="$AC_TAB" read -r ac_id ac_target ac_kind ac_before ac_after; do
    if [ "$ac_kind" = B ]; then printf '%s\n' "$(ac_fingerprint "$ac_target" F)"; fi
    if [ "${AC_NO_GIT:-}" != 1 ] && ac_within "$ac_target" "$AC_REPO"; then
      git -C "$AC_REPO" ls-files --stage -- ":(icase,literal)${ac_target#"$AC_REPO"/}" || ac_die "cannot read the Git index"
    fi
  done < "$AC_ITEMS"
  for ac_dependency in "$AC_TEAM" "$AC_LOCAL"; do
    [ -z "$ac_dependency" ] || printf '%s\t%s\n' "$ac_dependency" "$(ac_fingerprint "$ac_dependency" F)"
  done
)

ac_preview() {
  # Commit configuration and ownership after every content/generated write.
  awk -F '\t' 'FILENAME==ARGV[1] {late[$0]=1; next} {
    if ($2 in late) deferred=deferred $0 "\n"; else print
  } END {printf "%s",deferred}' "$AC_LATE_PATHS" "$AC_ITEMS" > "$AC_ITEMS.ordered"
  mv "$AC_ITEMS.ordered" "$AC_ITEMS"
  ac_preconditions=$(ac_token) || ac_die "cannot build preview preconditions"
  AC_TOKEN=$(printf '%s\n' "$ac_preconditions" | ac_checksum | tr : -)
  printf '%s preview for %s\n' "$AC_ACTION" "$AC_REPO"
  while IFS="$AC_TAB" read -r ac_id ac_target ac_kind ac_before ac_after; do
    printf '\n%s: %s -> %s\n' "$ac_target" "$ac_before" "$ac_after"
    if [ "$ac_kind" = D ]; then
      if [ -d "$ac_target" ] && [ ! -L "$ac_target" ]; then
        if [ "$ac_after" = missing ]; then mkdir -p "$AC_TMP/after.$ac_id"; fi
        diff -ruN "$ac_target" "$AC_TMP/after.$ac_id" || [ $? -eq 1 ]
      elif [ "$ac_after" != missing ]; then
        printf 'Directory contents:\n'
        (cd "$AC_TMP/after.$ac_id" && find . -type f -print | LC_ALL=C sort)
      fi
    elif [ "$ac_kind" = F ] || [ "$ac_kind" = B ]; then
      if [ -f "$ac_target" ]; then ac_old=$ac_target; else ac_old=/dev/null; fi
      if [ "$ac_after" != missing ]; then ac_new=$AC_TMP/after.$ac_id; else ac_new=/dev/null; fi
      diff -u "$ac_old" "$ac_new" || [ $? -eq 1 ]
    elif [ "$ac_kind" = L ]; then
      if [ -L "$ac_target" ]; then printf 'Current link: %s\n' "$(readlink "$ac_target")"; fi
      if [ "$ac_after" != missing ]; then printf 'Intended link: %s\n' "$(readlink "$AC_TMP/after.$ac_id")"; fi
    fi
    if [ "${AC_NO_GIT:-}" != 1 ] && ac_within "$ac_target" "$AC_REPO"; then
      ac_relative=${ac_target#"$AC_REPO"/}
      ac_indexed=$(ac_index_files "$ac_relative") || ac_die "cannot inspect tracking"
      if [ -n "$ac_indexed" ]; then
        printf 'Tracking: already indexed; review and stage the change explicitly.\n'
      else printf 'Tracking: currently untracked; stage only if intended for sharing.\n'; fi
    fi
  done < "$AC_ITEMS"
  printf '\nPrecondition token: %s\nApply by repeating this command with --apply --expect=%s\n' "$AC_TOKEN" "$AC_TOKEN"
}

ac_write_item() (
  ac_target=$1; ac_payload=$2; ac_after=$3
  ac_validate_target "$ac_target"
  if [ "$ac_after" = missing ]; then rm -rf "$ac_target"; exit 0; fi
  mkdir -p "$(dirname "$ac_target")"
  ac_stage=$(mktemp -d "$(dirname "$ac_target")/.agents-control-write.XXXXXX")
  trap 'rm -rf "$ac_stage"' EXIT HUP INT TERM
  printf '%s\t%s\t%s\t%s\n' "$ac_target" "$ac_stage" \
    "$(ac_fingerprint "$ac_target" F)" "$(ac_fingerprint "$ac_payload" F)" >> "$AC_JOURNAL/staging"
  if [ -f "$ac_payload" ] && [ ! -L "$ac_payload" ] && [ -f "$ac_target" ] && [ ! -L "$ac_target" ]; then
    cp -p "$ac_target" "$ac_stage/value"
    cat "$ac_payload" > "$ac_stage/value"
  else
    cp -RPp "$ac_payload" "$ac_stage/value"
    if [ "${AC_NO_GIT:-}" != 1 ] && ac_within "$ac_target" "$AC_REPO" &&
       { [ -z "$AC_PRIVATE" ] || ! ac_within "$ac_target" "$AC_PRIVATE"; } &&
       [ -f "$ac_stage/value" ] && [ ! -L "$ac_stage/value" ]; then
      chmod a+r "$ac_stage/value"
    fi
  fi
  if [ -d "$ac_target" ] && [ ! -L "$ac_target" ]; then
    mv "$ac_target" "$ac_stage/previous"
    if [ "${AGENTS_CONTROL_TEST_KILL_AFTER_REMOVE:-}" = 1 ]; then sh -c 'kill -KILL "$PPID"'; fi
  elif [ -d "$ac_stage/value" ] && [ -L "$ac_target" ]; then
    rm "$ac_target"
  fi
  mv -f "$ac_stage/value" "$ac_target"
)

# A killed writer cannot run its cleanup trap. Validate its recorded directory
# before recovery, and remove only the verified toolkit files after recovery.
ac_staging() (
  [ -f "$AC_JOURNAL/staging" ] || exit 0
  [ ! -L "$AC_JOURNAL/staging" ] || ac_die "staging record is not a regular file"
  awk -F '\t' 'NF!=4 {exit 1}' "$AC_JOURNAL/staging" || ac_die "invalid staging record"
  while IFS="$AC_TAB" read -r ac_target ac_stage ac_original ac_intended; do
    ac_validate_target "$ac_target"
    case $ac_stage in "$(dirname "$ac_target")"/.agents-control-write.*) ;;
      *) ac_die "invalid staging location" ;;
    esac
    ac_absolute "$ac_stage" >/dev/null
    ac_exists "$ac_stage" || continue
    [ -d "$ac_stage" ] || ac_die "staging directory was changed: $ac_stage"
    for ac_member in "$ac_stage"/* "$ac_stage"/.[!.]* "$ac_stage"/..?*; do
      ac_exists "$ac_member" || continue
      case $(basename "$ac_member") in
        previous) ac_expected=$ac_original ;; value) ac_expected=$ac_intended ;;
        *) ac_die "unrelated file in staging directory: $ac_member" ;;
      esac
      [ "$(ac_fingerprint "$ac_member" F)" = "$ac_expected" ] ||
        ac_die "partial write or newer edit in staging directory; reconcile it before recovery: $ac_member"
    done
    if [ "$1" = cleanup ]; then rm -rf "$ac_stage"; fi
  done < "$AC_JOURNAL/staging"
)

ac_apply() {
  ac_operation_paths
  ! ac_exists "$AC_JOURNAL/pending" || ac_die "an operation needs recovery; run agents-control recover --resume or --restore"
  [ -z "${AC_PENDING:-}" ] || ! ac_exists "$AC_PENDING" ||
    ac_die "an interrupted operation needs recovery from its original worktree and state root"
  [ "${AC_EXPECT:-}" = "$AC_TOKEN" ] || ac_die "stale or missing preview token; preview the operation again"
  if [ ! -s "$AC_ITEMS" ]; then printf 'No changes. Existing recovery record retained.\n'; return 0; fi
  mkdir "$AC_LOCK" 2>/dev/null || ac_die "another toolkit operation holds $AC_LOCK"
  AC_LOCK_HELD=$AC_LOCK
  printf '%s\n' "$$" > "$AC_LOCK/pid"
  [ -z "${AC_PENDING:-}" ] || ! ac_exists "$AC_PENDING" || ac_die "another operation needs recovery"
  ac_preconditions=$(ac_token) || ac_die "cannot recheck preview preconditions"
  [ "$(printf '%s\n' "$ac_preconditions" | ac_checksum | tr : -)" = "$AC_EXPECT" ] || ac_die "preview changed while acquiring the lock"
  while IFS="$AC_TAB" read -r ac_id ac_target ac_kind ac_before ac_after; do
    [ "$(ac_fingerprint "$ac_target" "$ac_kind")" = "$ac_before" ] ||
      ac_die "preview became stale: $ac_target"
  done < "$AC_ITEMS"
  ac_absolute "$AC_JOURNAL" >/dev/null
  rm -rf "$AC_JOURNAL"
  mkdir -p "$AC_JOURNAL"
  cp "$AC_ITEMS" "$AC_JOURNAL/items"
  ac_checksum < "$AC_ITEMS" > "$AC_JOURNAL/items.checksum"
  printf '%s\n' "$AC_REPO" > "$AC_JOURNAL/repo"
  while IFS="$AC_TAB" read -r ac_id ac_target ac_kind ac_before ac_after; do
    if ac_exists "$ac_target"; then cp -RPp "$ac_target" "$AC_JOURNAL/before.$ac_id"; fi
    if [ "$ac_after" != missing ] || [ "$ac_kind" = B ]; then cp -RPp "$AC_TMP/after.$ac_id" "$AC_JOURNAL/after.$ac_id"; fi
  done < "$AC_ITEMS"
  : > "$AC_JOURNAL/pending"
  if [ -n "${AC_PENDING:-}" ]; then printf '%s\n' "$AC_JOURNAL" > "$AC_PENDING"; fi
  ac_written=0
  while IFS="$AC_TAB" read -r ac_id ac_target ac_kind ac_before ac_after; do
    [ "$(ac_fingerprint "$ac_target" "$ac_kind")" = "$ac_before" ] ||
      ac_die "file changed during apply; recover before continuing: $ac_target"
    printf '%s\n' "$ac_id" > "$AC_JOURNAL/in-flight"
    if [ "$ac_kind" = B ]; then
      ac_block "$AC_JOURNAL/after.$ac_id" > "$AC_TMP/apply-block"
      ac_merge_block "$ac_target" "$AC_TMP/apply-block" > "$AC_TMP/apply-file"
      ac_write_item "$ac_target" "$AC_TMP/apply-file" "$(ac_fingerprint "$AC_TMP/apply-file" F)"
    else ac_write_item "$ac_target" "$AC_JOURNAL/after.$ac_id" "$ac_after"; fi
    [ "$(ac_fingerprint "$ac_target" "$ac_kind")" = "$ac_after" ] || ac_die "write verification failed: $ac_target"
    printf '%s\n' "$ac_id" >> "$AC_JOURNAL/completed"
    rm "$AC_JOURNAL/in-flight"
    ac_written=$((ac_written + 1))
    if [ "${AGENTS_CONTROL_TEST_FAIL_AFTER:-}" = "$ac_written" ]; then ac_die "injected interruption; recovery record saved"; fi
  done < "$AC_ITEMS"
  rm "$AC_JOURNAL/pending"
  [ -z "${AC_PENDING:-}" ] || rm -f "$AC_PENDING"
  printf '\nApplied. Git staging was not changed. Recovery record: %s\n' "$AC_JOURNAL"
}

ac_recover() {
  ac_operation_paths
  ac_absolute "$AC_JOURNAL" >/dev/null
  [ -f "$AC_JOURNAL/items" ] || ac_die "no recovery record"
  [ "$(ac_checksum < "$AC_JOURNAL/items")" = "$(cat "$AC_JOURNAL/items.checksum")" ] ||
    ac_die "recovery record was edited"
  [ "$(cat "$AC_JOURNAL/repo")" = "$AC_REPO" ] || ac_die "recover from the operation's original worktree"
  if [ -n "${AC_PENDING:-}" ] && ac_exists "$AC_PENDING"; then
    [ -f "$AC_PENDING" ] && [ ! -L "$AC_PENDING" ] || ac_die "pending marker is not a regular file"
    [ "$(cat "$AC_PENDING")" = "$AC_JOURNAL" ] || ac_die "recover using the interrupted operation's original state root"
  fi
  mkdir "$AC_LOCK" 2>/dev/null || ac_die "another operation holds the lock; verify its PID before removing a stale lock"
  AC_LOCK_HELD=$AC_LOCK
  printf '%s\n' "$$" > "$AC_LOCK/pid"
  # Validate every target first, so a conflict never causes a partial recovery.
  while IFS="$AC_TAB" read -r ac_id ac_target ac_kind ac_before ac_after; do
    for ac_side in before after; do
      if [ "$ac_side" = before ]; then ac_snapshot_expected=$ac_before; else ac_snapshot_expected=$ac_after; fi
      if [ "$ac_snapshot_expected" != missing ]; then
        [ "$(ac_fingerprint "$AC_JOURNAL/$ac_side.$ac_id" "$ac_kind")" = "$ac_snapshot_expected" ] ||
          ac_die "recovery snapshot was edited: $ac_side.$ac_id"
      fi
    done
    ac_current=$(ac_fingerprint "$ac_target" "$ac_kind")
    if [ "$ac_current" = missing ] && [ -f "$AC_JOURNAL/in-flight" ] &&
       [ "$(cat "$AC_JOURNAL/in-flight")" = "$ac_id" ]; then continue; fi
    [ "$ac_current" = "$ac_before" ] || [ "$ac_current" = "$ac_after" ] ||
      ac_die "newer user edit prevents recovery: $ac_target"
  done < "$AC_JOURNAL/items"
  ac_staging validate
  while IFS="$AC_TAB" read -r ac_id ac_target ac_kind ac_before ac_after; do
    if [ "$AC_RECOVERY" = resume ]; then
      ac_desired=$ac_after; ac_snapshot=$AC_JOURNAL/after.$ac_id
    else ac_desired=$ac_before; ac_snapshot=$AC_JOURNAL/before.$ac_id; fi
    if [ "$(ac_fingerprint "$ac_target" "$ac_kind")" != "$ac_desired" ]; then
      printf '%s\n' "$ac_id" > "$AC_JOURNAL/in-flight"
      if [ "$ac_kind" = B ]; then
        if [ "$AC_RECOVERY" = resume ]; then ac_other=$AC_JOURNAL/before.$ac_id
        else ac_other=$AC_JOURNAL/after.$ac_id; fi
        if [ "$(ac_fingerprint "$ac_target" F)" = "$(ac_fingerprint "$ac_other" F)" ]; then
          ac_write_item "$ac_target" "$ac_snapshot" "$(ac_fingerprint "$ac_snapshot" F)"
        else
          ac_block "$ac_snapshot" > "$AC_TMP/restore-block"
          ac_merge_block "$ac_target" "$AC_TMP/restore-block" > "$AC_TMP/restore-file"
          if [ ! -e "$ac_snapshot" ] && [ ! -s "$AC_TMP/restore-file" ]; then
            ac_write_item "$ac_target" - missing
          else ac_write_item "$ac_target" "$AC_TMP/restore-file" "$(ac_fingerprint "$AC_TMP/restore-file" F)"; fi
        fi
      else ac_write_item "$ac_target" "$ac_snapshot" "$ac_desired"; fi
      [ "$(ac_fingerprint "$ac_target" "$ac_kind")" = "$ac_desired" ] || ac_die "recovery write verification failed"
      rm -f "$AC_JOURNAL/in-flight"
    fi
  done < "$AC_JOURNAL/items"
  ac_staging cleanup
  rm -f "$AC_JOURNAL/pending"
  rm -f "$AC_JOURNAL/in-flight"
  [ -z "${AC_PENDING:-}" ] || rm -f "$AC_PENDING"
  printf 'Recovery %s complete. Git staging was not changed.\n' "$AC_RECOVERY"
}
