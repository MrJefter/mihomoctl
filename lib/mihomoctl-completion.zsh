#compdef mihomoctl

_mihomoctl() {
    local -a commands
    commands=(
        'status:Show current status'
        'group:Inspect and control native policy groups'
        'route:Inspect or pick a resolved routing path'
        'proxy:Operate on individual proxies'
        'mode:Show or override host traffic capture mode'
        'enable:Enable and start mihomo'
        'disable:Stop and disable mihomo'
        'sub:Manage subscription'
        'restart:Restart mihomo'
        'logs:Tail mihomo logs'
    )

    local -a group_commands
    group_commands=(
        'list:List native policy groups'
        'show:Show one group and its immediate members'
        'select:Select an immediate member of a Selector'
        'pin:Pin a URLTest or Fallback group to one member'
        'unpin:Return a URLTest or Fallback group to automatic mode'
    )

    local -a route_commands
    route_commands=(
        'status:Show active route resolutions'
        'pick:Interactively select a nested route'
    )

    local -a proxy_commands
    proxy_commands=(
        'test:Test proxy latency'
    )

    local -a mode_values
    mode_values=(
        'tun:Enable TUN capture'
        'proxy:Disable TUN capture and use configured proxy ports'
        'inherit:Remove the override and inherit tun.enable from the subscription'
    )

    local -a sub_commands
    sub_commands=(
        'set:Set subscription URL'
        'update:Download and apply subscription'
        'cycle:Set update interval'
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
                    if [[ $words[2] == "list" ]]; then
                        _arguments \
                            '--all[Include hidden groups]'
                    fi
                    ;;
                route)
                    _describe 'route command' route_commands
                    ;;
                proxy)
                    _describe 'proxy command' proxy_commands
                    if [[ $words[2] == "test" ]]; then
                        _arguments \
                            '--all[Test all leaf proxies under group targets]' \
                            '*:proxy or group: '
                    fi
                    ;;
                mode)
                    _describe 'capture mode' mode_values
                    ;;
                sub)
                    _describe 'sub command' sub_commands
                    if [[ $words[2] == "set" ]]; then
                        _arguments \
                            '*:subscription URL: '
                    fi
                    ;;
            esac
            ;;
    esac
}

_mihomoctl "$@"
