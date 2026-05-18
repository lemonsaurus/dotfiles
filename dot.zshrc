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
alias dockerkill='docker ps -q | xargs -r docker kill'

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
autoload -U add-zsh-hook
add-zsh-hook chpwd load_nvmrc
load_nvmrc

# bun completions
[ -s "/home/lemon/.bun/_bun" ] && source "/home/lemon/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/bin:$PATH"
