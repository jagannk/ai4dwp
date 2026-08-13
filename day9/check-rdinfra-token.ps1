$reg = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\RDInfraAgent' -ErrorAction SilentlyContinue
$token = $reg.RegistrationToken

if (-not $token) {
    Write-Output 'TokenMissing'
    exit 0
}

$prefixLen = [Math]::Min(20, $token.Length)
$suffixStart = [Math]::Max(0, $token.Length - 20)
$suffixLen = $token.Length - $suffixStart

Write-Output ("TokenLength={0}" -f $token.Length)
Write-Output ("TokenPrefix={0}" -f $token.Substring(0, $prefixLen))
Write-Output ("TokenSuffix={0}" -f $token.Substring($suffixStart, $suffixLen))
