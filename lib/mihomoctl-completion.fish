# mihomoctl fish completion

# Disable file completions by default
complete -c mihomoctl -f

# Main commands
complete -c mihomoctl -n "__fish_use_subcommand" -a "status" -d "Show current status"
complete -c mihomoctl -n "__fish_use_subcommand" -a "group" -d "Inspect and control native policy groups"
complete -c mihomoctl -n "__fish_use_subcommand" -a "route" -d "Inspect or pick a resolved routing path"
complete -c mihomoctl -n "__fish_use_subcommand" -a "proxy" -d "Operate on individual proxies"
complete -c mihomoctl -n "__fish_use_subcommand" -a "mode" -d "Show or override host traffic capture mode"
complete -c mihomoctl -n "__fish_use_subcommand" -a "enable" -d "Enable and start mihomo"
complete -c mihomoctl -n "__fish_use_subcommand" -a "disable" -d "Stop and disable mihomo"
complete -c mihomoctl -n "__fish_use_subcommand" -a "sub" -d "Manage subscription"
complete -c mihomoctl -n "__fish_use_subcommand" -a "restart" -d "Restart mihomo"
complete -c mihomoctl -n "__fish_use_subcommand" -a "logs" -d "Tail mihomo logs"

# Native group, route, and proxy subcommands
complete -c mihomoctl -n "__fish_seen_subcommand_from group; and not __fish_seen_subcommand_from list show select pin unpin" -a "list show select pin unpin"
complete -c mihomoctl -n "__fish_seen_subcommand_from group; and __fish_seen_subcommand_from list" -l all -d "Include hidden groups"
complete -c mihomoctl -n "__fish_seen_subcommand_from route; and not __fish_seen_subcommand_from status pick" -a "status pick"
complete -c mihomoctl -n "__fish_seen_subcommand_from proxy; and not __fish_seen_subcommand_from test" -a "test" -d "Test proxy latency"
complete -c mihomoctl -n "__fish_seen_subcommand_from proxy; and __fish_seen_subcommand_from test" -l all -d "Test all leaf proxies under group targets"

# Host capture mode values
complete -c mihomoctl -n "__fish_seen_subcommand_from mode" -a "tun" -d "Enable TUN capture"
complete -c mihomoctl -n "__fish_seen_subcommand_from mode" -a "proxy" -d "Disable TUN capture and use configured proxy ports"
complete -c mihomoctl -n "__fish_seen_subcommand_from mode" -a "inherit" -d "Inherit tun.enable from the subscription"

# sub subcommands
complete -c mihomoctl -n "__fish_seen_subcommand_from sub" -a "set" -d "Set subscription URL"
complete -c mihomoctl -n "__fish_seen_subcommand_from sub" -a "update" -d "Download and apply subscription"
complete -c mihomoctl -n "__fish_seen_subcommand_from sub" -a "cycle" -d "Set update interval"
