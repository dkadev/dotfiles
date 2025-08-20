#------------------------------------------------------
# Aliases
#------------------------------------------------------

alias ls='eza $eza_params'
alias l='eza --git-ignore $eza_params'
alias ll='eza --all --header --long $eza_params'
alias llm='eza --all --header --long --sort=modified $eza_params'
alias la='eza -lbhHigUmuSa'
alias lx='eza -lbhHigUmuSa@'
alias lt='eza --tree $eza_params'
alias tree='eza --tree $eza_params'

alias ff="fzf --style full --preview 'fzf-preview.sh {}' --bind 'focus:transform-header:file --brief {}'"

# macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
  alias cat="bat"
fi

# Linux
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  alias cat="batcat"
fi
alias ip="ip --color=auto"
alias h="history"
alias hs="history | grep"
alias hsi="history | grep -i"

# walk
alias lk="walk --icons"

# fman
alias fman="compgen -c | fzf | xargs man"

# tmux
alias tmxl="tmux ls"
alias tmxa="tmux a -t"
alias tmxk="tmux kill-session -t"