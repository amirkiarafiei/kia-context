---
description: >
  A human-facing explanation of how the running system is laid out — the services, the data stores, the
  network paths between them, and what happens to a request from end to end. Written for a person, not
  an agent: diagrams, sequence flows and plain prose, with enough detail to reason about the system
  without opening it. May go stale between releases without harming anything.
  Produced ON REQUEST. Agents do not maintain this file and do not read it to do the work — the
  authoritative version is `context/specs/ARCHITECTURE.md`.
authority: artifact
writes: agent, on request
status: empty
covers: "{{what it describes}}"
last_updated: "{{YYYY-MM-DD}}"
---

# System Architecture — {{Project}}

> **The layout below is a sample, not a requirement.** Keep it, drop it, reorder it, or replace it
> entirely with whatever this project actually needs — you are not filling in a form, and an empty
> section is worse than a missing one. The one thing that must **not** change is the frontmatter above:
> those six fields are what make this file part of kiacontext.

**Contents** · [The topology](#the-topology) · [What each piece does](#what-each-piece-does) · [A request, end to end](#a-request-end-to-end) · [Failure modes, and what happens](#failure-modes-and-what-happens) · [Scale and limits](#scale-and-limits)

> Not written yet. Delete this file if this project does not need one.

## The topology

```mermaid
graph TD
  U[{{client}}] --> S[{{service}}]
  S --> D[({{store}})]
```

## What each piece does

## A request, end to end

```mermaid
sequenceDiagram
  {{actor}}->>{{service}}: {{action}}
```

## Failure modes, and what happens

## Scale and limits
