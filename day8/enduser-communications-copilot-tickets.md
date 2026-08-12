# End-User Communications — Microsoft Copilot Support Tickets

---

## Ticket 1 — Finance Lead: Copilot won't summarise the Q3 board pack in SharePoint

**Subject: Update on your Copilot request — Q3 board pack**

Hi,

Thank you for getting in touch. We've looked into why Copilot couldn't summarise the Q3 board pack for you.

The file is most likely protected with a security label (for example, "Highly Confidential") that prevents Copilot from reading its contents. This is a deliberate data protection measure — not a fault with Copilot — and it applies even when you can open and read the document yourself.

**What to do next:**
1. Open the board pack in SharePoint and check the coloured label banner near the top of the document (e.g. "Highly Confidential – Board Only").
2. If you believe Copilot should be permitted to access this file for legitimate business reasons, please raise a request with your IT or Information Security team to review the label policy.
3. In the meantime, you can copy the relevant sections manually into a new Word document without a sensitivity label, and ask Copilot to summarise that instead.

If you have any further questions, please don't hesitate to reply to this message.

---

## Ticket 2 — New Hire: Copilot in Outlook knows nothing about my recent emails

**Subject: Update on your Copilot request — emails not visible**

Hi,

Welcome to the team! Thank you for letting us know about this.

This is completely normal for brand-new accounts. When a new mailbox is created, Microsoft 365 needs 24–72 hours to index your emails and calendar so that Copilot can reference them. Until that process is complete, Copilot won't be able to see your recent messages.

**What to do next:**
1. Please wait until tomorrow and try again — in most cases the indexing completes within one to two business days.
2. If Copilot is still not working after 72 hours, please reply to this message and we'll check that your Copilot licence has been fully set up.

There is nothing you need to do on your end right now. This will resolve itself automatically.

---

## Ticket 3 — HR Manager: Copilot returns "I don't have access to that content" for salary review spreadsheet

**Subject: Update on your Copilot request — salary review file**

Hi,

Thank you for reporting this. The message "I don't have access to that content" is Copilot telling you that a security policy is preventing it from reading the file — this is working exactly as intended.

Salary and HR files are typically labelled "Confidential" or "Highly Confidential," and our data protection policies block Copilot from processing that type of content to prevent accidental exposure of sensitive information.

**What to do next:**
1. If you need Copilot's help drafting or analysing content from this file, please speak to your HR systems administrator or Information Security team about whether a policy exception can be approved.
2. If the content is not sensitive, check whether the sensitivity label on the spreadsheet is correct and whether it can be lowered by the file owner.
3. For immediate needs, you can work with Copilot on a version of the document that has been de-identified (personal names and salaries removed).

We're sorry we can't resolve this instantly — it is a deliberate security control rather than a technical fault.

---

## Ticket 4 — Sales Rep: Copilot in Teams can't find a client contract from another organisation

**Subject: Update on your Copilot request — external client contract**

Hi,

Thank you for raising this. We've looked into why Copilot can't see the client contract shared with you.

The file lives on the client's own Microsoft 365 system, not ours. Copilot can only search and reference content stored within our organisation's Microsoft 365 environment. Files shared from an external company via a guest link are outside the boundary that Copilot can reach — this is an architectural limitation, not a bug.

**What to do next:**
1. Ask the client to send you the contract as an email attachment, or download a copy and save it to your own OneDrive or a Teams channel in our tenant.
2. Once the file is saved in our environment, Copilot will be able to find and reference it.
3. If you regularly work with documents from this client, consider asking them to set up a shared SharePoint space within our tenant for easier collaboration.

---

## Ticket 5 — IT Admin: Copilot stopped working for the whole Finance team

**Subject: Update — Copilot outage for Finance team**

Hi,

Thank you for escalating this promptly. We are actively investigating the issue.

When Copilot stops working for an entire team at the same time, the most common causes are a change to licences, a group membership update, or a policy change that affected the Finance team overnight. We're also checking Microsoft's service health dashboard to rule out a wider platform issue.

**What to expect next:**
1. We are reviewing licence assignments for the Finance team and checking for any policy or group changes made in the last 24 hours.
2. We will also verify Microsoft's M365 service health status for any confirmed Copilot incidents.
3. We will provide you with an update within **2 hours**.

If you need to complete urgent Copilot-dependent work in the meantime, please contact us directly and we will try to prioritise your account for restoration first.

We apologise for the disruption and will keep you informed.

---

## Ticket 6 — Manager: Copilot surfaced a file I didn't expect to see

**Subject: Update on your Copilot query — unexpected file in results**

Hi,

Thank you for flagging this — it's a great question and we're glad you let us know.

Copilot is designed to surface any file or content that you have permission to access, including folders you may have been given access to some time ago and forgotten about. It does not limit itself to files you've recently opened or are actively using.

In this case, it appears your account has read access to the folder where that file is stored, most likely through an inherited permission from a group or site membership.

**What to do next:**
1. If you believe you should **not** have access to that file, please let us know and we will review and correct the permissions immediately.
2. If you're happy to have access but would prefer Copilot not to surface it in future, please reply and we can discuss options with the site owner.
3. No action is needed if you're comfortable with the access — Copilot has simply done its job correctly.

Thank you for being security-aware and raising this with us.

---

## Ticket 7 — Analyst: Copilot gives generic answers and ignores SharePoint content

**Subject: Update on your Copilot request — generic responses**

Hi,

Thank you for getting in touch. We understand how frustrating it is when Copilot doesn't reference the internal documents you'd expect it to.

When Copilot gives generic answers instead of drawing on SharePoint content, it usually means one of the following: you may not have direct membership of the relevant SharePoint sites, the content was recently uploaded and hasn't been indexed yet, or there may be an issue with how your Copilot licence was set up.

**What to do next:**
1. Please try navigating directly to one of the SharePoint sites where the content lives and confirm you can open and read the files. If you cannot, it is a permissions issue we can fix for you.
2. If you can access the files fine but Copilot still ignores them, please reply and let us know which sites are affected — we'll investigate the indexing and licence status on our end.
3. If content was recently migrated to SharePoint, please allow 24–48 hours for indexing to complete before trying again.

We will follow up with you once we have checked the technical details.

---

## Ticket 8 — Executive Assistant: Copilot can't see shared mailbox calendar for the director

**Subject: Update on your Copilot request — shared mailbox calendar**

Hi,

Thank you for raising this. We've looked into why Copilot isn't able to see the director's calendar for you.

Copilot requires a specific level of permission — called **Full Access delegation** — to work with a shared mailbox or calendar on someone else's behalf. A lighter calendar-sharing permission (such as "Reviewer" or folder-level access) is enough for you to see the calendar yourself, but it isn't sufficient for Copilot to use it.

**What to do next:**
1. We will check the current delegation settings in the Exchange admin centre to confirm what level of access your account currently has.
2. If Full Access delegation is appropriate for your role, we'll arrange for it to be granted — please confirm with the director that they are happy for this to be set up.
3. Once Full Access is in place, Copilot should be able to reference the shared mailbox calendar within a few hours.

Please reply to confirm approval from the director and we will process this as quickly as possible.

---

*Communications prepared by IT Support — Microsoft Copilot Issue Resolution*
*Date: 2026-08-12*
