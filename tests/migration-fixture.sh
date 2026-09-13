#!/usr/bin/env bash
#
# Builds a throwaway project in the exact state that made this migration
# necessary: kiacontext v0.2, PROGRESS split the old way round, so the operating
# procedure sits in the closed part and the milestones written after the split
# drifted out of shape.
#
#   ./tests/migration-fixture.sh <dir>

set -u
D=${1:?usage: migration-fixture.sh <dir>}
rm -rf "$D"; mkdir -p "$D/kia-context/logs" "$D/kia-context/specs" "$D/kia-context/genesis"
(cd "$D" && git init -q . && git config user.email t@t && git config user.name t)

cat > "$D/kia-context/INDEX.md" <<'EOF'
---
description: >
  The map of the context harness.
  NOT here: any rule, any decision, any technical detail.
authority: map
writes: agent, when files move
status: active
covers: the whole harness
last_updated: "2026-07-02"
harness: kiacontext v0.2
---

# 🗺️ INDEX

## 2. Phases

| Phase | Span | State | Log |
|---|---|---|---|
| Prototype | 2026-05-02 → 2026-07-01 | closed | `logs/PROGRESS.md` |
| Beta | 2026-07-02 → | **active** | `logs/PROGRESS_2.md` |
EOF

# --- part one: closed, and holding the procedure everybody needs ---------
{
cat <<'EOF'
---
description: >
  The execution log and the working memory of the project.
  NOT here: why a choice was made (BRAINSTORM.md).
authority: state
writes: agent, every session
status: closed
covers: "Prototype, 2026-05-02 → 2026-07-01 — M1 to M15"
last_updated: "2026-07-01"
---

# 📈 PROGRESS — What we are building

> **← Previous:** none. This is part one.
> **Next →** `PROGRESS_2.md`

## The loop

1. Take the first unchecked deliverable (`- [ ]`) under the active milestone.
2. Build it. Verify it against its **acceptance criteria**.
3. **Pass:** mark `[x]`, write a one or two sentence **Report**, move on.
4. **Fail:** apply the circuit breakers. Do **not** mark `[x]`.

## Circuit breakers

- **Three attempts.** Three consecutive failed verification passes and you stop.
- **Then:** revert, mark the deliverable `[BLOCKED]`, write one paragraph, halt for a human.
- **No tampering, ever.** Never modify a test or an acceptance criterion to force a pass.

## Milestones

EOF
for m in $(seq 1 15); do
cat <<EOF
## 🏁 Milestone M$m: Prototype step $m

**Target.** The $m-th slice of the prototype works end to end.

### Deliverables

- [x] **Thing $m.a** — the first half
- [x] **Thing $m.b** — the second half

### Acceptance criteria

1. Running the $m-th slice exits zero.

### Report — 2026-0$(( (m % 2) + 5 ))-1$((m % 9))

Built and verified.

EOF
done
printf '> **← Previous:** none.\n> **Next →** `PROGRESS_2.md`\n'
} > "$D/kia-context/logs/PROGRESS.md"

# --- part two: active, procedure-free, and drifting ----------------------
{
cat <<'EOF'
---
description: >
  The execution log and the working memory of the project.
  NOT here: why a choice was made (BRAINSTORM.md).
authority: state
writes: agent, every session
status: active
covers: "Beta, 2026-07-02 onward — M16 onward"
last_updated: "2026-09-01"
---

# 📈 PROGRESS — What we are building (part two)

> **← Previous:** `PROGRESS.md`
> **Next →** none yet.

## Milestones

## 🏁 Milestone M16: Import pipeline

**Target.** Files land in the store without manual steps.

### Deliverables

- [x] **Watcher** — picks up new files
- [ ] **Parser** — reads the two formats
- [ ] **Store writer** — idempotent upsert
- [ ] **Retry** — three attempts then park
- [ ] **Metrics** — count and duration
- [x] **Docs** — a paragraph in the README
- [ ] **Alerting** — page on repeated failure

### Report — 2026-07-14

M16 is done. The pipeline runs nightly.

## 🏁 Milestone M17: Search

**Target.** Users can find a record by name or id.

### Deliverables

1. Index builder
2. Query parser
3. Result ranking

### Report — 2026-07-29

Search shipped behind a flag.

## 🏁 Milestone M18: Permissions

**Target.** Only the owning team can edit a record.

Built the role table and the check in the write path. Shipped 2026-08-05.

## 🏁 Milestone M19: Audit log

Every write is recorded with actor and timestamp. Shipped 2026-08-12.

## 🏁 Milestone M20: Export

CSV and JSON export from the record list. Shipped 2026-08-20.

## 🏁 Milestone M21: Rate limiting

Token bucket per API key. Shipped 2026-08-26.

## 🏁 Milestone M22: Dashboard

Counts and error rate on one page. Shipped 2026-09-01.

> **← Previous:** `PROGRESS.md`
> **Next →** none yet.
EOF
} > "$D/kia-context/logs/PROGRESS_2.md"

cat > "$D/kia-context/logs/BRAINSTORM.md" <<'EOF'
---
description: >
  The decision log.
  NOT here: the resulting rule itself.
authority: background
writes: agent, whenever a decision is made
status: active
covers: "Beta, 2026-05-02 onward — D1 onward"
last_updated: "2026-08-26"
---

# 🧠 BRAINSTORM

### D1 · Nightly batch over streaming — 2026-05-20

**Chose:** nightly batch. **Rejected:** streaming, because the source drops for hours at a time.
EOF

printf 'placeholder\n' > "$D/kia-context/specs/MANIFESTO.md"
printf '# demo app\n' > "$D/README.md"
printf 'print("hi")\n' > "$D/app.py"
(cd "$D" && git add -A >/dev/null 2>&1 && git commit -qm "project at kiacontext v0.2" >/dev/null 2>&1)
echo "fixture built at $D"
