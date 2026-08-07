Title: L2/L3 KB - Resolution Fast Fix
Version: v 1.0
Date: 07/08/2026
Status: Draft

## Resolution
Use this section only after the detection KB confirms Application Event 1000 with `igdumd64.dll`, Event 9009 on the affected host, and Event 9011 on `POOL-FIN-02` as the healthy control.

1. In Azure Portal, go to `Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-01`, set `Allow new sessions` to `No`, and click `Save`.
Expected result: `POOL-FIN-01` enters drain mode and no new users are sent to the affected host.

Azure CLI:
```bash
az desktopvirtualization session-host update --resource-group <rg-name> --host-pool-name FIN01 --name POOL-FIN-01 --allow-new-session false
```

2. In Azure Portal, stay at `Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-01`, open the `Sessions` view, select each active session, and click `Log off`.
Expected result: Active user sessions on `POOL-FIN-01` drop to `0`.

Azure CLI:
```bash
az desktopvirtualization user-session list --resource-group <rg-name> --host-pool-name FIN01 --session-host-name POOL-FIN-01 -o table
az desktopvirtualization user-session delete --resource-group <rg-name> --host-pool-name FIN01 --session-host-name POOL-FIN-01 --id <session-id>
```

3. In Azure Portal, go to `Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-01 > Virtual machine > Overview`, then click `Restart`.
Expected result: The VM restarts and returns to `Running` state.

Azure CLI:
```bash
az vm restart --resource-group <rg-name> --name POOL-FIN-01
```

4. In Azure Portal, go to `Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-01 > Virtual machine > Help > Properties`, then record the `Image` value.
Expected result: The current image reference for `POOL-FIN-01` is visible.

Azure CLI:
```bash
az vm show --resource-group <rg-name> --name POOL-FIN-01 --query "storageProfile.imageReference" -o json
```

5. In Azure Portal, go to `Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-02 > Virtual machine > Help > Properties`, then record the `Image` value.
Expected result: The healthy control image reference for `POOL-FIN-02` is visible.

Azure CLI:
```bash
az vm show --resource-group <rg-name> --name POOL-FIN-02 --query "storageProfile.imageReference" -o json
```

6. Compare the `Image` value for `POOL-FIN-01` against `POOL-FIN-02`.
Expected result: The image references match exactly, or you have confirmed an image drift condition.

7. If the image references match, go to `Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-01` and set `Allow new sessions` to `Yes`, then ask one test user to sign in.
Expected result: The host accepts one fresh session and the user reaches desktop without the crash pattern returning.

Azure CLI:
```bash
az desktopvirtualization session-host update --resource-group <rg-name> --host-pool-name FIN01 --name POOL-FIN-01 --allow-new-session true
```

8. If the image references do not match, leave `Allow new sessions` set to `No`, keep users on the healthy host, and raise an image-remediation change for `POOL-FIN-01`.
Expected result: Service is restored by routing users away from the affected host while image correction is controlled.

## Verification
1. In Azure Portal, go to `Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-01`, and confirm `Status` is `Available`.
Success looks like: The host is online and can accept connections when enabled.

Azure CLI:
```bash
az desktopvirtualization session-host show --resource-group <rg-name> --host-pool-name FIN01 --name POOL-FIN-01 --query "{name:name,status:status,allowNewSession:allowNewSession}" -o table
```

2. In Azure Portal, go to `Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-01 > Sessions`.
Success looks like: After re-enable, exactly one test session opens successfully and does not disconnect immediately.

Azure CLI:
```bash
az desktopvirtualization user-session list --resource-group <rg-name> --host-pool-name FIN01 --session-host-name POOL-FIN-01 -o table
```

3. In Azure Portal, go to `Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-01 > Virtual machine > Run command > RunPowerShellScript`, then run a query for Application Event `1000` and Event `9009` in the last 15 minutes.
Success looks like: No new Event `1000` with `igdumd64.dll` and no new Event `9009` appear after restart and test sign-in.

Azure CLI:
```bash
az vm run-command invoke --resource-group <rg-name> --name POOL-FIN-01 --command-id RunPowerShellScript --scripts "Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000,9009; StartTime=(Get-Date).AddMinutes(-15)} | Select-Object TimeCreated,Id,Message"
```

4. In Azure Portal, go to `Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-02 > Virtual machine > Help > Properties`, compare `Image` with `POOL-FIN-01` again.
Success looks like: `POOL-FIN-01` matches `POOL-FIN-02`, or the host remains drained pending formal image correction.

Azure CLI:
```bash
az vm show --resource-group <rg-name> --name POOL-FIN-01 --query "storageProfile.imageReference" -o json
az vm show --resource-group <rg-name> --name POOL-FIN-02 --query "storageProfile.imageReference" -o json
```

## Rollback
Use rollback if restart or re-enable causes immediate user failure again.

1. In Azure Portal, go to `Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-01`, set `Allow new sessions` to `No`, and click `Save`.
Immediate result: New users stop landing on the affected host.

Azure CLI:
```bash
az desktopvirtualization session-host update --resource-group <rg-name> --host-pool-name FIN01 --name POOL-FIN-01 --allow-new-session false
```

2. In Azure Portal, go to `Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-01 > Sessions`, select active sessions, and click `Log off`.
Immediate result: Active user impact is removed from the unstable host.

Azure CLI:
```bash
az desktopvirtualization user-session list --resource-group <rg-name> --host-pool-name FIN01 --session-host-name POOL-FIN-01 -o table
az desktopvirtualization user-session delete --resource-group <rg-name> --host-pool-name FIN01 --session-host-name POOL-FIN-01 --id <session-id>
```

3. In Azure Portal, go to `Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-02`, confirm `Allow new sessions` is `Yes`.
Immediate result: Healthy control host stays available for user routing.

Azure CLI:
```bash
az desktopvirtualization session-host show --resource-group <rg-name> --host-pool-name FIN01 --name POOL-FIN-02 --query "{name:name,status:status,allowNewSession:allowNewSession}" -o table
```

4. In Azure Portal, go to `Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-01 > Virtual machine > Help > Properties`, capture the `Image` value, then compare it against `POOL-FIN-02 > Virtual machine > Help > Properties > Image`.
Immediate result: You confirm whether image drift is the rollback trigger for formal rebuild.

Azure CLI:
```bash
az vm show --resource-group <rg-name> --name POOL-FIN-01 --query "storageProfile.imageReference" -o json
az vm show --resource-group <rg-name> --name POOL-FIN-02 --query "storageProfile.imageReference" -o json
```

5. If image drift is confirmed, leave `POOL-FIN-01` drained and open a rebuild change using the same image reference as `POOL-FIN-02`.
Immediate result: Users stay on healthy capacity while permanent repair is controlled.
