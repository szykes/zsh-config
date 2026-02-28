echo "Load .zshrc"

setopt PROMPT_SUBST

include () {
  [[ -f "$1" ]] && source "$1"
}

git-print()
{
  if ! type git > /dev/null; then
    echo "NA"
    return
  fi

  branch=$(git branch --show-current 2> /dev/null)
  if [ -n "$branch" ]; then
    local=$(git rev-parse ${branch} 2> /dev/null)
    origin=$(git rev-parse origin/${branch} 2> /dev/null)
    if [ "$local" = "$origin" ]; then
      echo ${branch}
      return
    else
      echo "${branch} !"
      return
    fi
  else
    branch=$(git branch 2> /dev/null | cut -d\  -f5)
    echo ${branch%?}
    return
  fi
}

k8s-cluster-print()
{
  if ! type kubectx > /dev/null; then
    return
  fi

  if [[ "$(kubectx | wc -l | tr -d ' ')" -lt 2 ]]; then
    return
  fi

  ctx="$(kubectx -c 2> /dev/null | sed -E 's|^arn:aws:eks:([^:]+):[^:]+:cluster/(.*)|\1/\2|')"
  if [[ "$?" -ne "0" ]]; then
    return
  fi

  echo "|$ctx"
}

k8s-namespace-print()
{
  if ! type kubens > /dev/null; then
    return
  fi

  ns="$(kubens -c 2> /dev/null)"
  if [[ "$?" -ne "0" ]]; then
    return
  fi

  echo "|$ns"
}

autoload -Uz compinit
compinit

autoload bashcompinit && bashcompinit

include $HOME/.secret
include $HOME/tools/.add-paths
include $HOME/.zshrc-company

PROMPT='%F{green}%B%n%F{yellow}[$(git-print)$(k8s-cluster-print)$(k8s-namespace-print)]%F{green}@%m:%F{blue}%~%#%f%b '

HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=$HISTSIZE
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.

unalias -a

# https://www.cyberciti.biz/faq/apple-mac-osx-terminal-color-ls-output-option/
export CLICOLOR=1
export LSCOLORS=ehfxcxdxbxegedabagacad

# emacs
export LSP_USE_PLISTS=true

alias -g ls="ls -F --color"
alias -g ll="ls -lF --color"
alias -g la="ls -alF --color"
alias -g grep="grep --color=auto"

alias -g git-log="git log --graph  --color --decorate --oneline --all --dense --date=local | less -R"
alias -g git-sub="git submodule update --init --recursive --jobs 10"
alias -g git-pull="git pull -r ; git pull -r && git-sub"
alias -g git-push-for="git push origin HEAD:refs/for/$(git symbolic-ref HEAD 2> /dev/null | sed -e 's,.*/\(.*\),\1,')"
alias -g git-push-draft="git push origin HEAD:refs/drafts/$(git symbolic-ref HEAD 2> /dev/null | sed -e 's,.*/\(.*\),\1,')"

if type go > /dev/null; then
  if [ -n "$(go env GOBIN)" ]; then
    export PATH="$(go env GOBIN):$PATH"
  elif [ -n "$(go env GOPATH)" ]; then
    export PATH="$(go env GOPATH)/bin:$PATH"
  else
    echo "WARNING: GOPATH is not set"
  fi
fi

if type kubectl > /dev/null ; then
  if [[ ! -e ~/.oh-my-zsh/completions/_kubernetes ]]; then
    mkdir -p ~/.oh-my-zsh/completions
    kubectl completion zsh > ~/.oh-my-zsh/completions/_kubernetes
  fi
  source ~/.oh-my-zsh/completions/_kubernetes

  alias -g k="kubectl"
fi

if type docker > /dev/null ; then
  if [[ ! -e ~/.oh-my-zsh/completions/_docker ]]; then
    mkdir -p ~/.oh-my-zsh/completions
    docker completion zsh > ~/.oh-my-zsh/completions/_docker
  fi

  source ~/.oh-my-zsh/completions/_docker
fi

if [ -f /opt/homebrew/bin/brew ]; then
   eval "$(/opt/homebrew/bin/brew shellenv)"

   export HOMEBREW_NO_AUTO_UPDATE=1
   export HOMEBREW_NO_INSTALL_FROM_API=1

   # https://docs.brew.sh/Shell-Completion
   FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

   if type az > /dev/null; then
     # https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-macos
     include $(brew --prefix)/etc/bash_completion.d/az
   fi

   if [ -d /opt/homebrew/opt/llvm/bin ]; then
     export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
   fi
fi

run-emacs()
{
  rm -f "$HOME/.emacs.d/desktop/lock"
  emacsclient --tty --alternate-editor="" -e '(switch-to-buffer nil)'
}

find-and-replace()
{
  if [ -z $1 ]; then
    echo "HELP: find-and-replace [path] [find string] [replace to]"
    echo "Separator character is ^"
    return 0
  fi

  if type fd > /dev/null && type sd > /dev/null ; then
    fd -t f . "$1" -x sd "$2" "$3"
  else
    echo "WARNING: execute `brew install fd sd` to be more effective"
    find $1 \( -type d -name .git -prune \) -o -type f -exec grep -Iq . {} \; -print0  | xargs -0 sed -i '' "s^$2^$3^g"
  fi
}
