Root cause: Win11 upgrade removed legacy VPN client; Intune did not redeploy new client due to detection-rule gap.

Exact action taken:
1. Manually removed stale VPN registry entries under HKLM\SOFTWARE\<vendor>.
2. Force-triggered Intune sync.
3. New VPN client deployed.
4. Split-tunnel config applied.

Config detail: split-tunnel configuration applied on redeployed new client.

Verification: connectivity confirmed to all internal subnets.

Data impact: no data loss.

Preventive action needed: close detection-rule gap so Intune reliably detects absence/state after Win11 upgrade and auto-redeploys new VPN client.
