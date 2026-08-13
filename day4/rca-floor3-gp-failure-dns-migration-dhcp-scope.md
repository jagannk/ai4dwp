Title: Root Cause Analysis — Group Policy Failure at Startup (Floor 3 Finance Machines)
Fault Reference: FAULT-A
Affected Machines: DESKTOP-FB031 (representative), FB055, FB056, FB057 — OU=Finance, Floor 3
Unaffected Reference: DESKTOP-FB029 / FB058 (same OU)
Incident Date: 2024-03-15
Incident Window: 07:40 – resolution
Status: Verified

---

## Executive Summary

Three of four Windows 11 machines in the Finance OU on Floor 3 failed to apply Group Policy on startup on 2024-03-15. Investigation confirmed that the DHCP scope for the Floor 3 subnet was not updated as part of an overnight DNS server migration (wave completed at 02:00). Affected machines received the IP of the decommissioned DNS server via DHCP, were unable to resolve the domain controller FQDN, and Group Policy processing failed entirely. The single unaffected machine (FB058) had been manually pre-configured with the correct new DNS server before the migration wave and was therefore unaffected.

---

## Incident Timeline

| Time | Event | Source | Detail |
|------|-------|--------|--------|
| 2024-03-14 overnight | DNS migration wave begins | Infrastructure team | Old DNS servers decommissioned; new central DNS (10.10.0.10) brought online |
| 02:00, 2024-03-15 | Migration wave completes | Infrastructure team | Old DNS server 10.10.3.250 / 172.16.5.5 decommissioned; DHCP scope for Floor 3 subnet not updated |
| Pre-migration | FB058 manually pre-configured | Engineer | DNS manually set to 10.10.0.10 on FB058 before migration wave |
| 07:40:02 | Network Location Awareness starts | DESKTOP-FB031 | Machine boot — network stack comes up |
| 07:40:08 | Event 5719 — Netlogon error | DESKTOP-FB031 | No domain controller available; DNS query for FINBRIDGE-DC01.finbridge.local returned no response |
| 07:40:09 | Event 1058 — GP error | DESKTOP-FB031 | Cannot access \\FINBRIDGE-DC01\sysvol\...\gpt.ini — error code `0x3` |
| 07:40:10 | Event 1030 — GP warning | DESKTOP-FB031 | Cannot query list of Group Policy objects — error code `0x546` |
| 07:40:11 | Event 1058 — GP error (repeat) | DESKTOP-FB031 | Same SYSVOL access failure |
| 07:40:12 | Event 1129 — GP error | DESKTOP-FB031 | GP failed — no network connectivity to DC; will retry on connectivity restore |
| 07:40:05 | Event 50036 — DHCP lease | DESKTOP-FB029 (unaffected) | DNS assigned: 10.10.0.10 (correct); GP processes successfully (Event 1500 @ 07:40:11) |
| 07:41:05 | Event 1014 — DNS timeout | DESKTOP-FB031 | Name resolution for FINBRIDGE-DC01.finbridge.local timed out; none of the configured DNS servers responded |
| 07:42:18 | Event 50036 — DHCP lease | DESKTOP-FB031 | IP 10.10.3.144 leased; **DNS assigned: 10.10.3.250** (decommissioned old DNS server) |
| 07:44:01 | Event 1129 — GP error (repeat) | DESKTOP-FB031 | GP still failing — no DC connectivity |
| — | DHCP server log — FB055–057 | DHCP server | DNS assigned: 172.16.5.5 (Floor 3 local DNS — decommissioned 2024-03-14 overnight) |
| — | DHCP server log — FB058 | DHCP server | DNS assigned: 10.10.0.10 (correct — manually set, overrides DHCP) |

---

## Evidence Assessment

### Why DNS failure is the root cause (not DC unavailability, not GP policy fault)

- **Event 5719 @ 07:40:08** — Netlogon explicitly states "DNS query for FINBRIDGE-DC01.finbridge.local returned no response." The DC is not unavailable — it cannot be reached because its name cannot be resolved.
- **Event 1014 @ 07:41:05** — "None of the configured DNS servers responded." The DNS servers themselves are unreachable, not just the DC. This points to the DNS server address being wrong, not to a DC outage.
- **Event 50036 @ 07:42:18** — DHCP lease confirms DNS assigned = **10.10.3.250**, which is the decommissioned old DNS server. This is the direct cause of DNS non-resolution.
- **DHCP server logs** — FB055–057 all received 172.16.5.5 (Floor 3 local DNS, decommissioned overnight). FB058 received 10.10.0.10 (correct) because it was manually pre-configured.
- **FB029 (Event 50036 @ 07:40:05 / Event 1500 @ 07:40:11)** — Identical machine in the same OU; received correct DNS via DHCP and applied GP successfully. The only structural difference is the DNS server assigned. This directly implicates DHCP scope misconfiguration, not a machine or policy fault.

### Why the GP errors are symptoms, not independent causes

Events 1058, 1030, 1129 all cascade from the DNS failure: GP cannot locate the DC, therefore cannot reach SYSVOL, therefore cannot process policy objects. None of these events indicate a fault in the policies themselves or in the machines' GP client.

---

## Root Cause

The DHCP scope for the Floor 3 subnet (10.10.3.0/24) was not updated to reflect the new DNS server (10.10.0.10) before the overnight DNS migration wave completed at 02:00 on 2024-03-15. The decommissioned DNS servers (10.10.3.250 and 172.16.5.5) were removed from service, but remained configured as the DNS option in the DHCP scope. Machines that renewed or obtained a new DHCP lease after 02:00 received a non-functional DNS server address. Unable to resolve the domain controller FQDN, they could not establish a Netlogon secure channel, could not reach SYSVOL, and Group Policy processing failed at every startup.

The single unaffected machine (FB058) was manually pre-configured with the correct DNS IP before the migration and therefore did not rely on the DHCP scope option.

---

## 5-Why Analysis

| Why | Answer |
|-----|--------|
| **Why #1** — Why did Group Policy fail on three machines? | The machines could not reach the domain controller — Netlogon reported no DC available (Event 5719) and GP could not access SYSVOL (Event 1058). |
| **Why #2** — Why could the machines not reach the domain controller? | DNS resolution for FINBRIDGE-DC01.finbridge.local failed — none of the assigned DNS servers responded (Event 1014). |
| **Why #3** — Why did DNS resolution fail? | The DNS server IP assigned to the machines via DHCP (10.10.3.250 / 172.16.5.5) was the old server, which was decommissioned at 02:00 as part of the migration wave (Event 50036 confirming the bad assignment). |
| **Why #4** — Why were the machines receiving an IP for the decommissioned DNS server? | The DHCP scope for the Floor 3 subnet was not updated to remove the old DNS server address and add the new one (10.10.0.10) before or during the migration wave. |
| **Why #5** — Why was the DHCP scope not updated? | The DNS migration plan did not include a step to audit and update all DHCP scopes referencing the old DNS server before decommissioning it; there was no pre-migration checklist item or automated validation to confirm all scopes were pointing to the new DNS before the cutover completed. |

**Root cause conclusion:** A gap in the DNS migration runbook — no DHCP scope audit or update step — left the Floor 3 subnet DHCP scope pointing to a server that no longer existed, silently breaking domain connectivity for all machines that relied on that scope for DNS assignment.

---

## Resolution Applied

1. DHCP scope for Floor 3 subnet updated: DNS option changed from 10.10.3.250 to 10.10.0.10.
2. On each affected machine (FB031, FB055, FB056, FB057):
   - `ipconfig /release` + `ipconfig /renew` — new lease obtained with correct DNS.
   - `ipconfig /flushdns` + `ipconfig /registerdns` — cache cleared, DC reachable.
   - `gpupdate /force` — Group Policy applied successfully.
3. Verified Event 1500/1501/1502 in GroupPolicy log on all four machines post-fix.
4. `nltest /sc_verify:FINBRIDGE` confirmed secure channel restored.

---

## Preventive Actions

| # | Action | Owner | Priority |
|---|--------|-------|----------|
| 1 | **DHCP scope audit step in DNS migration runbook** — Before decommissioning any DNS server, run a full audit of all DHCP scopes across all subnets to identify any scope still referencing the old DNS IP. Update all identified scopes as part of the migration task, not after. | Infrastructure / DNS team | Critical |
| 2 | **Automated pre-cutover validation** — Add a pre-decommission check script that queries all DHCP scopes for references to the DNS server being retired and fails the migration step if any remain unresolved. | Infrastructure / Automation | High |
| 3 | **Post-migration GP health check** — After any DNS or infrastructure migration, run `gpresult /r` or check for Event 1058/1129 across all domain-joined endpoints in affected OUs before declaring migration complete. | Infrastructure / Desktop team | High |
| 4 | **DHCP scope documentation** — Maintain a registry mapping each subnet DHCP scope to its DNS configuration, updated as part of every DNS infrastructure change. | Infrastructure | Medium |
| 5 | **Monitoring for Event 1129** — Create an alert on Event ID 1129 (GP failed — no DC connectivity) across all endpoints. A cluster of this event from the same subnet is a fast indicator of a subnet-level DNS fault. | Monitoring / Desktop team | Medium |

---

## Lessons Learned

- DNS migration runbooks must treat DHCP scope updates as a hard dependency, not an afterthought. Decommissioning a DNS server before all DHCP scopes are updated creates a silent, delayed failure that only surfaces when machines renew leases.
- The unaffected machine (FB058) is the key discriminator — identical OU, identical policy, different DNS source. Any incident with subnet-partial impact should immediately prompt a DHCP scope comparison between affected and unaffected machines.
- Events 5719 + 1014 together are the fastest signal: Netlogon cannot find the DC AND DNS is timing out. This combination points to DNS server reachability before GP or DC availability is investigated.
- Total blast radius was limited because one machine was manually pre-configured. Pre-configuring a canary machine and validating GP before migration completion is a low-cost way to surface this class of failure before it affects all users.
