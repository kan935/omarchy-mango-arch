# Omarchy for Arch Linux + MangoWC

This is a fork of [Omarchy](https://github.com/basecamp/omarchy) for **Arch
Linux** and **[MangoWC](https://github.com/mangowm/mango)**. It keeps Omarchy's
themes, menus, CLI, keybinding conventions, screenshots, recording, idle/lock,
and desktop helpers, while combining them with the Omarchy 4 "Quattro"
Quickshell desktop from the upstream `quattro` channel.

Quattro is the only desktop shell: bar, tags, menus, notifications, OSD,
wallpaper, theme and background pickers, idle/lock screen, and the polkit
agent. The Hyprland-specific Quattro integrations are patched to Mango's
`mmsg` IPC and `wlr-randr`. The Omarchy 3 stack (Waybar, Walker, Mako, swaybg,
swayidle, and SwayOSD) is not installed or started.

## Requirements

- Arch Linux (x86_64)
- MangoWC 0.18.2 or newer (`mangowm` from the official repositories)
- Quickshell 0.3.2 or newer (`quickshell` from the official repositories)
- A Wayland session manager or display manager. The installer configures
  [Ly](https://github.com/fairy-witch/ly) on tty1; GDM, SDDM, greetd, or a
  plain TTY also work.

Quattro is required for the desktop bar and panels. Mango will start without
it, but there is no secondary Waybar/Walker session.

Verify the compositor before installing:

```bash
mango -v
mmsg --help
```

## Install

```bash
git clone <your-fork-url> ~/omarchy-mango
cd ~/omarchy-mango
./install-arch.sh
```

The installer:

- installs the official Arch packages in `install/omarchy-arch.packages`
- optionally enables Chaotic-AUR and installs the desktop extras in
  `install/omarchy-arch-chaotic.packages` from that binary repository
- installs the iA Writer fonts directly from upstream, because Chaotic-AUR
  does not carry `ttf-ia-writer`
- copies the fork to `~/.local/share/omarchy`, including the Quattro `shell/`
  and every theme background
- copies `config/*` to `~/.config`, backing up replaced files to
  `~/.config/omarchy-install-backup-<timestamp>`
- installs `~/.bashrc.d/omarchy.sh` and makes `~/.bashrc` source it (starship
  prompt, zoxide, fzf, eza and aliases)
- installs `/usr/share/wayland-sessions/omarchy-mango.desktop`
- configures Ly (`/etc/ly/config.ini` and a theme-aware `/etc/ly/startup.sh`),
  disables other display managers and `getty@tty1`, and enables
  `ly@tty1.service`
- prepares the `tokyo-night` theme, background symlink, Quattro `shell.json`,
  btop theme, and GTK/Qt/Neovim/browser colors
- writes the PAM service used by the Quattro lock screen
- marks the upstream migrations as already applied
- validates the generated Mango configuration

Useful options:

```bash
./install-arch.sh --skip-packages   # copy config and set up the session only
./install-arch.sh --skip-extras     # official repositories only
./install-arch.sh --theme gruvbox
```

The installer does not start Mango or restart your current desktop session.

### Optional Chaotic-AUR packages

`install/omarchy-arch-chaotic.packages` contains the few desktop extras that
Arch only carries in the AUR. The installer adds the
[Chaotic-AUR](https://aur.chaotic.cx/) binary repository (keyring, mirror list,
and `[chaotic-aur]` entry in `/etc/pacman.conf`) and installs them with
`pacman`, so no AUR helper or local build is required:

- `yaru-icon-theme` and `bibata-cursor-theme` for the Omarchy look
- `helium-browser-bin` for the Omarchy browser

Chaotic-AUR does not carry `ttf-ia-writer`, so the installer downloads the
pinned iA-Fonts archive from upstream and installs the static Mono, Quattro,
Duo, and Duospace fonts into `/usr/share/fonts/ttf-ia-writer`.

If Chaotic-AUR is unavailable, the installer warns and leaves Chromium plus the
Adwaita/Papirus icons in place. Pass `--skip-extras` to skip all optional
packages and leave `/etc/pacman.conf` untouched.

## Log in

Log out, then choose **Omarchy (Mango)** in Ly or your display manager. Mango
starts and launches Quattro automatically. There is no secondary bar session.

The installer enables `ly@tty1.service` and disables `getty@tty1.service`. To
keep another display manager instead, run
`sudo systemctl disable ly@tty1.service` before rebooting.

From a TTY, start the session directly:

```bash
exec ~/.local/share/omarchy/bin/omarchy-mango-session
```

Quattro's startup is managed by
`~/.local/share/omarchy/bin/omarchy-mango-session-start`. The shell's log is
written to `$XDG_RUNTIME_DIR/omarchy/shell.log`.

Mango reads `~/.config/mango/config.conf`. The repository's entry point layers
Omarchy defaults, the generated theme, user overrides, and persistent toggle
snippets in this order:

```text
~/.config/mango/config.conf
├── ~/.local/share/omarchy/default/mango/{envs,looknfeel,input,windows,autostart}.conf
├── ~/.config/omarchy/current/theme/mango.conf
├── ~/.config/mango/{monitors,input,bindings,looknfeel,autostart}.conf
└── ~/.local/state/omarchy/toggles/mango/*.conf
```

Validate the result at any time:

```bash
mango -c ~/.config/mango/config.conf -p
```

## Themed matrix

Ly's built-in `animation = matrix` draws the login screen matrix. Its TTY
palette is rewritten at login from the active Omarchy theme, so the animation
follows the theme colors.

Inside the desktop, launch the themed matrix with:

```bash
omarchy-launch-cmatrix
```

or `Super + Shift + Alt + C`, or **System → Matrix** in the Omarchy menu.
It runs `cmatrix` in `foot`, whose palette is generated from the same active
theme, so the colors change with `omarchy-theme-set`.

## Key bindings

Mango uses the same `Super`-based layout as Omarchy. The main bindings:

| Binding | Action |
| --- | --- |
| `Super + Return` | Terminal (Foot via `xdg-terminal-exec`) |
| `Super + B` | Browser |
| `Super + Shift + B` | Private browser |
| `Super + E` | File manager (Nautilus) |
| `Super + Shift + A` | Coding agent picker |
| `Super + Space` | Omarchy menu (Quattro) |
| `Super + Alt + Space` | Omarchy apps menu |
| `Super + Ctrl + V` | Clipboard history |
| `Super + Ctrl + E` | Emoji picker |
| `Super + Ctrl + C` | Capture menu |
| `Super + Ctrl + Space` | Background picker |
| `Super + Shift + Ctrl + Space` | Theme picker |
| `Super + Q` | Close window |
| `Super + Z` | Toggle floating |
| `Super + F` | Toggle fullscreen |
| `Super + J` | Toggle dwindle split direction |
| `Super + L` | Toggle Dwindle/Scroller layout |
| `Super + O` | Pop window out as floating/sticky |
| `Super + 1..0` | Switch to tag 1..10 |
| `Super + Shift + 1..0` | Move window to tag 1..10 |
| `Super + Shift + Alt + 1..0` | Move window silently to tag 1..10 |
| `Super + Tab` / `Super + Shift + Tab` | Next/previous tag |
| `Super + Left/Right/Up/Down` | Focus in direction |
| `Super + Shift + arrows` | Swap window in direction |
| `Super + Ctrl + arrows` | Focus next/previous group member |
| `Super + Alt + arrows` | Join group in direction |
| `Super + Alt + Tab` | Focus next group member |
| `Super + S` | Toggle scratchpad |
| `Super + Alt + S` | Move window to scratchpad |
| `Super + Ctrl + L` | Lock |
| `Super + Print` | Colour picker |
| `Super + P` | Screenshot |
| `Alt + P` | Screen recording menu |
| `Super + Ctrl + Print` | Extract text from screen |
| `Super + Ctrl + I` | Toggle idle locking |
| `Super + Ctrl + N` | Toggle nightlight |
| `Super + Shift + Alt + C` | Themed cmatrix |
| `Super + Ctrl + Delete` | Toggle internal display |
| `Super + Ctrl + Alt + Delete` | Mirror internal display (unsupported, explains why) |

`omarchy-menu-keybindings` prints every binding parsed from the Mango config.
Only `~/.config/mango/bindings.conf` is sourced; the installer copies a full
binding set there (based on `default/mango/bindings.conf`), so edit that user
file directly. Mango has no `unbind`; redefine a modifier + key later in the
same file to override it.

## What changed from upstream Omarchy

| Omarchy / Hyprland | This fork |
| --- | --- |
| Hyprland | MangoWC (`mango`, `mmsg`) |
| Quattro Hyprland services | Quattro services patched for Mango tags, monitors, focus, and keyboard layout |
| `uwsm` session | `bin/omarchy-mango-session` + small `uwsm`/`uwsm-app` shims |
| `hyprctl` scripts | `bin/hyprctl` compatibility shim backed by Mango IPC |
| Hyprland workspaces | Native Mango tags 1-10 in the Quattro bar |
| Hyprland monitor focus | Cursor-monitor probe using `mmsg get cursorpos` |
| `hyprlock` | PAM-backed Quattro lock screen; `swaylock` only if shell IPC is unavailable |
| `hypridle` | Quattro idle service |
| `hyprsunset` | `gammastep` |
| `hyprpicker` | `slurp` + `grim` + ImageMagick |
| `hyprshot` | `grim` + `slurp` + `satty` |
| `gpu-screen-recorder` | `wf-recorder` |
| `pacman` / `yay` | official packages plus Chaotic-AUR binaries; the installer does not build AUR packages |
| Arch migrations | pre-marked as applied; `install-arch.sh` is authoritative |

Mango does not support Hyprland's named workspaces, but its native 10 tags map
directly to Omarchy's workspace keys and the Quattro bar.

## Arch notes

- Quickshell and MangoWC are both in the official Arch repositories.
  Chaotic-AUR is only used for the optional desktop extras.
- Polkit uses Quattro's built-in agent. No separate polkit agent package is
  installed, so it cannot race the shell on login.
- `python3-terminaltexteffects` is unavailable; the screensaver falls back to a
  built-in Python animation.
- `uwsm`, `xdg-terminal-exec`, `hypridle`, `hyprlock`, `hyprsunset`,
  `hyprpicker`, and `gpu-screen-recorder` are either absent or replaced.
  Compatibility shims live in `bin/`. `xdg-terminal-exec` is installed from
  the official repositories.
- Optional applications that Arch only packages in the AUR (Spotify, Obsidian,
  Typora, LocalSend, 1Password) can be installed with `yay`/`paru` or Flatpak.
- `omarchy update` runs `pacman -Syu`, updates AUR packages only when a
  helper is already installed, and then runs the usual Omarchy migrations and
  hooks. The installer itself does not install an AUR helper.

## Known Mango limitations

These are Mango or Mango-port limitations, not missing keybindings:

- **Monitor mirroring** is not supported. `monitor_rule` can position, scale,
  rotate, and disable outputs, but cannot clone one output onto another. The
  mirror command reports this and exits non-zero.
- **Per-window opacity** is not exposed. The transparency toggle changes the
  global focused/unfocused opacity instead.
- **Per-window scroll factors** are not supported. Set the global
  `trackpad_scroll_factor` in `~/.config/mango/input.conf`.
- **Lid-switch events** are not exposed by Mango. Use the Omarchy menu or
  `Super + Ctrl + Delete` to manage the internal display.
- **Hyprland zoom** has no Mango equivalent.
- **Outside-click dismissal for tray/media popups** relied on a
  Hyprland-only focus grab. The popup still closes from its bar button or
  `Escape`; clicking another application may leave it open.
- **Multiple audio sources in one recording** are not supported by
  `wf-recorder`. When both desktop and microphone audio are requested, desktop
  audio is recorded and a notification explains the limitation.

## Customisation

- Quattro bar position and transparency: `~/.config/omarchy/shell.json`
- Quattro shell: `~/.local/share/omarchy/shell/` and
  `~/.config/omarchy/shell.json`
- Key bindings: `~/.config/mango/bindings.conf`
- Input and trackpad: `~/.config/mango/input.conf`
- Shell setup: `~/.bashrc.d/omarchy.sh` (sourced by `~/.bashrc`)
- Starship prompt: `~/.config/starship.toml`
- Gaps, borders, blur, animations: `~/.config/mango/looknfeel.conf`
- Monitor rules: `~/.config/mango/monitors.conf`
- Extra autostart: `~/.config/mango/autostart.conf`
- Omarchy defaults: `~/.local/share/omarchy/default/mango/`

The Quattro bar can be changed without editing JSON:

```bash
omarchy bar position top
omarchy bar position bottom
omarchy bar transparent true
omarchy bar transparent toggle
```

Apply Mango changes with:

```bash
omarchy restart mango    # mmsg dispatch reload_config
```

`omarchy-theme-set tokyo-night` or the Quattro theme picker regenerates
`mango.conf`, Quattro shell colors, the foot palette, and the rest of the
themed files.

## Troubleshooting

**Mango rejects the configuration**

```bash
mango -c ~/.config/mango/config.conf -p
```

**Quattro does not start**

Check that Quickshell and the bundled shell are present:

```bash
pacman -Q quickshell
test -f ~/.local/share/omarchy/shell/shell.qml && echo shell-present
omarchy restart shell
```

Startup errors are appended to `$XDG_RUNTIME_DIR/omarchy/shell.log`. There is
no fallback bar; install Quickshell and restart the session.

**Bar icons or glyphs are missing**

Install the Nerd Font and Font Awesome icon fonts:

```bash
sudo pacman -S ttf-jetbrains-mono-nerd otf-font-awesome
fc-cache -f
omarchy restart shell
```

**A Hyprland compatibility script fails**

Try the shim directly:

```bash
hyprctl monitors -j
hyprctl clients -j
hyprctl activewindow -j
```

Unsupported dispatches are reported and skipped rather than killing a keybinding.

**Screen sharing reports "Compositor supports neither ext_image_copy_capture or wlr_screencopy"**

Mango exposes both protocols. Confirm the running compositor advertises them:

```bash
wayland-info | grep -E 'screencopy|image_copy'
```

`xdg-desktop-portal-wlr` must run with the same `WAYLAND_DISPLAY` and
`XDG_RUNTIME_DIR` as the session, and PipeWire must be running. This error is
expected when testing a headless Mango inside a private `dbus-run-session`:
D-Bus-activated portal services are started by the real systemd user manager
with `/run/user/<uid>`, so they cannot see the private headless compositor. It
does not occur in a normal login.

**The session is not listed at login**

```bash
ls /usr/share/wayland-sessions/omarchy-mango.desktop
```

Ly 1.4 scans `/usr/share/wayland-sessions`; the installer writes the session
there. If another display manager is used, make sure `/usr/share` is in
`XDG_DATA_DIRS` (it is on Arch by default).

**Ly does not start**

```bash
systemctl status ly@tty1.service
sudo ly-dm -c /etc/ly/config.ini
```

The installer writes `/etc/ly/config.ini` and a theme-aware
`/etc/ly/startup.sh`. Re-run `./install-arch.sh --skip-packages` to restore
them.

## Development

Most scripts still accept the original Omarchy command names; only
compositor-specific commands were renamed from `omarchy-hyprland-*` to
`omarchy-mango-*`.

```bash
bin/omarchy commands --check
mango -c config/mango/config.conf -p
```

## License

MIT, same as Omarchy.
