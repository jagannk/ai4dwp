# Communication Pack - Autopilot Enrollment Incident

Date: 2026-08-11  
Audience: IT leadership, Service Desk, Endpoint Engineering, Affected users

## 1) Executive Communication (Leadership)

Subject: Update - Autopilot enrollment failures traced to legacy MDM conflict

We identified the primary cause of the current Autopilot enrollment failures. A subset of devices still contains legacy manual MDM enrollment state, which conflicts with the new Autopilot enrollment flow and prevents profile application.

What we know:
- Failure signature is consistent (0x80180014 with existing MDM enrollment message).
- Supporting error 0x80070005 appeared in failed cycles.
- Licensing, Azure AD join, and network checks are healthy and not primary blockers.

Actions in progress:
- Applying controlled cleanup of legacy enrollment state.
- Re-running enrollment through standard Autopilot process.
- Monitoring successful profile application and recurrence rate.

Risk and mitigation:
- Risk: Additional legacy-state devices may fail in later waves.
- Mitigation: Mandatory pre-flight checks and rollout gates before expansion.

Next update: within the agreed operations reporting window.

## 2) Service Desk Communication

Subject: Handling Autopilot failure cases with existing MDM enrollment

If device enrollment fails and shows 0x80180014:

1. Confirm device has prior MDM enrollment state.
2. Do not continue repeated enrollment retries.
3. Route to L2/L3 cleanup path for legacy enrollment conflict.
4. Inform user provisioning is delayed pending remediation.

User-facing message:
"Your device setup is paused because of a management enrollment conflict. We are applying a fix and will retry setup. We will update you once provisioning is complete."

## 3) End-User Communication Template

Subject: Your device setup status

Hello <UserName>,

Your new device setup is currently delayed due to a management enrollment conflict identified during automated setup. Our endpoint team is applying a fix now.

What this means for you:
- No action is needed from you at this time.
- We will retry setup after remediation.
- We will confirm when your device is ready.

Estimated next update: <time window>

Thank you,
IT Support

## 4) Technical Stakeholder Update (Engineering)

Observed signals:
- EnrollmentState Failed
- 0x80180014 existing MDM enrollment
- MDMEnrolled Yes (legacy source)
- ProfilesApplied 0/4
- 0x80070005 access denied

Current control actions:
- Remove stale enrollment artifacts and stale tenant association
- Re-enroll and validate profile application
- Track recurrence by wave and gate rollout

Decision:
- No broad rollout expansion until post-remediation validation criteria are met.
