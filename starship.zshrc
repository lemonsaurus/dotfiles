eval "$(starship init zsh)"
cd

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

# Alias for bat (modern cat)
alias cat='bat --style=auto'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
