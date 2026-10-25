#!/usr/bin/env bash
# Calls the watchlist email endpoint once, writes one line to the log, and fails
# unless the run was clean: an HTTP 200 that reports no failed emails.
#
# It does not retry. The endpoint emails real people, and a second request while
# the first is still running could email someone twice. A failure is loud
# instead: the job goes red, and sending the run again by hand is safe, because
# a user who was already emailed is skipped.
set -u

URL="${WATCHLIST_URL:-https://sectors-watchlist-notification.vercel.app/api/email}"
LOG="${LOG_FILE:-logs/workflow.log}"
TIMEOUT="${TIMEOUT_SECONDS:-120}"
: "${BEARER_TOKEN:?BEARER_TOKEN is not set}"

mkdir -p "$(dirname "$LOG")"
body=$(mktemp)
trap 'rm -f "$body"' EXIT

status=$(curl --silent --show-error --max-time "$TIMEOUT" \
  --output "$body" --write-out '%{http_code}' \
  -H "Authorization: Bearer $BEARER_TOKEN" "$URL") || status="000"

# The log keeps a short summary: the JSON the endpoint sent, or the start of whatever
# else came back (an error page is long and says nothing the status does not).
if jq -e . "$body" > /dev/null 2>&1; then
  summary=$(jq -c . "$body" | head -c 300)
  failed=$(jq -r '.failed // 0' "$body")
elif [ "$status" = "000" ]; then
  summary="no response (the request failed or timed out after ${TIMEOUT}s)"
  failed=0
else
  summary=$(head -c 200 "$body" | tr '\n' ' ')
  failed=0
fi

echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') | HTTP ${status} | ${summary}" >> "$LOG"
echo "HTTP ${status} | ${summary}"

if [ "$status" != "200" ]; then
  echo "::error::The watchlist email run answered HTTP ${status}, so it did not run."
  exit 1
fi
if [ "$failed" != "0" ]; then
  echo "::error::The watchlist email run finished but ${failed} email(s) failed to send."
  exit 1
fi
