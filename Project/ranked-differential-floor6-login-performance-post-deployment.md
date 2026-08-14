# Ranked Differential - Floor 6 Login/Performance Issue (Post Friday Deployment)

## Scenario
A new app was deployed to Floor 6 on Friday afternoon. By Monday morning, users on that exact floor reported login delays and poor performance. The deployment timing and location match make the app change a leading hypothesis, but competing causes must be tested quickly.

## Ranked Most-Likely Causes (with fastest check)

### 1) New app startup component causing logon stall (highest likelihood)
Why likely:
- Tight temporal link: change Friday, impact Monday after full user return.
- Scope link: issue concentrated on the same floor that received deployment.
- Symptom fit: logon delay often maps to heavy startup tasks, shell extensions, profile init hooks, or first-run cache/index jobs.

Fastest check:
- On one affected endpoint, compare boot/logon phases in Event Viewer and startup impact (Task Manager Startup + Sysinternals Autoruns) against a nearby unaffected endpoint.
- Temporarily disable app auto-start component or launch guard on one pilot user, then test next sign-in.

Confirm deployment as cause if:
- Logon duration drops materially after disabling the app startup component.
- ETW/WPR trace shows app process or child process dominating CPU/disk during logon window.
- Affected devices share the same app build and policy ring; unaffected devices do not.

Rule out deployment as cause if:
- Disabling/removing startup hook has no measurable logon improvement across multiple tests.
- Process/trace data shows bottleneck elsewhere (for example, GPO, network auth, profile container mount).

### 2) App-triggered identity/auth overhead (AAD token plugin, WAM, conditional access loop)
Why likely:
- New app may request tokens or add authentication plugins at sign-in.
- Monday surge can expose hidden latency in token issuance or repeated prompts/retries.

Fastest check:
- Review Entra ID sign-in logs for affected users during failure window: token latency, repeated interactive prompts, CA policy evaluation delays, unusual app ID correlation.
- Check Windows AAD/Operational and User Device Registration logs for retry/error bursts immediately after credential entry.

Confirm deployment as cause if:
- Sign-in delays correlate to the new app's service principal/client ID.
- Token/CA latency spikes only for users/devices with the new app installed.

Rule out deployment as cause if:
- Same auth delays appear for users without the app, or logs point to tenant-wide identity degradation.

### 3) App content/cache path on network share causing floor-specific I/O contention
Why likely:
- If app cache, templates, or plug-in content sits on DFS/file share, Monday concurrent access can create queueing.
- Presents as "slow login then slow desktop" due to blocked reads at user init.

Fastest check:
- During impacted period, check SMB server counters and share latency; on clients, capture ProcMon/WPR for file I/O wait on app-related paths.
- Test one user with cache redirected to local disk or offline mode.

Confirm deployment as cause if:
- High wait time aligns to app-specific UNC paths and disappears when using local cache.
- Floor 6 subnet/users show disproportionate share queue depth tied to app files.

Rule out deployment as cause if:
- No app-path latency appears; storage/network waits center on unrelated paths.

### 4) Application compatibility conflict with existing endpoint controls (AV/EDR/DLP)
Why likely:
- New binaries can trigger real-time scanning or policy inspection at logon.
- Monday first-full-day usage amplifies scan storms and script inspection.

Fastest check:
- Correlate EDR/AV telemetry for scan time spikes on app binaries/process tree at login time.
- Run controlled test with approved temporary exclusion for app folder/hash on one device.

Confirm deployment as cause if:
- Login and responsiveness improve immediately with scoped exclusion and regress when removed.
- Security telemetry shows repeated scans/quarantine checks on new app artifacts.

Rule out deployment as cause if:
- No scan overhead around the app; exclusions do not change timing.

### 5) Coincidental floor infrastructure issue (DHCP/DNS/switch/Wi-Fi) revealed Monday
Why possible but lower:
- Same-floor clustering can also be explained by network segment faults.
- However, tight coupling to a fresh app rollout lowers this below deployment-linked causes.

Fastest check:
- Compare Floor 6 network health (DHCP scope, DNS response times, switch port errors, WLAN retries) to other floors during the same window.
- Run sign-in/performance test from a Floor 6 device on an alternate known-good network path.

Confirm deployment as cause (indirectly) if:
- Network is healthy and issue persists only where app is present.

Rule out deployment as primary cause if:
- Clear network fault affects all workloads (not just new app users), and remediation resolves symptoms without app changes.

## Evidence Matrix: Confirm vs Rule Out Deployment

### Evidence that confirms deployment is causal
- Strong correlation by build/ring: affected users have new app version; unaffected users do not.
- Reproducibility: install app on a clean comparable device reproduces delay; uninstall/rollback removes delay.
- Temporal precision: performance regression begins immediately after install or first post-deploy login.
- Trace-level attribution: CPU, disk, auth, or I/O waits map to app process, app plugin, or app content path.

### Evidence that rules out deployment as causal
- No difference between devices with and without the app under same floor conditions.
- Rollback/uninstall does not improve login time or desktop responsiveness.
- Alternate root cause has direct proof (for example, DNS timeout spikes, broken GPO, profile service errors) and fixes restore service.
- Tenant-wide platform issue observed across other floors and unaffected app cohorts.

## Practical 60-Minute Triage Sequence
1. Pick 2 affected + 1 unaffected Floor 6 endpoints and capture sign-in timing plus running process snapshots.
2. Disable app startup component on 1 affected endpoint and retest login once.
3. Pull Entra sign-in and endpoint security telemetry for the same 30-minute window.
4. If signal points to app, execute controlled rollback for a pilot group and compare median login time.
5. If signal does not point to app, pivot to floor network/GPO/profile diagnostics with deployment as secondary hypothesis.

## Initial Engineering Position
Based on timing, scope, and symptom pattern, the most likely primary cause is startup or authentication overhead introduced by the Friday app deployment. The fastest proof is an A/B test (disable or rollback on a small pilot) combined with a short trace showing whether logon critical path time is consumed by the new app stack.
