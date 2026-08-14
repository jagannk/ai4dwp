# Floor 6 Startup/Logon Evidence Script - AI Draft vs Hand-Corrected

## One-line fix note
I fixed matching and evidence quality by changing regex-based matching to wildcard-safe matching, adding missing startup sources and event channels, forcing structured JSON/CSV output for A/B comparison, and adding strict-mode safe `DisplayName` checks for sparse uninstall registry keys.

## Update stamp
- 2026-08-14: Corrected `PropertyNotFoundStrict` crash in dry-run/collection by guarding optional uninstall-key properties before access.

## How to run
- Dry run (no files written):

```powershell
Set-Location "c:\Users\labuser\Documents\Training\Project"
.\floor6-startup-logon-evidence-v2.ps1 -AppPattern "FinBridge" -LookbackHours 72 -DryRun
```

- Actual collection (writes evidence folder):

```powershell
Set-Location "c:\Users\labuser\Documents\Training\Project"
.\floor6-startup-logon-evidence-v2.ps1 -AppPattern "FinBridge" -LookbackHours 72 -OutputRoot ".\evidence"
```

## Side-by-side scripts

| AI-generated first version | Hand-corrected version |
|---|---|
| See [floor6-startup-logon-evidence-ai-v1.ps1](floor6-startup-logon-evidence-ai-v1.ps1) | See [floor6-startup-logon-evidence-v2.ps1](floor6-startup-logon-evidence-v2.ps1) |

## Output structure (from corrected script)
- summary.json: hypothesis, hit counts, confirm/rule-out decision guide
- host-info.json: machine and OS context for evidence chain
- startup-artifacts.json: Win32 startup commands + Run keys + Startup folder matches
- scheduled-tasks.json: scheduled task artifacts tied to app pattern
- services.json: service artifacts tied to app pattern
- processes.json: running process evidence snapshot
- installed-apps.json: installed version/publisher footprint
- events-diagnostics-performance.csv: boot/logon performance events
- events-winlogon.csv: Winlogon operational events
- events-system-gp-scm.csv: Group Policy and SCM correlation events
- timeline.csv: unified, time-sorted event timeline for triage handoff

## What confirms or rules out top-ranked cause
- Confirm deployment-linked startup stall:
  - Startup artifacts for the app exist and align with same-window logon/perf event spikes.
  - A/B retest after disabling startup item on pilot user reduces delay and event density.
- Rule out deployment-linked startup stall:
  - No app startup artifacts found and no correlated events.
  - Delay persists unchanged after pilot startup disable/rollback.
