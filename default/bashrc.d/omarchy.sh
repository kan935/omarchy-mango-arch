# Omarchy-style bash shell setup, sourced from ~/.bashrc.d
# Derived from https://github.com/omacom/omarchy default/bash/{shell,init,aliases}

# History control
shopt -s histappend
HISTCONTROL=ignoreboth
HISTSIZE=32768
HISTFILESIZE="$HISTSIZE"

if [[ ! -v BASH_COMPLETION_VERSINFO && -f /usr/share/bash-completion/bash_completion ]]; then
  source /usr/share/bash-completion/bash_completion
fi

# Prompt (Omarchy's starship config)
if [[ $- == *i* ]] && [[ ${TERM:-} != "dumb" ]] && command -v starship &> /dev/null; then
  eval "$(starship init bash --print-full-init)"
fi

# Smarter cd: zoxide remembers directories, plain cd still works for exact paths
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init bash)"
  alias cd="zd"
  zd() {
    if (( $# == 0 )); then
      builtin cd ~ || return
    elif [[ -d $1 ]]; then
      builtin cd "$1" || return
    else
      if ! z "$@"; then
        echo "Error: Directory not found"
        return 1
      fi

      printf "\U000F17A9 "
      pwd
    fi
  }
fi

# Ctrl-R history search, Ctrl-T file finder (Omarchy sources just the bindings, not the completions)
if command -v fzf &> /dev/null; then
  for _fzf_bindings in /usr/share/fzf/shell/key-bindings.bash /usr/share/fzf/key-bindings.bash; do
    [[ -f $_fzf_bindings ]] && { source "$_fzf_bindings"; break; }
  done
  unset _fzf_bindings
fi

# File system
if command -v eza &> /dev/null; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
fi

alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
alias lg='lazygit'
alias t='tmux attach || tmux new -s Work'

open() (
  xdg-open "$@" >/dev/null 2>&1 &
)

# Directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git (Omarchy's git aliases)
alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'

# OpenCode CLI
if [[ -d $HOME/.opencode/bin ]]; then
  PATH="$HOME/.opencode/bin:$PATH"
fi

# Package-management shortcuts
alias op='opencode'
alias u='sudo pacman -Syu'
alias i='sudo pacman -S'
alias s='pacman -Ss'
