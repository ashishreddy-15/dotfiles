#!/usr/bin/env bash
#
# Bootstrap this machine from the dotfiles repo. Safe to re-run at any time.
#
#   ./install.sh                 run every step (repos packages fonts wallpapers link services sddm defaults)
#   ./install.sh link            run only the given step(s)
#   ./install.sh -n              dry run: show what would happen, change nothing
#   ./install.sh -y              don't ask dnf for confirmation
#   ./install.sh unlink          remove all dotfile symlinks from $HOME
#
# Steps:
#   repos     install repo files from system/repos/ into /etc/yum.repos.d/
#   packages  dnf install everything in packages/*.txt,
#             then dnf remove everything in packages/remove.txt
#   fonts     download fonts in system/fonts.txt (pinned + checksummed) to ~/.local/share/fonts
#   wallpapers generate the Carbon & Pewter wallpapers into ~/.local/share/wallpapers (scripts/gen-wallpapers.py)
#   services  run system/services.sh (root) and system/user-services.sh (user units)
#   link      symlink home/<pkg>/ into $HOME with GNU stow
#             (existing real files are moved to ~/.dotfiles-backup/<time>/ first,
#             then the Hyprland config is checked with --verify-config)
#   sddm      the login screen: the "carbon" theme from system/sddm/ (with Maple Mono and your wallpaper copied in,
#             since the login screen cannot read your home folder) and /etc/sddm.conf.d/10-dotfiles.conf
#   defaults  set default applications (MIME_DEFAULTS below)

set -Eeuo pipefail
shopt -s nullglob

DOTFILES="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
STOW_DIR="$DOTFILES/home"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
REMOVE_LIST="$DOTFILES/packages/remove.txt"
ALL_STEPS=(repos packages fonts wallpapers link services sddm defaults)

# Default applications: "<desktop file> <mime type>..."
MIME_DEFAULTS=(
  "org.gnome.Nautilus.desktop inode/directory"
)

DRY_RUN=0
ASSUME_YES=0

# ---------- output helpers ----------
if [[ -t 1 ]]; then
  C_B=$'\e[1m' C_G=$'\e[32m' C_Y=$'\e[33m' C_R=$'\e[31m' C_0=$'\e[0m'
else
  C_B='' C_G='' C_Y='' C_R='' C_0=''
fi
step() { printf '\n%s==> %s%s\n' "$C_B" "$*" "$C_0"; }
info() { printf '  %s\n' "$*"; }
ok()   { printf '  %s✓%s %s\n' "$C_G" "$C_0" "$*"; }
warn() { printf '  %s!%s %s\n' "$C_Y" "$C_0" "$*" >&2; }
die()  { printf '%serror:%s %s\n' "$C_R" "$C_0" "$*" >&2; exit 1; }

trap 'die "failed at line $LINENO: $BASH_COMMAND"' ERR

# Run a command, or just print it in dry-run mode.
run() {
  if (( DRY_RUN )); then
    printf '  [dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

# Print the comment block at the top of this file.
usage() { awk 'NR>2 && /^#/ {sub(/^# ?/, ""); print; next} NR>2 {exit}' "${BASH_SOURCE[0]}"; exit "${1:-0}"; }

# Read package names from a list file: strip comments and blank lines.
read_list() { sed -e 's/#.*//' -e 's/[[:space:]]\+$//' -e '/^[[:space:]]*$/d' "$1"; }

# ---------- preflight ----------
preflight() {
  (( EUID != 0 )) || die "run as your normal user, not root (sudo is used only where needed)"

  # shellcheck source=/dev/null
  . /etc/os-release
  [[ "${ID:-}" == fedora ]] || die "this script targets Fedora (found: ${ID:-unknown})"

  local missing=()
  for cmd in dnf stow sudo; do
    command -v "$cmd" >/dev/null || missing+=("$cmd")
  done
  (( ${#missing[@]} == 0 )) || die "missing commands: ${missing[*]}  (sudo dnf install ${missing[*]})"

  [[ -d "$STOW_DIR" ]] || die "stow directory not found: $STOW_DIR"
}

need_sudo() {
  (( DRY_RUN )) && return 0
  sudo -v || die "sudo authentication failed"
}

# ---------- steps ----------
step_repos() {
  step "Repositories"
  local src name dest
  for src in "$DOTFILES"/system/repos/*.repo; do
    name=$(basename "$src")
    dest="/etc/yum.repos.d/$name"
    if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
      ok "$name (up to date)"
      continue
    fi
    if [[ -f "$dest" ]]; then
      warn "$name differs from installed copy; replacing:"
      diff -u "$dest" "$src" | sed 's/^/      /' || true
    fi
    need_sudo
    run sudo install -m 0644 -o root -g root "$src" "$dest"
    ok "$name installed"
  done

  # Warn about other Hyprland COPRs that would compete with ours.
  local f ours
  for f in /etc/yum.repos.d/*hypr*.repo; do
    ours=0
    for src in "$DOTFILES"/system/repos/*.repo; do
      [[ "$(basename "$src")" == "$(basename "$f")" ]] && ours=1
    done
    (( ours )) || warn "another Hyprland repo is present: $f (consider removing it)"
  done
}

step_packages() {
  step "Packages"
  local list p pkgs=() unwanted=()
  for list in "$DOTFILES"/packages/*.txt; do
    [[ "$list" == "$REMOVE_LIST" ]] && continue
    mapfile -t -O "${#pkgs[@]}" pkgs < <(read_list "$list")
    info "$(basename "$list"): $(read_list "$list" | wc -l) packages"
  done
  [[ -f "$REMOVE_LIST" ]] && mapfile -t unwanted < <(read_list "$REMOVE_LIST")

  # A package listed for both install and removal is a mistake in the lists.
  for p in "${unwanted[@]}"; do
    [[ " ${pkgs[*]} " == *" $p "* ]] && die "'$p' is in remove.txt and in an install list"
  done

  local yes=()
  (( ASSUME_YES )) && yes=(-y)

  # Install first, so replacements (e.g. nautilus) exist before removals.
  local missing=()
  for p in "${pkgs[@]}"; do
    rpm -q "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  if (( ${#missing[@]} )); then
    info "to install: ${missing[*]}"
    need_sudo
    run sudo dnf install "${yes[@]}" "${missing[@]}"
  else
    ok "all ${#pkgs[@]} packages already installed"
  fi

  local present=()
  for p in "${unwanted[@]}"; do
    rpm -q "$p" >/dev/null 2>&1 && present+=("$p")
  done
  if (( ${#present[@]} )); then
    info "to remove (plus their unused dependencies): ${present[*]}"
    need_sudo
    run sudo dnf remove "${yes[@]}" "${present[@]}"
  else
    ok "nothing to remove"
  fi
}

step_services() {
  step "Services"
  need_sudo
  if (( DRY_RUN )); then
    info "[dry-run] sudo bash system/services.sh"
    info "[dry-run] bash system/user-services.sh"
  else
    sudo bash "$DOTFILES/system/services.sh"
    bash "$DOTFILES/system/user-services.sh"
  fi
}

# Catch config mistakes now instead of at the next login.
verify_configs() {
  if command -v Hyprland >/dev/null && [[ -f "$HOME/.config/hypr/hyprland.lua" ]]; then
    local out
    if out=$(Hyprland --verify-config -c "$HOME/.config/hypr/hyprland.lua" 2>&1); then
      ok "Hyprland config is valid"
    else
      warn "Hyprland config has errors:"
      sed -n '/Config parsing result/,$p' <<<"$out" | sed 's/^/      /' >&2
      return 1
    fi
  fi
}

# Move any real file that would block stow into the backup dir.
backup_conflicts() {
  local pkg=$1 src rel target resolved
  while IFS= read -r -d '' src; do
    rel=${src#"$STOW_DIR/$pkg/"}
    target="$HOME/$rel"
    [[ -e "$target" || -L "$target" ]] || continue

    # Already a link into this repo: nothing to do.
    if [[ -L "$target" ]]; then
      resolved=$(readlink -f "$target" || true)
      [[ "$resolved" == "$STOW_DIR/"* ]] && continue
    fi
    [[ -d "$target" && ! -L "$target" ]] && die "$target is a directory but $pkg provides a file there"

    run mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
    run mv "$target" "$BACKUP_DIR/$rel"
    warn "backed up ~/$rel -> ${BACKUP_DIR/#"$HOME"/"~"}/$rel"
  done < <(find "$STOW_DIR/$pkg" \( -type f -o -type l \) -print0)
}

list_pkgs() {
  local d
  for d in "$STOW_DIR"/*/; do basename "$d"; done
}

# Login screen: the carbon theme (system/sddm/carbon). SDDM runs as its own user and cannot read $HOME, so the font
# and the current wallpaper are copied into the theme. Re-run after changing the wallpaper to update it there too.
step_sddm() {
  step "Login screen (SDDM)"
  command -v sddm >/dev/null 2>&1 || { ok "sddm is not installed: skipped"; return 0; }
  need_sudo
  local src="$DOTFILES/system/sddm" dest=/usr/share/sddm/themes/carbon
  local font="$HOME/.local/share/fonts/dotfiles/maple-mono-nf/MapleMono-NF-Regular.ttf"
  local wall
  wall=$(cat "$HOME/.local/state/dotfiles/wallpaper" 2>/dev/null)
  [[ -f "$wall" ]] || wall=$(find "$HOME/.local/share/wallpapers" -maxdepth 1 -type f 2>/dev/null | sort | head -1)

  run sudo install -d -m 755 "$dest" /etc/sddm.conf.d
  run sudo install -m 644 "$src"/carbon/* "$dest"/
  if [[ -f "$font" ]]; then
    run sudo install -m 644 "$font" "$dest/MapleMono-NF-Regular.ttf"
    run sudo install -m 644 "${font%Regular.ttf}Light.ttf" "$dest/MapleMono-NF-Light.ttf"
  else warn "Maple Mono not found (run ./install.sh fonts first): the login screen uses a plain monospace font"; fi
  if [[ -f "$wall" ]]; then run sudo install -m 644 "$wall" "$dest/background.jpg"
  else warn "no wallpaper found (run ./install.sh wallpapers): the login screen has a plain background"; fi
  run sudo install -m 644 "$src/10-dotfiles.conf" /etc/sddm.conf.d/10-dotfiles.conf
  ok "login screen: carbon (preview without logging out: sddm-greeter-qt6 --test-mode --theme $dest)"
}

step_link() {
  step "Linking dotfiles (stow)"
  local pkgs
  mapfile -t pkgs < <(list_pkgs)
  (( ${#pkgs[@]} )) || { ok "no packages in home/"; return; }

  local p
  for p in "${pkgs[@]}"; do backup_conflicts "$p"; done

  # Simulate first so a problem in one package leaves $HOME untouched.
  local out
  out=$(stow --no-folding -n -d "$STOW_DIR" -t "$HOME" -R "${pkgs[@]}" 2>&1) \
    || die "stow simulation failed; nothing was changed:"$'\n'"$out"
  run stow --no-folding -d "$STOW_DIR" -t "$HOME" -R "${pkgs[@]}"
  ok "linked: ${pkgs[*]}"
  # GTK4 / libadwaita apps read gsettings, not settings.ini: copy the linked defaults (dark, fonts, themes) there.
  if command -v gsettings >/dev/null 2>&1 && [[ -x "$HOME/.local/bin/appearance" || $DRY_RUN == 1 ]]; then
    run "$HOME/.local/bin/appearance" sync
  fi
  (( DRY_RUN )) || verify_configs || die "fix the config above, then re-run ./install.sh link"
}

# Download fonts listed in system/fonts.txt (pinned URL + sha256) into the user font dir.
step_fonts() {
  step "Fonts"
  local manifest="$DOTFILES/system/fonts.txt" dest_root="$HOME/.local/share/fonts/dotfiles"
  [[ -f "$manifest" ]] || { ok "no system/fonts.txt"; return 0; }
  local cmd
  for cmd in curl sha256sum unzip fc-cache; do
    command -v "$cmd" >/dev/null || die "missing command: $cmd"
  done

  local name sha url dest tmp file changed=0
  while read -r name sha url; do
    dest="$dest_root/$name"
    # The .sha256 marker records what is installed, so unchanged fonts are skipped.
    if [[ -f "$dest/.sha256" && "$(<"$dest/.sha256")" == "$sha" ]]; then
      ok "$name (up to date)"
      continue
    fi
    if (( DRY_RUN )); then
      info "[dry-run] download $name from $url"
      continue
    fi

    info "downloading $name ..."
    tmp=$(mktemp -d)
    file="$tmp/${url##*/}"
    if ! curl -fsSL --retry 3 -o "$file" "$url"; then
      rm -rf "$tmp"; die "download failed: $url"
    fi
    if [[ "$(sha256sum "$file" | cut -d' ' -f1)" != "$sha" ]]; then
      rm -rf "$tmp"; die "checksum mismatch for $name (file changed upstream or download corrupted); nothing installed"
    fi

    # Build the new font dir next to the old one, then swap, so a failure leaves the old font intact.
    mkdir -p "$tmp/out"
    case "${file,,}" in
      *.zip)       unzip -qq -j "$file" '*.ttf' '*.otf' -d "$tmp/out" 2>/dev/null || true ;;
      *.ttf|*.otf) cp "$file" "$tmp/out/$name.${file##*.}" ;;
      *)           rm -rf "$tmp"; die "$name: unsupported file type: ${file##*/}" ;;
    esac
    compgen -G "$tmp/out/*" >/dev/null || { rm -rf "$tmp"; die "$name: no font files found in download"; }
    printf '%s\n' "$sha" > "$tmp/out/.sha256"
    mkdir -p "$dest_root"
    rm -rf "$dest"
    mv "$tmp/out" "$dest"
    rm -rf "$tmp"
    ok "$name installed ($(find "$dest" -type f ! -name .sha256 | wc -l) files)"
    changed=1
  done < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$manifest")

  if (( changed )); then
    fc-cache -f "$dest_root"
    ok "font cache refreshed"
  fi
}

# Generate the wallpapers (kept out of git: they are a few MB each and fully reproducible).
step_wallpapers() {
  step "Wallpapers"
  local gen="$DOTFILES/scripts/gen-wallpapers.py"
  [[ -f "$gen" ]] || { ok "no generator found"; return 0; }
  python3 -c 'import PIL' 2>/dev/null || { warn "Pillow missing (sudo dnf install python3-pillow); skipping"; return 0; }
  if (( DRY_RUN )); then
    info "[dry-run] python3 scripts/gen-wallpapers.py"
  else
    python3 "$gen"
  fi
  download_photos
}

# Download the photos listed in system/wallpapers.txt (pinned URL + sha256). Unlike fonts these are
# optional, so a problem with one photo only warns and moves on.
download_photos() {
  local manifest="$DOTFILES/system/wallpapers.txt" dest="$HOME/.local/share/wallpapers"
  [[ -f "$manifest" ]] || return 0
  local cmd
  for cmd in curl sha256sum; do
    command -v "$cmd" >/dev/null || { warn "missing $cmd; skipping photos"; return 0; }
  done
  mkdir -p "$dest"

  local name sha url file tmp got
  while read -r name sha url; do
    file="$dest/$name.jpg"
    if [[ -f "$file" && "$(sha256sum "$file" | cut -d' ' -f1)" == "$sha" ]]; then
      ok "$name.jpg (up to date)"
      continue
    fi
    if (( DRY_RUN )); then
      info "[dry-run] download $name.jpg"
      continue
    fi
    tmp=$(mktemp)
    if ! curl -fsSL --retry 3 --max-time 120 -o "$tmp" "$url"; then
      warn "$name: download failed; skipped"; rm -f "$tmp"; continue
    fi
    got=$(sha256sum "$tmp" | cut -d' ' -f1)
    if [[ "$got" != "$sha" ]]; then
      warn "$name: checksum changed upstream; skipped (update system/wallpapers.txt if you trust the new file)"
      rm -f "$tmp"; continue
    fi
    mv "$tmp" "$file"
    ok "$name.jpg downloaded"
  done < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$manifest")
}

step_defaults() {
  step "Default applications"
  command -v xdg-mime >/dev/null || { warn "xdg-mime not found (dnf install xdg-utils); skipping"; return 0; }
  local entry app types t
  for entry in "${MIME_DEFAULTS[@]}"; do
    read -r app types <<<"$entry"
    if ! [[ -f "/usr/share/applications/$app" || -f "$HOME/.local/share/applications/$app" ]]; then
      warn "$app is not installed; skipping"
      continue
    fi
    for t in $types; do
      if [[ "$(xdg-mime query default "$t" 2>/dev/null)" == "$app" ]]; then
        ok "$t -> $app (already set)"
      else
        run xdg-mime default "$app" "$t"
        ok "$t -> $app"
      fi
    done
  done
}

step_unlink() {
  step "Unlinking dotfiles"
  local pkgs
  mapfile -t pkgs < <(list_pkgs)
  (( ${#pkgs[@]} )) || return 0
  run stow -d "$STOW_DIR" -t "$HOME" -D "${pkgs[@]}"
  ok "removed links for: ${pkgs[*]}"
}

# ---------- main ----------
main() {
  local steps=()
  while (( $# )); do
    case $1 in
      -n|--dry-run) DRY_RUN=1 ;;
      -y|--yes)     ASSUME_YES=1 ;;
      -h|--help)    usage 0 ;;
      repos|packages|fonts|wallpapers|services|link|sddm|defaults|unlink) steps+=("$1") ;;
      *) warn "unknown argument: $1"; usage 1 ;;
    esac
    shift
  done
  (( ${#steps[@]} )) || steps=("${ALL_STEPS[@]}")

  preflight
  (( DRY_RUN )) && info "${C_Y}dry run: no changes will be made${C_0}"

  local s
  for s in "${steps[@]}"; do "step_$s"; done

  step "Done"
  [[ -d "$BACKUP_DIR" ]] && info "replaced files were saved in ${BACKUP_DIR/#"$HOME"/"~"}"
  return 0
}

main "$@"
