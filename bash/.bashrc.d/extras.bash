# Interactive-shell extras. Sourced from ~/.bashrc; add this at the END of it
# (after starship init):
#
#   for f in ~/.bashrc.d/*.bash; do [ -r "$f" ] && . "$f"; done
#
# Each tool is optional: anything not installed is skipped.

# ---------------------------------------------------------------------------
# History: large, deduplicated, shared between WezTerm panes/tabs
# ---------------------------------------------------------------------------
shopt -s histappend
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups
# Append each command to ~/.bash_history as soon as it runs (bash 5.1+ allows
# PROMPT_COMMAND to be an array, which is what starship uses)
if (( BASH_VERSINFO[0] > 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] >= 1) )); then
  PROMPT_COMMAND=("history -a" "${PROMPT_COMMAND[@]}")
fi

# ---------------------------------------------------------------------------
# fzf: Ctrl-R history, Ctrl-T files, Alt-C cd (works in vi mode too)
# Colors: Catppuccin Mocha (catppuccin/fzf) without bg, so the terminal's
# own background and opacity show through
# ---------------------------------------------------------------------------
if command -v fzf >/dev/null; then
  export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,spinner:#F5E0DC,hl:#F38BA8 \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#6C7086,label:#CDD6F4"

  # fd is installed as fdfind on Ubuntu
  if command -v fdfind >/dev/null; then
    export FZF_DEFAULT_COMMAND="fdfind --type f --hidden --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="fdfind --type d --hidden --exclude .git"
  fi

  # fzf >= 0.48 prints its own setup; older Ubuntu packages ship the script
  if _fzf_init=$(fzf --bash 2>/dev/null); then
    eval "$_fzf_init"
  elif [ -r /usr/share/doc/fzf/examples/key-bindings.bash ]; then
    . /usr/share/doc/fzf/examples/key-bindings.bash
  fi
  unset _fzf_init
fi

# ---------------------------------------------------------------------------
# zoxide: "z foo" jumps to the most used directory matching foo, "zi" picks
# ---------------------------------------------------------------------------
if command -v zoxide >/dev/null; then
  eval "$(zoxide init bash)"
fi

# ---------------------------------------------------------------------------
# LS_COLORS in Catppuccin Mocha (ls, tab completion via colored-stats)
# ---------------------------------------------------------------------------
if command -v vivid >/dev/null; then
  export LS_COLORS="$(vivid generate catppuccin-mocha)"
fi

# ---------------------------------------------------------------------------
# Man pages highlighted by bat (Catppuccin Mocha via ~/.config/bat/config)
# ---------------------------------------------------------------------------
if command -v batcat >/dev/null; then
  export MANPAGER="sh -c 'col -bx | batcat -l man -p'"
  export MANROFFOPT="-c"
fi
