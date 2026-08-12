# Windows 11 Intune Compliance Policy Mapping (DWP)

Date: 2026-08-10  
Scope: Translate the provided security baseline into Microsoft Intune Windows compliance policy settings.

## Recommended Policy Target
- Platform: Windows 10 and later (covers Windows 11 in most tenants)
- Profile type: Compliance policy
- Policy name example: `WIN11-Compliance-Baseline-N-1`

## UI Path (Current Best-Known)
- Create policy: Intune admin center > Devices > Compliance policies > Policies > Create policy
- Platform/profile: Windows 10 and later > Compliance policy
- Configure settings: Compliance settings (categories such as Device Health, System Security, Device Properties)
- Grace period: Actions for noncompliance

Potential UI drift note:
- Microsoft has periodically renamed menu items (for example, Devices vs Endpoint security landing paths, and category grouping in settings). If labels differ in your tenant, use the policy search bar for the exact setting names listed below.

## Requirement-to-Setting Translation

| Requirement | Setting name (Intune) | Value | Effect (plain English) | False-positive risk | Recommendation |
|---|---|---|---|---|---|
| 1. BitLocker must be enabled on OS drive | **Require BitLocker** | **Require** | Device is noncompliant unless OS drive encryption is enabled. | Encryption may be active but state not yet synced to Intune after provisioning or key escrow delay. | Keep as Require. Allow enrollment/provisioning to complete before compliance evaluation in Autopilot waves. |
| 2. Secure Boot must be enabled | **Require Secure Boot to be enabled on the device** (often shown as **Secure Boot**) | **Require** | Blocks devices booting without UEFI Secure Boot protection. | Legacy BIOS mode devices, VM templates without Secure Boot, firmware state not refreshed after BIOS updates. | Keep as Require. Validate hardware/VM baseline supports UEFI + Secure Boot before assignment. |
| 3. Minimum OS build N-1 (22621.2861) | **Minimum OS version** | **10.0.22621.2861** | Devices below this build are noncompliant. | Version string mismatch (full version formatting), delayed Windows Update reporting, ring lag after patch Tuesday. | Use phased assignments and review update ring SLAs so managed devices can reach required build within grace period. |
| 4. Defender real-time protection must be on | **Real-time protection** | **Require** | Device is noncompliant if Microsoft Defender real-time scanning is off. | Third-party AV coexistence, temporary Defender passive mode during migration, stale sensor/reporting state. | If third-party AV is intentional, validate security model first; otherwise keep Require and enforce Defender active mode. |
| 5. Firewall enabled for all profiles | **Firewall** | **Require** | Requires Windows Firewall enabled; noncompliant if firewall is off. | Local troubleshooting scripts or GPO conflict may disable one profile briefly; reporting lag after policy flip. | Keep as Require. Align Intune endpoint security firewall profiles to avoid policy conflicts. |
| 6. PIN or password must be configured | **Required password type** + **Minimum password length** + (optionally) **Password complexity** related settings | Example: `Alphanumeric` (or `Device default` if WHfB PIN is primary), minimum length `6` or higher | Enforces a local sign-in secret (password/PIN policy baseline) to reduce unauthorized access risk. | Windows Hello for Business PIN deployments can be flagged if password-type requirements are too strict or mismatched with sign-in strategy. | Tune to your auth model: if WHfB PIN is standard, set values compatible with WHfB and test pilot devices before broad rollout. |
| 7. Device must not be jailbroken/rooted | **No direct Windows 11 "jailbroken/rooted" compliance toggle**. Closest equivalent: **Microsoft Defender for Endpoint device risk score** (via connector) | Set risk threshold (for example: `Low` or `Medium`) in compliance policy if MDE integrated | Uses endpoint risk telemetry to block potentially compromised devices. | If MDE connector is not configured or sensor health is degraded, compliant devices can appear unknown/noncompliant. | Implement MDE integration and use risk-based compliance as Windows equivalent control. Document that mobile jailbreak/root check is not a direct Windows control. |

## Grace Period Configuration (7 Days)

Set this in policy actions, not per individual setting:

1. In the compliance policy, open **Actions for noncompliance**.
2. Configure **Mark device noncompliant** to **Schedule = 7 days**.
3. (Optional) Add notifications (email or custom actions) at day 0/day 3/day7 to reduce helpdesk volume.

Result:
- Any failed requirement enters a 7-day remediation window before the device is marked noncompliant.

## Settings Most Likely to Have UI Label/Path Changes

The following have seen naming or placement changes across Intune UI revisions and should be verified in-tenant:
- Real-time protection
- Defender Antivirus-related settings
- Password requirement fields for Windows Hello for Business scenarios
- MDE risk score compliance setting labels

Operational tip:
- Use the setting search/filter inside the policy editor with the exact names from this document.

## Implementation Notes

- Assign first to a pilot Azure AD group (IT + test devices).
- Monitor **Device compliance** and **Per-setting status** for 1-2 patch cycles.
- Only then expand to production groups.

## Post-Assignment Validation Steps (All Devices Scope)

Use this immediately after a device sync to confirm the policy is evaluating correctly.

### 1) Where to See One Device's Status for This Specific Policy

Path A (device-centric, fastest for a known test device):
1. Intune admin center > **Devices** > **All devices**.
2. Select the test device.
3. Open **Device compliance** (or **Compliance**) in the device pane.
4. Open **Policies** (or **Compliance policies**) and select policy **WIN11-Compliance-Baseline-N-1**.
5. Review:
	- Overall state for this policy (Compliant / Not compliant / In grace period)
	- Per-setting results (for example, BitLocker, Secure Boot, Firewall)
	- Last check-in time and last evaluation time

Path B (policy-centric, fastest for broad impact checks):
1. Intune admin center > **Devices** > **Compliance policies** > **Policies**.
2. Open policy **WIN11-Compliance-Baseline-N-1**.
3. Open **Device status**.
4. Search/select the test device.
5. Open device details to view per-setting status for that policy.

### 2) What Each State Means for Conditional Access

- **Compliant**: Device satisfies the policy (or has remediated before deadline). For CA rules requiring a compliant device, access is allowed.
- **In grace period**: Device failed one or more settings, but the configured remediation window (7 days in this baseline) has not expired. With standard Intune noncompliance actions, this state is intended to provide remediation time before the device is marked noncompliant; validate behavior with a pilot CA test because tenant policy combinations can vary.
- **Not compliant**: Device failed policy requirements and is outside grace (or marked directly, depending on action settings). CA policies requiring compliant devices will block access or require alternative controls depending on policy design.

Operational note:
- Validate **In grace period** behavior with one pilot account/device pair before full rollout so CA impact is confirmed in your tenant.

### 3) BitLocker False-Positive Triage (Enabled Locally but Shown Non-compliant)

Most common causes and fastest checks:

1. Compliance telemetry lag after encryption/provisioning
	- Why it happens: OS volume is encrypted, but Intune has not yet received refreshed encryption state.
	- Fastest check:
	  - On device (admin PowerShell): `Get-BitLockerVolume -MountPoint C: | Select-Object MountPoint, VolumeStatus, ProtectionStatus, EncryptionPercentage`
	  - In Intune device record: compare local state vs **Last check-in** timestamp.
	- Quick action: trigger **Sync** from Company Portal or Intune device page, then recheck after next check-in.

2. Protection present but not fully enforced (protection off/suspended)
	- Why it happens: Drive can remain encrypted while protection is suspended/off, which can fail compliance logic.
	- Fastest check:
	  - `manage-bde -status C:`
	  - Confirm **Protection Status: Protection On** and not suspended.
	- Quick action: resume/enable protectors, then sync device.

3. Key escrow or policy timing mismatch during Autopilot/first-run
	- Why it happens: BitLocker starts, but key escrow/compliance signal arrives late, especially right after enrollment.
	- Fastest check:
	  - In Entra/Intune, confirm recovery key object exists for the device.
	  - Check device timeline for recent enrollment/profile assignment and whether compliance ran before escrow completed.
	- Quick action: allow enrollment flow to complete, force sync, then re-evaluate before escalating.

### First Validation Checklist (First 24 Hours)

1. In policy **Device status**, track count/percent by state every few hours.
2. In **Per-setting status**, confirm BitLocker is not the dominant failure reason.
3. Sample at least 20 flagged devices across rings/sites and compare local `Get-BitLockerVolume` output with Intune status.
4. Watch helpdesk/CA sign-in impact for spikes tied to this policy.
5. If false positives exceed your threshold (for example >2-3% of recently synced devices), pause broad expansion and keep assignments at pilot scope until telemetry stabilizes.
