Title: Closure Note — Account Lockout / Login Failure (cthompson)
Incident: FINBRIDGE\cthompson — DESKTOP-FB022
Date: 2024-03-15 | Resolved: 09:09

---

Resolved. Cause: Account locked out (Event 4740 @ 08:44:56) after three consecutive failed interactive login attempts with an incorrect password from DESKTOP-FB022; a second device (10.10.8.112) held a stale cached credential and continued firing Kerberos pre-authentication failures (Events 4771 @ 08:45:44–08:46:33) post-lockout, creating a re-lock risk. Action: Account re-enabled by helpdesk-admin (Event 4722 @ 09:08:14), password reset, and stale saved credential cleared from the second device at 10.10.8.112. Preventive: Implement account lockout alerting on Event 4740 and pre-lockout threshold alerting on 3+ Event 4625 failures per account within 10 minutes; update lockout runbook to check for secondary-device Kerberos failures (Event 4771) before closing; distribute credential-update checklist to users on every password reset. User confirmed working — Event 4624 (successful interactive logon, DESKTOP-FB022) recorded @ 09:09:01.
