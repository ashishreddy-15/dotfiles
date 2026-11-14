#!/usr/bin/env bash
#
# Bootstrap this machine from the dotfiles repo. Safe to re-run at any time.
#
#   ./install.sh                 run every step (repos packages flatpaks sdkman fonts wallpapers link services sddm defaults)
#   ./install.sh link            run only the given step(s)
#   ./install.sh -n              dry run: show what would happen, change nothing
#   ./install.sh -y              don't ask dnf for confirmation
#   ./install.sh unlink          remove all dotfile symlinks from $HOME
#
# Steps:
#   repos     install repo files from system/repos/ into /etc/yum.repos.d/
#   packages  dnf install everything in packages/*.txt,
#             then dnf remove everything in packages/remove.txt
#   flatpaks  install the apps in packages/flatpak.txt from Flathub, for your user (no sudo)
#   sdkman    install SDKMAN and the Java / Maven versions in packages/sdkman.txt, for your user (no sudo)
#   fonts     download fonts in system/fonts.txt (pinned + checksummed) to ~/.local/share/fonts
#   wallpapers download the photos in system/wallpapers.txt (pinned + checksummed) to ~/.local/share/wallpapers
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
ALL_STEPS=(repos packages flatpaks sdkman fonts wallpapers link services sddm defaults)

# Default applications: "<desktop file> <mime type>..."
MIME_DEFAULTS=(
  "org.gnome.Nautilus.desktop inode/directory"
)

DRY_RUN=0
ASSUME_YES=0

# ---------- output ----------
# shellcheck source=scripts/lib/ui.sh
source "$DOTFILES/scripts/lib/ui.sh"

trap 'die "failed at line $LINENO: $BASH_COMMAND"' ERR

# Run a command, or in a dry run skip it silently (each step says in words what it would do).
act() { (( DRY_RUN )) || "$@"; }

# Print the comment block at the top of this file.
usage() { awk 'NR>2 && /^#/ {sub(/^# ?/, ""); print; next} NR>2 {exit}' "${BASH_SOURCE[0]}"; exit "${1:-0}"; }

# Read package names from a list file: strip comments and blank lines.
read_list() { sed -e 's/#.*//' -e 's/[[:space:]]\+$//' -e '/^[[:space:]]*$/d' "$1"; }

# "a b c" as "a, b, c", or "a, b ... (12)" when long.
list_words() {
  local n=$# out
  if (( n > 6 )); then out="$1, $2, $3, $4 and $(( n - 4 )) more"; else out=$(printf '%s, ' "$@"); out=${out%, }; fi
  printf '%s' "$out"
}

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
  sudo -n true 2>/dev/null && return 0
  doing "this needs your password (sudo)"
  sudo -v || die "sudo authentication failed"
}

# ---------- steps ----------
step_repos() {
  step "Repositories" "extra package sources: Hyprland and Quickshell (COPR)"
  local src name dest fine=0
  for src in "$DOTFILES"/system/repos/*.repo; do
    name=$(basename "$src" .repo); name=${name##*:}
    dest="/etc/yum.repos.d/$(basename "$src")"
    if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then fine=$(( fine + 1 )); continue; fi
    if (( DRY_RUN )); then would "add the $name repository"; continue; fi
    [[ -f "$dest" ]] && warn "the installed $name repository differs: replacing it"
    need_sudo
    sudo install -m 0644 -o root -g root "$src" "$dest"
    done_ "added the $name repository"
  done
  (( fine )) && ok "$fine repositories already set up"

  # Warn about other Hyprland COPRs that would compete with ours.
  local f ours
  for f in /etc/yum.repos.d/*hypr*.repo; do
    ours=0
    for src in "$DOTFILES"/system/repos/*.repo; do
      [[ "$(basename "$src")" == "$(basename "$f")" ]] && ours=1
    done
    (( ours )) || warn "another Hyprland repository is present: $f (consider removing it)"
  done
}

step_packages() {
  step "Packages" "Fedora packages from packages/*.txt (and removals from remove.txt)"
  local list p pkgs=() unwanted=() lists=0
  for list in "$DOTFILES"/packages/*.txt; do
    [[ "$list" == "$REMOVE_LIST" ]] && continue
    [[ "$(basename "$list")" == flatpak.txt ]] && continue      # Flathub apps: step_flatpaks
    [[ "$(basename "$list")" == sdkman.txt ]] && continue       # Java / Maven: step_sdkman
    mapfile -t -O "${#pkgs[@]}" pkgs < <(read_list "$list")
    lists=$(( lists + 1 ))
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
  if (( ${#missing[@]} == 0 )); then
    ok "all ${#pkgs[@]} packages installed ($lists lists)"
  elif (( DRY_RUN )); then
    would "install ${#missing[@]}: $(list_words "${missing[@]}")"
  else
    doing "installing ${#missing[@]} with dnf: $(list_words "${missing[@]}")"
    need_sudo
    sudo dnf install "${yes[@]}" "${missing[@]}"
    done_ "installed $(list_words "${missing[@]}")"
  fi

  local present=()
  for p in "${unwanted[@]}"; do
    rpm -q "$p" >/dev/null 2>&1 && present+=("$p")
  done
  if (( ${#present[@]} == 0 )); then
    (( ${#unwanted[@]} )) && ok "nothing to remove (${#unwanted[@]} unwanted packages are not installed)"
  elif (( DRY_RUN )); then
    would "remove ${#present[@]}: $(list_words "${present[@]}")"
  else
    doing "removing ${#present[@]} with dnf (and what only they needed): $(list_words "${present[@]}")"
    need_sudo
    sudo dnf remove "${yes[@]}" "${present[@]}"
    gone "removed $(list_words "${present[@]}")"
  fi
}

step_services() {
  step "Services" "which system and user services are on or off"
  # Both scripts write into this run's summary; a dry run only reads the state, so it needs no root.
  local vars=(UI_EVENTS_FILE="$UI_EVENTS_FILE" UI_STEP_NAME="$UI_STEP_NAME" DRY_RUN="$DRY_RUN")
  [[ -t 1 ]] || vars+=(NO_COLOR=1)
  info "system services"
  if (( DRY_RUN )); then
    env "${vars[@]}" bash "$DOTFILES/system/services.sh"
  else
    need_sudo
    sudo env "${vars[@]}" bash "$DOTFILES/system/services.sh"
  fi
  info "your services (start with your session)"
  env "${vars[@]}" bash "$DOTFILES/system/user-services.sh"
}

# Catch config mistakes now instead of at the next login.
verify_configs() {
  if command -v Hyprland >/dev/null && [[ -f "$HOME/.config/hypr/hyprland.lua" ]]; then
    local out
    if out=$(Hyprland --verify-config -c "$HOME/.config/hypr/hyprland.lua" 2>&1); then
      ok "the Hyprland config is valid"
    else
      warn "the Hyprland config has errors:"
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

    if (( DRY_RUN )); then would "move ~/$rel aside (to the backup folder), to link the repo's version"; continue; fi
    mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
    mv "$target" "$BACKUP_DIR/$rel"
    warn "moved ~/$rel aside to ${BACKUP_DIR/#"$HOME"/"~"}/$rel"
  done < <(find "$STOW_DIR/$pkg" \( -type f -o -type l \) -print0)
}

list_pkgs() {
  local d
  for d in "$STOW_DIR"/*/; do basename "$d"; done
}

# Login screen: the carbon theme (system/sddm/carbon). SDDM runs as its own user and cannot read $HOME, so the font
# and the current wallpaper are copied into the theme. Re-run after changing the wallpaper to update it there too.
step_sddm() {
  step "Login screen" "the carbon theme for SDDM, with your font and wallpaper copied in"
  command -v sddm >/dev/null 2>&1 || { ok "SDDM is not installed: nothing to do"; return 0; }
  local src="$DOTFILES/system/sddm" dest=/usr/share/sddm/themes/carbon
  local font="$HOME/.local/share/fonts/dotfiles/maple-mono-nf/MapleMono-NF-Regular.ttf"
  local wall
  wall=$(cat "$HOME/.local/state/dotfiles/wallpaper" 2>/dev/null || true)
  [[ -f "$wall" ]] || wall=$(find "$HOME/.local/share/wallpapers" -maxdepth 1 -type f 2>/dev/null | sort | head -1)

  # What should be where: "<source> <destination>" pairs.
  local pairs=() f
  for f in "$src"/carbon/*; do pairs+=("$f" "$dest/$(basename "$f")"); done
  if [[ -f "$font" ]]; then
    pairs+=("$font" "$dest/MapleMono-NF-Regular.ttf" "${font%Regular.ttf}Light.ttf" "$dest/MapleMono-NF-Light.ttf")
  else warn "Maple Mono is not installed (./install.sh fonts): the login screen falls back to a plain font"; fi
  if [[ -f "$wall" ]]; then pairs+=("$wall" "$dest/background.jpg")
  else warn "no wallpaper found (./install.sh wallpapers): the login screen gets a plain background"; fi
  pairs+=("$src/10-dotfiles.conf" /etc/sddm.conf.d/10-dotfiles.conf)

  # Only what differs is copied (and only then is your password needed).
  local i changed=()
  for (( i = 0; i < ${#pairs[@]}; i += 2 )); do
    cmp -s "${pairs[i]}" "${pairs[i+1]}" 2>/dev/null || changed+=("${pairs[i]}" "${pairs[i+1]}")
  done
  if (( ${#changed[@]} == 0 )); then
    ok "the login screen is up to date (wallpaper: $(basename "${wall:-none}"))"
    return 0
  fi
  local n=$(( ${#changed[@]} / 2 )) files
  files="$n file$( (( n == 1 )) || echo s)"
  if (( DRY_RUN )); then would "update the login screen ($files; wallpaper: $(basename "${wall:-none}"))"; return 0; fi
  need_sudo
  sudo install -d -m 755 "$dest" /etc/sddm.conf.d
  for (( i = 0; i < ${#changed[@]}; i += 2 )); do sudo install -m 644 "${changed[i]}" "${changed[i+1]}"; done
  done_ "updated the login screen ($files; wallpaper: $(basename "${wall:-none}"))"
  info "see it at the next login, or now: sddm-greeter-qt6 --test-mode --theme $dest"
}

# Apps from Flathub (packages/flatpak.txt), for your user only: no sudo, nothing system-wide.
step_flatpaks() {
  step "Flatpaks" "apps from Flathub, for your user only"
  local list="$DOTFILES/packages/flatpak.txt"
  [[ -f "$list" ]] || { ok "no packages/flatpak.txt: nothing to do"; return 0; }
  command -v flatpak >/dev/null 2>&1 || { warn "flatpak is not installed: skipped"; return 0; }
  act flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  # Let Flatpak apps read (only read) the GTK settings in this repo, so they get the same palette, corners and font.
  act flatpak override --user --filesystem="$STOW_DIR/gtk:ro"
  local app apps=() missing=()
  while read -r app; do
    apps+=("$app")
    flatpak info --user "$app" >/dev/null 2>&1 || missing+=("$app")
  done < <(read_list "$list")
  if (( ${#missing[@]} == 0 )); then
    ok "all ${#apps[@]} Flathub apps installed ($(list_words "${apps[@]##*.}"))"
  elif (( DRY_RUN )); then
    would "install $(list_words "${missing[@]##*.}")"
  else
    doing "installing $(list_words "${missing[@]##*.}") from Flathub"
    flatpak install --user --noninteractive flathub "${missing[@]}"
    done_ "installed $(list_words "${missing[@]##*.}")"
  fi
  # Inside the sandbox GTK reads its config from the app's own folder (~/.var/app/<id>/config), not ~/.config:
  # link the repo's gtk.css and settings.ini into it (absolute paths: stow's relative links would not resolve there).
  local f
  for app in "${apps[@]}"; do
    act mkdir -p "$HOME/.var/app/$app/config/gtk-4.0"
    for f in gtk.css settings.ini; do
      act ln -sfn "$STOW_DIR/gtk/.config/gtk-4.0/$f" "$HOME/.var/app/$app/config/gtk-4.0/$f"
    done
  done
}

# Java, Maven... with SDKMAN (packages/sdkman.txt), for your user only. SDKMAN is told not to edit ~/.bashrc:
# home/bash/.bashrc.d/40-sdkman.sh sets up PATH and JAVA_HOME without slowing the shell down.
step_sdkman() {
  step "SDKMAN" "Java and Maven, for your user only"
  local list="$DOTFILES/packages/sdkman.txt" dir="$HOME/.sdkman"
  [[ -f "$list" ]] || { ok "no packages/sdkman.txt: nothing to do"; return 0; }
  if [[ -f "$dir/bin/sdkman-init.sh" ]]; then
    :
  elif (( DRY_RUN )); then
    would "install SDKMAN into ~/.sdkman"
  else
    doing "installing SDKMAN"
    local tmp; tmp=$(mktemp)
    curl -fsSL "https://get.sdkman.io?rcupdate=false" -o "$tmp" || { warn "could not download SDKMAN"; rm -f "$tmp"; return 0; }
    bash "$tmp" >/dev/null && done_ "installed SDKMAN"
    rm -f "$tmp"
  fi
  local cand ver
  if (( DRY_RUN )); then
    while read -r cand ver; do
      if [[ -d "$dir/candidates/$cand/$ver" ]]; then ok "$cand $ver"; else would "install $cand $ver"; fi
    done < <(read_list "$list")
    return 0
  fi
  # SDKMAN's scripts use unset variables, which this script treats as errors (set -u): allow them around its calls.
  set +u
  # shellcheck disable=SC1091
  source "$dir/bin/sdkman-init.sh"
  while read -r cand ver; do
    if [[ -d "$dir/candidates/$cand/$ver" ]]; then ok "$cand $ver"
    else
      doing "installing $cand $ver"
      if yes | sdk install "$cand" "$ver" >/dev/null 2>&1; then done_ "installed $cand $ver"
      else warn "$cand $ver: install failed"; continue; fi
    fi
    sdk default "$cand" "$ver" >/dev/null 2>&1
  done < <(read_list "$list")
  set -u
}

step_link() {
  step "Linking" "your configs from home/ into ~ (GNU stow)"
  local pkgs
  mapfile -t pkgs < <(list_pkgs)
  (( ${#pkgs[@]} )) || { ok "no packages in home/: nothing to do"; return; }

  local p
  for p in "${pkgs[@]}"; do backup_conflicts "$p"; done

  # Simulate first so a problem in one package leaves $HOME untouched.
  local out
  out=$(stow --no-folding -n -d "$STOW_DIR" -t "$HOME" -R "${pkgs[@]}" 2>&1) \
    || die "stow simulation failed; nothing was changed:"$'\n'"$out"
  act stow --no-folding -d "$STOW_DIR" -t "$HOME" -R "${pkgs[@]}"
  ok "${#pkgs[@]} packages linked: ${pkgs[*]}"
  # GTK4 / libadwaita apps read gsettings, not settings.ini: copy the linked defaults (dark, fonts, themes) there.
  if command -v gsettings >/dev/null 2>&1 && [[ -x "$HOME/.local/bin/appearance" ]]; then
    act "$HOME/.local/bin/appearance" sync >/dev/null
  fi
  (( DRY_RUN )) || verify_configs || die "fix the config above, then re-run ./install.sh link"
}

# Download fonts listed in system/fonts.txt (pinned URL + sha256) into the user font dir.
step_fonts() {
  step "Fonts" "pinned downloads, checked against their checksums"
  local manifest="$DOTFILES/system/fonts.txt" dest_root="$HOME/.local/share/fonts/dotfiles"
  [[ -f "$manifest" ]] || { ok "no system/fonts.txt: nothing to do"; return 0; }
  local cmd
  for cmd in curl sha256sum unzip fc-cache; do
    command -v "$cmd" >/dev/null || die "missing command: $cmd"
  done

  local name sha url dest tmp file changed=0
  while read -r name sha url; do
    dest="$dest_root/$name"
    # The .sha256 marker records what is installed, so unchanged fonts are skipped.
    if [[ -f "$dest/.sha256" && "$(<"$dest/.sha256")" == "$sha" ]]; then
      ok "$name"
      continue
    fi
    if (( DRY_RUN )); then would "download $name"; continue; fi

    doing "downloading $name"
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
    done_ "installed $name ($(find "$dest" -type f ! -name .sha256 | wc -l) files)"
    changed=1
  done < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$manifest")

  (( changed )) && fc-cache -f "$dest_root"
  return 0
}

step_wallpapers() {
  step "Wallpapers" "pinned photos from Unsplash, checked against their checksums"
  download_photos
}

# Download the photos listed in system/wallpapers.txt (pinned URL + sha256). Unlike fonts these are
# optional, so a problem with one photo only warns and moves on.
download_photos() {
  local manifest="$DOTFILES/system/wallpapers.txt" dest="$HOME/.local/share/wallpapers"
  [[ -f "$manifest" ]] || return 0
  local cmd
  for cmd in curl sha256sum; do
    command -v "$cmd" >/dev/null || { warn "missing $cmd: photos skipped"; return 0; }
  done
  mkdir -p "$dest"

  local name sha url file tmp got fine=0
  while read -r name sha url; do
    file="$dest/$name.jpg"
    if [[ -f "$file" && "$(sha256sum "$file" | cut -d' ' -f1)" == "$sha" ]]; then fine=$(( fine + 1 )); continue; fi
    if (( DRY_RUN )); then would "download $name"; continue; fi
    doing "downloading $name"
    tmp=$(mktemp)
    if ! curl -fsSL --retry 3 --max-time 120 -o "$tmp" "$url"; then
      warn "$name: download failed; skipped"; rm -f "$tmp"; continue
    fi
    got=$(sha256sum "$tmp" | cut -d' ' -f1)
    if [[ "$got" != "$sha" ]]; then
      warn "$name: the photo changed upstream; skipped (update system/wallpapers.txt if you trust the new one)"
      rm -f "$tmp"; continue
    fi
    mv "$tmp" "$file"
    done_ "downloaded $name"
  done < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$manifest")
  (( fine )) && ok "$fine wallpapers up to date"

  # Remove what is no longer in the list (this folder holds only the listed photos; your own are in ~/Pictures/Wallpapers).
  local listed f
  listed=$(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$manifest" | awk '{print $1 ".jpg"}')
  for f in "$dest"/*; do
    [[ -f "$f" ]] || continue
    grep -qxF "$(basename "$f")" <<<"$listed" && continue
    if (( DRY_RUN )); then would "remove $(basename "$f" .jpg) (no longer listed)"; continue; fi
    rm -f "$f"
    gone "removed $(basename "$f" .jpg) (no longer listed)"
  done
}

step_defaults() {
  step "Default apps" "which app opens what"
  command -v xdg-mime >/dev/null || { warn "xdg-mime not found (dnf install xdg-utils): skipped"; return 0; }
  local entry app types t
  for entry in "${MIME_DEFAULTS[@]}"; do
    read -r app types <<<"$entry"
    if ! [[ -f "/usr/share/applications/$app" || -f "$HOME/.local/share/applications/$app" ]]; then
      warn "$app is not installed: skipped"
      continue
    fi
    for t in $types; do
      if [[ "$(xdg-mime query default "$t" 2>/dev/null)" == "$app" ]]; then
        ok "$t opens with ${app%.desktop}"
      elif (( DRY_RUN )); then
        would "open $t with ${app%.desktop}"
      else
        xdg-mime default "$app" "$t"
        done_ "$t now opens with ${app%.desktop}"
      fi
    done
  done
}

step_unlink() {
  step "Unlinking" "removing the links into ~ (your files in the repo stay)"
  local pkgs
  mapfile -t pkgs < <(list_pkgs)
  (( ${#pkgs[@]} )) || return 0
  if (( DRY_RUN )); then would "remove the links of ${#pkgs[@]} packages"; return 0; fi
  stow -d "$STOW_DIR" -t "$HOME" -D "${pkgs[@]}"
  gone "removed the links of ${#pkgs[@]} packages: $(printf '%s ' "${pkgs[@]}")"
}

# ---------- main ----------
main() {
  local steps=()
  while (( $# )); do
    case $1 in
      -n|--dry-run) DRY_RUN=1 ;;
      -y|--yes)     ASSUME_YES=1 ;;
      -h|--help)    usage 0 ;;
      repos|packages|flatpaks|sdkman|fonts|wallpapers|services|link|sddm|defaults|unlink) steps+=("$1") ;;
      *) warn "unknown argument: $1"; usage 1 ;;
    esac
    shift
  done
  (( ${#steps[@]} )) || steps=("${ALL_STEPS[@]}")

  preflight
  UI_EVENTS_FILE=$(mktemp)
  export UI_EVENTS_FILE
  trap 'rm -f "$UI_EVENTS_FILE"' EXIT
  UI_STEP_TOTAL=${#steps[@]}

  ui_banner "${NAME:-Fedora} ${VERSION_ID:-}  ·  $USER@$(hostname -s)" \
    "$( (( DRY_RUN )) && printf 'dry run: nothing will be changed  ·  ' )steps: ${steps[*]}"

  local s
  for s in "${steps[@]}"; do "step_$s"; done

  ui_summary "$DRY_RUN"
  [[ -d "$BACKUP_DIR" ]] && info "files that were in the way are in ${BACKUP_DIR/#"$HOME"/"~"}"
  printf '\n'
  return 0
}

main "$@"
