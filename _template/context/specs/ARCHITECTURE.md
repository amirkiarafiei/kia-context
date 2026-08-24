---
description: >
  The technical blueprint. What this project IS and how it actually works — the domain it models, the
  rules it enforces, and the machinery underneath. A reader must be able to UNDERSTAND the system from
  this file, not merely find out where to look: it is not an orientation page, an index or a map. The
  stack and the folder tree are the cheapest facts in any repository and an agent re-derives both in one
  command; the value here is everything a command cannot produce. It describes the CURRENT state, so it
  changes in place and is never split.
  NOT here: rationale or rejected options (BRAINSTORM.md), product rules (MANIFESTO.md), visual design
  (DESIGN.md), or a deep file tree — a written tree is stale within a week.
authority: blueprint
writes: agent, when explicitly refactoring
status: active
covers: the system as it is today
last_updated: "{{YYYY-MM-DD}}"
---

# 🏗️ ARCHITECTURE — How this project is built

> **The layout below is a sample, not a requirement.** Keep it, drop it, reorder it, or replace it
> entirely with whatever this project actually needs — you are not filling in a form, and an empty
> section is worse than a missing one. The one thing that must **not** change is the frontmatter above:
> those six fields are what make this file part of kiacontext.

> **Scope.** What the system is and how it works. *Why* it is built this way, and what was rejected:
> `context/logs/BRAINSTORM.md`. A domain rule that sounds like a product promise still belongs here if
> it describes how the system is built — see *Where a finding goes* in `AGENTS.md`.

## How deep to go

**Do not stop at the stack and the folder layout.** They are the easiest things to reverse-engineer,
which is exactly why a shallow version of this file always ends there. They are also the two facts a
reader could get for themselves in one command.

A reader should be able to answer all of these from this file alone, without opening the code:

- **The nouns.** What things does this system deal with, what does each one mean, and how do they relate
  to each other? Draw the model if a picture is clearer than a list.
- **The states.** If any of those things move through states, what are the states, what moves them, and
  who is allowed to move them? A state machine that lives only in the code is the single most common
  thing missing from a file like this.
- **The rules.** What does the system refuse to do, and where is that refusal enforced?
- **The flows.** For the two or three things this system exists to do, what happens end to end — which
  parts are involved, in what order, and what is stored on the way?
- **The contracts.** What does it expose to the outside, and what does it depend on?
- **The words.** If this project or its domain uses terms an outsider would misread, define them.

**Length is set by the system, not by a target.** A distributed service fleet needs far more than a CLI
tool. If a section needs five paragraphs to be true, write five. If it needs a table of thirty rows,
write the table.

**Every number is measured, and every claim is sourced.** Put the command beside a count so the next
reader can re-run it. For anything a command cannot produce — a domain model, a lifecycle, a rule — the
measurement is the **path you read it from**. `offering/domain/models.py` beside a state machine is
exactly as verifiable as a `wc -l` beside a number.

**Never drop a section because you cannot attach a command to it.** That is how the most valuable half of
this file goes missing: the cheap facts have commands, the expensive ones have citations, and dropping
whatever is not countable leaves only the cheap facts. If you are unsure of something, write it and mark
it uncertain. If you deliberately leave something out, say so in the file rather than narrowing quietly.

Where the code contradicts a README or a comment, the code wins — and say so.

**Contents**

| § | |
|---|---|
| [1](#1-what-this-is-in-one-page) | What this is, in one page |
| [2](#2-tech-stack) | Tech stack |
| [3](#3-repo-layout) | Repo layout |

Only three sections, because these three are nearly the only ones every project has. **They are the
starting point, not the whole file** — the questions above are what make it useful, and answering them
means adding sections. Domain model, lifecycle, data, runtime, interfaces, jobs, testing, deployment,
invariants, security: add what this project has, in whatever order makes sense, and update this table.

---

## 1. What this is, in one page

> One paragraph, then a picture if a picture helps. Say what the system does *in its own domain's terms*,
> not only in technical ones. The bar is that someone new could read this section alone and know both
> what they are looking at and what problem it solves.

```
{{input}} ──► {{step}} ──► {{step}} ──► {{output}}
```

**The few facts that explain most of the design:**

> The surprising ones. A fact that would make a new contributor stop and re-read is worth more here than
> a fact they would have assumed anyway.

| | |
|---|---|
| **{{Fact}}** | {{One line, pointing at the section that details it}} |
| **{{Fact}}** | {{One line}} |

---

## 2. Tech stack

> Include versions where a version matters, and where each choice is pinned so the next reader can check.

| Layer | Choice | Note |
|---|---|---|
| {{}} | {{}} | {{}} |

---

## 3. Repo layout

> **Top level only. Never deeper.** Name each folder and what it owns. Development changes a file tree
> faster than anyone updates a document, and an agent can list the tree in one command — what it cannot
> work out is what each part is *for*.

| Path | Owns |
|---|---|
| `{{folder}}/` | {{what lives here}} |

---

> Everything past this point is yours. The questions under *How deep to go* are not answered yet by the
> three sections above — go and answer them.
