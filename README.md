# CR-05 sandbox definition

> **This repository is the deployable copy.** It is generated from
> `cr05/labs/sandbox-definition/` in the private CADMUS content repository and is
> what the Cyber Range sandbox definition points at. Relative paths below such as
> `../lab_env_description.md` refer to that repository, not to this one.

Infrastructure as Code for the shared CADMUS CR-05 Cyber Range: a `topology.yml`, APG
`variables.yml`, and an Ansible `provisioning/` tree. One sandbox serves all six labs
(A1 to F1); each lab's `../lab_<id>.unused.yml` records the hosts that lab does not use.

## Topology

Five hosts and two routers across two networks (see `../lab_env_description.md` for the
full inventory):

| Host | Role | Networks |
|---|---|---|
| ubuntu-ws | primary hardening target (Ubuntu 24.04) | access, lab |
| rhel-srv | second hardening target (RHEL 9) | access, lab |
| ubuntu-ref | unhardened reference for the E1 comparison scan | access, lab |
| attacker | test client (Ubuntu + attacker toolset) | access, lab |
| logstation | F1 incident dataset and C1 log receiver (off the lab segment) | access |

## The sandbox ships unhardened, on purpose

The learner does the hardening. `roles/seed_weaknesses` installs the exact findings the
labs fix (root SSH login permitted, `/tmp` without `nodev,nosuid,noexec`, loadable
modules, an over-broad `svc_app` sudo rule, an unsafe SUID shell, a world-writable
root-cron script, permissive firewall). `ubuntu-ref` is excluded from that role so it
stays at plain defaults as the E1 baseline.

## Passkey chain

`roles/passkeys` writes each passkey file and the matching `Verify-Lab*.sh` to the host
named in the lab's "Lab Completion" section. The passkey values are fixed literals that
must stay identical to `../../training_definition.json`:

| Lab | Host | Passkey file | Value |
|---|---|---|---|
| A1 | ubuntu-ws | `/secure/hardening/passkey.txt` | `cr05-a1-baseline-hardened` |
| B1 | rhel-srv | `/home/secure_user/passkey.txt` | `cr05-b1-auth-hardened` |
| C1 | ubuntu-ws | `/secure/audit/passkey.txt` | `cr05-c1-logging-verified` |
| D1 | rhel-srv | `/root/secure_passkey.txt` | `cr05-d1-escalation-remediated` |
| E1 | rhel-srv | `/secure/compliance/passkey.txt` | `cr05-e1-compliance-validated` |
| F1 | logstation | `/analysis/incident_passkey.txt` | `cr05-f1-incident-reconstructed` |

Each script runs the lab's two completion checks and prints the passkey only when both
pass. Checks that span both hosts use a read-only probe (`verify-probe.sh`) that
`engineer` runs on the peer over a provisioned key with NOPASSWD sudo limited to that one
script, so a cross-host check needs no password and grants no writable privilege.

## Deviations and decisions (also in the build report)

1. **`rhel-srv` runs Rocky Linux 9, not RHEL 9.** The host has to be Red Hat-family: lab C1
   runs `firewall-cmd`/`firewalld` and `dnf` on it, and node N2 teaches SELinux enforcing mode
   on it, none of which exist on Ubuntu. The platform catalogue held no Red Hat-family image
   until 1 Sep 2026, when `rocky-9.8-min-x86_64` was loaded, and `topology.yml` now names it.
   Rocky 9 is binary-compatible with RHEL 9 and needs no subscription, and the labs use no
   `subscription-manager`. The host keeps the name `rhel-srv`, which the labs, the passkey
   scripts and `training_definition.json` all address it by. `mgmt_user` is `rocky`, the Rocky
   cloud-image default; the catalogue leaves its Default User column blank for every image, so
   provisioning is where that value is confirmed.
2. **CIS-CAT is licence-gated.** `roles/compliance_tools` installs OpenSCAP and the SCAP
   Security Guide (freely redistributable, CIS-aligned) and leaves a hook directory
   (`/opt/cis-cat`) for a trainer-supplied CIS-CAT Assessor. Nothing CIS-licensed is
   fetched or shipped.
3. **`ubuntu-ref` is a fifth host** added beyond the four in the original scenario, because
   lab E1 scans an unhardened reference host alongside `rhel-srv` and the learner has sudo
   on it. `../lab_env_description.md` was updated to match.
4. **APG randomizes service passwords only.** The passkeys and the documented engineer /
   analyst logins are fixed so the passkey chain and `training_definition.json` stay
   consistent (see `variables.yml`).
