#------------------------------------------------------
# Aliases
#------------------------------------------------------

alias ls="lsd"
alias ll="ls -lh"
alias lla="ls -lah"
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

alias fman="compgen -c | fzf | xargs man"