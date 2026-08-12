# L2/L3 KB - Autopilot Enrollment Conflict Remediation (0x80180014)

Last updated: 2026-08-11  
Audience: L2/L3 Endpoint Engineering

## Objective

Resolve Autopilot enrollment failures caused by legacy/stale MDM enrollment state while preserving authoritative device identity and restoring profile delivery.

## Confirmed Signature

- EnrollmentState = Failed
- ErrorCode = 0x80180014
- Description indicates existing MDM enrollment
- ProfilesApplied often 0/N
- Companion signal may include 0x80070005 (Access denied)

## Preconditions

- Change approval available if cleanup impacts production records
- Device identity details available (serial, hardware hash, device name, user UPN)

## Step 1 - Evidence Collection

Collect and attach to ticket:
- MDM diagnostic export
- Current device record(s) from Intune and Entra
- Enrollment history and timestamps
- Profile assignment status

## Step 2 - Confirm Conflict Scope

1. Verify prior/manual legacy enrollment exists.
2. Check for duplicate or stale device identities in tenant systems.
3. Confirm prerequisites are otherwise healthy:
- Azure AD join present
- Licensing present
- Network reachable

## Step 3 - Remediation Actions

1. Retire/remove stale legacy MDM enrollment record(s) per governance.
2. Clean conflicting local enrollment artifacts using approved endpoint runbook.
3. Reboot device.
4. Re-initiate enrollment via standard Autopilot flow.
5. Trigger sync.

## Step 4 - Post-Remediation Validation

All conditions should pass:
- Enrollment succeeds (no repeat 0x80180014)
- Profile application progresses to expected total
- No recurring access-denied signal in immediate policy cycle
- Single authoritative device identity remains in Intune/Entra

## Step 5 - If Issue Persists

- Re-check for hidden duplicate object or stale assignment link.
- Review enrollment and DeviceManagement diagnostic logs for same-cycle failure markers.
- Escalate to platform engineering with full artifact bundle and failure sequence.

## Rollout Prevention Controls

- Enforce pre-flight check for legacy enrollment state before Autopilot assignment.
- Implement duplicate object detection (serial + hardware hash + device identity).
- Apply rollout gate thresholds before moving beyond pilot wave.

## Ticket Closure Requirements

Ticket can be closed only when:
- Root cause documented as confirmed or ruled out
- Remediation steps and timestamps recorded
- Validation evidence attached
- Preventive control action logged (if process gap identified)
