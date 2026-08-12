# M365 Copilot Readiness — Tiered Ranking (Finance Department)
**Organisation:** Financial Services  
**Department:** Finance (~200 users)  
**Prepared by:** DWP Engineering  
**Date:** 2026-08-12  
**Reference checklist:** m365-copilot-readiness-checklist-finance.md

---

## Tiered Ranking — M365 Copilot Readiness Checklist (Finance)

---

### MUST complete before rollout — Blocking

These items either prevent Copilot from functioning at all, or create a direct, immediate risk of data exposure the moment a licence is assigned.

| Item | Why blocking |
|------|-------------|
| **1.1** Confirm E5 licences active | Copilot add-on cannot be assigned without a qualifying base licence |
| **1.2** Copilot add-on licences procured | No licence = no rollout |
| **1.3** No conflicting legacy SKUs | Orphaned E3 seats can cause assignment errors and partial feature states |
| **2.1** M365 Apps on required build | Copilot UI does not render in older builds — rollout will fail silently for affected users |
| **2.3** Click-to-Run confirmed | MSI/perpetual installs cannot receive Copilot features regardless of licence |
| **3.1** All users in Entra ID | Copilot requires cloud identity — local-only AD accounts cannot authenticate to Copilot services |
| **3.2** MFA enforced via CA policy | Microsoft's own Copilot licensing terms require MFA; unprotected accounts accessing AI-summarised sensitive data is an unacceptable risk |
| **3.3** No MFA CA exclusions for Finance users | An exclusion silently creates unprotected Copilot-enabled accounts |
| **4a.4** Identify all "Everyone" / "All Company" shares | **See justification below** |
| **4a.5** Remove/restrict broad group shares | **See justification below** |
| **4a.6** Payroll, M&A, board pack libraries — access scoped to named individuals | **See justification below** |
| **4a.7** Active sharing links reviewed and revoked | **See justification below** |
| **4a.8** External sharing disabled on Finance sites | A single active external sharing link + Copilot = potential exfiltration surface |
| **5.2** Mandatory labelling policy active | Without it, Finance users can generate Copilot output from unlabelled documents and share it without any classification signal |
| **5.4** Highly Confidential label applies encryption | If encryption is not enforced, label presence alone does not prevent Copilot surfacing the content to under-privileged users |

---

### SHOULD complete before rollout — High risk if skipped

These do not technically block licence assignment but leave material risk open that is very hard to remediate after users are already in production.

| Item | Risk if skipped |
|------|----------------|
| **1.4** Pilot cohort defined | Full department rollout without a pilot removes the ability to catch permission surfacing issues on a small blast radius |
| **2.2** Devices on old build identified | Users silently get no Copilot; generates helpdesk noise and partial-rollout confusion |
| **2.4** Update channel policy enforced | Without it, devices drift back to old builds and Copilot breaks post-rollout |
| **2.5** Teams client current | Teams is a primary Copilot surface; stale clients cause meeting summary and chat features to fail |
| **3.4** Authenticator registered (not SMS) | SMS MFA is SIM-swappable; for Finance users accessing payroll and M&A data via an AI surface, SMS is not an acceptable second factor |
| **3.5** Service accounts / shared mailboxes reviewed | An accidentally licenced shared mailbox with Finance site access is a low-audit Copilot session |
| **4a.1** Finance sites enumerated | Cannot audit what you haven't listed — this is the foundation for all of Section 4 |
| **4a.2** Site collection admin list reviewed | Stale admins can grant themselves or others access to Finance content post-audit |
| **4a.3** Broken inheritance identified | Broken inheritance makes permissions opaque; Copilot will traverse it regardless |
| **4b.1** OneDrive sharing report run | Personal OneDrive is a common shadow store for Finance files; broad shares here feed Copilot too |
| **4b.2** OneDrive "Anyone" link policy restricted | Copilot can summarise a file and the summary can then be shared via an Anyone link — double exposure |
| **5.1** Sensitivity labels published to Finance | Users cannot label correctly if the right labels aren't available |
| **5.5** Test: Highly Confidential not surfaced to unauthorised user | This is the one functional test that confirms the technical controls actually work end-to-end |
| **5.6** Unlabelled content scan run | Copilot will happily summarise unlabelled payroll data; you need to know how much of that exists |
| **6.1** "What Copilot can see" awareness session | Without this, Finance users will not understand *why* they should report unexpected content surfacing |
| **6.3** Acceptable use / data handling communicated | Legal and compliance exposure if a Finance user prompts Copilot to process data beyond their authorised scope |

---

### CAN complete during or after rollout — Lower risk

These are important for long-term governance and adoption but do not create an acute exposure window at go-live.

| Item | Notes |
|------|-------|
| **2.4** Update policy monitoring (ongoing) | Initial state is verified pre-rollout; ongoing drift monitoring can follow |
| **3.6** Entra ID P2 / PIM in use for admin roles | Good practice, but admin role exposure is separate from end-user Copilot risk |
| **4a.9** SAM oversharing insights reports | Valuable for ongoing governance; the manual checks in 4a.4–4a.8 cover the acute risk |
| **4b.3** Payroll/M&A not stored in personal OneDrive | DLP policy can enforce this over time; not a day-one blocker if labelling and MFA are in place |
| **4c.1** Entra Access Reviews scheduled | Reviews take weeks to complete — initiate early but completion can follow rollout |
| **4c.2** Named Site Owner assigned per site | Important for governance; not a direct Copilot exposure risk |
| **4c.3** Quarterly permissions review cadence | Ongoing governance; schedule it now, runs post-launch |
| **5.3** Auto-labelling policies configured | Auto-labelling is additive; manual + mandatory labelling covers the acute risk |
| **5.7** DLP policies block external sharing of Finance content | DLP adds depth-in-defence but the external sharing disable at site level (4a.8) already closes the immediate gap |
| **6.2** Finance-specific prompt guidance | Adoption enablement; can follow initial rollout |
| **6.4** Finance Copilot Champions identified | Useful for sustained adoption; not safety-critical |
| **6.5** Helpdesk briefed | Should happen before go-live ideally, but low-risk if delayed by a few days |
| **6.6** Feedback channel set up | Post-launch monitoring; can be stood up on day one of rollout |

---

## Why permissions and oversharing belongs in MUST — not just first among equals

Licensing and client version checks are binary: a missing licence or old build means Copilot simply does not work. The failure is visible, contained, and easily fixed after the fact with no lasting harm done.

Unaudited permissions work differently. **Copilot does not evaluate whether a user *should* see something — only whether they *can*.** The moment a Finance user receives a Copilot licence, the model begins traversing the full graph of content they have access to, including everything inherited from the 2019 migration. A single "Everyone except external users" share on a payroll library — which may have sat dormant and unnoticed for seven years — instantly becomes queryable by every licenced user in the tenant via a natural language prompt. There is no warning, no audit trail that flags it as anomalous, and no way to un-surface information that has already been read and acted on.

The specific risk factors in this Finance environment compound each other:

- **Data gravity:** Payroll, M&A documents, and board packs are individually among the highest-sensitivity data classes in any organisation. Together they represent a concentration of material non-public information, personal data, and commercially sensitive content in one department.
- **Inheritance opacity:** Permissions broken from a 2019 migration are structurally harder to reason about than clean permissions. A site that *looks* correctly scoped at the top level may have a library three levels down with a stale Everyone grant that no one is aware of.
- **Breadth of reach:** At 200 users, even one misconfigured broad share exposed via Copilot is exposed to the entire Finance department simultaneously — not a single user browsing to a wrong URL.
- **Regulatory consequence:** For a financial services firm, inadvertent access to M&A data has insider trading implications. Payroll exposure triggers GDPR obligations. Neither is recoverable by patching permissions after the fact.

Licensing and client version checks are **deployment prerequisites**. The permissions audit is a **data protection control**. The former stops Copilot from running; the latter stops Copilot from causing harm when it does.

---

*Document version 1.0 — Companion to m365-copilot-readiness-checklist-finance.md*
