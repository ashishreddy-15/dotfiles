# Turning systemd units on and off, with a readable report. Used by system/services.sh and system/user-services.sh.
# Source scripts/lib/ui.sh first, set SVC (the systemctl command), then call, per group of units:
#   svc_group on   "<what they are>" unit...    enabled (and started, with SVC_NOW=1)
#   svc_group off  "<what they are>" unit...    disabled and stopped
#   svc_group mask "<what they are>" unit...    masked: cannot start even on demand
# Each group prints one line when nothing changes, e.g.  "✓ off   printing   cups.socket cups.path cups",
# and a line per unit it changes. DRY_RUN=1 only reads the state (no root needed for system units).

SVC=${SVC:-systemctl}
SVC_NOW=${SVC_NOW:-1}
DRY_RUN=${DRY_RUN:-0}
SVC_MISSING=0

# Is the unit already the way we want it? Sets _load (loaded / not-found / masked).
_svc_fine() {
  local want=$1 u=$2 file="" active="" kv
  _load=""
  # (key=value: with --value systemd prints them in its own order, not the one asked for)
  while IFS= read -r kv; do
    case $kv in LoadState=*) _load=${kv#*=} ;; UnitFileState=*) file=${kv#*=} ;; ActiveState=*) active=${kv#*=} ;; esac
  done < <($SVC show -p LoadState,UnitFileState,ActiveState "$u" 2>/dev/null)
  case $want in
    on)   [[ $file == enabled* || $file == static || $file == alias ]] && { (( ! SVC_NOW )) || [[ $active == active ]]; } ;;
    off)  [[ $file != enabled* && $active != active ]] ;;
    mask) [[ $_load == masked ]] ;;
  esac
}

svc_group() {
  local want=$1 why=$2 u name fine=() _load
  shift 2
  for u in "$@"; do
    name=${u%.service}
    if _svc_fine "$want" "$u"; then fine+=("$name"); continue; fi
    if [[ $_load == not-found ]]; then SVC_MISSING=$(( SVC_MISSING + 1 )); continue; fi
    if (( DRY_RUN )); then
      case $want in on) would "turn on $name ($why)" ;; off) would "turn off $name ($why)" ;; mask) would "mask $name ($why)" ;; esac
      continue
    fi
    case $want in
      on)
        $SVC unmask "$u" >/dev/null 2>&1
        if (( SVC_NOW )); then $SVC enable --now "$u" >/dev/null 2>&1; else $SVC enable "$u" >/dev/null 2>&1; fi \
          && done_ "turned on $name ($why)" || warn "could not turn on $name"
        ;;
      off)
        $SVC disable --now "$u" >/dev/null 2>&1 && gone "turned off $name ($why)" || warn "could not turn off $name" ;;
      mask)
        $SVC stop "$u" >/dev/null 2>&1
        $SVC mask "$u" >/dev/null 2>&1 && gone "masked $name ($why)" || warn "could not mask $name" ;;
    esac
  done
  (( ${#fine[@]} )) || return 0
  local word=$want colour=$UI_OK
  [[ $want == off ]] && colour=$UI_DIM
  [[ $want == mask ]] && { word=masked; colour=$UI_WARN; }
  printf '  %s✓%s %s%-6s%s %s%-34s%s %s%s%s\n' "$UI_OK" "$UI_0" "$colour" "$word" "$UI_0" "$UI_TXT" "$why" "$UI_0" \
    "$UI_DIM" "${fine[*]}" "$UI_0"
}

# After all groups: how many listed units this machine does not have.
svc_missing_note() {
  (( SVC_MISSING )) && info "$SVC_MISSING listed units are not installed here (nothing to turn off)"
  return 0
}
