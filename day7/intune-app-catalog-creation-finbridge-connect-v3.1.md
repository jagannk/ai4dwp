# Intune App Catalog Creation Guide (Worked Example: FinBridge Connect v3.1)

Purpose: Add a Windows application to the Intune app catalog so phased rollout can begin safely.

Scope: This guide is written for DWP engineers with no prior Intune app-deployment experience.

Important: Intune UI labels and menu positions can vary by tenant version, feature flighting, and portal updates. At every navigation step below, verify labels in your live tenant and follow the equivalent path if wording differs.

## 1. Add The App In Intune

1. Sign in to the Intune admin center at `https://intune.microsoft.com` with an account that has app management permissions.
2. Navigate to Apps > Windows > Add.
   - Label-variation warning: Some tenants show Apps > All apps > Add, or place Windows app choices inside a platform picker.
   - Action: Verify the live label path in your tenant before proceeding.
3. In App type, choose the correct option for your package model:
   - For `.intunewin` package: select Windows app (Win32).
   - For Microsoft Store-delivered app: select Microsoft Store app (new).
   - For URL shortcut deployment: select Web link.
4. Click Select (or Next) to open the app creation wizard.
   - Label-variation warning: Button text can be Select, Create, or Next depending on UI version.

Worked example selection for this guide:
- App type: Windows app (Win32)
- Source package: `FinBridge Connect v3.1 (.intunewin)`

## 2. Fill Required Fields For A Windows LOB/Win32 App

Note: In many Intune tenants, `.intunewin` is exposed as "Windows app (Win32)" rather than "LOB app." Use the option that accepts `.intunewin` files.

### 2.1 App Information

1. Upload the `.intunewin` package file.
2. Provide required metadata:
   - Name: `FinBridge Connect`
   - Description: `Finance desktop connectivity client for FinBridge workflows.`
   - Publisher: `FinBridge`
   - Version: `3.1`
3. Add optional fields if your tenant enforces or benefits from them (owner, notes, category, logo).
4. Click Next.

Label-variation warning:
- The section may be called App information, Information, or Properties.

### 2.2 Program

1. Set install command:
   - `FinBridgeConnect_Setup.exe /silent`
2. Set uninstall command:
   - `FinBridgeConnect_Setup.exe /uninstall /silent`
3. Set install behavior/context:
   - Recommended default for enterprise app deployment: System context.
   - Use User context only if the app explicitly requires per-user install scope.
4. Keep restart behavior aligned to package behavior (for silent enterprise deployments, generally suppress forced restarts unless vendor requires).
5. Click Next.

Label-variation warning:
- The section can appear as Program, Install and uninstall, or Command line.

### 2.3 Requirements

1. Set Operating system architecture based on package compatibility:
   - Typical setting: 64-bit only for modern Win11 app fleets.
   - If 32-bit supported and required, configure accordingly.
2. Set minimum operating system:
   - For this environment, set to Windows 11 minimum version aligned with your corporate baseline.
3. Review hardware risk:
   - 5% of devices have 4 GB RAM and may struggle with v3.1.
   - Action: Do not block catalog creation, but ensure pilot includes representative low-RAM endpoints to validate performance before broad assignment.
4. Click Next.

Label-variation warning:
- Requirements may include additional fields (disk space, memory, processor) in some app types or tenant experiences.

### 2.4 Detection Rules

Purpose: Detection tells Intune how to decide if install succeeded.

1. Choose detection rule type: Registry.
2. Configure rule for worked example:
   - Hive: `HKEY_LOCAL_MACHINE`
   - Key path: `SOFTWARE\FinBridge\Connect`
   - Value name: `Version`
   - Detection method: String comparison equals
   - Expected value: `3.1`
3. Save and continue.

Other supported detection methods to know:
- MSI product code
- File or folder exists/value

Label-variation warning:
- The wizard may split detection into Rule format and Detection method, or show combined fields.

### 2.5 Return Codes

Purpose: Return codes map installer exit codes to success/retry/failure in Intune reporting.

1. Review default return codes pre-populated by Intune.
2. Confirm or set standard mappings (common baseline):
   - `0` = Success
   - `3010` = Soft reboot required
   - `1641` = Hard reboot initiated
   - Non-mapped non-zero codes = Failure (unless vendor documentation states otherwise)
3. Add vendor-specific success codes if FinBridge documentation defines additional non-zero success outcomes.
4. Click Next.

Label-variation warning:
- Some tenants expose return code type choices as Success, Soft reboot, Hard reboot, Retry.

## 3. Assignment Basics

### 3.1 Assignment Types

1. Required:
   - Intune enforces install automatically on targeted users/devices.
2. Available for enrolled devices:
   - App is optional; users can install from Company Portal.
3. Uninstall:
   - Intune removes the app from targeted users/devices.

Label-variation warning:
- Wording may appear as Required, Available, and Uninstall, or under separate include/exclude assignment panels.

### 3.2 Pilot-First Assignment Strategy (Do Not Target All 10,000 Immediately)

1. Create/identify a small test group first (for example, IT pilot + a subset of Finance).
2. Assign FinBridge Connect v3.1 as Required to that pilot group.
3. Validate install success, app launch behavior, and performance (especially on 4 GB RAM devices).
4. Expand to Finance priority group (500 users) after pilot passes, to meet end-of-week-1 need.
5. Expand in phases to remaining fleet over the 3-week deadline.

Why this is mandatory:
- Reduces blast radius.
- Protects critical Finance timeline.
- Detects performance issues early on lower-spec hardware.
- Preserves rollback path to v3.0 if needed.

## 4. Verification Steps

### 4.1 Confirm App Is In Catalog

1. Go to Apps > All apps.
2. Search for `FinBridge Connect`.
3. Open the app and verify:
   - Type is Win32/LOB-equivalent entry.
   - Version is 3.1.
   - Commands and detection rule match the intended configuration.

Label-variation warning:
- Some tenants separate platform filters (Windows) and app lists differently.

### 4.2 Check Install Status On A Test Device

1. From the app blade, open Monitor > Device install status (or User install status depending assignment target).
2. Locate pilot test device/user entries.
3. Confirm status transitions after policy sync.
4. On endpoint, force sync if needed:
   - Company Portal sync, or
   - Settings > Accounts > Access work or school > connected account > Info > Sync.

Label-variation warning:
- Monitor tabs and status blades are commonly renamed or relocated.

### 4.3 Interpret Common Statuses

1. Installed:
   - Detection rule matched expected version (for this app: registry Version = 3.1).
2. Failed:
   - Installer returned failure code, command line failed, or detection never matched after install attempt.
3. Not applicable:
   - Device does not meet requirements or assignment conditions (for example OS/architecture mismatch).

Action guidance:
- For Failed: review return code, Intune Management Extension logs, and command syntax.
- For Not applicable: validate requirement rules and targeting.

## 5. Minimal Pre-Rollout Checklist (Before Phase Expansion)

1. App record exists and metadata is correct.
2. Install and uninstall commands validated on pilot devices.
3. Detection rule confirms exactly version 3.1.
4. Return codes reviewed against vendor installer behavior.
5. Pilot results are stable across both standard and low-spec (4 GB RAM) devices.
6. Rollback plan confirmed: v3.0 available and assignment rollback steps documented.

## 6. Worked Example Summary (Copy-Ready Values)

- App name: FinBridge Connect
- Version: 3.1
- Package type: `.intunewin` (Windows app Win32 / LOB-equivalent workflow)
- Install command: `FinBridgeConnect_Setup.exe /silent`
- Uninstall command: `FinBridgeConnect_Setup.exe /uninstall /silent`
- Detection type: Registry
- Detection rule: `HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1`
- Initial assignment recommendation: Required to pilot group only, then phased expansion
- Rollback option: Re-target v3.0 from Intune app catalog if blocking issues appear

End of guide.
