# Style

- Two spaces for indentation, no tabs
- Use bash 5 conditionals: use `[[ ]]` for string/file tests and `(( ))` for numeric tests
- In `[[ ]]`, don't quote variables, but do quote string literals when comparing values (e.g., `[[ $branch == "dev" ]]`)
- Prefer `(( ))` over numeric operators inside `[[ ]]` (e.g., `(( count < 50 ))`, not `[[ $count -lt 50 ]]`)
- For strings/paths with spaces, quote them instead of escaping spaces with `\ ` (e.g., `"$APP_DIR/Disk Usage.desktop"`, not `$APP_DIR/Disk\ Usage.desktop`)
- Shebangs must use `#!/bin/bash` consistently (never `#!/usr/bin/env bash`)
- Scripts under `install/` and `migrations/` may be sourced and intentionally omit shebangs

# Command Naming

All commands start with `omarchy-`. Prefixes indicate purpose.

The authoritative command group list lives in `bin/omarchy` in `GROUP_DESCRIPTIONS`. Keep `GROUP_DESCRIPTIONS` updated when adding a new command prefix.

Common prefixes include:

- `cmd-` - check if commands exist, misc utility commands
- `capture-` - screenshots, screen recordings, and other capture tools
- `pkg-` - package management helpers
- `hw-` - hardware detection (return exit codes for use in conditionals)
- `refresh-` - copy default config to user's `~/.config/`
- `restart-` - restart a component
- `launch-` - open applications
- `install-` - install optional software
- `setup-` - interactive setup wizards
- `toggle-` - toggle features on/off
- `theme-` - theme management
- `update-` - update components

Other current prefixes include:

- `ac-`, `audio-`, `bar-`, `battery-`, `branch-`, `brightness-`, `channel-`, `config-`, `debug-`, `dev-`, `drive-`, `first-`, `font-`, `haptic-`, `hibernation-`, `hook-`, `mango-`, `menu-`, `migrate-`, `notification-`, `npx-`, `plugin-`, `plymouth-`, `powerprofiles-`, `reinstall-`, `remove-`, `screensaver-`, `shell-`, `show-`, `snapshot-`, `state-`, `sudo-`, `system-`, `transcode-`, `tui-`, `tz-`, `upload-`, `version-`, `voxtype-`, `webapp-`, `wifi-`, `windows-`

# Command Metadata

Commands in `bin/` can declare CLI metadata in comments near the top of the file. `bin/omarchy` scans the first 80 lines, and tests expect command metadata to remain valid.

Supported metadata keys:

- `# omarchy:summary=...` - short help text
- `# omarchy:group=...` - command group when it differs from the filename-derived prefix
- `# omarchy:name=...` - command name within the group
- `# omarchy:args=...` - usage arguments
- `# omarchy:examples=...` - examples separated with ` | `
- `# omarchy:alias=...` / `# omarchy:aliases=...` - alternate routes
- `# omarchy:hidden=true` - hide from default command listings
- `# omarchy:requires-sudo=true` - mark commands that require sudo

Prefer explicit metadata for user-facing commands. Keep routes consistent with the filename unless there is a deliberate alias or compatibility route.

Example:

```bash
# omarchy:summary=Take a screenshot
# omarchy:group=capture
# omarchy:args=[smart|region|windows|fullscreen] [slurp|copy]
# omarchy:examples=omarchy screenshot | omarchy capture screenshot region
# omarchy:aliases=omarchy screenshot
```

# Install Scripts

Install entry point (`install-arch.sh`) uses `#!/bin/bash`. Many scripts under `install/` are sourced via `run_logged` and intentionally do not have shebangs.

Install stage files follow this pattern:

- `install/*/all.sh` lists scripts in execution order
- leaf scripts are sourced by `run_logged $OMARCHY_INSTALL/path/to/script.sh`
- avoid `exit` in sourced install scripts unless intentionally aborting the install
- use `$OMARCHY_INSTALL` and `$OMARCHY_PATH` instead of hard-coded Omarchy paths
- keep hardware-specific logic under `install/config/hardware/`
- prefer helper commands for package and command checks where available

Raw `command -v`, `pacman`, and `pacman-key` are acceptable in bootstrap/preflight/package-helper contexts where the helper commands may not be available yet or where direct package-manager behavior is the point of the script.

# Helper Commands

Use these instead of raw shell commands:

- `omarchy-cmd-missing` / `omarchy-cmd-present` - check for commands
- `omarchy-pkg-missing` / `omarchy-pkg-present` - check for packages
- `omarchy-pkg-add` - install packages (handles both pacman and AUR)
- `omarchy-hw-asus-rog` - detect ASUS ROG hardware (and similar `hw-*` commands)

Exceptions are allowed for bootstrap, preflight, migration, and package-helper scripts where the helper may not be available yet, where the helper itself is being implemented, or where direct package-manager behavior is required.

# Config Structure

- `config/` - default configs copied to `~/.config/`
- `default/themed/*.tpl` - templates with `{{ variable }}` placeholders for theme colors
- `themes/*/colors.toml` - theme color definitions (accent, background, foreground, color0-15)

# Visual Changes

When making visual changes, such as Quattro bar, widget, or desktop appearance, always take and analyze a screenshot after applying the change to verify the result. Use `omarchy capture screenshot fullscreen save` for fullscreen screenshots.

# Refresh Pattern

To copy a default config to user config with automatic backup:

```bash
omarchy-refresh-config mango/looknfeel.conf
```

This copies `~/.local/share/omarchy/config/mango/looknfeel.conf` to `~/.config/mango/looknfeel.conf`.

# Migrations

To create a new migration, run `omarchy-dev-add-migration --no-edit`. This creates a migration file named after the unix timestamp of the last commit.

New migration format:
- File permissions must be `0644` (`-rw-r--r--`); migrations are sourced, not executed directly
- No shebang line
- Start with an `echo` describing what the migration does
- Use `$OMARCHY_PATH` to reference the omarchy directory
- Prefer helper commands such as `omarchy-cmd-present`, `omarchy-cmd-missing`, `omarchy-pkg-present`, and `omarchy-pkg-missing`

Some older migrations predate these rules. Do not copy older migrations that start with shebangs, omit the leading `echo`, or hard-code `~/.local/share/omarchy`.

Migrations may use raw package-manager commands, `command -v`, or direct config edits when needed for historical compatibility or one-off repair work.

Example:
```bash
echo "Restart the Omarchy shell after a shell update"

if omarchy-cmd-present omarchy-shell; then
  omarchy restart shell
fi
```
