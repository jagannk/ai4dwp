# Temp Cleanup Script

This folder contains a PowerShell 5.1 script that safely cleans up temp files on a Windows endpoint by moving them into a quarantine folder instead of permanently deleting them immediately.

## Files

- `endpoint-health-report.ps1`: Temp cleanup and rollback script.
- `logs`: Created automatically to store timestamped execution logs.
- `cleanup-quarantine`: Created automatically to store quarantined files and rollback manifests.

## What The Script Does

- Scans one or more target folders recursively for files older than a specified number of days.
- Supports a dry run mode that prints the files that would be removed.
- Skips locked files and logs the error without stopping the run.
- Uses per-file `try/catch` handling so one file failure does not stop the script.
- Logs every action to a timestamped log file.
- Produces a rollback manifest for successful cleanup runs.
- Restores files from quarantine when rollback mode is used.
- Remains idempotent because files already moved are no longer found on later cleanup runs, and rollback skips files that are already back in place.

## Default Target Paths

If you do not supply `-Path`, the script scans:

- `%TEMP%`
- `%WINDIR%\Temp`

## Parameters

- `-Path <string[]>`
  One or more folders to scan.

- `-OlderThanDays <int>`
  Only targets files with `LastWriteTime` older than the specified number of days.
  Default: `0`

- `-DryRun`
  Shows which files would be removed from the source location without moving any files.

- `-QuarantineRoot <string>`
  Sets the folder used to store quarantined files and rollback manifests.
  Default: `day3\cleanup-quarantine`

- `-LogDirectory <string>`
  Sets the folder used for timestamped log files.
  Default: `day3\logs`

- `-Rollback`
  Switches the script into rollback mode.

- `-ManifestPath <string>`
  Optional path to a specific rollback manifest CSV.
  If omitted during rollback, the script uses the latest manifest found under `cleanup-quarantine\manifests`.

## Examples

Preview cleanup only:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\day3\endpoint-health-report.ps1 -DryRun
```

Clean temp files older than 7 days from the default locations:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\day3\endpoint-health-report.ps1 -OlderThanDays 7
```

Clean a specific folder only:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\day3\endpoint-health-report.ps1 -Path 'C:\Temp' -OlderThanDays 3
```

Rollback using the latest manifest automatically:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\day3\endpoint-health-report.ps1 -Rollback
```

Rollback using a specific manifest:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\day3\endpoint-health-report.ps1 -Rollback -ManifestPath '.\day3\cleanup-quarantine\manifests\cleanup-manifest-20260805-101500.csv'
```

## Operational Notes

- Cleanup is reversible because files are moved to quarantine instead of being hard deleted.
- Review the log file and manifest after each non-dry-run execution.
- If a file is open or locked by another process, the script logs the issue and continues.
- Run the script from an elevated PowerShell session when targeting locations that require administrative access.