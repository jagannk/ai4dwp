param(
    [Parameter(Mandatory = $true)]
    [string]$registrationToken
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$agentPath = 'C:\Windows\Temp\AVD-Agent.msi'
$bootPath = 'C:\Windows\Temp\AVD-Boot.msi'

Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/?linkid=2310011' -OutFile $agentPath
Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/?linkid=2311028' -OutFile $bootPath

$agentInstallCmd = "/c msiexec /i \"$agentPath\" /qn REGISTRATIONTOKEN=$registrationToken"
$bootInstallCmd = "/c msiexec /i \"$bootPath\" /qn"

Start-Process -FilePath 'cmd.exe' -ArgumentList $agentInstallCmd -Wait -NoNewWindow
Start-Process -FilePath 'cmd.exe' -ArgumentList $bootInstallCmd -Wait -NoNewWindow

Get-Service -Name RDAgentBootLoader, RDAgent | Select-Object Name, Status, StartType | ConvertTo-Json -Compress
