Title: Runbook - Finance Shared Drive Access Recovery (AD Group / GPO Drive Map)
Version: 1.0
Date: 10/08/2026
Author: Training
Reviewed: Self
Status: Draft
Change: Initial version from RCA - Finance team cannot access shared drives

# Runbook - Finance Shared Drive Access Recovery (AD Group / GPO Drive Map)

## 1. Prerequisites

- Confirm you have the incident ticket number, list of affected usernames, and the reported start time of the issue.
- Confirm you have the name of the affected file share (default: \\FS01\Finance, DFS path: \\corp.local\shares\Finance).
- Confirm you can access Active Directory Users and Computers (ADUC) or Active Directory Administrative Center (ADAC). **[ELEVATED]**
- Confirm you have rights to modify AD group membership for FIN-ShareAccess. **[ELEVATED]**
- Confirm you can access the Domain Controller Security event log in Event Viewer. **[ELEVATED]**
- Confirm you can access the file server FS01 event log and share permissions. **[ELEVATED]**
- Confirm RSAT Active Directory tools are installed on your admin workstation.
- Confirm you can remotely trigger a Group Policy refresh on affected endpoints or ask users to run gpupdate /force.
- Confirm at least one Finance team user is reachable by phone or Teams for access validation after remediation.

## 2. Procedure

1. Open the incident ticket in ServiceNow and record the exact names of all affected users, the share path they cannot access, and the exact error message reported.
   - Expected result: A list of affected usernames, the share path (\\FS01\Finance or F: drive), and the error text are captured in your notes.

2. Ask two or three affected Finance users to try the UNC path directly in File Explorer by typing \\finance-server\Finance in the address bar and pressing Enter.
   - Expected result: You confirm whether the error is "Access is denied" or "Network path not found", which determines whether this is a permissions issue or a connectivity/server issue.

3. If the error is "Network path not found", check that the file server FS01 is online. From your admin workstation, run `ping FS01` and `Test-NetConnection -ComputerName FS01 -Port 445` in PowerShell. **[ELEVATED]**
   - Expected result: Ping and port 445 respond, confirming the server is reachable. If unreachable, escalate to the Server/Infrastructure team immediately and stop this runbook.

4. Sign in to a Domain Controller with your admin account and open Active Directory Users and Computers (dsa.msc). **[ELEVATED]**
   - Expected result: ADUC opens and the domain structure is visible.

5. In ADUC, navigate to the FIN-ShareAccess security group (search using Ctrl+F or browse to the Groups OU). **[ELEVATED]**
   - Expected result: The FIN-ShareAccess group object is found and selected.

6. Right-click FIN-ShareAccess and select Properties, then open the Members tab. **[ELEVATED]**
   - Expected result: The Members list is visible. If it is empty or missing Finance user accounts, this confirms the RCA root cause.

7. Click Add on the Members tab and add each affected Finance user account. If the full Finance team is affected, obtain the complete user list from the Finance team lead or ServiceNow CMDB and add all accounts. **[ELEVATED]**
   - Expected result: All Finance user accounts are listed in the Members tab with no missing entries.

8. Click Apply then OK to save group membership changes. **[ELEVATED]**
   - Expected result: The dialog closes and the Members tab shows all added users when reopened.

9. Open Event Viewer on the Domain Controller, click Windows Logs > Security, and filter Event ID 4729 (member removed from security group) for the incident time window. Search for FIN-ShareAccess. **[ELEVATED]**
   - Expected result: Bulk Event ID 4729 entries confirm who or what script removed the members. Record the Subject (actor) and TimeCreated values in your notes for the post-incident report.

10. On the file server FS01, open Server Manager > File and Storage Services > Shares, locate the Finance share, and review Share Permissions and Security (NTFS). **[ELEVATED]**
    - Expected result: FIN-ShareAccess group is listed with at least Change/Read at share level and Modify or Read & Execute at NTFS level. If absent, restore permissions and proceed to Step 11.

11. If share or NTFS permissions for FIN-ShareAccess are missing on FS01, add them: Share Permissions — Change and Read; NTFS Security — Modify (This folder, subfolders and files). Click Apply. **[ELEVATED]**
    - Expected result: FIN-ShareAccess appears in both Share Permissions and NTFS Security tabs with the correct access levels.

12. On an affected endpoint (or via remote session), open a Command Prompt as the affected user (not admin) and run `gpupdate /force`. **[ELEVATED for remote access]**
    - Expected result: Group Policy update completes successfully with message "Computer Policy update has completed successfully. User Policy update has completed successfully."

13. Ask the affected user to sign out and sign back in to the endpoint.
    - Expected result: User signs back in to Windows without error.

14. Ask the user to open File Explorer and check whether the F: drive is listed under This PC.
    - Expected result: F: drive is present and labelled (for example, Finance (F:)).

15. Ask the user to click the F: drive and open a known file or folder inside.
    - Expected result: Files and folders are visible and can be opened without an access denied error.

16. Confirm with the Finance team lead that all team members have regained access. Test with at least two users on different endpoints.
    - Expected result: No further access denied reports. All Finance users can open shared drive files.

17. Update the ServiceNow incident ticket with findings: root cause (FIN-ShareAccess group members removed), actions taken, affected users restored, and reference to Event ID 4729 evidence. Set ticket status to Resolved.
    - Expected result: Ticket is complete with a full audit trail for post-incident review.

18. Raise a linked Problem ticket for the AD cleanup script scope review. Flag FIN-ShareAccess as a protected group for the AD/Infrastructure team.
    - Expected result: Problem ticket is created and assigned to the AD team for script audit and recurrence prevention.

## 3. Escalation

Escalate to L3 / AD Infrastructure team if:
- FIN-ShareAccess group cannot be found in AD (group may have been deleted, not just emptied).
- File server FS01 is unreachable on port 445.
- Permissions on the Finance share have been removed and restoring them requires confirmation of the original ACL.
- The cleanup script is still running and re-removing members during remediation.
- More than one business-critical AD group is found to be empty after the same cleanup script run.
