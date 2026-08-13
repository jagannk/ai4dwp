# Azure Virtual Desktop Provisioning Record (Day 9)

Date: 2026-08-13
Environment: Windows + Azure CLI (authenticated)

## Scope
This document captures the exact provisioning workflow executed for Azure Virtual Desktop in subscription `1c7550b6-10d6-4884-a991-f7a6fd15840a`, resource group `dwp-lab-rg`, region `centralus`, and user access for `p14@zippyops.in`.

## Target Build
- Host pool: `POOL-FIN-01` (Pooled)
- Load balancing: `BreadthFirst`
- Max sessions per host: `5`
- Application group: `DAG-POOL-FIN-01` (Desktop)
- Workspace: `FinBridge-Workspace`
- Session host VM: `finsh01`
- OS image: `MicrosoftWindowsDesktop:windows-11:win11-25h2-avd:latest`
- VM size: `Standard_B2ms`
- Security: Trusted Launch (`Secure Boot` + `vTPM` enabled)
- Join model: Microsoft Entra ID sign-in path (`AADLoginForWindows` extension)

## 1) Permission and Context Validation
Commands executed:

```powershell
az account show --query "{subscription:id,user:user.name,tenant:tenantId}" --output table
az role assignment list --assignee traininguser16@zippyops.in --scope /subscriptions/1c7550b6-10d6-4884-a991-f7a6fd15840a --include-inherited --query "[].{role:roleDefinitionName,scope:scope}" --output table
```

Observed result:
- Active operator had `Owner` on subscription scope.

## 2) Clean Recreate of Environment
Commands executed:

```powershell
az group delete --name dwp-lab-rg --yes --no-wait
az group wait --name dwp-lab-rg --deleted
az group create --name dwp-lab-rg --location centralus
```

## 3) Network Provisioning
Command executed:

```powershell
az network vnet create --resource-group dwp-lab-rg --name dwp-avd-vnet --location centralus --address-prefixes 10.40.0.0/16 --subnet-name sessionhosts --subnet-prefixes 10.40.1.0/24
```

## 4) AVD Control Plane Provisioning
Commands executed:

```powershell
az desktopvirtualization hostpool create --resource-group dwp-lab-rg --name POOL-FIN-01 --location centralus --host-pool-type Pooled --load-balancer-type BreadthFirst --preferred-app-group-type Desktop --max-session-limit 5 --friendly-name POOL-FIN-01

$hpId = az desktopvirtualization hostpool show --resource-group dwp-lab-rg --name POOL-FIN-01 --query id -o tsv
az desktopvirtualization applicationgroup create --resource-group dwp-lab-rg --name DAG-POOL-FIN-01 --location centralus --application-group-type Desktop --host-pool-arm-path $hpId --friendly-name DAG-POOL-FIN-01

$appId = az desktopvirtualization applicationgroup show --resource-group dwp-lab-rg --name DAG-POOL-FIN-01 --query id -o tsv
az desktopvirtualization workspace create --resource-group dwp-lab-rg --name FinBridge-Workspace --location centralus --friendly-name FinBridge-Workspace --application-group-references $appId
```

## 5) Session Host VM Provisioning
Command executed:

```powershell
$adminUser='localavdadmin'
$adminPass='C0mpl3x!LabHost#2026'
az vm create --resource-group dwp-lab-rg --name finsh01 --location centralus --size Standard_B2ms --image MicrosoftWindowsDesktop:windows-11:win11-25h2-avd:latest --vnet-name dwp-avd-vnet --subnet sessionhosts --public-ip-sku Standard --nsg-rule RDP --security-type TrustedLaunch --enable-secure-boot true --enable-vtpm true --admin-username $adminUser --admin-password $adminPass --license-type Windows_Client
```

Verification command used:

```powershell
az vm show --resource-group dwp-lab-rg --name finsh01 -d --query "{name:name,powerState:powerState,privateIps:privateIps,publicIps:publicIps,securityType:securityProfile.securityType,secureBoot:securityProfile.uefiSettings.secureBootEnabled,vTPM:securityProfile.uefiSettings.vTpmEnabled}" --output table
```

## 6) Enable Entra Sign-in Extension
Command executed:

```powershell
az vm extension set --resource-group dwp-lab-rg --vm-name finsh01 --name AADLoginForWindows --publisher Microsoft.Azure.ActiveDirectory
```

## 7) Session Host Registration Workflow Used
Because direct token passing can be malformed by quoting/parameter handling, the run used a safer sequence:

1. Install AVD agent + bootloader without token.
2. Generate fresh host pool registration token.
3. Base64-wrap token and apply it through generated script content.
4. Restart `RdAgent` and `RDAgentBootLoader`.
5. Verify token length/prefix in registry and verify session host object in host pool.

Representative commands used:

```powershell
az vm run-command invoke --resource-group dwp-lab-rg --name finsh01 --command-id RunPowerShellScript --scripts @day9/install-avd-agent-no-token.ps1

$exp=(Get-Date).ToUniversalTime().AddHours(24).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')
az desktopvirtualization hostpool update --resource-group dwp-lab-rg --name POOL-FIN-01 --registration-info expiration-time=$exp registration-token-operation=Update
$token=az desktopvirtualization hostpool retrieve-registration-token --resource-group dwp-lab-rg --name POOL-FIN-01 --query token -o tsv
$tokenB64=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($token))

$template=Get-Content -Raw day9/set-rdinfra-token-template.ps1
$script=$template.Replace('__TOKEN_B64__',$tokenB64)
Set-Content -Path day9/set-rdinfra-token-generated.ps1 -Value $script -Encoding ascii

az vm run-command invoke --resource-group dwp-lab-rg --name finsh01 --command-id RunPowerShellScript --scripts @day9/set-rdinfra-token-generated.ps1
```

## 8) User Access Role Assignments (p14@zippyops.in)
Commands executed:

```powershell
$vmScope='/subscriptions/1c7550b6-10d6-4884-a991-f7a6fd15840a/resourceGroups/dwp-lab-rg/providers/Microsoft.Compute/virtualMachines/finsh01'
$dagScope='/subscriptions/1c7550b6-10d6-4884-a991-f7a6fd15840a/resourceGroups/dwp-lab-rg/providers/Microsoft.DesktopVirtualization/applicationGroups/DAG-POOL-FIN-01'

az role assignment create --assignee p14@zippyops.in --role "Virtual Machine Administrator Login" --scope $vmScope
az role assignment create --assignee p14@zippyops.in --role "Desktop Virtualization User" --scope $dagScope
```

## 9) Host Pool RDP Property for Entra-Joined Session Host
Command executed:

```powershell
az desktopvirtualization hostpool update --resource-group dwp-lab-rg --name POOL-FIN-01 --custom-rdp-property "enablerdsaadauth:i:1;targetisaadjoined:i:1;"
```

## 10) Final Session Host Status Verification
Command used:

```powershell
$api=az provider show --namespace Microsoft.DesktopVirtualization --query "resourceTypes[?resourceType=='hostpools/sessionhosts'].apiVersions[0]" -o tsv
$uri="https://management.azure.com/subscriptions/1c7550b6-10d6-4884-a991-f7a6fd15840a/resourceGroups/dwp-lab-rg/providers/Microsoft.DesktopVirtualization/hostPools/POOL-FIN-01/sessionHosts?api-version=$api"
az rest --method get --uri $uri --output json
```

Observed status at completion:
- Session host object present: `POOL-FIN-01/finsh01`
- Agent version: `1.0.15008.300`
- `allowNewSession`: `true`
- `status`: `Unavailable`
- `AADJoinedHealthCheck`: `Succeeded`
- `DomainJoinedCheck`: `Failed`
- `DomainTrustCheck`: `Failed`

## Scripts Created and Moved to Day 9
- `day9/check-rdinfra-token.ps1`
- `day9/install-avd-agent.ps1`
- `day9/install-avd-agent-no-token.ps1`
- `day9/set-rdinfra-token.ps1`
- `day9/set-rdinfra-token-template.ps1`
- `day9/set-rdinfra-token-generated.ps1`

## Notes
- The registration-token handling required defensive scripting because direct inline/parameter passing can corrupt the token string.
- This log is an execution record of what was actually run, including remediation steps.
