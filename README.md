# mihomoctl

CLI tool for managing Mihomo (Clash.Meta) subscriptions on Linux.

## Features

- Subscription management (set URL, auto-update)
- Proxy group/node selection via CLI
- Interactive node picker (with fzf)
- TUN/Proxy mode switching
- Systemd integration (daemon + auto-update timer)

## Requirements

- Linux with systemd
- Python 3
- PyYAML (`python3-yaml`)

## Install

```bash
git clone https://github.com/user/mihomoctl.git
cd mihomoctl
sudo make install
sudo ./install.sh
```

The `make install` copies files; `install.sh` handles dependencies and mihomo binary download.

## Updating

```bash
cd /path/to/mihomoctl
sudo make update
sudo systemctl restart mihomo.service
```

## Uninstall

```bash
sudo make uninstall
```

Then optionally remove config and state:

```bash
sudo rm -rf /etc/mihomo /var/lib/mihomoctl
```

## Commands

```
mihomoctl status              # show current status
mihomoctl groups              # list proxy groups
mihomoctl nodes [group]       # list nodes in a group
mihomoctl group set <name>    # set default group
mihomoctl use <node> [group]  # select a node
mihomoctl pick [group]        # interactive selection (needs fzf)
mihomoctl apply               # apply saved node
mihomoctl mode [tun|proxy]    # get/set mode
mihomoctl sub set [url]       # set subscription URL
mihomoctl sub update          # update subscription
mihomoctl restart             # restart mihomo service
mihomoctl logs                # tail service logs
```

## Systemd Units

| Unit | Purpose |
|---|---|
| `mihomo.service` | Mihomo daemon |
| `mihomo-update.service` | One-shot subscription update |
| `mihomo-update.timer` | Periodic update (every 6h) |

Enable after install:

```bash
sudo systemctl enable --now mihomo.service
sudo systemctl enable --now mihomo-update.timer  # optional
```

## File Layout After Install

```
/usr/local/bin/mihomoctl
/usr/local/bin/mihomo
/usr/local/sbin/mihomo-update-config
/etc/mihomo/config.yaml
/etc/systemd/system/mihomo.service
/etc/systemd/system/mihomo-update.service
/etc/systemd/system/mihomo-update.timer
/var/lib/mihomoctl/state.json
```

## License

GPL-3.0
