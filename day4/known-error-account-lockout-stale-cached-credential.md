Title: Known Error Record — Account Lockout / Login Failure (Stale Cached Credential on Secondary Device)
Knowledge Base ID: KE-AD-001
Source Incident: FINBRIDGE\cthompson — DESKTOP-FB022 — 2024-03-15
Status: Verified

---

**Symptom**
The user is unable to log in interactively and receives an "Unknown user name or bad password" or "Account locked out" error at the Windows login screen. The failure occurs at the credential prompt — the desktop never loads.

**Cause**
Three consecutive failed login attempts with an incorrect password from the user's primary workstation trip the domain lockout policy threshold, locking the account (Event 4740). A secondary device holding a stale cached credential for the same account then continues firing Kerberos pre-authentication requests with the wrong password (Event 4771), re-locking the account after any unlock if the secondary device is not addressed.

**Scope**
The affected user only — account lockout is per-user and does not impact other accounts or devices. Any device the user has previously authenticated from that holds a saved credential becomes a compounding source if that credential is out of date.

**Workaround**
Unlock the account in Active Directory (`Unlock-ADAccount -Identity <username>`) and immediately identify any secondary devices firing Event 4771 failures for the account (check source IP against device inventory). Clear the stale saved credential on those devices before the user retries login, otherwise the account will re-lock.

**Permanent Fix**
Reset the user's password and instruct them to update saved credentials on all devices (Windows Credential Manager, mobile mail profile, saved browser credentials). Pin preventive alerting on Event 4740 and on 3+ Event 4625 failures per account within 10 minutes so future lockouts are surfaced before the user reports them.

**How to Spot It**
On the domain controller Security log: **Event 4740** (account locked out) identifies the locking caller device. **Event 4776** with error code `0xC000006A` and **Event 4625** with reason "Unknown user name or bad password" confirm wrong-password failures — not expired (`0xC0000071`) or disabled (`0xC0000072`). **Event 4771** with failure code `0x18` from a source IP different to the reported workstation identifies a secondary device holding a stale credential. Absence of **Event 4624** (successful logon) throughout the window confirms the failure is entirely at the authentication layer.
