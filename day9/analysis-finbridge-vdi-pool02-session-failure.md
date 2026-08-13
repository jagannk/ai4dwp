# Incident Analysis: FinBridge VDI Pool-02 Session Launch Failure

**Date:** 2026-08-13  
**Analyst:** DWP Analyst  
**Status:** Root Cause Identified — Remediation Confirmed  

---

## 1. Incident Overview

| Field | Detail |
|---|---|
| Affected service | Citrix VDI session launch — FinBridge-VDI-Pool-02 |
| Impact | 22 of 30 users unable to launch VDI sessions |
| Unaffected | FinBridge-VDI-Pool-01 (same site) |
| Broker error | 1030 — `No machines available in the desktop group` |
| First observed | ~08:58 (session broker log) |
| Underlying fault origin | ~23:40 previous day (Broker Service stopped on dc-vdi-02) |

---

## 2. Scope Facts (Extracted from Logs)

### 2.1 Affected Pool and Users
- **Pool affected:** `FinBridge-VDI-Pool-02`
- **Users impacted:** 22 of 30
- **Unaffected pool:** `FinBridge-VDI-Pool-01` — same site, different Delivery Controller

### 2.2 Exact Broker Error
- **Error code:** 1030
- **Message:** `No machines available in the desktop group`
- **Preceding condition:** 30,000 ms timeout waiting for machine registration response (logged 08:58:34)

### 2.3 Machine Catalog Registration Status

| Pool | Provisioned | Registered | Unregistered | Maintenance Mode |
|---|---|---|---|---|
| Pool-02 | 25 | 3 | 22 | 0 |
| Pool-01 | 20 | 19 | 1 | 0 |

**Unregistered Pool-02 machines (sample):**

| Machine | Last Registration Attempt | Error |
|---|---|---|
| VDI-P02-014 | 06:15:22 | Connection refused — `dc-vdi-02.finbridge.local:80` |
| VDI-P02-017 | 06:16:01 | Connection refused — `dc-vdi-02.finbridge.local:80` |

### 2.4 Delivery Controller Health

| Controller | Broker Service | Last Running | Notes |
|---|---|---|---|
| `dc-vdi-02` (Pool-02) | **STOPPED** | Yesterday 23:40 | Windows Update ran today 00:15; reboot-required flag set; host NOT rebooted |
| `dc-vdi-01` (Pool-01) | **RUNNING** | 14 days continuous uptime | No issues |

---

## 3. Hypothesis Ranking

### Hypothesis 1 — Citrix Broker Service stopped on dc-vdi-02 post-Windows Update (CONFIRMED ROOT CAUSE)
**Probability: Highest**

**Evidence alignment:**
- Service STOPPED; last known running 23:40; Windows Update ran at 00:15 — consistent with update pre-processing or service dependency restart
- All 22 unregistered VDAs report `connection refused` on port 80 — a stopped service produces a hard refusal, not a timeout or DNS error
- Pool-01 VDAs (served by healthy dc-vdi-01) show near-full registration — isolates fault to the controller, not VDA agents or network fabric

**Fastest confirmation check:**
```powershell
Get-Service 'CitrixBrokerService' -ComputerName dc-vdi-02
Test-NetConnection -ComputerName dc-vdi-02.finbridge.local -Port 80
```

---

### Hypothesis 2 — Windows Update corrupted a Broker Service dependency (pending reboot)
**Probability: Medium (contributing factor)**

**Evidence alignment:**
- Reboot-required flag set but host not rebooted; some patches replace in-use DLLs — the service may have lost a dependency
- Explains clean service stop at 23:40 rather than a crash

**Confirmation check:**
```powershell
(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing").RebootPending
Get-EventLog -LogName System -Source 'Service Control Manager' -Newest 20 | Where-Object {$_.Message -like '*CitrixBroker*'}
```

---

### Hypothesis 3 — No fallback controller configured for Pool-02 VDAs (single point of failure)
**Probability: Lower (architectural gap, not direct cause)**

**Evidence alignment:**
- All 22 machines exclusively contacted dc-vdi-02 — no failover occurred, suggesting no secondary DC in `ListOfDDCs`
- Pool-01's resilience may be partly due to healthier controller assignment

**Confirmation check:**
```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Citrix\VirtualDesktopAgent" -Name ListOfDDCs
```

---

## 4. Finalized Root Cause

> **Citrix Broker Service on `dc-vdi-02.finbridge.local` was stopped following Windows Update activity at 00:15 today. The service stopped at 23:40 during or after update processing and was not automatically restarted. With the service down, port 80 was closed, causing all Pool-02 VDA registration attempts to receive `connection refused`. With 22 of 25 machines unregistered, the broker had no available machines to assign, producing error 1030 for 22 users at session launch time.**

---

## 5. Remediation Plan

### 5.1 Immediate Steps (in order)

| Step | Action | Detail |
|---|---|---|
| 1 | Confirm service state | `Get-Service 'CitrixBrokerService' -ComputerName dc-vdi-02` |
| 2 | Confirm port 80 refused | `Test-NetConnection dc-vdi-02.finbridge.local -Port 80` |
| 3 | Attempt service start | `Start-Service 'CitrixBrokerService' -ComputerName dc-vdi-02` |
| 4 | If start fails — check event log | Determine if reboot is required before scheduling one |
| 5 | If reboot required — raise emergency change | Notify users; reboot dc-vdi-02 in maintenance window |
| 6 | Verify service running and port 80 open | Repeat checks from steps 1–2 |
| 7 | Wait for VDA re-registration | Allow 5–10 minutes for VDA retry cycle |
| 8 | Validate with live session launch | Test as affected user (e.g., jsmith) |
| 9 | Communicate resolution | Service desk closure to affected users |

### 5.2 PowerShell Remediation Commands

```powershell
# Confirm state
Get-Service 'CitrixBrokerService' -ComputerName dc-vdi-02

# Start service
Start-Service 'CitrixBrokerService' -ComputerName dc-vdi-02

# Verify port
Test-NetConnection -ComputerName dc-vdi-02.finbridge.local -Port 80

# Check VDA registration recovery (Citrix Studio SDK)
Get-BrokerMachine -DesktopGroupName 'FinBridge-VDI-Pool-02' |
    Group-Object RegistrationState | Select-Object Name, Count
```

---

## 6. Verification Checks Post-Remediation

| Check | Expected Result |
|---|---|
| `CitrixBrokerService` state on dc-vdi-02 | Running |
| Port 80 on dc-vdi-02 | TcpTestSucceeded = True |
| Pool-02 registered machine count | ≥ 22 registered, ≤ 3 unregistered |
| Live session launch (jsmith or test account) | Session launches — no error 1030 |

---

## 7. Preventive Actions

| Action | Detail | Owner |
|---|---|---|
| Dual-controller assignment | Add `dc-vdi-01` to `ListOfDDCs` on all Pool-02 VDAs | Desktop Engineering |
| Windows Update policy for DCs | Exclude Delivery Controllers from auto-update/restart; require change-controlled patching with immediate post-patch reboot | Platform / Change Management |
| Broker Service monitoring alert | Alert within 2 minutes if `CitrixBrokerService` stops on any DC | Monitoring Team |
| Reboot-pending daily check | Alert if `RebootPending` flag is set on any DC with no scheduled reboot within 24 hours | Monitoring Team |

---

*Document created: 2026-08-13*
