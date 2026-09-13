#!/usr/bin/env bash
#
# kia-context — update and migration scenarios
#
#   ./tests/update-scenarios.sh
#
# The installer rewrites files in a repository somebody else owns, so the cases
# that matter are the ones where it must NOT write: damaged markers, a fetch that
# failed halfway, a skill the user has edited. Each scenario builds a throwaway
# project under tmp/ and asserts what is on disk afterwards.

cd "$(dirname "$0")/.." || exit 1
ROOT=$PWD
WORK="$ROOT/tmp/scenarios"
rm -rf "$WORK"; mkdir -p "$WORK"

PASS=0; FAIL=0
if [ -t 1 ]; then GRN=$'\033[32m'; RED=$'\033[31m'; DIM=$'\033[2m'; B=$'\033[1m'; R=$'\033[0m'
else GRN=""; RED=""; DIM=""; B=""; R=""; fi

# install.sh targets bash 3.2 and BSD userland, so the suite that guards it has to
# run there too. These three are the only GNU-isms the scenarios needed.
sed_i() { local e=$1; shift; if sed --version >/dev/null 2>&1; then sed -i "$e" "$@"
          else sed -i '' "$e" "$@"; fi; }
sum()   { if command -v md5sum >/dev/null 2>&1; then md5sum; else md5 -q; fi; }
parents() { # read paths on stdin, print each one's directory
          while IFS= read -r f; do dirname "$f"; done; }

scenario() { printf '\n%s%s%s\n' "$B" "$1" "$R"; }
ok()   { PASS=$((PASS+1)); printf '  %s✓%s %s\n' "$GRN" "$R" "$1"; }
no()   { FAIL=$((FAIL+1)); printf '  %s✗ %s%s\n' "$RED" "$1" "$R"; }
check(){ if [ "$2" = "$3" ]; then ok "$1"; else no "$1 — expected '$3', got '$2'"; fi; }

# install <dir> [extra args...] -> sets RC and OUT
install_into() {
  local d=$1; shift
  OUT=$(NO_COLOR=1 "$ROOT/install.sh" --yes --agents claude --dir "$d" "$@" 2>&1); RC=$?
}
fresh() { local d="$WORK/$1"; rm -rf "$d"; mkdir -p "$d"; (cd "$d" && git init -q .); printf '%s' "$d"; }
# The Skills step prints ".claude/skills/kia-context-init" etc, so a whole-output
# grep for a skill name also matches the install lines. Scope to the closing menu.
next_steps() { echo "$OUT" | sed -n '/Next, in your agent/,$p'; }
mentions()   { echo "$OUT" | grep -c -- "$1"; }

# ---------------------------------------------------------------------------
scenario "1. Fresh install"
D=$(fresh s1); install_into "$D"
check "exit 0" "$RC" "0"
check "reports Installed" "$(echo "$OUT" | grep -c 'Installed\.')" "1"
check "context files written" "$(find "$D/kia-context" -name '*.md' | wc -l | tr -d ' ')" "8"
check "four skills written" "$(find "$D/.claude/skills" -name SKILL.md | wc -l | tr -d ' ')" "4"
check "stamped with a version" "$(grep -c '^harness: kiacontext v' "$D/kia-context/INDEX.md")" "1"
check "suggests init" "$(next_steps | grep -c '/kia-context-init')" "1"
check "does not suggest migrate" "$(next_steps | grep -c '/kia-context-migrate')" "0"

# ---------------------------------------------------------------------------
scenario "2. Idempotent re-run leaves no trace"
BEFORE=$(cd "$D" && find . -path ./.git -prune -o -type f -print | sort | xargs sum 2>/dev/null | sum)
install_into "$D"
AFTER=$(cd "$D" && find . -path ./.git -prune -o -type f -print | sort | xargs sum 2>/dev/null | sum)
check "exit 0" "$RC" "0"
check "nothing changed" "$BEFORE" "$AFTER"
check "no backup files created" "$(find "$D" -name '*.kiacontext-bak' | wc -l | tr -d ' ')" "0"
check "does not suggest init again" "$(next_steps | grep -c '/kia-context-init')" "0"

# ---------------------------------------------------------------------------
scenario "3. A locally edited skill is backed up, never silently lost"
D=$(fresh s3); install_into "$D"
echo "MY PROJECT RULE" >> "$D/.claude/skills/kia-context-sync/SKILL.md"
install_into "$D"
check "exit 0" "$RC" "0"
check "backup exists" "$([ -f "$D/.claude/skills/kia-context-sync/SKILL.md$(echo .kiacontext-bak)" ] && echo yes || echo no)" "yes"
check "backup holds the user's edit" \
  "$(grep -c 'MY PROJECT RULE' "$D/.claude/skills/kia-context-sync/SKILL.md.kiacontext-bak")" "1"
check "live file is ours again" \
  "$(grep -c 'MY PROJECT RULE' "$D/.claude/skills/kia-context-sync/SKILL.md")" "0"
check "the run says so" "$(echo "$OUT" | grep -c 'previous kept at')" "1"

# ---------------------------------------------------------------------------
scenario "4. User content after the block survives, and the block stays put"
D=$(fresh s4); install_into "$D"
printf '\n## My own house rules\n\nNever force-push to main.\n' >> "$D/AGENTS.md"
TAIL_BEFORE=$(tail -1 "$D/AGENTS.md")
# force a refresh by making the on-disk block differ
sed_i '0,/^## kiacontext/s//## kiacontext OLD/' "$D/AGENTS.md"
install_into "$D"
check "exit 0" "$RC" "0"
check "user's rules survived" "$(grep -c 'Never force-push to main' "$D/AGENTS.md")" "1"
check "block did not migrate to EOF" "$(tail -1 "$D/AGENTS.md")" "$TAIL_BEFORE"
check "exactly one begin marker" "$(grep -c 'kiacontext:begin' "$D/AGENTS.md")" "1"
check "backup of the doc kept" "$([ -f "$D/AGENTS.md.kiacontext-bak" ] && echo yes || echo no)" "yes"

# ---------------------------------------------------------------------------
scenario "5. Missing END marker — refuse, do not touch"
D=$(fresh s5); install_into "$D"
printf '\n## My own house rules\n\nNever force-push to main.\n' >> "$D/AGENTS.md"
sed_i '/kiacontext:end/d' "$D/AGENTS.md"
SUM_BEFORE=$(sum < "$D/AGENTS.md")
install_into "$D"
SUM_AFTER=$(sum < "$D/AGENTS.md")
check "exit non-zero" "$([ "$RC" -ne 0 ] && echo yes || echo no)" "yes"
check "file byte-identical" "$SUM_BEFORE" "$SUM_AFTER"
check "user's rules intact" "$(grep -c 'Never force-push to main' "$D/AGENTS.md")" "1"
check "says markers are damaged" "$(echo "$OUT" | grep -c 'markers are damaged')" "1"
check "never claims Installed" "$(echo "$OUT" | grep -c 'Installed\.')" "0"

# ---------------------------------------------------------------------------
scenario "6. Missing BEGIN marker — refuse, no duplicate block"
D=$(fresh s6); install_into "$D"
sed_i '/kiacontext:begin/d' "$D/AGENTS.md"
install_into "$D"
check "exit non-zero" "$([ "$RC" -ne 0 ] && echo yes || echo no)" "yes"
check "no second copy of the block" "$(grep -c "this project's memory" "$D/AGENTS.md")" "1"
check "end markers still 1" "$(grep -c 'kiacontext:end' "$D/AGENTS.md")" "1"

# ---------------------------------------------------------------------------
scenario "7. Two blocks present — refuse"
D=$(fresh s7); install_into "$D"
cat "$D/AGENTS.md" "$D/AGENTS.md" > "$D/AGENTS.dup" && mv "$D/AGENTS.dup" "$D/AGENTS.md"
SUM_BEFORE=$(sum < "$D/AGENTS.md")
install_into "$D"
check "exit non-zero" "$([ "$RC" -ne 0 ] && echo yes || echo no)" "yes"
check "file untouched" "$SUM_BEFORE" "$(sum < "$D/AGENTS.md")"

# ---------------------------------------------------------------------------
scenario "8. Partial fetch failure is reported honestly"
D=$(fresh s8)
mv "$ROOT/_template/kia-context/specs/MANIFESTO.md" "$WORK/MANIFESTO.hold"
install_into "$D"
mv "$WORK/MANIFESTO.hold" "$ROOT/_template/kia-context/specs/MANIFESTO.md"
check "exit non-zero" "$([ "$RC" -ne 0 ] && echo yes || echo no)" "yes"
check "never claims Installed" "$(echo "$OUT" | grep -c 'Installed\.')" "0"
check "names the problem count" "$(echo "$OUT" | grep -c 'Finished with 1 problem')" "1"

# ---------------------------------------------------------------------------
scenario "9. A v0.1 layout is detected and offered the migration"
D=$(fresh s9); mkdir -p "$D/context"; echo "x" > "$D/context/INDEX.md"
install_into "$D" --dry-run
check "detects the old layout" "$(echo "$OUT" | grep -c 'v0.1 layout is already here')" "1"
check "offers the migrate skill" "$([ "$(mentions '/kia-context-migrate')" -ge 1 ] && echo yes || echo no)" "yes"
check "dry run wrote nothing" "$(find "$D/kia-context" -type f 2>/dev/null | wc -l | tr -d ' ')" "0"

# ---------------------------------------------------------------------------
scenario "10. An older stamp is offered the migration; a current one is not"
D=$(fresh s10); install_into "$D"
sed_i 's/^harness: kiacontext v.*/harness: kiacontext v0.2/' "$D/kia-context/INDEX.md"
install_into "$D"
check "behind: suggests migrate" "$(next_steps | grep -c '/kia-context-migrate')" "1"
check "behind: does not suggest init" "$(next_steps | grep -c '/kia-context-init')" "0"
check "stamp NOT bumped by the installer" \
  "$(grep -c 'harness: kiacontext v0.2' "$D/kia-context/INDEX.md")" "1"
install_into "$WORK/s1"
check "current: no migrate nag" "$(next_steps | grep -c '/kia-context-migrate')" "0"

# ---------------------------------------------------------------------------
scenario "11. Dry run never writes, in any state"
D=$(fresh s11)
install_into "$D" --dry-run
check "fresh dry-run: no files" "$(find "$D" -name '*.md' | wc -l | tr -d ' ')" "0"
install_into "$D"
SUM_BEFORE=$(cd "$D" && find . -path ./.git -prune -o -type f -print | sort | xargs sum | sum)
install_into "$D" --dry-run
check "installed dry-run: nothing changed" \
  "$(cd "$D" && find . -path ./.git -prune -o -type f -print | sort | xargs sum | sum)" "$SUM_BEFORE"

# ---------------------------------------------------------------------------
scenario "13. An unwritable target is reported, not claimed as done"
D=$(fresh s13); install_into "$D"
echo "MY PROJECT RULE" >> "$D/.claude/skills/kia-context-help/SKILL.md"
chmod 555 "$D/.claude/skills/kia-context-help"
install_into "$D"
chmod 755 "$D/.claude/skills/kia-context-help"
check "exit non-zero" "$([ "$RC" -ne 0 ] && echo yes || echo no)" "yes"
check "never claims Installed" "$(echo "$OUT" | grep -c 'Installed\.')" "0"
check "says it was left untouched" "$(echo "$OUT" | grep -c 'Left untouched')" "1"
check "the user's edit is still there" \
  "$(grep -c 'MY PROJECT RULE' "$D/.claude/skills/kia-context-help/SKILL.md")" "1"

# ---------------------------------------------------------------------------
scenario "14. A marker inside a fenced code block is treated as damage, not as ours"
D=$(fresh s14); install_into "$D"
printf '\n```\n%s\n```\n' '<!-- kiacontext:begin -->' >> "$D/AGENTS.md"
SUM_BEFORE=$(sum < "$D/AGENTS.md")
install_into "$D"
check "exit non-zero" "$([ "$RC" -ne 0 ] && echo yes || echo no)" "yes"
check "file untouched" "$SUM_BEFORE" "$(sum < "$D/AGENTS.md")"

# ---------------------------------------------------------------------------
scenario "15. A repeated run never destroys the only backup"
D=$(fresh s15); install_into "$D"
echo "USER EDIT ONE" >> "$D/.claude/skills/kia-context-help/SKILL.md"
install_into "$D"; install_into "$D"; install_into "$D"
check "backup still holds the original edit" \
  "$(grep -c 'USER EDIT ONE' "$D/.claude/skills/kia-context-help/SKILL.md.kiacontext-bak")" "1"

# ---------------------------------------------------------------------------
scenario "16. A dry run predicts the real run's failure"
D=$(fresh s16); install_into "$D"
sed_i '/kiacontext:end/d' "$D/AGENTS.md"
install_into "$D" --dry-run
check "damaged: dry run exits non-zero" "$([ "$RC" -ne 0 ] && echo yes || echo no)" "yes"
check "damaged: says it would stop a real run" "$(echo "$OUT" | grep -c 'would stop a real run')" "1"
D=$(fresh s16b); install_into "$D" --dry-run
check "healthy: dry run exits 0" "$RC" "0"

# ---------------------------------------------------------------------------
scenario "17. File modes survive a refresh"
D=$(fresh s17); install_into "$D"
mode() { if stat -c '%a' "$1" >/dev/null 2>&1; then stat -c '%a' "$1"; else stat -f '%Lp' "$1"; fi; }
UMASK_DEFAULT=$(printf '%o' $(( 0666 & ~$(umask) )))
check "fresh AGENTS.md at the umask default" "$(mode "$D/AGENTS.md")" "$UMASK_DEFAULT"
check "fresh SKILL.md at the umask default" \
  "$(mode "$D/.claude/skills/kia-context-help/SKILL.md")" "$UMASK_DEFAULT"
sed_i '0,/^## kiacontext/s//## kiacontext OLD/' "$D/AGENTS.md"
echo "EDIT" >> "$D/.claude/skills/kia-context-help/SKILL.md"
chmod 640 "$D/.claude/skills/kia-context-help/SKILL.md"
install_into "$D"
check "AGENTS.md keeps its mode" "$(mode "$D/AGENTS.md")" "$UMASK_DEFAULT"
check "a user's own mode is preserved" \
  "$(mode "$D/.claude/skills/kia-context-help/SKILL.md")" "640"

# ---------------------------------------------------------------------------
scenario "18. A v0.1 project is not given a stamp it has not earned"
D=$(fresh s18); mkdir -p "$D/context/logs"
printf -- '---\nharness: kiacontext v0.1\n---\n# INDEX\n' > "$D/context/INDEX.md"
printf -- '# PROGRESS\n- [x] real work\n' > "$D/context/logs/PROGRESS.md"
install_into "$D"
check "exit 0" "$RC" "0"
check "no kia-context/ scaffolded" "$([ -d "$D/kia-context" ] && echo yes || echo no)" "no"
check "says why it skipped" "$(echo "$OUT" | grep -c 'skipped until context/ is migrated')" "8"
check "docs/ still scaffolded" "$([ -d "$D/docs" ] && echo yes || echo no)" "yes"
check "instructions block still installed" "$([ -f "$D/AGENTS.md" ] && echo yes || echo no)" "yes"
check "migrate skill still installed" \
  "$([ -f "$D/.claude/skills/kia-context-migrate/SKILL.md" ] && echo yes || echo no)" "yes"
check "v0.1 content untouched" "$(grep -c 'real work' "$D/context/logs/PROGRESS.md")" "1"
# What the migrator reads is kia-context/INDEX.md. It must not exist, so the only
# stamp in the project stays the honest v0.1 one in context/INDEX.md.
# (The migrate SKILL.md mentions v0.3 in its own decision table — that is not a stamp.)
check "no kia-context/INDEX.md for the migrator to misread" \
  "$([ -f "$D/kia-context/INDEX.md" ] && echo yes || echo no)" "no"
check "the only project stamp still reads v0.1" \
  "$(grep -rh '^harness: kiacontext' "$D/context" "$D/kia-context" 2>/dev/null | sort -u | tr -d ' ')" \
  "harness:kiacontextv0.1"

# ---------------------------------------------------------------------------
scenario "19. A failed temp dir must not empty the docs it says it left alone"
D=$(fresh s19); install_into "$D"
printf '\n## My own house rules\n\nNever force-push to main.\n' >> "$D/AGENTS.md"
sed_i '0,/^## kiacontext/s//## kiacontext OLD/' "$D/AGENTS.md"
SIZE_BEFORE=$(wc -c < "$D/AGENTS.md")
OUT=$(TMPDIR=/nonexistent-dir NO_COLOR=1 "$ROOT/install.sh" --yes --agents claude --dir "$D" 2>&1); RC=$?
check "exit non-zero" "$([ "$RC" -ne 0 ] && echo yes || echo no)" "yes"
check "AGENTS.md not truncated" "$(wc -c < "$D/AGENTS.md")" "$SIZE_BEFORE"
check "user's rules survive" "$(grep -c 'force-push' "$D/AGENTS.md")" "1"
check "CLAUDE.md not truncated" "$([ -s "$D/CLAUDE.md" ] && echo yes || echo no)" "yes"
# both docs and all four skills report it, so just require it to be said
check "says why" \
  "$([ "$(echo "$OUT" | grep -c 'no usable temp directory')" -ge 2 ] && echo yes || echo no)" "yes"

# ---------------------------------------------------------------------------
scenario "20. An upstream release must not overwrite the user's edit in the backup"
D=$(fresh s20); install_into "$D"
SK="$D/.claude/skills/kia-context-help/SKILL.md"
UP="$ROOT/skills/kia-context-help/SKILL.md"
cp "$UP" "$WORK/help.orig"
echo "IRREPLACEABLE USER RULE" >> "$SK"
install_into "$D"                                  # backup captures the user's edit
echo "upstream v2" >> "$UP"; install_into "$D"      # a release changes our file
echo "upstream v3" >> "$UP"; install_into "$D"      # and another
cp "$WORK/help.orig" "$UP"; rm -f "$WORK/help.orig"
check "the user's rule still exists somewhere" \
  "$([ "$(grep -rl 'IRREPLACEABLE USER RULE' "$D" 2>/dev/null | wc -l)" -ge 1 ] && echo yes || echo no)" "yes"
check "repo's own skill restored" "$(grep -c 'upstream v' "$UP")" "0"

# ---------------------------------------------------------------------------
scenario "21. A NUL byte must not misdiagnose intact markers"
D=$(fresh s21); install_into "$D"
printf '\n## Notes\nbinary paste: \000 oops\n' >> "$D/AGENTS.md"
install_into "$D"
check "no raw shell error leaks" "$(echo "$OUT" | grep -c 'integer expression expected')" "0"
check "markers read correctly, not called damaged" "$(echo "$OUT" | grep -c 'markers are damaged')" "0"

# ---------------------------------------------------------------------------
scenario "22. --skills-dir is not word-split or globbed"
D=$(fresh s22)
NO_COLOR=1 "$ROOT/install.sh" --yes --agents other --skills-dir "my skills" --dir "$D" >/dev/null 2>&1
check "a path with a space stays one directory" \
  "$(find "$D/my skills" -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')" "4"
D=$(fresh s22b)
NO_COLOR=1 "$ROOT/install.sh" --yes --agents other --skills-dir '*' --dir "$D" >/dev/null 2>&1
check "a glob is not expanded against the cwd" \
  "$(find "$D" -name SKILL.md | wc -l | tr -d ' ')" "4"

# ---------------------------------------------------------------------------
scenario "23. A truncated download is refused, not installed"
# A fetch can return 200 and still be cut short; in remote mode that would put half
# the instructions into every agent's context and report success.
D=$(fresh s23)
cp "$ROOT/_template/AGENTS.harness.md" "$WORK/h.bak"
head -20 "$WORK/h.bak" > "$ROOT/_template/AGENTS.harness.md"
install_into "$D"
cp "$WORK/h.bak" "$ROOT/_template/AGENTS.harness.md"
check "truncated block: exit non-zero" "$([ "$RC" -ne 0 ] && echo yes || echo no)" "yes"
check "truncated block: says why" "$(echo "$OUT" | grep -c 'block is incomplete')" "1"
check "truncated block: nothing written" "$([ -f "$D/AGENTS.md" ] && echo yes || echo no)" "no"

D=$(fresh s23b)
cp "$ROOT/skills/kia-context-sync/SKILL.md" "$WORK/s.bak"
head -3 "$WORK/s.bak" > "$ROOT/skills/kia-context-sync/SKILL.md"
install_into "$D"
cp "$WORK/s.bak" "$ROOT/skills/kia-context-sync/SKILL.md"; rm -f "$WORK/s.bak" "$WORK/h.bak"
check "truncated skill: exit non-zero" "$([ "$RC" -ne 0 ] && echo yes || echo no)" "yes"
check "truncated skill: not written" \
  "$([ -f "$D/.claude/skills/kia-context-sync/SKILL.md" ] && echo yes || echo no)" "no"
check "truncated skill: the other three still land" \
  "$(find "$D/.claude/skills" -name SKILL.md | wc -l | tr -d ' ')" "3"

check "the end sentinel never reaches the installed block" \
  "$(grep -c 'block-end' "$WORK/s1/AGENTS.md")" "0"

# ---------------------------------------------------------------------------
scenario "12. All agent slugs still install where they should"
for pair in claude:.claude cursor:.cursor gemini:.gemini codex:.agents copilot:.copilot \
            opencode:.opencode qoder:.qoder kiro:.kiro hermes:.hermes antigravity:.agents \
            pi:.pi omp:.omp grok:.grok; do
  slug=${pair%%:*}; want=${pair##*:}
  d="$WORK/ag-$slug"; rm -rf "$d"; mkdir -p "$d"
  NO_COLOR=1 "$ROOT/install.sh" --yes --agents "$slug" --dir "$d" >/dev/null 2>&1
  got=$(find "$d" -name SKILL.md | parents | sed "s|$d/||;s|/skills/.*||" | sort -u)
  n=$(find "$d" -name SKILL.md | wc -l | tr -d ' ')
  if [ "$got" = "$want" ] && [ "$n" = "4" ]; then ok "$slug -> $want (4 skills)"
  else no "$slug -> got '$got' ($n skills), want '$want' (4)"; fi
done

# ---------------------------------------------------------------------------
printf '\n%s%d passed, %d failed%s\n\n' "$([ "$FAIL" -eq 0 ] && printf '%s' "$GRN" || printf '%s' "$RED")" \
  "$PASS" "$FAIL" "$R"
[ "$FAIL" -eq 0 ]
