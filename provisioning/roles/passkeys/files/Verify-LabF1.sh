#!/bin/bash
# Lab F1 — log investigation and incident reconstruction. Run on logstation.
#   1. An incident timeline and a structured summary exist under /root/incident/
#   2. The summary's stated root cause matches the control the dataset was built around
# The dataset shows an SSH brute force that succeeded because the account had no lockout,
# so a correct root cause names the missing account-lockout control (pam_faillock).
set -u
INC=/root/incident
PASSKEY_FILE=/analysis/incident_passkey.txt

fails=0

timeline="$(ls -1 "$INC"/timeline* 2>/dev/null | head -1)"
summary="$(ls -1 "$INC"/summary* 2>/dev/null | head -1)"

if [ -z "$timeline" ] || [ ! -s "$timeline" ]; then
  echo "[FAIL] no non-empty timeline found under $INC (expected timeline.txt)"; fails=1
fi
if [ -z "$summary" ] || [ ! -s "$summary" ]; then
  echo "[FAIL] no non-empty summary found under $INC (expected summary.txt)"; fails=1
fi

if [ -n "$summary" ] && [ -s "$summary" ]; then
  if ! grep -Eiq 'faillock|account lockout|lockout|brute[ -]?force' "$summary"; then
    echo "[FAIL] the summary's root cause does not name the missing lockout control (pam_faillock / account lockout)"
    fails=1
  fi
fi

if [ "$fails" -eq 0 ]; then
  echo "[PASS] Both checks passed. Passkey:"
  cat "$PASSKEY_FILE"
  exit 0
fi
echo "Fix the items above and re-run. No passkey printed."
exit 1
