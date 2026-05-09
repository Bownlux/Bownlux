#!/usr/bin/env bash
# Generate an SVG card showing the count of closed issues assigned to USER.
# Usage: issues-solved.sh <username> <output-path>
set -euo pipefail

USER="${1:-Bownlux}"
OUT="${2:-profile/issues-solved.svg}"
TOKEN="${GITHUB_TOKEN:-}"

# Closed issues where the user was the assignee — our proxy for "issues solved by me".
QUERY="is:issue+is:closed+assignee:${USER}"

AUTH_ARGS=()
if [[ -n "$TOKEN" ]]; then
  AUTH_ARGS=(-H "Authorization: Bearer ${TOKEN}")
fi

RESPONSE=$(curl -sS ${AUTH_ARGS[@]+"${AUTH_ARGS[@]}"} \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/search/issues?q=${QUERY}&per_page=1")

COUNT=$(echo "$RESPONSE" | jq -r '.total_count // 0')

if ! [[ "$COUNT" =~ ^[0-9]+$ ]]; then
  echo "Unexpected API response:" >&2
  echo "$RESPONSE" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"

cat > "$OUT" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="400" height="120" viewBox="0 0 400 120" role="img" aria-label="Issues solved: ${COUNT}">
  <style>
    .bg     { fill: #151515; stroke: #e4e2e2; stroke-opacity: 0.1; }
    .title  { fill: #fe428e; font: 600 18px 'Segoe UI', Ubuntu, Sans-Serif; }
    .count  { fill: #79ff97; font: 700 48px 'Segoe UI', Ubuntu, Sans-Serif; }
    .sub    { fill: #9f9f9f; font: 400 12px 'Segoe UI', Ubuntu, Sans-Serif; }
  </style>
  <rect class="bg" x="0.5" y="0.5" width="399" height="119" rx="6" />
  <text class="title" x="20" y="34">Issues Solved</text>
  <text class="count" x="20" y="86">${COUNT}</text>
  <text class="sub"   x="20" y="108">closed issues assigned to ${USER}</text>
</svg>
EOF

echo "Wrote ${OUT} with count=${COUNT}"
