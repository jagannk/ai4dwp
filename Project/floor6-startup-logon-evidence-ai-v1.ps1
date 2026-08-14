[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AppName,
    [int]$LookbackHours = 72,
    [string]$OutDir = ".\floor6-evidence",
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$startTime = (Get-Date).AddHours(-$LookbackHours)
$hostInfo = Get-CimInstance Win32_OperatingSystem | Select-Object CSName, Caption, Version, LastBootUpTime

if (-not $DryRun) {
    New-Item -Path $OutDir -ItemType Directory -Force | Out-Null
}

$startupCommands = Get-CimInstance Win32_StartupCommand | Where-Object {
    $_.Name -match $AppName -or $_.Command -match $AppName
} | Select-Object Name, Command, Location, User

$runKeys = @(
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
)
$runEntries = foreach ($k in $runKeys) {
    if (Test-Path $k) {
        $item = Get-ItemProperty -Path $k
        foreach ($p in $item.PSObject.Properties) {
            if ($p.Name -in @('PSPath','PSParentPath','PSChildName','PSDrive','PSProvider')) { continue }
            if ($p.Value -match $AppName -or $p.Name -match $AppName) {
                [pscustomobject]@{
                    RegistryPath = $k
                    Name = $p.Name
                    Command = [string]$p.Value
                }
            }
        }
    }
}

$tasks = Get-ScheduledTask | Where-Object {
    $_.TaskName -match $AppName -or $_.TaskPath -match $AppName
} | Select-Object TaskName, TaskPath, State

$procs = Get-Process | Where-Object {
    $_.ProcessName -match $AppName
} | Select-Object ProcessName, Id, CPU, StartTime, WorkingSet64

$diagEvents = Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Diagnostics-Performance/Operational'
    StartTime = $startTime
} -ErrorAction SilentlyContinue | Where-Object {
    $_.Message -match 'logon|boot|degrad'
} | Select-Object TimeCreated, Id, LevelDisplayName, Message

$summary = [pscustomobject]@{
    CollectedAt = (Get-Date)
    ComputerName = $env:COMPUTERNAME
    AppName = $AppName
    LookbackHours = $LookbackHours
    StartupHits = @($startupCommands).Count + @($runEntries).Count
    ScheduledTaskHits = @($tasks).Count
    RunningProcessHits = @($procs).Count
    DiagnosticsEvents = @($diagEvents).Count
}

if ($DryRun) {
    [pscustomobject]@{
        Mode = 'DryRun'
        PlannedOutputDirectory = (Resolve-Path -Path .).Path + '\\' + $OutDir.TrimStart('.\\')
        WouldCollect = @(
            'Win32_StartupCommand',
            'HKLM/HKCU Run keys',
            'Scheduled tasks',
            'Running process sample',
            'Diagnostics-Performance events'
        )
        SummaryPreview = $summary
    } | Format-List
    return
}

$startupCommands | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $OutDir 'startup-commands.json')
$runEntries | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $OutDir 'run-key-hits.json')
$tasks | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $OutDir 'scheduled-task-hits.json')
$procs | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $OutDir 'running-process-hits.json')
$diagEvents | Export-Csv -NoTypeInformation -Path (Join-Path $OutDir 'diagnostics-performance-events.csv')
$summary | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $OutDir 'summary.json')
$hostInfo | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $OutDir 'host.json')

[pscustomobject]@{
    Status = 'Complete'
    OutputDirectory = (Resolve-Path $OutDir).Path
    Summary = $summary
    Files = @(
        'summary.json',
        'host.json',
        'startup-commands.json',
        'run-key-hits.json',
        'scheduled-task-hits.json',
        'running-process-hits.json',
        'diagnostics-performance-events.csv'
    )
} | Format-List
