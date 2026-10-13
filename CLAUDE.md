# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A modular, idempotent Arch Linux setup for a Wayland-based development environment. Hyprland is the compositor, Noctalia v5 (native Wayland shell, no Qt/Quickshell) provides the desktop shell (bar, launcher, lock screen, notifications, clipboard history, wallpaper theming), and all configs are managed via symlinks from this repo.

## Running the Installer

```bash
./install.sh    # Do NOT use sudo; individual scripts call sudo as needed
```

Safe to re-run at any time. All package installs use `--needed --noconfirm`. Existing files are backed up with `.bak.TIMESTAMP` before symlink creation.

## Architecture

### Execution Flow

`install.sh` sources `scripts/lib.sh` (shared helpers), then runs each step via `source`:

```
00-prereq.sh  -> git, base-devel, curl
10-pacman.sh  -> packages from config/pacman.txt + config/fonts.txt (includes noctalia from extra)
20-paru.sh     -> bootstrap paru AUR helper
30-aur.sh     -> packages from config/paru.txt
50-ohmyzsh.sh -> Oh My Zsh + Powerlevel10k + zsh plugin symlinks
60-tools.sh   -> Atuin, Go tools, remove Noctalia v4 leftovers, Noctalia check
65-nvim.sh    -> clone/update ljudina/php.nvim into ~/.local/share/nvim-php-config
70-dotfiles.sh-> symlink dotfiles/ into ~ and ~/.config
45-powerfix.sh-> install on-battery CPU power cap from powerfix/
40-services.sh-> enable iwd, bluetooth, power-profiles-daemon, docker (runs last)
```

Scripts are numbered for ordering but `install.sh` controls the actual sequence (note: 40 runs after 70).

### Package Lists (`config/`)

Plain text files, one package per line. Comments (`#`) and blank lines are ignored. Parsed by `read_pkgs_file()` in `lib.sh` using `grep -Ev '^\s*($|#)'`.

- `pacman.txt` -- official repo packages
- `paru.txt` -- AUR packages (installed via paru)
- `fonts.txt` -- font packages

### Dotfiles Deployment (`70-dotfiles.sh`)

Symlink-based: `dotfiles/home/*` -> `~/`, `dotfiles/config/*` -> `~/.config/`. Editing `~/.config/hypr/hyprland.lua` edits the repo file directly.

`Pictures/` is handled differently: only `dotfiles/Pictures/wallpapers` is linked (to `~/Pictures/wallpapers`) — the top-level `Pictures/` is not walked like `home/` and `config/` are.

The `link_one()` function backs up existing real files, updates stale symlinks, and creates new ones. `sync_dir_entries()` iterates top-level entries (with `dotglob`) and calls `link_one` for each.

After linking, the script also:
- `chmod +x` on every `~/.config/hypr/scripts/*.sh`
- symlinks `~/.local/share/nvim-php-config` -> `~/.config/nvim` (the Neovim config cloned by `65-nvim.sh`)
- writes `~/.config/systemd/user/hyprland-session.target` if missing (see below)

`hyprland-session.target` is a systemd user target that `BindsTo` `graphical-session.target`. `hyprland.lua` starts it from the `hyprland.start` event, which activates `graphical-session.target`. `xdg-desktop-portal` 1.22+ has `Requisite=graphical-session.target`, so without this the portal never starts and GTK/libadwaita apps (Nautilus, LibreOffice) fall back to the light theme regardless of the gsettings/Noctalia dark setting.

### Shared Library (`scripts/lib.sh`)

Key helpers: `log`/`warn`/`err` (colored output), `need_cmd` (assert command exists), `read_pkgs_file` (parse package list), `pac_install_file`/`aur_install_file` (install from list file), `enable_service_now`/`enable_service`/`start_service_timeout` (systemd wrappers).

All scripts use `set -euo pipefail`.

### Desktop Shell: Noctalia v5 + Hyprland

Noctalia replaces waybar, rofi, hyprlock, hyprpaper, and cliphist. Installed from the official `extra` repo (`noctalia`, listed in `config/pacman.txt`). Started with `noctalia` from the `hyprland.start` event in `hyprland.lua`. Hyprland keybinds drive it with `noctalia msg <command>` (`panel-toggle launcher|session|clipboard`, `panel-toggle control-center notifications`, `settings-toggle`, `session lock`, `bar-toggle`, `window-switcher hold`, `volume-up|down|mute`, `mic-mute`, `brightness-up|down`). `noctalia msg --help` lists every command.

Config is TOML: `dotfiles/config/noctalia/config.toml` (symlinked to `~/.config/noctalia/`, every `*.toml` there is merged and hot-reloaded). Changes made in the Settings UI land in `~/.local/state/noctalia/settings.toml`, which overrides the repo file and is intentionally not tracked. Plugins are Luau (`plugin.toml` + `.luau`), enabled via `[plugins].enabled`, and are fetched by the shell into `~/.local/state/noctalia/plugins/`; nothing plugin-related lives in this repo.

v4 (Quickshell `noctalia-shell` + `noctalia-qs`) is unmaintained upstream and its `settings.json`/QML plugins are not compatible. `60-tools.sh` removes those packages (plus `cliphist`, `matugen`, `wl-clip-persist`, `qt6-multimedia`) when present. The optional Hyprland colour template (Settings -> Templates) writes `~/.config/hypr/noctalia.lua`, which `hyprland.lua` loads with a guarded `pcall(require, "noctalia")`.

### Hyprland Helper Scripts (`dotfiles/config/hypr/scripts/`)

Wired into `hyprland.lua` via Lua startup events, direct execution, or binds:

- `autostart.sh` -- starts the `foot --server` daemon (shared backend for all `footclient` instances) plus a startup `footclient` pinned to workspace 2, and launches `udiskie` (USB automount), `iwgtk` (Wi-Fi tray), and the AC-power watcher; invoked from the `hyprland.start` event
- `ac-power-watcher.sh` -- background loop that flips `power-profiles-daemon` between `performance` (AC online) and `power-saver` (AC offline); only acts on state changes so manual selection sticks
- `lid-monitor.sh` -- reconciles the `eDP-1` panel against `/proc/acpi/button/lid/*/state`; idempotent, safe to call from lid event, hotplug, or session start
- `monitor-watcher.sh` -- parallel watcher on Hyprland IPC and `/proc` lid state that re-runs `lid-monitor.sh` (works around dropped `bindl` lid events during dock hotplug cascades)
- `mail.sh` -- startup mail client for workspace 3: launches the Chrome Outlook PWA desktop entry if present, otherwise writes a Gmail PWA desktop entry (`gmail-pwa.desktop`, a Thorium `--app` window) and launches that; both window classes are pinned to workspace 3 by window rules in `hyprland.lua`

### Power Fix (`powerfix/`, `45-powerfix.sh`)

Caps CPU package power (MSR RAPL) while on battery to prevent hard power-offs when CPU peak draw exceeds what the battery pack can deliver (hit on ThinkPad P14s Gen 4 / i7-1370P during video calls). Portable across laptops: the script detects the Mains supply by type, captures the machine's own firmware limits at boot into `/run/rapl-powercap.stock`, and applies battery caps as percentages of them (PL1 40%, PL2 60%, PL4 50%; override via `/etc/default/rapl-powercap`). No-ops on hardware without Intel RAPL (AMD), so it installs everywhere.

Deployed as: `/usr/local/bin/rapl-powercap.sh` (logic), a udev rule (re-apply on plug/unplug), `rapl-powercap.service` (apply at boot), and a system-sleep hook (re-apply after resume, since MSR limits reset on wake). Check activity with `journalctl -t rapl-powercap`.

### Neovim

External config repo (`ljudina/php.nvim`) cloned to `~/.local/share/nvim-php-config`, symlinked to `~/.config/nvim` by `70-dotfiles.sh`. Not stored in this repo's dotfiles.

## Common Changes

**Add a pacman package:** Add line to `config/pacman.txt`
**Add an AUR package:** Add line to `config/paru.txt`
**Add a new dotfile config:** Place in `dotfiles/config/<app>/` (will be symlinked to `~/.config/<app>`)
**Add a home dotfile:** Place in `dotfiles/home/` (will be symlinked to `~/`)
**Add a new install step:** Create `scripts/NN-name.sh`, add `run_step "NN-name.sh"` to `install.sh`
**Modify Hyprland keybinds/config:** Edit `dotfiles/config/hypr/hyprland.lua`
**Persist a Noctalia change made in its Settings UI:** copy the key from `~/.local/state/noctalia/settings.toml` into `dotfiles/config/noctalia/config.toml`, then delete it from `settings.toml` so the override stops shadowing the repo value. Leave runtime state there (`config_version`, `lockscreen_widgets`, `wallpaper.last`, `wallpaper.monitors.*`)
**Modify autostart programs:** Edit `dotfiles/config/hypr/scripts/autostart.sh`
**Add a Hyprland helper script:** Place in `dotfiles/config/hypr/scripts/` (made executable on install by `70-dotfiles.sh`)

## Conventions

- All bash scripts use `set -euo pipefail` and source `lib.sh` for helpers
- Scripts are idempotent: check before install, use `--needed`, guard with `command -v`
- Package list files use `#` for comments and are sectioned by category
- `|| true` is used where failure is acceptable (e.g., `gsettings set ... || true`)
- Hyprland program values (`menu`, `powermenu`, `lockscreen`) are Lua locals near the top of `hyprland.lua` and referenced in keybinds below
- Noctalia layer rule (namespace `^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$`) uses `no_anim` so Hyprland does not double-animate the shell's own surface animations
