# Incident Closure Note - Autopilot Enrollment Failure

Date closed: 2026-08-11  
Incident owner: DWP Endpoint Support

## Incident Overview

Autopilot enrollment failures were observed on devices with legacy manual MDM enrollment state. Failures presented with 0x80180014 and blocked profile application.

## Confirmed Root Cause

Existing legacy MDM enrollment context conflicted with current Autopilot enrollment path.

## Key Evidence Used

- EnrollmentState: Failed
- ErrorCode: 0x80180014
- ErrorDescription: device already enrolled in MDM
- MDMEnrolled: Yes (legacy manual enrollment)
- ProfilesApplied: 0 of 4
- LastError: 0x80070005 (Access denied)
- AzureADJoined: Yes
- Intune and Autopilot licensing: Yes
- Network: healthy

## Resolution Implemented

1. Identified legacy/stale MDM enrollment state.
2. Removed conflicting enrollment artifacts and stale record associations per runbook.
3. Rebooted and re-ran Autopilot enrollment.
4. Forced sync and validated profile application recovery.

## Validation Outcome

Closure criteria met:
- Enrollment no longer fails with 0x80180014 on remediated path.
- Enrollment/profile progression resumed from previous blocked state.
- No prerequisite issues found in licensing, AAD join, or network.

## Preventive Actions Logged

- Mandatory pre-flight check for legacy enrollment state before Autopilot wave assignment.
- Duplicate identity/object check in Intune/Entra before provisioning.
- Rollout gate based on enrollment failure thresholds and recurring error signature.

## Lessons Learned

- Legacy MDM state must be treated as a hard blocker for modern enrollment flows.
- Early pre-flight controls reduce user-facing provisioning delays and repeated failed attempts.

## Closure Approval

Approved by: <Approver Name/Role>  
Approval date: <Date>
