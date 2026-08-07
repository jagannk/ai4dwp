# Account Lockout RCA - jsmith

## Incident Summary

- User: jsmith
- Symptom: User was locked out of machine during a 30-minute incident window.
- Primary host seen in events: DESKTOP-FB001
- Outcome: Account was re-enabled by helpdesk, then user successfully logged on.

## Event ID Meaning (What Each Event Records)

### Event ID 4625 (Audit Failure - Failed Logon)
This event records a failed sign-in attempt. It includes failure reason, source workstation, and logon type.

In this incident:
- Failure reason at 08:02:14 and 08:04:22: Unknown username or bad password.
- Failure reason at 08:07:45: Account locked out.

### Event ID 4740 (Audit Failure - Account Locked Out)
This event records that the account lockout threshold was reached and the account was locked by policy.

In this incident:
- 08:06:01 shows jsmith locked out, called from DESKTOP-FB001.

### Event ID 4722 (Audit Success - Account Enabled)
This event records that an account was enabled (or re-enabled) by an administrator.

In this incident:
- 08:22:10 shows jsmith account enabled by FINBRIDGE\helpdesk-admin.

### Event ID 4624 (Audit Success - Successful Logon)
This event records a successful sign-in.

In this incident:
- 08:23:44 shows successful interactive sign-in for jsmith.

## Reconstructed Sequence of Events (Plain English)

1. At 08:02:14, an interactive sign-in attempt for jsmith failed on DESKTOP-FB001 with bad username/password.
2. At 08:04:22, a second interactive sign-in attempt failed with the same bad password reason.
3. At 08:06:01, account lockout occurred for jsmith. The lockout event points to DESKTOP-FB001 as the calling machine.
4. At 08:07:45, another sign-in attempt occurred as an unlock action (logon type 7), but it failed because the account was already locked.
5. At 08:22:10, helpdesk-admin re-enabled the account.
6. At 08:23:44, jsmith successfully logged on interactively.

## Most Likely Cause of Lockout

Most likely cause:
Repeated bad password attempts on DESKTOP-FB001 triggered the account lockout policy threshold.

Evidence:
- Multiple 4625 failures before lockout with reason Unknown username or bad password.
- 4740 lockout event explicitly identifies DESKTOP-FB001 as the calling system.
- Post-lockout 4625 (logon type 7) shows user/device continued trying while account was locked.
- After administrative re-enable (4722), successful logon (4624) occurred, indicating credentials were likely corrected and account state restored.

## Root Cause Analysis (RCA)

### Technical Root Cause
The account lockout was caused by repeated failed authentication attempts for jsmith from DESKTOP-FB001 until lockout threshold was reached.

### Contributing Factors
- User entered incorrect password multiple times, or stale cached credentials were repeatedly submitted from the endpoint.
- Unlock attempt was made after lockout, generating additional failed event noise.
- Recovery required manual helpdesk intervention to re-enable account.

### Impact
- User could not access workstation until account was re-enabled.
- Productivity interruption of approximately 21-22 minutes from lockout to successful sign-in.

### 5 Why Analysis

1. Why was jsmith unable to access the machine?
- Because the account was locked out (4740), and subsequent unlock attempt failed due to lock state (4625 with account locked out).

2. Why was the account locked out?
- Because repeated failed sign-in attempts were made with bad credentials (multiple 4625 failures).

3. Why were repeated failed attempts occurring?
- Most likely incorrect password entry sequence or a stale saved credential retrying on DESKTOP-FB001.

4. Why did the issue persist until helpdesk action?
- The account remained locked until an administrator re-enabled it (4722); user attempts alone could not clear lockout.

5. Why was service restoration dependent on manual intervention?
- Lockout policy and process required admin action to restore account access in this case.

### Corrective Actions

Immediate:
- Confirm user password reset/re-entry and test sign-in.
- Check for cached credentials and mapped resources on DESKTOP-FB001 that may retry old credentials.

Preventive:
- User guidance on password update sequence (sign out/in on all sessions after password change).
- Review lockout threshold balance between security and usability.
- Enable lockout diagnostics runbook for rapid source validation (workstation, scheduled tasks, services, credential manager entries).

## Confidence and Verification Notes

- High confidence in lockout sequence and source machine attribution from 4625 and 4740 events.
- Medium confidence on exact upstream trigger (manual mistype vs cached credential) because those evidence points are not present in the provided excerpt.
- Verify account lockout policy values and credential cache state if deeper forensic certainty is required.
