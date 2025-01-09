echo "Load .zshrc"

setopt PROMPT_SUBST

ulimit -n 2048

include () {
  [[ -f "$1" ]] && source "$1"
}

git-print()
{
  if ! which git > /dev/null; then
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

  echo "|"$(kubectx -c)
}

k8s-namespace-print()
{
  if ! type kubens > /dev/null; then
    return
  fi

  echo "|"$(kubens -c)
}

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

alias -g ls="ls -F --color"
alias -g ll="ls -lF --color"
alias -g la="ls -alF --color"
alias -g grep="grep --color=auto"

alias -g git-log="git log --graph  --color --decorate --oneline --all --dense --date=local | less -R"
alias -g git-sub="git submodule update --init --recursive --jobs 10"
alias -g git-pull="git pull -r ; git pull -r && git-sub"
alias -g git-push-for="git push origin HEAD:refs/for/$(git symbolic-ref HEAD 2> /dev/null | sed -e 's,.*/\(.*\),\1,')"
alias -g git-push-draft="git push origin HEAD:refs/drafts/$(git symbolic-ref HEAD 2> /dev/null | sed -e 's,.*/\(.*\),\1,')"

if type go &>/dev/null
then
  if [ -n "$(go env GOBIN)" ]; then
    export PATH="$(go env GOBIN):$PATH"
  elif [ -n "$(go env GOPATH)" ]; then
    export PATH="$(go env GOPATH)/bin:$PATH"
  else
    echo "WARNING: GOPATH is not set"
  fi
fi

export PATH

eval "$(/opt/homebrew/bin/brew shellenv)"

export LSP_USE_PLISTS=true

export HOMEBREW_NO_INSTALL_FROM_API=1

autoload -Uz compinit
compinit

# https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-macos
autoload bashcompinit && bashcompinit
include $(brew --prefix)/etc/bash_completion.d/az

# https://docs.brew.sh/Shell-Completion
if type brew &>/dev/null
then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

# https://medium.com/@bm54cloud/how-to-setup-kubectl-zsh-autocompletion-for-macos-2fb4d270cfab
#kubectl autocompletion
if type kubectl &>/dev/null
then
  source <(kubectl completion zsh)
  alias -g k="kubectl"
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

  find $1 \( -type d -name .git -prune \) -o -type f -exec grep -Iq . {} \; -print0  | xargs -0 sed -i '' "s^$2^$3^g"
}

go-install-if-exists()
{
  if type "$1" &>/dev/null
  then
    echo "Updating $1"
    go install "$2"
  else
    echo "Not installed: $1"
  fi
}

update-packages()
{
  if type brew &>/dev/null
  then
    brew update && brew upgrade && brew cleanup
  fi

  if type go &>/dev/null
  then
    go-install-if-exists gopls golang.org/x/tools/gopls@latest
    go-install-if-exists mockgen go.uber.org/mock/mockgen@latest
    go-install-if-exists govulncheck golang.org/x/vuln/cmd/govulncheck@latest
    go-install-if-exists deadcode golang.org/x/tools/cmd/deadcode@latest
    go-install-if-exists golangci-lint github.com/golangci/golangci-lint/cmd/golangci-lint@latest
    go-install-if-exists impi github.com/pavius/impi/cmd/impi@latest
    go-install-if-exists go-acc github.com/ory/go-acc@latest
    go-install-if-exists protoc-gen-go google.golang.org/protobuf/cmd/protoc-gen-go@latest
    go-install-if-exists protoc-gen-go-grpc google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
  fi
}
