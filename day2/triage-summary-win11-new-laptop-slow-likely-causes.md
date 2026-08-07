1. Post-build background provisioning still running (Intune policies, app installs, Defender indexing/scans, OneDrive known-folder sync).  
Likely reason: Newly deployed devices are busiest in the first 24-48 hours and can saturate CPU/disk.  
Single fastest check: Open Task Manager and confirm CPU/disk are being consumed by `Microsoft Intune Management Extension`, `MsMpEng.exe`, `SearchIndexer.exe`, or `OneDrive.exe`.

2. Windows Update and driver update backlog after first sign-in.  
Likely reason: Fresh Win11 builds often pull cumulative updates, firmware, and drivers immediately after deployment.  
Single fastest check: Check Settings > Windows Update for active downloads/installs or pending restart.

3. Endpoint security stack running first-time full scans/compliance checks.  
Likely reason: Managed security baselines and EDR onboarding can trigger heavy initial scanning and policy evaluation.  
Single fastest check: In Task Manager, verify sustained resource use by `MsMpEng.exe` or EDR agent process during the slowdown window.

4. OneDrive profile/data rehydration from migration baseline.  
Likely reason: User profile folders and files are syncing back to the new laptop, causing disk and network pressure.  
Single fastest check: Check OneDrive status icon for “Syncing” and large remaining file count/data volume.

5. Power plan/firmware state limiting performance (Battery saver, OEM quiet mode, outdated BIOS/chipset).  
Likely reason: New devices may default to conservative power settings or ship with pre-update firmware impacting responsiveness.  
Single fastest check: Confirm Windows power mode is not set to Best power efficiency/Battery saver while plugged in.
