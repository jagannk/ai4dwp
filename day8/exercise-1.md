# Copilot Support Ticket Triage

---

## Ticket 1 — Finance lead: Copilot won't summarise the Q3 board pack in SharePoint

**Likely cause (ranked)**
1. Sensitivity label restriction — board packs routinely carry high-sensitivity labels that block Copilot grounding
2. Permissions/access boundary — the user may have view access via a link rather than direct site membership, which Copilot does not honour
3. Data indexing lag — if the file was uploaded very recently it may not yet be in the search index

**Fastest check**
Open the file in SharePoint and inspect the sensitivity label banner at the top of the document.

**Is this actually a Copilot bug?** No — an explicit "I can see it myself" comment is the classic signal that the file is accessible to the user but blocked to Copilot by a label or indirect-link permission; genuine Copilot faults do not discriminate on individual documents this way.

---

## Ticket 2 — New hire (started yesterday): Copilot in Outlook knows nothing about my recent emails

**Likely cause (ranked)**
1. Data indexing lag — new mailboxes take 24–72 hours to be fully indexed for Copilot grounding
2. License/client prerequisite issue — the M365 Copilot license may have been assigned but not yet fully provisioned

**Fastest check**
In the M365 admin centre confirm the Copilot license was assigned and note the assignment timestamp; if assigned today, indexing lag is the explanation and no action is needed.

**Is this actually a Copilot bug?** No — indexing lag for brand-new accounts is expected and documented behaviour.

---

## Ticket 3 — HR manager: Copilot in Word returns "I don't have access to that content" for salary review spreadsheet

**Likely cause (ranked)**
1. Sensitivity label restriction — salary/HR files almost always carry Confidential or Highly Confidential labels that prevent Copilot from reading the content
2. Permissions/access boundary — the file may be in a restricted SharePoint library with explicit deny rules that override the user's general site access

**Fastest check**
Check the sensitivity label on the spreadsheet; if it is "Confidential" or higher, confirm whether the Copilot DLP/label policy is set to block grounding for that classification.

**Is this actually a Copilot bug?** No — the error message "I don't have access to that content" is the expected Copilot response when a sensitivity label or permission boundary blocks access; it is functioning correctly.

---

## Ticket 4 — Sales rep: Copilot in Teams can't find a client contract shared via a guest link from another org

**Likely cause (ranked)**
1. Guest/external sharing limitation — Copilot only indexes content within the user's own Microsoft 365 tenant; files residing in an external organisation's tenant and shared via a guest link are out of scope

**Fastest check**
Confirm where the file physically lives: if the URL contains the external org's tenant domain (e.g. `contoso.sharepoint.com`) Copilot cannot reach it regardless of the sharing link.

**Is this actually a Copilot bug?** No — cross-tenant grounding via guest links is an architectural boundary, not a fault.

---

## Ticket 5 — IT admin: Copilot suddenly stopped working for the whole Finance team this morning

**Likely cause (ranked)**
1. License/client prerequisite issue — a bulk licence change, assignment removal, or policy update (e.g. Conditional Access or Entra group change) affecting the Finance team is the most common cause of a sudden, team-wide outage
2. Permissions/access boundary — a SharePoint or sensitivity-label policy change overnight could block the entire team simultaneously
3. Genuine Copilot fault — only if the M365 service health dashboard shows a confirmed incident affecting the tenant

**Fastest check**
Check the M365 admin centre Service Health dashboard for active Copilot incidents, then cross-check the licence assignment report filtered to the Finance group for any changes in the last 24 hours.

**Is this actually a Copilot bug?** Unclear — sudden team-wide scope is unusual for individual misconfigurations and cannot be ruled out until service health and licence status are verified; escalate to Microsoft only after confirming both are clean.

---

## Ticket 6 — Manager: Copilot surfaced a file from a folder I forgot I had access to

**Likely cause (ranked)**
1. Permissions/access boundary (working as designed) — Copilot grounds on all content the user is permitted to access, not just recently viewed files; the manager has legitimate access to that folder

**Fastest check**
Verify in SharePoint that the manager's account has direct or inherited read permission on the folder in question.

**Is this actually a Copilot bug?** No — this is correct behaviour. Copilot surfaces any content the user is authorised to see; the manager is likely surprised by inherited folder access they had forgotten about. If the file should not be accessible to this user, the permission model needs to be reviewed, not Copilot.

---

## Ticket 7 — Analyst: Copilot gives generic answers, ignores internal SharePoint content entirely

**Likely cause (ranked)**
1. Permissions/access boundary — the analyst may have no direct membership of the relevant SharePoint sites, meaning Copilot has nothing to ground on
2. Data indexing lag — if SharePoint content was migrated or bulk-uploaded recently it may not yet be indexed
3. License/client prerequisite issue — an incomplete Copilot licence provisioning can result in search grounding being silently disabled

**Fastest check**
Have the analyst navigate directly to one of the expected SharePoint sites and confirm they can read content; if they cannot, it is a permissions issue not a Copilot issue.

**Is this actually a Copilot bug?** Unclear — the symptom (generic answers, no grounding) could be permissions, indexing, or provisioning; it cannot be attributed to Copilot itself until all three are eliminated.

---

## Ticket 8 — Executive assistant: Copilot in Outlook can't see shared mailbox calendar managed on behalf of director

**Likely cause (ranked)**
1. Permissions/access boundary — Copilot respects the Exchange delegate model strictly; calendar-sharing permissions granted at the folder level are often not equivalent to the Full Access delegation that Copilot requires to ground on a shared mailbox
2. License/client prerequisite issue — shared mailboxes do not hold a Copilot licence; Copilot can only act on them when the delegating user has both Full Access delegation and a valid Copilot licence

**Fastest check**
In the Exchange admin centre confirm the EA has **Full Access** delegation (not merely "Reviewer" or folder-level calendar permission) on the shared mailbox.

**Is this actually a Copilot bug?** No — delegate and shared mailbox access for Copilot grounding has documented prerequisites; the inability to see a calendar via a lighter permission grant is expected behaviour.
