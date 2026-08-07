Title: L2/L3 KB - Detection Fast Check
Version: v 1.0
Date: 07/08/2026
Status: Draft

## Detection
Use this section to confirm the issue in under 3 minutes before taking any action.

1. Open Event Viewer on the affected machine and go to `Event Viewer > Windows Logs > Application`.
Expected result: You are in the exact `Application` log and can see application crash and launch events.

2. In the `Application` log, click `Filter Current Log...` and enter `1000,9009,9011` in `Includes/Excludes Event IDs`, then click `OK`.
Expected result: The view shows only Event `1000`, Event `9009`, and Event `9011`.

3. In the filtered `Application` log, sort by `Date and Time` descending and open the latest Event `1000` during the incident window.
Expected result: The event details window opens for the newest application fault event.

4. In Event `1000`, check the `General` tab and confirm the `Faulting module name` is `igdumd64.dll`.
Expected result: The field explicitly shows `Faulting module name: igdumd64.dll`.

5. In the same `Application` log, locate Event `9009` entries in the same time window as Event `1000`.
Expected result: Event `9009` appears in the same incident period, confirming the companion failure signature.

6. On the unaffected control machine `POOL-FIN-02`, open `Event Viewer > Windows Logs > Application` and filter for Event `9011`.
Expected result: Event `9011` is present on `POOL-FIN-02`, establishing the healthy baseline control.

7. Compare the affected machine against `POOL-FIN-02`.
Expected result: The affected machine shows Event `1000` with `igdumd64.dll` and Event `9009`, while `POOL-FIN-02` shows Event `9011` as the unaffected control state.

8. Run the following PowerShell command on the affected machine to extract the required events quickly:

```powershell
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000,9009; StartTime=(Get-Date).AddHours(-4)} |
Select-Object TimeCreated, Id, MachineName, ProviderName, LevelDisplayName, Message |
Format-List
```

Expected result: Output shows recent Application log Event `1000` and Event `9009` entries for the affected machine.

9. Run the following PowerShell command on `POOL-FIN-02` to confirm the healthy baseline event:

```powershell
Get-WinEvent -ComputerName 'POOL-FIN-02' -FilterHashtable @{LogName='Application'; Id=9011; StartTime=(Get-Date).AddHours(-4)} |
Select-Object TimeCreated, Id, MachineName, ProviderName, LevelDisplayName, Message |
Format-List
```

Expected result: Output shows Application log Event `9011` on `POOL-FIN-02` as the unaffected control.

10. Confirm this is the issue only if all three checks are true.
Expected result: You have an exact match when the affected machine has Event `1000` with `igdumd64.dll`, the affected machine also has Event `9009`, and `POOL-FIN-02` shows Event `9011` as the healthy comparison baseline.
