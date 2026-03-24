#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.sh"

need_cmd git
need_cmd curl
need_cmd zsh

install_ohmyzsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log "Oh My Zsh already installed"
    return 0
  fi

  log "Installing Oh My Zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_p10k() {
  local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  local dir="$custom/themes/powerlevel10k"

  if [[ -d "$dir/.git" ]]; then
    log "powerlevel10k already installed, updating"
    (cd "$dir" && git pull --ff-only)
  else
    log "Installing powerlevel10k"
    mkdir -p "$(dirname "$dir")"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$dir"
  fi
}

set_default_shell_zsh() {
  local zsh_path
  zsh_path="$(command -v zsh)"

  if [[ "${SHELL:-}" == "$zsh_path" ]]; then
    log "Default shell already zsh"
    return 0
  fi

  log "Setting default shell to zsh"
  chsh -s "$zsh_path"
}

install_ohmyzsh
install_p10k
set_default_shell_zsh

link_omz_plugin() {
  local name="$1"
  local src="/usr/share/zsh/plugins/$name"
  local dst="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$name"

  if [[ -d "$src" && ! -e "$dst" ]]; then
    log "Linking OMZ plugin: $name"
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
  fi
}

link_omz_plugin zsh-autosuggestions
link_omz_plugin zsh-syntax-highlighting
