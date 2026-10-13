#!/usr/bin/env bash
# Structural validation for agy. No frameworks, no fixtures.
set -uo pipefail
cd "$(dirname "$0")" || exit 1

fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

marketplace_ok=0

echo "== manifests =="
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
  if [ ! -f "$f" ]; then bad "missing $f"; continue; fi
  if python3 -c "import json,sys;json.load(open(sys.argv[1]))" "$f" 2>/dev/null; then
    ok "$f parses"
    if [ "$f" = ".claude-plugin/marketplace.json" ]; then
      marketplace_ok=1
    fi
  else
    bad "$f is not valid JSON"
  fi
done

if [ "$marketplace_ok" -eq 1 ]; then
  python3 - <<'PY' || fail=1
import json
import sys
try:
  m = json.load(open('.claude-plugin/marketplace.json'))
  plugins = m.get('plugins', [])
  assert len(plugins) == 1, f"expected 1 plugin entry, got {len(plugins)}"
  assert plugins[0]['name'] == 'agy', f"plugin name must be 'agy', got {plugins[0]['name']!r}"
  assert plugins[0]['source'] == './', f"source must be './', got {plugins[0]['source']!r}"
  print('  ok    marketplace entry: agy -> ./')
except (AssertionError, KeyError, IndexError, json.JSONDecodeError) as e:
  print(f'  FAIL  marketplace entry: {e}')
  sys.exit(1)
PY
fi

echo "== forbidden usage (stale third-party agy flags) =="
# Mentioning a dead flag is correct ("there is no --yolo flag in 1.1.22").
# Using one in an invocation is the bug. Match usage, not mention.
matches=$(grep -rIn -E 'agy .*--yolo' skills commands 2>/dev/null)
if [ -n "$matches" ]; then
  bad "--yolo used in an agy invocation:"
  printf '%s\n' "$matches" | head -3 | sed 's/^/         /'
else
  ok "no --yolo usage"
fi
for pat in 'gemini-1.5' 'gemini-2.0' '--approval-mode'; do
  matches=$(grep -rIn -F -- "$pat" skills commands 2>/dev/null)
  if [ -n "$matches" ]; then
    bad "forbidden string '$pat' present:"
    printf '%s\n' "$matches" | head -3 | sed 's/^/         /'
  else
    ok "no '$pat'"
  fi
done

echo "== invariants file =="
INV=skills/agy/references/invariants.md
if [ ! -f "$INV" ]; then
  bad "missing $INV"
else
  for needle in "-p='" 'silently ignores stdin' '--dangerously-skip-permissions' 'rtk proxy git diff' 'gemini-3.8-flash-high'; do
    if grep -qF -- "$needle" "$INV"; then ok "invariants documents: $needle"
    else bad "invariants missing: $needle"; fi
  done
fi

echo "== SKILL.md =="
S=skills/agy/SKILL.md
if [ ! -f "$S" ]; then
  bad "missing $S"
else
  python3 - <<'PY' || fail=1
import re, sys, os, yaml
try:
  p = 'skills/agy/SKILL.md'
  text = open(p, encoding='utf-8').read()
  if not text.startswith('---\n'):
      print('  FAIL  frontmatter must start at byte 0 with ---'); sys.exit(1)
  end = text.find('\n---\n', 3)
  if end == -1:
      print('  FAIL  frontmatter not closed with ---'); sys.exit(1)
  fm = yaml.safe_load(text[4:end])
  print('  ok    frontmatter parses as YAML')
  if fm.get('name') != 'agy':
      print(f"  FAIL  name must be agy, got {fm.get('name')!r}"); sys.exit(1)
  print('  ok    name: agy')
  desc = fm.get('description') or ''
  if not desc.strip():
      print('  FAIL  description is required and must be non-empty'); sys.exit(1)
  if len(desc) > 1024:
      print(f'  FAIL  description {len(desc)} chars, Hermes validator caps at 1024'); sys.exit(1)
  print(f'  ok    description present ({len(desc)} chars)')
  plats = fm.get('platforms') or []
  if 'windows' in plats:
      print('  FAIL  windows must not be listed (headless agy -p is broken there)'); sys.exit(1)
  print(f'  ok    platforms: {plats}')
  body = text[end:]
  links = sorted(set(re.findall(r'references/[A-Za-z0-9_.-]+\.md', body)))
  if not links:
      print('  FAIL  body must link at least one references/*.md file'); sys.exit(1)
  missing = [l for l in links if not os.path.isfile(os.path.join('skills/agy', l))]
  for l in links:
      print(('  ok    link resolves: ' if l not in missing else '  FAIL  link dangles: ') + l)
  if missing:
      sys.exit(1)
except Exception as e:
  print(f'  FAIL  unexpected error: {e}'); sys.exit(1)
PY
fi

echo "== command pointers =="
for c in setup review delegate research media; do
  f="commands/$c.md"
  if [ ! -f "$f" ]; then bad "missing $f"; continue; fi
  target="skills/agy/references/$c.md"
  if grep -qF "references/$c.md" "$f"; then
    if [ -f "$target" ]; then ok "$f -> $target"
    else bad "$f points at missing $target"; fi
  else
    bad "$f does not reference references/$c.md"
  fi
  grep -q '^description:' "$f" || bad "$f missing description in frontmatter"
done

echo "== docs =="
for f in README.md docs/HERMES.md; do
  [ -f "$f" ] && ok "$f present" || bad "missing $f"
done
if [ -f docs/HERMES.md ]; then
  grep -qiE 'untested|[Tt]ested on Hermes' docs/HERMES.md \
    && ok "HERMES.md states the Hermes path's verification status" \
    || bad "HERMES.md must state whether the Hermes path is tested"
  grep -q 'hermes skills tap add' docs/HERMES.md \
    && ok "HERMES.md documents tap install" \
    || bad "HERMES.md missing tap install command"
  # Spec §5 mitigation 3: the accepted name collision must be stated plainly.
  grep -q 'cc-tmux-agents' docs/HERMES.md \
    && ok "HERMES.md names the known agy collision holders" \
    || bad "HERMES.md must name the skills already using 'agy' (spec §5)"
  grep -q 'hermes skills list' docs/HERMES.md \
    && ok "HERMES.md tells the user to verify what installed" \
    || bad "HERMES.md must tell the user to verify with 'hermes skills list'"
fi

echo
if [ "$fail" -eq 0 ]; then echo "PASS"; else echo "FAIL"; fi
exit "$fail"
