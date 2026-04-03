#!/usr/bin/env bash
set -euo pipefail

REPO="https://raw.githubusercontent.com/lemonsaurus/dotfiles/main"

info()  { printf '\033[1;34m=> %s\033[0m\n' "$*"; }
ok()    { printf '\033[1;32m=> %s\033[0m\n' "$*"; }
warn()  { printf '\033[1;33m=> %s\033[0m\n' "$*"; }
error() { printf '\033[1;31m=> %s\033[0m\n' "$*"; exit 1; }

# --- Install zsh ---
if ! command -v zsh &>/dev/null; then
    info "Installing zsh..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y -qq zsh
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y zsh
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm zsh
    else
        error "Couldn't figure out your package manager. Install zsh manually and re-run."
    fi
fi
ok "zsh is installed"

# --- Make zsh default shell ---
if [ "$SHELL" != "$(command -v zsh)" ]; then
    info "Setting zsh as default shell..."
    chsh -s "$(command -v zsh)" || warn "Couldn't change default shell. Run: chsh -s $(command -v zsh)"
fi

# --- Install starship ---
if ! command -v starship &>/dev/null; then
    info "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi
ok "starship is installed"

# --- Install eza ---
if ! command -v eza &>/dev/null; then
    info "Installing eza..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y -qq eza 2>/dev/null || {
            # eza might not be in default repos on older Ubuntu
            sudo mkdir -p /etc/apt/keyrings
            wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
            sudo apt-get update -qq && sudo apt-get install -y -qq eza
        }
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y eza
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm eza
    else
        warn "Couldn't install eza automatically. Install it manually: https://eza.rocks"
    fi
fi

# --- Install bat ---
if ! command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    info "Installing bat..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y -qq bat
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y bat
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm bat
    else
        warn "Couldn't install bat automatically. Install it manually: https://github.com/sharkdp/bat"
    fi
fi

# --- Install zsh plugins ---
ZSH_PLUGIN_DIR="$HOME/.zsh"
mkdir -p "$ZSH_PLUGIN_DIR"

install_zsh_plugin() {
    local name="$1" repo="$2"
    if [ ! -d "$ZSH_PLUGIN_DIR/$name" ]; then
        info "Installing zsh plugin: $name"
        git clone --depth 1 "$repo" "$ZSH_PLUGIN_DIR/$name"
    else
        ok "zsh plugin already installed: $name"
    fi
}

install_zsh_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git"
install_zsh_plugin "zsh-z"               "https://github.com/agkozak/zsh-z.git"
install_zsh_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"

# --- Deploy configs ---
info "Installing starship config..."
mkdir -p "$HOME/.config"
curl -fsSL "$REPO/dot.starship.toml" -o "$HOME/.config/starship.toml"
ok "starship.toml installed"

info "Installing .zshrc..."
if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.bak"
    warn "Backed up existing .zshrc to .zshrc.bak"
fi
curl -fsSL "$REPO/dot.zshrc" -o "$HOME/.zshrc"
ok ".zshrc installed"

# --- Terminal emulator setup (Ghostty on native Linux, Rio on WSL) ---
if grep -qi microsoft /proc/version 2>/dev/null; then
    info "WSL detected — installing Rio config on Windows side..."

    WIN_USER=$(/mnt/c/Windows/System32/cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
    RIO_DIR="/mnt/c/Users/$WIN_USER/AppData/Local/rio"
    RIO_THEMES="$RIO_DIR/themes"

    if [ -d "/mnt/c/Users/$WIN_USER" ]; then
        mkdir -p "$RIO_THEMES"
        curl -fsSL "$REPO/rio.config.toml" -o "$RIO_DIR/config.toml"
        curl -fsSL "$REPO/rio.themes.electron-highlighter.toml" -o "$RIO_THEMES/Electron Highlighter.toml"
        ok "Rio config and theme installed"
    else
        warn "Couldn't find Windows user directory. Install Rio config manually."
    fi
else
    info "Not running in WSL — skipping Rio config."
fi

echo ""
ok "All done! Restart your terminal or run 'zsh' to get started."
