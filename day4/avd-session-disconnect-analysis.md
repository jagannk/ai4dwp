Title: AVD Finance Session Host - Disconnect on Logon - Analysis and Hypothesis
Date: 10/08/2026
Incident Window: 2024-03-15 07:00 - 07:30
Affected Host: SHFIN-01-A (POOL-FIN-01)
Unaffected Reference Host: SHFIN-02-A (POOL-FIN-02)
Status: Draft

---

## Incident Summary

Finance AVD users are immediately disconnected after logging on to session host SHFIN-01-A. The session connects then drops within seconds with no user-facing desktop rendered. Multiple users are affected. The host was rebooted during an overnight image update prior to the incident window.

---

## Ranked Hypotheses (Initial Scope - Pre-Evidence)

1. **Image update introduced a faulty GPU/display driver** — overnight image update rebooted the host; a driver version change may cause DWM to crash on session start.
2. **DWM (Desktop Window Manager) instability on the session host** — a DWM crash prevents any session from rendering, causing immediate disconnect for every connecting user.
3. **User profile corruption for specific accounts** — a corrupted roaming or local profile could block desktop load, but would typically affect individual users only.
4. **Insufficient host resources (CPU/RAM) post-update** — resource exhaustion could prevent sessions from initialising, though unlikely to produce instant drops.
5. **Network or RDP listener issue** — a connectivity fault could cause session drops, but this would typically prevent logon from completing at all.

---

## Evidence Assessment

### Hypothesis 1 — Image update introduced a faulty GPU/display driver
**Verdict: SUPPORTED**

- **Event 1 @ 07:02:14 (Kernel-General)** — Records system boot time as 02:03:11, confirming SHFIN-01-A was rebooted overnight as part of an image update. This is the change event that preceded all failures.
- **Event 1000 @ 07:02:16 (Application Error)** — `dwm.exe` crashes with faulting module `igdumd64.dll` version `31.0.101.4146`. This is the Intel GPU driver. The crash occurs 6 seconds after the first user logon, consistent with a session-triggered driver initialisation failure introduced by the new image.
- **Event 1000 @ 07:02:46 and 07:08:24** — Same faulting module and exception code (`0xc0000005`) repeat for every subsequent session, confirming the driver fault is persistent and not a one-time glitch.
- **SHFIN-02-A (unaffected, image build-20240313 pre-update)** — Event 9011 @ 07:01:46 confirms DWM started successfully and no Event 1000 entries appear in the window. The only structural difference between the two hosts is the image version, directly implicating the overnight update on SHFIN-01-A.

---

### Hypothesis 2 — DWM instability on the session host
**Verdict: SUPPORTED as symptom, not independent root cause**

- **Event 9009 @ 07:02:18** — `The Desktop Window Manager has exited with code (0x40010004)` immediately after the first Event 1000 crash. DWM is confirmed to have terminated.
- **Event 40 @ 07:02:17** — Session disconnect for mlopez occurs one second after Event 1000 and one second before Event 9009, confirming the disconnect is a direct consequence of DWM going down.
- **Event 9009 @ 07:03:01** — DWM crashes again after the first reconnect attempt, showing DWM cannot recover across sessions.
- This hypothesis is supported in that DWM instability is the proximate mechanism of disconnection, but it is not independent — it is caused by the faulty driver identified in Hypothesis 1. Cannot be separated from H1 as a standalone root cause.

---

### Hypothesis 3 — User profile corruption for specific accounts
**Verdict: CONTRADICTED**

- **Event 1000 @ 07:02:16 and 07:02:46** — The crash is in `dwm.exe` at the driver layer (`igdumd64.dll`), which loads before any user profile content is processed. Profile data is not involved at this point in the session stack.
- **Event 1000 @ 07:08:24** — A second distinct user, `FINBRIDGE\akapoor`, triggers an identical crash with the same module and exception code. If profile corruption were the cause, a different user's profile would not reproduce the exact same fault in the same module at the same memory offset.
- **SHFIN-02-A** — User `bwalker` on the unaffected host logs on without issue. No profile-layer errors appear, and DWM starts cleanly. This shows users are not universally corrupt — the fault is host-specific.

---

### Hypothesis 4 — Insufficient host resources (CPU/RAM) post-update
**Verdict: NEUTRAL / NOT SUPPORTED**

- No Event IDs in the provided evidence indicate CPU throttling, low memory conditions, paging file exhaustion, or disk pressure (e.g., no Event 2004, 153, or System errors relating to resources).
- **Event 1000 @ 07:02:16** — The crash occurs only 6 seconds after session logon at 07:02:10, and the faulting module is a GPU driver, not a memory allocation or process scheduling failure. Resource exhaustion crashes typically present differently (hangs, slow load, pagefile events) rather than an access violation (`0xc0000005`) in a specific driver module.
- Cannot fully confirm or contradict without performance counter data, but the specific nature of the crash points away from resource constraints.

---

### Hypothesis 5 — Network or RDP listener issue
**Verdict: CONTRADICTED**

- **Event 21 @ 07:02:10** — `Remote Desktop Services: Session logon succeeded` confirms that the RDP connection, authentication, and session establishment all completed successfully before any problem occurred. The network path and RDP listener are functioning.
- **Event 21 @ 07:02:44 and 07:03:10** — mlopez successfully reconnects twice, again confirming the RDP listener and network are not the failure point.
- **Event 21 @ 07:08:22** — akapoor also connects successfully. Session establishment is consistent and reliable; the failure only occurs after connection.
- **Event 40** follows DWM crash events, not network timeout codes. Reason code 0 on the disconnect indicates a local session termination, not a network-side drop.

---

## Surviving Hypothesis

**Hypothesis 1 — Image update introduced a faulty Intel GPU driver (`igdumd64.dll`)**

H2 (DWM instability) is eliminated as an independent root cause because it only occurs as a direct consequence of H1. H3, H4, and H5 are contradicted by the evidence. H1 is the sole surviving hypothesis.

> The overnight image update applied to SHFIN-01-A introduced Intel GPU driver `igdumd64.dll` version `31.0.101.4146`. When a user session is established, the Desktop Window Manager (`dwm.exe`) attempts to initialise using this driver, triggers an access violation (exception `0xc0000005`), and terminates immediately. The crash ends the session within seconds of logon. The fault is host-wide, reproducible across all users on the updated pool, and absent on SHFIN-02-A which is running the pre-update image.

---

## Resolution Steps

### Immediate — Protect users now

1. In Azure Portal, go to **Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts**.
   Set SHFIN-01-A (and all other session hosts in POOL-FIN-01 that received the overnight update) to **Drain mode** to block new incoming connections.
   Expected result: No new Finance users are routed to the affected host. Existing broken sessions are not replaced with new ones.

2. Notify the Finance team (via Teams or email) that POOL-FIN-01 is temporarily unavailable and direct them to connect via **POOL-FIN-02** for the duration of the incident.
   Expected result: Finance users can resume work on the unaffected pool with no data loss.

3. Update the ServiceNow incident ticket with confirmed root cause, affected hosts, and the drain action taken. Set ticket priority to reflect business impact.
   Expected result: Incident record is accurate and visible to all resolver groups.

### Short-term — Restore POOL-FIN-01 to service

4. In Azure Portal, go to **Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts**.
   Remove or redeploy the affected session hosts using the last known-good image version: `10.0.22621.2861-build-20240313` (the version confirmed working on SHFIN-02-A).
   Expected result: New session host instances boot with the pre-update image and `igdumd64.dll` version is not `31.0.101.4146`.

5. On one redeployed host, verify the fix before re-enabling the full pool:
   - Open Event Viewer > Application log and confirm **Event 9011** (DWM started successfully) is present after first logon.
   - Confirm **no Event 1000** with faulting module `igdumd64.dll` in the Application log.
   - Ask one Finance user to log on and confirm the session persists beyond 60 seconds with a rendered desktop.
   Expected result: Session is stable, no disconnect occurs, desktop loads normally.

6. Once validated, take the redeployed hosts out of Drain mode in Azure Portal.
   Expected result: POOL-FIN-01 begins accepting Finance user sessions normally.

### Long-term — Prevent recurrence

7. Locate the image build pipeline that produced the overnight update and identify how `igdumd64.dll` version `31.0.101.4146` was introduced (Windows Update, driver injection, or third-party package). Pin the Intel GPU driver to the previously validated version in the image template.
   Expected result: Future image builds do not include the faulty driver version.

8. Add a post-build validation step to the image pipeline that deploys the image to a canary session host, runs a synthetic logon, and checks for Event 1000 (Application Error) in the Application log before promoting to production pools.
   Expected result: A faulty driver in a new image is caught in staging before Finance users are affected.

9. Create an Azure Monitor alert rule for **Event ID 1000** with faulting application `dwm.exe` on all AVD session hosts. Set severity to Critical and route to the AVD operations queue.
   Add **Event ID 9009** to the same ruleset.
   Expected result: Any future DWM crash on a session host triggers an alert within minutes, before users report disconnects.

10. Raise a **Problem ticket** linked to this incident to track the driver pinning, pipeline fix, and monitoring improvements. Assign to the AVD image engineering team with a target resolution date.
    Expected result: Recurrence prevention actions are tracked to completion and not lost after incident closure.
