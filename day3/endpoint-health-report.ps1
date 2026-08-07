<#
Endpoint Health Report (Read-Only)
Author: DWP Engineer Support Script
PowerShell: 5.1

This script collects endpoint health information without modifying system state.
It performs read-only queries against WMI/CIM, process tables, registry, and event logs.
#>

[CmdletBinding()]
param()

# This section enables stricter script behavior so variable and property mistakes fail early.
Set-StrictMode -Version Latest

# This section records the report generation time for the final console output.
$reportTime = Get-Date

# -----------------------------
# Section 1: System Uptime
# -----------------------------
# This section reads the operating system last boot time and calculates the current uptime.
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$lastBoot = $os.LastBootUpTime
$uptimeSpan = $reportTime - $lastBoot

# -----------------------------
# Section 2: Free Disk Space
# -----------------------------
# This section reads local fixed disk capacity and free space in GB without modifying any disks.
$diskInfo = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = 3" |
    Select-Object DeviceID,
                  VolumeName,
                  @{ Name = 'SizeGB'; Expression = { [math]::Round($_.Size / 1GB, 2) } },
                  @{ Name = 'FreeGB'; Expression = { [math]::Round($_.FreeSpace / 1GB, 2) } },
                  @{ Name = 'FreePercent'; Expression = {
                        if ($_.Size -gt 0) {
                            [math]::Round(($_.FreeSpace / $_.Size) * 100, 2)
                        } else {
                            0
                        }
                    }
                  }

# -----------------------------
# Section 3: Pending Reboot Check
# -----------------------------
# This section checks common read-only registry indicators that suggest Windows is waiting for a reboot.
# VERIFY BEFORE RUNNING: Confirm these registry paths match the pending reboot indicators approved by your support baseline.
$pendingRebootPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
)

# VERIFY BEFORE RUNNING: Confirm this registry value is part of your approved reboot checks for the Windows builds you support.
$pendingRebootValuePath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
$pendingRebootValueName = 'PendingFileRenameOperations'

$pendingRebootReasons = New-Object System.Collections.Generic.List[string]

foreach ($path in $pendingRebootPaths) {
    if (Test-Path -Path $path) {
        [void]$pendingRebootReasons.Add("Registry key exists: $path")
    }
}

$sessionManagerProps = Get-ItemProperty -Path $pendingRebootValuePath -ErrorAction SilentlyContinue
if ($null -ne $sessionManagerProps -and $sessionManagerProps.PSObject.Properties.Name -contains $pendingRebootValueName) {
    [void]$pendingRebootReasons.Add("Registry value exists: $pendingRebootValuePath -> $pendingRebootValueName")
}

$pendingReboot = $pendingRebootReasons.Count -gt 0

# -----------------------------
# Section 4: Top 5 Processes by Memory (Working Set)
# -----------------------------
# This section lists the five running processes using the most working set memory in MB.
# VERIFY BEFORE RUNNING: Some protected or system processes may not expose their executable path without elevated rights.
$topMemoryProcesses = Get-Process |
    Sort-Object -Property WorkingSet64 -Descending |
    Select-Object -First 5 ProcessName,
                  Id,
                  @{ Name = 'WorkingSetMB'; Expression = { [math]::Round($_.WorkingSet64 / 1MB, 2) } },
                  @{ Name = 'ExecutableName'; Expression = {
                        if ([string]::IsNullOrWhiteSpace($_.Path)) {
                            'N/A (Access Restricted or Not Available)'
                        } else {
                            [System.IO.Path]::GetFileName($_.Path)
                        }
                    }
                  },
                  @{ Name = 'ExecutablePath'; Expression = {
                        if ([string]::IsNullOrWhiteSpace($_.Path)) {
                            'N/A (Access Restricted or Not Available)'
                        } else {
                            $_.Path
                        }
                    }
                  }

# -----------------------------
# Section 5: Top 5 Processes by CPU
# -----------------------------
# This section lists the five running processes with the highest cumulative CPU time in seconds.
# VERIFY BEFORE RUNNING: CPU here is cumulative process CPU time since process start, not instantaneous CPU percentage.
$topCpuProcesses = Get-Process |
    Where-Object { $null -ne $_.CPU } |
    Sort-Object -Property CPU -Descending |
    Select-Object -First 5 ProcessName,
                  Id,
                  @{ Name = 'CPUSeconds'; Expression = { [math]::Round($_.CPU, 2) } },
                  @{ Name = 'ExecutableName'; Expression = {
                        if ([string]::IsNullOrWhiteSpace($_.Path)) {
                            'N/A (Access Restricted or Not Available)'
                        } else {
                            [System.IO.Path]::GetFileName($_.Path)
                        }
                    }
                  },
                  @{ Name = 'ExecutablePath'; Expression = {
                        if ([string]::IsNullOrWhiteSpace($_.Path)) {
                            'N/A (Access Restricted or Not Available)'
                        } else {
                            $_.Path
                        }
                    }
                  }

# -----------------------------
# Section 6: Last 5 System Log Errors
# -----------------------------
# This section reads the five most recent Error entries from the System event log.
# VERIFY BEFORE RUNNING: Reading the System log may require elevated rights in some environments.
$lastSystemErrors = Get-EventLog -LogName System -EntryType Error -Newest 5 -ErrorAction SilentlyContinue |
    Select-Object TimeGenerated,
                  Source,
                  EventID,
                  Message

# -----------------------------
# Output Report
# -----------------------------
# This section prints a structured, human-readable report to the console only.
Write-Host ''
Write-Host '========== Endpoint Health Report ==========' -ForegroundColor Cyan
Write-Host ("Generated: {0}" -f $reportTime.ToString('yyyy-MM-dd HH:mm:ss'))
Write-Host ''

Write-Host '[1] System Uptime' -ForegroundColor Yellow
Write-Host ("Last Boot Time : {0}" -f $lastBoot)
Write-Host ("Uptime         : {0} days {1} hours {2} minutes" -f $uptimeSpan.Days, $uptimeSpan.Hours, $uptimeSpan.Minutes)
Write-Host ''

Write-Host '[2] Free Disk Space' -ForegroundColor Yellow
$diskInfo | Format-Table -AutoSize | Out-Host
Write-Host ''

Write-Host '[3] Pending Reboot' -ForegroundColor Yellow
Write-Host ("Pending Reboot : {0}" -f $pendingReboot)
if ($pendingRebootReasons.Count -gt 0) {
    Write-Host 'Reasons:'
    $pendingRebootReasons | ForEach-Object { Write-Host (" - {0}" -f $_) }
} else {
    Write-Host 'Reasons: None detected from checked indicators.'
}
Write-Host ''

Write-Host '[4] Top 5 Processes by Memory (Working Set)' -ForegroundColor Yellow
$topMemoryProcesses | Format-List ProcessName, Id, WorkingSetMB, ExecutableName, ExecutablePath | Out-Host
Write-Host ''

Write-Host '[5] Top 5 Processes by CPU' -ForegroundColor Yellow
$topCpuProcesses | Format-List ProcessName, Id, CPUSeconds, ExecutableName, ExecutablePath | Out-Host
Write-Host ''

Write-Host '[6] Last 5 System Log Errors' -ForegroundColor Yellow
if ($lastSystemErrors) {
    $lastSystemErrors | Format-List | Out-Host
} else {
    Write-Host 'No System Error events found or access denied.'
}
Write-Host ''

Write-Host '========== End of Report ==========' -ForegroundColor Cyan
