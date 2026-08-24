#!/usr/bin/env bash
#
# kia-context — interactive installer
#
#   Local:  ./install.sh
#   Remote: curl -sSL https://raw.githubusercontent.com/amirkiarafiei/kia-context/main/install.sh | bash
#
# What it does, and nothing else:
#   1. scaffolds context/ and docs/ into this repository, never overwriting a file
#   2. writes the agent instructions into AGENTS.md (and CLAUDE.md / GEMINI.md), between markers
#   3. installs three project-scoped skills for the agents you pick
#
# Portability: targets bash 3.2 (macOS default) — no associative arrays, no mapfile, no ${x,,}.
# All keyboard input is read from /dev/tty so it still works when piped from curl.

set -o pipefail

REPO_RAW_URL="https://raw.githubusercontent.com/amirkiarafiei/kia-context/main"
VERSION="v0.1"
BEGIN_MARK="<!-- kiacontext:begin -->"
END_MARK="<!-- kiacontext:end -->"

# ------------------------------------------------------------------ data ---

# Agents, their PROJECT-scoped skills directory, and the instruction file they read.
# Only Claude Code's path is documented by its vendor; the rest follow the same
# convention. Use "Other" (or --skills-dir) if yours differs.
AGENT_NAMES=(
  "Claude Code" "Cursor" "Gemini CLI" "Codex" "GitHub Copilot"
  "OpenCode" "Qoder" "Kiro" "Other"
)
AGENT_SLUGS=(
  "claude" "cursor" "gemini" "codex" "copilot" "opencode" "qoder" "kiro" "other"
)
AGENT_SKILL_DIRS=(
  ".claude/skills" ".cursor/skills" ".gemini/skills" ".agents/skills" ".copilot/skills"
  ".opencode/skills" ".qoder/skills" ".kiro/skills" ""
)
AGENT_DOCS=(
  "CLAUDE.md" "AGENTS.md" "GEMINI.md" "AGENTS.md" "AGENTS.md"
  "AGENTS.md" "AGENTS.md" "AGENTS.md" "AGENTS.md"
)

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

# ---------------------------------------------------------- capabilities ---

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-dumb}" != "dumb" ]; then
  B=$'\033[1m'; DIM=$'\033[2m'; R=$'\033[0m'; REV=$'\033[7m'
  RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'
  BLU=$'\033[34m'; CYN=$'\033[36m'; GRY=$'\033[90m'
else
  B=""; DIM=""; R=""; REV=""; RED=""; GRN=""; YEL=""; BLU=""; CYN=""; GRY=""
fi

if printf '%s' "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" | grep -qi 'utf-*8'; then
  LINE="─"; CHK="▣"; BOX="□"; ARROW="›"; TICK="✓"; CROSS="✗"; DOT="·"
  TL="╭"; TR="╮"; BL="╰"; BR="╯"; VT="│"
else
  LINE="-"; CHK="[x]"; BOX="[ ]"; ARROW=">"; TICK="+"; CROSS="x"; DOT="."
  TL="+"; TR="+"; BL="+"; BR="+"; VT="|"
fi

term_cols() { local c; c=$(tput cols 2>/dev/null) || c=80; [ "$c" -gt 0 ] 2>/dev/null || c=80; printf '%s' "$c"; }
term_rows() { local r; r=$(tput lines 2>/dev/null) || r=24; [ "$r" -gt 0 ] 2>/dev/null || r=24; printf '%s' "$r"; }

hr() {
  local w i out=""
  w=$(term_cols); [ "$w" -gt 74 ] && w=74
  i=0; while [ "$i" -lt "$w" ]; do out="$out$LINE"; i=$((i + 1)); done
  printf '  %s%s%s\n' "$GRY" "$out" "$R"
}

say()  { printf '  %s\n' "$*"; }
step() { printf '\n  %s%s%s\n\n' "$B" "$*" "$R"; }
ok()   { printf '   %s%s%s %s\n' "$GRN" "$TICK" "$R" "$*"; }
kept() { printf '   %s%s %s%s\n'  "$GRY" "$DOT" "$*" "$R"; }
warn() { printf '   %s!%s %s\n' "$YEL" "$R" "$*"; }
bad()  { printf '   %s%s%s %s\n' "$RED" "$CROSS" "$R" "$*" >&2; }

banner() {
  local w; w=$(term_cols)
  printf '\n'
  if [ "$w" -ge 68 ]; then
    printf '%s' "$CYN$B"
    cat <<'ART'
  ██╗  ██╗██╗ █████╗
  ██║ ██╔╝██║██╔══██╗
  █████╔╝ ██║███████║
  ██╔═██╗ ██║██╔══██║
  ██║  ██╗██║██║  ██║
  ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝
ART
    printf '%s\n%s' "$R" "$BLU"
    cat <<'ART'
   ██████╗ ██████╗ ███╗   ██╗████████╗███████╗██╗  ██╗████████╗
  ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔════╝╚██╗██╔╝╚══██╔══╝
  ██║     ██║   ██║██╔██╗ ██║   ██║   █████╗   ╚███╔╝    ██║
  ██║     ██║   ██║██║╚██╗██║   ██║   ██╔══╝   ██╔██╗    ██║
  ╚██████╗╚██████╔╝██║ ╚████║   ██║   ███████╗██╔╝ ██╗   ██║
   ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝   ╚═╝
ART
    printf '%s' "$R"
  else
    printf '  %s%skia-context%s\n' "$B" "$CYN" "$R"
  fi
  printf '\n  %sA kit of markdown files to maintain project context for/by agents.%s\n' "$DIM" "$R"
  printf '  %sNothing more.%s  %s%s%s\n\n' "$DIM" "$R" "$GRY" "$VERSION" "$R"
  hr
}

# ----------------------------------------------------------------- input ---

TTY=/dev/tty
HAVE_TTY=0
if [ -r "$TTY" ] && { [ -t 0 ] || [ -t 1 ]; }; then HAVE_TTY=1; else TTY=/dev/null; fi

CURSOR_HIDDEN=0
hide_cursor() { [ -t 1 ] || return 0; printf '\033[?25l'; CURSOR_HIDDEN=1; }
show_cursor() { [ "$CURSOR_HIDDEN" -eq 1 ] && printf '\033[?25h'; CURSOR_HIDDEN=0; return 0; }
cleanup() { show_cursor; }
on_interrupt() { show_cursor; printf '\n'; bad "Cancelled."; exit 130; }
trap cleanup EXIT
trap on_interrupt INT TERM

read_key() {
  local k a b seq=""
  IFS= read -rsn1 k <"$TTY" 2>/dev/null || { printf 'eof'; return; }
  case "$k" in
    "")    printf 'enter'; return ;;
    " ")   printf 'space'; return ;;
    $'\t') printf 'tab';   return ;;
    $'\033')
      if ! IFS= read -rsn1 -t 1 a <"$TTY" 2>/dev/null; then printf 'esc'; return; fi
      case "$a" in "[" | "O") ;; *) printf 'esc'; return ;; esac
      while IFS= read -rsn1 -t 1 b <"$TTY" 2>/dev/null; do
        seq="$seq$b"; case "$b" in [A-Za-z~]) break ;; esac
      done
      case "$seq" in
        A) printf 'up' ;;  B) printf 'down' ;;
        C) printf 'right';; D) printf 'left' ;;
        H|"1~") printf 'home' ;; F|"4~") printf 'end' ;;
        *) printf 'other' ;;
      esac
      return ;;
    *) printf '%s' "$k"; return ;;
  esac
}

rewind() { local n=$1; [ "$n" -gt 0 ] && printf '\033[%dA\033[J' "$n"; return 0; }

BTN_W=38
draw_button() {
  local label=$1 focused=$2 enabled=$3
  local len pad l r bar color content i=0
  len=${#label}
  if [ "$len" -gt "$BTN_W" ]; then label=${label:0:$BTN_W}; len=$BTN_W; fi
  pad=$(( (BTN_W - len) / 2 ))
  l=$(printf '%*s' "$pad" ''); r=$(printf '%*s' $(( BTN_W - len - pad )) '')
  content="${l}${label}${r}"
  bar=""; while [ "$i" -lt "$BTN_W" ]; do bar="${bar}${LINE}"; i=$((i + 1)); done

  if [ "$focused" -eq 1 ]; then
    if [ "$enabled" -eq 1 ]; then color="$GRN$B"; else color="$YEL$B"; fi
  elif [ "$enabled" -eq 1 ]; then color="$B"; else color="$GRY"; fi

  printf '     %s%s%s%s%s\n' "$color" "$TL" "$bar" "$TR" "$R"
  if [ "$focused" -eq 1 ]; then
    printf '   %s %s%s%s%s%s%s%s\n' "$ARROW" "$color" "$VT" "$REV" "$content" "$R$color" "$VT" "$R"
  else
    printf '     %s%s%s%s%s\n' "$color" "$VT" "$content" "$VT" "$R"
  fi
  printf '     %s%s%s%s%s\n' "$color" "$BL" "$bar" "$BR" "$R"
}

# The one question. Toggle agents, then press the button.
# Sets PICKED to a space-separated list of indices; returns 1 if cancelled.
PICKED=""
menu_agents() {
  local n=${#AGENT_NAMES[@]}
  local cur=0 drawn=0 i key count marks=""

  i=0; while [ "$i" -lt "$n" ]; do marks="${marks}0"; i=$((i + 1)); done
  marks="1${marks:1}"          # Claude Code preselected — the common case

  hide_cursor
  while :; do
    count=0; i=0
    while [ "$i" -lt "$n" ]; do
      [ "${marks:$i:1}" = "1" ] && count=$((count + 1)); i=$((i + 1))
    done

    rewind "$drawn"; drawn=0
    printf '\n'; drawn=$((drawn + 1))
    printf '  %sWhich agents work in this repository?%s   %s%d selected%s\n' \
      "$B" "$R" "$DIM" "$count" "$R"; drawn=$((drawn + 1))
    printf '  %sEach one gets the three skills, project-scoped.%s\n' "$DIM" "$R"; drawn=$((drawn + 1))
    printf '\n'; drawn=$((drawn + 1))

    i=0
    while [ "$i" -lt "$n" ]; do
      local box name dir
      if [ "${marks:$i:1}" = "1" ]; then box="${GRN}${CHK}${R}"; else box="${GRY}${BOX}${R}"; fi
      name=${AGENT_NAMES[$i]}; dir=${AGENT_SKILL_DIRS[$i]}
      [ -z "$dir" ] && dir="you will be asked for the path"
      if [ "$i" -eq "$cur" ]; then
        printf '   %s %s %s%-16s%s %s%s%s\n' "$ARROW" "$box" "$CYN$B" "$name" "$R" "$DIM" "$dir" "$R"
      else
        printf '     %s %-16s %s%s%s\n' "$box" "$name" "$GRY" "$dir" "$R"
      fi
      drawn=$((drawn + 1)); i=$((i + 1))
    done

    printf '\n'; drawn=$((drawn + 1))
    if [ "$count" -gt 0 ]; then
      if [ "$cur" -eq "$n" ]; then draw_button "Install" 1 1; else draw_button "Install" 0 1; fi
    else
      if [ "$cur" -eq "$n" ]; then draw_button "Pick at least one agent" 1 0; else draw_button "Install" 0 0; fi
    fi
    drawn=$((drawn + 3))

    printf '\n'; drawn=$((drawn + 1))
    printf '     %s↑/↓ move %s space or enter toggle %s a all %s n none%s\n' \
      "$DIM" "$DOT" "$DOT" "$DOT" "$R"; drawn=$((drawn + 1))
    printf '     %spast the last agent is the Install button %s q cancel%s\n' \
      "$DIM" "$DOT" "$R"; drawn=$((drawn + 1))

    key=$(read_key)
    case "$key" in
      up|k)   cur=$((cur - 1)); [ "$cur" -lt 0 ] && cur=$n ;;
      down|j) cur=$((cur + 1)); [ "$cur" -gt "$n" ] && cur=0 ;;
      home)   cur=0 ;;
      end)    cur=$n ;;
      a) i=0; marks=""; while [ "$i" -lt "$n" ]; do marks="${marks}1"; i=$((i + 1)); done ;;
      n) i=0; marks=""; while [ "$i" -lt "$n" ]; do marks="${marks}0"; i=$((i + 1)); done ;;
      space|left|right)
        if [ "$cur" -lt "$n" ]; then
          if [ "${marks:$cur:1}" = "1" ]; then marks="${marks:0:$cur}0${marks:$((cur+1))}"
          else marks="${marks:0:$cur}1${marks:$((cur+1))}"; fi
        fi ;;
      enter)
        if [ "$cur" -lt "$n" ]; then
          if [ "${marks:$cur:1}" = "1" ]; then marks="${marks:0:$cur}0${marks:$((cur+1))}"
          else marks="${marks:0:$cur}1${marks:$((cur+1))}"; fi
        elif [ "$count" -gt 0 ]; then
          rewind "$drawn"; show_cursor
          PICKED=""; i=0
          while [ "$i" -lt "$n" ]; do
            [ "${marks:$i:1}" = "1" ] && PICKED="$PICKED $i"
            i=$((i + 1))
          done
          return 0
        fi ;;
      q|esc|eof) show_cursor; return 1 ;;
    esac
  done
}

ask_path() {  # ask_path <prompt> <default> -> ANSWER
  local prompt=$1 default=$2 reply=""
  printf '   %s%s%s %s[%s]%s ' "$B" "$prompt" "$R" "$DIM" "$default" "$R"
  show_cursor
  IFS= read -r reply <"$TTY" || reply=""
  [ -z "$reply" ] && reply=$default
  case "$reply" in "~") reply="$HOME" ;; "~/"*) reply="$HOME/${reply#\~/}" ;; esac
  ANSWER=$reply
}

# -------------------------------------------------------------- fetching ---

MODE="local"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo .)"
[ -d "$SCRIPT_DIR/_template" ] || MODE="remote"

fetch() {
  if command -v curl >/dev/null 2>&1; then curl -fsSL "$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then wget -qO "$2" "$1"
  else return 1; fi
}
get_file() {
  local src=$1 dest=$2
  mkdir -p "$(dirname "$dest")" || return 1
  if [ "$MODE" = "local" ]; then [ -f "$SCRIPT_DIR/$src" ] || return 1; cp "$SCRIPT_DIR/$src" "$dest"
  else fetch "$REPO_RAW_URL/$src" "$dest"; fi
}
read_file() {
  if [ "$MODE" = "local" ]; then cat "$SCRIPT_DIR/$1" 2>/dev/null
  else local tmp; tmp=$(mktemp) || return 1; fetch "$REPO_RAW_URL/$1" "$tmp" && cat "$tmp"; rm -f "$tmp"; fi
}

# ----------------------------------------------------------------- flags ---

usage() {
  cat <<USAGE
kia-context installer $VERSION

  ./install.sh              interactive — one question, then it installs
  ./install.sh --dry-run    show what would happen, write nothing
  ./install.sh --help       this message

Non-interactive:
  --yes                     accept defaults, no prompts
  --dir PATH                where to install (default: the git root, else \$PWD)
  --agents LIST             comma- or space-separated slugs:
                            claude cursor gemini codex copilot opencode qoder kiro
  --skills-dir PATH         project-scoped skills directory, for an agent not listed

  ./install.sh --yes --agents claude,cursor

Existing files are never overwritten. Re-running is safe.
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

# ------------------------------------------------------------------ main ---

banner

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -n "$ROOT" ] || ROOT="$PWD"
[ -n "$OPT_DIR" ] && ROOT="$OPT_DIR"
case "$ROOT" in "~") ROOT="$HOME" ;; "~/"*) ROOT="$HOME/${ROOT#\~/}" ;; esac
if [ ! -d "$ROOT" ]; then bad "Not a directory: $ROOT"; exit 1; fi
printf '  %sinto%s %s\n' "$DIM" "$R" "$ROOT"

# --- the one question ---
if [ -n "$OPT_AGENTS" ]; then
  PICKED=""
  for tok in $(printf '%s' "$OPT_AGENTS" | tr ',' ' '); do
    idx=-1; j=0
    while [ $j -lt ${#AGENT_SLUGS[@]} ]; do
      [ "${AGENT_SLUGS[$j]}" = "$tok" ] && idx=$j && break
      j=$((j + 1))
    done
    case "$tok" in ''|*[!0-9]*) ;; *) idx=$((tok - 1)) ;; esac
    if [ "$idx" -lt 0 ] || [ "$idx" -ge ${#AGENT_NAMES[@]} ]; then bad "Unknown agent: $tok"; exit 1; fi
    PICKED="$PICKED $idx"
  done
elif [ "$ASSUME_YES" = "1" ] || [ "$HAVE_TTY" = "0" ]; then
  [ "$HAVE_TTY" = "0" ] && [ "$ASSUME_YES" = "0" ] && \
    warn "No terminal — defaulting to Claude Code. Use --agents to choose."
  PICKED="0"
else
  if ! menu_agents; then printf '\n'; bad "Cancelled."; exit 130; fi
fi

SEL_DIRS=""; SEL_DOCS="AGENTS.md"; SEL_LABEL=""
for idx in $PICKED; do
  d="${AGENT_SKILL_DIRS[$idx]}"
  if [ -z "$d" ]; then
    if [ -n "$OPT_SKILLS_DIR" ]; then d="$OPT_SKILLS_DIR"
    elif [ "$HAVE_TTY" = "1" ]; then printf '\n'; ask_path "Skills directory for \"Other\"" ".claude/skills"; d="$ANSWER"
    else d=".claude/skills"; fi
  fi
  SEL_DIRS="$SEL_DIRS $d"
  SEL_LABEL="$SEL_LABEL${SEL_LABEL:+, }${AGENT_NAMES[$idx]}"
  case " $SEL_DOCS " in *" ${AGENT_DOCS[$idx]} "*) ;; *) SEL_DOCS="$SEL_DOCS ${AGENT_DOCS[$idx]}" ;; esac
done
printf '  %sfor%s  %s\n' "$DIM" "$R" "$SEL_LABEL"
printf '\n'; hr

# --- 1. scaffold ---
step "Context files"
created=0; existed=0
for src in "${TEMPLATE_FILES[@]}"; do
  rel="${src#_template/}"; dest="$ROOT/$rel"
  if [ -f "$dest" ]; then kept "$rel"; existed=$((existed + 1)); continue; fi
  if [ "$DRY" = "1" ]; then ok "$rel"; created=$((created + 1)); continue; fi
  if get_file "$src" "$dest"; then ok "$rel"; created=$((created + 1)); else bad "$rel — could not fetch"; fi
done
[ "$existed" -gt 0 ] && printf '\n   %s%d file(s) already existed and were left alone.%s\n' "$GRY" "$existed" "$R"

# --- 2. instructions ---
step "Agent instructions"
BLOCK="$(read_file _template/AGENTS.harness.md | sed '1,/-->/d' | sed '/./,$!d')"
if [ -z "$BLOCK" ]; then bad "Could not read the harness block."; exit 1; fi
for doc in $SEL_DOCS; do
  target="$ROOT/$doc"
  had=0; [ -f "$target" ] && grep -qF "$BEGIN_MARK" "$target" 2>/dev/null && had=1
  if [ "$DRY" = "1" ]; then
    if [ "$had" = "1" ]; then ok "$doc  ${GRY}refresh${R}"; else ok "$doc  ${GRY}append${R}"; fi
    continue
  fi
  if [ "$had" = "1" ]; then
    tmp="$(mktemp)"
    awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
      index($0,b){skipping=1} !skipping{print} index($0,e){skipping=0}' "$target" > "$tmp"
    { cat "$tmp"; printf '%s\n\n%s\n\n%s\n' "$BEGIN_MARK" "$BLOCK" "$END_MARK"; } > "$target"
    rm -f "$tmp"; ok "$doc  ${GRY}block refreshed${R}"
  else
    [ -f "$target" ] && printf '\n' >> "$target"
    printf '%s\n\n%s\n\n%s\n' "$BEGIN_MARK" "$BLOCK" "$END_MARK" >> "$target"
    ok "$doc"
  fi
done

# --- 3. skills ---
step "Skills"
for d in $SEL_DIRS; do
  for s in "${SKILLS[@]}"; do
    dest="$ROOT/$d/$s/SKILL.md"
    if [ "$DRY" = "1" ]; then ok "$d/$s"; continue; fi
    if get_file "skills/$s/SKILL.md" "$dest"; then ok "$d/$s"; else bad "$d/$s — could not fetch"; fi
  done
done

# --- done ---
printf '\n'; hr; printf '\n'
if [ "$DRY" = "1" ]; then
  printf '  %s%s Dry run — nothing was written.%s\n' "$YEL$B" "$ARROW" "$R"
else
  printf '  %s%s Installed.%s %s%d created, %d left alone%s\n' "$GRN$B" "$TICK" "$R" "$DIM" "$created" "$existed" "$R"
fi
printf '\n  %sNext, in your agent:%s\n\n' "$B" "$R"
printf '     %s/kia-context-init%s   %sfill it in — new project or half-built, it handles both%s\n' "$CYN$B" "$R" "$DIM" "$R"
printf '     %s/kia-context-help%s   %swhat each file is for%s\n' "$CYN$B" "$R" "$DIM" "$R"
printf '     %s/kia-context-sync%s   %scatch the files up after work has happened%s\n' "$CYN$B" "$R" "$DIM" "$R"
printf '\n  %sNothing here is mandatory. Reshape any file; only the frontmatter is fixed.%s\n\n' "$GRY" "$R"
