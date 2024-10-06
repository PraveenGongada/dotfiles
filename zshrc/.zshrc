# Exported Paths
export ZSH="$HOME/.config/zshrc"
export PATH="$PATH:/Users/praveenkumar/FlutterDev/flutter/bin"
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
export PATH="$PATH:/Users/praveenkumar/istio-1.22.3/bin"
export CONFIG_DIR="$HOME/.config/lazygit"
export PATH="/opt/homebrew/bin:$PATH"

# Plugins
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Eza
alias l="eza -l --icons --git"
alias ls="eza --icons"
alias lt="eza --tree --level=2 --icons"
alias ltree="eza --tree --level=2 --long --icons"

# Aliases
alias ..="cd .."
alias ...="cd ../.."

# Oh My Posh 
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/themes/powerlevel10k-custom.yaml)"
# eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/themes/robbyrussell.yaml)"
# eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/robbyrussell.omp.json)"
