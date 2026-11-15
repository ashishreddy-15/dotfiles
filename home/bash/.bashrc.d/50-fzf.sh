# fzf, zoxide and bat (packages/shell.txt):
#   Ctrl + R        search the history                Ctrl + T    pick files (with a preview) into the command line
#   Alt + C         go into a folder below this one   ** + Tab    fuzzy completion, e.g. `nvim **<Tab>`
#   z <part>        jump to a folder you use often    zi          pick one of them with fzf
# Kept fast: fzf's key bindings come from the file the package ships (no `eval "$(fzf --bash)"`, which would start a
# program in every new shell), and zoxide's setup is cached to a file. zoxide runs only when you change folder.
[[ $- == *i* ]] || return 0

if command -v fzf >/dev/null; then
    # Lists come from fd (fast, skips .git and what .gitignore hides; shows hidden files).
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
    export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
    export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'

    # Looks: the terminal's own palette (-1 = its default colours, 0-15 = its slots), so fzf follows kitty's light/dark
    # switch. Accent 4, ok 2, quiet parts 8. There is no slot "slightly off the background" in both themes, so the
    # current line is shown by the ▌ pointer and bold text instead of a tinted background.
    export FZF_DEFAULT_OPTS="--height=45% --layout=reverse --border=rounded --info=inline-right \
--prompt='❯ ' --pointer='▌' --marker='●' --scrollbar='│' \
--color=bg:-1,bg+:-1,fg:-1,fg+:-1:bold,hl:4,hl+:4:bold \
--color=border:8,prompt:4,pointer:4,marker:2,info:8,spinner:8 \
--color=header:8,gutter:-1,separator:8,scrollbar:8,label:8,query:-1"

    # Previews: files with bat (plain cat if bat is missing), folders as a listing.
    if command -v bat >/dev/null; then
        export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:300 {}'"
    else
        export FZF_CTRL_T_OPTS="--preview 'head -300 {}'"
    fi
    export FZF_ALT_C_OPTS="--preview 'ls -A --color=always --group-directories-first {} | head -100'"

    [[ -f /usr/share/fzf/shell/key-bindings.bash ]] && source /usr/share/fzf/shell/key-bindings.bash
fi

if command -v bat >/dev/null; then
    export BAT_THEME=ansi          # bat uses the terminal's own colours (kitty: the palette)
fi

if command -v zoxide >/dev/null; then
    # zoxide's setup without its prompt hook (`--hook none`): its hook would start a subshell at every prompt.
    # The prompt (30-prompt.sh) calls __p_on_cd instead, only when the folder has actually changed.
    # The setup only changes when zoxide is updated: cache it, and make it again when the program is newer.
    __zoxide_cache=${XDG_CACHE_HOME:-$HOME/.cache}/zoxide-init-nohook.bash
    # ${ ...; } runs in this shell (bash 5.3): no subshell is started to find the program.
    if [[ ! -s $__zoxide_cache || $__zoxide_cache -ot ${ type -P zoxide; } ]]; then
        mkdir -p "${__zoxide_cache%/*}" && zoxide init bash --hook none > "$__zoxide_cache"
    fi
    source "$__zoxide_cache"
    unset __zoxide_cache
    # Recorded in the background (in a subshell, so bash prints no job number): the prompt does not wait for it.
    __p_on_cd() { ( command zoxide add -- "$PWD" & ) 2>/dev/null; }
fi
