# The prompt:   ~/dotfiles  main  3.2s ✗1 ❯
#   folder (the last three levels), git branch, how long the last command took (from 2 s on),
#   its exit code (only when it failed), then ❯ (# as root). user@host first over SSH; (venv) when one is active.
#
# Built to never lag: drawing it starts no programs at all (no git, no subshells, no $(...)). The branch is read
# from .git/HEAD with bash's own `read`; the time comes from $EPOCHREALTIME. Colours: the terminal's own palette slots, so it follows kitty's light/dark switch live.
[[ $- == *i* ]] || return 0

PROMPT_DIRTRIM=3

# Colours are the terminal's palette slots, not fixed values: kitty swaps the palette when the desktop goes light or
# dark, and even a shell that is already open follows. Wrapped in \[ \] so bash knows they take no space.
# Each one starts with 0 (reset) so the bold of the folder does not leak into the next part.
__p_dir='\[\e[0;1m\]'                 # default foreground, bold (readable on both backgrounds)
__p_git='\[\e[0;34m\]'                # colour 4: the pewter blue-grey
__p_dim='\[\e[0;90m\]'                # colour 8 (bright black): dim
__p_err='\[\e[0;31m\]'                # colour 1: error
__p_ok='\[\e[0;32m\]'                 # colour 2: ok
__p_off='\[\e[0m\]'

# The branch (or the short commit when detached), found by walking up to the nearest .git. Sets __p_branch.
__p_find_branch() {
    __p_branch=''
    local dir=$PWD head line gitdir
    while :; do
        if [[ -f $dir/.git/HEAD ]]; then
            read -r head < "$dir/.git/HEAD"
            break
        elif [[ -f $dir/.git ]]; then                       # a worktree or submodule: ".git" names the real folder
            read -r line < "$dir/.git"
            gitdir=${line#gitdir: }
            [[ $gitdir == /* ]] || gitdir=$dir/$gitdir
            read -r head < "$gitdir/HEAD" 2>/dev/null
            break
        fi
        [[ -z $dir ]] && return
        dir=${dir%/*}
    done
    if [[ $head == 'ref: refs/heads/'* ]]; then __p_branch=${head#ref: refs/heads/}
    elif [[ -n $head ]]; then __p_branch=${head:0:7}
    fi
}

# When a command starts, PS0 notes the time (an arithmetic expansion: no subshell, prints nothing).
PS0='${PS0:0:$((__p_start = ${EPOCHREALTIME/./}, 0))}'

__p_prompt() {
    local status=$? took='' ps
    # How long the last command took (only when one ran; Enter on an empty line runs nothing).
    if [[ -n $__p_start ]]; then
        local us=$(( ${EPOCHREALTIME/./} - __p_start ))
        unset __p_start
        if (( us >= 2000000 )); then
            local s=$(( us / 1000000 ))
            if (( s >= 60 )); then printf -v took '%dm%02ds' $(( s / 60 )) $(( s % 60 ))
            else printf -v took '%d.%ds' "$s" $(( us % 1000000 / 100000 ))
            fi
        fi
    else
        status=0                                             # nothing ran: do not repeat an old failure
    fi

    # Changed folder? Then tell whoever wants to know (zoxide, in 50-fzf.sh). Nothing runs while you stay put.
    if [[ $PWD != "$__p_lastdir" ]]; then
        __p_lastdir=$PWD
        declare -F __p_on_cd >/dev/null && __p_on_cd
    fi

    __p_find_branch
    ps=''
    [[ -n $SSH_CONNECTION ]] && ps+="${__p_dim}\u@\h "
    [[ -n $VIRTUAL_ENV ]] && ps+="${__p_dim}(${VIRTUAL_ENV##*/}) "
    ps+="${__p_dir}\w"
    [[ -n $__p_branch ]] && ps+="  ${__p_git}${__p_branch}"
    [[ -n $took ]] && ps+="  ${__p_dim}${took}"
    (( status != 0 )) && ps+="  ${__p_err}✗${status}"
    if (( EUID == 0 )); then ps+=" ${__p_err}#"
    elif (( status != 0 )); then ps+=" ${__p_err}❯"
    else ps+=" ${__p_ok}❯"
    fi
    PS1="${ps}${__p_off} "

    history -a                                               # share history with other terminals right away
}

# Run first (it needs the exit code before anything else changes it); keep what Fedora set (the window title).
if [[ ${PROMPT_COMMAND[*]} != *__p_prompt* ]]; then
    PROMPT_COMMAND=(__p_prompt "${PROMPT_COMMAND[@]}")
fi
