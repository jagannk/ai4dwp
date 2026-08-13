param(
    [Parameter(Mandatory = $true)]
    [string]$registrationTokenBase64
)

$ErrorActionPreference = 'Stop'

$registrationToken = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($registrationTokenBase64))

$regPath = 'HKLM:\SOFTWARE\Microsoft\RDInfraAgent'
Set-ItemProperty -Path $regPath -Name RegistrationToken -Value $registrationToken

Restart-Service -Name RdAgent -Force
Restart-Service -Name RDAgentBootLoader -Force

$token = (Get-ItemProperty -Path $regPath).RegistrationToken
Write-Output ("TokenLength={0}" -f $token.Length)
Write-Output ("TokenPrefix={0}" -f $token.Substring(0, [Math]::Min(20, $token.Length)))
