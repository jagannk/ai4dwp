# Microsoft 365 Copilot Readiness Note - FinBridge Legal (45 users)

## What this line actually is
"Pulled up a matter she's never had access to" is not a normal support ticket and not a generic Copilot quality issue. It is a potential unauthorized data access incident involving legal confidentiality boundaries (ethical wall / matter access control), and must be handled as a security and compliance event with immediate investigation.

## What not to do
- Do not close it as "AI weirdness" or user confusion.
- Do not treat it as a prompt-tuning or training request.
- Do not ask the user to keep testing access on live matters.
- Do not delay notification to Security, Legal Ops, and M365 data governance owners.

## Two-sentence escalation draft
User reported that Microsoft 365 Copilot surfaced legal matter content they were not authorized to access, indicating possible permission boundary failure and potential confidentiality breach. Please open an immediate Sev-2 security/compliance investigation, preserve relevant audit logs, and involve Legal Operations, Information Security, and Microsoft 365 Purview/eDiscovery owners for containment and impact assessment.

## Readiness checklist placement
Add this as a mandatory item in the FinBridge Legal Copilot readiness checklist: "Any cross-matter or out-of-scope Copilot data exposure is treated as a security/compliance incident, not a standard service ticket."
