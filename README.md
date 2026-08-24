# kia-context

**A kit of markdown files to maintain project context for/by agents. Nothing more.**

Not a framework. Not a workflow. Not a competitor to [spec-kit](https://github.com/github/spec-kit),
Claude's memory, or any agent's own todo list, planner or subagents — use all of those. This is the set
of context documents you end up asking an agent to write anyway, standardised, so it knows where to put
things without being told each time.

There is nothing to learn. You talk to your agent normally; it maintains the files.

## Install

```bash
curl -sSL https://raw.githubusercontent.com/amirkiarafiei/kia-context/main/install.sh | bash
```

or clone and run `./install.sh`. It is interactive, it never overwrites an existing file, and re-running
it is safe.

```
./install.sh                                    interactive
./install.sh --yes --agents claude,cursor       non-interactive
./install.sh --dry-run                          show what would happen
```

It does three things: scaffolds `context/` and `docs/`, writes the harness instructions into `AGENTS.md`
(and `CLAUDE.md` / `GEMINI.md`) between markers, and installs three project-scoped skills for the agents
you pick.

## The three skills

Both you and the agent can invoke them.

| | |
|---|---|
| `/kia-context-init` | Fill it in for the first time. Run once per repository. |
| `/kia-context-help` | What this is and what each file is for, in plain language. |
| `/kia-context-sync` | Catch the files up after work has happened. |

**`init` handles a half-built project too.** It reverse-engineers `ARCHITECTURE.md` and `DESIGN.md` from
the code, infers a rough `PROGRESS.md` and `BRAINSTORM.md` from git history — clearly flagged as
inferred, because commit messages say what changed and almost never why — and asks you a short, optional
set of questions for `GENESIS.md` and `MANIFESTO.md`, which no amount of code reading can answer.
`SEED.md` holds the prompts that started the project; on an existing repo those are gone, and it says so
rather than inventing them.

## What gets installed

```
context/           the agent reads and writes this
  INDEX.md         the map
  genesis/         SEED.md · GENESIS.md          where the project came from
  specs/           MANIFESTO.md · ARCHITECTURE.md · DESIGN.md    the law
  logs/            PROGRESS.md · BRAINSTORM.md   state

docs/              humans read this, and only when someone asks for one
  SOFTWARE_ARCHITECTURE · SYSTEM_ARCHITECTURE · DEPLOYMENT · AUTHENTICATION · SECURITY
```

`context/` is for the agent. `docs/` is for people — written on request, free to carry diagrams and long
prose, and free to go stale, because nothing reads it to do the work.

Delete anything a project does not need. Every layout in every file is a suggestion.

## How it is used

1. **Talk it through** until a decision gets made. The agent records it in `BRAINSTORM.md` — but only
   real decisions, not every exchange.
2. **Decide the milestones.** The agent writes them into `PROGRESS.md` with acceptance criteria.
3. **Work through them** — one at a time, several at once, however suits you. That part is yours.

Nobody fills in a form. The agent maintains these files the way it writes commit messages.

## Loop-friendly

A finished milestone list with acceptance criteria is exactly what an autonomous loop needs: a next task,
a definition of done, and somewhere to record the outcome. `PROGRESS.md` carries its own loop protocol
and circuit breakers, so a loop has somewhere to stop.

That is a property of the format. Nothing here requires a loop.

## The one strict part

Six frontmatter fields on every file — `description`, `authority`, `writes`, `status`, `covers`,
`last_updated`. They are what make a file part of kia-context. Everything below the frontmatter is yours
to reshape, reorder or delete.

Beside them sit seven rules, in `AGENTS.md`, for keeping the documents honest — never renumber, grep
after a rename, never state a rule in two files, and so on. All of them are about maintaining markdown.
None of them tell you how to write code.

## Layout of this repository

```
install.sh          the installer
_template/          the markdown files it copies, plus AGENTS.harness.md
skills/             the three skills
```

MIT.
