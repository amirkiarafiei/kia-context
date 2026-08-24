#!/usr/bin/env bash
#
# kiacontext — interactive installer
#
#   Local:  ./install.sh
#   Remote: curl -sSL https://raw.githubusercontent.com/amirkiarafiei/kia-context/main/install.sh | bash
#
# What it does, and nothing else:
#   1. scaffolds context/ and docs/ into this repository, never overwriting a file
#   2. writes the harness instructions into AGENTS.md (and CLAUDE.md / GEMINI.md), between markers
#   3. installs three project-scoped skills for the agents you pick
#
# Portability: targets bash 3.2 (macOS default) — no associative arrays, no mapfile, no ${x,,}.
# All input is read from /dev/tty so it still works when piped from curl.

set -o pipefail

REPO_RAW_URL="https://raw.githubusercontent.com/amirkiarafiei/kia-context/main"
VERSION="v0.1"

BEGIN_MARK="<!-- kiacontext:begin -->"
END_MARK="<!-- kiacontext:end -->"

# ------------------------------------------------------------------ data ---

# Agents, their PROJECT-scoped skills directory, and the instruction file they read.
# Only Claude Code's path is documented by its vendor; the rest follow the same
# convention. Pick "Other" if yours differs.
AGENT_NAMES=(
  "Claude Code" "Cursor" "Gemini CLI" "Codex" "GitHub Copilot"
  "OpenCode" "Qoder" "Kiro" "Other (custom path)"
)
AGENT_SLUGS=(
  "claude" "cursor" "gemini" "codex" "copilot"
  "opencode" "qoder" "kiro" "other"
)
AGENT_SKILL_DIRS=(
  ".claude/skills" ".cursor/skills" ".gemini/skills" ".agents/skills" ".copilot/skills"
  ".opencode/skills" ".qoder/skills" ".kiro/skills" ""
)
AGENT_DOCS=(
  "CLAUDE.md" "AGENTS.md" "GEMINI.md" "AGENTS.md" "AGENTS.md"
  "AGENTS.md" "AGENTS.md" "AGENTS.md" "AGENTS.md"
)

# Files the template ships. Destination is the path with "_template/" removed.
TEMPLATE_FILES=(
  "_template/context/INDEX.md"
  "_template/context/genesis/SEED.md"
  "_template/context/genesis/GENESIS.md"
  "_template/context/specs/MANIFESTO.md"
  "_template/context/specs/ARCHITECTURE.md"
  "_template/context/specs/DESIGN.md"
  "_template/context/logs/PROGRESS.md"
  "_template/context/logs/BRAINSTORM.md"
  "_template/docs/SOFTWARE_ARCHITECTURE.md"
  "_template/docs/SYSTEM_ARCHITECTURE.md"
  "_template/docs/DEPLOYMENT.md"
  "_template/docs/AUTHENTICATION.md"
  "_template/docs/SECURITY.md"
)
SKILLS=( "kia-context-help" "kia-context-init" "kia-context-sync" )

# ---------------------------------------------------------------- output ---

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  B=$'\033[1m'; R=$'\033[0m'; DIM=$'\033[2m'
  GRN=$'\033[32m'; YEL=$'\033[33m'; RED=$'\033[31m'; CYA=$'\033[36m'
else
  B=""; R=""; DIM=""; GRN=""; YEL=""; RED=""; CYA=""
fi
TICK="+"; SKIP="-"; CROSS="x"

say()  { printf '  %s\n' "$*"; }
good() { printf '  %s%s%s %s\n' "$GRN" "$TICK" "$R" "$*"; }
skip() { printf '  %s%s %s%s\n'  "$DIM" "$SKIP" "$*" "$R"; }
warn() { printf '  %s%s%s %s\n' "$YEL" "!" "$R" "$*"; }
bad()  { printf '  %s%s%s %s\n' "$RED" "$CROSS" "$R" "$*" >&2; }
hr()   { printf '  %s────────────────────────────────────────────────────────%s\n' "$DIM" "$R"; }

# ----------------------------------------------------------------- input ---

# A readable /dev/tty is not enough — in a non-interactive runner it exists but
# returns EOF immediately, which would silently pick every default. Require a
# real terminal on stdin or stdout as well.
TTY=/dev/tty
HAVE_TTY=0
if [ -r "$TTY" ] && { [ -t 0 ] || [ -t 1 ]; }; then HAVE_TTY=1; else TTY=/dev/null; fi

ask() {  # ask <prompt> <default> -> ANSWER
  local prompt=$1 default=$2 reply=""
  if [ "$ASSUME_YES" = "1" ]; then
    ANSWER=$default
    printf '  %s%s%s %s%s%s\n' "$B" "$prompt" "$R" "$DIM" "$default" "$R"
    return 0
  fi
  printf '  %s%s%s %s[%s]%s ' "$B" "$prompt" "$R" "$DIM" "$default" "$R"
  IFS= read -r reply <"$TTY" || reply=""
  [ -z "$reply" ] && reply=$default
  ANSWER=$reply
}

# --------------------------------------------------------------- fetching ---

MODE="local"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo .)"
[ -d "$SCRIPT_DIR/_template" ] || MODE="remote"

fetch() {  # fetch <url> <dest>
  if command -v curl >/dev/null 2>&1; then curl -fsSL "$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then wget -qO "$2" "$1"
  else return 1; fi
}

get_file() {  # get_file <repo-relative-path> <dest>  -> 0 ok
  local src=$1 dest=$2
  mkdir -p "$(dirname "$dest")" || return 1
  if [ "$MODE" = "local" ]; then
    [ -f "$SCRIPT_DIR/$src" ] || return 1
    cp "$SCRIPT_DIR/$src" "$dest"
  else
    fetch "$REPO_RAW_URL/$src" "$dest"
  fi
}

read_file() {  # read_file <repo-relative-path> -> stdout
  if [ "$MODE" = "local" ]; then cat "$SCRIPT_DIR/$1" 2>/dev/null
  else
    local tmp; tmp=$(mktemp) || return 1
    fetch "$REPO_RAW_URL/$1" "$tmp" && cat "$tmp"; rm -f "$tmp"
  fi
}

# ------------------------------------------------------------------ steps ---

usage() {
  cat <<USAGE
kiacontext installer $VERSION

  ./install.sh              interactive
  ./install.sh --yes        accept every default, no prompts
  ./install.sh --dry-run    show what would happen, write nothing
  ./install.sh --help       this message

Non-interactive:
  --dir PATH                where to install (default: the git root, else \$PWD)
  --agents LIST             comma- or space-separated. Slugs or menu numbers:
                            claude cursor gemini codex copilot opencode qoder kiro
  --skills-dir PATH         project-scoped skills directory, for an agent not listed

  ./install.sh --yes --agents claude,cursor --dir .

Installs a kit of Markdown files that keeps a project's context for and by agents.
Existing files are never overwritten.
USAGE
}

ASSUME_YES=0; DRY=0; OPT_DIR=""; OPT_AGENTS=""; OPT_SKILLS_DIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -y|--yes)  ASSUME_YES=1 ;;
    -n|--dry-run) DRY=1 ;;
    --dir) shift; OPT_DIR="$1" ;;
    --agents) shift; OPT_AGENTS="$1" ;;
    --skills-dir) shift; OPT_SKILLS_DIR="$1" ;;
    *) bad "Unknown option: $1"; usage; exit 1 ;;
  esac
  shift
done

printf '\n  %skiacontext%s %s%s%s\n' "$B$CYA" "$R" "$DIM" "$VERSION" "$R"
say "${DIM}A kit of Markdown files to maintain project context for and by agents.${R}"
if [ "$HAVE_TTY" = "0" ] && [ "$ASSUME_YES" = "0" ]; then
  warn "No terminal available — using defaults. Pass --dir / --agents to choose, or --yes to silence this."
  ASSUME_YES=1
fi

printf '\n'; hr; printf '\n'

# 1. Where -------------------------------------------------------------------
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -n "$ROOT" ] || ROOT="$PWD"
if [ -n "$OPT_DIR" ]; then ROOT="$OPT_DIR"; say "${B}Directory${R} ${DIM}$ROOT${R}"
else ask "Install into which directory?" "$ROOT"; ROOT="$ANSWER"; fi
case "$ROOT" in "~") ROOT="$HOME" ;; "~/"*) ROOT="$HOME/${ROOT#\~/}" ;; esac
if [ ! -d "$ROOT" ]; then bad "Not a directory: $ROOT"; exit 1; fi
printf '\n'

# 2. Which agents ------------------------------------------------------------
if [ -n "$OPT_AGENTS" ]; then
  PICKED="$(printf '%s' "$OPT_AGENTS" | tr ',' ' ')"
  say "${B}Agents${R} ${DIM}$PICKED${R}"
else
  say "${B}Which agents work in this repository?${R}"
  say "${DIM}Skills are installed for each one, project-scoped.${R}"
  printf '\n'
  i=0
  while [ $i -lt ${#AGENT_NAMES[@]} ]; do
    n=$((i+1))
    if [ -n "${AGENT_SKILL_DIRS[$i]}" ]; then
      printf '    %s%d%s  %-10s %-20s %s%s%s\n' "$B" "$n" "$R" "${AGENT_SLUGS[$i]}" "${AGENT_NAMES[$i]}" "$DIM" "${AGENT_SKILL_DIRS[$i]}" "$R"
    else
      printf '    %s%d%s  %-10s %s\n' "$B" "$n" "$R" "${AGENT_SLUGS[$i]}" "${AGENT_NAMES[$i]}"
    fi
    i=$((i+1))
  done
  printf '\n'
  ask "Numbers or slugs, separated by spaces or commas" "1"
  PICKED="$(printf '%s' "$ANSWER" | tr ',' ' ')"
fi
printf '\n'; hr; printf '\n'

SEL_DIRS=""; SEL_DOCS="AGENTS.md"; SEL_NAMES=""
for n in $PICKED; do
  idx=-1
  case "$n" in
    ''|*[!0-9]*)
      j=0
      while [ $j -lt ${#AGENT_SLUGS[@]} ]; do
        [ "${AGENT_SLUGS[$j]}" = "$n" ] && idx=$j && break
        j=$((j+1))
      done
      if [ "$idx" -lt 0 ]; then bad "Unknown agent: $n  (try --help)"; exit 1; fi ;;
    *) idx=$((n-1)) ;;
  esac
  if [ "$idx" -lt 0 ] || [ "$idx" -ge ${#AGENT_NAMES[@]} ]; then bad "Out of range: $n"; exit 1; fi
  d="${AGENT_SKILL_DIRS[$idx]}"
  if [ -z "$d" ]; then
    if [ -n "$OPT_SKILLS_DIR" ]; then d="$OPT_SKILLS_DIR"
    else ask "Project-scoped skills directory (relative to the repo)" ".claude/skills"; d="$ANSWER"; fi
  fi
  SEL_DIRS="$SEL_DIRS $d"
  SEL_NAMES="$SEL_NAMES|${AGENT_NAMES[$idx]}"
  case " $SEL_DOCS " in *" ${AGENT_DOCS[$idx]} "*) ;; *) SEL_DOCS="$SEL_DOCS ${AGENT_DOCS[$idx]}" ;; esac
done

# 3. Scaffold ----------------------------------------------------------------
say "${B}context/ and docs/${R}"
created=0; existed=0
for src in "${TEMPLATE_FILES[@]}"; do
  rel="${src#_template/}"
  dest="$ROOT/$rel"
  if [ -f "$dest" ]; then skip "$rel  ${DIM}(exists, left alone)${R}"; existed=$((existed+1)); continue; fi
  if [ "$DRY" = "1" ]; then good "$rel  ${DIM}(would create)${R}"; created=$((created+1)); continue; fi
  if get_file "$src" "$dest"; then good "$rel"; created=$((created+1)); else bad "$rel — could not fetch"; fi
done
printf '\n'

# 4. Instruction files -------------------------------------------------------
say "${B}Agent instructions${R}"
BLOCK="$(read_file _template/AGENTS.harness.md | sed '1,/-->/d' | sed '/./,$!d')"
if [ -z "$BLOCK" ]; then bad "Could not read the harness block."; exit 1; fi

for doc in $SEL_DOCS; do
  target="$ROOT/$doc"
  if [ "$DRY" = "1" ]; then
    if [ -f "$target" ] && grep -qF "$BEGIN_MARK" "$target" 2>/dev/null
      then good "$doc  ${DIM}(would refresh the kiacontext block)${R}"
      else good "$doc  ${DIM}(would append the kiacontext block)${R}"; fi
    continue
  fi
  if [ -f "$target" ] && grep -qF "$BEGIN_MARK" "$target" 2>/dev/null; then
    tmp="$(mktemp)"
    awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
      index($0,b){skipping=1} !skipping{print} index($0,e){skipping=0}' "$target" > "$tmp"
    { cat "$tmp"; printf '%s\n\n%s\n\n%s\n' "$BEGIN_MARK" "$BLOCK" "$END_MARK"; } > "$target"
    rm -f "$tmp"
    good "$doc  ${DIM}(block refreshed)${R}"
  else
    [ -f "$target" ] && printf '\n' >> "$target"
    printf '%s\n\n%s\n\n%s\n' "$BEGIN_MARK" "$BLOCK" "$END_MARK" >> "$target"
    good "$doc  ${DIM}(block appended)${R}"
  fi
done
printf '\n'

# 5. Skills ------------------------------------------------------------------
say "${B}Skills${R}"
for d in $SEL_DIRS; do
  for s in "${SKILLS[@]}"; do
    dest="$ROOT/$d/$s/SKILL.md"
    if [ "$DRY" = "1" ]; then good "$d/$s/SKILL.md  ${DIM}(would install)${R}"; continue; fi
    if get_file "skills/$s/SKILL.md" "$dest"; then good "$d/$s/SKILL.md"
    else bad "$d/$s — could not fetch"; fi
  done
done
printf '\n'; hr; printf '\n'

# 6. What next ---------------------------------------------------------------
if [ "$DRY" = "1" ]; then
  say "${B}Dry run — nothing was written.${R}"
else
  say "${B}Done.${R} $created file(s) created, $existed left alone."
fi
printf '\n'
say "Next, in your agent:"
say "  ${CYA}/kia-context-init${R}   fill it in — new project or half-built, it handles both"
say "  ${CYA}/kia-context-help${R}   what each file is for"
say "  ${CYA}/kia-context-sync${R}   catch the files up after work has happened"
printf '\n'
say "${DIM}Nothing here is mandatory. Reshape any file; only the frontmatter is fixed.${R}"
printf '\n'
