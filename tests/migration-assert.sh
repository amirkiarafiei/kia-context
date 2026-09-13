#!/usr/bin/env bash
#
# Asserts the end state of a v0.2 -> v0.3 migration.
#
#   ./tests/migration-assert.sh <dir>
#
# Run it against a fixture that has been migrated. Everything here is checkable
# without knowing HOW the agent did it — the point is the state it left behind.

set -u
D=${1:?usage: migration-assert.sh <dir>}
L="$D/kia-context/logs"
PASS=0; FAIL=0
if [ -t 1 ]; then GRN=$'\033[32m'; RED=$'\033[31m'; B=$'\033[1m'; R=$'\033[0m'
else GRN=""; RED=""; B=""; R=""; fi
ok(){ PASS=$((PASS+1)); printf '  %s✓%s %s\n' "$GRN" "$R" "$1"; }
no(){ FAIL=$((FAIL+1)); printf '  %s✗ %s%s\n' "$RED" "$1" "$R"; }
is(){ if [ "$2" = "$3" ]; then ok "$1"; else no "$1 — expected '$3', got '$2'"; fi; }

printf '\n%sMigrated state%s\n' "$B" "$R"

# --- the inversion ---------------------------------------------------------
is "PROGRESS.md exists" "$([ -f "$L/PROGRESS.md" ] && echo yes || echo no)" "yes"
is "PROGRESS.md is the ACTIVE part" \
   "$(sed -n 's/^status:[[:space:]]*//p' "$L/PROGRESS.md" 2>/dev/null | head -1)" "active"
is "history moved to PROGRESS_1.md" "$([ -f "$L/PROGRESS_1.md" ] && echo yes || echo no)" "yes"
is "PROGRESS_1.md is closed" \
   "$(sed -n 's/^status:[[:space:]]*//p' "$L/PROGRESS_1.md" 2>/dev/null | head -1)" "closed"
is "PROGRESS_2.md is gone" "$([ -e "$L/PROGRESS_2.md" ] && echo present || echo gone)" "gone"

# --- nothing lost ----------------------------------------------------------
is "M1 still recorded" "$(grep -rlc 'Milestone M1:' "$L"/PROGRESS*.md >/dev/null 2>&1 && grep -rh 'Milestone M1:' "$L"/PROGRESS*.md | wc -l | tr -d ' ')" "1"
is "M22 still recorded" "$(grep -rh 'Milestone M22:' "$L"/PROGRESS*.md | wc -l | tr -d ' ')" "1"
is "all 22 milestones survive" \
   "$(grep -rh '^## 🏁 Milestone M' "$L"/PROGRESS*.md | wc -l | tr -d ' ')" "22"
is "numbering never restarted" \
   "$(grep -rho 'Milestone M[0-9]*' "$L"/PROGRESS*.md | sed 's/.*M//' | sort -n | uniq | wc -l | tr -d ' ')" "22"

# --- the procedure is back in the active file ------------------------------
is "active part carries The loop" "$(grep -c '## The loop' "$L/PROGRESS.md")" "1"
is "active part carries Circuit breakers" "$(grep -c '## Circuit breakers' "$L/PROGRESS.md")" "1"
is "procedure not duplicated across parts" \
   "$(grep -rh '## The loop' "$L"/PROGRESS*.md | wc -l | tr -d ' ')" "1"

# --- the drifted milestones ------------------------------------------------
# M17 had its deliverables as a numbered list: mechanically recoverable.
M17=$(awk '/^## 🏁 Milestone M17:/{f=1} /^## 🏁 Milestone M18:/{f=0} f' "$L/PROGRESS.md")
is "M17 deliverables became checkboxes" \
   "$(printf '%s' "$M17" | grep -c '^- \[')" "3"
# M18-M22 had no deliverables at all: must NOT be invented.
M19=$(awk '/^## 🏁 Milestone M19:/{f=1} /^## 🏁 Milestone M20:/{f=0} f' "$L/PROGRESS.md")
is "M19 deliverables were not invented" \
   "$([ "$(printf '%s' "$M19" | grep -c '^- \[')" -eq 0 ] && echo none || echo invented)" "none"

# --- the stamp, last -------------------------------------------------------
is "stamp bumped to v0.3" \
   "$(sed -n 's/^harness:[[:space:]]*kiacontext[[:space:]]*//p' "$D/kia-context/INDEX.md" | head -1)" "v0.3"
is "INDEX phase table points at the active file" \
   "$(grep -c 'logs/PROGRESS.md' "$D/kia-context/INDEX.md")" "1"
is "INDEX no longer points at PROGRESS_2" \
   "$(grep -c 'PROGRESS_2' "$D/kia-context/INDEX.md")" "0"

# --- no stale references ---------------------------------------------------
# Only valid because THIS fixture had exactly two parts, so PROGRESS_2 was renamed
# away. With three or more parts a PROGRESS_2.md legitimately keeps its name, and
# its references with it — do not generalise this assertion.
is "no dangling PROGRESS_2 references (two-part fixture)" \
   "$(grep -rn 'PROGRESS_2' "$D" --exclude-dir=.git --exclude-dir=.claude 2>/dev/null | wc -l | tr -d ' ')" "0"

printf '\n%s%d passed, %d failed%s\n\n' \
  "$([ "$FAIL" -eq 0 ] && printf '%s' "$GRN" || printf '%s' "$RED")" "$PASS" "$FAIL" "$R"
[ "$FAIL" -eq 0 ]
