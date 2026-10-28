#!/bin/bash

# Omarchy on Arch Linux with MangoWC
#
# Installs the Arch/Mango fork into the current user's home directory:
#   ~/.local/share/omarchy     program files
#   ~/.config                  desktop configuration
#   /usr/local/share/wayland-sessions/omarchy-mango.desktop
#
# Existing ~/.config files that would be replaced are backed up first.
#
# Usage: ./install-arch.sh [--skip-packages] [--skip-aur] [--theme <name>]

set -eEo pipefail

SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OMARCHY_PATH="$HOME/.local/share/omarchy"
CONFIG_DIR="$HOME/.config"
STATE_DIR="$HOME/.local/state/omarchy"
THEME="tokyo-night"
SKIP_PACKAGES=false
SKIP_AUR=false

log() {
  printf '\n\033[1;34m==>\033[0m %s\n' "$*"
}

warn() {
  printf '\033[1;33mWarning:\033[0m %s\n' "$*" >&2
}

die() {
  printf '\033[1;31mError:\033[0m %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --skip-packages   Do not install Arch packages
  --skip-aur        Do not install optional AUR packages
  --theme <name>    Initial theme (default: tokyo-night)
  -h, --help        Show this help
EOF
}

while (($#)); do
  case "$1" in
  --skip-packages)
    SKIP_PACKAGES=true
    SKIP_AUR=true
    shift
    ;;
  --skip-aur)
    SKIP_AUR=true
    shift
    ;;
  --theme)
    THEME="${2:-}"
    [[ -n $THEME ]] || die "--theme requires a name"
    shift 2
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    die "Unknown option: $1"
    ;;
  esac
done

[[ -f /etc/arch-release ]] || die "This installer targets Arch Linux."

export OMARCHY_PATH
export PATH="$OMARCHY_PATH/bin:$HOME/.local/bin:$PATH"

install_packages() {
  local package_file="$SOURCE_DIR/install/omarchy-arch.packages"
  local package=""
  local pending=()

  [[ -f $package_file ]] || die "Missing package list: $package_file"

  while IFS= read -r package; do
    [[ -n $package ]] || continue
    pacman -Q "$package" >/dev/null 2>&1 || pending+=("$package")
  done < <(grep -vE '^[[:space:]]*(#|$)' "$package_file")

  if ((${#pending[@]} == 0)); then
    log "All Arch packages are already installed"
    return 0
  fi

  log "Installing ${#pending[@]} Arch packages (this can take a while)"
  sudo -v || die "sudo access is required to install packages"
  sudo pacman -Syu --noconfirm
  sudo pacman -S --needed --noconfirm "${pending[@]}"
}

install_aur_helper() {
  local tmp=""

  command -v yay >/dev/null 2>&1 && return 0
  command -v paru >/dev/null 2>&1 && return 0

  log "Installing the yay AUR helper"
  tmp="$(mktemp -d)"
  git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
  (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$tmp"
}

install_aur_packages() {
  local package_file="$SOURCE_DIR/install/omarchy-arch-aur.packages"
  local package=""
  local pending=()
  local helper=""

  [[ -f $package_file ]] || return 0

  while IFS= read -r package; do
    [[ -n $package ]] || continue
    pacman -Q "$package" >/dev/null 2>&1 || pending+=("$package")
  done < <(grep -vE '^[[:space:]]*(#|$)' "$package_file")

  if ((${#pending[@]} == 0)); then
    log "All optional AUR packages are already installed"
    return 0
  fi

  if ! install_aur_helper; then
    warn "Could not install an AUR helper; skipping: ${pending[*]}"
    return 0
  fi

  if command -v yay >/dev/null 2>&1; then
    helper=yay
  else
    helper=paru
  fi

  log "Installing ${#pending[@]} AUR packages"
  sudo -v || true
  "$helper" -S --needed --noconfirm "${pending[@]}" ||
    warn "Some AUR packages could not be installed: ${pending[*]}"
}

copy_program_files() {
  log "Installing Omarchy into $OMARCHY_PATH"

  mkdir -p "$OMARCHY_PATH"
  if [[ $SOURCE_DIR == "$OMARCHY_PATH" ]]; then
    log "Already running from $OMARCHY_PATH"
    return 0
  fi

  tar -C "$SOURCE_DIR" --exclude=.git -cf - . | tar -C "$OMARCHY_PATH" -xf -
}

backup_conflicts() {
  local backup_root="$CONFIG_DIR/omarchy-install-backup-$(date +%Y%m%d-%H%M%S)"
  local source="$SOURCE_DIR/config"
  local file=""
  local rel=""
  local target=""
  local backed_up=false

  while IFS= read -r -d '' file; do
    rel="${file#"$source"/}"
    target="$CONFIG_DIR/$rel"
    [[ -e $target || -L $target ]] || continue

    mkdir -p "$backup_root/$(dirname "$rel")"
    cp -a "$target" "$backup_root/$rel"
    backed_up=true
  done < <(find "$source" -type f -print0)

  if $backed_up; then
    log "Backed up replaced configuration to $backup_root"
  fi
}

copy_user_config() {
  log "Installing configuration into $CONFIG_DIR"

  mkdir -p "$CONFIG_DIR"
  backup_conflicts
  cp -a "$SOURCE_DIR/config/." "$CONFIG_DIR/"

  if [[ ! -f $HOME/.XCompose ]]; then
    cat >"$HOME/.XCompose" <<'EOF'
include "%H/.local/share/omarchy/default/xcompose"
EOF
  fi

  mkdir -p "$HOME/.local/share/fonts"
  cp -f "$OMARCHY_PATH/config/omarchy.ttf" "$HOME/.local/share/fonts/omarchy.ttf"
  command -v fc-cache >/dev/null 2>&1 && fc-cache -f >/dev/null 2>&1 || true
}

install_bash_shell() {
  local target="$HOME/.bashrc.d/omarchy.sh"
  local bashrc="$HOME/.bashrc"

  log "Installing the Omarchy bash shell setup"
  mkdir -p "$HOME/.bashrc.d"
  if [[ -f $target ]] && ! cmp -s "$OMARCHY_PATH/default/bashrc.d/omarchy.sh" "$target"; then
    cp -a "$target" "$target.bak-$(date +%Y%m%d-%H%M%S)"
  fi
  install -m644 "$OMARCHY_PATH/default/bashrc.d/omarchy.sh" "$target"

  # Arch's stock ~/.bashrc does not read ~/.bashrc.d.
  touch "$bashrc"
  if ! grep -qF '.bashrc.d/omarchy.sh' "$bashrc"; then
    printf '\n# Omarchy shell setup\n[[ -f ~/.bashrc.d/omarchy.sh ]] && source ~/.bashrc.d/omarchy.sh\n' >>"$bashrc"
  fi
}

install_ly() {
  log "Configuring the Ly login manager"

  if ! command -v ly-dm >/dev/null 2>&1; then
    warn "ly is not installed; skipping login manager setup"
    return 0
  fi

  sudo -v || die "sudo access is required to configure Ly"
  if [[ -f /etc/ly/config.ini ]] && ! sudo cmp -s "$OMARCHY_PATH/default/ly/config.ini" /etc/ly/config.ini; then
    sudo cp -a /etc/ly/config.ini "/etc/ly/config.ini.bak-$(date +%Y%m%d-%H%M%S)"
  fi
  sudo install -Dm644 "$OMARCHY_PATH/default/ly/config.ini" /etc/ly/config.ini
  sed "s|@HOME@|$HOME|g" "$OMARCHY_PATH/default/ly/startup.sh" | sudo tee /etc/ly/startup.sh >/dev/null
  sudo chmod 755 /etc/ly/startup.sh
  for dm in gdm sddm lightdm; do
    sudo systemctl disable "$dm.service" >/dev/null 2>&1 || true
  done
  sudo systemctl disable getty@tty1.service >/dev/null 2>&1 || true
  sudo systemctl enable ly@tty1.service
}

install_lock_auth() {
  log "Configuring lock screen authentication"
  OMARCHY_INSTALL_USER="$USER" "$OMARCHY_PATH/bin/omarchy-apply-lock" ||
    warn "Could not configure lock screen authentication"
}

install_session_file() {
  log "Installing the Omarchy (Mango) Wayland session"
  sudo -v || die "sudo access is required to install the Wayland session file"
  # Ly 1.4 only scans /usr/share/wayland-sessions, so install there rather
  # than /usr/local/share where Ly would not list the session.
  sudo install -Dm644 "$OMARCHY_PATH/default/wayland-sessions/omarchy-mango.desktop" \
    /usr/share/wayland-sessions/omarchy-mango.desktop
}

configure_browser() {
  local browser="chromium.desktop"

  if [[ -f /usr/share/applications/helium.desktop ]]; then
    browser="helium.desktop"
  fi

  log "Preparing the Chromium theme policy directory"
  sudo -v || die "sudo access is required to create the browser policy directory"
  sudo mkdir -p /etc/chromium/policies/managed
  sudo chmod a+rw /etc/chromium/policies/managed

  log "Setting $browser as the default browser"
  xdg-settings set default-web-browser "$browser" || warn "Could not set the default browser"
  xdg-mime default "$browser" x-scheme-handler/http
  xdg-mime default "$browser" x-scheme-handler/https
  xdg-mime default "$browser" text/html
}

prepare_theme() {
  local current="$CONFIG_DIR/omarchy/current"
  local theme_source="$OMARCHY_PATH/themes/$THEME"
  local background=""

  [[ -d $theme_source ]] || die "Theme '$THEME' does not exist in $OMARCHY_PATH/themes"

  log "Preparing the initial theme: $THEME"

  mkdir -p "$current"
  rm -rf "$current/next-theme"
  mkdir -p "$current/next-theme"
  cp -a "$theme_source/." "$current/next-theme/"

  OMARCHY_PATH="$OMARCHY_PATH" "$OMARCHY_PATH/bin/omarchy-theme-set-templates"

  rm -rf "$current/theme"
  mv "$current/next-theme" "$current/theme"
  printf '%s\n' "$THEME" >"$current/theme.name"

  background=$(find -L "$current/theme/backgrounds" -maxdepth 1 -type f \
    ! -iregex '.*\.\(mp4\|m4v\|mov\|webm\|mkv\|avi\)$' 2>/dev/null | sort | head -n 1 || true)
  [[ -n $background ]] || background=$(find -L "$current/theme/backgrounds" -maxdepth 1 -type f 2>/dev/null | sort | head -n 1 || true)
  if [[ -n $background ]]; then
    ln -nsf "$background" "$current/background"
  fi

  mkdir -p "$CONFIG_DIR/btop/themes"
  ln -snf "$current/theme/btop.theme" "$CONFIG_DIR/btop/themes/current.theme"

  PATH="$OMARCHY_PATH/bin:$PATH" OMARCHY_PATH="$OMARCHY_PATH" "$OMARCHY_PATH/bin/omarchy-theme-set-gnome" ||
    warn "Could not apply the GTK theme"
  PATH="$OMARCHY_PATH/bin:$PATH" OMARCHY_PATH="$OMARCHY_PATH" "$OMARCHY_PATH/bin/omarchy-theme-set-qt" ||
    warn "Could not apply the Qt theme"
  PATH="$OMARCHY_PATH/bin:$PATH" OMARCHY_PATH="$OMARCHY_PATH" "$OMARCHY_PATH/bin/omarchy-theme-set-neovim" ||
    warn "Could not apply the Neovim theme"
  PATH="$OMARCHY_PATH/bin:$PATH" OMARCHY_PATH="$OMARCHY_PATH" "$OMARCHY_PATH/bin/omarchy-theme-set-browser" ||
    warn "Could not apply the browser theme"
}

mark_migrations_applied() {
  local migration=""

  log "Marking Arch migrations as applied"
  mkdir -p "$STATE_DIR/migrations"
  for migration in "$OMARCHY_PATH"/migrations/*.sh; do
    [[ -f $migration ]] || continue
    touch "$STATE_DIR/migrations/$(basename "$migration")"
  done
}

verify_install() {
  local failed=false
  local command=""

  for command in mango mmsg quickshell qs cmatrix ly-dm foot; do
    if ! command -v "$command" >/dev/null 2>&1; then
      warn "Required command not found: $command"
      failed=true
    fi
  done

  if [[ -x $OMARCHY_PATH/bin/omarchy-mango-session && -x $OMARCHY_PATH/bin/hyprctl ]]; then
    log "Omarchy launchers are executable"
  else
    warn "Omarchy launchers are missing executable bits"
    failed=true
  fi

  log "Validating the Mango configuration"
  if ! mango -c "$CONFIG_DIR/mango/config.conf" -p; then
    warn "Mango reported configuration problems (see above)"
    failed=true
  fi

  $failed && return 1
  return 0
}

if ! $SKIP_PACKAGES; then
  install_packages
  if ! $SKIP_AUR; then
    install_aur_packages
  fi
fi

copy_program_files
copy_user_config
install_bash_shell
install_session_file
install_ly
configure_browser
prepare_theme
install_lock_auth
mark_migrations_applied

cat <<EOF

Omarchy for Mango is installed.

Next steps:
  1. Log out and choose "Omarchy (Mango)" on the login screen.
     From a TTY you can also run:
       exec $OMARCHY_PATH/bin/omarchy-mango-session
  2. Change themes with: omarchy-theme-set "Tokyo Night"
  3. Check key bindings with: omarchy-menu-keybindings
  4. Launch the themed matrix with: omarchy-launch-cmatrix
     or Super + Shift + Alt + C
  5. Update later with: omarchy update

Mango limitations are documented in README.md (no mirroring, per-window
opacity, or lid-switch events; best-effort fallbacks are provided).
EOF

if verify_install; then
  log "Installation verified"
else
  warn "Installation finished, but verification found problems"
  exit 1
fi
