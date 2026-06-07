#compdef mihomoctl

_mihomoctl() {
    local -a commands
    commands=(
        'status:Show current status'
        'group:Manage proxy groups'
        'node:Manage proxy nodes'
        'enable:Enable and start mihomo'
        'disable:Stop and disable mihomo'
        'mode:Switch between tun and proxy mode'
        'sub:Manage subscription'
        'restart:Restart mihomo'
        'logs:Tail mihomo logs'
        'dns:Configure DNS settings'
    )

    local -a group_commands
    group_commands=(
        'pick:Select default proxy group'
        'profile:Select routing profile'
    )

    local -a node_commands
    node_commands=(
        'pick:Select node in current group'
        'test:Test node latency'
    )

    local -a sub_commands
    sub_commands=(
        'set:Set subscription URL'
        'update:Download and apply subscription'
        'cycle:Set update interval'
    )

    local -a dns_commands
    dns_commands=(
        'set:Configure DNS settings'
    )

    local -a mode_values
    mode_values=(
        'tun:Full system proxy mode'
        'proxy:App-level proxy only'
    )

    _arguments -C \
        '1:command:->commands' \
        '*::arg:->args'

    case $state in
        commands)
            _describe 'command' commands
            ;;
        args)
            case $words[1] in
                group)
                    _describe 'group command' group_commands
                    ;;
                node)
                    _describe 'node command' node_commands
                    if [[ $words[2] == "test" ]]; then
                        _arguments \
                            '--all[Test all nodes in group]'
                    fi
                    ;;
                mode)
                    _describe 'mode value' mode_values
                    ;;
                sub)
                    _describe 'sub command' sub_commands
                    if [[ $words[2] == "set" ]]; then
                        _arguments \
                            '*:subscription URL: '
                    fi
                    ;;
                dns)
                    _describe 'dns command' dns_commands
                    ;;
            esac
            ;;
    esac
}

_mihomoctl "$@"
