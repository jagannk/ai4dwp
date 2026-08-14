# L2 Technical Article: Floor 6 Login/Performance Recurrence Handling
Version: 1.0
Date: 2026-08-14
Source runbook: runbook-floor6-section4-ring-pull-rollback-v1.md

## Purpose
This article re-expresses the Section 4 runbook for next-incident execution by L2/L3 engineering.

## Trigger condition
Use when Floor 6 login/performance symptoms recur and deployment ring correlation is re-established.

## Inputs
- `$RingGroupId`: problematic deployment ring group.
- `$RollbackGroupId`: rollback/uninstall or known-good version group.
- `$AffectedDeviceNames`: confirmed incident device list.

## Execution procedure
1. Connect to Microsoft Graph with required scopes.
2. Resolve each device in Entra by `displayName`.
3. Remove each resolved device from `$RingGroupId`.
4. Add each resolved device to `$RollbackGroupId`.
5. Trigger Intune sync on each managed device.
6. Export results to timestamped CSV evidence.

## Canonical command block
Use the exact Section 4 commands from the source runbook:
- Authentication and module load.
- Variable assignment for ring, rollback, and affected devices.
- `foreach` action loop creating `RemovedFromRing`, `AddedToRollback`, and `SyncTriggered` flags.
- CSV export: `rollback-ring-action-<timestamp>.csv`.

## Expected success criteria
- Per-device status row present.
- Success flags true for ring removal, rollback add, and sync trigger.
- Membership verifies: absent in ring group, present in rollback group.
- Follow-up user tests show improved login/performance.

## Verification checklist
1. Group membership corrected for every affected device.
2. Intune check-in timestamp updated after sync.
3. Assigned app state reflects rollback targeting.
4. Pilot user confirms improvement on next sign-in.

## Rollback of this fix
If wrong cohort was targeted:
1. Remove affected devices from `$RollbackGroupId`.
2. Re-add affected devices to `$RingGroupId`.
3. Trigger Intune sync again.
4. Record rollback actions in incident notes with CSV attachment.

## Notes for handoff
- Keep all IDs and the exported CSV in the incident timeline.
- If Graph resolution fails for a device, mark it explicitly as unresolved and continue remaining devices.
