# Event Log Archive and Cleanup Script

This folder contains a PowerShell 5.1 script for safely archiving and cleaning Windows Event Logs on an endpoint.

Script file:
- `eventlog-archive-cleanup.ps1`

## Safety Model

- The script archives each log before attempting cleanup.
- Cleanup clears an entire log only when all records in that log are older than the configured cutoff.
- If newer records exist, cleanup is skipped for that log.
- The script is idempotent for daily operations: if today's archive file already exists for a log, that log is skipped.

## Parameters

- `-LogName <string[]>`
  Event logs to process. Default: `Application`, `System`, `Security`.

- `-OlderThanDays <int>`
  Age threshold for cleanup decisions. Default: `3`.

- `-DryRun`
  No changes are made. The script prints and logs the count of records it would delete.

- `-ArchiveRoot <string>`
  Root directory for archive files and manifests.
  Default: `day3\eventlog-archive`.

- `-LogDirectory <string>`
  Directory for timestamped execution logs.
  Default: `day3\logs`.

- `-Rollback`
  Switches the script into rollback mode.

- `-ManifestPath <string>`
  Optional manifest path for rollback. If omitted, the latest manifest is used.

## What Dry Run Reports

For each log, dry run prints:
- total record count
- old record count (older than cutoff)
- would-delete count

`WouldDelete` is non-zero only when a full clear is safe for that log.

## Rollback Behavior

Rollback mode restores archived EVTX data copies into:
- `eventlog-archive\rollback-restored`

Important:
- Native Windows tooling does not provide a safe, selective import path to re-inject archived events into active channels while preserving original record semantics.
- Rollback in this script therefore recovers archived data files for review and evidence retention.

## Examples

Dry run with defaults:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\day3\eventlog-archive-cleanup.ps1 -DryRun
```

Dry run for logs older than 7 days:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\day3\eventlog-archive-cleanup.ps1 -OlderThanDays 7 -DryRun
```

Run archive + cleanup with defaults:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\day3\eventlog-archive-cleanup.ps1
```

Run for specific logs:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\day3\eventlog-archive-cleanup.ps1 -LogName Application,System
```

Rollback using latest manifest:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\day3\eventlog-archive-cleanup.ps1 -Rollback
```

Rollback using specific manifest:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\day3\eventlog-archive-cleanup.ps1 -Rollback -ManifestPath .\day3\eventlog-archive\manifests\eventlog-manifest-20260805-120000.json
```

## Operational Notes

- Run from an elevated PowerShell session if your environment restricts access to specific logs.
- Security log access is frequently restricted; errors are logged and the script continues.
- Every operation uses try/catch and all actions are logged to a timestamped log file.
