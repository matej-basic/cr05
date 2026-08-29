#!/bin/bash
# Lab B1 — authentication and privilege hardening. Run on rhel-srv.
#   1. PermitRootLogin no is the effective sshd setting on both ubuntu-ws and rhel-srv
#   2. The svc_app sudo policy grants no ALL command and no shell
set -u
PROBE=/opt/scripts/verify-probe.sh
[ -f /opt/scripts/verify.env ] && . /opt/scripts/verify.env
PEER_IP="${PEER_IP:-}"; PEER_HOST="${PEER_HOST:-}"; VERIFY_KEY="${VERIFY_KEY:-/root/.verify_key}"
PASSKEY_FILE=/home/secure_user/passkey.txt

probe_local(){ "$PROBE" "$1"; }
probe_peer(){ ssh -i "$VERIFY_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=8 \
    "engineer@${PEER_IP:-$PEER_HOST}" "sudo $PROBE $1" 2>/dev/null; }
both(){ [ "$(probe_local "$1")" = PASS ] && [ "$(probe_peer "$1")" = PASS ]; }

fails=0
both rootlogin_off              || { echo "[FAIL] PermitRootLogin is not no on both hosts"; fails=1; }
[ "$(probe_local svc_app_scoped)" = PASS ] || { echo "[FAIL] the svc_app sudo rule still grants ALL or a shell"; fails=1; }

if [ "$fails" -eq 0 ]; then
  echo "[PASS] Both checks passed. Passkey:"
  cat "$PASSKEY_FILE"
  exit 0
fi
echo "Fix the items above and re-run. No passkey printed."
exit 1
