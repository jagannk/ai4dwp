# JAMF macOS Security Baseline — Design Team Fleet (25 Devices)

**Author:** DWP Engineer  
**Date:** 2026-08-13  
**Scope:** 25-device Design team macOS fleet  
**Purpose:** Translate security baseline requirements into JAMF configuration profile settings

---

> **Naming Caveat (read before deploying)**  
> JAMF Pro's UI payload names and label text change between versions. Every setting below reflects terminology current at the time of writing. Before deploying, verify each payload name and toggle label against your own JAMF Pro instance. Apply the same discipline used in the Intune labs on Day 6 — treat this document as a reference map, not a copy-paste source of truth.

---

## Requirement 1 — FileVault Disk Encryption Must Be Enabled

| Field | Detail |
|---|---|
| **Payload type** | **Disk Encryption** (FileVault) — found under *Computers › Configuration Profiles › + Add › Disk Encryption*. Also surfaced in the **Security & Privacy** payload on older JAMF versions. |
| **Value** | `Require FileVault 2` — set Encryption Mode to **Require for all users** |
| **Effect** | Forces full-volume encryption on the startup disk. Users are prompted to enable FileVault on next login if it is not already active; the device remains in a non-compliant state until encryption completes and JAMF receives the updated inventory. |
| **False-positive risk** | Encryption in progress (the volume is encrypting but not yet 100% complete); devices that have just been re-enrolled and have not yet submitted an updated inventory record; and M-series Macs where the secure enclave reports encryption differently — these can appear non-compliant briefly even when encryption is active. |

> ⚠️ **Verify label:** The dedicated *Disk Encryption* payload was introduced in JAMF Pro 10.x. Older instances may route this through *Security & Privacy*. Confirm which payload your instance exposes.

---

## Requirement 2 — Gatekeeper Must Be Enabled (Identified Developers Only)

| Field | Detail |
|---|---|
| **Payload type** | **Restrictions** (*Computers › Configuration Profiles › Restrictions*), under the **Applications** tab |
| **Value** | Set **Allow apps downloaded from** to **Mac App Store and identified developers** (maps to the `assessmentPolicy` key `GKE-2` or `allow-identified-developers` depending on JAMF version) |
| **Effect** | Prevents execution of unsigned or unnotarised binaries. Users cannot open apps that have not been signed by an Apple-identified developer certificate without explicitly bypassing Gatekeeper — enforcement via MDM removes the option to permanently disable it through System Settings. |
| **False-positive risk** | Legacy in-house tools compiled without a Developer ID, design applications distributed as direct downloads that predate Apple's notarisation requirement (introduced macOS 10.15), and disk images mounted from network shares. These will be blocked or flagged even when intentionally deployed. Maintain an allow-list for known business tools. |

> ⚠️ **Verify label:** The Restrictions payload Application tab label for Gatekeeper changed wording across macOS 12–15. Confirm the exact toggle text in your JAMF instance matches what you expect.

---

## Requirement 3 — Minimum macOS Version: Current Stable Minus One Point Release

| Field | Detail |
|---|---|
| **Payload type** | **macOS Monterey / Ventura / Sequoia — OS Update enforcement** via *Computers › Configuration Profiles › **Restrictions*** (Software Updates tab) **or** a dedicated **Software Update** payload; compliance checking is done via **Smart Groups** and/or **Compliance Reporter** |
| **Value** | Set the minimum allowed OS build/version to the current stable release minus one point version. As of the document date (August 2026) verify the current Apple stable release and subtract one point — e.g. if stable is 15.6, set minimum to **15.5**. Update this value each time Apple releases a new point version. |
| **Effect** | Devices running an OS version below the minimum are placed in a non-compliant Smart Group, enabling automated scoping of remediation policies (e.g. Self Service prompts, email notifications, or deferred forced-update deadlines via DDM/Software Update enforcement). |
| **False-positive risk** | Devices that received a JAMF inventory update before completing an OS upgrade, devices on an approved deferral (e.g. creative workloads being held back for app compatibility), and devices enrolled during a transition window immediately after Apple releases a new point version. Always allow a grace period window — typically 14–30 days — before enforcement actions trigger. |

> ⚠️ **Verify label:** Apple's Declarative Device Management (DDM) Software Update enforcement (available from macOS 14+) uses a different payload path than the legacy MDM Software Update payload. If your fleet includes mixed macOS 13/14+ devices, you may need both approaches. Verify which your JAMF version supports.

---

## Requirement 4 — Firewall Must Be Enabled

| Field | Detail |
|---|---|
| **Payload type** | **Security & Privacy** (*Computers › Configuration Profiles › Security & Privacy*), Firewall section |
| **Value** | `Enable Firewall` = **Enabled**; optionally also enable **Block all incoming connections** (evaluate per use case — see False-positive risk). Stealth mode can be enabled for additional hardening. |
| **Effect** | Enables the macOS application-layer firewall (not the packet filter). Incoming connections to unsigned applications are blocked. Users cannot disable the firewall through System Settings when managed via MDM. |
| **False-positive risk** | Screen sharing, AirDrop, AirPlay Receiver, and Remote Management are blocked unless explicitly allowed. Design team users frequently use local network collaboration tools (e.g. screen sharing to a second Mac, Bonjour-based asset sharing) — enabling **Block all incoming connections** will break these without per-application exceptions. Audit the team's workflow before applying the most restrictive setting. |

> ⚠️ **Verify label:** The **Security & Privacy** payload contains both the Firewall section and the Privacy settings. The exact sub-section label may read *Firewall* or *Application Firewall* depending on JAMF version.

---

## Requirement 5 — Login Password Required After Sleep or Screen Saver

| Field | Detail |
|---|---|
| **Payload type** | **Login Window** (*Computers › Configuration Profiles › Login Window*) **and/or** **Security & Privacy** payload (Screen Saver section) |
| **Value** | In **Security & Privacy**: set **Require password after sleep or screen saver begins** to **Immediately** (or the maximum acceptable delay — recommend **Immediately** for this baseline). In **Login Window**: ensure automatic login is disabled. |
| **Effect** | The screen locks as soon as the display sleeps or the screen saver activates. A password (or Touch ID if permitted) is required to resume the session. Prevents physical access to an unattended unlocked machine — relevant for an open-plan Design studio environment. |
| **False-positive risk** | Shared workstations or presentation Macs where users intentionally want the screen to stay unlocked during a presentation will be affected. Design team members running long renders or exports may find their screen locking mid-task — this is cosmetic only (the task continues) but can cause confusion. Communicate the policy change before deployment. |

> ⚠️ **Verify label:** Screen saver password settings have moved between **Security & Privacy** and a standalone **Screen Saver** payload across JAMF versions. Check both payload sections in your instance.

---

## Requirement 6 — Automatic Software Updates Must Be Enabled for Security Updates

| Field | Detail |
|---|---|
| **Payload type** | **Software Update** (*Computers › Configuration Profiles › Software Update*) — key: `AutomaticallyInstallAppUpdates`, `CriticalUpdateInstall`, `AutomaticCheckEnabled`, `AutomaticDownload` |
| **Value** | Enable the following keys: **Check for updates** = `true`; **Download newly available updates** = `true`; **Install security responses and system files** = `true` (this targets Rapid Security Responses); optionally **Install macOS updates** based on team policy. |
| **Effect** | Ensures security patches and Rapid Security Responses (RSRs) are downloaded and installed automatically without requiring user action or JAMF-triggered policies. Reduces the window of exposure to published CVEs, which is critical for internet-connected design workstations accessing external asset libraries. |
| **False-positive risk** | RSRs (Rapid Security Responses) can install silently and prompt a restart, which may interrupt long-running creative exports or active design sessions. Some RSRs have historically been recalled by Apple within 24–48 hours of release — devices that auto-installed a recalled RSR may show an unexpected build string in inventory until JAMF re-inventories. Consider a 24-hour deferral for non-critical update types while keeping security responses immediate. |

> ⚠️ **Verify label:** The **Software Update** payload key names differ between the legacy macOS MDM protocol and the newer DDM (Declarative Device Management) protocol available on macOS 14+. JAMF may present these under different payload names depending on your JAMF Pro version. Verify whether your instance uses the legacy or DDM-based update management.

---

## Deployment Notes for the Design Team Fleet

| Consideration | Recommendation |
|---|---|
| **Phased rollout** | Deploy to 2–3 pilot devices first; validate no creative tools are blocked by Gatekeeper or Firewall before fleet-wide push |
| **User communication** | Notify the Design team before deploying Req 5 (screen lock) and Req 6 (auto-updates with restarts) |
| **Smart Groups** | Create compliance Smart Groups for each requirement so non-compliant devices are visible in the JAMF dashboard without requiring manual checks |
| **Conflict checking** | If a user-level profile and a computer-level profile both manage the same key (e.g. screen saver timeout), the most restrictive value typically wins — audit for conflicts before deployment |
| **JAMF version** | Confirm your JAMF Pro version before deploying. Settings in this document were authored against JAMF Pro 11.x conventions. Payload availability and naming may differ on earlier versions. |

---

*Prepared as part of DWP IT Operations training — Day 9. Cross-reference JAMF documentation and your live instance before production deployment.*
