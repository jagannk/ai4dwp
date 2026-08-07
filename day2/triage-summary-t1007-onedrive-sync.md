Summary (one line)
OneDrive stuck in 'processing changes' state since migration; user reports missing files locally.

Impact (who/how many/ business urgency)
Who: Single user (to-verify).
How many: One user reported (to-verify).
Business urgency: High (data access blocked; missing local files may indicate sync failure or data loss concern).

known facts
- OneDrive migration occurred (timing and scope to-verify).
- OneDrive status shows 'processing changes' since migration.
- Condition persists (not transient).
- User reports missing files in local OneDrive folder.

Missing information to gather
- How long has OneDrive been in 'processing changes' state (to-verify).
- Which files are reported as missing locally and are they visible in OneDrive web portal (to-verify).
- OneDrive folder location and size (to-verify).
- Available storage quota and current consumption (to-verify).
- Whether any files were recently modified or deleted around migration time (to-verify).
- OneDrive client version and recent updates (to-verify).
- Windows event logs and OneDrive logs showing sync errors (to-verify).
- Whether user has permissions to access migrated files (to-verify).
- Is this affecting all files or specific subset (to-verify).
- Whether user can manually download files from OneDrive web (to-verify).

likely catagory
OneDrive sync failure and data migration incident (to-verify).

Suggest first diagnostic step
Verify data accessibility and diagnose sync state: confirm files are present in OneDrive web portal (browser access); check available OneDrive storage quota and sync status in client; enable OneDrive logs and capture sync activity; pause and resume OneDrive sync; restart OneDrive client and check for error codes; verify user permissions on migrated content; if files remain inaccessible locally, escalate to OneDrive/migration team with file names and sync logs to determine whether data loss or permission issue (to-verify).
