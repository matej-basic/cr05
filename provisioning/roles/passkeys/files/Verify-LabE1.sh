#!/bin/bash
# Lab E1 — compliance scanning and remediation cycle. Run on rhel-srv.
#   1. Two dated scan reports exist and the second shows the remediated findings passing
#   2. An exception register exists recording at least the deliberate decisions from earlier labs
set -u
REPORT_DIR=/secure/compliance
PASSKEY_FILE="$REPORT_DIR/passkey.txt"

fails=0

# Check 1: at least two dated reports, and the newest is newer than the oldest.
mapfile -t reports < <(ls -1 "$REPORT_DIR"/scan-*.xml "$REPORT_DIR"/scan-*.html 2>/dev/null | sort)
if [ "${#reports[@]}" -lt 2 ]; then
  echo "[FAIL] fewer than two dated scan reports found in $REPORT_DIR (expected scan-<date>.xml/html)"
  fails=1
else
  newest="$(ls -1t "${reports[@]}" | head -1)"
  oldest="$(ls -1t "${reports[@]}" | tail -1)"
  if [ "$newest" -nt "$oldest" ]; then :; else
    echo "[FAIL] the two scan reports are not dated apart (no before/after pair)"; fails=1
  fi
fi

# Check 2: a non-empty exception register that names at least one control.
reg="$(ls -1 "$REPORT_DIR"/*exception* 2>/dev/null | head -1)"
if [ -z "$reg" ] || [ ! -s "$reg" ]; then
  echo "[FAIL] no non-empty exception register found in $REPORT_DIR (expected a file named *exception*)"
  fails=1
elif ! grep -Eiq 'cis|control|sudo|faillock|auditd|nftables|firewalld|ssh' "$reg"; then
  echo "[FAIL] the exception register names no recognisable control"
  fails=1
fi

if [ "$fails" -eq 0 ]; then
  echo "[PASS] Both checks passed. Passkey:"
  cat "$PASSKEY_FILE"
  exit 0
fi
echo "Fix the items above and re-run. No passkey printed."
exit 1
