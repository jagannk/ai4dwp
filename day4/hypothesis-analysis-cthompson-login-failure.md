Title: Login Failure — Hypothesis Analysis
User: cthompson
Symptom: Unable to log in
Onset: ~08:40, 2026-08-13
Scope: Single user only
Reported Changes: None
Status: Pre-investigation — hypotheses not yet confirmed

---

## Scope Facts

- Only cthompson is affected — no other users reporting login failures at this time.
- Issue began this morning (~08:40).
- No change recorded (no password reset, no device swap, no known maintenance window).

---

## Ranked Hypotheses — Most Probable First

---

### 1. Account Lockout

**Why it fits the scope facts:**
A lockout is the most common cause of a sudden, single-user login failure with no reported change. cthompson may have entered an incorrect password several times (mistyped, cached credential on a mobile device, or a saved credential out of sync), triggering the domain lockout threshold. The abrupt 08:40 onset aligns with a morning login attempt after an overnight credential refresh or device wake.

**Fastest check:**
In Active Directory Users and Computers (or `Search-ADAccount -LockedOut`), check whether cthompson's account shows **Locked Out = True**. Result available in under 60 seconds.

---

### 2. Expired Password

**Why it fits the scope facts:**
If cthompson's password reached its maximum age overnight or this morning, the account would refuse interactive login from 08:40 onwards with no admin-side change needed to trigger it. A single-user impact with no change event fits exactly — password expiry is per-account and is not a change that helpdesk would normally log.

**Fastest check:**
Run `Get-ADUser cthompson -Properties PasswordExpired, PasswordLastSet, PasswordNeverExpires` — if `PasswordExpired` returns `True`, this hypothesis is confirmed.

---

### 3. Profile Corruption or Missing Profile

**Why it fits the scope facts:**
A corrupted or missing local/roaming profile would allow authentication to succeed but block the desktop from loading, which a user may report as "cannot log in." A single-user scope is consistent — profiles are per-user. If cthompson recently had a forced logoff, a device rebuild, or an interrupted logon, the profile may be in a broken state.

**Fastest check:**
Ask cthompson whether they reach the Windows loading screen at all (i.e., does the session progress past the credential prompt?). If yes, check `C:\Users\` on the target machine or the profile server share for a `cthompson.V6.bak` or `TEMP` profile folder, which signals profile load failure.

---

### 4. Account Disabled or Expired

**Why it fits the scope facts:**
An account disabled by an automated process (e.g., HR-triggered de-provisioning, an IAM rule on inactive accounts, or a scheduled task) would produce a clean single-user block at whatever time the job ran — potentially early morning. "No change" as reported by the user is consistent because the action would have been taken by a system, not a helpdesk operator.

**Fastest check:**
Run `Get-ADUser cthompson -Properties Enabled, AccountExpirationDate` — check `Enabled = False` or whether `AccountExpirationDate` has passed. Also review the Security event log on the domain controller for Event ID **4725** (account disabled) or **4767** (account unlocked — may reveal a prior lock) around 08:40.

---

### 5. Cached Credential / Kerberos Ticket Issue

**Why it fits the scope facts:**
If cthompson is authenticating against a domain resource but their Kerberos ticket or cached credential is stale, corrupted, or tied to a machine that is off the network (e.g., connecting via VPN for the first time today), login can fail for that user only while others on the same system succeed. The single-user, single-morning scope fits a per-session credential state issue.

**Fastest check:**
Ask whether cthompson is on VPN or in-office, and whether they are logging into a domain-joined machine or a web/cloud resource. On the client, run `klist` to inspect current Kerberos tickets. If tickets are absent or show the wrong realm/expiry, purge with `klist purge` and retry login. Also check whether other users can log on to the same machine successfully.

---

## Next Step

Perform fastest checks for H1 and H2 first — both can be ruled in or out in under two minutes via AD and require no access to cthompson's device. Report findings before committing to a resolution path.

---

## Evidence Assessment — Event Log Analysis

**Evidence window:** 2024-03-15 08:44–08:46, Security log on DESKTOP-FB022 and domain controller

---

### H1 — Account Lockout | Verdict: SUPPORTED

- **Event 4776 @ 08:44:01** — DC credential validation attempted for cthompson with error code `0xC000006A` (wrong password). Authentication is being attempted with incorrect credentials from DESKTOP-FB022.
- **Event 4625 @ 08:44:03, 08:44:28, 08:44:55** — Three consecutive interactive (Logon type 2) failures with "Unknown user name or bad password" from DESKTOP-FB022. Three bad-password attempts in quick succession is the exact trigger pattern for a lockout policy threshold.
- **Event 4740 @ 08:44:56** — "A user account was locked out" — cthompson explicitly locked, caller computer DESKTOP-FB022. This directly confirms H1.
- **Event 4625 @ 08:45:10** — Logon type 7 (Unlock attempt) fails with "Account locked out" — cthompson is already locked at this point and cannot authenticate.
- H1 is **confirmed by direct evidence**. The lockout event and its originating failures are all present.

---

### H2 — Expired Password | Verdict: CONTRADICTED

- **Event 4776 @ 08:44:01** — Error code is `0xC000006A` (wrong password). An expired password would produce `0xC0000071`. The credential validation is failing on a wrong value, not on age.
- **Event 4771 @ 08:45:44, 08:46:01, 08:46:33** — Kerberos pre-authentication failure code `0x18` (wrong password). Expired password produces Kerberos failure code `0x17`. No expiry code appears anywhere in the evidence window.
- H2 is **contradicted** — the error codes across both NTLM and Kerberos channels are consistently "wrong password," not "password expired."

---

### H3 — Profile Corruption or Missing Profile | Verdict: CONTRADICTED

- **Event 4625 @ 08:44:03** — The failure occurs at credential validation (Logon type 2, pre-authentication). A profile fault would only surface after successful authentication (Event 4624), which never occurs here. Every event in the log is a pre-authentication failure.
- **Event 4740 @ 08:44:56** — Lockout is an account-layer event entirely unrelated to the profile stack. No Event 4624 (successful logon) is present anywhere in the window, so profile loading is never reached.
- H3 is **contradicted** — the failure is at the credential layer, not the session/profile layer.

---

### H4 — Account Disabled or Expired | Verdict: CONTRADICTED

- **Event 4625 @ 08:44:03** — Failure reason is "Unknown user name or bad password," not "Account currently disabled." A disabled account produces a distinct failure reason and Sub Status code (`0xC0000072`).
- **Event 4776 @ 08:44:01** — The DC proceeds to validate credentials (the attempt reaches the validation step), which only occurs for enabled accounts. A disabled account is rejected before this step.
- **Event 4740 @ 08:44:56** — A disabled account cannot be locked out — lockout is only applied to enabled accounts. The presence of this event confirms the account was enabled at lockout time.
- H4 is **contradicted** by the failure reason codes and the lockout event itself.

---

### H5 — Cached Credential / Kerberos Ticket Issue | Verdict: PARTIALLY SUPPORTED (contributing factor, not root cause)

- **Event 4771 @ 08:45:44, 08:46:01, 08:46:33** — Kerberos pre-authentication failures from source IP **10.10.8.112**, which differs from DESKTOP-FB022 (10.10.1.88). This is a second device, unknown at this point, continuing to fire authentication attempts with failure code `0x18` (wrong password) even after cthompson is already locked.
- This second device holds a stale or incorrect cached credential for cthompson. This is not the root cause of the initial lockout (which originated from DESKTOP-FB022 per Event 4740), but it is a compounding factor — it will re-lock the account after any unlock if not addressed.
- H5 is **partially supported** as a secondary contributor: a second device with a wrong cached password is actively sustaining the problem. It does not independently explain the initial lockout.

---

## Surviving Hypothesis

**H1 — Account Lockout** is the sole confirmed root cause.

Three consecutive bad-password attempts from DESKTOP-FB022 (Events 4625 at 08:44:03, 08:44:28, 08:44:55) tripped the lockout policy threshold, producing Event 4740 at 08:44:56. H2, H3, and H4 are directly contradicted by error codes and event sequence. H5 survives only as a compounding factor — a second device at 10.10.8.112 with an incorrect cached credential that will re-trigger the lockout after any unlock unless cleared.

> The immediate cause is account lockout from DESKTOP-FB022. The secondary risk is a second device (10.10.8.112) holding a wrong cached credential that will re-lock the account. Both must be addressed in the resolution.

---

## Resolution Steps

### Immediate — Restore cthompson's access

1. Unlock the account in Active Directory:
   ```powershell
   Unlock-ADAccount -Identity cthompson
   ```
   Confirm with:
   ```powershell
   Get-ADUser cthompson -Properties LockedOut | Select-Object Name, LockedOut
   ```
   Expected result: `LockedOut = False`.

2. Have cthompson set a new password immediately (either via SSPR portal or helpdesk reset), so the wrong cached credential on all devices becomes invalid.
   Expected result: Any further attempts using the old wrong password will fail on a fresh credential, not re-lock the account under the new password context.

### Critical — Identify and clear the second device (10.10.8.112)

3. Identify the device at IP 10.10.8.112 (check DHCP lease or DNS reverse lookup). This device is firing Kerberos requests with a wrong password (Events 4771 at 08:45:44, 08:46:01, 08:46:33) and will re-lock the account after unlock if not resolved.
   ```powershell
   Resolve-DnsName 10.10.8.112
   ```

4. On the identified device, clear all saved credentials for cthompson's account:
   - Windows Credential Manager: remove any entry for FINBRIDGE\cthompson or the domain.
   - If a mobile device (Intune/Exchange ActiveSync): prompt re-authentication or wipe the account profile.
   Expected result: No further Kerberos failures from 10.10.8.112 after password is reset.

### Verification

5. Ask cthompson to log on to DESKTOP-FB022 with the new password and confirm desktop loads successfully.
6. Monitor the Security event log for Event 4625 or 4771 for cthompson for 15 minutes post-resolution to confirm no re-lock occurs.
   Expected result: No further lockout events (4740) for cthompson.
