# L1 KB - Autopilot Enrollment Failure 0x80180014

Last updated: 2026-08-11  
Audience: L1 Service Desk

## Purpose

Help L1 quickly identify and route Autopilot enrollment failures caused by existing MDM enrollment conflicts.

## When to Use This KB

Use when user reports device setup/autopilot enrollment failed and diagnostic output shows:
- 0x80180014
- Message indicates device is already enrolled in MDM

## What L1 Should Check (Fast Triage)

1. Confirm failure signature:
- Enrollment failed
- Error code 0x80180014
- Existing MDM enrollment message present

2. Confirm basic prerequisites are not obvious blockers:
- Azure AD joined state present (if available in export)
- Network reachable
- Licensing indicators present

3. Confirm whether profiles are not applying (for example 0 of expected profiles)

## L1 Decision Tree

- If 0x80180014 with existing MDM enrollment message is present:
  - Classify as probable legacy enrollment conflict.
  - Escalate to L2/L3 using escalation template below.

- If signature is different:
  - Follow standard Autopilot failure triage KB.

## What L1 Must Not Do

- Do not run repeated enrollment retries after signature is confirmed.
- Do not remove device records without L2/L3 process ownership.

## Escalation Template (Copy/Paste)

Subject: Escalation - Autopilot enrollment failure 0x80180014

Include:
- Device name:
- User UPN:
- Serial number:
- EnrollmentState:
- ErrorCode:
- ErrorDescription:
- MDMEnrolled and source/date:
- ProfilesApplied:
- LastError:
- AzureADJoined:
- License indicators:
- Network indicator:

Requested action:
- Validate and remediate legacy/stale MDM enrollment conflict and re-enrollment path.

## User Communication Script

"We identified a management enrollment conflict on your device setup. This needs a backend fix by our endpoint team. We have escalated it and will update you after the enrollment retry is completed."
