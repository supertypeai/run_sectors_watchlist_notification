# Watchlist notification scheduler

A GitHub Action that starts the weekly watchlist email. Every Monday it calls
`/api/email` on the watchlist app (`sectors_watchlist_notification`), which finds
the users who are due an email and sends it through Mailroom.

- **Schedule:** Mondays, 05:00 UTC (12:00 WIB). GitHub starts scheduled runs late under
  load, so it can be several hours later. Run it by hand from the Actions tab with
  *Run workflow* any time.
- **Secret:** the repo secret `SECRET` is the bearer token the endpoint expects.
- **A run is green only if it was clean:** HTTP 200 and no failed emails. Anything else
  turns the job red, so GitHub tells you. `scripts/trigger.sh` does the call.
- **No automatic retry,** on purpose: the endpoint emails real people, and a repeat
  while the first request is still running could email someone twice. If a run fails,
  run it again by hand. A user who was already emailed is skipped, so that is safe.
- **`logs/workflow.log`** gets one line per run: the time, the HTTP status and the
  endpoint's summary. The bot commits it every run, which also stops GitHub from
  switching the schedule off after 60 days without activity.
