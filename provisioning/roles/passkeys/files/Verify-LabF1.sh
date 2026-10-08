#!/bin/bash
# Lab F1 — log investigation and incident reconstruction. Run on logstation.
#   1. An incident timeline and a structured summary exist under /root/incident/
#   2. The summary's stated root cause matches the control the dataset was built around
#   3. The summary and timeline carry the facts only the evidence gives: the attacking source,
#      the compromised account, the escalation (maint-shell), the account created (sysmaint)
#      and an audit key (privileged, identity or scope). Matching is case-insensitive and in
#      any order.
# The dataset shows an SSH brute force that succeeded because the account had no lockout,
# so a correct root cause names the missing account-lockout control (pam_faillock).
set -u
INC=/root/incident
PASSKEY_FILE=/analysis/incident_passkey.txt
AUTH=${F1_AUTH_LOG:-/var/log/collected/auth.log}
# Fallbacks match roles/log_dataset/defaults/main.yml (attacker_lab_ip) and auth.log.j2.
ATTACKER_IP=10.10.20.6
ACCOUNT=engineer

fails=0

timeline="$(ls -1 "$INC"/timeline* 2>/dev/null | head -1)"
summary="$(ls -1 "$INC"/summary* 2>/dev/null | head -1)"

if [ -z "$timeline" ] || [ ! -s "$timeline" ]; then
  echo "[FAIL] no non-empty timeline found under $INC (expected timeline.txt)"; fails=1
fi
if [ -z "$summary" ] || [ ! -s "$summary" ]; then
  echo "[FAIL] no non-empty summary found under $INC (expected summary.txt)"; fails=1
fi

# Take the attacking source and the compromised account from the accepted login in the
# dataset itself, so the check follows the seeded values.
acc="$(grep -m1 'Accepted password for' "$AUTH" 2>/dev/null)"
if [ -n "$acc" ]; then
  ACCOUNT="$(echo "$acc" | sed -E 's/.*Accepted password for ([^ ]+) from.*/\1/')"
  ATTACKER_IP="$(echo "$acc" | sed -E 's/.*from ([0-9.]+) port.*/\1/')"
fi

if [ -n "$summary" ] && [ -s "$summary" ]; then
  if ! grep -Eiq 'faillock|account lockout|lockout|lock out' "$summary"; then
    echo "[FAIL] the summary's root cause does not name the missing lockout control (pam_faillock / account lockout)"
    fails=1
  fi

  evidence="$(cat "$summary" "$timeline" 2>/dev/null)"
  has() { printf '%s\n' "$evidence" | grep -Fiq -- "$1"; }
  if ! has "$ATTACKER_IP"; then
    echo "[FAIL] the summary or timeline does not give the source address of the brute force"; fails=1
  fi
  if ! has "$ACCOUNT"; then
    echo "[FAIL] the summary or timeline does not name the compromised account"; fails=1
  fi
  if ! has "maint-shell"; then
    echo "[FAIL] the summary or timeline does not name the program used to escalate to root (see the sudo and audit records)"; fails=1
  fi
  if ! has "sysmaint"; then
    echo "[FAIL] the summary or timeline does not name the account the intruder created (see the audit records)"; fails=1
  fi
  if ! printf '%s\n' "$evidence" | grep -Eiq '(^|[^a-z])(privileged|identity|scope)([^a-z]|$)'; then
    echo "[FAIL] the summary or timeline does not cite the audit key that retrieved the changes (privileged, identity or scope)"; fails=1
  fi
fi

if [ "$fails" -eq 0 ]; then
  echo "[PASS] All checks passed. Passkey:"
  cat "$PASSKEY_FILE"
  exit 0
fi
echo "Fix the items above and re-run. No passkey printed."
exit 1
