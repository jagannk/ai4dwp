Title: L2/L3 KB - AD Account Lockout Diagnosis and Recovery (DWP)
Version: v 1.0
Date: 07/08/2026
Status: Draft

## Background
This service allows staff to sign in to Windows, Outlook, Teams, and business apps using one corporate account. If the account is locked, the user cannot sign in and may also lose access to email and app sessions. Fast and accurate diagnosis matters because repeated bad sign-in attempts can keep re-locking the account even after helpdesk unlocks it.

## Symptom
Engineer observes:
- Security events show repeated failed sign-ins followed by account lockout.
- Lockout may reoccur shortly after unlock.
- Same caller computer name appears before each lockout.

User reports:
- "My password was working earlier, now I am locked out."
- "I can sometimes sign in, then it locks again."
- "Outlook or Teams keeps asking for password."

## Root Cause
Specific technical cause:
- Repeated bad credential submissions from one endpoint or active session hit account lockout threshold.

Evidence that confirms it:
- Event ID 4625 (failed logon) appears multiple times before lockout.
- Event ID 4740 confirms account lockout and identifies Caller Computer Name.
- Event ID 4722 confirms admin re-enable/unlock action.
- Event ID 4624 confirms successful sign-in after remediation.
- Re-lockout after unlock indicates stale cached credential replay or scheduled task/service using old password.

## Detection
Run all checks before remediation.

1. On a domain controller, open Event Viewer at Server Manager > Tools > Event Viewer > Windows Logs > Security, then filter Event IDs to 4625,4740,4722,4624 for the incident time range.
Expected evidence: Only relevant auth events are shown for timeline reconstruction.

2. In the same Security log, use Find for the exact username, then open latest Event ID 4740.
Log location and fields: Windows Logs/Security, Event 4740, fields Account Name and Caller Computer Name.
Expected evidence: Account Name matches impacted user and Caller Computer Name identifies lockout source.

3. In Security log, open the two Event ID 4625 entries immediately before 4740 for the same user.
Log location and fields: Windows Logs/Security, Event 4625, fields Failure Reason, Status/SubStatus, Logon Type, Workstation Name.
Expected evidence: Failure Reason indicates bad password or account locked; logon type helps identify interactive vs unlock attempt.

4. In Security log, confirm whether Event ID 4722 occurred after lockout.
Log location and fields: Windows Logs/Security, Event 4722, fields Subject (admin actor), Target Account Name, TimeCreated.
Expected evidence: Admin action timestamp is present for account re-enable/unlock activity.

5. In Security log, confirm whether Event ID 4624 appears after 4722.
Log location and fields: Windows Logs/Security, Event 4624, fields Account Name, Logon Type, Workstation Name, TimeCreated.
Expected evidence: Successful logon for affected user after recovery action.

6. In Azure portal, compare AVD lockout correlation between two pools at Azure Portal > Azure Virtual Desktop > Host pools > Pool1 > Insights and Azure Portal > Azure Virtual Desktop > Host pools > Pool2 > Insights.
Comparison check (Pool2 vs Pool1): Compare failed sign-in trend and active session count for the same 30-minute window.
Expected evidence: One pool shows higher failure/session churn and is the likely replay source path.

## Resolution
Perform in order.

1. Azure portal path: Azure Portal > Virtual machines > DC management VM > Connect > Bastion, then open Event Viewer and confirm latest 4740 Caller Computer Name before making changes.
Expected result: You have one confirmed source machine to target first.

2. Azure portal path: Azure Portal > Azure Virtual Desktop > Host pools > affected pool (Pool1 or Pool2) > Session hosts > user session > Disconnect or Log off stale sessions for affected user.
Expected result: Active stale sessions that can replay old credentials are terminated.

3. Azure portal path: Azure Portal > Virtual machines > DC management VM > Connect > Bastion, then open ADUC (dsa.msc), locate user, tick Unlock account on Account tab, Apply.
Expected result: Lockout state clears for the user account.

4. Azure portal path: Azure Portal > Virtual machines > DC management VM > Connect > Bastion, in ADUC check if account is disabled and click Enable Account if required.
Expected result: Account is enabled and available for authentication.

5. Azure portal path: Azure Portal > Virtual machines > source endpoint VM (or management jump VM to source endpoint) > Connect, then open Control Panel > User Accounts > Credential Manager > Windows Credentials and remove stale entries for affected account.
Expected result: Cached credentials that replay old passwords are removed.

6. Azure portal path: Azure Portal > Virtual machines > source endpoint VM > Connect, open PowerShell (Admin), run Get-ScheduledTask filter for affected user and disable offending tasks.
Expected result: No scheduled task continues automated bad-password attempts.

7. Azure portal path: Azure Portal > Azure Virtual Desktop > Host pools > affected pool > Session hosts, confirm host is Available, then ask user to sign in once with correct password.
Expected result: User reaches desktop without lockout message.

## Verification
1. Event Viewer path: Server Manager > Tools > Event Viewer > Windows Logs > Security.
Check: New Event ID 4624 exists for user after remediation.
Success: Account Name matches user and timestamp is after unlock action.

2. Event Viewer path: same Security log view with Event ID 4740 filter.
Check: Observe for 5 minutes after sign-in.
Success: Zero new 4740 events for affected user.

3. Event Viewer path: same Security log view with Event ID 4625 filter.
Check: Caller Computer Name equals previous source host.
Success: No repeated 4625 burst (three or more failures) in verification window.

4. Azure portal path: Azure Portal > Azure Virtual Desktop > Host pools > Pool1 and Pool2 > Insights.
Check: Compare post-fix failed sign-in trend and session churn.
Success: Previously affected pool normalizes and no divergence vs peer pool.

## Rollback
Use only if remediation increases lockouts or blocks user access.

1. Azure portal path: Azure Portal > Virtual machines > source endpoint VM > Connect > Task Scheduler Library, re-enable only tasks disabled during this incident.
Immediate result: Required automation resumes.

2. Azure portal path: Azure Portal > Virtual machines > DC management VM > Connect > Event Viewer > Security (4740 filter), confirm whether lockout is still firing.
Immediate result: You know if containment failed.

3. Azure portal path: Azure Portal > Virtual machines > DC management VM > Connect > ADUC, reset password to temporary value and enforce change at next logon.
Immediate result: Old cached credentials become invalid.

4. Azure portal path: Azure Portal > Azure Virtual Desktop > Host pools > affected pool > Session hosts > user session, force logoff all remaining sessions for user.
Immediate result: Remaining token replay paths are removed.

5. Azure portal path: Azure Portal > Monitor > Alerts, raise high-priority IAM/SOC escalation with latest 4740 Caller Computer Name and timestamps if lockout persists.
Immediate result: Security/identity team takes ownership with actionable evidence.

## Preventive
1. DWP engineer, after deployment, runs a scheduled lockout-correlation script that parses Event IDs 4625 and 4740 and emails Caller Computer Name, user, and timestamp to the DWP queue; pass = report delivered by 08:00 with zero missing fields, fail = any blank host/user/timestamp field creates a P2 tooling ticket the same day. Automated. [REQUIRES: scheduled reporting script and mail relay]

2. Service desk lead, after deployment at ticket closure, enforces mandatory ServiceNow fields for Caller Computer Name, two preceding 4625 Failure Reasons, and post-fix 4624 timestamp; pass = 100% of closed lockout tickets contain all three data points, fail = closure blocked and ticket returned to resolver. Manual now; automate with ServiceNow mandatory field policy. [REQUIRES: ServiceNow form rule]

3. Service desk lead, before deployment of password-reset communications and during every password-reset process, issues a standard user checklist: sign out of all sessions, remove saved credentials, then sign in once per device; pass = user confirms all three actions in ticket notes, fail = ticket stays open and is routed to DWP engineer for guided cleanup. Manual now; automate with password-reset email template and portal checklist.

4. DWP engineer, after deployment each day, compares Pool2 vs Pool1 failed sign-in trend in Azure Portal > Azure Virtual Desktop > Host pools > Pool1/Pool2 > Insights; pass = difference in failed sign-ins is less than 20% over 24 hours, fail = proactive incident opened with pool name, counts, and top source host. Manual now; automate with Azure Monitor workbook and alert rule. [REQUIRES: AVD Insights workbook/alert]

5. Image owner, before deployment of shared endpoint changes and after any password-change incident, reviews the controlled list of scheduled tasks running under user context on shared endpoints; pass = zero tasks run with stale user credentials, fail = task is disabled or converted to service account before change closure. Manual now; automate with scheduled task inventory export. [REQUIRES: shared endpoint task inventory]

6. Release engineer, before deployment, runs a pre-deployment smoke test on one non-production endpoint using the target image and one test user account; pass = zero Event IDs 4625 and 4740 during one sign-in and sign-out cycle, fail = deployment does not start and change manager is notified. Manual now; automate with pre-release sign-in test job. [REQUIRES: pre-production test endpoint]

7. DWP engineer, during deployment, monitors Azure Portal > Azure Monitor > Alerts and Security log events on the DC for the rollout window; pass = fewer than 3 Event ID 4625 entries per user per 15 minutes and zero Event ID 4740 spikes above baseline, fail = pause rollout and drain affected pool immediately. Automated alerting preferred; manual monitoring acceptable until alert exists. [REQUIRES: Azure Monitor alert and DC event collection]

8. Change manager, after deployment before change closure, validates healthy state using one sampled ticket or test user per affected pool; pass = one Event ID 4624 exists after change and zero new Event ID 4740 events occur for 30 minutes, fail = change remains open and remediation owner is assigned. Manual.

9. Release engineer, during deployment, applies the rollback trigger if any pool shows 2 or more user lockouts (Event ID 4740) in 15 minutes or failed sign-ins rise above the peer pool by 25%; pass = threshold not met, fail = stop rollout, set affected host pool to no new sessions, and invoke rollback plan. Automated alerting preferred; manual threshold check until alert exists. [REQUIRES: pool-level lockout threshold monitoring]

10. DWP engineer, after deployment and after every confirmed incident, updates the runbook and checklist within 2 business days with new source host patterns, task findings, and verification evidence; pass = document version/date updated and linked in ticket problem record, fail = problem review remains open under service desk lead. Manual.

## Related
- Related runbook: day5/runbook-account-lockout-recovery.md
- Related L1 self-service article: day5/kb-account-lockout-self-service.md
- Related incident note: day3/account-lockout-rca-jsmith.md
- Related pattern: day2/triage-summary-t1002-shared-mailbox.md
- Related pattern: day2/triage-summary-t1007-onedrive-sync.md
- Related environment symptom set: day2/triage-summary-t1003-avd-disconnect.md
