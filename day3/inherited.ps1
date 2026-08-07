<#
Purpose:
- Gather and print basic endpoint health data (computer info, free disk space, top memory processes, recent system errors, and stale user profile count).

Author:
- DWP Engineer Support Script

How to run:
- Open PowerShell 5.1.
- Run: powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\day3\inherited.ps1

Notes:
- This script is read-only and prints results to the console.
#>

# Get computer system information (for example, computer name and total physical memory).
$computerSystem = Get-CimInstance Win32_ComputerSystem

# Get free space on drive C: in bytes.
$freeSpaceBytesOnC = Get-PSDrive C | Select-Object -ExpandProperty Free

# Get the top 5 running processes sorted by working set memory (highest first).
$topProcessesByWorkingSet = Get-Process | Sort-Object WS -Descending | Select-Object -First 5

# Get the last 10 System log events and keep only Error-level events.
$recentSystemErrors = Get-WinEvent -LogName System -MaxEvents 10 | Where-Object { $_.Level -eq 2 }

# Get user profiles and keep only non-special profiles that have not been used in the last 90 days.
$staleUserProfiles = Get-CimInstance Win32_UserProfile | Where-Object {
     -not $_.Special -and $_.LastUseTime -lt (Get-Date).AddDays(-90)
}

# Print computer name and total physical memory.
Write-Host $computerSystem.Name $computerSystem.TotalPhysicalMemory

# Convert free bytes on C: to GB (rounded to 2 decimals) and print it.
Write-Host ([math]::Round($freeSpaceBytesOnC / 1GB, 2)) 'GB free'

# Print process name and working set memory for each of the top 5 processes.
$topProcessesByWorkingSet | ForEach-Object { Write-Host $_.Name $_.WS }

# Print timestamp and message for each recent System error event.
$recentSystemErrors | ForEach-Object { Write-Host $_.TimeCreated $_.Message }

# Print stale profile count only when at least one stale profile exists.
if ($staleUserProfiles.Count -gt 0) { Write-Host 'Stale profiles:' $staleUserProfiles.Count }
