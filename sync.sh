#!/usr/bin/env bash
# Sync this repo from the jfc-talk deck (branch clariphy-tutorial-2026-09-14) and make the tutorial cut the default view.
#   ./sync.sh            # copy + patch + show the diff stat
#   ./sync.sh --push     # ...and commit + push (Pages redeploys from main)
set -euo pipefail
SRC="${JFC_TALK:-$HOME/work/talks/jfc-talk}"
HERE="$(cd "$(dirname "$0")" && pwd)"
branch="$(git -C "$SRC" rev-parse --abbrev-ref HEAD)"
[ "$branch" = "clariphy-tutorial-2026-09-14" ] || { echo "jfc-talk is on '$branch', not the tutorial branch"; exit 1; }
rsync -a --delete "$SRC/assets/" "$HERE/assets/"
cp "$SRC/index.html" "$HERE/index.html"
python3 - "$HERE/index.html" <<'PY'
import sys; p=sys.argv[1]; s=open(p).read()
reps=[("const PROFILE_THEME = { tutorial: 'light' };",
       "const DEFAULT_PROFILE = 'tutorial';   // this repo serves the CLARIPHY tutorial cut; ?profile=none shows every scene\nconst PROFILE_THEME = { tutorial: 'light' };"),
      ("  const prof = qs.get('profile');\n", "  const prof = qs.get('profile') || (qs.has('skip') ? null : DEFAULT_PROFILE);   // this repo: the tutorial cut by default\n"),
      ("    const forced = qs.get('theme') || (qs.get('profile') && PROFILE_THEME[qs.get('profile')]);",
       "    const forced = qs.get('theme') || PROFILE_THEME[qs.get('profile') || DEFAULT_PROFILE];")]
for a,b in reps:
    assert s.count(a)==1, 'patch anchor missing: '+a[:50]; s=s.replace(a,b)
open(p,'w').write(s); print('patched: tutorial profile is the default')
PY
git -C "$HERE" add -A && git -C "$HERE" diff --cached --stat | tail -3
if [ "${1:-}" = "--push" ]; then
  git -C "$HERE" commit -q -m "sync from jfc-talk@$(git -C "$SRC" rev-parse --short HEAD)" && git -C "$HERE" push -q origin main && echo "pushed → https://jfc-mit.github.io/jfc-tutorial-nrp-clariphy/"
fi
