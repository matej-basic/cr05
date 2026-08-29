#!/bin/bash
# Lab A1 — baseline assessment and initial hardening. Run on ubuntu-ws.
#   1. /tmp mounted nodev,nosuid,noexec on both ubuntu-ws and rhel-srv
#   2. kernel.randomize_va_space is 2 and the blocked modules resolve to /bin/false (both)
set -u
PROBE=/opt/scripts/verify-probe.sh
[ -f /opt/scripts/verify.env ] && . /opt/scripts/verify.env
PEER_IP="${PEER_IP:-}"; PEER_HOST="${PEER_HOST:-}"; VERIFY_KEY="${VERIFY_KEY:-/root/.verify_key}"
PASSKEY_FILE=/secure/hardening/passkey.txt

probe_local(){ "$PROBE" "$1"; }
probe_peer(){ ssh -i "$VERIFY_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=8 \
    "engineer@${PEER_IP:-$PEER_HOST}" "sudo $PROBE $1" 2>/dev/null; }
both(){ [ "$(probe_local "$1")" = PASS ] && [ "$(probe_peer "$1")" = PASS ]; }

fails=0
both tmp_hardened   || { echo "[FAIL] /tmp is not nodev,nosuid,noexec on both hosts"; fails=1; }
both aslr_modules   || { echo "[FAIL] ASLR is not 2 or the unused modules are not blocked on both hosts"; fails=1; }

if [ "$fails" -eq 0 ]; then
  echo "[PASS] Both checks passed. Passkey:"
  cat "$PASSKEY_FILE"
  exit 0
fi
echo "Fix the items above and re-run. No passkey printed."
exit 1
