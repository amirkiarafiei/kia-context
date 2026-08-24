---
description: >
  A human-facing account of how this project is deployed and operated — the environments, what runs
  where, how a change reaches production, and what to do when something is wrong. Written so somebody
  who did not build the system can deploy it, and so somebody woken at night can recover it.
  Produced ON REQUEST. Agents do not maintain this file. It contains no secrets — only the names of the
  places secrets live.
authority: artifact
writes: agent, on request
status: empty
covers: "{{environments}}"
last_updated: "{{YYYY-MM-DD}}"
---

# Deployment — {{Project}}

> **The layout below is a sample, not a requirement.** Keep it, drop it, reorder it, or replace it
> entirely with whatever this project actually needs — you are not filling in a form, and an empty
> section is worse than a missing one. The one thing that must **not** change is the frontmatter above:
> those six fields are what make this file part of kiacontext.

**Contents** · [Environments](#environments) · [From a commit to production](#from-a-commit-to-production) · [Configuration](#configuration) · [Rolling back](#rolling-back) · [When it breaks](#when-it-breaks)

> Not written yet. Delete this file if this project is not deployed.

## Environments

| Environment | Where | Who can deploy |
|---|---|---|

## From a commit to production

## Configuration

> Name the settings and where they are read from. **Never paste a value.**

## Rolling back

## When it breaks

| Symptom | Likely cause | What to do |
|---|---|---|
