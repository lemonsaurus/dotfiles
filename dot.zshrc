eval "$(starship init zsh)"

# opencode
export PATH=/home/lemon/.opencode/bin:$PATH

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

# Alias for bat (modern cat)
alias cat='batcat --style=auto'

# More aliases!
alias explore='explorer.exe'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# pnpm
export PNPM_HOME="/home/lemon/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Automatically switch to the right node version if .nvmrc exists
cdnvm() {
    builtin cd "$@" || return
    if [[ -f .nvmrc && -r .nvmrc ]]; then
        nvm use
    fi
}
alias cd='cdnvm'

# bun completions
[ -s "/home/lemon/.bun/_bun" ] && source "/home/lemon/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/bin:$PATH"
