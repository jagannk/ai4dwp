Summary (one line)
Company app installation from Company Portal fails with error 0x87D1041C.

Impact (who/how many/ business urgency)
Who: Single user (to-verify).
How many: One user reported (to-verify).
Business urgency: to-verify (app unavailable; impact depends on criticality of app to user's role).

known facts
- Installation attempted via Company Portal (Intune).
- Installation fails with error code 0x87D1041C.
- App name/vendor/version not specified (to-verify).
- Device platform (Windows, iOS, Android, macOS—to-verify).

Missing information to gather
- Exact app name, publisher, and version being deployed (to-verify).
- Is error 0x87D1041C consistent, or intermittent (to-verify).
- Has this app been successfully installed on other devices (to-verify).
- Device OS version and available storage space (to-verify).
- Whether app was previously installed and is now failing on reinstall (to-verify).
- Intune app deployment policy settings and target group membership (to-verify).
- Whether user has local admin rights required for app installation (to-verify).
- Company Portal app version and recent updates (to-verify).
- Intune device sync status and last successful check-in (to-verify).

likely catagory
Intune mobile device management (MDM) app deployment failure (to-verify).

Suggest first diagnostic step
Diagnose Intune deployment blockers: verify device is enrolled and synced with Intune (check device compliance status in Intune portal); confirm user is in correct target group for app assignment; check Intune app deployment logs on device; verify device meets app prerequisites (OS version, storage, RAM); attempt manual app installation from Company Portal after forced sync; escalate to app publisher/LOB team if app-specific blocker identified (to-verify).
