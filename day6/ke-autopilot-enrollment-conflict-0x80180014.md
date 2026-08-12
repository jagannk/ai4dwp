# Known Error Record - Autopilot Enrollment Conflict (0x80180014)

Date opened: 2026-08-11  
Owner team: DWP Endpoint Engineering  
Status: Known Error - Workaround and permanent fix available

## KE Summary

Autopilot enrollment can fail when a device already has a legacy manual MDM enrollment context. In this condition, the enrollment workflow fails and required profiles are not applied.

## Error Signature

- EnrollmentState: Failed
- ErrorCode: 0x80180014
- ErrorDescription: The device is already enrolled in MDM.
- Common companion signal: LastError 0x80070005 (Access denied)
- Typical profile result: ProfilesApplied = 0 of expected profiles

## Affected Scope

- Devices entering Autopilot with historical non-Autopilot MDM enrollment state
- Most likely during migration waves from older/manual enrollment methods

## Business Impact

- Device provisioning delayed
- User readiness delayed
- Managed baseline not applied until resolved

## Root Cause

Primary: Existing legacy manual MDM enrollment conflicts with current Autopilot enrollment path.  
Contributing: No mandatory pre-flight cleanup/check for stale enrollment state.

## Detection Criteria

Treat as this known error when all are true:

1. Enrollment fails during Autopilot.
2. 0x80180014 with description indicating existing MDM enrollment is present.
3. Evidence of prior MDM enrollment record or local legacy MDM artifacts.

## Workaround

- Temporarily route affected device through legacy-enrollment cleanup process before retrying Autopilot.
- Hold user cutover until enrollment retry succeeds and expected profiles apply.

## Permanent Fix

1. Retire/remove stale legacy MDM enrollment (tenant record + local enrollment artifacts) per approved runbook.
2. Reboot device.
3. Re-run standard Autopilot enrollment.
4. Force sync and verify profiles apply to expected count.

## Verification of Recovery

- EnrollmentState no longer failed
- 0x80180014 no longer present
- ProfilesApplied reaches expected value
- No recurrence of 0x80070005 in immediate enrollment cycle

## Preventive Controls

- Add mandatory pre-flight check for legacy enrollment state.
- Add duplicate object check in Intune/Entra before assignment.
- Add wave gate: do not scale rollout if enrollment-failure threshold is exceeded.

## Escalation Rules

Escalate to L2/L3 when:

- Cleanup completed but 0x80180014 persists
- Multiple active device identities cannot be safely reconciled
- Access denied signals continue after clean re-enrollment attempt
