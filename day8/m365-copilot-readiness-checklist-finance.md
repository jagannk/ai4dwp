# Microsoft 365 Copilot Readiness Checklist — Finance Department
**Organisation:** Financial Services  
**Department:** Finance (~200 users)  
**Prepared by:** DWP Engineering  
**Date:** 2026-08-12  
**Licensing baseline:** M365 E5 | Copilot add-on: Not yet assigned

---

> **Risk note for this engagement:** SharePoint permissions across Finance sites and libraries were inherited from a 2019 migration and have not been audited since. Finance holds payroll, board packs, M&A documents, and client financial data. Permissions and oversharing checks are therefore **the highest-priority workstream** and must reach a satisfactory state *before* the Copilot licence is assigned. Copilot reasons over everything the signed-in user can access — unaudited oversharing will be surfaced and amplified at scale.

---

## SECTION 1 — Licensing Prerequisites

| # | Check | Owner | Status |
|---|-------|-------|--------|
| 1.1 | Confirm all ~200 Finance users hold an active **M365 E5** licence in Entra ID / M365 Admin Centre | Licensing Admin | ☐ |
| 1.2 | Confirm **Microsoft 365 Copilot add-on** licences have been procured for Finance (quantity matches headcount + ~5% buffer) | Licensing Admin | ☐ |
| 1.3 | Confirm no users are on legacy/conflicting SKUs (e.g. Office 365 E3 remnants from migration) that would block Copilot eligibility | Licensing Admin | ☐ |
| 1.4 | Identify a **pilot cohort** (10–20 users) within Finance to receive Copilot licences first before full department rollout | DWP Lead | ☐ |
| 1.5 | Do **not** assign Copilot add-on licences until Sections 2 and 3 are marked complete | DWP Lead | ☐ |

---

## SECTION 2 — Microsoft 365 Apps Client Version Requirements

| # | Check | Owner | Status |
|---|-------|-------|--------|
| 2.1 | Confirm all Finance endpoints are on **Microsoft 365 Apps Current Channel** (or Monthly Enterprise Channel minimum) — Copilot features require build **16.0.16227** or later | Endpoint Team | ☐ |
| 2.2 | Run an Intune / SCCM / Endpoint Analytics report to identify any Finance devices still on Semi-Annual Channel or pinned to older builds | Endpoint Team | ☐ |
| 2.3 | Confirm **Click-to-Run** (not MSI/perpetual) install is in use across all Finance devices | Endpoint Team | ☐ |
| 2.4 | Verify **Office update channel policy** is enforced via Intune or Group Policy — no user-managed update deferrals | Endpoint Team | ☐ |
| 2.5 | Confirm **Microsoft Teams** desktop client is current (Teams is a primary Copilot surface); auto-update is enabled or managed | Endpoint Team | ☐ |

---

## SECTION 3 — Identity & MFA Readiness

| # | Check | Owner | Status |
|---|-------|-------|--------|
| 3.1 | Confirm all Finance users are sourced from **Entra ID** (cloud-only or hybrid-synced) — no local-only AD accounts without cloud identity | Identity Team | ☐ |
| 3.2 | Confirm **MFA is enforced** for all Finance users via Conditional Access policy (not just Security Defaults) | Identity Team | ☐ |
| 3.3 | Confirm no Finance accounts are excluded from MFA CA policies (check exclusion groups carefully) | Identity Team | ☐ |
| 3.4 | Confirm Finance users are registered for **Microsoft Authenticator** (preferred) or equivalent strong MFA method — not SMS-only | Identity Team | ☐ |
| 3.5 | Review **service accounts** and shared mailboxes in the Finance OU — ensure none hold user licences that could receive Copilot inadvertently | Identity Team | ☐ |
| 3.6 | Confirm **Entra ID P2** (included in E5) is active and Privileged Identity Management is in use for any Finance admin roles | Identity Team | ☐ |

---

## SECTION 4 — SharePoint & OneDrive: Permissions and Oversharing Audit ⚠️ HIGHEST PRIORITY

> **Context:** Permissions across Finance SharePoint sites were inherited from a 2019 migration and have never been formally audited. Given the sensitivity of Finance data (payroll, board packs, M&A, client financials), this section must be completed and signed off before any Copilot licence is assigned. Microsoft 365 Copilot will surface content that users have *any* read access to — inherited broken permissions, overly broad site-collection access, and legacy Everyone/All Staff shares will all become discoverable via Copilot prompts.

### 4a — SharePoint Site & Library Access Audit

| # | Check | Owner | Status |
|---|-------|-------|--------|
| 4a.1 | **Enumerate all Finance SharePoint sites** — run `Get-SPOSite` filtered to Finance-owned sites and export to a working register | SharePoint Admin | ☐ |
| 4a.2 | For each Finance site, export the **site collection admin list** — remove any individuals who are no longer in Finance or no longer require admin rights | SharePoint Admin | ☐ |
| 4a.3 | **Identify all sites using unique permissions at library or folder level** (broken inheritance from migration) — export the full list | SharePoint Admin | ☐ |
| 4a.4 | **Identify and review all "Everyone", "Everyone except external users", and "All Company" shares** on Finance sites and libraries — these are high-risk overshares that Copilot will expose | SharePoint Admin | ☐ |
| 4a.5 | Remove or restrict all **broad group shares** identified in 4a.4 before Copilot go-live; document any exceptions with business justification and owner sign-off | SharePoint Admin / Finance Lead | ☐ |
| 4a.6 | For **payroll, M&A, and board pack libraries specifically** — confirm access is limited to named individuals or tightly scoped security groups; no inherited open access | SharePoint Admin / Finance Lead | ☐ |
| 4a.7 | Review **sharing links** on Finance sites: run a report of all "Anyone" and "People in your organisation" links that are still active; revoke links that are no longer required | SharePoint Admin | ☐ |
| 4a.8 | Confirm **external sharing** is disabled at the site-collection level for all Finance SharePoint sites | SharePoint Admin | ☐ |
| 4a.9 | Enable **SharePoint Advanced Management (SAM)** data access governance reports if available under E5 — use "Sites with 'Everyone' permissions" and "Oversharing insights" reports to validate | SharePoint Admin | ☐ |

### 4b — OneDrive for Business Audit

| # | Check | Owner | Status |
|---|-------|-------|--------|
| 4b.1 | Run a **OneDrive sharing report** for Finance users — identify files shared broadly with the organisation or externally | SharePoint Admin | ☐ |
| 4b.2 | Confirm the **OneDrive sharing policy** for the Finance group restricts "Anyone" link creation — enforce "People in your organisation" as the maximum, or "Specific people" for sensitive roles | SharePoint Admin | ☐ |
| 4b.3 | Confirm payroll and M&A-classified files are **not being stored in personal OneDrive** — verify against Purview DLP policy or activity reports | Compliance / DWP | ☐ |

### 4c — Access Reviews & Ongoing Governance

| # | Check | Owner | Status |
|---|-------|-------|--------|
| 4c.1 | Schedule and initiate an **Entra ID Access Review** for all security groups used to grant access to Finance SharePoint sites | Identity Team | ☐ |
| 4c.2 | Assign a named **Site Owner** for every Finance SharePoint site — document in the site register; no site should have no active owner | Finance Lead / SharePoint Admin | ☐ |
| 4c.3 | Establish a **quarterly permissions review cadence** for Finance sites post-Copilot go-live — add to IT governance calendar | DWP Lead | ☐ |

---

## SECTION 5 — Sensitivity Labelling

| # | Check | Owner | Status |
|---|-------|-------|--------|
| 5.1 | Confirm **Microsoft Purview sensitivity labels** are published and available to Finance users — at minimum: `Confidential`, `Highly Confidential`, `Internal` | Compliance Team | ☐ |
| 5.2 | Confirm a **mandatory labelling policy** is in place for Finance — users cannot save or send Office documents without applying a label | Compliance Team | ☐ |
| 5.3 | Confirm **auto-labelling policies** are configured for high-sensitivity Finance data patterns (payroll figures, account numbers, NI numbers, financial identifiers) | Compliance Team | ☐ |
| 5.4 | Confirm `Highly Confidential` labelled content applies **encryption** that is enforced at rest and in transit — verify label configuration in Purview | Compliance Team | ☐ |
| 5.5 | Confirm **Copilot respects label-based access controls** — test that a Highly Confidential encrypted document is not surfaced to a user without rights, even via a Copilot prompt | DWP Lead / Compliance | ☐ |
| 5.6 | Run a **content scan** (Purview Content Explorer or DLP activity explorer) across Finance SharePoint sites to identify unlabelled documents — prioritise bulk labelling or auto-label remediation before Copilot go-live | Compliance Team | ☐ |
| 5.7 | Confirm **DLP policies** block sharing of Finance-classified content (payroll, M&A) to external recipients or unapproved channels (personal email, USB, Teams external) | Compliance Team | ☐ |

---

## SECTION 6 — End-User Communications & Enablement

| # | Check | Owner | Status |
|---|-------|-------|--------|
| 6.1 | Deliver a **"What Copilot can see" awareness session** specifically for Finance — explain that Copilot accesses everything the user has permission to access; reinforce why the permissions clean-up was necessary | DWP / Change Lead | ☐ |
| 6.2 | Publish **Finance-specific Copilot prompt guidance** — example prompts relevant to Finance workflows (summarise board pack, draft accruals commentary, analyse budget variance) | DWP / Finance Champion | ☐ |
| 6.3 | Communicate **data handling responsibilities** — Finance users must not prompt Copilot to process data outside their access rights; reiterate acceptable use policy | Compliance / HR | ☐ |
| 6.4 | Identify and brief **Finance Copilot Champions** (2–3 senior users) who will support peer adoption and escalate issues | Finance Lead / DWP | ☐ |
| 6.5 | Confirm **helpdesk/service desk** is briefed on common Copilot issues (licence errors, missing features, sensitivity label prompts) before go-live | Service Desk Lead | ☐ |
| 6.6 | Set up a **Copilot feedback channel** (e.g. Teams channel or Viva Insights survey) for Finance users to report unexpected content surfacing or access anomalies post-launch | DWP Lead | ☐ |

---

## Sign-Off Gate — Pre Licence Assignment

Before the Copilot add-on is assigned to any Finance user, the following must be confirmed:

| Gate | Confirmed by | Date |
|------|-------------|------|
| Section 3 (Identity/MFA) complete | | |
| Section 4a items 4a.4–4a.6 complete (oversharing remediated) | | |
| Section 4a.7–4a.8 complete (links and external sharing locked) | | |
| Section 5.2 (mandatory labelling) and 5.4 (encryption) confirmed active | | |
| Finance Lead sign-off on permissions state | | |
| DWP Lead sign-off to proceed | | |

---

*Checklist version 1.0 — Review after pilot cohort deployment and update before full Finance rollout.*
