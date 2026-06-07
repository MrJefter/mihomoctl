# mihomoctl fish completion

# Disable file completions by default
complete -c mihomoctl -f

# Main commands
complete -c mihomoctl -n "__fish_use_subcommand" -a "status" -d "Show current status"
complete -c mihomoctl -n "__fish_use_subcommand" -a "group" -d "Manage proxy groups"
complete -c mihomoctl -n "__fish_use_subcommand" -a "node" -d "Manage proxy nodes"
complete -c mihomoctl -n "__fish_use_subcommand" -a "enable" -d "Enable and start mihomo"
complete -c mihomoctl -n "__fish_use_subcommand" -a "disable" -d "Stop and disable mihomo"
complete -c mihomoctl -n "__fish_use_subcommand" -a "mode" -d "Switch between tun and proxy mode"
complete -c mihomoctl -n "__fish_use_subcommand" -a "sub" -d "Manage subscription"
complete -c mihomoctl -n "__fish_use_subcommand" -a "restart" -d "Restart mihomo"
complete -c mihomoctl -n "__fish_use_subcommand" -a "logs" -d "Tail mihomo logs"
complete -c mihomoctl -n "__fish_use_subcommand" -a "dns" -d "Configure DNS settings"

# group subcommands
complete -c mihomoctl -n "__fish_seen_subcommand_from group" -a "pick" -d "Select default proxy group"
complete -c mihomoctl -n "__fish_seen_subcommand_from group" -a "profile" -d "Select routing profile"

# node subcommands
complete -c mihomoctl -n "__fish_seen_subcommand_from node" -a "pick" -d "Select node in current group"
complete -c mihomoctl -n "__fish_seen_subcommand_from node" -a "test" -d "Test node latency"
complete -c mihomoctl -n "__fish_seen_subcommand_from test" -l all -d "Test all nodes in group"

# mode values
complete -c mihomoctl -n "__fish_seen_subcommand_from mode" -a "tun" -d "Full system proxy mode"
complete -c mihomoctl -n "__fish_seen_subcommand_from mode" -a "proxy" -d "App-level proxy only"

# sub subcommands
complete -c mihomoctl -n "__fish_seen_subcommand_from sub" -a "set" -d "Set subscription URL"
complete -c mihomoctl -n "__fish_seen_subcommand_from sub" -a "update" -d "Download and apply subscription"
complete -c mihomoctl -n "__fish_seen_subcommand_from sub" -a "cycle" -d "Set update interval"

# dns subcommands
complete -c mihomoctl -n "__fish_seen_subcommand_from dns" -a "set" -d "Configure DNS settings"
