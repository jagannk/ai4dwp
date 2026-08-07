<#
Startup Program Auditor
Author: DWP Engineer Support Script
PowerShell: 5.1

This script audits startup programs and can disable a selected startup entry safely.
#>

[CmdletBinding(DefaultParameterSetName = 'List')]
param(
    # This switch performs a read-only listing of startup programs.
    [Parameter(ParameterSetName = 'List')]
    [switch]$DryRun,

    # This switch enables disable mode for a specific startup program name.
    [Parameter(ParameterSetName = 'Disable', Mandatory = $true)]
    [switch]$Disable,

    # This parameter provides the startup program name to disable.
    [Parameter(ParameterSetName = 'Disable', Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ProgramName
)

# This section enables strict script behavior so common coding mistakes fail early.
Set-StrictMode -Version Latest

function Get-StartupItems {
    # This section collects startup items from registry Run keys and Startup folders.
    $items = New-Object System.Collections.Generic.List[object]

    $runSources = @(
        @{ Scope = 'CurrentUser'; Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' },
        @{ Scope = 'AllUsers'; Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' }
    )

    foreach ($src in $runSources) {
        try {
            if (Test-Path -LiteralPath $src.Path) {
                $props = Get-ItemProperty -LiteralPath $src.Path -ErrorAction Stop
                foreach ($p in $props.PSObject.Properties) {
                    if ($p.Name -notin @('PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider')) {
                        $items.Add([pscustomobject]@{
                            Name = $p.Name
                            Command = [string]$p.Value
                            Location = $src.Path
                            SourceType = 'Registry'
                            Scope = $src.Scope
                            Enabled = $true
                        }) | Out-Null
                    }
                }
            }
        } catch {
            Write-Warning ("Unable to read startup registry source {0}. {1}" -f $src.Path, $_.Exception.Message)
        }
    }

    $startupFolders = @(
        @{ Scope = 'CurrentUser'; Path = [Environment]::GetFolderPath('Startup') },
        @{ Scope = 'AllUsers'; Path = [Environment]::GetFolderPath('CommonStartup') }
    )

    foreach ($folder in $startupFolders) {
        try {
            if (-not [string]::IsNullOrWhiteSpace($folder.Path) -and (Test-Path -LiteralPath $folder.Path)) {
                Get-ChildItem -LiteralPath $folder.Path -File -ErrorAction Stop |
                    ForEach-Object {
                        $items.Add([pscustomobject]@{
                            Name = $_.BaseName
                            Command = $_.FullName
                            Location = $folder.Path
                            SourceType = 'StartupFolder'
                            Scope = $folder.Scope
                            Enabled = -not $_.Extension.Equals('.disabled', [System.StringComparison]::OrdinalIgnoreCase)
                        }) | Out-Null
                    }
            }
        } catch {
            Write-Warning ("Unable to read startup folder {0}. {1}" -f $folder.Path, $_.Exception.Message)
        }
    }

    return $items
}

function Disable-StartupProgram {
    param(
        [Parameter(Mandatory = $true)]
        [string]$NameToDisable
    )

    # This section disables matching startup entries in both registry and startup folders.
    $result = [ordered]@{
        RequestedName = $NameToDisable
        MatchedItems = 0
        DisabledItems = 0
        AlreadyDisabled = 0
        Errors = 0
    }

    $exactMatches = Get-StartupItems | Where-Object { $_.Name -ieq $NameToDisable }
    $result.MatchedItems = @($exactMatches).Count

    if ($result.MatchedItems -eq 0) {
        Write-Host ("No startup item found with name: {0}" -f $NameToDisable) -ForegroundColor Yellow
        return [pscustomobject]$result
    }

    foreach ($item in $exactMatches) {
        if ($item.SourceType -eq 'Registry') {
            try {
                $disabledPath = $item.Location -replace '\\Run$', '\\Run-Disabled'

                if (-not (Test-Path -LiteralPath $disabledPath)) {
                    New-Item -Path $disabledPath -Force | Out-Null
                }

                $existing = Get-ItemProperty -LiteralPath $disabledPath -Name $item.Name -ErrorAction SilentlyContinue
                if ($null -ne $existing) {
                    $result.AlreadyDisabled++
                    Write-Host ("Already disabled (registry): {0} [{1}]" -f $item.Name, $item.Scope)
                    continue
                }

                New-ItemProperty -LiteralPath $disabledPath -Name $item.Name -Value $item.Command -PropertyType String -Force | Out-Null
                Remove-ItemProperty -LiteralPath $item.Location -Name $item.Name -ErrorAction Stop

                $result.DisabledItems++
                Write-Host ("Disabled (registry): {0} [{1}]" -f $item.Name, $item.Scope) -ForegroundColor Green
            } catch {
                $result.Errors++
                Write-Warning ("Failed to disable registry startup item {0}. {1}" -f $item.Name, $_.Exception.Message)
            }
        }

        if ($item.SourceType -eq 'StartupFolder') {
            try {
                if ($item.Command.EndsWith('.disabled', [System.StringComparison]::OrdinalIgnoreCase)) {
                    $result.AlreadyDisabled++
                    Write-Host ("Already disabled (startup folder): {0} [{1}]" -f $item.Name, $item.Scope)
                    continue
                }

                $targetPath = "{0}.disabled" -f $item.Command
                if (Test-Path -LiteralPath $targetPath) {
                    $result.AlreadyDisabled++
                    Write-Host ("Already disabled (startup folder): {0} [{1}]" -f $item.Name, $item.Scope)
                    continue
                }

                Rename-Item -LiteralPath $item.Command -NewName ([System.IO.Path]::GetFileName($targetPath)) -ErrorAction Stop
                $result.DisabledItems++
                Write-Host ("Disabled (startup folder): {0} [{1}]" -f $item.Name, $item.Scope) -ForegroundColor Green
            } catch {
                $result.Errors++
                Write-Warning ("Failed to disable startup folder item {0}. {1}" -f $item.Name, $_.Exception.Message)
            }
        }
    }

    return [pscustomobject]$result
}

# This section routes script execution to listing mode or disable mode.
if ($PSCmdlet.ParameterSetName -eq 'Disable' -or $Disable.IsPresent) {
    $disableSummary = Disable-StartupProgram -NameToDisable $ProgramName
    Write-Host ''
    Write-Host '========== Startup Disable Summary ==========' -ForegroundColor Cyan
    foreach ($k in $disableSummary.PSObject.Properties.Name) {
        Write-Host ("{0}: {1}" -f $k, $disableSummary.$k)
    }
    Write-Host '=============================================' -ForegroundColor Cyan
    exit
}

# This section performs dry-run listing by default to show current startup programs.
$startupItems = Get-StartupItems | Sort-Object Scope, SourceType, Name

Write-Host ''
Write-Host '========== Startup Program Audit (Dry Run) ==========' -ForegroundColor Cyan
if (@($startupItems).Count -eq 0) {
    Write-Host 'No startup programs found.' -ForegroundColor Yellow
} else {
    $startupItems |
        Select-Object Name, Scope, SourceType, Enabled, Command, Location |
        Format-Table -AutoSize |
        Out-Host
}
Write-Host '=====================================================' -ForegroundColor Cyan
