$ErrorActionPreference = 'Stop'

$registrationToken = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('__TOKEN_B64__'))
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\RDInfraAgent' -Name RegistrationToken -Value $registrationToken

Restart-Service -Name RdAgent -Force
Restart-Service -Name RDAgentBootLoader -Force

$t = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\RDInfraAgent').RegistrationToken
Write-Output ("TokenLength={0}" -f $t.Length)
Write-Output ("TokenPrefix={0}" -f $t.Substring(0, [Math]::Min(20, $t.Length)))
