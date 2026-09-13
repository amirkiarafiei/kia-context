![kia-context — loop-friendly project context](assets/banner.jpeg)

# Kia Context

**A Loop Engineering-friendly Kit of Markdown Files to Maintain Project Context for/by Agents. Nothing More!**

Not a framework. Not a workflow. Not a competitor to [spec-kit](https://github.com/github/spec-kit),
Claude's memory, or your agent's own features. Use all of those. What I provide are the
context docs you end up asking an agent to write anyway — same names, same places, so it knows where
things go without being told every session.

There is nothing to learn. You talk to your agent normally; it keeps the files up to date.

## Quick Install

```bash
curl -sSL https://raw.githubusercontent.com/amirkiarafiei/kia-context/main/install.sh | bash
```



## How to Use

![Flow](assets/flow.png)

Sorry I just lied. There is one small thing you need to learn:

1. **Talk to your Agent**: Brainstorm features, design architecture, and make key decisions as usual.
2. **Define milestones:** Establish your implementation plan. The agent records each milestone and its acceptance criteria in `PROGRESS.md`.
3. **Loop over the milestones:** Work through them sequentially or in batches, whichever suits your workflow — one at a time, several at once.

The agent updates the necessary files the way it writes commit messages.

## Context System

Eight files under `kia-context/`. The agent reads and writes all of them.


| File                    | What it holds                                                                                                                                                       |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `INDEX.md`              | The map. What every other file is, which era it covers, and which one to open for a given question. Read first.                                                     |
| `genesis/SEED.md`       | The first prompts that started the project, lightly cleaned. Written once, then left alone.                                                                         |
| `genesis/GENESIS.md`    | Why the project exists — what happened that made it start, who it is for, and what was deliberately left out on day one.                                            |
| `specs/MANIFESTO.md`    | What the product is, and the numbered rules it may not break. Plain English, no jargon; this is the one people read.                                                |
| `specs/ARCHITECTURE.md` | How it actually works — the things it deals with, the states they move through, the rules it enforces, and the stack underneath.                                    |
| `specs/DESIGN.md`       | The design system in [DESIGN.md](https://github.com/google-labs-code/design.md) format — tokens plus the reasoning behind them. Delete it if there is no interface. |
| `logs/PROGRESS.md`      | Milestones, their deliverables and acceptance criteria, and a short report when each one closes. Where the agent looks to find the next thing to build.             |
| `logs/BRAINSTORM.md`    | Numbered decisions and open questions. Why an option was chosen and what was rejected — so nobody re-argues it in three months.                                     |


Beside them, `docs/` holds human-facing write-ups — software and system architecture, deployment,
authentication, security. Those are written **only when someone asks for one**, may hold diagrams and long
text, and are free to go out of date, because nothing reads them to do the work.

Delete whatever your project does not need. Every layout in every file is a suggestion; only the
frontmatter is fixed.

## Skills

You can run them, and so can the agent.


|                     | When                                                                                                                                                                                                                                                                                                 |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/kia-context-init` | Once per repo, straight after installing. Works on a half-built project too: it reads your code for `ARCHITECTURE.md` and `DESIGN.md`, drafts `PROGRESS.md` and `BRAINSTORM.md` from git history and flags them as inferred, and asks you a few short questions for `GENESIS.md` and `MANIFESTO.md`. |
| `/kia-context-help` | Any time you or the agent are unsure what a file is for, or where something should be written down.                                                                                                                                                                                                  |
| `/kia-context-sync` | After a stretch of work, before a handover, or whenever the files have fallen behind what the code actually does.                                                                                                                                                                                    |
| `/kia-context-migrate` | After re-running the installer on a project that already had kiacontext, when it says this project is behind. Applies only what changed since your version. |




## Loop-engineering-friendly

A finished milestone list with acceptance criteria is what an autonomous loop needs: a next task, a
definition of done, and a place to write the result. `PROGRESS.md` ships with its own loop protocol and
circuit breakers, so the loop knows when to stop.

That comes from the format. Nothing here needs a loop.

## Installation

The one-liner at the top is the fast path. To read the script before running it, clone the repo and run
`./install.sh`. Either way it asks one question — which agents work in this repo — and is safe to run
again. It never touches a context file you already have, and anything of ours that it does replace is
copied to `*.kiacontext-bak` first.

```
./install.sh                                    interactive
./install.sh --yes --agents claude,cursor       non-interactive
./install.sh --dry-run                          show what it would do
```

It does three things: creates `kia-context/` and `docs/`, adds the agent instructions to `AGENTS.md` (and
`CLAUDE.md` / `GEMINI.md`) inside markers so a re-run replaces them instead of adding a second copy, and
installs four project-scoped skills for the agents you pick.

## Updating

Run the installer again. That is the whole update path, and it is safe by design:

| What | Happens on a re-run |
| ---- | ------------------- |
| `kia-context/`, `docs/` | left alone — they hold your project, not ours |
| the `AGENTS.md` block | replaced **in place**, previous copy kept at `AGENTS.md.kiacontext-bak` |
| the skills | replaced, previous copy kept at `SKILL.md.kiacontext-bak` |

A backup is written only when the content is actually about to change, so an
unchanged re-run leaves nothing behind. **An existing backup is never overwritten** —
later ones become `.kiacontext-bak.1`, `.kiacontext-bak.2`. That matters more than it
sounds: the first backup is the one holding whatever you changed, and a single slot
would let the next routine update replace your edit with a copy of our own previous
version. Delete them whenever you have looked.

If the markers around the block have been damaged — one of the pair deleted, or the block pasted twice —
the installer **refuses to touch that file** and tells you what to repair. Rewriting it from a half-open
marker would take your surrounding text with it. Nothing is reported as installed unless it was actually
written: if any part fails, the run says so and exits non-zero rather than printing a green tick.

When the harness itself changes shape, your context files need moving, and only an agent can do that
sensibly — these are prose documents, not a schema. So the installer reads the version this project is
stamped with (`harness:` in `kia-context/INDEX.md`) and, if it is behind, points you at
`/kia-context-migrate`. That skill applies only the changes since your version, moves content rather than
recreating it, and updates the stamp **last** — so a half-applied migration never looks finished.

### Agents it knows

Each one gets the four skills in the directory its own vendor documents. `AGENTS.md` is always written,
and every agent added in v0.2 reads it, so none of them needs an instruction file of its own. Claude Code
and Gemini CLI also get `CLAUDE.md` and `GEMINI.md`, since those are what they read first.

| Agent | Slug | Skills go in |
| ----- | ---- | ------------ |
| Claude Code | `claude` | `.claude/skills/` |
| Cursor | `cursor` | `.cursor/skills/` |
| Gemini CLI | `gemini` | `.gemini/skills/` |
| Codex | `codex` | `.agents/skills/` |
| GitHub Copilot | `copilot` | `.copilot/skills/` |
| OpenCode | `opencode` | `.opencode/skills/` |
| Qoder | `qoder` | `.qoder/skills/` |
| Kiro | `kiro` | `.kiro/skills/` |
| Hermes Agent | `hermes` | `.hermes/skills/` |
| Antigravity | `antigravity` | `.agents/skills/` |
| Pi | `pi` | `.pi/skills/` |
| Oh My Pi | `omp` | `.omp/skills/` |
| Grok | `grok` | `.grok/skills/` |

`.agents/skills/` is a shared convention rather than one vendor's. Codex and Antigravity use it as their
primary directory, so picking both installs one copy instead of two. Hermes, Pi and Oh My Pi read it as
well, but the installer writes each of them the directory its own vendor documents — so those get a copy
each, and moving them to the shared one is your call, not the installer's.

**Hermes and Pi ignore project skills until the project is trusted.** The installer says so when you
pick either; Hermes uses `hermes skills trust`, Pi prompts on first run. Oh My Pi has no such gate.

Anything else: pick **Other** and give it a path, or pass `--skills-dir`.

## Naming Philosophy

**Kia** as in Amirkia. Also as in the car.

Kia builds cars that are genuinely good without being the best or the most expensive. Nobody buys one
expecting a Ferrari, and nobody regrets it either. It starts every morning, it does the job, and everyone
is happy with it. It has never pretended to be a Rolls-Royce.

Same here. This is not competing with [spec-kit](https://github.com/github/spec-kit) or
[Superpowers](https://github.com/obra/superpowers). Those are doing something more ambitious. Kia Context is just a good way to maitain project context. Simple, easy to understand, and enough.

Nothing more.

## Layout of this repository

```
install.sh          the installer
_template/          the markdown files it copies, plus AGENTS.harness.md
skills/             the four skills
tests/              update and migration scenarios — ./tests/update-scenarios.sh
```

MIT.