Title: Known Error Record — AVD Session Immediate Disconnect on Logon (DWM / igdumd64.dll)
Knowledge Base ID: KE-AVD-001
Source Incident: POOL-FIN-01 / SHFIN-01-A — 2024-03-15
Status: Verified

---

**Symptom**
Users connecting to an AVD session host are disconnected immediately after logon — within seconds — with no desktop rendered. The session appears to connect successfully then drops before any applications or the desktop loads.

**Cause**
An image update introduced Intel GPU driver `igdumd64.dll` version `31.0.101.4146` to the session host. When a user session is established, `dwm.exe` (Desktop Window Manager) attempts to initialise using this driver, triggers an access violation (exception `0xc0000005`), and terminates. The DWM crash ends the session immediately for every user on the affected host.

**Scope**
All users connecting to any session host that received the image containing `igdumd64.dll` v31.0.101.4146 are affected — the fault is host-wide, not user-specific. Session hosts running the pre-update image (e.g., build `10.0.22621.2861-build-20240313`) are unaffected and operate normally.

**Workaround**
Set the affected session host(s) to Drain mode in Azure Portal (AVD > Host pools > [pool] > Session hosts) to stop new connections being routed to them. Redirect affected users to a session host running the known-good image. No user data is lost; sessions simply need to be re-established on the working host.

**Permanent Fix**
Redeploy affected session hosts from the last known-good image (`10.0.22621.2861-build-20240313`). Pin the Intel GPU driver to the validated version in the image template to prevent the faulty driver being reintroduced by a future update. Add a canary post-build validation gate to the image pipeline that runs a synthetic logon and checks for Event ID 1000 (`dwm.exe`) before any image is promoted to production pools.

**How to Spot It**
In Event Viewer > Application log on the session host, look for **Event ID 1000** (Application Error) with faulting application `dwm.exe` and faulting module `igdumd64.dll` — exception code `0xc0000005` confirms an access violation in the GPU driver. This is immediately followed by **Event ID 9009** (DWM exited with code `0x40010004`) and **Event ID 40** (RDS session disconnect, reason code 0). The pattern repeats for every user logon on the affected host; the unaffected reference host shows **Event ID 9011** (DWM started successfully) with no Event 1000 entries.
