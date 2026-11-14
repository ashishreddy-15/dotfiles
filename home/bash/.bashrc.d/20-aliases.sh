# Aliases and small functions (interactive shells only).
[[ $- == *i* ]] || return 0

# ---- dnf ----
alias din='sudo dnf install'
alias dup='sudo dnf upgrade'
alias drm='sudo dnf remove'
alias dse='dnf search'
alias dinfo='dnf info'                  # about one package
alias dprov='dnf provides'              # which package has this file or command
alias dls='dnf list --installed'
alias dhist='dnf history'

# ---- files ----
alias ls='ls --color=auto --group-directories-first'
alias ll='ls -lh'
alias la='ls -lAh'
alias lt='ls -lht'                      # newest first
alias cp='cp -i'                        # ask before overwriting
alias mv='mv -i'
alias rm='rm -I'                        # ask once before deleting more than three files, or folders
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ip='ip -c'
alias grep='grep --color=auto'

# ---- moving around ----
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias dots='cd ~/dotfiles'
mkcd() { mkdir -p -- "$1" && cd -- "$1"; }

# ---- git ----
alias g='git'
alias gs='git status -sb'
alias gd='git diff'
alias gds='git diff --staged'
alias ga='git add'
alias gc='git commit'
alias gca='git commit --amend'
alias gp='git push'
alias gl='git pull'
alias gsw='git switch'
alias glog='git log --oneline --graph --decorate -20'

# ---- systemd ----
alias sc='systemctl'
alias scu='systemctl --user'
alias jf='journalctl -f'                # follow the system log
alias jfu='journalctl --user -f'        # follow your user services' log

# ---- the shell itself ----
alias reload='source ~/.bashrc'
