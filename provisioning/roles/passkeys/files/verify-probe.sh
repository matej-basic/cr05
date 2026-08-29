#!/bin/bash
# Read-only verification probe. Given a check id, prints PASS or FAIL and exits 0.
# Deployed to every host that a Verify-Lab*.sh script inspects (locally or over SSH).
# engineer may run ONLY this script via NOPASSWD sudo, so a peer check needs no password
# and grants no writable privilege. Add no state-changing command here.
set -u
id="${1:-}"

pass() { echo "PASS"; exit 0; }
fail() { echo "FAIL"; exit 0; }

case "$id" in
  tmp_hardened)
    # /tmp mounted with nodev, nosuid, and noexec.
    opts="$(findmnt -no OPTIONS /tmp 2>/dev/null)"
    for o in nodev nosuid noexec; do
      echo ",$opts," | grep -q ",$o," || fail
    done
    pass
    ;;

  aslr_modules)
    # ASLR full, and the unused modules resolve to /bin/false.
    [ "$(sysctl -n kernel.randomize_va_space 2>/dev/null)" = "2" ] || fail
    for m in cramfs freevxfs jffs2 udf dccp sctp rds tipc; do
      modprobe -n -v "$m" 2>&1 | grep -q '/bin/false' || fail
    done
    pass
    ;;

  rootlogin_off)
    # Effective sshd setting is PermitRootLogin no.
    sshd -T 2>/dev/null | grep -qi '^permitrootlogin no' || fail
    pass
    ;;

  svc_app_scoped)
    # svc_app sudo grants no blanket ALL command and no interactive shell.
    out="$(sudo -l -U svc_app 2>/dev/null)"
    echo "$out" | grep -Eq '\(ALL(\s*:\s*ALL)?\)\s+(NOPASSWD:\s*)?ALL' && fail
    echo "$out" | grep -Eq '/bin/(ba)?sh|/usr/bin/(ba)?sh' && fail
    pass
    ;;

  auditd_immutable)
    # auditd enabled and immutable (-e 2), with at least one keyed rule loaded.
    auditctl -s 2>/dev/null | grep -q 'enabled 2' || fail
    auditctl -l 2>/dev/null | grep -q 'key=' || fail
    pass
    ;;

  lab_default_deny)
    # The input policy drops by default while loopback, established, and SSH are accepted.
    rs="$(nft list ruleset 2>/dev/null)"
    echo "$rs" | grep -Eq 'type filter hook input .*policy drop' || fail
    echo "$rs" | grep -Eq 'ct state (established|related)' || fail
    echo "$rs" | grep -Eq 'dport 22|"ssh"|lo' || fail
    pass
    ;;

  suid_removed)
    # The seeded unsafe SUID shell no longer carries the SUID bit.
    [ -u /usr/local/bin/maint-shell ] && fail
    pass
    ;;

  writable_script_fixed)
    # The root-cron script is no longer writable by group or other.
    perm="$(stat -c '%A' /usr/local/sbin/larkfield-maint.sh 2>/dev/null)"
    case "$perm" in
      *w*w*|??????w?|?????????w) fail ;;   # group- or other-writable
    esac
    pass
    ;;

  *)
    echo "UNKNOWN_CHECK"; exit 0 ;;
esac
