# Personal AI Usage Charter (DWP Desktop and Endpoint Engineer)

## Purpose
Use public AI assistants to improve speed and quality for low-risk engineering work while protecting users, systems, and DWP data.

## 1. Appropriate Uses (Allowed)
- Draft generic scripts (PowerShell/batch) with dummy values only.
- Explain command syntax, log patterns, and troubleshooting approaches.
- Create checklists, runbooks, triage templates, and summaries without sensitive details.
- Rewrite technical communications.
- Suggest non-production test cases.
- Summarize public vendor documentation.

## 2. Not Appropriate Uses (Not Allowed)
- Paste incident tickets containing user-identifiable details.
- Share hostnames, serial numbers, asset IDs, IP ranges, tenant identifiers, or internal URLs.
- Share screenshots/logs with names, emails, usernames, phone numbers, addresses, case refs, or auth data.
- Generate/validate production credentials, tokens, MFA codes, or secrets.
- Use AI output as sole approval for production changes.
- Share security incident details unless formally cleared.

## 3. Data-Handling Rule (PII and Credentials)
- Never paste end-user PII, credentials, secrets, or live identifiers into public AI.
- Redact by default using placeholders (USER_A, DEVICE_X, DOMAIN_Y).
- Remove metadata/hidden fields from logs/screenshots.
- If redaction is not possible, do not use public AI.
- Never share passwords, hashes, tokens, cookies, private keys, recovery codes, or session artifacts.

## 4. Generate Then Verify Rule (Scripts and System Changes)
- Treat AI output as a draft only.
- Review every line; remove anything not fully understood.
- Lint/syntax-check locally.
- Test in lab/VM/non-production first.
- Confirm expected behavior and rollback path.
- Seek second human review for impactful changes.
- Roll out in phases and monitor.
- Record generated output, changes made, and verification evidence.
