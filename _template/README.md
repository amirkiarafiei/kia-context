# kiacontext — `_template`

A copy-paste context harness for AI agents. **Markdown and folders. Nothing else.** No scripts, no
linters, no commands to run.

```
_template/
├── AGENTS.harness.md          ← append to AGENTS.md and CLAUDE.md
├── context/                   ← the agent reads and writes this
│   ├── INDEX.md
│   ├── genesis/ SEED.md · GENESIS.md
│   ├── specs/   MANIFESTO.md · ARCHITECTURE.md · DESIGN.md
│   └── logs/    PROGRESS.md · BRAINSTORM.md
└── docs/                      ← humans read this, and only when asked for
    SOFTWARE_ARCHITECTURE.md · SYSTEM_ARCHITECTURE.md · DEPLOYMENT.md
    AUTHENTICATION.md · SECURITY.md
```

## Installing it by hand

1. Copy `context/` and `docs/` into the repository root.
2. Append `AGENTS.harness.md` to the end of `AGENTS.md` and `CLAUDE.md`, then delete it.
   Keep those two files byte-for-byte identical.
3. Fill in `{{...}}` and today's date. Delete every section the project does not have.
4. Delete the `> How to use this file` blocks as each file becomes real.

## The one thing that matters

`context/` is for the agent. `docs/` is for people, and only when somebody asks for one. A stale
`docs/` file costs nothing because nothing reads it. **A stale `context/` file gets believed.**

## The frontmatter contract

Six fields, no more. There is no validator — the only thing keeping them consistent is that the list is
short enough to remember.

| Field | Answers |
|---|---|
| `description` | What this file is for, **and what does not go in it** |
| `authority` | How binding: `law` · `blueprint` · `state` · `background` · `map` · `artifact` |
| `writes` | Who may write to it, and when |
| `status` | `active` · `closed` · `frozen` · `empty` |
| `covers` | The span — phase name, dates, milestone or decision range |
| `last_updated` | When it was last true |

**The frontmatter is the strict part; everything below it is not.** Every section in every template is a
suggestion — reshape, reorder or delete it so the file fits the project. These six fields are what make a
file part of kiacontext, so they stay on every file, all six, with current values.

`description` carries the *what does NOT go here* line. That one sentence prevents more drift than a long
description does — most confusion in a harness is a file quietly doing another file's job.

## Splitting a log

`PROGRESS.md` and `BRAINSTORM.md` grow. Split them on a **phase boundary** first, and on **length**
second — around 1,500 lines, or whenever the file has stopped being readable.

- Name the parts `PROGRESS.md`, `PROGRESS_2.md`, `PROGRESS_3.md`.
- **Continue the numbering.** M17 follows M16 into a new file. D262 follows D261. These get cited from
  code, and a renumber breaks every citation silently.
- Set the old part's `status:` to `closed`, and put the next/previous block at the top **and** the bottom
  of both parts. The logs are a linked list; the blocks are how a reader walks it.
- **Never split** `ARCHITECTURE.md`, `DESIGN.md` or `MANIFESTO.md`. They describe one current state, so
  they change in place.

## The rules that make it work

They are in `AGENTS.harness.md` — seven of them, all about keeping documents honest, none about how to
write code. **Read that file before deciding this is just a folder of markdown.** The folders are easy;
the rules are the part that was paid for.

---

`kiacontext v0.1`
