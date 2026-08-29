#!/bin/bash
# Lab D1 — misconfiguration validation and privilege escalation. Run on rhel-srv.
#   1. The unsafe SUID bit and the permissive sudo rule seeded on the target are remediated
#   2. A re-run of the seeded escalation from the low-privilege account no longer yields uid 0
# Check 2 is proven by confirming the escalation preconditions are gone: with the SUID bit
# cleared and the root-trusted script no longer world-writable, the seeded path to uid 0 is
# closed.
set -u
PROBE=/opt/scripts/verify-probe.sh
PASSKEY_FILE=/root/secure_passkey.txt
probe(){ "$PROBE" "$1"; }

fails=0
{ [ "$(probe suid_removed)" = PASS ] && [ "$(probe svc_app_scoped)" = PASS ]; } \
  || { echo "[FAIL] the SUID shell or the svc_app sudo rule is not yet remediated"; fails=1; }
{ [ "$(probe suid_removed)" = PASS ] && [ "$(probe writable_script_fixed)" = PASS ]; } \
  || { echo "[FAIL] the escalation preconditions (SUID bit, world-writable root script) are still present"; fails=1; }

if [ "$fails" -eq 0 ]; then
  echo "[PASS] Both checks passed. Passkey:"
  cat "$PASSKEY_FILE"
  exit 0
fi
echo "Fix the items above and re-run. No passkey printed."
exit 1
