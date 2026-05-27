# Arch Linux Development Environment Setup (Noctalia)

A modular, idempotent Arch Linux setup for a Wayland-based development environment built around Hyprland and the Noctalia Shell. All configuration lives in this repo and is deployed via symlinks, so there is exactly one source of truth for every dotfile.

The main goals are:
- fast setup on a new machine
- zero configuration drift between this repo and `~`
- safe to re-run at any time
- no duplicated configuration files

---

## Features

- Modular `install.sh` with ordered, idempotent setup steps
- Pacman + AUR (`paru`) package management driven by plain-text package lists
- Hyprland compositor with monitor hotplug + lid reconciliation scripts
- Noctalia Shell (replaces Waybar, Rofi, Hyprlock, Hyprpaper)
- Matugen-driven Material Design 3 theming sourced into Hyprland
- Foot terminal (foot server/client via `footclient`)
- Yazi file manager configuration
- Oh My Zsh with Powerlevel10k and Arch-native Zsh plugins (autosuggestions + syntax highlighting)
- Atuin shell history sync
- Neovim PHP-focused config pulled from upstream (`ljudina/php.nvim`)
- Automatic power-profile switching on AC plug/unplug (`power-profiles-daemon`)
- Symlink-based dotfiles deployment with automatic backup of pre-existing files

---

## Repository Structure

```
.
├── install.sh                  # entry point, sources scripts in order
├── config/                     # package lists (one package per line, '#' comments)
│   ├── pacman.txt
│   ├── paru.txt
│   └── fonts.txt
├── scripts/
│   ├── lib.sh                  # shared helpers (log, pac_install_file, ...)
│   ├── 00-prereq.sh            # git, base-devel, curl
│   ├── 10-pacman.sh            # install pacman.txt + fonts.txt
│   ├── 20-paru.sh              # bootstrap paru-bin from AUR
│   ├── 30-aur.sh               # install paru.txt (incl. noctalia-shell)
│   ├── 40-services.sh          # iwd, bluetooth, power-profiles-daemon, docker
│   ├── 50-ohmyzsh.sh           # Oh My Zsh + Powerlevel10k + plugin symlinks
│   ├── 60-tools.sh             # Atuin, Go tools, Noctalia first-run setup
│   ├── 65-nvim.sh              # clone/update ljudina/php.nvim
│   └── 70-dotfiles.sh          # symlink dotfiles/ into ~ and ~/.config
└── dotfiles/
    ├── home/
    │   ├── .zshrc
    │   └── .p10k.zsh
    ├── config/
    │   ├── hypr/
    │   │   ├── hyprland.conf
    │   │   └── scripts/        # autostart, lid/monitor watchers, AC watcher
    │   ├── noctalia/           # shell settings, plugins, color schemes
    │   ├── foot/               # foot terminal config (Catppuccin Mocha)
    │   ├── thorium/            # Thorium browser profile bits
    │   └── yazi/
    └── Pictures/
        └── wallpapers/
```

---

## Installation

### 1. Clone the repository

```bash
git clone <your-repo-url> ~/src/arch-setup-noctalia
cd ~/src/arch-setup-noctalia
```

### 2. Run the installer (do NOT use sudo)

```bash
./install.sh
```

Individual steps call `sudo` themselves where needed. The installer will:

1. install prerequisites (`git`, `base-devel`, `curl`)
2. install pacman packages from `config/pacman.txt` and `config/fonts.txt`
3. bootstrap `paru` and install AUR packages from `config/paru.txt`
4. install Oh My Zsh + Powerlevel10k, set Zsh as default shell, link pacman-provided Zsh plugins
5. install Atuin, Go tools (`templ`, `air`), run Noctalia first-run setup
6. clone/update the Neovim PHP config
7. symlink everything in `dotfiles/` into `~` and `~/.config`
8. enable `iwd`, `bluetooth`, `power-profiles-daemon`, and (best-effort) `docker`

### 3. Open a new terminal

Or log out and back in if Zsh was just set as the default shell.

---

## Re-running and Updating

Every step is idempotent — packages use `--needed`, services use `enable --now`, and the dotfile linker backs up any real file it would otherwise overwrite. Re-run safely:

```bash
./install.sh
```

To pull repo changes and apply them:

```bash
git pull
./install.sh
```

---

## Desktop Shell: Noctalia

Noctalia is a Wayland desktop shell built on Quickshell (Qt/QML). It replaces Waybar, Rofi, Hyprlock, and Hyprpaper with a unified shell experience.

Noctalia provides:
- Status bar / panels
- Application launcher
- Lock screen
- Notification system with history and DND
- OSD for volume and brightness
- Dock
- Wallpaper management
- GTK/Qt theming via Matugen (Material Design 3)

Hyprland keybinds invoke Noctalia via `qs -c noctalia-shell ipc call <module> <action>` — e.g. launcher, sessionMenu, lockScreen, clipboard, notifications, audio, brightness, settings, hypr overview.

Matugen writes generated theme fragments into `~/.config/hypr/noctalia/{colors,layout,outputs}.conf`, which `hyprland.conf` sources. Empty stubs are created so Hyprland's `source` directives never fail on a fresh machine.

---

## Hyprland Helper Scripts

Lives in `dotfiles/config/hypr/scripts/`:

- `autostart.sh` — runs `udiskie`, `iwgtk`, and the AC-power watcher
- `ac-power-watcher.sh` — switches `power-profiles-daemon` to `performance` on AC, `power-saver` off AC; only fires on state changes so manual profile selection sticks
- `lid-monitor.sh` — reconciles the `eDP-1` panel against actual lid position; safe to call on lid events, hotplug, or session start
- `monitor-watcher.sh` — watches Hyprland IPC and `/proc` lid state in parallel and re-runs `lid-monitor.sh` (works around dropped `bindl` events during hotplug cascades)
- `update.sh`, `check_updates_json.sh`, `rotate_windows.sh`, `keepassxc_autostart.sh` — assorted helpers wired into Hyprland keybinds or Noctalia widgets

---

## Dotfiles Workflow

All configuration files are managed using symlinks.

- Editing `~/.config/<app>` or `~/.zshrc` edits the repository directly
- No configuration files are generated by scripts (apart from empty Noctalia theme stubs)
- No duplication between scripts and dotfiles
- Pre-existing real files are renamed to `<file>.bak.YYYYMMDDHHMMSS` before the symlink is created

---

## Neovim Configuration

Neovim uses the upstream configuration: https://github.com/ljudina/php.nvim

The installer:
- clones the repo into `~/.local/share/nvim-php-config`
- symlinks it to `~/.config/nvim`

To update the Neovim config:

```bash
git -C ~/.local/share/nvim-php-config pull
```

---

## Zsh Setup Notes

- Oh My Zsh is installed automatically (with `RUNZSH=no CHSH=no KEEP_ZSHRC=yes`)
- Powerlevel10k is the active theme, cloned into `$ZSH_CUSTOM/themes/powerlevel10k`
- Zsh plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`) are installed via pacman and symlinked into `$ZSH_CUSTOM/plugins/`
- `navi` is integrated via `eval "$(navi widget zsh)"`
- Atuin is installed via the official setup script

---

## License

MIT License
