# Prompting Guide — Accessibility Review & Rewrites

*Read-through perspective: a nervous first-time AI user with no prior experience of AI tools, worried about doing something wrong.*

---

## Flagged Issues

### Flag 1 — The word "prompt" is never explained

The guide uses the word "prompt" from the very first section heading without defining it. A nervous first-timer may not know what a prompt is. They see a heading like "Example Prompts" and their first reaction is: *"What's a prompt? Is that something technical I need to set up?"*

---

### Flag 2 — RATE table: "Role" instruction feels strange

Telling someone to open Copilot and type *"I'm a finance analyst..."* as an opener will feel odd to a first-timer. People don't usually introduce themselves to software. Without a quick explanation of *why* this helps, a nervous user will skip this step entirely or feel self-conscious doing it.

---

### Flag 3 — Word example 3: "reading age of around 14" is unexpectedly strange to type

> *"Aim for a reading age of around 14."*

Someone unfamiliar with the concept of reading-age scores will find this prompt confusing to write. *"Why would I ask it to write for a 14-year-old? My audience is adults."* It needs either a plain alternative or a one-line explanation.

---

### Flag 4 — Excel example 1: assumes the user already has a formula to paste

> *"Explain what this formula does in plain English... =IFERROR(VLOOKUP(A2,Sheet2!$A:$C,3,FALSE),"Not found")"*

The prompt itself is full of technical syntax. A nervous user who doesn't know what VLOOKUP is won't have this formula sitting in front of them — which is the only situation where this prompt makes sense. This example is aimed at someone who is *moderately* comfortable with Excel already, not a true beginner. It risks making the reader feel: *"I don't even understand the example, so this isn't for me."*

---

### Flag 5 — Quick Tips: "iterate" is jargon; "weak" feels like a telling-off

> *"Iterate. If the first result isn't right..."*

"Iterate" is a technical/developer term. A nervous user will read it and feel excluded or confused.

> *"Write a professional email" is weak.*

Using the word "weak" to describe a user's attempt — even a hypothetical one — risks making an already-nervous person feel they're going to get it wrong. For someone who is worried about looking foolish, this tips over into discouraging.

---

### Flag 6 — Data safety note: leads with alarm, may put people off entirely

The current section opens with a bold warning block and includes the phrase **"is a data breach"**. For a nervous user who is already unsure whether they should be using AI at all, this framing could read as: *"This thing is dangerous. One wrong click and I've committed a serious offence."*

The result? They avoid Copilot altogether — which is the opposite of the guide's purpose.

The approved tool (Microsoft 365 Copilot) should be front and centre. The caution about external tools should be a brief, calm note — not the dominant message.

Also: **"Microsoft tenant"** is jargon. A first-timer won't know what this means.

---

## Rewrites (Flagged Sections Only)

---

### Rewrite 1 — Welcome section addition: define "prompt" upfront

**Replace the current Welcome section with:**

---

## Welcome

Microsoft 365 Copilot is built into the tools you already use every day — Outlook, Word, and Excel. It won't replace your judgement, but it can take a lot of the typing and thinking-from-scratch off your plate.

This guide gives you everything you need to start getting real value from Copilot today. No technical knowledge required.

**One word to know before you start: a prompt.**
A prompt is simply the instruction you type to Copilot — just like a search query, but written as a sentence. For example: *"Summarise this email in three bullet points."* That's all it is. You don't need special commands or technical language. Plain English works perfectly.

---

### Rewrite 2 — RATE table: add a reassuring "why" for the Role step

**Replace the Role row explanation with:**

| **R** | **Role** — give Copilot a bit of context about who you are | *"I'm writing on behalf of the Finance team..."* |

Add this line directly below the table (replacing the existing "Easy way to remember it" callout):

> You don't need all four every time — even just Action + Topic will get you a decent result. The Role part is simply context-setting: it helps Copilot tailor the tone and language it uses. Think of it like starting a call with *"Hi, I'm in accounts — can you help me with..."*

> **Easy way to remember it:** *"RATE your prompt before you send it."*

---

### Rewrite 3 — Word example 3: replace "reading age of 14" with plain-language equivalent

**Replace the current Word example 3 prompt and explanation with:**

#### 3. Improving an existing draft

> *"Review the document I've attached. Identify any sentences that are too long or hard to follow and rewrite them. Keep all the facts exactly as they are. Write in a way that anyone in the office could read easily, not just specialists."*

**Why it works:** You're asking Copilot to be your second pair of eyes — improving clarity without changing your content. It's like having a colleague read it back to you before you hit send.

---

### Rewrite 4 — Excel example 1: replace formula-paste prompt with a beginner-friendly scenario

**Replace the current Excel example 1 prompt and explanation with:**

#### 1. Making sense of a spreadsheet someone else built

> *"I've been sent a spreadsheet and I'm not sure what it's showing me. Column A has employee names, column B has numbers, and there's a formula in column C I don't recognise. Can you explain what column C is likely calculating and what I should look at first?"*

**Why it works:** You don't need to understand the spreadsheet to describe it. Copilot can help you get oriented before you start working with the data — useful any time you inherit a file from a colleague.

---

### Rewrite 5 — Quick Tips: remove jargon and soften the tone

**Replace the current Quick Tips section with:**

---

## Quick Tips for Better Results

- **The more detail you give, the better the result.** Compare *"Write a professional email"* with *"Write a 100-word email politely declining a meeting request and suggesting next Tuesday instead."* The second one saves you editing time.
- **Tell it who the reader is.** *"Explain this to a senior manager who isn't a finance specialist"* will give you something very different from *"Explain this to a new starter."* Copilot adjusts its language based on the audience you describe.
- **If the first result isn't quite right, just ask again.** You don't have to start over. Try: *"That's good, but make it shorter"* or *"Can you make the tone a bit warmer?"* You're having a conversation, not filling in a form.
- **Use it to get unstuck.** Even a rough Copilot draft gives you something to react to, and reacting is always faster than writing from scratch.

---

### Rewrite 6 — Data safety note: lead with reassurance, soften the caution

**Replace the current data safety section with:**

---

## Using Copilot Safely — A Short Note

**The short version: you're in safe hands with Microsoft 365 Copilot.**

Because Copilot is built directly into your Microsoft 365 apps, everything you type stays inside FinBridge's own secure Microsoft environment. It doesn't go anywhere else. You can use it for your normal day-to-day work with confidence.

The one thing to be mindful of: **free AI tools on the public internet — such as ChatGPT or Google Gemini — are a different story.** Those tools are not connected to our systems, and anything you type into them could be stored or used outside our control. So please don't paste work content — client names, account details, salary figures, or anything marked Confidential — into those tools.

Think of it this way: Microsoft 365 Copilot is like talking to a trusted colleague in a private meeting room. A public AI tool is more like saying the same thing loudly in a coffee shop.

This is the same principle from Day 1 of this programme: *think before you share, and know where your data is going.* Copilot is the approved, safe option — so use it freely.

---

*Review completed: 2026-08-12*
*Original guide: copilot-prompting-starter-guide-finbridge.md*
