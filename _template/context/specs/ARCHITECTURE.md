---
description: >
  The technical blueprint. What this project IS and how it is built, written so an agent can act on it
  without reading the whole codebase first. It describes the CURRENT state, so it changes in place and is
  never split into parts.
  NOT here: rationale or rejected options (BRAINSTORM.md), product rules (MANIFESTO.md), visual design
  (DESIGN.md), or a deep file tree — an agent can list a tree in one command, and a written one is stale
  within a week.
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

> **Scope.** What the system is and how it is built. *Why* it is built this way, and what was rejected:
> `context/logs/BRAINSTORM.md`.

**Contents**

| § | |
|---|---|
| [1](#1-what-this-is-in-one-page) | What this is, in one page |
| [2](#2-tech-stack) | Tech stack |
| [3](#3-repo-layout) | Repo layout |

Three sections, because nearly every project has these three and almost nothing else is universal. Add
whatever else this one needs — data model, runtime, interfaces, testing, deployment, invariants,
security, anything — in whatever order makes sense here, and update the contents table as you go.

---

## 1. What this is, in one page

> One paragraph, then a picture if a picture helps. The bar is that someone new could read this section
> alone and know what they are looking at.

```
{{input}} ──► {{step}} ──► {{step}} ──► {{output}}
```

**The few facts that explain most of the design:**

| | |
|---|---|
| **{{Fact}}** | {{One line}} |
| **{{Fact}}** | {{One line}} |

---

## 2. Tech stack

> Deliberately near the top. It is the first thing anyone needs and the last thing they should have to
> hunt for. Include versions where a version matters.

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
