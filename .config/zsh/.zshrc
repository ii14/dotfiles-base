# PROMPT /////////////////////////////////////////////////////////////////////////////////
autoload -U colors && colors

# Git prompt -----------------------------------------------------------------------------
if [[ -d ~/.config/zsh/plugins/git-prompt.zsh ]]; then
    source ~/.config/zsh/plugins/git-prompt.zsh/git-prompt.zsh
    ZSH_GIT_PROMPT_SHOW_UPSTREAM="no"
    ZSH_THEME_GIT_PROMPT_PREFIX="%K{233}"
    ZSH_THEME_GIT_PROMPT_SUFFIX="%K{233} "
    ZSH_THEME_GIT_PROMPT_SEPARATOR="%K{233} "
    ZSH_THEME_GIT_PROMPT_DETACHED="%K{233}%{$fg[cyan]%}:"
    ZSH_THEME_GIT_PROMPT_BRANCH="%K{233}%{$fg[yellow]%}"
    ZSH_THEME_GIT_PROMPT_UPSTREAM_SYMBOL="%K{233}%{$fg[yellow]%}⟳ "
    ZSH_THEME_GIT_PROMPT_UPSTREAM_PREFIX="%K{233}%{$fg[red]%}(%{$fg[yellow]%}"
    ZSH_THEME_GIT_PROMPT_UPSTREAM_SUFFIX="%K{233}%{$fg[red]%})"
    ZSH_THEME_GIT_PROMPT_BEHIND="%K{233}↓"
    ZSH_THEME_GIT_PROMPT_AHEAD="%K{233}↑"
    ZSH_THEME_GIT_PROMPT_UNMERGED="%K{233}%{$fg[red]%}x"
    ZSH_THEME_GIT_PROMPT_STAGED="%K{233}%{$fg[green]%}●"
    ZSH_THEME_GIT_PROMPT_UNSTAGED="%K{233}%{$fg[red]%}+"
    ZSH_THEME_GIT_PROMPT_UNTRACKED="%K{233}…"
    ZSH_THEME_GIT_PROMPT_STASHED="%K{233}%{$fg[blue]%}⚑"
    ZSH_THEME_GIT_PROMPT_CLEAN="%K{233}%{$fg[green]%}✔"
    _zsh_gitprompt_loaded=0
fi

# Vim mode indicator ---------------------------------------------------------------------
_zsh_vim_ins_mode=2 # main mode color: green
_zsh_vim_cmd_mode=4 # vim mode color: blue
_zsh_vim_mode=$_zsh_vim_ins_mode

function zle-keymap-select {
    _zsh_vim_mode="${${KEYMAP/vicmd/${_zsh_vim_cmd_mode}}/(main|viins)/${_zsh_vim_ins_mode}}"
    zle reset-prompt
}
zle -N zle-keymap-select

function zle-line-finish {
    _zsh_vim_mode=$_zsh_vim_ins_mode
}
zle -N zle-line-finish

function TRAPINT() {
    _zsh_vim_mode=$_zsh_vim_ins_mode
    return $(( 128 + $1 ))
}

# Prompt ---------------------------------------------------------------------------------
if [[ "$TERM" == 'linux' ]]; then
    # no fancy prompt on linux tty
    PROMPT='%n@%m:%~$ '
else
    PROMPT='%K{233}%f '

    # print user@host if logged in through ssh
    if [[ -v SSH_CONNECTION ]]; then
        PROMPT+='%b%n@%m%B '
    fi

    # print directory
    PROMPT+='%B%(4~|%-1~/…/%2~|%3~)%b '

    # print git branch
    if [[ -v _zsh_gitprompt_loaded ]]; then
        PROMPT+='$(gitprompt)'
    fi

    # print emacs/vim mode indicator
    PROMPT+='%F{233}%K{${_zsh_vim_mode}}%k%F{${_zsh_vim_mode}}%f '

    # set terminal window title
    _set_title() {
        (echo -ne "\033]0;$(dirs -p | head -n 1) - zsh\007") 2>/dev/null
    }
    precmd_functions+=(_set_title)
fi

# INCLUDES ///////////////////////////////////////////////////////////////////////////////
[ -f "$HOME/.config/aliasrc" ] && source "$HOME/.config/aliasrc"
[ -f "$HOME/.local/share/shortcuts" ] && source "$HOME/.local/share/shortcuts"


# OPTIONS ////////////////////////////////////////////////////////////////////////////////
setopt menu_complete            # insert first match of the completion
setopt list_packed              # fit more completions on the screen
setopt auto_cd                  # change directory by writing the directory name
setopt notify                   # report job status immediately
setopt no_flow_control          # disable flow control - Ctrl+S and Ctrl+Q keys
setopt interactive_comments     # allow comments

# History --------------------------------------------------------------------------------
setopt append_history
setopt share_history            # share history between sessions
setopt hist_ignore_all_dups     # remove duplicate commands from history
setopt hist_ignore_space        # don't add commands with leading space to history
SAVEHIST=10000
HISTSIZE=10000
HISTFILE=~/.cache/zsh/history

# Directory stack ------------------------------------------------------------------------
setopt auto_pushd               # automatically push previous directory to the stack
setopt pushd_minus              # swap + and -
setopt pushd_silent             # silend pushd and popd
setopt pushd_to_home            # pushd defaults to $HOME
DIRSTACKSIZE=12
alias dh='dirs -v'


# KEY BINDINGS ///////////////////////////////////////////////////////////////////////////
export KEYTIMEOUT=1

# Emacs key bindings with Vim normal mode ------------------------------------------ [Esc]
bindkey -e
bindkey '\e' vi-cmd-mode

# Filter history ------------------------------------------------------------- [Up] [Down]
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A'  up-line-or-beginning-search
bindkey '^[OA'  up-line-or-beginning-search
bindkey '^p'    up-line-or-beginning-search
bindkey '^[[B'  down-line-or-beginning-search
bindkey '^[OB'  down-line-or-beginning-search
bindkey '^n'    down-line-or-beginning-search

# Backward delete word ---------------------------------------------------------- [Ctrl-W]
my-backward-delete-word() {
    local WORDCHARS=${WORDCHARS/\//}
    zle backward-delete-word
}
zle -N my-backward-delete-word
bindkey '^w' my-backward-delete-word

# Search backward for string ---------------------------------------------------- [Ctrl-R]
bindkey '^r' history-incremental-search-backward

# Jump between words ---------------------------------------------- [Alt-Left] [Alt-Right]
bindkey '\e[1;3C' forward-word
bindkey '\e[1;3D' backward-word

# Completion menu backwards -------------------------------------------------- [Shift-Tab]
[[ "${terminfo[kcbt]}" != "" ]] && bindkey "${terminfo[kcbt]}" reverse-menu-complete

# Go to beginning or end of line -------------------------------------------- [Home] [End]
[[ "${terminfo[khome]}" != "" ]] && bindkey "${terminfo[khome]}" beginning-of-line
[[ "${terminfo[kend]}" != "" ]] && bindkey "${terminfo[kend]}" end-of-line

# One directory up --------------------------------------------------------------- [Alt-U]
bindkey -s '\eu' 'cd ..^M'

# Edit command line -------------------------------------------------------------- [Alt-E]
autoload -U edit-command-line
zle -N edit-command-line
bindkey '\ee' edit-command-line

# Completion menu vim movement ------------------------------------------ [Ctrl-{h,j,k,l}]
zmodload zsh/complist
bindkey -M menuselect '^k' up-line-or-history
bindkey -M menuselect '^p' up-line-or-history
bindkey -M menuselect '^j' down-line-or-history
bindkey -M menuselect '^n' down-line-or-history
bindkey -M menuselect '^l' forward-char
bindkey -M menuselect '^h' backward-char

bindkey -M menuselect '^y' accept-search
bindkey -M menuselect '^e' send-break
bindkey -M menuselect '\e' send-break
bindkey -M menuselect '^r' history-incremental-search-forward

# Swtich between background and foreground -------------------------------------- [Ctrl-Z]
function fg-bg() {
    if [[ $#BUFFER -eq 0 ]]; then
        fg
    else
        zle push-input
    fi
}
zle -N fg-bg
bindkey '^z' fg-bg

# Expand "!" with space
bindkey ' ' magic-space


# COMPLETION /////////////////////////////////////////////////////////////////////////////
fpath=(~/.config/zsh/completions $fpath)

autoload -Uz compinit
compinit -d ~/.cache/zsh/zcompdump

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
# zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# ignored
zstyle ':completion:*:(all-|)files' ignored-patterns '(|*/).pyc'

zstyle ':completion:*' menu select


# SYNTAX HIGHLIGHTING ////////////////////////////////////////////////////////////////////
if [[ -d ~/.config/zsh/plugins/zsh-syntax-highlighting ]]; then
    typeset -A ZSH_HIGHLIGHT_STYLES
    ZSH_HIGHLIGHT_STYLES[comment]='fg=black'
    source ~/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi


# AUTOSUGGESTIONS ////////////////////////////////////////////////////////////////////////
if [[ -d ~/.config/zsh/plugins/zsh-autosuggestions ]]; then
    ZSH_AUTOSUGGEST_USE_ASYNC=1
    source ~/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    bindkey '^ ' autosuggest-accept
fi


# FZF ////////////////////////////////////////////////////////////////////////////////////
export FZF_DEFAULT_OPTS='--bind=ctrl-a:select-all,ctrl-u:page-up,ctrl-d:page-down,ctrl-space:toggle'

if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude ".git"'
    export FZF_CTRL_T_COMMAND='fd --type f --type d --hidden --exclude ".git"'
    export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude ".git"'
    _fzf_compgen_path() { fd --hidden --exclude ".git" . "$@"; }
    _fzf_compgen_dir() { fd --type d --hidden --exclude ".git" . "$@"; }
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

bindkey '^f' fzf-cd-widget


# SAFER RM ///////////////////////////////////////////////////////////////////////////////
setopt rmstarsilent
function rm {
    printf 'Continue?: rm'
    for i in "$@"; do printf " $i"; done
    read -rsk r; echo
    if [[ $r != $'\n' && $r != 'y' && $r != 'Y' ]]; then
        echo 'Operation cancelled.'
        return
    fi
    command rm -v $@
}

alias t='trash -v'


# DIRECTORY HASHES ///////////////////////////////////////////////////////////////////////
hash -d trash="$HOME/.local/share/Trash"
hash -d dls="$(xdg-user-dir DOWNLOAD)"
hash -d pic="$(xdg-user-dir PICTURES)"
hash -d vid="$(xdg-user-dir VIDEOS)"

function hashcwd {
    hash -d "$1"="$PWD"
}
