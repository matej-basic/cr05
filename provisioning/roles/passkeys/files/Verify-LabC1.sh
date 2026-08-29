#!/bin/bash
# Lab C1 — logging, auditing, file integrity, firewall. Run on ubuntu-ws.
#   1. auditctl -s reports enabled 2 (immutable) and the keyed rules are loaded on both hosts
#   2. The lab interface enforces default-deny while SSH stays reachable on the access interface
set -u
PROBE=/opt/scripts/verify-probe.sh
[ -f /opt/scripts/verify.env ] && . /opt/scripts/verify.env
PEER_IP="${PEER_IP:-}"; PEER_HOST="${PEER_HOST:-}"; VERIFY_KEY="${VERIFY_KEY:-/root/.verify_key}"
PASSKEY_FILE=/secure/audit/passkey.txt

probe_local(){ "$PROBE" "$1"; }
probe_peer(){ ssh -i "$VERIFY_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=8 \
    "engineer@${PEER_IP:-$PEER_HOST}" "sudo $PROBE $1" 2>/dev/null; }
both(){ [ "$(probe_local "$1")" = PASS ] && [ "$(probe_peer "$1")" = PASS ]; }

fails=0
both auditd_immutable                   || { echo "[FAIL] auditd is not immutable or has no keyed rules on both hosts"; fails=1; }
[ "$(probe_local lab_default_deny)" = PASS ] || { echo "[FAIL] the lab interface does not enforce default-deny with SSH still permitted"; fails=1; }

if [ "$fails" -eq 0 ]; then
  echo "[PASS] Both checks passed. Passkey:"
  cat "$PASSKEY_FILE"
  exit 0
fi
echo "Fix the items above and re-run. No passkey printed."
exit 1
