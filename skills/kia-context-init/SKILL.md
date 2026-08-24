---
name: kia-context-init
description: Fills in kiacontext for the first time in a repository. Handles a brand-new project and one already half-built — reverse-engineering ARCHITECTURE and DESIGN from the code, inferring a rough PROGRESS and BRAINSTORM from git history and flagging both as inferred, and asking the human a short, optional set of questions for GENESIS and MANIFESTO. Use once per repository, after the installer has scaffolded the files.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# kia-context-init — fill in the context for the first time

The installer created the files. This fills them in. **Run it once per repository.**

## The one rule

**Never write something you do not know.** A confidently wrong context file is worse than an empty one,
because it gets believed for months. Where you infer, say you inferred. Where you cannot know, leave the
placeholder and say why.

## Step 1 — work out which situation this is

```bash
git rev-list --count HEAD 2>/dev/null || echo 0    # how much history is there
git log -1 --format=%ad 2>/dev/null                 # how old
```

Then look at the tree. Two situations:

- **New project** — little or no code, few commits. Almost everything comes from the conversation.
- **Existing project** — real code and real history. Most of it comes from reading, some from asking,
  and one file cannot be recovered at all.

## Step 2 — fill what the code can tell you

These need no human input. Read the repository and write them.

| File | Where it comes from |
|---|---|
| `specs/ARCHITECTURE.md` | Reverse-engineer it. Manifests and lock files give the stack; the top-level tree gives the layout; the entry points give the one-page summary. Keep the layout one level deep. |
| `specs/DESIGN.md` | Reverse-engineer it from the stylesheets, theme file or component library — real token values, not invented ones. **If the project has no interface, delete the file** rather than filling it with defaults. |
| `INDEX.md` | Write it last, once you know what the other files actually contain. |

## Step 3 — infer the history, and label it as inferred

Only for an existing project. Git is the only record of what happened before kiacontext existed, and it
is a weak one — commit messages say what changed, almost never why.

```bash
git log --oneline --no-merges | head -100
git tag --sort=-creatordate | head -20
```

- **`logs/PROGRESS.md`** — group the history into a few coarse milestones, marked done. Short, high
  level, no acceptance criteria invented after the fact.
- **`logs/BRAINSTORM.md`** — only decisions the history makes genuinely visible: a dependency swapped, a
  module rewritten, an approach abandoned and replaced. Usually a handful. Skip anything that needs a
  reason the commits do not give.

**Both files open with this line, and every inferred entry says so:**

> **Reconstructed from git history on {{date}}, not captured from the work as it happened.** Treat it as
> approximate. Everything below this point was recorded live.

Numbering starts at M1 and D1 as normal — an inferred entry still owns its number permanently.

## Step 4 — ask the human, briefly, once

`GENESIS.md` and `MANIFESTO.md` cannot be reverse-engineered. Code shows what a project does, never why
it exists or what it must never do.

**Ask in one batch. Keep it to four or five questions. Offer to skip.** Something like:

- Why does this project exist — what happened that made it start?
- Who is it for?
- What is the one thing about it that must stay true?
- Is there anything it deliberately does *not* do?

Then write both files from the answers, in their words rather than yours. If they decline or answer
thinly, write what you have, leave the rest as placeholders, and move on — do not push. An empty section
is honest; an invented one is not.

Do not ask anything you could have found by reading the repository first.

## Step 5 — SEED.md

`SEED.md` holds the first prompts that started the project. For an existing project **those conversations
are gone and cannot be recovered.** Say so plainly and offer the choice: paste them if they still have
them somewhere, or delete the file.

Never reconstruct it. An invented first prompt is a fabricated historical record.

## Step 6 — finish

- Set every `last_updated` to today and every `covers` to something true.
- Write `INDEX.md`, including §7's link graph — **measure it with grep, do not guess it.**
- Delete every template file the project does not need, and every `> How to use this file` block from the
  ones it does.

## Step 7 — report

Tell the human, in a few lines:

- which files you filled, and from what;
- which are marked inferred;
- which are still placeholders and what you would need to finish them;
- anything you found while reading that they may not know.
