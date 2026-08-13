Title: End-User Communications — Account Lockout Incident (cthompson)
Incident: FINBRIDGE\cthompson login failure — DESKTOP-FB022
Date: 2024-03-15
Incident Window: 08:40 – 09:09
Source: hypothesis-analysis-cthompson-login-failure.md / rca-cthompson-account-lockout-login-failure.md

---

## Audience 1 — Non-Technical Executive

Your account and data are completely safe — nothing was lost or accessed without authorisation.

This morning, one team member was temporarily unable to log in after their account was automatically locked following several failed password attempts. IT identified the cause, re-enabled the account, and reset the password. The employee was back at work by 09:09. No other users were affected.

No action is required from you.

---

## Audience 2 — Affected Team (Non-Technical)

Hi team,

This morning, one of your colleagues was briefly locked out of their account after too many incorrect password attempts triggered an automatic security lock — IT re-enabled the account and reset the password, and they were back online by 09:09.

If you ever find yourself locked out and cannot log in, do not keep retrying — it will make things worse. Instead, contact the IT Service Desk straight away so we can unlock your account quickly.

**Contact:** IT Service Desk — Teams chat or email servicedesk@company.com

---

## Audience 3 — Engineer-to-Engineer Internal Note

**User:** FINBRIDGE\cthompson
**Device:** DESKTOP-FB022 (10.10.1.88)
**Window:** 2024-03-15 08:40–09:09 | **Resolved by:** helpdesk-admin @ 09:08:14

### Root Cause

Account locked (Event 4740 @ 08:44:56, caller: DESKTOP-FB022) after three consecutive interactive logon failures (Events 4625 @ 08:44:03, 08:44:28, 08:44:55) — NTLM error code `0xC000006A` (wrong password). Lockout policy threshold triggered on the third failure.

Compounding factor: second device at 10.10.8.112 (separate from DESKTOP-FB022/10.10.1.88) firing Kerberos pre-auth failures (Events 4771 @ 08:45:44, 08:46:01, 08:46:33) with failure code `0x18` (wrong password) — stale cached credential. Would have re-locked the account after any simple unlock if not addressed.

All other hypotheses contradicted: error codes rule out expired password (`0xC0000071`/`0x17`) and disabled account (`0xC0000072`); no Event 4624 reached so profile faults ruled out; account reached validation step confirming it was enabled at time of first failure.

### Action Taken

1. Account re-enabled/unlocked by helpdesk-admin — **Event 4722 @ 09:08:14** (account enabled, performed by FINBRIDGE\helpdesk-admin).
2. cthompson password reset by helpdesk; user informed to update credentials on all devices.
3. Second device at 10.10.8.112 identified via DHCP/DNS; stale saved credential for FINBRIDGE\cthompson cleared from Windows Credential Manager.

### Config Detail

- Lockout triggered from: DESKTOP-FB022 (10.10.1.88) — interactive logon, 3 failures within ~52 seconds
- Second device firing stale Kerberos: 10.10.8.112 — post-lockout, wrong password cached credential
- NTLM error code: `0xC000006A` | Kerberos failure code: `0x18` — both = wrong password
- Resolution actor: FINBRIDGE\helpdesk-admin (Event 4722)

### Verification Step

**Event 4624 @ 09:09:01** — "An account was successfully logged on" — FINBRIDGE\cthompson, Logon type 2 (Interactive), source DESKTOP-FB022. Desktop loaded without error. Security log monitored post-resolution — no further Events 4625 or 4740 for cthompson.

### Preventive Action Needed

1. **Account lockout alert** — create SIEM/Azure Monitor alert on Event 4740 for any account; route to Service Desk queue as P2. Currently no proactive alerting — incidents surface only via user report.
2. **Pre-lockout threshold alert** — alert on 3+ Event 4625 failures for the same account within 10 minutes, before lockout fires.
3. **Stale credential runbook step** — update account lockout runbook: when unlocking, always check for Event 4771 entries from source IPs other than the reported device; identify and clear credential on any secondary device before closing.
4. **User guidance on password change** — send credential-update checklist on every helpdesk or SSPR password reset: Windows Credential Manager, mobile mail profile, saved browser credentials.
5. **SSPR / self-service unlock** — if not already enabled, activate Azure AD Self-Service Password Reset to reduce resolution time from ~29 min to under 5 min for future occurrences.
