#!/usr/bin/env bash
# Preview the bownlux.dev site locally, assembled exactly like the Pages workflow.
# Usage: scripts/serve.sh [port]
set -euo pipefail

PORT="${1:-8000}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/.preview"

rm -rf "$OUT"
mkdir -p "$OUT/profile"
cp -r "$ROOT/site/." "$OUT/"
cp "$ROOT"/profile/*.svg "$OUT/profile/" 2>/dev/null || true

# Same figure refresh the Pages workflow does. Skip with NO_STATS=1 to stay offline.
if [[ -z "${NO_STATS:-}" ]]; then
  python3 "$ROOT/scripts/update-stats.py" "$OUT/index.html" || true
fi

# Build the Retromod docs into /retromod, as the Pages workflow does. Needs a
# local Retromod checkout and Ruby 3.x; without either, the redirect stub in
# site/retromod/ stays in place. Skip with NO_DOCS=1.
RETROMOD_DOCS="${RETROMOD_DOCS:-$ROOT/../RetroMod/Retromod/docs}"
if [[ -z "${NO_DOCS:-}" && -f "$RETROMOD_DOCS/_config.yml" ]]; then
  for rb in /opt/homebrew/opt/ruby@3.3/bin /opt/homebrew/opt/ruby/bin; do
    [[ -d "$rb" ]] && PATH="$rb:$PATH"
  done
  if (cd "$ROOT/docs-build" && bundle exec jekyll --version) >/dev/null 2>&1; then
    printf 'baseurl: "/retromod"\nurl: "https://bownlux.dev"\n' > "$OUT/../.retromod-overrides.yml"
    if (cd "$ROOT/docs-build" && bundle exec jekyll build \
          --source "$RETROMOD_DOCS" \
          --destination "$OUT/retromod.tmp" \
          --config "$RETROMOD_DOCS/_config.yml,$OUT/../.retromod-overrides.yml") >/dev/null 2>&1; then
      rm -rf "$OUT/retromod" && mv "$OUT/retromod.tmp" "$OUT/retromod"
      echo "Built Retromod docs into /retromod"
    else
      echo "Retromod docs build failed; /retromod keeps the redirect stub"
    fi
    rm -f "$OUT/../.retromod-overrides.yml"
  else
    echo "No Jekyll available; /retromod keeps the redirect stub"
  fi
fi

echo "Serving $OUT at http://localhost:${PORT}/  (Ctrl-C to stop)"
cd "$OUT"
python3 -m http.server "$PORT"
