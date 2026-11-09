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
            # font-family = "" clears earlier fonts, so this one is primary
            # rather than a fallback
            write_managed_block "$config" "terminal" "font-family = \"\"
font-family = \"$font\"
font-size = 14
window-padding-x = 12
window-padding-y = 8
cursor-style = bar"
            if [[ "$ZAPZ_BLOCK_CHANGED" == true ]]; then
                ui_item changed "Ghostty" "font and spacing set"
            else
                ui_item existing "Ghostty" "font and spacing already set"
            fi
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

# The shell lines zapz manages, for zsh. Oh My Zsh is left out when the
# user's own .zshrc already loads it, so it doesn't load twice.
_zsh_block() {
    local setup="$1" with_omz="${2:-true}"
    local prefix='${HOMEBREW_PREFIX:-/opt/homebrew}'
    if [[ "$setup" != recommended ]]; then
        echo 'command -v starship >/dev/null && eval "$(starship init zsh)"'
        return 0
    fi
    if [[ "$with_omz" == true ]]; then
        printf '%s\n' \
            'export ZSH="$HOME/.oh-my-zsh"' \
            'ZSH_THEME=""   # Starship draws the prompt' \
            'plugins=(git)' \
            '[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"'
    fi
    printf '%s\n' \
        "[ -f \"$prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh\" ] && source \"$prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh\"" \
        'command -v fzf >/dev/null && source <(fzf --zsh)' \
        'command -v zoxide >/dev/null && eval "$(zoxide init zsh)"' \
        'command -v eza >/dev/null && alias ls="eza --group-directories-first" ll="eza -l --git --group-directories-first"' \
        'command -v starship >/dev/null && eval "$(starship init zsh)"' \
        '# Highlighting must load last' \
        "[ -f \"$prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh\" ] && source \"$prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh\""
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
        if [[ "$ZAPZ_BLOCK_CHANGED" == true ]]; then
            ui_item changed "Shell" "$setup setup for bash (Oh My Zsh is zsh-only)"
        else
            ui_item existing "Shell" "$setup setup for bash"
        fi
        return 0
    fi

    local with_omz=true
    if [[ "$setup" == recommended ]]; then
        if file_has_outside_blocks "$rc" "oh-my-zsh.sh"; then
            # Their own Oh My Zsh setup stays in charge
            with_omz=false
            ui_item existing "Oh My Zsh" "already set up in your .zshrc"
        elif [[ -d "$HOME/.oh-my-zsh" ]]; then
            ui_item existing "Oh My Zsh" "already installed"
        else
            run_quiet "Oh My Zsh" git clone --quiet --depth 1 "$ZAPZ_OMZ_REPO" "$HOME/.oh-my-zsh" || true
        fi
    fi
    write_managed_block "$rc" "shell" "$(_zsh_block "$setup" "$with_omz")"
    local described="Starship prompt"
    [[ "$setup" == light ]] || described="suggestions, highlighting, Starship prompt"
    if [[ "$ZAPZ_BLOCK_CHANGED" == true ]]; then
        ui_item changed "Shell" "$described"
    else
        ui_item existing "Shell" "$described"
    fi
}

setup_terminal_shell() {
    log_header "Terminal & shell"
    setup_terminal_app
    setup_shell
}
