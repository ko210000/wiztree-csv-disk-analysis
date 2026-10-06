#!/usr/bin/env bash
# Analyze a WizTree 4.x CSV export (full-path folder rollups + file rows).
# Usage:
#   wiztree-analyze.sh <csv> dirs  <prefix>          # immediate subfolders of <prefix>, by size (top 40)
#   wiztree-analyze.sh <csv> files <prefix> [topN]   # largest individual files under <prefix> (default 30)
# <prefix> example: "C:" or "C:\Users\<user>\AppData" (case-insensitive, trailing backslash optional)
set -euo pipefail

CSV="${1:?usage: wiztree-analyze.sh <csv> dirs|files <prefix> [topN]}"
CMD="${2:?missing command (dirs|files)}"
PREFIX="${3:?missing prefix}"
N="${4:-30}"

# normalize prefix: uppercase drive letter, strip trailing backslashes
PREFIX="$(printf '%s' "$PREFIX" | sed -e 's/\\\+$//' -e 's/^\([a-z]\):/\U\1:/')"

PREFIX="$PREFIX" N="$N" awk -v cmd="$CMD" '
BEGIN { prefix = ENVIRON["PREFIX"] }
{
  if (!match($0, /^"([^"]*)"/)) next
  p = substr($0, RSTART + 1, RLENGTH - 2)
  rest = substr($0, RSTART + RLENGTH + 1)   # size,alloc,mtime,attr,files,folders
  split(rest, f, ",")
  size = f[1] + 0
  isdir = (p ~ /\\$/)
  pn = p; sub(/\\+$/, "", pn)
  pl = tolower(pn); pre = tolower(prefix)

  if (cmd == "dirs") {
    if (pl == pre) { total = size; totaldir = isdir; next }
    if (!isdir) next
    if (substr(pl, 1, length(pre) + 1) != pre "\\") next
    rem = substr(pn, length(prefix) + 2)
    if (rem !~ /\\/) printf "%12.2f|%8.2f GB  %s\\\n", size, size / 1073741824, pn
  } else if (cmd == "files") {
    if (isdir) next
    if (pl == pre || substr(pl, 1, length(pre) + 1) == pre "\\")
      printf "%12.2f|%8.2f GB  %s\n", size, size / 1073741824, p
  }
}
END {
  if (cmd == "dirs" && totaldir)
    printf "ZZZZZZZZZZZZ|TOTAL %s = %.2f GB\n", prefix, total / 1073741824
}
' "$CSV" | sort -t'|' -k1,1nr | head -n "$N" | cut -d'|' -f2-
