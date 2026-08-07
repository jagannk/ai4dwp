Title: Runbook - Account Lockout Recovery (AD User)
Version: 1.0
Date: 07/08/2026
Author: Sathishbabu
reviewed: self
status: draft
change: initila version from RCA

# Runbook - Account Lockout Recovery (AD User)

## 1. Prerequisites

- Confirm you have the incident ticket number, affected username, and a 30-minute event window.
- Confirm you have the affected endpoint hostname (for example, DESKTOP-FB001).
- Confirm you can access the domain controller Security log in Event Viewer. **[ELEVATED]**
- Confirm you can use Active Directory Users and Computers (ADUC) or Active Directory Administrative Center (ADAC). **[ELEVATED]**
- Confirm you have rights to unlock/enable domain user accounts. **[ELEVATED]**
- Confirm you can remotely connect to the affected endpoint to inspect Credential Manager and startup tasks. **[ELEVATED]**
- Confirm RSAT Active Directory tools are installed on your admin workstation.
- Confirm user is reachable by phone or Teams for immediate logon validation.

## 2. Procedure

1. Open the incident ticket in ServiceNow and copy the exact value in the `Affected User` field into your notes.
   - Expected result: One exact username string is captured (example: `jsmith`) with no spelling differences.

2. Sign in to a writable domain controller with your admin account and launch Event Viewer from `Server Manager > Tools > Event Viewer`. **[ELEVATED]**
   - Expected result: Event Viewer opens on the domain controller desktop.

3. Click `Windows Logs > Security` in Event Viewer. **[ELEVATED]**
   - Expected result: Security log entries are listed in the center pane.

4. Click `Filter Current Log...` in the right `Actions` pane. **[ELEVATED]**
   - Expected result: The `Filter Current Log` dialog is open.

5. Enter `4625,4740,4722,4624` in `Includes/Excludes Event IDs` and set `Logged` to `Custom range...` matching the incident window, then click `OK`. **[ELEVATED]**
   - Expected result: Only those four event IDs are shown for the selected time range.

6. Click `Find...` in the right `Actions` pane, type the username from Step 1, and click `Find Next`. **[ELEVATED]**
   - Expected result: The first event containing the exact username is highlighted.

7. Sort by `Date and Time` descending and open the newest Event ID `4740` for that username. **[ELEVATED]**
   - Expected result: The event details window shows a lockout event for the correct account.

8. In the Event ID `4740` details, record the value of `Caller Computer Name`. **[ELEVATED]**
   - Expected result: A single source host is captured in notes (example: `DESKTOP-FB001`).

9. Open the two Event ID `4625` entries immediately before that `4740` timestamp for the same username. **[ELEVATED]**
   - Expected result: Two failed logon events directly preceding lockout are displayed.

10. In each of those two `4625` events, record `Failure Reason` and `Logon Type` from the `General` tab. **[ELEVATED]**
   - Expected result: You have the exact failure reason text and numeric logon type values in notes.

11. Open ADUC by running `dsa.msc` and browse to the user object in `Domain > Users` (or the user OU). **[ELEVATED]**
   - Expected result: The correct user object is selected in ADUC.

12. Right-click the user object and select `Properties`, then open the `Account` tab. **[ELEVATED]**
   - Expected result: The account state controls are visible for that user.

13. If present, tick `Unlock account` and click `Apply`. **[ELEVATED]**
   - Expected result: The unlock checkbox clears after apply and no lockout warning remains.

14. If the user icon has a down-arrow or context menu shows `Enable Account`, right-click user and click `Enable Account`. **[ELEVATED]**
   - Expected result: A confirmation message shows the account was enabled and the down-arrow overlay is removed.

15. Remote to the source host from Step 8 and open `Control Panel > User Accounts > Credential Manager > Windows Credentials`. **[ELEVATED]**
   - Expected result: Saved Windows credentials are listed.

16. Remove each credential entry that references the affected domain user or old password target (for example `TERMSRV`, file share, or mail profile entries tied to that user). **[ELEVATED]**
   - Expected result: Targeted stale entries are no longer present in the credentials list.

17. Open PowerShell as Administrator on the source host and run `Get-ScheduledTask | Where-Object { $_.Principal.UserId -match 'jsmith' } | Select-Object TaskPath,TaskName,State`. **[ELEVATED]**
   - Expected result: You get either an empty result or a list of tasks running as the affected user.

18. Run `Disable-ScheduledTask -TaskPath '<TaskPath>' -TaskName '<TaskName>'` for each task returned in Step 17 that is not business-critical. **[ELEVATED]**
   - Expected result: Each targeted task state changes to `Disabled`.

19. Ask the user to sign in once on the affected endpoint using the current password.
   - Expected result: Windows sign-in completes and the desktop loads without account lock message.

20. In the Security log view, keep the user-filtered results open for 5 minutes after sign-in. **[ELEVATED]**
   - Expected result: No new Event ID `4740` appears for that username.

## 3. Verification

1. In Event Viewer Security log, locate Event ID `4624` for the affected username after the unlock timestamp. **[ELEVATED]**
   - Success looks like: `4624` exists after remediation time and `Account Name` exactly matches the affected user.

2. In the same filtered view, check for Event ID `4740` for 5 minutes after the successful sign-in time. **[ELEVATED]**
   - Success looks like: Zero new `4740` entries are generated for that username.

3. In the same 5-minute window, check Event ID `4625` entries where `Caller Computer Name` equals the source host recorded earlier. **[ELEVATED]**
   - Success looks like: No repeated `4625` pattern (3 or more failures) is present from that source host.

4. Ask the user to open Outlook/Teams and one required line-of-business application while on call.
   - Success looks like: User confirms each required app opens without credential prompts or access denied errors.

5. Update and close the incident ticket with lockout source host, key event timestamps, and remediation actions.
   - Success looks like: Ticket work notes contain enough detail for audit replay and closure reason is accepted by queue policy.

## 4. Rollback

Use this rollback only when remediation caused a worse state. Steps 1-5 are the 3-minute containment path and do not depend on end-user response time.

1. On the source endpoint, open `Task Scheduler` (`Start > Task Scheduler Library`), right-click each task you disabled during remediation, and click `Enable`. **[ELEVATED]**
   - Immediate outcome: Previously disabled business tasks return to `Ready` state in the center pane.

2. In Event Viewer on the domain controller (`Server Manager > Tools > Event Viewer > Windows Logs > Security`), open `Filter Current Log...`, set Event ID to `4740`, and click `OK`. **[ELEVATED]**
   - Immediate outcome: You can immediately see whether a fresh lockout event is being generated.

3. If a new `4740` appears, open ADUC (`Start > Run > dsa.msc`), open the correct user (`Domain > Users > user > Properties > Account`), tick `Unlock account`, and click `Apply`. **[ELEVATED]**
   - Immediate outcome: User account lock state is cleared again within seconds.

4. In ADUC on the same user, click `Reset Password...`, set a temporary password, tick `User must change password at next logon`, and click `OK`. **[ELEVATED]**
   - Immediate outcome: Old cached credentials become invalid and repeated bad-password retries stop on next authentication cycle.

5. On the source endpoint, open `Command Prompt (Admin)` and run `shutdown /l` to sign out the current session immediately. **[ELEVATED]**
   - Immediate outcome: Any in-session cached token replay is terminated.

6. Back in Event Viewer Security log, refresh once (`Action > Refresh`) after 60 seconds. **[ELEVATED]**
   - Immediate outcome: No new `4740` for the user confirms rollback stabilized the incident.

7. After containment is stable, ask the user to sign in using the temporary password and change it at prompt.
   - Immediate outcome: User reaches desktop and password is updated to a user-known value.

If Step 6 still shows a new `4740`, escalate immediately to IAM/SOC with the latest `Caller Computer Name` from that event.

## 5. Notes

- Edge case: Event ID 4740 may be logged on a different domain controller than expected; check all writable DCs if not found initially.
- Edge case: AVD/VDI pooled hosts can generate hidden retry traffic; include broker/session hosts in source checks.
- Warning: Do not leave critical scheduled tasks disabled without service owner approval.
- Warning: Unlocking without clearing stale credentials often causes immediate re-lockout.
- Related incident pattern: Bad password bursts followed by 4740 and then a successful 4624 after admin unlock indicates credential replay from endpoint cache.
- Related incidents to compare: password change not propagated to saved credentials, mapped drives using old credentials, service account tasks configured with expired password.
