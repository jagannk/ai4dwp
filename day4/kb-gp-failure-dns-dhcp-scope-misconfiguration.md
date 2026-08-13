Title: KB Article — Group Policy Fails to Apply at Startup (DNS Assigned by DHCP Points to Decommissioned Server)
KB ID: KB-GP-001
Applies To: Windows 11, Domain-joined machines, Post-DNS-migration environments
Source Incident: FAULT-A — Floor 3, Finance OU — 2024-03-15
Status: Verified

---

## Symptom

Three or more machines on the same subnet fail to apply Group Policy at startup. Users may experience missing drive mappings, missing software, unenforced security settings, or other policy-dependent configurations not taking effect. The problem affects multiple machines on the same floor or subnet simultaneously; machines on other subnets or manually pre-configured machines are unaffected.

---

## Cause

The DHCP scope for the affected subnet was not updated before or during a DNS server migration. When affected machines boot and renew their DHCP lease, they receive the IP address of the old (now decommissioned) DNS server. Unable to resolve the domain controller's fully qualified domain name, the machines cannot establish a secure channel to the DC, SYSVOL is unreachable, and Group Policy processing fails entirely.

---

## Scope

All domain-joined machines on subnets whose DHCP scope still references a decommissioned DNS server. Machines that were manually pre-configured with the new DNS server IP before the migration are unaffected. The fault is subnet-wide, not machine-specific.

---

## Workaround — Restore GP Immediately (No DHCP Change Required)

Run the following on each affected machine as a local administrator or via remote session:

**Step 1 — Set DNS manually to the correct new server**
```powershell
# Replace <InterfaceAlias> with the active adapter name (e.g., Ethernet, Wi-Fi)
Set-DnsClientServerAddress -InterfaceAlias "<InterfaceAlias>" -ServerAddresses "10.10.0.10"
```

**Step 2 — Flush DNS cache and re-register**
```powershell
ipconfig /flushdns
ipconfig /registerdns
```

**Step 3 — Force a DHCP renewal (picks up new lease)**
```powershell
ipconfig /release
ipconfig /renew
```

**Step 4 — Verify DNS is now correct**
```powershell
Get-DnsClientServerAddress | Select-Object InterfaceAlias, ServerAddresses
# Confirm: ServerAddresses should show 10.10.0.10, not 10.10.3.250 or 172.16.5.5
```

**Step 5 — Verify DC connectivity**
```powershell
nltest /sc_verify:FINBRIDGE
# Expected: "Flags: ... WRITABLE ... DC connection status = OK"
```

**Step 6 — Force Group Policy refresh**
```powershell
gpupdate /force
```

Expected result: GP applies cleanly. Event ID **1501** or **1502** (GP applied successfully) appears in the GroupPolicy log; Event ID **1500** confirms synchronous processing completed.

---

## Permanent Fix — Update DHCP Scope

On the DHCP server, update the DNS server option for every affected subnet scope:

1. Open **DHCP Manager** (or use PowerShell):
   ```powershell
   # List current DNS options for the affected scope
   Get-DhcpServerv4OptionValue -ScopeId <ScopeIP> -OptionId 6

   # Set correct DNS server
   Set-DhcpServerv4OptionValue -ScopeId <ScopeIP> -OptionId 6 -Value "10.10.0.10"
   ```
2. Verify the scope no longer references the old DNS IP (10.10.3.250 / 172.16.5.5).
3. Force lease renewal on all affected machines (`ipconfig /release` + `ipconfig /renew`) so they pick up the corrected DNS assignment.
4. Confirm Event 1500 or 1502 in the GroupPolicy log on each machine after renewal.

---

## How to Spot It

| Signal | Location | Detail |
|--------|----------|--------|
| Event 5719 | System log — Netlogon | "Unable to set up a secure channel to domain — no domain controller available"; DNS query for DC FQDN returned no response |
| Event 1058 | Application log — GroupPolicy | "Group Policy processing failed — cannot access \\DC\SYSVOL\..." Error code `0x3` (path not found) |
| Event 1030 | Application log — GroupPolicy | "Cannot query list of Group Policy objects" Error code `0x546` |
| Event 1129 | Application log — GroupPolicy | "Group Policy failed — no network connectivity to domain controller" |
| Event 1014 | System log — DNS Client | "Name resolution for \<DC FQDN\> timed out — none of the configured DNS servers responded" |
| Event 50036 | System log — DHCP Client | DHCP lease showing old/decommissioned DNS IP in assigned DNS servers field |

**Key discriminator:** Check the DNS server IP assigned in Event 50036 against the list of current live DNS servers. A decommissioned IP in that field confirms DHCP scope misconfiguration as the root cause. Compare against an unaffected machine on the same OU — if its DHCP-assigned DNS is correct and GP applies cleanly, the fault is subnet/scope-level, not machine-level.
