# Small installer helpers. Ownership records protect locally edited artifacts.
ac_checksum() { cksum | awk '{print $1 ":" $2}'; }
ac_block() (
  [ -f "$1" ] || exit 0
  awk '
    $0=="<!-- agents-control:start -->" {if (active || seen++) exit 2; active=1}
    active {print}
    $0=="<!-- agents-control:end -->" {if (!active) exit 2; active=0; closed=1}
    END {if (active || (seen && !closed)) exit 2}
  ' "$1" || ac_die "damaged personal instruction block: $1"
)
# Keep the previous record format so unedited installations can update directly.
ac_fingerprint() (
  if [ "$2" = B ]; then
    body=$(ac_block "$1")
    if [ -n "$body" ]; then printf 'block:%s\n' "$(printf '%s\n' "$body" | ac_checksum)"
    else printf 'missing\n'; fi
  elif [ -L "$1" ]; then printf 'link:%s\n' "$(readlink "$1" | ac_checksum)"
  elif [ -f "$1" ]; then printf 'file:%s\n' "$(ac_checksum < "$1")"
  elif [ -d "$1" ]; then
    members=$(cd "$1" && find . -exec sh -c '
      for member do
        [ "$member" != . ] || continue
        if printf "%s" "$member" | LC_ALL=C grep "[[:cntrl:]]" >/dev/null; then exit 1; fi
        printf "%s\t" "$member"
        if [ -L "$member" ]; then printf "link:"; readlink "$member" | cksum
        elif [ -f "$member" ]; then printf "file:"; cksum < "$member"
        elif [ -d "$member" ]; then printf "directory\n"
        else exit 1; fi
      done
    ' sh {} +) || ac_die "unsupported installed resource: $1"
    printf 'dir:%s\n' "$(printf '%s\n' "$members" | LC_ALL=C sort | ac_checksum)"
  elif ac_exists "$1"; then ac_die "unsupported installed file: $1"
  else printf 'missing\n'; fi
)
ac_merge_block() (
  if [ ! -f "$1" ]; then cat "$2"; exit 0; fi
  if [ -z "$(ac_block "$1")" ]; then cat "$1"; printf '\n'; cat "$2"; exit 0; fi
  # Byte offsets preserve the user's text, including a missing final newline.
  range=$(LC_ALL=C awk '
    BEGIN {offset=0}
    $0=="<!-- agents-control:start -->" {start=offset}
    {offset+=length($0)+1}
    $0=="<!-- agents-control:end -->" {print start,offset}
  ' "$1")
  IFS=' ' read -r start end <<RANGE
$range
RANGE
  dd if="$1" bs=1 count="$start" 2>/dev/null
  cat "$2"
  dd if="$1" bs=1 skip="$end" 2>/dev/null
)
# Normalize system aliases such as /tmp before validating paths.
ac_install_path() (
  ac_text_path "$1"
  case $1 in /*) base=$1 ;; *) base=$INSTALL_CWD/$1 ;; esac
  suffix=
  while [ ! -d "$base" ]; do
    [ ! -L "$base" ] || ac_die "broken symlink: $base"
    suffix=/$(basename "$base")$suffix
    base=$(dirname "$base")
  done
  base=$(cd "$base" && pwd -P)
  printf '%s%s\n' "${base%/}" "$suffix"
)
