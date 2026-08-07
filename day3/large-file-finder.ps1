<#
Large File Finder (Read-Only)
Author: DWP Engineer Support Script
PowerShell: 5.1

This script scans for large files and reports them without changing system state.
#>

[CmdletBinding()]
param(
    # This parameter defines one or more root paths to scan recursively.
    [string[]]$Path = @((Join-Path -Path $env:SystemDrive -ChildPath '\')),

    # This parameter defines the minimum file size (in MB) to report.
    [ValidateRange(1, 1024000)]
    [int]$ThresholdMB = 100,

    # This parameter limits the result set size after sorting by largest files first.
    [ValidateRange(1, 1000000)]
    [int]$Top = 200
)

# This section enables strict behavior to catch common scripting mistakes early.
Set-StrictMode -Version Latest

# This section computes byte thresholds and initializes tracking collections.
$thresholdBytes = [int64]$ThresholdMB * 1MB
$results = New-Object System.Collections.Generic.List[object]
$scanErrors = New-Object System.Collections.Generic.List[object]
$scanTime = Get-Date

Write-Host ''
Write-Host '========== Large File Finder (Read-Only) ==========' -ForegroundColor Cyan
Write-Host ("Started      : {0}" -f $scanTime.ToString('yyyy-MM-dd HH:mm:ss'))
Write-Host ("ThresholdMB  : {0}" -f $ThresholdMB)
Write-Host ("ThresholdB   : {0}" -f $thresholdBytes)
Write-Host ("Top          : {0}" -f $Top)
Write-Host ("Paths        : {0}" -f ($Path -join '; '))
Write-Host ''

# This section scans each path recursively and records files that meet the threshold.
foreach ($root in $Path) {
    try {
        if ([string]::IsNullOrWhiteSpace($root)) {
            continue
        }

        if (-not (Test-Path -LiteralPath $root)) {
            Write-Warning ("Skipping missing path: {0}" -f $root)
            continue
        }

        Write-Host ("Scanning: {0}" -f $root) -ForegroundColor Yellow

        Get-ChildItem -LiteralPath $root -File -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Length -ge $thresholdBytes } |
            ForEach-Object {
                $results.Add([pscustomobject]@{
                    FullName = $_.FullName
                    SizeBytes = [int64]$_.Length
                    SizeMB = [math]::Round($_.Length / 1MB, 2)
                    SizeGB = [math]::Round($_.Length / 1GB, 2)
                    LastWriteTime = $_.LastWriteTime
                    Directory = $_.DirectoryName
                    FileName = $_.Name
                }) | Out-Null
            }
    } catch {
        $scanErrors.Add([pscustomobject]@{
            Path = $root
            Error = $_.Exception.Message
        }) | Out-Null
        Write-Warning ("Error scanning path {0}. {1}" -f $root, $_.Exception.Message)
    }
}

# This section sorts and prints the largest matching files in a readable table.
$sorted = $results | Sort-Object -Property SizeBytes -Descending
$topResults = $sorted | Select-Object -First $Top

Write-Host ''
Write-Host '[Large Files]' -ForegroundColor Yellow
if (@($topResults).Count -eq 0) {
    Write-Host 'No files matched the threshold.' -ForegroundColor Yellow
} else {
    $topResults |
        Select-Object SizeGB, SizeMB, SizeBytes, LastWriteTime, FullName |
        Format-Table -AutoSize |
        Out-Host
}

# This section prints a concise summary for quick operational review.
$endTime = Get-Date
$duration = $endTime - $scanTime
Write-Host ''
Write-Host '[Summary]' -ForegroundColor Yellow
Write-Host ("MatchedFiles : {0}" -f $results.Count)
Write-Host ("Returned     : {0}" -f @($topResults).Count)
Write-Host ("ErrorCount   : {0}" -f $scanErrors.Count)
Write-Host ("DurationSec  : {0}" -f [math]::Round($duration.TotalSeconds, 2))

if ($scanErrors.Count -gt 0) {
    Write-Host ''
    Write-Host '[Scan Errors]' -ForegroundColor Yellow
    $scanErrors | Format-Table -AutoSize | Out-Host
}

Write-Host ''
Write-Host '==============================================' -ForegroundColor Cyan
