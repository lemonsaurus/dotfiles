eval "$(starship init zsh)"

# opencode (WSL box only; skipped where not installed)
[ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"

# Add local bin to PATH for eza and bat
export PATH=$HOME/.local/bin:$PATH

# zsh-autosuggestions - suggests commands as you type based on history
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-z - jump to frequently used directories
source ~/.zsh/zsh-z/zsh-z.plugin.zsh

# zsh-syntax-highlighting - colors commands as you type
# NOTE: This must be sourced at the end
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Aliases for eza (modern ls)
alias ls='eza --icons'
alias ll='eza -l --icons --git'
alias la='eza -la --icons --git'
alias lt='eza --tree --icons'

# Open multiple folders in VSCode
codeall() { for dir in "$@"; do code "$dir"; done }

# Alias for bat (modern cat) — Ubuntu names it batcat, brew names it bat
if command -v batcat >/dev/null; then
  alias cat='batcat --style=auto'
elif command -v bat >/dev/null; then
  alias cat='bat --style=auto'
fi

# explore {path}: open the file explorer at that path (WSL or native Linux)
explore() {
  local target="${1:-.}"
  [ -f "$target" ] && target="$(dirname "$target")"
  if command -v explorer.exe >/dev/null; then
    explorer.exe "$(wslpath -w "$target")" || true
  else
    xdg-open "$target"
  fi
}
alias dockerkill='docker ps -q | xargs -r docker kill'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# pnpm (skipped where not installed)
export PNPM_HOME="$HOME/.local/share/pnpm"
if [ -d "$PNPM_HOME" ]; then
  case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
  esac
fi
# pnpm end

# Automatically switch node version when .nvmrc is found in cwd or any parent
load_nvmrc() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -r "$dir/.nvmrc" ]]; then
            local want="$(<"$dir/.nvmrc")"
            local have="$(nvm version)"
            local target="$(nvm version "$want")"
            if [[ "$target" == "N/A" ]]; then
                nvm install "$want"
            elif [[ "$target" != "$have" ]]; then
                nvm use "$want"
            fi
            return
        fi
        dir="${dir:h}"
    done
}
if command -v nvm >/dev/null; then
  autoload -U add-zsh-hook
  add-zsh-hook chpwd load_nvmrc
  load_nvmrc
fi

# bun (skipped where not installed)
export BUN_INSTALL="$HOME/.bun"
if [ -d "$BUN_INSTALL" ]; then
  [ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
fi

export PATH="/usr/local/bin:$PATH"

# carla-sync: pull ~/.agents on shell start (if safe). See ~/.agents/README.md.
# Runs in the background so it never slows the shell.
[[ -x "$HOME/.agents/bin/carla-sync" ]] && "$HOME/.agents/bin/carla-sync" &!


# Pi
export PATH="$HOME/.local/share/pi-node/current/bin:$PATH"

# dotagents: load Pi private integration tokens
if [ -f "$HOME/.pi/agent/private.env" ]; then
  set -a
  source "$HOME/.pi/agent/private.env"
  set +a
fi

# Machine-specific settings kept out of the repo
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
