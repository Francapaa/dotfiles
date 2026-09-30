#!/usr/bin/env bash
# dotfiles install — Linux / Mac / WSL
# Uso: ./install.sh
set -euo pipefail
DOTFILES="$(cd "$(dirname "$0")" && pwd)"
echo "dotfiles: $DOTFILES"

link_or_copy() {
  local src="$1" dst="$2"
  [ -e "$src" ] || { echo "SKIP (falta fuente): $src"; return 0; }
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mv "$dst" "$dst.bak-$(date +%Y%m%d-%H%M%S)"
    echo "backup: $dst"
  fi
  if ln -sf "$src" "$dst" 2>/dev/null; then echo "link: $dst -> $src";
  else cp -r "$src" "$dst"; echo "copy (fallback): $dst"; fi
}

# OS paths
if [[ "$OSTYPE" == "darwin"* ]]; then ZED_DIR="$HOME/Library/Application Support/Zed";
else ZED_DIR="$HOME/.config/zed"; fi
OPENCODE_DIR="$HOME/.config/opencode"
SKILLS_DIR="$HOME/.agents/skills"
PROFILE_DEST="$HOME/.config/powershell/Microsoft.PowerShell_profile.ps1"

# .env
[ -f "$DOTFILES/.env" ] || { cp "$DOTFILES/.env.example" "$DOTFILES/.env"; echo "creado .env desde ejemplo — completalo"; }
set -a; [ -f "$DOTFILES/.env" ] && source "$DOTFILES/.env"; set +a

# Zed
link_or_copy "$DOTFILES/zed/settings.json" "$ZED_DIR/settings.json"
link_or_copy "$DOTFILES/zed/keymap.json" "$ZED_DIR/keymap.json"
link_or_copy "$DOTFILES/zed/AGENTS.md" "$ZED_DIR/AGENTS.md"
echo "Zed extensions: ver zed/extensions.txt"

# Opencode
link_or_copy "$DOTFILES/opencode/opencode.jsonc" "$OPENCODE_DIR/opencode.jsonc"
mkdir -p "$OPENCODE_DIR/plugins"
cp -r "$DOTFILES/opencode/plugins/"* "$OPENCODE_DIR/plugins/" 2>/dev/null || true

# Git
[ -z "$(git config --global user.name || true)" ] && [ -n "${DOTFILES_GIT_NAME:-}" ] && git config --global user.name "$DOTFILES_GIT_NAME" || true
[ -z "$(git config --global user.email || true)" ] && [ -n "${DOTFILES_GIT_EMAIL:-}" ] && git config --global user.email "$DOTFILES_GIT_EMAIL" || true

# PowerShell profile (si usas pwsh en linux)
link_or_copy "$DOTFILES/powershell/Microsoft.PowerShell_profile.ps1" "$PROFILE_DEST"

# SSH
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
[ -f "$HOME/.ssh/config" ] || [ ! -f "$DOTFILES/ssh/config.example" ] || cp "$DOTFILES/ssh/config.example" "$HOME/.ssh/config"

# Skills públicas: solo aviso (ver agents/README.md)
echo "skills públicas: ver agents/skills-manifest.json"

# Skills privadas
if [ -n "${SKILLS_PRIVATE_REPO:-}" ]; then
  PRIV="$HOME/.agents/skills-private"
  [ -d "$PRIV" ] || git clone "$SKILLS_PRIVATE_REPO" "$PRIV"
  for d in "$PRIV"/*/; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    [ -e "$SKILLS_DIR/$name" ] || link_or_copy "$d" "$SKILLS_DIR/$name"
  done
else echo "SKILLS_PRIVATE_REPO no seteado — salto privadas"; fi

echo "Listo. Reinicia terminal."
