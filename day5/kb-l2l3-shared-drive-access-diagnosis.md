Title: L2/L3 KB - Finance Shared Drive Access Failure - Diagnosis and Recovery (DWP)
Version: v 1.0
Date: 10/08/2026
Status: Draft

## Background
Finance team members access a shared drive (mapped as F: via Group Policy) hosted on the file server FS01 under the DFS path \\corp.local\shares\Finance. Access is controlled by the AD security group FIN-ShareAccess. Loss of access prevents finance staff from retrieving invoices, reports, and budgets, causing business-critical impact. Fast root cause isolation is required to avoid incorrect or repeated remediation.

## Symptom
Engineer observes:
- Drive mapping F: is missing from File Explorer for affected users.
- UNC path \\finance-server\Finance returns "Network path not found" or "Access is denied".
- Event log on file server shows repeated failed connection attempts or permission denials.
- GPO processing logs show drive map policy not applied or skipped.

User reports:
- "My F: drive has disappeared."
- "I get an error saying I do not have permission to access Finance."
- "The Finance folder shows but I cannot open it."
- "It was working yesterday and nothing changed on my side."

## Root Cause
Specific technical cause confirmed by RCA:
- The AD security group FIN-ShareAccess had its membership cleared during a routine AD cleanup script run with overly broad scope.
- All Finance team user accounts were removed from the group, revoking their NTFS and share-level permissions on \\FS01\Finance.
- Because the GPO drive map uses group membership as a targeting filter (Item-Level Targeting), the drive mapping also stopped applying at next logon/GP refresh.

Evidence that confirms it:
- Event ID 4625 / 5140 on FS01 showing access denied for Finance user accounts against the Finance share.
- Event ID 4727 / 4729 on the Domain Controller confirming group member removal events for FIN-ShareAccess.
- GPO operational log (Microsoft-Windows-GroupPolicy/Operational) on affected endpoints shows drive map item skipped due to failed ILT evaluation.
- AD group FIN-ShareAccess shows 0 members at time of incident.

## Detection
Run all checks before remediation.

1. On a Domain Controller, open Active Directory Users and Computers (dsa.msc), navigate to the FIN-ShareAccess security group, and check the Members tab.
Expected evidence: Group shows 0 members or is missing expected Finance user accounts.

2. On a Domain Controller, open Event Viewer at Windows Logs > Security, filter Event IDs 4727 and 4729 for the incident time window, and search for the group name FIN-ShareAccess.
Log location and fields: Windows Logs/Security, Event 4729 (member removed), fields Group Name, Member Account Name, Subject (actor), TimeCreated.
Expected evidence: Bulk member removal events for FIN-ShareAccess at the time of the cleanup script execution.

3. On the file server FS01, open Event Viewer at Windows Logs > Security, filter Event ID 5140 (network share access) and 5145 (share object access check) for the incident time window.
Log location and fields: Windows Logs/Security, Event 5140/5145, fields Share Name, Account Name, Access, Keywords (Audit Failure).
Expected evidence: Repeated Audit Failure entries for Finance user accounts against \\FS01\Finance.

4. On an affected endpoint, open the Group Policy operational log at Event Viewer > Applications and Services Logs > Microsoft > Windows > GroupPolicy > Operational and filter for the most recent GP refresh.
Log location and fields: GroupPolicy/Operational, drive preference events, fields Policy Name, Reason (ILT failure), TimeCreated.
Expected evidence: Drive map for F: shows item skipped or ILT targeting returned false for Finance group.

5. On an affected endpoint, open PowerShell and run:
   gpresult /r /scope user
Expected evidence: The Finance drive map policy is listed under Denied GPOs or Item-Level Targeting is shown as not met.

6. On the file server FS01, open Server Manager > File and Storage Services > Shares, select the Finance share, and review Share Permissions and NTFS Security.
Comparison check: Confirm FIN-ShareAccess group is listed with Read/Change or Full Control at share level and Modify or Read & Execute at NTFS level.
Expected evidence: FIN-ShareAccess is absent from permissions or shows No Access.

## Resolution
Perform in order.

1. Domain Controller path: Open ADUC (dsa.msc) > find group FIN-ShareAccess > Members tab > Add all Finance team accounts back to the group.
Expected result: All affected user accounts are listed as members of FIN-ShareAccess.

2. Domain Controller path: Verify in ADUC that each added user shows FIN-ShareAccess under their Member Of tab.
Expected result: Group membership is confirmed for each Finance team account.

3. On an affected endpoint (or ask the user): Run gpupdate /force in a command prompt, then sign out and sign back in.
Expected result: GP refresh applies drive map policy and F: drive reappears in File Explorer.

4. On the file server FS01: Open Server Manager > Shares > Finance share, confirm FIN-ShareAccess has Modify NTFS permission and at least Change/Read share permission. Restore if missing.
Expected result: Share and NTFS permissions are correct and FIN-ShareAccess is listed.

5. Ask one affected Finance user to attempt to open the F: drive.
Expected result: Drive opens without access denied error and Finance files are accessible.

6. Confirm with the Finance team lead that all team members have regained access.
Expected result: No further access denied reports from Finance team.

7. Escalate to the AD/Infrastructure team to review the cleanup script scope and add FIN-ShareAccess to the exclusion list to prevent recurrence.
Expected result: Change request or problem ticket raised for script review and protection of business-critical groups.

## Post-Incident Notes
- Review all AD cleanup or automation scripts for overly broad group membership scope.
- Add protected AD groups (FIN-ShareAccess and similar) to a "do not modify" OU or tag with a custom attribute checked by scripts before making changes.
- Consider enabling AD Recycle Bin if not already active to allow faster membership restore in future.
- Raise a Problem ticket to track root cause remediation and script audit.
