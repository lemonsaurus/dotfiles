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
    # Try non-interactive sudo first (works if sudo is cached), otherwise defer
    if sudo -n chsh -s "$(command -v zsh)" "$USER" 2>/dev/null; then
        ok "zsh is now the default shell"
    else
        warn "Run manually: sudo chsh -s $(command -v zsh) $USER"
    fi
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
else
    ok "eza is installed"
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
else
    ok "bat is installed"
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

# --- Install MesloLGS Nerd Font ---
# Only install fonts locally — over SSH, the local terminal handles font rendering
FONT_NAME="MesloLGS Nerd Font"
if [ -n "${SSH_CLIENT:-}${SSH_CONNECTION:-}" ]; then
    info "SSH session detected — skipping font install (install $FONT_NAME on your local machine)"
else
    FONT_DIR="$HOME/.local/share/fonts"
    if ! fc-list 2>/dev/null | grep -qi "MesloLGS"; then
        info "Installing $FONT_NAME..."
        mkdir -p "$FONT_DIR"
        MESLO_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Meslo.tar.xz"
        tmp_archive="$(mktemp)"
        curl -fsSL "$MESLO_URL" -o "$tmp_archive"
        # Extract only MesloLGS variants into the font directory
        tar -xJf "$tmp_archive" -C "$FONT_DIR" --wildcards 'MesloLGSNerdFont-*' 2>/dev/null \
            || tar -xJf "$tmp_archive" -C "$FONT_DIR"
        rm -f "$tmp_archive"
        if command -v fc-cache &>/dev/null; then
            fc-cache -f "$FONT_DIR"
        fi
        ok "$FONT_NAME installed"
    else
        ok "$FONT_NAME already installed"
    fi
fi

# --- Deploy configs (only if changed) ---
deploy_config() {
    local url="$1" dest="$2" label="$3"
    local tmp
    tmp="$(mktemp)"
    curl -fsSL "$url" -o "$tmp"
    if [ -f "$dest" ] && cmp -s "$tmp" "$dest"; then
        rm "$tmp"
        ok "$label already up to date"
    else
        if [ -f "$dest" ]; then
            cp "$dest" "${dest}.bak"
            warn "Backed up existing $label to ${dest}.bak"
        fi
        mkdir -p "$(dirname "$dest")"
        mv "$tmp" "$dest"
        ok "$label installed"
    fi
}

deploy_config "$REPO/dot.starship.toml" "$HOME/.config/starship.toml" "starship.toml"
deploy_config "$REPO/dot.zshrc" "$HOME/.zshrc" ".zshrc"

# --- WSL: Install Rio config on Windows side ---
if grep -qi microsoft /proc/version 2>/dev/null; then
    info "WSL detected — installing Rio config on Windows side..."

    WIN_USER=$(/mnt/c/Windows/System32/cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')

    if [ -d "/mnt/c/Users/$WIN_USER" ]; then
        # --- Detect or install a Nerd Font on Windows ---
        POWERSHELL="/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
        RIO_FONT=""

        # Ask Windows for the real font family names — filenames are unreliable
        if [ -x "$POWERSHELL" ]; then
            RIO_FONT=$("$POWERSHELL" -NoProfile -Command '
                Add-Type -AssemblyName System.Drawing
                (New-Object System.Drawing.Text.InstalledFontCollection).Families |
                    Where-Object { $_.Name -match "Nerd|NF" } |
                    Select-Object -First 1 -ExpandProperty Name
            ' 2>/dev/null | tr -d '\r')
        fi

        if [ -n "$RIO_FONT" ]; then
            ok "Found Nerd Font on Windows: $RIO_FONT"
        else
            # No Nerd Font found — install MesloLGS
            info "No Nerd Font found on Windows — installing $FONT_NAME..."
            MESLO_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Meslo.tar.xz"
            tmp_archive="$(mktemp)"
            curl -fsSL "$MESLO_URL" -o "$tmp_archive"
            SYS_FONT_DIR="/mnt/c/Windows/Fonts"
            USER_FONT_DIR="/mnt/c/Users/$WIN_USER/AppData/Local/Microsoft/Windows/Fonts"
            if cp /dev/null "$SYS_FONT_DIR/.write-test" 2>/dev/null; then
                rm -f "$SYS_FONT_DIR/.write-test"
                tar -xJf "$tmp_archive" -C "$SYS_FONT_DIR" --wildcards 'MesloLGSNerdFont-*' 2>/dev/null \
                    || tar -xJf "$tmp_archive" -C "$SYS_FONT_DIR"
                ok "$FONT_NAME installed to system fonts"
            else
                mkdir -p "$USER_FONT_DIR"
                tar -xJf "$tmp_archive" -C "$USER_FONT_DIR" --wildcards 'MesloLGSNerdFont-*' 2>/dev/null \
                    || tar -xJf "$tmp_archive" -C "$USER_FONT_DIR"
                warn "$FONT_NAME installed to user fonts — Rio may not see it. Right-click the .ttf files and 'Install for all users' if needed."
            fi
            rm -f "$tmp_archive"
            RIO_FONT="MesloLGS Nerd Font"
        fi

        # --- Deploy Rio config and patch font family ---
        RIO_DIR="/mnt/c/Users/$WIN_USER/AppData/Local/rio"
        mkdir -p "$RIO_DIR/themes"
        deploy_config "$REPO/rio.config.toml" "$RIO_DIR/config.toml" "Rio config"
        deploy_config "$REPO/rio.themes.electron-highlighter.toml" "$RIO_DIR/themes/Electron Highlighter.toml" "Rio theme"

        # Patch Rio config to use the detected/installed font
        if [ -n "$RIO_FONT" ]; then
            sed -i "s/family = \"MesloLGS Nerd Font\"/family = \"$RIO_FONT\"/" "$RIO_DIR/config.toml"
            ok "Rio config set to use font: $RIO_FONT"
        fi
    else
        warn "Couldn't find Windows user directory. Install Rio config manually."
    fi
else
    info "Not running in WSL — skipping Rio config."
fi

echo ""
ok "All done! Restart your terminal or run 'zsh' to get started."
