# Root Cause Analysis: FinBridge VDI Pool-02 Session Launch Failure

**RCA Reference:** RCA-2026-0813-VDI-P02  
**Date of Incident:** 2026-08-13  
**Date of RCA:** 2026-08-13  
**Severity:** High — 22 users unable to access VDI workloads  
**Status:** Root Cause Confirmed — Remediation Defined  
**Prepared by:** DWP Analyst  

---

## 1. Executive Summary

On 2026-08-13, 22 of 30 users on `FinBridge-VDI-Pool-02` were unable to launch Citrix VDI sessions. The Citrix Session Broker returned error 1030 (`No machines available in the desktop group`). Investigation confirmed that the `Citrix Broker Service` on Delivery Controller `dc-vdi-02.finbridge.local` had stopped at approximately 23:40 the previous day, following Windows Update activity at 00:15. With port 80 closed, all Pool-02 VDA registration attempts failed. Pool-01, served by a separate healthy controller (`dc-vdi-01`), was unaffected. The outage was total for Pool-02 because no secondary Delivery Controller was configured as a fallback for that pool.

---

## 2. Incident Timeline

| Time | Event |
|---|---|
| **Yesterday 23:40** | `Citrix Broker Service` last recorded as running on `dc-vdi-02` |
| **Today 00:15** | Windows Update installed on `dc-vdi-02`; reboot-required flag set; host not rebooted |
| **Today 06:15:22** | `VDI-P02-014` attempts registration — `connection refused` on `dc-vdi-02:80` |
| **Today 06:16:01** | `VDI-P02-017` attempts registration — `connection refused` on `dc-vdi-02:80` |
| **Today 08:58:03** | User `jsmith` requests session launch on Pool-02 |
| **Today 08:58:04** | Broker queries available machines in Pool-02 |
| **Today 08:58:34** | Broker timeout after 30,000 ms — no registered machines respond |
| **Today 08:58:34** | Session launch **FAILED** — Error 1030: `No machines available in the desktop group` |
| **Today (investigation)** | 22 of 25 Pool-02 machines confirmed unregistered; `CitrixBrokerService` confirmed STOPPED on dc-vdi-02 |

---

## 3. Supporting Evidence

### 3.1 Session Broker Log
```
[08:58:03] Session launch requested: user jsmith, Pool-02
[08:58:04] Broker: Querying available machines in Pool-02
[08:58:34] Broker: Timeout waiting for machine registration response (30000ms exceeded)
[08:58:34] Session launch FAILED: error 1030 'No machines available in the desktop group'
```

### 3.2 Machine Catalog Registration Status

| Pool | Provisioned | Registered | Unregistered | Maintenance Mode |
|---|---|---|---|---|
| Pool-02 | 25 | **3** | **22** | 0 |
| Pool-01 | 20 | 19 | 1 | 0 |

### 3.3 Unregistered VDA Detail (Pool-02 Sample)

| Machine | Last Registration Attempt | Error Detail |
|---|---|---|
| VDI-P02-014 | 06:15:22 | `Unable to contact Delivery Controller — dc-vdi-02.finbridge.local:80 — connection refused` |
| VDI-P02-017 | 06:16:01 | `Unable to contact Delivery Controller — dc-vdi-02.finbridge.local:80 — connection refused` |

**Significance:** `Connection refused` (not timeout, not DNS failure) confirms the port is actively closed — consistent with the service being stopped, not the host being unreachable.

### 3.4 Delivery Controller Health

| Controller | Broker Service | Last Running | Update Activity |
|---|---|---|---|
| `dc-vdi-02` (Pool-02) | **STOPPED** | Yesterday 23:40 | Windows Update at 00:15 today; reboot-required flag set; host NOT rebooted |
| `dc-vdi-01` (Pool-01) | **RUNNING** | 14 days continuous | No update activity noted |

### 3.5 Isolation Evidence
- `FinBridge-VDI-Pool-01` (same site, different controller) is unaffected with 19/20 machines registered
- Fault is isolated to the controller, not the VDA agents, not the network, not StoreFront

---

## 4. Root Cause Statement

> **The `Citrix Broker Service` on `dc-vdi-02.finbridge.local` stopped at approximately 23:40 on 2026-08-12, during or immediately after Windows Update pre-processing activity. The update completed at 00:15 on 2026-08-13 and set a reboot-required flag, but the host was not rebooted. The stopped service left TCP port 80 closed. All 22 Pool-02 VDA machines that exclusively rely on `dc-vdi-02` for registration received `connection refused` errors and could not register. With only 3 of 25 machines registered, the Citrix Broker had no available machines to assign, producing error 1030 for all 22 affected users at session launch time. The impact was total because Pool-02 VDAs had no secondary Delivery Controller configured for failover.**

---

## 5. Five Whys Analysis

| Why | Answer |
|---|---|
| **Why** were users unable to launch VDI sessions? | The Citrix Broker returned error 1030 — no machines were available in Pool-02 |
| **Why** were no machines available? | 22 of 25 Pool-02 machines were unregistered with the Delivery Controller |
| **Why** were the machines unregistered? | VDAs could not contact `dc-vdi-02.finbridge.local` on port 80 — all received `connection refused` |
| **Why** was port 80 on dc-vdi-02 refusing connections? | The `Citrix Broker Service` was stopped on dc-vdi-02 — the service that listens on that port |
| **Why** was the Citrix Broker Service stopped? | Windows Update ran on dc-vdi-02 at 00:15 and either stopped the service as part of update processing, or a dependency was disrupted; the host was not rebooted to restore state, and there was no monitoring to detect the stopped service |

**Contributing factor (Why was the impact total rather than partial?):**  
Pool-02 VDAs had only a single Delivery Controller (`dc-vdi-02`) in their `ListOfDDCs` configuration — no failover controller was assigned. When that single controller became unavailable, 100% of machines in the pool lost registration.

---

## 6. Remediation Steps

### 6.1 Immediate Resolution (in order)

| Step | Action | Command / Detail |
|---|---|---|
| 1 | Confirm service state on dc-vdi-02 | `Get-Service 'CitrixBrokerService' -ComputerName dc-vdi-02` |
| 2 | Confirm port 80 is refused | `Test-NetConnection -ComputerName dc-vdi-02.finbridge.local -Port 80` |
| 3 | Attempt to start the service | `Start-Service 'CitrixBrokerService' -ComputerName dc-vdi-02` |
| 4 | If start fails — check event log for dependency error | `Get-EventLog -LogName System -Source 'Service Control Manager' -Newest 20` on dc-vdi-02 |
| 5 | If reboot required — raise emergency change and reboot dc-vdi-02 | Notify users; coordinate with change management; `Restart-Computer -ComputerName dc-vdi-02 -Force` |
| 6 | Verify service running | `Get-Service 'CitrixBrokerService' -ComputerName dc-vdi-02` — expect: `Running` |
| 7 | Verify port 80 responding | `Test-NetConnection -ComputerName dc-vdi-02.finbridge.local -Port 80` — expect: `TcpTestSucceeded = True` |
| 8 | Allow 5–10 minutes for VDA re-registration cycle | VDAs retry on a timer — no manual action needed |
| 9 | Confirm Pool-02 registration recovery | `Get-BrokerMachine -DesktopGroupName 'FinBridge-VDI-Pool-02' \| Group-Object RegistrationState` — target: ≥ 22 Registered |
| 10 | Test a live session launch | Launch as jsmith or a test account via Citrix Workspace — expect: session launches without error 1030 |
| 11 | Communicate resolution | Service desk closes tickets; notify affected users |

### 6.2 Remediation PowerShell Reference

```powershell
# Step 1-2: Validate current state
Get-Service 'CitrixBrokerService' -ComputerName dc-vdi-02
Test-NetConnection -ComputerName dc-vdi-02.finbridge.local -Port 80

# Step 3: Start service
Start-Service 'CitrixBrokerService' -ComputerName dc-vdi-02

# Step 4: Check event log if start fails
Invoke-Command -ComputerName dc-vdi-02 -ScriptBlock {
    Get-EventLog -LogName System -Source 'Service Control Manager' -Newest 20 |
        Where-Object { $_.Message -like '*CitrixBroker*' }
}

# Step 5: Reboot if required
Restart-Computer -ComputerName dc-vdi-02 -Force

# Step 6-7: Post-action verification
Get-Service 'CitrixBrokerService' -ComputerName dc-vdi-02
Test-NetConnection -ComputerName dc-vdi-02.finbridge.local -Port 80

# Step 9: VDA registration check (requires Citrix Studio SDK)
Get-BrokerMachine -DesktopGroupName 'FinBridge-VDI-Pool-02' |
    Group-Object RegistrationState | Select-Object Name, Count
```

---

## 7. Verification Checks After Remediation

| Check | Expected Result | Fail Action |
|---|---|---|
| `CitrixBrokerService` state on dc-vdi-02 | `Running` | Review event log; escalate to Citrix team |
| TCP port 80 on dc-vdi-02 | `TcpTestSucceeded = True` | Check Windows Firewall; confirm service is actually bound to port |
| Pool-02 registered machine count | ≥ 22 Registered, ≤ 3 Unregistered | Check individual VDA event logs for persistent errors |
| Live session launch | Session launches — no error 1030 | Confirm StoreFront and broker are in sync; restart broker if needed |

---

## 8. Preventive Actions

| Priority | Action | Detail | Owner |
|---|---|---|---|
| **P1 — Immediate** | Add `dc-vdi-01` to Pool-02 VDA `ListOfDDCs` | Edit Group Policy or VDA config to include dc-vdi-01 as secondary controller for all Pool-02 machines — eliminates single point of failure | Desktop Engineering |
| **P1 — Immediate** | Create monitoring alert for `CitrixBrokerService` stopped | Alert within 2 minutes of service stopping on any Delivery Controller; route to on-call engineer | Monitoring Team |
| **P2 — Short term** | Enforce Windows Update policy on Delivery Controllers | Exclude DCs from auto-update/restart groups; require change-controlled patching; mandate immediate post-patch reboot in a maintenance window | Platform / Change Management |
| **P2 — Short term** | Daily reboot-pending detection check | Script to check `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending` on all DCs; alert if flag set with no reboot scheduled within 24 hours | Monitoring Team |
| **P3 — Medium term** | Review all VDI pools for single-controller dependency | Audit `ListOfDDCs` across all pools; ensure every pool has at least two controllers assigned | Desktop Engineering |

---

## 9. Lessons Learned

1. **Patch management must treat Delivery Controllers as critical infrastructure** — automatic update without immediate controlled reboot creates a silent failure window where services may stop and go undetected overnight.
2. **A stopped service producing `connection refused` vs. a network issue producing `timeout`** are diagnostically distinct — `connection refused` should immediately direct investigation to the service layer, not the network.
3. **Single-controller pool design is an architectural gap** — any pool with only one Delivery Controller in its `ListOfDDCs` has no tolerance for controller maintenance or failure; this must be treated as a risk item and remediated.
4. **Monitoring coverage on Delivery Controllers was insufficient** — the service was stopped from 23:40 yet not detected until users reported failures at 08:58, a gap of over 9 hours.

---

## 10. Approvals and Distribution

| Role | Name | Date |
|---|---|---|
| DWP Analyst (Author) | — | 2026-08-13 |
| Service Desk Manager | — | Pending |
| Platform / Desktop Engineering Lead | — | Pending |

---

*RCA Reference: RCA-2026-0813-VDI-P02 | Created: 2026-08-13*
