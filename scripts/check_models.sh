#!/usr/bin/env bash
# check_models.sh [dir ...]
# Fail (exit 1) if any markdown file under the given dirs (default: skills/agy
# of this repo) names an agy model id that `agy models` does not list.
# Scanned: `--model <id>` literals (optionally 'quoted' or "quoted"), backticked
# model ids on any line, and bare model ids in markdown table cells.
# Exit 2 if the check could not run (agy missing / `agy models` failed/empty)
# or if no model ids were found at all (wrong directory?).
# Placeholders and prose (X, <id>, claude-*, claude-, "--model display") are
# ignored: an id must contain a digit.
# Never prints success unless the check really ran. Read-only; no hooks/cron.
# Example: scripts/check_models.sh path/to/other/skills/dir
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -eq 0 ] && set -- "$root/skills/agy"

command -v agy >/dev/null 2>&1 || { echo "check_models: agy not installed; cannot check model ids" >&2; exit 2; }
out="$(agy models 2>/dev/null)" || { echo "check_models: 'agy models' failed; cannot check model ids" >&2; exit 2; }
known="$(printf '%s\n' "$out" | awk -F'\t' 'NF>=2 && $1 ~ /^[A-Za-z0-9._-]+$/ {print $1}')"
[ -n "$known" ] || { echo "check_models: 'agy models' listed no models; cannot check" >&2; exit 2; }

for d in "$@"; do [ -d "$d" ] || { echo "check_models: not a directory: $d" >&2; exit 2; }; done

bad=0; n=0
# Each named dir must itself contain at least one model id reference.
for d in "$@"; do
  c="$(find "$d" -type f -name '*.md' -print0 | xargs -0 -r grep -hEc -e '--model|(gemini|claude|gpt)-[A-Za-z0-9._-]*[0-9]' 2>/dev/null | awk '{s+=$1} END{print s+0}')"
  [ "$c" -gt 0 ] || { echo "check_models: no model ids found in $d: wrong directory?" >&2; exit 2; }
done
while IFS=: read -r file line id; do
  [ -z "$id" ] && continue
  n=$((n+1))
  if ! printf '%s\n' "$known" | grep -qxF -- "$id"; then
    echo "UNKNOWN MODEL: $id  ($file:$line)" >&2; bad=1
  fi
done < <(
  for d in "$@"; do
    find "$d" -type f -name '*.md' -print0 | xargs -0 -r awk '
      function emit(id) { sub(/[.,;:)]+$/, "", id); if (id !~ /[*<>$]/ && id !~ /-$/ && id ~ /[0-9]/) print FILENAME ":" FNR ":" id }
      {
        s = $0
        while (match(s, /--model[ =]+["\047]?[A-Za-z0-9._*<>$-]+/)) {
          t = substr(s, RSTART, RLENGTH); sub(/--model[ =]+["\047]?/, "", t); emit(t)
          s = substr(s, RSTART + RLENGTH)
        }
        s = $0
        while (match(s, /`(gemini|claude|gpt)-[A-Za-z0-9._-]+`/)) {
          t = substr(s, RSTART + 1, RLENGTH - 2); emit(t)
          s = substr(s, RSTART + RLENGTH)
        }
        if ($0 ~ /^[ ]*\|/) {
          m = split($0, cells, "|")
          for (i = 1; i <= m; i++) {
            c = cells[i]; gsub(/^[ \t]+|[ \t]+$/, "", c)
            if (c ~ /^(gemini|claude|gpt)-[A-Za-z0-9._-]+$/) emit(c)
          }
        }
      }'
  done
)
if [ "$n" -eq 0 ]; then echo "check_models: no model ids found in $*: wrong directory?" >&2; exit 2; fi
if [ "$bad" -ne 0 ]; then echo "check_models: FAIL - model ids not in 'agy models' (see above)" >&2; exit 1; fi
echo "check_models: OK - $n model id reference(s) all listed by 'agy models'"
