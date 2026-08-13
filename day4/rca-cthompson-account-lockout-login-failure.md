Title: Root Cause Analysis — Account Lockout / Login Failure (cthompson)
User: FINBRIDGE\cthompson
Device: DESKTOP-FB022 (10.10.1.88)
Incident Window: 2024-03-15 08:44 — 09:09
Resolved: 2024-03-15 09:09
Status: Closed

---

## Executive Summary

User cthompson was unable to log in to DESKTOP-FB022 from approximately 08:40 on 2024-03-15. Investigation confirmed the account was locked out at 08:44:56 following three consecutive failed login attempts with an incorrect password from DESKTOP-FB022. A second device (10.10.8.112) was found to be holding a stale cached credential and continuing to fire Kerberos authentication requests after the lockout, creating a re-lock risk. The account was unlocked, cthompson's password was reset, and the cached credential on the second device was cleared. cthompson confirmed successful login at 09:09 with no further issues reported.

---

## Incident Timeline

| Time | Event | Source | Detail |
|------|-------|--------|--------|
| ~08:40 | User reports inability to log in | cthompson | Cannot get past Windows login screen |
| 08:44:01 | Event 4776 — Credential validation failure | DESKTOP-FB022 | Error code `0xC000006A` (wrong password) for FINBRIDGE\cthompson |
| 08:44:03 | Event 4625 — Logon failure #1 | DESKTOP-FB022 | Logon type 2 (Interactive); reason: Unknown user name or bad password |
| 08:44:28 | Event 4625 — Logon failure #2 | DESKTOP-FB022 | Same reason — second failed attempt |
| 08:44:55 | Event 4625 — Logon failure #3 | DESKTOP-FB022 | Same reason — third failed attempt; lockout threshold reached |
| 08:44:56 | Event 4740 — Account locked out | DESKTOP-FB022 | FINBRIDGE\cthompson locked; caller: DESKTOP-FB022 |
| 08:45:10 | Event 4625 — Unlock attempt fails | DESKTOP-FB022 | Logon type 7 (Unlock); reason: Account locked out |
| 08:45:44 | Event 4771 — Kerberos failure | 10.10.8.112 (second device) | Pre-auth failure code `0x18` (wrong password) — different source IP |
| 08:46:01 | Event 4771 — Kerberos failure | 10.10.8.112 | Same — second attempt from second device |
| 08:46:33 | Event 4771 — Kerberos failure | 10.10.8.112 | Same — third attempt from second device |
| ~08:50 | Ticket raised; investigation begins | Service Desk | Scope facts gathered; hypothesis analysis initiated |
| ~08:55 | Event log evidence reviewed | Engineer | All five hypotheses assessed; H1 confirmed, H2/H3/H4 contradicted, H5 identified as compounding factor |
| ~09:00 | Account unlocked in AD | Engineer | `Unlock-ADAccount -Identity cthompson`; LockedOut confirmed False |
| ~09:01 | Second device (10.10.8.112) identified | Engineer | DHCP/DNS lookup; cached credential located and cleared |
| ~09:03 | Password reset performed | cthompson / Engineer | New password set via helpdesk reset; all cached entries invalidated |
| 09:09 | cthompson confirms successful login | cthompson | Desktop loads on DESKTOP-FB022; no disconnect or error |
| 09:09 | Incident closed | Engineer | Security log monitored — no further 4625/4740 events for cthompson |

---

## Evidence Detail

### Security Event Log — DESKTOP-FB022 / Domain Controller
**Window: 2024-03-15 08:44–08:46**

```
08:44:01  Event 4776  Audit Failure
          Credential validation — FINBRIDGE\cthompson
          Error Code: 0xC000006A (wrong password)
          Source: DESKTOP-FB022

08:44:03  Event 4625  Audit Failure
          Failure reason: Unknown user name or bad password
          Logon type: 2 (Interactive) — Source: DESKTOP-FB022

08:44:28  Event 4625  Audit Failure
          Failure reason: Unknown user name or bad password
          Logon type: 2 (Interactive) — Source: DESKTOP-FB022

08:44:55  Event 4625  Audit Failure
          Failure reason: Unknown user name or bad password
          Logon type: 2 (Interactive) — Source: DESKTOP-FB022

08:44:56  Event 4740  Audit Failure
          Account locked out — FINBRIDGE\cthompson
          Caller computer: DESKTOP-FB022

08:45:10  Event 4625  Audit Failure
          Failure reason: Account locked out
          Logon type: 7 (Unlock attempt) — Source: DESKTOP-FB022

08:45:44  Event 4771  Audit Failure
          Kerberos pre-authentication failed — FINBRIDGE\cthompson
          Failure code: 0x18 (wrong password)
          Source IP: 10.10.8.112  [NOTE: different from DESKTOP-FB022 / 10.10.1.88]

08:46:01  Event 4771  Audit Failure
          Kerberos pre-auth failed — failure code 0x18 — Source IP: 10.10.8.112

08:46:33  Event 4771  Audit Failure
          Kerberos pre-auth failed — failure code 0x18 — Source IP: 10.10.8.112
```

### Key Observations from Evidence

1. Failure code `0xC000006A` (NTLM) and `0x18` (Kerberos) both mean **wrong password** — not expired (`0xC0000071` / `0x17`), not disabled (`0xC0000072`), not expired account (`0xC0000193`).
2. The lockout (Event 4740) names DESKTOP-FB022 as the caller — the originating device is confirmed.
3. Events 4771 from 10.10.8.112 begin **after** the lockout, confirming a second device with a stale/wrong cached credential independently attempting Kerberos authentication. This device would re-lock the account after any unlock if not cleared.
4. No Event 4624 (successful logon) appears at any point in the window — the failure is entirely at the credential/authentication layer, not at profile or session loading.

---

## Root Cause

**Immediate cause:** cthompson's account was locked out at 08:44:56 (Event 4740) after three failed interactive login attempts from DESKTOP-FB022 with an incorrect password (Events 4625 at 08:44:03, 08:44:28, 08:44:55).

**Compounding factor:** A second device at IP 10.10.8.112 (separate from DESKTOP-FB022) held a stale or incorrect cached credential for cthompson and continued firing Kerberos authentication attempts (Events 4771 at 08:45:44, 08:46:01, 08:46:33) after the lockout, creating a re-lock risk that would have defeated a simple unlock without addressing the second device.

---

## 5-Why Analysis

**Problem statement:** cthompson was unable to log in to DESKTOP-FB022 on the morning of 2024-03-15.

| Why | Answer |
|-----|--------|
| **Why #1** — Why could cthompson not log in? | The account was locked out (Event 4740 @ 08:44:56), blocking all authentication attempts. |
| **Why #2** — Why was the account locked out? | Three consecutive failed login attempts with an incorrect password from DESKTOP-FB022 tripped the domain lockout threshold (Events 4625 @ 08:44:03–08:44:55). |
| **Why #3** — Why were incorrect password attempts made? | cthompson (or a device acting on their behalf) was submitting a password that did not match the current AD credential — most likely a recently changed password not yet updated on one or more devices. |
| **Why #4** — Why was the wrong password in use on multiple devices? | No mechanism existed to alert cthompson that a cached credential on the second device (10.10.8.112) had become stale after a password change, and no process prompted the user to update credentials across all devices. |
| **Why #5** — Why was there no alerting or process for stale cached credentials? | There is no automated monitoring for repeated pre-authentication failures per account that would surface a stale-credential risk before lockout threshold is reached; and no user-facing guidance exists for clearing saved credentials after a password change. |

**Root cause conclusion:** The absence of proactive monitoring for repeated failed authentication attempts, combined with no process for users to identify and clear stale cached credentials on secondary devices, allowed a credential synchronisation gap to escalate silently to an account lockout.

---

## Resolution Applied

1. Account unlocked via AD:
   ```powershell
   Unlock-ADAccount -Identity cthompson
   ```
2. Second device at 10.10.8.112 identified via DHCP/DNS; saved credential for FINBRIDGE\cthompson removed from Windows Credential Manager.
3. cthompson's password reset by helpdesk; user prompted to update on all devices.
4. cthompson confirmed successful login to DESKTOP-FB022 at 09:09 — desktop loaded normally, no errors.
5. Security event log monitored post-resolution — no further Event 4625 or 4740 for cthompson observed.

---

## Preventive Actions

| # | Action | Owner | Priority |
|---|--------|-------|----------|
| 1 | **Account lockout alerting** — Create a SIEM / Azure Monitor alert rule that fires when Event 4740 is recorded for any user account. Route to Service Desk queue as P2. This surfaces lockouts immediately rather than waiting for user reports. | AD/Security team | High |
| 2 | **Pre-lockout threshold alert** — Alert on 3+ Event 4625 failures for a single account within a 10-minute window, before the lockout threshold is reached. Allows proactive intervention. | AD/Security team | High |
| 3 | **User communication — password change checklist** — When a password reset is performed (via SSPR or helpdesk), automatically send the user a short checklist: update credentials in Windows Credential Manager, update mobile mail profile, update any saved browser credentials. Prevents stale credential build-up on secondary devices. | Service Desk / Comms | Medium |
| 4 | **SSPR / self-service unlock enablement** — If not already active, enable Azure AD Self-Service Password Reset so users can unlock their own accounts without a helpdesk call, reducing resolution time from ~25 minutes to under 5. | IAM team | Medium |
| 5 | **Lockout source tracing in runbook** — Update the account lockout runbook to include the step of checking the source IP of Event 4771 entries against the device inventory, specifically to identify secondary devices (phones, tablets, secondary workstations) holding stale credentials. | Service Desk / Knowledge | Low |

---

## Lessons Learned

- A single-user lockout with no reported change should immediately prompt investigation of **all devices** the user has authenticated from, not just the reported workstation. The second device (10.10.8.112) would have caused a re-lock within minutes of unlock had it not been identified.
- Error codes in Event 4776 and 4771 are fast discriminators: `0xC000006A` / `0x18` = wrong password; `0xC0000071` / `0x17` = expired password; `0xC0000072` = disabled. Checking these first eliminates H2 and H4 in under 30 seconds from log review.
- Total incident duration was approximately 29 minutes (08:40–09:09). With an SSPR unlock capability and the stale-credential checklist in place, this could reduce to under 10 minutes for future occurrences.
