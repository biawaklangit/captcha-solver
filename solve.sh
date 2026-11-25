#!/usr/bin/env bash
# Quick captcha solve client
# Usage:
#   ./solve.sh turnstile <sitekey> <url> [timeout]
#   ./solve.sh cloudflare <url> [proxy]
#   ./solve.sh health
set -euo pipefail
BASE="${SOLVER_URL:-http://127.0.0.1:8877}"
TYPE="${1:-}"
case "$TYPE" in
  health|status|logs)
    curl -sS "$BASE/$TYPE" | python3 -m json.tool
    ;;
  turnstile)
    SITEKEY="${2:?sitekey required}"
    URL="${3:?url required}"
    TIMEOUT="${4:-90}"
    curl -sS -X POST "$BASE/solve" \
      -H "Content-Type: application/json" \
      -d "{\"type\":\"turnstile\",\"sitekey\":\"$SITEKEY\",\"url\":\"$URL\",\"timeout_s\":$TIMEOUT}" \
      | python3 -m json.tool
    ;;
  recaptcha)
    SITEKEY="${2:?sitekey required}"
    URL="${3:?url required}"
    VERSION="${4:-v2}"
    curl -sS -X POST "$BASE/solve" \
      -H "Content-Type: application/json" \
      -d "{\"type\":\"recaptcha\",\"sitekey\":\"$SITEKEY\",\"url\":\"$URL\",\"version\":\"$VERSION\",\"timeout_s\":90}" \
      | python3 -m json.tool
    ;;
  cloudflare|awswaf)
    URL="${2:?url required}"
    PROXY="${3:-}"
    BODY="{\"type\":\"$TYPE\",\"url\":\"$URL\",\"timeout_s\":90"
    if [[ -n "$PROXY" ]]; then BODY+=",\"proxy\":\"$PROXY\""; fi
    BODY+="}"
    curl -sS -X POST "$BASE/solve" \
      -H "Content-Type: application/json" \
      -d "$BODY" | python3 -m json.tool
    ;;
  *)
    echo "Usage: $0 {health|turnstile|recaptcha|cloudflare|awswaf} ..."
    echo "  $0 turnstile <sitekey> <url> [timeout]"
    echo "  $0 recaptcha <sitekey> <url> [v2|v3|invisible]"
    echo "  $0 cloudflare <url> [proxy]"
    echo "  $0 awswaf <url> [proxy]"
    exit 1
    ;;
esac
