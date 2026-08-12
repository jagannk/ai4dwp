# Exercise Day 7 — Comment Clustering, Prioritisation & Proactive Notification

**Dataset:** 15 post-rollout user comments  
**Date:** 2026-08-12

---

## 1. Comment Clusters by Theme

### Theme A — Credentials Vault Access Failure (CRITICAL)
IDs: 5, 8, 14

| ID | Comment |
|----|---------|
| 5 | Shared credentials vault is completely inaccessible, whole team blocked. |
| 8 | Third day now I can't access the credentials vault, this is urgent. |
| 14 | Vault access still broken, escalated to my manager now. |

**Pattern:** Total loss of access to the shared credentials vault. Multi-day outage (at least 3 days confirmed). Already self-escalated by users. Whole-team blast radius implied in ID 5.

---

### Theme B — Admin Console Lockouts (CRITICAL)
IDs: 3, 10

| ID | Comment |
|----|---------|
| 3 | Second engineer this week locked out of the admin console entirely. |
| 10 | Admin console lockouts happening across the whole team now, not just one person. |

**Pattern:** Started as isolated incidents, now confirmed team-wide. Privileged access loss — engineers cannot perform admin functions.

---

### Theme C — Test VM Remote Access Failure (HIGH)
IDs: 1, 12

| ID | Comment |
|----|---------|
| 1 | Can't remote into any of my test VMs since the update, blocking my whole day. |
| 12 | My test VM access is still down, can't do my job today either. |

**Pattern:** Remote access to test VMs broken since rollout. At least two users affected across separate days. Work-blocking.

---

### Theme D — Minor UI / UX Changes (LOW)
IDs: 2, 4, 7, 9, 11, 15

| ID | Comment |
|----|---------|
| 2 | New ticketing system dashboard is a nicer colour scheme, small win. |
| 4 | Font in the new portal is slightly smaller, hard to read for some of us. |
| 7 | Notification sounds changed, mildly annoying but not a big deal. |
| 9 | Dashboard refresh is a bit slower than before, barely noticeable. |
| 11 | Nice that the new theme supports dark mode properly now. |
| 15 | Small UI icon changes, took a second to adjust but fine. |

**Pattern:** Cosmetic and minor usability observations. Mix of positive and minor negative. No productivity loss reported.

---

### Theme E — Positive / No Issues (INFORMATIONAL)
IDs: 6, 13

| ID | Comment |
|----|---------|
| 6 | Overall the rollout felt smoother than last time, appreciate it. |
| 13 | No issues at all for me, everything's working fine. |

**Pattern:** Satisfied users. Useful as a baseline — majority of comments are *not* in this group, which reinforces the urgency of Themes A and B.

---

## 2. Top 2 Themes — Act Today

### Rank 1 — Credentials Vault Access Failure (Theme A)

**Why #1:**
- Complete, not partial — the vault is *totally* inaccessible (ID 5)
- Multi-day duration confirmed (ID 8: "third day now") — this predates the current day's feedback
- User has already escalated to management (ID 14) — if engineering does not act first, leadership escalation is imminent
- A shared credentials vault is a dependency for *other* systems; vault downtime has a multiplier effect on all work requiring those credentials
- Whole-team blast radius (ID 5) means the impact is not contained to one user

### Rank 2 — Admin Console Lockouts (Theme B)

**Why #2:**
- Privilege loss for engineers is high-severity by definition — admin console access is required to investigate and fix other issues, including Rank 1
- Scope has already widened: ID 3 reports one person, ID 10 confirms it is now the whole team — active spread pattern
- If admin console lockouts are not resolved quickly, the team loses the ability to self-remediate any other rollout issue

---

## 3. Proactive Notification — Theme A: Credentials Vault Access Failure

**Channel:** Incident notification (email + Teams channel post)  
**Audience:** All affected users + their managers + IT leadership  
**Tone:** Transparent, ownership-taking, action-oriented

---

**Subject:** [ACTIVE INCIDENT] Shared Credentials Vault — Access Outage | Engineering Update

---

Hi all,

We are aware that the **shared credentials vault is currently inaccessible** for a number of users following the recent rollout, and that this has been ongoing for **multiple days**.

We sincerely apologise for the disruption this is causing. We understand that vault access is a dependency for day-to-day work, and we are treating this as a **priority-one incident**.

**Current status:** Under active investigation by the engineering team.

**What we know:**
- The vault became inaccessible following the recent system update
- Multiple users across the team are affected
- Access has not been restored by vault restart or standard remediation steps — a deeper fix is being worked

**What we are doing right now:**
- A dedicated engineer has been assigned and is investigating the root cause
- We are liaising with the [vault platform/vendor] team to identify whether this is a configuration or authentication regression from the update
- An interim workaround will be communicated as soon as one is available

**What to do in the meantime:**
- If you have an urgent credential requirement that cannot wait, please contact **[Service Desk contact / name]** directly and reference incident **[INC-XXXX]** — we will handle these manually on a case-by-case basis
- Do not attempt repeated vault login attempts as this may trigger additional lockout behaviour

**Next update by:** [Time — e.g. 14:00 today]

If you have been affected and have not already logged a ticket, please do so and reference **[INC-XXXX]** so we can track the full impact accurately.

Thank you for your patience.

**[Your name]**  
DWP Engineering  
[Contact / Teams handle]

---

*Exercise Day 7 — Comment analysis and incident communication practice*
