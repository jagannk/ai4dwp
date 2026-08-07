<#
Disk Health Reporter (Read-Only)
Author: DWP Engineer Support Script
PowerShell: 5.1

This script reports disk health and optimization status without changing system state.
It never starts defragmentation or any optimization action.
#>

[CmdletBinding()]
param()

# This section enables strict mode so undeclared variables and similar issues fail early.
Set-StrictMode -Version Latest

# This section captures report generation time and prints a read-only safety banner.
$reportTime = Get-Date
Write-Host ''
Write-Host '========== Disk Health Report (Read-Only) ==========' -ForegroundColor Cyan
Write-Host ("Generated: {0}" -f $reportTime.ToString('yyyy-MM-dd HH:mm:ss'))
Write-Host 'Safety   : This script does not run defrag or optimization commands.' -ForegroundColor Green
Write-Host ''

# -----------------------------
# Section 1: Logical Disk Capacity and Free Space
# -----------------------------
# This section reads local fixed disk capacity and available free space.
try {
    $logicalDisks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = 3" |
        Select-Object DeviceID,
                      VolumeName,
                      FileSystem,
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

    Write-Host '[1] Logical Disk Space' -ForegroundColor Yellow
    if ($logicalDisks) {
        $logicalDisks | Format-Table -AutoSize | Out-Host
    } else {
        Write-Host 'No fixed disks were found.'
    }
    Write-Host ''
} catch {
    Write-Host '[1] Logical Disk Space' -ForegroundColor Yellow
    Write-Warning ("Failed to read logical disk data. {0}" -f $_.Exception.Message)
    Write-Host ''
}

# -----------------------------
# Section 2: Physical Disk Health
# -----------------------------
# This section reads physical disk health status using Storage cmdlets, with WMI fallback for compatibility.
Write-Host '[2] Physical Disk Health' -ForegroundColor Yellow
try {
    if (Get-Command -Name Get-PhysicalDisk -ErrorAction SilentlyContinue) {
        $physicalDisks = Get-PhysicalDisk |
            Select-Object FriendlyName,
                          MediaType,
                          HealthStatus,
                          OperationalStatus,
                          Size,
                          @{ Name = 'SizeGB'; Expression = { [math]::Round($_.Size / 1GB, 2) } }

        if ($physicalDisks) {
            $physicalDisks | Select-Object FriendlyName, MediaType, HealthStatus, OperationalStatus, SizeGB | Format-Table -AutoSize | Out-Host
        } else {
            Write-Host 'No physical disk entries returned by Get-PhysicalDisk.'
        }
    } else {
        $wmiDisks = Get-CimInstance -ClassName Win32_DiskDrive |
            Select-Object Model,
                          InterfaceType,
                          Status,
                          @{ Name = 'SizeGB'; Expression = { [math]::Round($_.Size / 1GB, 2) } }

        if ($wmiDisks) {
            $wmiDisks | Format-Table -AutoSize | Out-Host
        } else {
            Write-Host 'No disk entries returned by Win32_DiskDrive.'
        }
    }
} catch {
    Write-Warning ("Failed to read physical disk health data. {0}" -f $_.Exception.Message)
}
Write-Host ''

# -----------------------------
# Section 3: Disk Error Indicators from System Event Log
# -----------------------------
# This section reads recent storage-related System log errors and warnings for quick triage context.
Write-Host '[3] Recent Storage-Related System Events' -ForegroundColor Yellow
try {
    $storageSources = @('disk', 'Ntfs', 'volmgr', 'storahci', 'iaStorA', 'stornvme')
    $recentStorageEvents = Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 2, 3 } -ErrorAction Stop |
        Where-Object { $storageSources -contains $_.ProviderName } |
        Select-Object -First 10 TimeCreated, ProviderName, Id, LevelDisplayName, Message

    if ($recentStorageEvents) {
        $recentStorageEvents | Format-List | Out-Host
    } else {
        Write-Host 'No recent storage-related warnings/errors found in System log.'
    }
} catch {
    Write-Warning ("Failed to read storage-related system events. {0}" -f $_.Exception.Message)
}
Write-Host ''

# -----------------------------
# Section 4: Optimization Status (Read-Only)
# -----------------------------
# This section reports optimization scheduling and recent optimization history without running optimization.
Write-Host '[4] Optimization Status (No Defrag Executed)' -ForegroundColor Yellow

try {
    $scheduledDefragTask = Get-ScheduledTask -TaskPath '\\Microsoft\\Windows\\Defrag\\' -TaskName 'ScheduledDefrag' -ErrorAction Stop
    $scheduledDefragTaskInfo = Get-ScheduledTaskInfo -TaskPath '\\Microsoft\\Windows\\Defrag\\' -TaskName 'ScheduledDefrag' -ErrorAction Stop

    $taskState = $scheduledDefragTask.State
    $lastRunTime = $scheduledDefragTaskInfo.LastRunTime
    $nextRunTime = $scheduledDefragTaskInfo.NextRunTime
    $lastTaskResult = $scheduledDefragTaskInfo.LastTaskResult

    Write-Host ("Scheduled Task State : {0}" -f $taskState)
    Write-Host ("Last Run Time        : {0}" -f $lastRunTime)
    Write-Host ("Next Run Time        : {0}" -f $nextRunTime)
    Write-Host ("Last Task Result     : {0}" -f $lastTaskResult)
} catch {
    Write-Warning ("Failed to read ScheduledDefrag task status. {0}" -f $_.Exception.Message)
}

try {
    $defragLogName = 'Microsoft-Windows-Defrag/Operational'
    $defragLogExists = $false

    try {
        $null = Get-WinEvent -ListLog $defragLogName -ErrorAction Stop
        $defragLogExists = $true
    } catch {
        $defragLogExists = $false
    }

    if ($defragLogExists) {
        $defragEvents = Get-WinEvent -FilterHashtable @{ LogName = $defragLogName } -MaxEvents 10 -ErrorAction Stop |
            Select-Object TimeCreated, Id, LevelDisplayName, Message

        if ($defragEvents) {
            Write-Host ''
            Write-Host 'Recent Defrag Operational Events:'
            $defragEvents | Format-List | Out-Host
        } else {
            Write-Host 'No recent events found in Defrag operational log.'
        }
    } else {
        Write-Host 'Defrag operational log is not available on this endpoint.'
    }
} catch {
    Write-Warning ("Failed to read defrag operational events. {0}" -f $_.Exception.Message)
}

Write-Host ''
Write-Host '========== End of Disk Health Report ==========' -ForegroundColor Cyan
