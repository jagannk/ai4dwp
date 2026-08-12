# Analysis and RCA: Adobe Acrobat Pro v23.6 Intune Install Failure (Return Code 1603)

## 1. Incident Summary

- Incident type: Intune Win32 app deployment failure
- Application: Adobe Acrobat Pro v23.6
- Package: AdobeAcrobatPro.intunewin
- Install context: SYSTEM
- Install command used: `msiexec /i AcrobatPro.msi /quiet`
- Primary failure signal: MSI return code 1603
- Detection outcome: Not detected
- Behavior: Initial failure followed by retry failure after 60 minutes

## 2. Evidence From Log

Observed sequence:

1. Install starts successfully under SYSTEM context.
2. Installer exits with code 1603 at first attempt.
3. Detection rule runs immediately after install:
   - Registry key checked: `HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0`
   - Result: value not found, detection not detected.
4. Intune marks deployment as Failed and schedules retry.
5. Retry executes the same install command and fails again with 1603.

Interpretation:
- The install process is not completing successfully.
- The detection rule is also likely mismatched for the target product, increasing false-negative risk even if install had partially succeeded.

## 3. Technical Analysis

### 3.1 Meaning of 1603

MSI error 1603 is a generic fatal install error. In enterprise deployments it commonly indicates one or more of the following:

- Incorrect install command parameters or missing required transforms/properties.
- Installation blocked by prerequisites or pending reboot.
- Attempting to install over conflicting existing product/version.
- Installer content path or permissions issue under SYSTEM context.
- Security tooling interference (AV/EDR) with MSI execution.

### 3.2 Detection Rule Mismatch (High Confidence)

The app being deployed is Adobe Acrobat Pro, but detection checks a Reader path:

- Configured check: `HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0`

This path aligns to Adobe Reader branding, not typically Acrobat Pro (which usually writes under Acrobat-specific product paths, depending on architecture and package build).

Impact of mismatch:
- Even if install succeeds, Intune may still evaluate as Not detected.
- This causes repeated reinstall attempts and recurring failures/noise.

### 3.3 Command/Package Validation Gap (Medium-High Confidence)

The command uses a direct MSI call:

- `msiexec /i AcrobatPro.msi /quiet`

Potential issues:
- MSI file name inside the intunewin may differ from `AcrobatPro.msi`.
- Vendor package may require additional properties (for example EULA acceptance, serial/licensing, or transform MST).
- Missing logging switch reduces diagnosability.

### 3.4 Retry Behavior

Because detection remains Not detected and command is unchanged, retries repeat the same failure path, resulting in no recovery.

## 4. Root Cause Assessment

Primary root cause:
- Deployment configuration defect: Detection rule targets Adobe Reader registry path instead of Acrobat Pro detection artifact.

Secondary/root contributing cause:
- Install command likely incomplete or not aligned with the packaged MSI deployment requirements, resulting in MSI 1603.

Why this is the most probable RCA:
- Direct evidence of detection pointing to Reader key while deploying Pro.
- Repeated 1603 on same command with no environmental change suggests deterministic packaging/command/config issue rather than transient endpoint condition.

## 5. Impact Assessment

- User impact: Targeted users do not receive functional Acrobat Pro installation.
- Platform impact: Device remains in failed state; Intune retries consume cycles and generate support tickets.
- Operational impact: SLA risk for application rollout and increased service desk load.

## 6. Corrective Actions (Immediate)

1. Pause broad assignment
- Stop or limit Required assignments to pilot/test group until remediation is validated.

2. Fix detection rule
- Replace Reader-based detection with Acrobat Pro-specific detection.
- Preferred detection order:
  1. MSI product code (most reliable if MSI deployment is used).
  2. Acrobat Pro executable/file version path.
  3. Acrobat Pro registry key/value path verified from a known-good manual install.

3. Fix install command and enable verbose logging
- Update command to include MSI logging for root-cause proof:
  - `msiexec /i "AcrobatPro.msi" /qn /norestart /L*v "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AcrobatPro_install.log"`
- Add required vendor properties/MST if documented by Adobe packaging standard.

4. Validate package content
- Confirm `AcrobatPro.msi` exists at package root expected by command.
- If nested path differs, update command accordingly.

5. Pre-check endpoint conditions on pilot devices
- Ensure no pending reboot.
- Confirm no conflicting Acrobat/Reader enterprise package blocks upgrade path.
- Validate SYSTEM execution permissions for temp/cache paths.

## 7. Preventive Actions (Long-Term)

1. Add pre-production checklist for every Win32 app
- Verify install command locally under SYSTEM.
- Verify uninstall command.
- Verify detection against real installed artifact.
- Validate return codes and restart behavior.

2. Require pilot gate before scale
- Minimum 24-48 hour pilot with success/failure thresholds before broad assignment.

3. Standardize detection strategy
- Prefer MSI product code when available.
- Use registry/file detection only when product code is unavailable.

4. Improve troubleshooting readiness
- Always include verbose MSI logging during pilot phase.
- Capture and archive Intune Management Extension logs for failed attempts.

## 8. Validation Plan After Fix

1. Redeploy to a 20-device pilot group.
2. Success criteria:
- >= 95% install success within first 4 hours.
- 0 repeated retry loops caused by false detection.
- Detection status shows Installed for successful endpoints.
3. Inspect at least 3 successful and 3 failed clients:
- Intune status
- IME logs
- MSI verbose logs
4. If criteria pass, expand in phased rings.

## 9. Executive RCA Statement

Adobe Acrobat Pro v23.6 deployment failed in Intune due to a configuration issue combining incorrect detection logic and a likely incomplete MSI deployment command. The detection rule references an Adobe Reader registry path, which is inconsistent with the Acrobat Pro target and causes Not detected outcomes. Concurrent MSI code 1603 across repeated attempts indicates a deterministic installation configuration problem (command/package prerequisites), not a transient device issue. Remediation requires correcting detection to Acrobat Pro artifacts, hardening the MSI command with required parameters and logging, then validating in pilot before broader rollout.
