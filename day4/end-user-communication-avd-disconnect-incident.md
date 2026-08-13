Title: AVD Finance Session Disconnect — End-User Communications (Three Audiences)
Incident: POOL-FIN-01 / SHFIN-01-A immediate session disconnect on logon
Date: 2026-08-13
Source: avd-session-disconnect-analysis.md

---

## Audience 1 — Non-Technical Executive

Your access and data are completely safe.

An overnight software update introduced a faulty component on one of the Finance virtual desktop servers, causing Finance users to be disconnected immediately after logging in. The affected server has been taken offline and users have been moved to a working server. The fix has been validated and normal service has been restored.

No action is required from you.

---

## Audience 2 — Affected Finance Team

Hi team,

An overnight update to one of your virtual desktop servers introduced a faulty driver that caused your session to disconnect immediately after logging in. The affected server has been taken offline and you should now be able to connect normally.

If you experience the same immediate disconnect again, please do not retry repeatedly — log out and contact the IT Service Desk straight away so we can investigate quickly.

**Contact:** IT Service Desk — Teams chat or email servicedesk@company.com

---

## Audience 3 — Engineer-to-Engineer Internal Note

**Incident window:** 2024-03-15 07:00–07:30
**Affected host:** SHFIN-01-A (POOL-FIN-01)
**Unaffected reference:** SHFIN-02-A (POOL-FIN-02, image build-20240313)

### Root Cause

Overnight image update to SHFIN-01-A introduced Intel GPU driver `igdumd64.dll` version `31.0.101.4146`. On session establishment, `dwm.exe` attempts driver initialisation, hits access violation `0xc0000005` in `igdumd64.dll`, and terminates. DWM exit (Event 9009 / code `0x40010004`) fires within 1–2 seconds of logon (Event 21), producing immediate session disconnect (Event 40, reason code 0 — local termination, not network drop). Fault is host-wide and reproducible across all users; absent on SHFIN-02-A running pre-update image. Profile corruption (H3), resource exhaustion (H4), and RDP/network faults (H5) all contradicted by evidence. DWM instability (H2) is the proximate mechanism but not an independent root cause — fully caused by H1.

**Key events confirming root cause:**
| Time | Event ID | Source | Detail |
|------|----------|--------|--------|
| 07:02:14 | Kernel-General | System | Boot time 02:03:11 — overnight reboot confirmed |
| 07:02:10 | 21 | RDS | Session logon succeeded — mlopez (RDP/network OK) |
| 07:02:16 | 1000 | Application Error | `dwm.exe` fault in `igdumd64.dll` v31.0.101.4146, exception 0xc0000005 |
| 07:02:17 | 40 | RDS | Session disconnect — mlopez |
| 07:02:18 | 9009 | DWM | DWM exited 0x40010004 |
| 07:02:46 | 1000 | Application Error | Same fault — mlopez reconnect attempt |
| 07:03:01 | 9009 | DWM | DWM crash on reconnect — cannot recover across sessions |
| 07:08:22 | 21 | RDS | Session logon succeeded — akapoor |
| 07:08:24 | 1000 | Application Error | Same fault — akapoor (confirms host-wide, not profile-specific) |

### Action Taken

1. SHFIN-01-A (and all POOL-FIN-01 hosts that received the overnight update) set to **Drain mode** in Azure Portal > AVD > Host pools > POOL-FIN-01 > Session hosts. Blocked all new inbound sessions immediately.
2. Finance users redirected to **POOL-FIN-02** (unaffected, pre-update image) — no data loss.
3. Affected session hosts redeployed from last known-good image: `10.0.22621.2861-build-20240313` (confirmed clean on SHFIN-02-A — no Event 1000 / `igdumd64.dll` in that image's log window).
4. ServiceNow incident updated with confirmed root cause, affected scope, and drain action.

### Verification Step

On one redeployed host before re-enabling pool:
- Event Viewer > Application log: confirm **Event 9011** (DWM started successfully) present after first logon.
- Confirm **no Event 1000** with faulting module `igdumd64.dll`.
- Synthetic user logon: session must persist >60 seconds with rendered desktop.
- Once validated, remove Drain mode — POOL-FIN-01 resumes accepting sessions.

### Preventive Actions Required

1. **Driver pinning:** Identify how `igdumd64.dll` v31.0.101.4146 entered the image (Windows Update, driver injection, or third-party package). Pin Intel GPU driver to the previously validated version in the image template. Track via Problem ticket assigned to AVD image engineering.

2. **Pipeline canary gate:** Add a post-build validation step to the image pipeline — deploy to a canary session host, run a synthetic logon, and check for Event ID 1000 (`dwm.exe`) in Application log before promoting to production pools.

3. **Azure Monitor alerting:** Create alert rule for **Event ID 1000** (faulting app: `dwm.exe`) and **Event ID 9009** on all AVD session hosts. Severity: Critical. Route to AVD operations queue. This catches future DWM crashes before user reports come in.

4. Raise a **Problem ticket** linked to this incident to track items 1–3 to completion.
