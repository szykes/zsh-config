echo "Load .zshrc"

setopt PROMPT_SUBST

include () {
    [[ -f "$1" ]] && source "$1"
}

cc-git-print()
{
  branch=$(git symbolic-ref HEAD 2> /dev/null | sed -e 's,.*/\(.*\),\1,')
  if [ -n "$branch" ]; then
    local=$(git rev-parse ${branch})
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

  echo "NA"
}

include $HOME/.secret
include $HOME/tools/.add-paths

PROMPT="%F{green}%B%n%F{yellow}[$(cc-git-print)]%F{green}@%m:%F{blue}%~%#%f%b "

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

alias -g vi="vim"

alias -g git-log="git log --graph  --color --decorate --oneline --all --dense --date=local | less -R"
alias -g git-sub="git submodule update --init --recursive --jobs 10"
alias -g git-pull="git pull -r ; git pull -r && git-sub"
alias -g git-push-for="git push origin HEAD:refs/for/$(git symbolic-ref HEAD 2> /dev/null | sed -e 's,.*/\(.*\),\1,')"
alias -g git-push-draft="git push origin HEAD:refs/drafts/$(git symbolic-ref HEAD 2> /dev/null | sed -e 's,.*/\(.*\),\1,')"

path=('/opt/homebrew/bin' $path)
export PATH

eval "$(/opt/homebrew/bin/brew shellenv)"

export LSP_USE_PLISTS=true

run-emacs()
{
  if [ $(ps aux | grep -i emacs | grep daemon | grep $USER | wc -l) -eq 0 ]; then
    emacs --daemon=$USER
  fi
  emacsclient -s $USER -t
}

find-and-replace()
{
    if [ -z $1 ]; then
        echo "HELP: find-and-replace [path] [find string] [replace to]"
        return 0
    fi

    find $1 \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i "s@$2@$3@g"
}
