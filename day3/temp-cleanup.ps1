<#
Temp File Cleanup Utility
Author: DWP Engineer Support Script
PowerShell: 5.1

This script safely cleans up temp files by moving them to a quarantine folder.
Moving files out of the source location provides a reversible cleanup path through rollback.
#>

[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Cleanup')]
param(
    # This parameter defines one or more root folders to scan for temp files during cleanup mode.
    [Parameter(ParameterSetName = 'Cleanup')]
    [string[]]$Path = @(
        $env:TEMP,
        (Join-Path -Path $env:WINDIR -ChildPath 'Temp')
    ),

    # This parameter controls the file age filter in days. Only files older than this value are targeted.
    [Parameter(ParameterSetName = 'Cleanup')]
    [ValidateRange(0, 3650)]
    [int]$OlderThanDays = 0,

    # This switch performs a non-destructive preview and prints the files that would be removed.
    [Parameter(ParameterSetName = 'Cleanup')]
    [switch]$DryRun,

    # This parameter sets the base folder used to hold quarantined files and rollback manifests.
    [Parameter(ParameterSetName = 'Cleanup')]
    [Parameter(ParameterSetName = 'Rollback')]
    [string]$QuarantineRoot,

    # This parameter sets the folder used to store timestamped execution logs.
    [Parameter(ParameterSetName = 'Cleanup')]
    [Parameter(ParameterSetName = 'Rollback')]
    [string]$LogDirectory,

    # This switch activates rollback mode and restores files from a manifest back to their original path.
    [Parameter(ParameterSetName = 'Rollback', Mandatory = $true)]
    [switch]$Rollback,

    # This parameter points to a manifest CSV created by a previous cleanup run.
    # If omitted in rollback mode, the latest manifest in the quarantine root is used.
    [Parameter(ParameterSetName = 'Rollback')]
    [string]$ManifestPath
)

# This section enables stricter script behavior so unexpected variable or property mistakes are surfaced early.
Set-StrictMode -Version Latest

# This section resolves the script root and applies default working folders after parameters have been parsed.
$scriptRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
    $scriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
}

if ([string]::IsNullOrWhiteSpace($QuarantineRoot)) {
    $QuarantineRoot = Join-Path -Path $scriptRoot -ChildPath 'cleanup-quarantine'
}

if ([string]::IsNullOrWhiteSpace($LogDirectory)) {
    $LogDirectory = Join-Path -Path $scriptRoot -ChildPath 'logs'
}

# This section creates common timestamp values that are reused by the log, quarantine, and summary output.
$runTimestamp = Get-Date
$runStamp = $runTimestamp.ToString('yyyyMMdd-HHmmss')

# This section ensures the log folder exists before the first write is attempted.
if (-not (Test-Path -LiteralPath $LogDirectory)) {
    New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
}

# This section creates a unique, timestamped log file for the current execution.
$logFile = Join-Path -Path $LogDirectory -ChildPath ("temp-cleanup-{0}.log" -f $runStamp)

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    # This section writes a timestamped message to both the console and the run-specific log file.
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $entry = "[{0}] [{1}] {2}" -f $timestamp, $Level, $Message
    Add-Content -Path $logFile -Value $entry
    Write-Host $entry
}

function Initialize-Directory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    # This section creates a directory only when needed so repeated executions stay safe and repeatable.
    if (-not (Test-Path -LiteralPath $TargetPath)) {
        New-Item -Path $TargetPath -ItemType Directory -Force | Out-Null
    }
}

function Get-LatestManifestPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestDirectory
    )

    # This section finds the newest rollback manifest so rollback mode can work without extra input.
    if (-not (Test-Path -LiteralPath $ManifestDirectory)) {
        return $null
    }

    $latestManifest = Get-ChildItem -Path $ManifestDirectory -Filter '*.csv' -File -ErrorAction SilentlyContinue |
        Sort-Object -Property LastWriteTime -Descending |
        Select-Object -First 1

    if ($null -eq $latestManifest) {
        return $null
    }

    return $latestManifest.FullName
}

function Test-FileLocked {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    # This section checks whether a file can be opened exclusively so locked files can be skipped safely.
    try {
        $stream = [System.IO.File]::Open($File.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $stream.Close()
        return $false
    } catch [System.UnauthorizedAccessException] {
        throw
    } catch [System.IO.IOException] {
        return $true
    }
}

function Get-CleanupCandidates {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$TargetPaths,

        [Parameter(Mandatory = $true)]
        [datetime]$CutoffDate,

        [Parameter(Mandatory = $true)]
        [string[]]$ExcludedRoots
    )

    # This section discovers eligible files from each requested path while excluding script-owned folders.
    $candidates = New-Object System.Collections.Generic.List[System.IO.FileInfo]

    foreach ($targetPath in $TargetPaths) {
        if ([string]::IsNullOrWhiteSpace($targetPath)) {
            continue
        }

        if (-not (Test-Path -LiteralPath $targetPath)) {
            Write-Log -Level 'WARN' -Message ("Skipping missing path: {0}" -f $targetPath)
            continue
        }

        Write-Log -Message ("Scanning path: {0}" -f $targetPath)

        Get-ChildItem -Path $targetPath -File -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object {
                $currentFile = $_
                $isExcluded = $false

                foreach ($excludedRoot in $ExcludedRoots) {
                    if (-not [string]::IsNullOrWhiteSpace($excludedRoot)) {
                        $normalizedRoot = $excludedRoot.TrimEnd('\\')
                        if ($currentFile.FullName.StartsWith($normalizedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
                            $isExcluded = $true
                            break
                        }
                    }
                }

                return $currentFile.LastWriteTime -lt $CutoffDate -and
                    -not ($currentFile.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -and
                    -not $isExcluded
            } |
            ForEach-Object {
                $candidates.Add($_)
            }
    }

    return $candidates
}

function Invoke-Cleanup {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$TargetPaths,

        [Parameter(Mandatory = $true)]
        [int]$AgeInDays,

        [Parameter(Mandatory = $true)]
        [bool]$IsDryRun,

        [Parameter(Mandatory = $true)]
        [string]$QuarantineBase
    )

    # This section prepares the cutoff date, quarantine structure, and summary counters for cleanup mode.
    $cutoffDate = (Get-Date).AddDays(-$AgeInDays)
    $manifestsDirectory = Join-Path -Path $QuarantineBase -ChildPath 'manifests'
    $runQuarantineDirectory = Join-Path -Path $QuarantineBase -ChildPath $runStamp

    Initialize-Directory -TargetPath $QuarantineBase
    Initialize-Directory -TargetPath $manifestsDirectory

    if (-not $IsDryRun) {
        Initialize-Directory -TargetPath $runQuarantineDirectory
    }

    $excludedRoots = @($QuarantineBase, $LogDirectory)
    $manifestRecords = New-Object System.Collections.Generic.List[object]
    $summary = [ordered]@{
        Mode = if ($IsDryRun) { 'DryRun' } else { 'Cleanup' }
        CutoffDate = $cutoffDate
        TargetPaths = ($TargetPaths -join '; ')
        Candidates = 0
        MovedToQuarantine = 0
        LockedSkipped = 0
        Errors = 0
        DryRunListed = 0
    }

    Write-Log -Message ("Cleanup mode started. OlderThanDays={0}; CutoffDate={1}" -f $AgeInDays, $cutoffDate)

    # This section gathers all matching candidate files before any action is taken.
    $candidates = Get-CleanupCandidates -TargetPaths $TargetPaths -CutoffDate $cutoffDate -ExcludedRoots $excludedRoots
    $summary.Candidates = $candidates.Count
    Write-Log -Message ("Discovered {0} candidate file(s)." -f $summary.Candidates)

    # This section prints the pending delete list in dry run mode without changing any files.
    if ($IsDryRun) {
        if ($candidates.Count -gt 0) {
            Write-Host ''
            Write-Host 'Files that would be removed from the target location:' -ForegroundColor Yellow
            $candidates |
                Sort-Object -Property FullName |
                Select-Object FullName, Length, LastWriteTime |
                Format-Table -AutoSize |
                Out-Host
        } else {
            Write-Host 'No files matched the supplied criteria.' -ForegroundColor Yellow
        }

        foreach ($candidate in $candidates) {
            Write-Log -Message ("Dry run candidate: {0}" -f $candidate.FullName)
        }

        $summary.DryRunListed = $candidates.Count
        return [pscustomobject]@{
            Summary = $summary
            LogFile = $logFile
            ManifestPath = $null
        }
    }

    $fileIndex = 0

    # This section processes each file independently so one failure does not stop the rest of the cleanup.
    foreach ($candidate in $candidates) {
        $fileIndex++

        try {
            if (Test-FileLocked -File $candidate) {
                $summary.LockedSkipped++
                Write-Log -Level 'WARN' -Message ("Skipped locked file: {0}" -f $candidate.FullName)
                continue
            }

            $quarantineName = "{0:D6}_{1}" -f $fileIndex, $candidate.Name
            $quarantinePath = Join-Path -Path $runQuarantineDirectory -ChildPath $quarantineName

            if ($PSCmdlet.ShouldProcess($candidate.FullName, 'Move file to quarantine')) {
                Move-Item -LiteralPath $candidate.FullName -Destination $quarantinePath -Force -ErrorAction Stop
            }

            $manifestRecords.Add([pscustomobject]@{
                OriginalPath = $candidate.FullName
                QuarantinePath = $quarantinePath
                Length = $candidate.Length
                LastWriteTime = $candidate.LastWriteTime.ToString('o')
                CleanupTimestamp = $runTimestamp.ToString('o')
                Status = 'MovedToQuarantine'
            })

            $summary.MovedToQuarantine++
            Write-Log -Message ("Moved to quarantine: {0} -> {1}" -f $candidate.FullName, $quarantinePath)
        } catch {
            $summary.Errors++
            Write-Log -Level 'ERROR' -Message ("Failed to process file: {0}. {1}" -f $candidate.FullName, $_.Exception.Message)
        }
    }

    # This section writes a rollback manifest only for files that were moved successfully.
    $manifestPath = $null
    if ($manifestRecords.Count -gt 0) {
        $manifestPath = Join-Path -Path $manifestsDirectory -ChildPath ("cleanup-manifest-{0}.csv" -f $runStamp)
        $manifestRecords | Export-Csv -Path $manifestPath -NoTypeInformation
        Write-Log -Message ("Rollback manifest created: {0}" -f $manifestPath)
    } else {
        Write-Log -Level 'WARN' -Message 'No files were moved, so no rollback manifest was created.'
    }

    return [pscustomobject]@{
        Summary = $summary
        LogFile = $logFile
        ManifestPath = $manifestPath
    }
}

function Invoke-Rollback {
    param(
        [string]$RollbackManifestPath,

        [Parameter(Mandatory = $true)]
        [string]$QuarantineBase
    )

    # This section resolves the manifest to use and prepares summary counters for rollback mode.
    $manifestsDirectory = Join-Path -Path $QuarantineBase -ChildPath 'manifests'

    if ([string]::IsNullOrWhiteSpace($RollbackManifestPath)) {
        $RollbackManifestPath = Get-LatestManifestPath -ManifestDirectory $manifestsDirectory
    }

    if ([string]::IsNullOrWhiteSpace($RollbackManifestPath) -or -not (Test-Path -LiteralPath $RollbackManifestPath)) {
        throw 'Rollback could not continue because no valid manifest file was found.'
    }

    $summary = [ordered]@{
        Mode = 'Rollback'
        ManifestPath = $RollbackManifestPath
        ManifestEntries = 0
        Restored = 0
        AlreadyPresentSkipped = 0
        MissingQuarantineSkipped = 0
        Errors = 0
    }

    Write-Log -Message ("Rollback mode started. Manifest={0}" -f $RollbackManifestPath)

    # This section imports the manifest so each previously moved file can be restored individually.
    $manifestEntries = Import-Csv -Path $RollbackManifestPath
    $summary.ManifestEntries = @($manifestEntries).Count

    foreach ($entry in $manifestEntries) {
        try {
            if (Test-Path -LiteralPath $entry.OriginalPath) {
                $summary.AlreadyPresentSkipped++
                Write-Log -Level 'WARN' -Message ("Rollback skipped because the original file already exists: {0}" -f $entry.OriginalPath)
                continue
            }

            if (-not (Test-Path -LiteralPath $entry.QuarantinePath)) {
                $summary.MissingQuarantineSkipped++
                Write-Log -Level 'WARN' -Message ("Rollback skipped because the quarantined file is missing: {0}" -f $entry.QuarantinePath)
                continue
            }

            $parentDirectory = Split-Path -Path $entry.OriginalPath -Parent
            Initialize-Directory -TargetPath $parentDirectory

            Move-Item -LiteralPath $entry.QuarantinePath -Destination $entry.OriginalPath -Force -ErrorAction Stop
            $summary.Restored++
            Write-Log -Message ("Restored file: {0} -> {1}" -f $entry.QuarantinePath, $entry.OriginalPath)
        } catch {
            $summary.Errors++
            Write-Log -Level 'ERROR' -Message ("Failed to restore file: {0}. {1}" -f $entry.OriginalPath, $_.Exception.Message)
        }
    }

    return [pscustomobject]@{
        Summary = $summary
        LogFile = $logFile
        ManifestPath = $RollbackManifestPath
    }
}

try {
    # This section routes execution into cleanup mode or rollback mode based on the selected parameter set.
    if ($PSCmdlet.ParameterSetName -eq 'Rollback') {
        $result = Invoke-Rollback -RollbackManifestPath $ManifestPath -QuarantineBase $QuarantineRoot
    } else {
        $result = Invoke-Cleanup -TargetPaths $Path -AgeInDays $OlderThanDays -IsDryRun $DryRun.IsPresent -QuarantineBase $QuarantineRoot
    }

    # This section prints a consistent end-of-run summary so engineers can confirm what happened quickly.
    Write-Host ''
    Write-Host '========== Temp Cleanup Summary ==========' -ForegroundColor Cyan
    foreach ($key in $result.Summary.Keys) {
        Write-Host ("{0}: {1}" -f $key, $result.Summary[$key])
    }
    Write-Host ("LogFile: {0}" -f $result.LogFile)
    if ($result.ManifestPath) {
        Write-Host ("ManifestPath: {0}" -f $result.ManifestPath)
    }
    Write-Host '==========================================' -ForegroundColor Cyan
} catch {
    # This section handles unrecoverable errors that happen outside per-file processing and records them to the log.
    Write-Log -Level 'ERROR' -Message $_.Exception.Message
    throw
}
