# Autopilot Enrollment Failure Analysis and Finalized Resolution (DWP)

Date: 2026-08-11  
Analyst: DWP L2/L3 Support  
Incident Type: Windows Autopilot enrollment failure

## 1) Executive Summary

A Windows device failed Autopilot enrollment. The exported diagnostics indicate the device was already enrolled through a legacy manual MDM channel, which blocked the new enrollment flow. Secondary evidence shows policy application did not proceed and failed with access denied. Licensing and network health were confirmed as good, reducing likelihood of tenant licensing or connectivity as primary causes.

Finalized resolution: remove the legacy/stale MDM enrollment context, cleanly re-enroll the device through the intended Intune Autopilot flow, and validate that all required profiles apply.

## 2) Source Evidence (Collected Facts)

From the provided MDM diagnostic export:

- EnrollmentState: Failed
- ErrorCode: 0x80180014
- ErrorDescription: The device is already enrolled in MDM.
- MDMEnrolled: Yes (previous enrollment from 2023-11-04)
- EnrolmentSource: Legacy manual MDM enrollment
- ProfilesApplied: 0 of 4
- LastError: 0x80070005 (Access denied)
- AzureADJoined: Yes
- IntuneP1License: Yes
- AutopilotLicense: Yes
- Network: All endpoints reachable, no proxy

## 3) Scope Interpretation (No Hypothesis Layer)

- Enrollment status: Failed
- Reported enrollment blocker: device already enrolled in MDM
- Azure AD join state: Joined
- Prior MDM state: Present (legacy manual enrollment)
- Policy/profile application status: Failed (0/4 applied)
- Licensing posture: Correct (Intune P1 and Autopilot licenses present)
- Connectivity posture: Healthy

## 4) Ranked Likely Causes (Most Probable First)

### Cause 1: Existing legacy MDM enrollment blocks Autopilot enrollment

Why this fits:
- Direct match with export text: "device is already enrolled in MDM"
- Prior enrollment exists and source is legacy manual enrollment
- New profile application never progressed (0/4)

Fastest confirmation check:
- Verify existing MDM artifacts on device and matching historical enrollment record in tenant
- Confirm there is an old enrollment relationship tied to the same device/user

Remediation if confirmed:
- Retire/remove old MDM enrollment record and stale local enrollment artifacts using approved runbook
- Re-run enrollment via the current Autopilot + Intune path

### Cause 2: Access denied during policy channel creation due to stale enrollment context

Why this fits:
- LastError is 0x80070005 (Access denied)
- 0/4 profiles applied suggests failure before settings delivery

Fastest confirmation check:
- Review DeviceManagement-Enterprise-Diagnostics-Provider event logs at failure time
- Validate MDM certificate/task artifacts are valid and owned by expected context

Remediation if confirmed:
- Remove corrupted/stale enrollment artifacts
- Reboot and trigger fresh enrollment + sync

### Cause 3: Duplicate/conflicting device identity records (legacy vs Autopilot target object)

Why this fits:
- Device is AAD joined and licensed, and network is healthy
- Legacy enrollment plus Autopilot assignment can collide when duplicate objects exist

Fastest confirmation check:
- Search Intune/Entra by serial, hardware hash, and device name for duplicate active records

Remediation if confirmed:
- Retain authoritative device object, retire stale duplicate record(s), reassign profile, retry enrollment

## 5) Finalized Resolution Plan

1. Identify and document all existing enrollment objects and local MDM artifacts for the device.
2. Retire/remove legacy manual MDM enrollment (tenant-side and local stale enrollment context) per standard change process.
3. Reboot device to clear enrollment session state.
4. Start clean Autopilot enrollment sequence with intended user/device assignment.
5. Force sync and confirm profile application progression from 0/4 to expected completion.
6. Verify compliance and conditional access posture after successful enrollment.

## 6) Validation Criteria After Remediation

Success is confirmed only when all conditions below are true:

- EnrollmentState changes to success state
- No repeat of 0x80180014 during enrollment
- ProfilesApplied reaches expected count (4/4 for this case)
- Access denied condition (0x80070005) no longer appears in latest enrollment/policy cycle
- Device remains Azure AD joined and appears once (authoritative object) in Intune/Entra
- Device reports compliant against assigned baseline after sync

## 7) Operational Safeguards for Future Autopilot Waves

- Add pre-flight check: block migration if legacy manual MDM enrollment is detected.
- Add duplicate-object check (serial + hardware hash) before Autopilot assignment.
- Pilot enrollment with telemetry watch for 0x80180014 and 0x80070005 before broad rollout.
- Track profile application rate (applied/expected) in first 24 hours for early failure detection.

## 8) Code Meaning Handling Note

- 0x80180014: treated as confirmed per export description (device already enrolled in MDM).
- 0x80070005: treated as confirmed per export description (Access denied).
- No additional unsupported error-code expansion was used in this analysis.
