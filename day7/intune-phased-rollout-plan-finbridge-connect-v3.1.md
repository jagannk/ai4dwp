# FinBridge Connect v3.1 Intune Phased Deployment Plan (10,000 Win11 Endpoints, 3 Weeks)

## 1. RING STRUCTURE

Ring design is user-targeted (primary assignment by user groups) with device-based guardrails for at-risk hardware.

1. Ring 1 (Pilot)
- Size: 250 users (2.5% of fleet), with at least 50 devices from the 4 GB RAM at-risk segment.
- Duration: 3 calendar days minimum of active monitoring after deployment completes.
- Who to include:
  - IT endpoint engineering and service desk power users.
  - 100 business users from mixed departments.
  - Explicit canary subset of low-spec hardware (4 GB RAM).
- Purpose:
  - Validate install reliability, detection accuracy, uninstall behavior, and baseline performance on standard and low-spec devices.
  - Confirm support readiness before higher business exposure.
- Intune assignment group type:
  - Microsoft Entra ID security group (Assigned/Static membership) for users: `FINBRIDGE-R1-PILOT-USERS`.
  - Supplemental device security group for low-RAM validation: `FINBRIDGE-R1-4GB-DEVICES`.
  - Assignment type in Intune: Required for FinBridge Connect v3.1.

2. Ring 2 (Early)
- Size: 2,250 users total by end of Ring 2, including the 500 Finance users.
- Duration: 4 calendar days minimum monitoring after all Ring 2 assignments are in place.
- Who to include:
  - Finance users (500, highest priority) after Ring 1 pass.
  - Additional business units with medium operational criticality.
  - Keep at least 10% of Ring 2 population from older hardware profile where possible.
- Purpose:
  - Validate business-process fit at real scale.
  - Detect issues that only appear under broader concurrency and varied endpoint states.
- Intune assignment group type:
  - Microsoft Entra ID security groups (Assigned/Static):
    - `FINBRIDGE-R2-FINANCE-USERS`
    - `FINBRIDGE-R2-EARLY-USERS`
  - Assignment type in Intune: Required for FinBridge Connect v3.1.

3. Ring 3 (Broad)
- Size: Remaining 7,500 users.
- Duration: 10 calendar days to complete rollout and stabilization within week 2 and week 3.
- Who to include:
  - All remaining eligible Win11 users not already in Ring 1 or Ring 2.
  - Exclude active incident hold groups if any.
- Purpose:
  - Complete enterprise adoption within deadline while retaining control points.
- Intune assignment group type:
  - Microsoft Entra ID dynamic user group or static batched groups by region/site:
    - `FINBRIDGE-R3-BROAD-USERS`
  - Assignment type in Intune: Required for FinBridge Connect v3.1, staged by subgroup waves (for example, 2,500 users every 2-3 days).

## 2. ADVANCE CRITERIA

Criteria are evaluated per ring at the defined monitoring checkpoint using Intune app install status and service desk ticket counts.

1. Ring 1 -> Ring 2 advance criteria
- Install success rate (minimum): >= 97.0% of targeted endpoints show Installed within 24 hours of assignment.
- Error rate threshold (maximum): <= 2.0% show Failed in Intune device install status over the same 24-hour window.
- User-reported issue rate (maximum): <= 3 tickets per 100 deployed users per 24 hours, where ticket category is FinBridge v3.1 install/use issue.
- Monitoring period (minimum): 72 continuous hours after >95% of Ring 1 endpoints have checked in.
- Time-bound decision point: CAB-lite go/no-go review by end of day 4 from Ring 1 start.

2. Ring 2 -> Ring 3 advance criteria
- Install success rate (minimum): >= 98.0% Installed across Ring 2 within 24 hours of assignment.
- Error rate threshold (maximum): <= 1.5% Failed in Intune over a 24-hour rolling window.
- User-reported issue rate (maximum): <= 2 tickets per 100 deployed users per 24 hours, with no upward trend for 2 consecutive days.
- Monitoring period (minimum): 96 continuous hours after Ring 2 assignment completion.
- Time-bound decision point: go/no-go by end of day 9 from project start, enabling broad completion by end of week 3.

3. Hold condition (pause without full rollback)
- Trigger: any single non-critical issue class exceeds threshold but does not meet rollback trigger. Example: silent install succeeds, but post-install first-launch delay >60 seconds affects 6% of Ring 2 users for one day.
- Action:
  - Pause progression to next ring for 48 hours.
  - Keep current ring active, stop adding new assignments.
  - Deploy mitigation (for example startup pre-cache script or user guidance), then re-evaluate metrics.

## 3. ROLLBACK TRIGGERS

All triggers below are measurable and tied to a specific decision owner, decision window, and exact Intune action.

1. Install failure rate automatic halt trigger
- Trigger condition: Failed status > 5.0% in any active ring for 4 continuous hours after assignment.
- Immediate action: Automatic rollout halt (no new ring expansion).
- Decision owner: Endpoint Engineering Lead (primary) plus Intune Service Owner (approver).
- Decision window: 2 hours from trigger detection.
- Exact Intune rollback action:
  - In FinBridge Connect v3.1 app assignments, remove Required include groups for the active and upcoming rings.
  - Add active ring group(s) to a temporary exclude group: `FINBRIDGE-ROLLBACK-HOLD`.
  - In FinBridge Connect v3.0 app, add Required assignment for the affected ring group(s):
    - `FINBRIDGE-R1-PILOT-USERS`, `FINBRIDGE-R2-FINANCE-USERS`, or `FINBRIDGE-R2-EARLY-USERS` as applicable.
  - If v3.1 must be removed before downgrade, add Uninstall assignment for v3.1 to affected groups, then keep v3.0 Required.

2. Application crash rate rollback-consideration trigger
- Trigger condition: Crash rate >= 2.0 crashes per 100 active users per day, sustained for 2 consecutive days in the same ring.
- Decision owner: Workplace Apps Product Owner with Endpoint Engineering Lead.
- Decision window: 4 business hours after second-day confirmation.
- Exact Intune action if rollback approved:
  - Freeze new v3.1 assignments (remove upcoming ring includes).
  - Reassign affected group(s) to v3.0 Required.
  - Optionally set v3.1 Uninstall for affected groups if crashes are severe and reproducible.

3. Business-critical failure immediate rollback trigger
- Trigger condition: any confirmed defect that blocks Finance from completing payment release workflow in production (for example, users cannot open or submit payment batch in FinBridge Connect after update).
- Decision owner: Incident Commander (Major Incident bridge) with Finance Application Owner sign-off.
- Decision window: Immediate, maximum 60 minutes from validation.
- Exact Intune rollback action:
  - Immediately remove Finance Required assignment from v3.1 (`FINBRIDGE-R2-FINANCE-USERS` or Ring 0 group if used).
  - Assign Finance group to v3.0 as Required.
  - If needed for rapid restoration, also set v3.1 Uninstall as Required for Finance group.

4. 4 GB RAM at-risk segment isolation trigger
- Trigger condition: Failure rate > 8.0% on devices in `FINBRIDGE-R1-4GB-DEVICES` or equivalent at-risk hardware group during any 24-hour period.
- Decision owner: Endpoint Engineering Lead.
- Decision window: 2 hours.
- Exact Intune action:
  - Isolate low-RAM devices by excluding hardware group from v3.1 Required assignments.
  - Continue rollout for non-at-risk groups if global triggers are not breached.
  - Keep or restore v3.0 Required assignment for isolated low-RAM group until mitigation is validated.

## 4. FINANCE DEADLINE RESOLUTION

1. Option A - Compress Ring 1 to place Finance in Ring 2 by end of week 1
- Minimum safe pilot duration:
  - 48 hours absolute minimum, with at least one business day plus one overnight cycle.
- Risk introduced:
  - Lower chance of catching delayed failures (policy retry loops, post-reboot issues, and day-2 performance degradation).
- Compensating control:
  - Increase Ring 1 canary size for 4 GB RAM devices to at least 75 and run 2 forced sync checkpoints (at +8h and +24h), with a mandatory go/no-go checkpoint before Finance inclusion.

2. Option B - Finance as separate priority Ring 0 before main pilot
- Ring 0 structure:
  - Size: 75 Finance power users across key payment and reconciliation workflows.
  - Duration: 2 days monitoring.
  - Assignment: Required to `FINBRIDGE-R0-FINANCE-CANARY` only.
- Ring 0 advance conditions:
  - >= 98.0% Installed within 24 hours.
  - <= 1.0% Failed in Intune.
  - Zero Sev1 business workflow failures.
  - Ticket rate <= 2 per 100 users per 24 hours.
- Ring 0 rollback plan:
  - If any Sev1 workflow failure or >3.0% install failures in first 24 hours, remove Ring 0 from v3.1 and assign Ring 0 to v3.0 Required within 60 minutes.

3. Recommendation (single clear choice)
- Recommend Option B (Finance Ring 0) as the primary plan.
- Justification:
  - Meets Finance end-of-week-1 deadline with controlled exposure.
  - Tests the most business-critical workflows first, where failure impact is highest.
  - Preserves statistical value of Ring 1 for technical validation across mixed hardware.
  - Reduces enterprise risk versus compressing pilot observation time too aggressively.

Execution timeline summary (3 weeks)
- Days 1-2: Ring 0 Finance canary (75 users).
- Days 3-5: Ring 1 pilot (250 users including low-RAM canaries).
- Days 6-7: Complete Finance expansion to full 500 users (remaining 425 after Ring 0), then hold 24-hour validation checkpoint.
- Days 8-9: Continue Ring 2 with non-Finance early adopters to reach 2,250 total users.
- Days 10-21: Ring 3 broad rollout (remaining 7,500 users in controlled waves).
