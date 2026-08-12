# Detailed RCA - Autopilot Enrollment Failure (DWP)

Date: 2026-08-11  
Prepared by: DWP Analyst  
Incident category: Endpoint provisioning / MDM enrollment

## 1. Incident Summary

A Windows device failed during Autopilot enrollment. The primary blocker reported by diagnostics was that the device already had an existing MDM enrollment from a legacy manual process. Policy/profile delivery did not complete, and a secondary access-denied condition was observed during the failed cycle.

## 2. Scope and Impact

- Scope: Affected endpoint(s) entering Autopilot flow with historical non-Autopilot MDM state.
- Immediate impact: New enrollment failed; required profiles were not applied.
- Security/compliance impact: Device could not progress through intended managed configuration baseline until enrollment conflict was removed.
- Business impact: Provisioning delay and potential user onboarding delay.

## 3. Supporting Evidence (Verbatim Diagnostic Facts)

Source: Device MDM diagnostic export provided for analysis.

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

## 4. Evidence Interpretation Matrix

| Evidence item | What it establishes | RCA relevance |
|---|---|---|
| EnrollmentState = Failed | Enrollment did not complete | Confirms incident condition |
| ErrorDescription = already enrolled in MDM | Existing enrollment conflict is present | Strong primary-cause signal |
| MDMEnrolled = Yes, legacy source/date present | Prior manual MDM relationship exists | Explains enrollment collision path |
| ProfilesApplied = 0/4 | Policy delivery never progressed | Indicates failure early in enrollment/channel setup |
| LastError = 0x80070005 (Access denied) | Permission/access failure occurred in cycle | Likely secondary symptom tied to stale enrollment context |
| AzureADJoined = Yes | Join prerequisite satisfied | Rules out AAD join absence as primary cause |
| Intune/Autopilot licenses = Yes | Licensing prerequisites satisfied | Rules out license deficiency as primary cause |
| Network endpoints reachable, no proxy | Connectivity baseline healthy | Rules out network path issues as primary cause |

## 5. Incident Timeline

Note: Exact wall-clock timestamps were not present in the provided export. Timeline below is evidence-sequenced.

- T-1 (historical): Device previously enrolled through legacy manual MDM process (2023-11-04).
- T0: Device enters Autopilot enrollment workflow.
- T1: Enrollment attempt fails (EnrollmentState = Failed).
- T2: Enrollment reports 0x80180014 with message indicating existing MDM enrollment conflict.
- T3: Profile application does not proceed (ProfilesApplied = 0 of 4).
- T4: Access denied condition appears in cycle (LastError = 0x80070005).
- T5: Diagnostic review confirms prerequisites otherwise healthy (AAD joined, licensed, network reachable).
- T6: Resolution path finalized: remove legacy/stale enrollment context and re-enroll via intended Autopilot-Intune flow.

## 6. Problem Statement

Why did Autopilot enrollment fail for this device despite valid Azure AD join, licensing, and network prerequisites?

## 7. 5-Why Analysis

1. Why did Autopilot enrollment fail?
Because the enrollment state ended as Failed and the process did not apply required profiles.

2. Why were profiles not applied?
Because enrollment did not successfully establish the active MDM management channel (0 of 4 applied).

3. Why did channel establishment fail?
Because the enrollment flow encountered an existing MDM enrollment conflict (0x80180014 with explicit description).

4. Why was an existing enrollment conflict present?
Because the device retained a prior legacy manual MDM enrollment relationship from 2023-11-04.

5. Why was legacy enrollment still present at Autopilot start?
Because no enforced pre-flight cleanup/validation control removed or blocked devices with legacy enrollment state before entering Autopilot provisioning.

### 5-Why Conclusion

Primary root cause: Legacy manual MDM enrollment state existed on the device and conflicted with Autopilot enrollment.  
Contributing factor: Lack of mandatory pre-flight check and cleanup for legacy/stale enrollment artifacts prior to Autopilot onboarding.

## 8. Final Root Cause Statement

Autopilot enrollment failed because the target device already had an active legacy MDM enrollment context, producing an enrollment conflict (0x80180014). A secondary access-denied event (0x80070005) occurred within the failed cycle, consistent with stale/conflicting management context. Licensing, Azure AD join, and network conditions were not causal in this incident.

## 9. Corrective Actions Taken / Finalized Resolution

1. Identify legacy enrollment records and local enrollment artifacts for the affected device.
2. Retire/remove stale legacy MDM enrollment context per approved support runbook.
3. Reboot and rerun enrollment through standard Autopilot-Intune path.
4. Trigger sync and verify profile application completion (target: 4/4).
5. Validate compliance and access posture after successful enrollment.

## 10. Preventive Actions

### Process Controls

- Implement mandatory pre-flight enrollment check to detect existing manual/legacy MDM state.
- Gate Autopilot assignment until conflicting enrollment artifacts are cleared.
- Add duplicate-object review in Intune/Entra (serial/hardware hash/device identity) before provisioning.

### Technical Controls

- Standardize legacy artifact cleanup procedure for L2/L3 with approval checkpoints.
- Add automated detection/reporting for devices with dual or stale enrollment indicators.
- Add enrollment health dashboard metric for profile application ratio (applied/expected) in first 24 hours.

### Operational Controls

- Pilot each rollout wave and monitor for recurrence of 0x80180014 and 0x80070005 patterns.
- Define rollback/hold criteria if failed-enrollment rate exceeds threshold.
- Update helpdesk triage script to capture prior enrollment history at first contact.

## 11. Validation of Effectiveness (Post-Remediation)

Resolution is considered effective when all are true:

- Enrollment no longer fails for affected cohort with existing-legacy-state pattern.
- No repeat occurrence of 0x80180014 for remediated devices.
- Profile application completes to expected count after re-enrollment.
- Access-denied enrollment symptom no longer present in immediate post-enrollment cycle.
- Device appears as a single authoritative managed identity in tenant records.

## 12. Residual Risk and Follow-Up

- Residual risk: Additional devices with unknown legacy enrollment state may fail similarly in future waves.
- Follow-up owner action: Run tenant-wide pre-flight scan for legacy enrollment markers before next migration tranche.
- Follow-up review window: 7 days after next rollout wave.
