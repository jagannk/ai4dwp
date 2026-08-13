$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$agentPath = 'C:\Windows\Temp\AVD-Agent.msi'
$bootPath = 'C:\Windows\Temp\AVD-Boot.msi'

Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/?linkid=2310011' -OutFile $agentPath
Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/?linkid=2311028' -OutFile $bootPath

Start-Process -FilePath 'msiexec.exe' -ArgumentList @('/i', $agentPath, '/qn') -Wait -NoNewWindow
Start-Process -FilePath 'msiexec.exe' -ArgumentList @('/i', $bootPath, '/qn') -Wait -NoNewWindow

Get-Service -Name RdAgent,RDAgentBootLoader | Select-Object Name,Status,StartType | ConvertTo-Json -Compress
