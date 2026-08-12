# Copilot Incident Triage, Rankings & End-User Communications
### Legal Team — FinBridge / Legal Operations
*Prepared: 2026-08-12*

---

## Severity Rankings (Priority Order)

| Rank | Ticket | User | Severity | Reason |
|------|--------|------|----------|--------|
| 🔴 1 | Ticket 3 | Partner | **Critical — Security / Compliance** | Copilot surfaced content from a matter the user is not assigned to. Potential privilege breach. Must be investigated before any other ticket. |
| 🔴 2 | Ticket 4 | Legal ops manager | **Critical — Service Outage** | 40 users fully offline. Business-wide impact. Escalate immediately. |
| 🟡 3 | Ticket 5 | Contract specialist | **Medium — Functional Degradation** | Copilot is accessible but not grounding on the templates library. Productivity impact, no compliance risk. |
| 🟡 4 | Ticket 2 | New associate | **Medium — New User Provisioning** | Indexing lag for new mailbox is expected but needs confirming within 72-hour window. |
| 🟢 5 | Ticket 1 | Paralegal | **Low — Access / Permissions** | User never had legitimate access to the folder; Copilot correctly refused. Permissions review needed, not a fault. |

---

---

## Ticket 1 — Paralegal: "I don't have access to that content" on client NDA

### Incident Triage

**Reported behaviour:** Copilot returned "I don't have access to that content" when asked to summarise a client NDA stored in SharePoint.

**Key context flag:** The user states she has never opened the folder herself — she only heard about the file in a meeting. This is the critical detail.

**Likely cause (ranked):**
1. **Permissions/access boundary (most likely)** — The user does not have direct SharePoint access to the folder. Copilot strictly enforces the same permissions as SharePoint itself; if she cannot open the file, Copilot cannot read it either. The fact she heard about it in a meeting confirms she may never have been granted access.
2. **Sensitivity label restriction** — Client NDAs may carry a Confidential or Highly Confidential label that blocks Copilot grounding regardless of folder permissions.

**Is this a Copilot bug?** No — Copilot is working correctly. It refused to access content the user does not have permission to see. This is the expected and desired behaviour for a document management environment handling privileged legal documents.

**Recommended action:**
1. Confirm in SharePoint whether the paralegal's account has any access to the folder (direct or inherited).
2. If she needs access for a legitimate work reason, the matter owner or document controller must grant it through the correct SharePoint permissions process — not as an IT workaround.
3. Check the sensitivity label on the NDA; if labelled Confidential or above, even granting access may not allow Copilot to summarise it — escalate to Information Security for a policy review if needed.
4. Do not grant access without confirming with the matter partner that this is appropriate.

**Severity:** Low — No fault. Permissions and label review required before any access is granted.

---

### End-User Communication — Ticket 1

**Subject: Update on your Copilot request — client NDA summary**

Hi,

Thank you for getting in touch. We've looked into why Copilot wasn't able to summarise the NDA for you.

The message "I don't have access to that content" means Copilot couldn't reach the file — and in this case, that's because your account doesn't currently have access to the folder where it's stored. Copilot follows exactly the same access rules as SharePoint itself, so if you haven't been given permission to open the folder, Copilot can't read it on your behalf either.

This is actually Copilot working correctly — it won't read documents you haven't been authorised to see, which is especially important for client files.

**What happens next:**
1. If you need access to this NDA for a current matter, please speak to the partner responsible for that matter, who can arrange for the correct access to be granted.
2. Once access is confirmed, let us know and we'll verify everything is set up so Copilot can assist you.
3. Please don't use workarounds such as asking a colleague to copy the file — access to client NDAs must go through the proper permissions process.

We're sorry we can't unlock this for you directly, but we want to make sure client document access is handled correctly.

---

---

## Ticket 2 — New Associate: Copilot in Outlook can't find case emails

### Incident Triage

**Reported behaviour:** Copilot in Outlook cannot find or reference case emails for a user who started this week.

**Key context flag:** User is new this week — mailbox was created very recently.

**Likely cause (ranked):**
1. **Data indexing lag (most likely)** — New Microsoft 365 mailboxes take 24–72 hours to be fully indexed for Copilot grounding. Emails received before indexing completed will not be visible to Copilot until the index catches up.
2. **Licence provisioning delay** — The M365 Copilot licence may have been assigned but not yet fully activated (provisioning can lag up to 24 hours after assignment).

**Is this a Copilot bug?** No — indexing lag for newly created accounts is documented, expected behaviour.

**Recommended action:**
1. In the M365 admin centre, confirm the Copilot licence was assigned and note the exact timestamp.
2. If the licence was assigned within the last 72 hours, advise the user to wait and retry — no technical action needed.
3. If it has been more than 72 hours since licence assignment and the problem persists, open a service request with Microsoft for index investigation.
4. For immediate needs (e.g., context on urgent case emails), the user can paste relevant email text directly into a Copilot prompt as a temporary workaround.

**Severity:** Medium — Expected behaviour, but needs monitoring to confirm it resolves within the 72-hour window.

---

### End-User Communication — Ticket 2

**Subject: Update on your Copilot request — case emails not appearing**

Hi, and welcome to the team!

Thank you for flagging this. We've checked and the good news is there's nothing wrong with your setup — this is completely normal for a brand-new account.

When a new mailbox is created, Microsoft 365 needs 24 to 72 hours to index all of your emails so that Copilot can reference them. Until that process finishes, Copilot won't be able to find your messages. Think of it like a new filing system that's still being organised — once it's done, everything will be in the right place.

**What to do in the meantime:**
1. Please try again tomorrow morning. In most cases the indexing completes within one to two business days.
2. If you need Copilot's help with a specific email urgently, you can copy and paste the email text into the Copilot chat box and ask your question from there — this gets you the same result without waiting for indexing.
3. If it's still not working by the end of your first week, please reply to this message and we'll investigate further.

Nothing is broken — this will sort itself out automatically. We hope you're settling in well!

---

---

## Ticket 3 — Partner: Copilot surfaced a draft settlement from an unassigned matter

### Incident Triage

**Reported behaviour:** Copilot surfaced and summarised a draft settlement document from a matter the partner is not assigned to and did not know they could access.

**⚠️ This is a potential legal privilege and data governance incident. Do not treat this as a routine Copilot query.**

**Key context flag:** The partner explicitly states they are *not assigned* to the matter and were unaware they had any access. In a legal environment, unintended access to draft settlements between matters is a serious professional privilege concern.

**Likely cause (ranked):**
1. **Overly permissive SharePoint permissions (most likely)** — Copilot surfaces any content the signed-in user is technically permitted to access. If the partner can see the folder (even via inherited site or group membership), Copilot will surface it. The root cause is almost certainly an access control misconfiguration, not a Copilot fault.
2. **Broad group/site membership** — Partners may be members of a top-level SharePoint site that gives blanket read access across matter sub-folders, rather than having access scoped to their assigned matters only.

**Is this a Copilot bug?** No — Copilot showed the partner content they were technically permitted to see. However, this incident reveals that the underlying permissions model is not aligned with matter-assignment boundaries, which is a compliance risk that exists regardless of Copilot.

**Recommended immediate actions:**
1. **Escalate immediately** to the Legal Operations Manager and the firm's Data Protection / Compliance lead. Do not close this as a routine IT ticket.
2. Identify the specific matter folder and document surfaced. Confirm who is the assigned matter partner.
3. Audit the partner's SharePoint group memberships to understand how they gained access to the folder.
4. Temporarily restrict access to the settlement document pending a full permissions review.
5. Document the incident for compliance records — depending on the firm's obligations, this may need to be logged as a near-miss under the firm's information security policy.
6. Review whether other partners or staff may have similarly broad access to matters they are not assigned to. This may indicate a systemic permissions design problem.

**Severity:** Critical — Potential privilege/compliance incident. Requires immediate escalation beyond IT.

---

### End-User Communication — Ticket 3

**Subject: Important update — your Copilot query regarding unassigned matter document**

Hi,

Thank you for flagging this immediately — you did exactly the right thing by reporting it.

We have escalated your report to the Legal Operations Manager and our compliance team, and we are investigating urgently.

To be clear about what happened: Copilot surfaced content that your account had technical permission to access. Copilot itself did not make an error — but the access permissions on that matter folder appear to be broader than they should be, and we need to understand why.

**What we are doing:**
1. We are identifying the specific document and matter and restricting access to it while the review is in progress.
2. We are auditing how your account gained access to that folder.
3. The compliance team will determine whether any further action or notification is required.

**What we need from you:**
- Please do not share, save, or reference the content that Copilot surfaced. Treat it as if you had accidentally received a misdirected physical document — set it aside and let us handle it.
- If you are contacted by the compliance team for more detail about what you saw, please cooperate fully.

We will keep you updated as the investigation progresses. Thank you again for raising this — it is exactly the kind of thing we rely on staff to report promptly.

---

---

## Ticket 4 — Legal Ops Manager: All 40 Legal team members lost Copilot access

### Incident Triage

**Reported behaviour:** All 40 members of the Legal team lost Copilot access simultaneously this morning. It worked normally last week.

**Key context flag:** Sudden, team-wide scope is the defining signal here. Individual misconfigurations do not affect 40 users at once.

**Likely cause (ranked):**
1. **Bulk licence change or revocation (most likely)** — A licence assignment, group membership change, or Entra/Azure AD policy update affecting the Legal team group is the most common cause of simultaneous team-wide access loss.
2. **Conditional Access policy change** — A new or modified Conditional Access policy (e.g., applied to the Legal team security group) could block Copilot authentication for all members at once.
3. **SharePoint or Entra group modification** — Removal of the Legal team from a SharePoint site or Entra group that controlled Copilot access.
4. **M365 service incident** — Only if Microsoft's service health dashboard confirms an active Copilot incident. Tenant-scoped or team-scoped outages from Microsoft's end are less common but possible.

**Is this a Copilot bug?** Unclear — cannot be determined until service health and admin change logs are reviewed.

**Recommended immediate actions:**
1. Check the **M365 admin centre Service Health dashboard** for any active Copilot or M365 incidents affecting the tenant.
2. Pull the **audit log** for licence assignment changes in the last 24–48 hours, filtered to the Legal team group.
3. Check **Entra ID (Azure AD) group membership** for the Legal team — confirm the group is intact and the Copilot licence assignment is still applied.
4. Check **Conditional Access policies** for any new or modified rules that could affect the Legal security group.
5. If service health is clear and no licence changes are found, open a **P1 support ticket with Microsoft** and include the affected group name, tenant ID, and approximate time of first reported failure.
6. Provide the Legal Ops Manager with a status update every 30 minutes until resolved.

**Severity:** Critical — 40-user outage with immediate business impact. Treat as P1 until resolved.

---

### End-User Communication — Ticket 4

**Subject: Copilot access outage — Legal team | We are investigating**

Hi,

We are aware that Copilot access has stopped working for the entire Legal team as of this morning and we are treating this as a priority incident.

Our initial investigation is focused on recent changes to licences and access policies. We are also checking Microsoft's own service status to rule out a platform-level issue.

**Current status:** Under active investigation. No action needed from individual team members.

**What to expect:**
- We will send an update every 30 minutes until this is resolved.
- If Copilot is critical to a time-sensitive piece of work today, please contact the service desk directly and we will try to restore your individual access first while the wider fix is applied.

We apologise for the disruption and are working to resolve this as quickly as possible. Thank you for your patience.

*Next update by: 30 minutes from the time of this message.*

---

---

## Ticket 5 — Contract Specialist: Copilot gives generic answers on contract templates library

### Incident Triage

**Reported behaviour:** Copilot gives vague, generic answers when asked about clauses in the contract templates library and does not appear to read the actual documents.

**Likely cause (ranked):**
1. **Permissions/access boundary** — The contract specialist may not have direct SharePoint site membership for the templates library. Copilot cannot ground on content the user cannot directly access, even if they can browse to it via a shared link.
2. **Data indexing lag or gap** — If the templates library was recently created, migrated, or had a large number of files uploaded at once, the SharePoint search index may not yet have fully processed the content.
3. **Library/file type not indexed** — Certain SharePoint library configurations (e.g., restricted search indexing settings, check-out required, or files stored as non-standard formats) can prevent Copilot from reaching the content.
4. **Licence provisioning issue** — Incomplete Copilot licence provisioning can silently disable search grounding, causing Copilot to fall back to general knowledge only.

**Is this a Copilot bug?** Unlikely but unconfirmed — the symptom (generic answers, no grounding) is consistent with a permissions or indexing issue rather than a Copilot fault, but cannot be confirmed until access and index status are checked.

**Recommended action:**
1. Ask the contract specialist to navigate directly to the SharePoint templates library and open one of the contract files — if they cannot, it is a permissions issue.
2. If they can access the files directly, check the SharePoint library's search and indexing settings in the admin centre.
3. Confirm in the M365 admin centre that the user's Copilot licence is fully provisioned (not just assigned).
4. As a quick test: ask the specialist to open a specific contract file in Word and use Copilot *within that document* — if it works there but not in Teams or Outlook, the issue is likely search index scope rather than permissions.
5. If none of the above resolves it, raise a service request with Microsoft including the library URL, affected user UPN, and a sample of the prompts that returned generic results.

**Severity:** Medium — Functional degradation. No data exposure risk, but productivity impact on contract work.

---

### End-User Communication — Ticket 5

**Subject: Update on your Copilot request — contract templates library**

Hi,

Thank you for raising this. We've looked into why Copilot is giving you generic answers instead of referencing your contract templates.

When Copilot seems to ignore documents that should be in scope, it's usually because it can't reach them — either due to how the library's permissions are set up, or because the files haven't been fully indexed yet for Copilot to search.

**To help us investigate, could you try the following and let us know what happens:**
1. Go directly to the contract templates library in SharePoint and try opening one of the files. If you get an access error, please let us know — that tells us exactly what we need to fix.
2. Open a specific contract template in Word, then use the Copilot panel within that document to ask your question. If that works, it helps us narrow down where the problem is.

**What we're doing in parallel:**
- We're checking the library's indexing and permissions settings on our end.
- We're verifying your Copilot licence is fully activated.

We'll follow up with you by end of day once we have more information. In the meantime, the workaround of opening the file directly in Word and using Copilot there should get you the answers you need.

---

*Triage and communications prepared by IT Support | DWP Engineering*
*Date: 2026-08-12*
