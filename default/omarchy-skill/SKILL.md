---
name: omarchy
description: >
  REQUIRED for end-user customization of Linux desktop, window manager, or system config.
  Use when editing ~/.config/mango/, ~/.config/omarchy/,
  ~/.config/alacritty/, ~/.config/foot/, ~/.config/kitty/, or ~/.config/ghostty/.
  Triggers: Mango, MangoWC, Quattro shell, bar widgets, plugins, window rules,
  animations, keybindings, monitors, gaps, borders, opacity, terminal config, themes,
  wallpaper, night light, idle, lock screen, screenshots, reminders, layer rules,
  workspace/tag settings, display config, and user-facing omarchy commands. Excludes Omarchy
  source development in ~/.local/share/omarchy/ and `omarchy dev` workflows.
---

# Omarchy Skill

Manage [Omarchy](https://omarchy.org/) on **Arch Linux with MangoWC**. This fork keeps Omarchy's themes, menus, and CLI while using Mango's native tags and IPC.

This skill is for end-user customization on installed systems.
It is not for contributing to Omarchy source code.

## When This Skill MUST Be Used

**ALWAYS invoke this skill for end-user requests involving ANY of these:**

- Editing ANY file in `~/.config/mango/` (window rules, animations, keybindings, monitors, etc.)
- Editing terminal configs (alacritty, foot, kitty, ghostty)
- Editing ANY file in `~/.config/omarchy/`, including `shell.json`
- Window behavior, animations, opacity, blur, gaps, borders
- Layer rules, workspace settings, display/monitor configuration
- Themes, wallpapers, fonts, appearance changes
- User-facing `omarchy` commands (`omarchy theme ...`, `omarchy refresh ...`, `omarchy restart ...`, etc.)
- Screenshots, screen recording, reminders, night light, idle behavior, lock screen

**If you're about to edit a config file in ~/.config/ on this system, STOP and use this skill first.**

**Do NOT use this skill for Omarchy development tasks** (editing files in `~/.local/share/omarchy/`, creating migrations, or running `omarchy dev ...` workflows).

## Critical Safety Rules

**For end-user customization tasks, NEVER modify anything in `~/.local/share/omarchy/`** - but READING is safe and encouraged.

This directory contains Omarchy's source files managed by git. Any changes will be:
- Lost on next `omarchy update`
- Cause conflicts with upstream
- Break the system's update mechanism

```
~/.local/share/omarchy/     # READ-ONLY - NEVER EDIT (reading is OK)
├── bin/                    # Source scripts (symlinked to PATH)
├── config/                 # Default config templates
├── themes/                 # Stock themes
├── default/                # System defaults
├── migrations/             # Update migrations
└── install/                # Installation scripts
```

**Reading `~/.local/share/omarchy/` is SAFE and useful** - do it freely to:
- Understand how omarchy commands work: `omarchy theme set --help` or `cat $(which omarchy-theme-set)`
- See default configs before customizing: `cat ~/.local/share/omarchy/config/omarchy/shell.json`
- Check stock theme files to copy for customization
- Reference default Mango settings: `cat ~/.local/share/omarchy/default/mango/*`

**Always use these safe locations instead:**
- `~/.config/` - User configuration (safe to edit)
- `~/.config/omarchy/themes/<custom-name>/` - Custom themes (must be real directories)
- `~/.config/omarchy/hooks/` - Custom automation hooks

If the request is to develop Omarchy itself, this skill is out of scope. Follow repository development instructions instead of this skill.

## System Architecture

Omarchy is built on:

| Component | Purpose | Config Location |
|-----------|---------|-----------------|
| **Arch Linux** | Base OS | `/etc/`, `~/.config/` |
| **MangoWC** | Wayland compositor/WM | `~/.config/mango/` |
| **Quattro shell** | Bar, menus, notifications, OSD, lock | `~/.config/omarchy/shell.json` |
| **Alacritty/Foot/Kitty/Ghostty** | Terminals | `~/.config/<terminal>/` |

## Command Discovery

Omarchy ships a single `omarchy` CLI that dispatches to all `omarchy-*` binaries via `omarchy <group> <action>`. Always prefer this form — it is self-documenting and stable. The underlying `omarchy-*` binaries still exist on `PATH` and remain safe to read for source.

```bash
# List every documented command and its summary
omarchy commands

# Show the commands inside a group
omarchy theme --help
omarchy refresh --help
omarchy restart --help

# Show help for a specific command (does not execute it)
omarchy theme set --help

# Machine-readable listing (binary, route, summary, args, aliases)
omarchy commands --json

# Read a command's source to understand it
cat $(which omarchy-theme-set)
```

### Command Groups

Run `omarchy --help` for the full list. The most common groups:

| Group | Purpose | Example |
|-------|---------|---------|
| `omarchy refresh` | Reset config to defaults (backs up first) | `omarchy refresh shell` |
| `omarchy restart` | Restart a service/app | `omarchy restart shell` |
| `omarchy toggle` | Toggle feature on/off | `omarchy toggle nightlight` |
| `omarchy theme` | Theme management | `omarchy theme set <name>` |
| `omarchy bar` | Bar layout and widgets | `omarchy bar position top` |
| `omarchy install` | Install optional software / packages | `omarchy install docker dbs` |
| `omarchy launch` | Launch apps | `omarchy launch browser` |
| `omarchy capture` | Screenshots and recordings | `omarchy capture screenshot` |
| `omarchy reminder` | Desktop notification reminders | `omarchy reminder 15 "Pickup Jack"` |
| `omarchy pkg` | Package management | `omarchy pkg add <pkg>` |
| `omarchy setup` | Initial setup tasks | `omarchy setup security fingerprint` |
| `omarchy update` | System updates | `omarchy update` |

## Configuration Locations

### MangoWC (Window Manager)

```
~/.config/mango/
├── config.conf        # Main config (sources defaults, theme, overrides)
├── bindings.conf      # Keybindings
├── monitors.conf      # Display configuration
├── input.conf         # Keyboard/mouse/touchpad settings
├── looknfeel.conf     # Appearance (gaps, borders, animations)
├── autostart.conf     # Extra startup applications
└── ~/.local/state/omarchy/toggles/mango/*.conf  # Persistent toggle snippets
```

Idle and lock are handled by the Quattro shell; night light uses `gammastep`.
Their state lives outside `~/.config/mango/`.

**Key behaviors:**
- Mango does NOT watch config files. Run `omarchy restart mango`
  (`mmsg dispatch reload_config`) after edits.
- Validate before reloading: `mango -c ~/.config/mango/config.conf -p`
- Use `omarchy refresh mango` to reset to defaults.
- Use `mmsg get all-monitors` / `mmsg get all-clients` for state, not `hyprctl`.
  A `hyprctl` compatibility shim exists for older scripts.

### Quattro Shell (Bar, Panels, OSD)

```
~/.config/omarchy/
└── shell.json         # Bar layout, plugin settings, and shell options
```

The shell source and built-in plugins live in
`~/.local/share/omarchy/shell/` and are read-only for end-user customization.
Custom plugins live in `~/.config/omarchy/plugins/`.

**The shell runs with `QS_DISABLE_FILE_WATCHER=1` in this fork**, so run
`omarchy restart shell` after changing `shell.json`, plugin files, or shell
QML. Validate a shell change before restarting.

**Commands:** `omarchy restart shell`, `omarchy refresh shell`,
`omarchy bar position top`, `omarchy bar transparent toggle`

### Terminals

```
~/.config/alacritty/alacritty.toml
~/.config/foot/foot.ini
~/.config/kitty/kitty.conf
~/.config/ghostty/config
```

**Command:** `omarchy restart terminal`

### Other Configs

| App | Location |
|-----|----------|
| btop | `~/.config/btop/btop.conf` |
| fastfetch | `~/.config/fastfetch/config.jsonc` |
| lazygit | `~/.config/lazygit/config.yml` |
| starship | `~/.config/starship.toml` |
| git | `~/.config/git/config` |

## Safe Customization Patterns

### Pattern 1: Edit User Config Directly

For simple changes, edit files in `~/.config/`:

```bash
# 1. Read current config
cat ~/.config/mango/bindings.conf

# 2. Backup before changes
cp ~/.config/mango/bindings.conf ~/.config/mango/bindings.conf.bak.$(date +%s)

# 3. Make changes with Edit tool

# 4. Apply changes
# - Mango: validate with `mango -c ~/.config/mango/config.conf -p`, then `omarchy restart mango`
# - Quattro shell: MUST restart with `omarchy restart shell`
# - Terminals: MUST restart with `omarchy restart terminal`
```

### Pattern 2: Make a new theme

1. Create a directory under ~/.config/omarchy/themes.
2. See how an existing theme is done via ~/.local/share/omarchy/themes/catppuccin.
3. Download a matching background (or several) from the internet and put them in ~/.config/omarchy/themes/[name-of-new-theme]
4. When done with the theme, run `omarchy theme set "Name of new theme"`

### Pattern 3: Use Hooks for Automation

Create scripts in `~/.config/omarchy/hooks/` to run automatically on events:

```bash
# Available hooks (see samples in ~/.config/omarchy/hooks/):
~/.config/omarchy/hooks/
├── theme-set        # Runs after theme change (receives theme name as $1)
├── font-set         # Runs after font change
└── post-update      # Runs after `omarchy update`
```

Example hook (`~/.config/omarchy/hooks/theme-set`):
```bash
#!/bin/bash
THEME_NAME=$1
echo "Theme changed to: $THEME_NAME"
# Add custom actions here
```

### Pattern 4: Reset to Defaults -- ALWAYS SEEK USER CONFIRMATION BEFORE RUNNING

When customizations go wrong:

```bash
# Reset specific config (creates backup automatically)
omarchy refresh shell
omarchy refresh mango

# The refresh command:
# 1. Backs up current config with timestamp
# 2. Copies default from ~/.local/share/omarchy/config/
# 3. Restarts the component
```

## Common Tasks

### Themes

```bash
omarchy theme list              # Show available themes
omarchy theme current           # Show current theme
omarchy theme set <name>        # Apply theme (use "Tokyo Night" not "tokyo-night")
omarchy theme bg next           # Cycle wallpaper
omarchy theme install <url>     # Install from git repo
```

### Keybindings

Edit `~/.config/mango/bindings.conf`. It is the only bindings file sourced
by this fork and starts as a full copy of the default. Format:
```
bind=SUPER,Return,spawn,xdg-terminal-exec
bind=SUPER,w,killclient
bind=SUPER+SHIFT,q,quit
```

View current bindings: `omarchy menu keybindings --print`

**IMPORTANT: When re-binding an existing key:**

1. First check existing bindings: `omarchy menu keybindings --print`
2. Mango has no `unbind`. Redefine the same modifier + key later in
   `~/.config/mango/bindings.conf`; the last definition wins.
3. Inform the user what the key was previously bound to.

Example - rebinding SUPER+F (fullscreen by default):
```
# SUPER+F is now file manager; this overrides the default fullscreen binding.
bind=SUPER,f,spawn,nautilus
```

Always tell the user: "Note: SUPER+F was previously bound to fullscreen. I've
added a binding in ~/.config/mango/bindings.conf to override it."

### Display/Monitors

Edit `~/.config/mango/monitors.conf`. Format:
```
monitor_rule=name:^eDP-1$,width:1920,height:1080,refresh:60,x:0,y:0,scale:1
monitor_rule=name:^HDMI-A-1$,width:2560,height:1440,refresh:144,x:1920,y:0,scale:1
```

Rules are first-match-wins. List monitors: `mmsg get all-monitors`.
Never use negative coordinates if XWayland applications matter.

### Window Rules

**CRITICAL: Mango window rules use their own syntax.**

Before writing window rules, fetch the current documentation from the Mango wiki:
- https://github.com/mangowm/mango/wiki/rules

Window rules go in `~/.config/mango/windows.conf` (create it if missing) or a
sourced file. The default rules live in
`~/.local/share/omarchy/default/mango/windows.conf`.

Format: `window_rule=parameter:value,...,app_id:regex`. Rules are evaluated in
order; `app_id` and `title` use regular expressions. There is no Hyprland-style
`windowrulev2`.

### Fonts

```bash
omarchy font list               # Available fonts
omarchy font current            # Current font
omarchy font set <name>         # Change font
```

### System

```bash
omarchy update                  # Full system update
omarchy version                 # Show Omarchy version
omarchy debug --no-sudo --print # Debug info (ALWAYS use these flags)
omarchy system lock             # Lock screen
omarchy system shutdown         # Shutdown
omarchy system reboot           # Reboot
```

**IMPORTANT:** Always run `omarchy debug` with `--no-sudo --print` flags to avoid interactive sudo prompts that will hang the terminal.

## Troubleshooting

```bash
# Get debug information (ALWAYS use these flags to avoid interactive prompts)
omarchy debug --no-sudo --print

# Upload logs for support
omarchy upload log

# Reset specific config to defaults
omarchy refresh <app>

# Refresh specific config file
# config-file path is relative to ~/.config/
# eg. `omarchy refresh config mango/looknfeel.conf` will refresh ~/.config/mango/looknfeel.conf
omarchy refresh config <config-file>

# Full reinstall of configs (nuclear option)
omarchy reinstall
```

## Decision Framework

When user requests system changes:

1. **Is it a stock omarchy command?** Use it directly
2. **Is it a config edit?** Edit in `~/.config/`, never `~/.local/share/omarchy/`
3. **Is it a theme customization?** Create a NEW custom theme directory
4. **Is it automation?** Use hooks in `~/.config/omarchy/hooks/`
5. **Is it a package install?** Use `omarchy pkg add <pkgs...>` (Arch `pacman`; AUR packages via `omarchy pkg aur add`)
6. **Unsure if command exists?** Run `omarchy commands` (or `omarchy <group> --help` for one group)

### Reminder Requests

When the user asks to set a reminder, use `omarchy reminder <minutes> [message]` directly. Convert natural language durations to minutes and title-case short reminder labels when appropriate.

```bash
omarchy reminder 15 "Pickup Jack"
omarchy reminder 60 "Check laundry"
omarchy reminder show
omarchy reminder clear
```

## Out of Scope

This skill intentionally does not cover Omarchy source development. Do not use this skill for:
- Editing files in `~/.local/share/omarchy/` (`bin/`, `config/`, `default/`, `themes/`, `migrations/`, etc.)
- Creating or editing migrations
- Running `omarchy dev ...` commands

## Example Requests

- "Change my theme to catppuccin" -> `omarchy theme set catppuccin`
- "Add a keybinding for Super+E to open file manager" -> Check existing bindings first, then add a later `bind=` line in `~/.config/mango/bindings.conf`
- "Configure my external monitor" -> Edit `~/.config/mango/monitors.conf`
- "Make the window gaps smaller" -> Edit `~/.config/mango/looknfeel.conf`
- "Set up night light to turn on at sunset" -> `omarchy toggle nightlight` (gammastep)
- "Set a reminder to pickup jack in 15 minutes" -> `omarchy reminder 15 "Pickup Jack"`
- "Show my reminders" -> `omarchy reminder show`
- "Clear all reminders" -> `omarchy reminder clear`
- "Customize the catppuccin theme colors" -> Create `~/.config/omarchy/themes/catppuccin-custom/` by copying from stock, then edit
- "Run a script every time I change themes" -> Create `~/.config/omarchy/hooks/theme-set`
- "Reset the shell bar to defaults" -> `omarchy refresh shell`
