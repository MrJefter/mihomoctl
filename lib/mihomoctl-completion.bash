#!/usr/bin/env bash
# mihomoctl bash completion

_mihomoctl_completions() {
    local cur prev
    _init_completion || return

    local commands="status group route proxy mode enable disable sub restart logs"
    local subcommands_group="list show select pin unpin"
    local subcommands_route="status pick"
    local subcommands_proxy="test"
    local values_mode="tun proxy inherit"
    local subcommands_sub="set update cycle"

    # Complete subcommand names
    if [[ ${COMP_CWORD} -eq 1 ]]; then
        COMPREPLY=($(compgen -W "$commands" -- "$cur"))
        return
    fi

    local cmd="${COMP_WORDS[1]}"

    case "$cmd" in
        group)
            if [[ ${COMP_CWORD} -eq 2 ]]; then
                COMPREPLY=($(compgen -W "$subcommands_group" -- "$cur"))
            elif [[ ${COMP_CWORD} -eq 3 && "${COMP_WORDS[2]}" == "list" ]]; then
                COMPREPLY=($(compgen -W "--all" -- "$cur"))
            fi
            ;;
        route)
            if [[ ${COMP_CWORD} -eq 2 ]]; then
                COMPREPLY=($(compgen -W "$subcommands_route" -- "$cur"))
            fi
            ;;
        proxy)
            if [[ ${COMP_CWORD} -eq 2 ]]; then
                COMPREPLY=($(compgen -W "$subcommands_proxy" -- "$cur"))
            elif [[ ${COMP_CWORD} -ge 3 && "${COMP_WORDS[2]}" == "test" ]]; then
                COMPREPLY=($(compgen -W "--all" -- "$cur"))
            fi
            ;;
        mode)
            if [[ ${COMP_CWORD} -eq 2 ]]; then
                COMPREPLY=($(compgen -W "$values_mode" -- "$cur"))
            fi
            ;;
        sub)
            if [[ ${COMP_CWORD} -eq 2 ]]; then
                COMPREPLY=($(compgen -W "$subcommands_sub" -- "$cur"))
            elif [[ ${COMP_CWORD} -eq 3 && "${COMP_WORDS[2]}" == "set" ]]; then
                # Complete URLs (basic http/https)
                COMPREPLY=($(compgen -W "http:// https://" -- "$cur"))
            fi
            ;;
    esac
}

complete -F _mihomoctl_completions mihomoctl
