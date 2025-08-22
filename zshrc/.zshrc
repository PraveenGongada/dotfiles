if [[ -f "/opt/homebrew/bin/brew" ]] then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Oh My Posh 
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/themes/powerlevel10k-custom.yaml)"
# eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/themes/robbyrussell.yaml)"
# eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/robbyrussell.omp.json)"

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in zsh plugins
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light jeffreytse/zsh-vi-mode

# Add in snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Zsh Vi Mode 
# Following 4 lines modify the escape key to `jj`
ZVM_VI_ESCAPE_BINDKEY=jj
ZVM_VI_INSERT_ESCAPE_BINDKEY=$ZVM_VI_ESCAPE_BINDKEY
ZVM_VI_VISUAL_ESCAPE_BINDKEY=$ZVM_VI_ESCAPE_BINDKEY
ZVM_VI_OPPEND_ESCAPE_BINDKEY=$ZVM_VI_ESCAPE_BINDKEY

# Source .fzf.zsh so that the ctrl+r bindkey is given back fzf
zvm_after_init_commands+=('[ -f $HOME/.fzf.zsh ] && source $HOME/.fzf.zsh')

# Syntax Hihghlighting
typeset -A ZSH_HIGHLIGHT_STYLES

ZSH_HIGHLIGHT_STYLES[command]='fg=white'
ZSH_HIGHLIGHT_STYLES[alias]='fg=white'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=white'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=white'
ZSH_HIGHLIGHT_STYLES[default]='fg=white'
ZSH_HIGHLIGHT_STYLES[function]='fg=white'

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias cd="z"
alias ..="cd .."
alias ...="cd ../.."

# Eza
alias l="eza -l --icons --git"
alias ls="eza --icons=always"
alias lt="eza --tree --level=2 --icons"
alias ltree="eza --tree --level=2 --long --icons"

# Nvim
alias n="nvim"

#Lazygit 
alias lg="lazygit"

# Pomodoro
function work () {
  timer 25m
  osascript -e 'display notification "Pomodoro" with title "Work Timer is up! Take a Break 😊" sound name "Crystal"'
}

function rest () {
  timer 5m
  osascript -e 'display notification "Pomodoro" with title "Break is over! Get back to work 😬" sound name "Crystal"'
}

# Clear
clear() { command clear; [ -n "$TMUX" ] && tmux clear-history; return true}

export ZSH="$HOME/.config/zshrc"
export GPG_TTY=$(tty)
export PATH="$PATH:/Users/praveenkumar/FlutterDev/flutter/bin"
export PATH="$GOPATH/bin:$PATH"
export PATH="$PATH:/Users/praveenkumar/istio-1.26.3/bin"
export CONFIG_DIR="$HOME/.config/lazygit"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.local/share/zinit/plugins/JanDeDobbeleer/oh-my-posh:$PATH"
export EDITOR="nvim"
export XDG_CONFIG_HOME=$HOME/.config

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"

# Kubectl completion
source <(kubectl completion zsh)
