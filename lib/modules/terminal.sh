#!/usr/bin/env bash

# Your terminal app and shell: the font and settings for the terminal you
# chose, then Oh My Zsh, the Starship prompt and friends (or less, or
# nothing). Everything zapz adds to your shell is in one marked block.

ZAPZ_OMZ_REPO="${ZAPZ_OMZ_REPO:-https://github.com/ohmyzsh/ohmyzsh.git}"

setup_terminal_app() {
    local app font
    app=$(config_get '.terminal.app')
    font=$(config_get '.terminal.font' "JetBrainsMono Nerd Font")

    case "$app" in
        "")
            ui_item skipped "Terminal" "none in your config"
            ;;
        ghostty)
            local config="$HOME/.config/ghostty/config"
            mkdir -p "$(dirname "$config")"
            write_managed_block "$config" "terminal" "font-family = \"$font\"
font-size = 14
window-padding-x = 12
window-padding-y = 8
cursor-style = bar"
            ui_item changed "Ghostty" "font and spacing set"
            ;;
        iterm2|warp|terminal)
            local name="iTerm2"
            [[ "$app" == warp ]] && name="Warp"
            [[ "$app" == terminal ]] && name="Terminal"
            ui_item skipped "$name" "set its font yourself (see checklist)"
            add_checklist "In $name, set the font to $font so icons show up"
            ;;
        *)
            ui_item skipped "Terminal" "unknown terminal.app: $app"
            ;;
    esac
}

# The shell lines zapz manages, for zsh
_zsh_block() {
    local setup="$1"
    local prefix='${HOMEBREW_PREFIX:-/opt/homebrew}'
    if [[ "$setup" == recommended ]]; then
        cat << EOF
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME=""   # Starship draws the prompt
plugins=(git)
[ -f "\$ZSH/oh-my-zsh.sh" ] && source "\$ZSH/oh-my-zsh.sh"
[ -f "$prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && source "$prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
command -v fzf >/dev/null && source <(fzf --zsh)
command -v zoxide >/dev/null && eval "\$(zoxide init zsh)"
command -v eza >/dev/null && alias ls="eza --group-directories-first" ll="eza -l --git --group-directories-first"
command -v starship >/dev/null && eval "\$(starship init zsh)"
# Highlighting must load last
[ -f "$prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && source "$prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
EOF
    else
        echo 'command -v starship >/dev/null && eval "$(starship init zsh)"'
    fi
}

_bash_block() {
    local setup="$1"
    if [[ "$setup" == recommended ]]; then
        cat << 'EOF'
command -v fzf >/dev/null && eval "$(fzf --bash)"
command -v zoxide >/dev/null && eval "$(zoxide init bash)"
command -v eza >/dev/null && alias ls="eza --group-directories-first" ll="eza -l --git --group-directories-first"
command -v starship >/dev/null && eval "$(starship init bash)"
EOF
    else
        echo 'command -v starship >/dev/null && eval "$(starship init bash)"'
    fi
}

setup_shell() {
    local setup rc
    setup=$(config_get '.shell.setup' none)
    rc=$(shell_rc_file)

    case "$setup" in
        recommended|light) ;;
        none)
            if remove_managed_block "$rc" "shell"; then
                ui_item changed "Shell" "zapz's shell setup removed"
            else
                ui_item existing "Shell" "left as it is"
            fi
            return 0
            ;;
        *)
            ui_item skipped "Shell" "unknown shell.setup: $setup"
            return 0
            ;;
    esac

    if [[ "${SHELL:-}" == */bash ]]; then
        write_managed_block "$rc" "shell" "$(_bash_block "$setup")"
        ui_item changed "Shell" "$setup setup for bash (Oh My Zsh is zsh-only)"
        return 0
    fi

    if [[ "$setup" == recommended ]]; then
        if [[ -d "$HOME/.oh-my-zsh" ]]; then
            ui_item existing "Oh My Zsh" "already installed"
        else
            run_quiet "Oh My Zsh" git clone --quiet --depth 1 "$ZAPZ_OMZ_REPO" "$HOME/.oh-my-zsh" || true
        fi
    fi
    write_managed_block "$rc" "shell" "$(_zsh_block "$setup")"
    if [[ "$setup" == recommended ]]; then
        ui_item changed "Shell" "suggestions, highlighting, Starship prompt"
    else
        ui_item changed "Shell" "Starship prompt"
    fi
}

setup_terminal_shell() {
    log_header "Terminal & shell"
    setup_terminal_app
    setup_shell
}
