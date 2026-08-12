# DEX Signal – Startup Performance Drop: Probable Cause Analysis

**Source:** DEX scope facts — Finance-Win11 startup degradation  
**Config change applied:** 2026-08-04 at 02:00  
**Date analysed:** 2026-08-12  

---

## Analytical Basis

The timing of the degradation (immediate, overnight, first observed 2026-08-04) and the clean comparison group (IT-Win11 stable at 84–85 with no config change) together constitute strong evidence that the config change is the direct cause. All three hypotheses below are rooted in components of that change.

---

## Ranked Probable Causes

---

### Rank 1 — Compliance Logging Startup Script Running Synchronously

**Why it fits the evidence:**  
The config change explicitly added a startup script for compliance logging. If that script is configured to run synchronously — meaning Windows holds the login process and waits for the script to finish before presenting the usable desktop — it would produce exactly the kind of fixed, consistent delay seen here (+23.8 seconds, sustained across three days). The IT-Win11 group has no such script and shows zero degradation. The delay magnitude is consistent with a script that runs to completion rather than a random I/O spike.

**Fastest check to confirm or eliminate:**  
Open the Intune or Group Policy configuration for the deployed script. Check the execution setting:  
- In Intune: Scripts > the compliance logging script > check **"Run script in 64-bit PowerShell host"** and whether it is set to run in the **user context or system context at login**.  
- In GPO: Check whether the script is assigned under Computer Configuration > Windows Settings > Scripts > **Startup** (blocking) rather than as a background task.  
- On one affected device: open **Event Viewer > Applications and Services Logs > Microsoft > Windows > GroupPolicy** and look for script execution start/end timestamps bracketing the delay window.

---

### Rank 2 — Defender Scan Policy Triggering an I/O-Heavy Scan at Login

**Why it fits the evidence:**  
The config change also applied an additional Defender scan policy. If this policy schedules or triggers a scan at device startup or first login, it competes for disk I/O and CPU at exactly the moment the system is trying to load the user profile and desktop. This would degrade startup time for all 215 Finance devices simultaneously from 2026-08-04 onward. The IT-Win11 group was not in scope for this policy and remained unaffected.

**Fastest check to confirm or eliminate:**  
On an affected Finance-Win11 device, log out and log back in while **Task Manager is open on another account or via remote session**. Watch whether `MsMpEng.exe` (Defender) shows high CPU or disk usage during the login window. Alternatively, check **Event Viewer > Windows Defender > Operational** for scan-start events timestamped within seconds of login. If scans are firing at startup, the policy trigger setting (OnStartup / OnLogon) will be visible in the Intune Endpoint Security profile.

---

### Rank 3 — Compliance Logging Script Making a Slow or Failing Network Call

**Why it fits the evidence:**  
If the compliance logging script contacts a remote endpoint — such as a logging server, SIEM collector, or Active Directory service — and that connection is slow to establish or times out before falling back, the script would stall at login for a consistent duration matching the observed delay. This variant of Rank 1 is ranked separately because it implies a different fix path (network/firewall config rather than script execution mode). The comparison group again corroborates this: IT-Win11 devices have no such script and no delay.

**Fastest check to confirm or eliminate:**  
Review the compliance logging script source code for any remote calls (e.g., `Invoke-WebRequest`, `Test-NetConnection`, SIEM agent calls, UNC path writes). If remote calls exist, run the script manually on an affected device with network tracing active (`netsh trace start`) and measure how long the remote call takes. Also check whether the target endpoint is reachable from Finance devices and whether firewall rules were updated to permit the new traffic.

---

## Summary Table

| Rank | Probable Cause | Key Evidence Link | Fastest Check |
|---|---|---|---|
| 1 | Startup script running synchronously at login | Consistent fixed delay; script added by config change; comparison group unaffected | Check Intune/GPO script execution mode and Event Viewer GroupPolicy logs |
| 2 | Defender scan policy triggering I/O-heavy scan at login | Defender policy added by same change; disk/CPU contention at login | Watch MsMpEng.exe during login in Task Manager; check Defender Operational event log |
| 3 | Startup script making slow/failing network call | Script added by config change; consistent delay suggests timeout, not random I/O | Review script source for remote calls; trace network activity during login |

---

*End of analysis — scope facts file: dex-signal-startup-scope-facts.md*
