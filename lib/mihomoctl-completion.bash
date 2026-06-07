#!/usr/bin/env bash
# mihomoctl bash completion

_mihomoctl_completions() {
    local cur prev
    _init_completion || return

    local commands="status group node enable disable mode sub restart logs dns"
    local subcommands_group="pick profile"
    local subcommands_node="pick test"
    local subcommands_sub="set update cycle"
    local subcommands_mode="tun proxy"
    local subcommands_dns="set"

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
            fi
            ;;
        node)
            if [[ ${COMP_CWORD} -eq 2 ]]; then
                COMPREPLY=($(compgen -W "$subcommands_node" -- "$cur"))
            elif [[ ${COMP_CWORD} -eq 3 && "${COMP_WORDS[2]}" == "test" ]]; then
                COMPREPLY=($(compgen -W "--all" -- "$cur"))
            fi
            ;;
        mode)
            if [[ ${COMP_CWORD} -eq 2 ]]; then
                COMPREPLY=($(compgen -W "$subcommands_mode" -- "$cur"))
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
        dns)
            if [[ ${COMP_CWORD} -eq 2 ]]; then
                COMPREPLY=($(compgen -W "$subcommands_dns" -- "$cur"))
            fi
            ;;
    esac
}

complete -F _mihomoctl_completions mihomoctl
