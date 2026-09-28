#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source_home="${DOTFILES_SOURCE_HOME:-$HOME}"
target_home="$repo_dir/home"

mkdir -p "$target_home/.config"

files=(
  .condarc
  .docker/daemon.json
  .docker/mcp/config.yaml
  .docker/mcp/registry.yaml
  .docker/mcp/tools.yaml
  .p10k.zsh
  .tmux.conf
  .vimrc
  .wezterm.lua
  .zprofile
  .zshrc
)

for path in "${files[@]}"; do
  if [[ -f "$source_home/$path" ]]; then
    mkdir -p "$(dirname "$target_home/$path")"
    cp -p "$source_home/$path" "$target_home/$path"
  fi
done

directories=(
  .config/fish
  .config/htop
  .config/neofetch
)

for path in "${directories[@]}"; do
  if [[ -d "$source_home/$path" ]]; then
    mkdir -p "$target_home/$path"
    rsync -a --delete \
      --exclude='.git/' \
      --exclude='.DS_Store' \
      --exclude='*.swp' \
      --exclude='*history*' \
      --exclude='*.sqlite*' \
      --exclude='*.db' \
      --exclude='node_modules/' \
      "$source_home/$path/" "$target_home/$path/"
  fi
done

# Never retain token-like values copied from shell configuration, including
# commented examples. The original file remains untouched.
if [[ -f "$target_home/.zshrc" ]]; then
  perl -0pi -e 's/(\b(?:API_KEY|AUTH_TOKEN|ACCESS_TOKEN|SECRET|PASSWORD)\b\s*[=:]\s*)"[^"\n]*"/${1}"REDACTED"/gi; s/(\b(?:API_KEY|AUTH_TOKEN|ACCESS_TOKEN|SECRET|PASSWORD)\b\s*=\s*)[^\\\s;#]+/${1}REDACTED/gi; s/\bsk-[A-Za-z0-9_-]+\b/REDACTED/g' "$target_home/.zshrc"
fi

echo "Synced portable dotfiles into $target_home"
