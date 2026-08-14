# Runbook: Floor 6 Login/Performance Fix (Section 4)
Version: 1.0
Date: 2026-08-14
Owner: DWP Engineering

## Source and intent
This runbook is the single source for the Section 4 fix: remove affected devices from the problematic deployment ring, target rollback, and force policy sync.

## Prerequisites
- Incident approved for deployment containment (incident lead or CAB delegate).
- Entra group IDs confirmed:
  - Ring group (`$RingGroupId`): group currently assigned the problematic app version.
  - Rollback group (`$RollbackGroupId`): group assigned uninstall or known-good version.
- Confirmed affected device list (`$AffectedDeviceNames`) from Floor 6.
- Engineer has Graph permissions:
  - `GroupMember.ReadWrite.All`
  - `Device.Read.All`
  - `DeviceManagementManagedDevices.ReadWrite.All`
- Microsoft Graph PowerShell SDK available.

## Section 4 Procedure (numbered)
1. Start authenticated Graph session.

```powershell
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.DeviceManagement
Import-Module Microsoft.Graph.Identity.DirectoryManagement
Connect-MgGraph -Scopes "GroupMember.ReadWrite.All","Device.Read.All","DeviceManagementManagedDevices.ReadWrite.All"
```

Expected result:
- Graph sign-in completes with no scope error.

2. Set containment inputs.

```powershell
$RingGroupId = "11111111-1111-1111-1111-111111111111"
$RollbackGroupId = "22222222-2222-2222-2222-222222222222"
$AffectedDeviceNames = @(
  "FL6-LT-001",
  "FL6-LT-004",
  "FL6-LT-007"
)
```

Expected result:
- Variables exist and device names match the incident list.

3. Execute ring removal, rollback targeting, and sync trigger.

```powershell
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
```

Expected result:
- Each target device returns a row showing containment actions and status.
- Successful rows should show `RemovedFromRing=True`, `AddedToRollback=True`, and `SyncTriggered=True`.

4. Write action evidence and print operator view.

```powershell
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outFile = ".\rollback-ring-action-$stamp.csv"
$results | Export-Csv -Path $outFile -NoTypeInformation -Encoding utf8
$results | Format-Table -AutoSize
Write-Host "Action log written to $outFile"
```

Expected result:
- CSV evidence file created.
- Console table available for immediate handoff.

## Verification
- Group membership:
  - For each device ID, verify it is absent from `$RingGroupId` and present in `$RollbackGroupId`.
- Intune status:
  - Device check-in time updates after sync trigger.
  - Assigned app action reflects rollback policy.
- User impact:
  - On pilot affected users, next sign-in shows improved login/performance versus pre-fix baseline.

## Rollback (if containment was incorrect)
1. Reverse group membership.

```powershell
foreach ($deviceName in $AffectedDeviceNames) {
    $aadDevice = Get-MgDevice -Filter "displayName eq '$deviceName'" -ConsistencyLevel eventual | Select-Object -First 1
    if ($aadDevice) {
        Remove-MgGroupMemberByRef -GroupId $RollbackGroupId -DirectoryObjectId $aadDevice.Id -ErrorAction SilentlyContinue
        New-MgGroupMemberByRef -GroupId $RingGroupId -BodyParameter @{"@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($aadDevice.Id)"}
    }
}
```

Expected result:
- Device membership restored to original deployment ring.

2. Trigger sync again.

```powershell
foreach ($deviceName in $AffectedDeviceNames) {
    $managedDevice = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$deviceName'" | Select-Object -First 1
    if ($managedDevice) { Invoke-MgDeviceManagementManagedDeviceSyncDevice -ManagedDeviceId $managedDevice.Id }
}
```

Expected result:
- Endpoint policy re-evaluates and original assignment state returns.
