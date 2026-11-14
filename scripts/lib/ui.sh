# Output for install.sh and the scripts it runs (system/services.sh, system/user-services.sh): one look for all of them.
# Source it, then use:
#   ui_banner "<what>" "<detail>"      the title at the start
#   step "<name>" "<what it does>"     a numbered step header (set UI_STEP_TOTAL first; each call counts up)
#   ok "<text>"        ✓  already fine, nothing to do              (dim: the eye skips it)
#   done_ "<text>"     +  installed / changed / turned on          (bright: this is what happened)
#   gone "<text>"      −  removed / turned off
#   warn "<text>"      !  something to look at                     (repeated in the summary)
#   info "<text>"      ·  a detail
#   doing "<text>"     →  what is happening now
#   would "<text>"     →  dry run: what would happen ("would <text>"; counted in the summary)
#   die "<text>"       ✗  stop
#   ui_summary         changes and warnings of the whole run, and how long it took
# Changes and warnings are also written to $UI_EVENTS_FILE (when set), so the summary includes the ones made by
# scripts run with sudo. Colours are the desktop's palette; NO_COLOR or output that is not a terminal turns them off.

if [[ -t 1 && -z ${NO_COLOR:-} ]]; then
  _c() { printf '\e[38;2;%d;%d;%dm' "$1" "$2" "$3"; }
  UI_ACC=$(_c 108 127 145)  UI_OK=$(_c 125 152 137)  UI_WARN=$(_c 168 151 111)  UI_ERR=$(_c 166 122 126)
  UI_DIM=$(_c 102 106 110)  UI_TXT=$(_c 173 176 179) UI_BRIGHT=$(_c 208 211 214)
  UI_BOLD=$'\e[1m' UI_0=$'\e[0m'
  unset -f _c
else
  UI_ACC='' UI_OK='' UI_WARN='' UI_ERR='' UI_DIM='' UI_TXT='' UI_BRIGHT='' UI_BOLD='' UI_0=''
fi

UI_STEP_INDEX=${UI_STEP_INDEX:-0}
UI_STEP_TOTAL=${UI_STEP_TOTAL:-0}
UI_STEP_NAME=${UI_STEP_NAME:-}
UI_START=${UI_START:-$SECONDS}

# $HOME as ~, so long paths stay short.
_ui_short() { local s="$*"; printf '%s' "${s//$HOME/\~}"; }

_ui_event() {   # kind, text: for the summary
  [[ -n ${UI_EVENTS_FILE:-} ]] && printf '%s\t%s\t%s\n' "$1" "${UI_STEP_NAME:-}" "$2" >> "$UI_EVENTS_FILE"
  return 0
}

ui_banner() {
  printf '\n  %s%sdotfiles%s  %s%s%s\n' "$UI_BOLD" "$UI_BRIGHT" "$UI_0" "$UI_DIM" "$1" "$UI_0"
  [[ -n ${2:-} ]] && printf '  %s%s%s\n' "$UI_DIM" "$2" "$UI_0"
  return 0
}

step() {
  UI_STEP_INDEX=$(( UI_STEP_INDEX + 1 ))
  UI_STEP_NAME=$1
  local num="" rule
  (( UI_STEP_TOTAL > 1 )) && num="$UI_STEP_INDEX/$UI_STEP_TOTAL"
  printf -v rule '%*s' $(( 54 - ${#1} - ${#num} > 4 ? 54 - ${#1} - ${#num} : 4 )) ''
  rule=${rule// /─}
  printf '\n %s%-5s%s %s%s%s%s %s%s%s\n' "$UI_ACC" "$num" "$UI_0" "$UI_BOLD" "$UI_BRIGHT" "$1" "$UI_0" "$UI_DIM" "$rule" "$UI_0"
  [[ -n ${2:-} ]] && printf '       %s%s%s\n' "$UI_DIM" "$2" "$UI_0"
  return 0
}

ok()    { printf '  %s✓%s %s%s%s\n' "$UI_OK" "$UI_0" "$UI_DIM" "$(_ui_short "$*")" "$UI_0"; }
done_() { printf '  %s+%s %s%s%s\n' "$UI_OK" "$UI_0" "$UI_BRIGHT" "$(_ui_short "$*")" "$UI_0"; _ui_event change "$(_ui_short "$*")"; }
gone()  { printf '  %s−%s %s%s%s\n' "$UI_WARN" "$UI_0" "$UI_TXT" "$(_ui_short "$*")" "$UI_0"; _ui_event change "$(_ui_short "$*")"; }
info()  { printf '  %s· %s%s\n' "$UI_DIM" "$(_ui_short "$*")" "$UI_0"; }
doing() { printf '  %s→%s %s\n' "$UI_ACC" "$UI_0" "$(_ui_short "$*")"; }
would() { printf '  %s→ would%s %s\n' "$UI_ACC" "$UI_0" "$(_ui_short "$*")"; _ui_event would "$(_ui_short "$*")"; }
warn()  { printf '  %s! %s%s\n' "$UI_WARN" "$(_ui_short "$*")" "$UI_0" >&2; _ui_event warn "$(_ui_short "$*")"; }
die()   { printf '\n  %s✗ %s%s\n\n' "$UI_ERR" "$(_ui_short "$*")" "$UI_0" >&2; exit 1; }

# Everything that changed, every warning, and the time it took.
ui_summary() {
  local dry=${1:-0} secs=$(( SECONDS - UI_START )) changes=0 warns=0 kind stepname text
  if [[ -n ${UI_EVENTS_FILE:-} && -s $UI_EVENTS_FILE ]]; then
    changes=$(grep -cE "^(change|would)"$'\t' "$UI_EVENTS_FILE" || true)
    warns=$(grep -c "^warn"$'\t' "$UI_EVENTS_FILE" || true)
  fi
  local title="Done" time
  (( dry )) && title="Dry run done"
  time=$(( secs >= 60 ? secs / 60 : 0 ))m$(( secs % 60 ))s
  [[ $time == 0m* ]] && time=${time#0m}
  local rule; printf -v rule '%*s' $(( 50 - ${#title} - ${#time} )) ''; rule=${rule// /─}
  printf '\n %s%s%s%s %s%s %s%s%s\n' "$UI_BOLD" "$UI_BRIGHT" "$title" "$UI_0" "$UI_DIM" "$rule" "$time" "$UI_0" ""

  local what="changed" none="nothing to change: everything is already in place"
  (( dry )) && { what="would change"; none="nothing would change: everything is already in place"; }
  if (( changes == 0 && warns == 0 )); then
    printf '  %s✓%s %s\n' "$UI_OK" "$UI_0" "$none"
    return 0
  fi
  printf '  %s+ %d %s%s' "$UI_OK" "$changes" "$what" "$UI_0"
  (( warns )) && printf '     %s! %d warning%s%s' "$UI_WARN" "$warns" "$( (( warns == 1 )) || echo s)" "$UI_0"
  printf '\n'
  while IFS=$'\t' read -r kind stepname text; do
    if [[ $kind == change ]]; then printf '    %s+%s %s%-13s%s %s\n' "$UI_OK" "$UI_0" "$UI_DIM" "$stepname" "$UI_0" "$text"
    elif [[ $kind == would ]]; then printf '    %s→%s %s%-13s%s %s\n' "$UI_ACC" "$UI_0" "$UI_DIM" "$stepname" "$UI_0" "$text"
    else printf '    %s! %-13s %s%s\n' "$UI_WARN" "$stepname" "$text" "$UI_0"
    fi
  done < "$UI_EVENTS_FILE"
  return 0
}
