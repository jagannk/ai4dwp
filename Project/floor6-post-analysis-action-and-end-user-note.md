# Floor 6 Post-Analysis Action and End-User Note

## Most-likely cause
Post-analysis points to the Friday app deployment ring as the most likely cause of Monday login/performance degradation on Floor 6.

## Technical action to execute now (Intune/Entra ring pull + rollback targeting)
Use this when affected devices are in a pilot/ring group and you need immediate containment.

### 1) Required inputs
Set these values before running:
- $RingGroupId: Entra group currently targeted by the problematic app deployment
- $RollbackGroupId: Entra group targeted by rollback/uninstall assignment
- $AffectedDeviceNames: device names from Floor 6 incident list

### 2) Commands
```powershell
# Requires Microsoft Graph PowerShell SDK
# Install once if needed: Install-Module Microsoft.Graph -Scope CurrentUser

Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.DeviceManagement
Import-Module Microsoft.Graph.Identity.DirectoryManagement

Connect-MgGraph -Scopes "GroupMember.ReadWrite.All","Device.Read.All","DeviceManagementManagedDevices.ReadWrite.All"

$RingGroupId = "11111111-1111-1111-1111-111111111111"
$RollbackGroupId = "22222222-2222-2222-2222-222222222222"
$AffectedDeviceNames = @(
  "FL6-LT-001",
  "FL6-LT-004",
  "FL6-LT-007"
)

$results = foreach ($deviceName in $AffectedDeviceNames) {
    $aadDevice = Get-MgDevice -Filter "displayName eq '$deviceName'" -ConsistencyLevel eventual -ErrorAction SilentlyContinue | Select-Object -First 1

    if (-not $aadDevice) {
        [pscustomobject]@{
            DeviceName = $deviceName
            AADDeviceId = $null
            RemovedFromRing = $false
            AddedToRollback = $false
            SyncTriggered = $false
            Status = "Device not found in Entra"
        }
        continue
    }

    $removed = $false
    $added = $false
    $synced = $false
    $status = "OK"

    try {
        Remove-MgGroupMemberByRef -GroupId $RingGroupId -DirectoryObjectId $aadDevice.Id -ErrorAction Stop
        $removed = $true
    }
    catch {
        $status = "Ring removal warning: $($_.Exception.Message)"
    }

    try {
        New-MgGroupMemberByRef -GroupId $RollbackGroupId -BodyParameter @{"@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($aadDevice.Id)"}
        $added = $true
    }
    catch {
        $status = "Rollback add warning: $($_.Exception.Message)"
    }

    try {
        $managedDevice = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$deviceName'" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($managedDevice) {
            Invoke-MgDeviceManagementManagedDeviceSyncDevice -ManagedDeviceId $managedDevice.Id
            $synced = $true
        }
        else {
            $status = "No Intune managed device found for sync"
        }
    }
    catch {
        $status = "Sync warning: $($_.Exception.Message)"
    }

    [pscustomobject]@{
        DeviceName = $deviceName
        AADDeviceId = $aadDevice.Id
        RemovedFromRing = $removed
        AddedToRollback = $added
        SyncTriggered = $synced
        Status = $status
    }
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outFile = ".\rollback-ring-action-$stamp.csv"
$results | Export-Csv -Path $outFile -NoTypeInformation -Encoding utf8
$results | Format-Table -AutoSize
Write-Host "Action log written to $outFile"
```

### 3) Optional emergency local rollback command (single device)
Use only if central policy propagation is delayed and CAB/incident lead approves:
```powershell
# Example pattern only: replace with actual product or package identity
Get-Package | Where-Object { $_.Name -like "*FinBridge*" } | Uninstall-Package -Force
```

## Plain-language note to Floor 6 (reassuring, no uncontrolled ETA)
Hi Team,

We identified a likely link between a recent software deployment and the sign-in/performance issues affecting Floor 6, and we have already started targeted remediation on impacted devices. Your files and account data remain safe, and we will continue updates at key checkpoints until service behavior is stable across the floor.
