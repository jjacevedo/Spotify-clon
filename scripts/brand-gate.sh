#!/usr/bin/env bash
# Brand gate (constraint 2 and replica/brand.md, Sweep). Exits non-zero on the first failure.
#   1. The original's names, domains and colours in the app's own folders (replica/brand.json).
#   2. The original's feature labels in the same folders.
#   3. The original's Title-case library label (case-sensitive; the sweep would also flag "your library").
#   4. WCAG AA contrast of both colour blocks of the design tokens.
set -euo pipefail

cd "$(dirname "$0")/.."

SWEEP=.claude/skills/replica-brand/sweep.py
CONTRAST=.claude/skills/replica-design/contrast.py
TOKENS=replica/design/tokens.json
FOLDERS=(apps/web packages)
LABELS="Liked Songs,Smart Shuffle,Discover Weekly,Daily Mix"

for folder in "${FOLDERS[@]}"; do
  echo "== sweep ${folder} --config replica/brand.json"
  python3 "$SWEEP" "$folder" --config replica/brand.json
done

for folder in "${FOLDERS[@]}"; do
  echo "== sweep ${folder} --avoid <feature labels>"
  python3 "$SWEEP" "$folder" --avoid "$LABELS"
done

echo "== Title-case label grep (apps, packages)"
if grep -rnI --exclude-dir=node_modules --exclude-dir=.next "Your Library" apps packages; then
  echo "brand-gate: the Title-case label above must not ship" >&2
  exit 1
fi
echo "Clean."

echo "== contrast: color (dark)"
python3 "$CONTRAST" "$TOKENS"

echo "== contrast: color-light"
light=$(mktemp)
trap 'rm -f "$light"' EXIT
python3 -c "import json,sys;t=json.load(open(sys.argv[1]));t['color']=t['color-light'];json.dump(t,open(sys.argv[2],'w'))" "$TOKENS" "$light"
python3 "$CONTRAST" "$light"

echo "brand-gate: all checks passed"
