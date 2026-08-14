# L1 Self-Service: Floor 6 Login/Performance Recurrence
Version: 1.0
Date: 2026-08-14
Source runbook: runbook-floor6-section4-ring-pull-rollback-v1.md

If Floor 6 sign-in or desktop performance slows again, this is most likely linked to a software deployment ring and is being handled by engineering.

What to do now:
1. Restart once, then sign in once.
2. If still slow, capture the device name (for example, FL6-LT-001) and the time.
3. Contact the service desk and provide: device name, time, and a short description ("slow login" or "slow after sign-in").
4. Do not keep retrying multiple times; repeated retries can delay diagnosis.

What engineering will do:
- Remove affected devices from the problematic deployment ring.
- Apply rollback targeting.
- Trigger management sync and verify improvement.

Reassurance:
Your account and files remain safe. We will share updates at key checkpoints while stabilization work is in progress.
