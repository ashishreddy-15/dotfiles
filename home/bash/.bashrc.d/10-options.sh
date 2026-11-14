# Shell behaviour (interactive shells only). Loaded by Fedora's ~/.bashrc, which sources ~/.bashrc.d/*.
[[ $- == *i* ]] || return 0

# History: big, no duplicates, shared between terminals (each command is written as soon as it ends).
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups        # skip duplicates and commands starting with a space
HISTIGNORE='ls:ll:la:cd:pwd:exit:clear:history'
shopt -s histappend cmdhist

shopt -s checkwinsize                  # follow the terminal size
shopt -s globstar                      # ** matches any depth
shopt -s autocd                        # type a folder's name to go into it
shopt -s cdspell dirspell              # fix small typos in folder names

# Completion and history search (readline).
bind 'set completion-ignore-case on'
bind 'set completion-map-case on'       # - and _ are the same when completing
bind 'set show-all-if-ambiguous on'     # one Tab lists the choices
bind 'set colored-stats on'             # colour the choices like ls
bind 'set mark-symlinked-directories on'
bind 'set skip-completed-text on'
# Up / Down search the history for what you have typed so far.
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
