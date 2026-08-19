#!/usr/bin/env bash
# Returns a Gotify client API token for the eval admin user.
# The SUT seeds admin/admin via GOTIFY_DEFAULTUSER_*; we poll health, then mint a
# client token over basic auth (POST /client). Token is used as X-Gotify-Key.
set -euo pipefail
BASE_URL="http://localhost:8090"
U="${GOTIFY_ADMIN:-admin}"; P="${GOTIFY_PASS:-admin}"
deadline=$(( $(date +%s) + 300 ))
until curl -sf -m3 "${BASE_URL}/health" | grep -q green; do
  [[ $(date +%s) -ge $deadline ]] && { echo "ERROR: Gotify health timed out" >&2; exit 1; }
  sleep 3
done
curl -sf -u "$U:$P" -X POST "${BASE_URL}/client" \
  -H 'Content-Type: application/json' \
  -d "{\"name\":\"eval-$(date +%s%N)\"}" \
  | python3 -c "import json,sys;print(json.load(sys.stdin)['token'])"
