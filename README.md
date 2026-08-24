# kia-context

**A Loop Engineering-friendly  Kit of Markdown Files to Maintain Project Context for/by Agents. Nothing More!**

Not a framework. Not a workflow. Not a competitor to [spec-kit](https://github.com/github/spec-kit),
Claude's memory, or your agent's own features. Use all of those. What I provide are the
context docs you end up asking an agent to write anyway — same names, same places, so it knows where
things go without being told every session.

There is nothing to learn. You talk to your agent normally; it keeps the files up to date.

## How to Use

Sorry I just lied. There is one small thing you need to learn:

1. **Talk to your Agent**: Brainstorm features, design architecture, and make key decisions as usual.
2. **Define milestones:** Establish your implementation plan. The agent records each milestone and its acceptance criteria in
3. **Loop over the Milestones** Work through the milestones sequentially or in batches based on your preferred workflow — one at a time, several at once, however suits you. 

The agent updates the necessary files the way it writes commit messages.

## Install

```bash
curl -sSL https://raw.githubusercontent.com/amirkiarafiei/kia-context/main/install.sh | bash
```

Or clone the repo and run `./install.sh`. It asks a few questions, never overwrites a file you already
have, and is safe to run again.

```
./install.sh                                    interactive
./install.sh --yes --agents claude,cursor       non-interactive
./install.sh --dry-run                          show what it would do
```

It does three things: creates `context/` and `docs/`, adds the agent instructions to `AGENTS.md` (and
`CLAUDE.md` / `GEMINI.md`) inside markers so a re-run replaces them instead of adding a second copy, and
installs three project-scoped skills for the agents you pick.

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

`context/` is for the agent. `docs/` is for people — written when someone asks, free to hold diagrams and
long text, and free to go out of date, because nothing reads it to do the work.

Delete whatever your project does not need. Every layout in every file is a suggestion.

## The three skills

You can run them, and so can the agent.

| | |
|---|---|
| `/kia-context-init` | Fill everything in the first time. Run once per repo. |
| `/kia-context-help` | What this is, and what each file is for. |
| `/kia-context-sync` | Catch the files up after some work is done. |

**`init` works on a half-built project too.** It reads your code to write `ARCHITECTURE.md` and
`DESIGN.md`. It reads git history to draft `PROGRESS.md` and `BRAINSTORM.md`, and flags both as inferred
— commit messages tell you what changed, almost never why. For `GENESIS.md` and `MANIFESTO.md` it asks
you a few short questions, because no amount of code reading answers them. `SEED.md` holds the prompts
that started the project; on an existing repo those chats are gone, and it says so instead of making
them up.

## Loop-engineering-friendly

A finished milestone list with acceptance criteria is what an autonomous loop needs: a next task, a
definition of done, and a place to write the result. `PROGRESS.md` ships with its own loop protocol and
circuit breakers, so the loop knows when to stop.

That comes from the format. Nothing here needs a loop.

## Layout of this repository

```
install.sh          the installer
_template/          the markdown files it copies, plus AGENTS.harness.md
skills/             the three skills
```

MIT.
