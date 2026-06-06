# mihomoctl

CLI tool for managing Mihomo (Clash.Meta) subscriptions on Linux.

## Features

- Subscription management (set URL, auto-update)
- Proxy group/node selection via interactive picker (fzf)
- Routing profile selection
- TUN/Proxy mode switching
- Systemd integration (enable/disable, daemon, auto-update timer)

## Requirements

- Linux with systemd
- Python 3
- PyYAML (`python3-yaml`)
- fzf (optional, for interactive selection)

## Install

```bash
git clone https://github.com/MrJefter/mihomoctl.git
cd mihomoctl
sudo make install
sudo ./install.sh
```

The `make install` copies files; `install.sh` handles dependencies, mihomo binary download, and optionally downloads the [RoscomVPN routing template](https://github.com/hydraponique/roscomvpn-routing).

## Routing Template

During installation you'll be asked whether to download the RoscomVPN routing template. This provides ready-made proxy groups (VPN, YouTube, Discord, Games, etc.) and rule-sets for Russian/Belarusian routing.

If you decline, set your subscription manually:

```bash
sudo mihomoctl sub set
sudo mihomoctl sub update
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
mihomoctl group pick         # fzf: choose default group
mihomoctl group profile      # fzf: choose routing profile
mihomoctl node pick          # fzf: pick node in current group
mihomoctl enable             # enable and start mihomo
mihomoctl disable            # stop and disable mihomo
mihomoctl status             # show status
mihomoctl mode [tun|proxy]   # get/set mode
mihomoctl sub set [url]      # set subscription URL
mihomoctl sub update         # update subscription
mihomoctl restart            # restart mihomo
mihomoctl logs               # tail service logs
```

## Updating

```bash
cd /path/to/mihomoctl
sudo make update
sudo systemctl restart mihomo.service
```

## Systemd Units

| Unit | Purpose |
|---|---|
| `mihomo.service` | Mihomo daemon |
| `mihomo-update.service` | One-shot subscription update |
| `mihomo-update.timer` | Periodic update (every 6h) |

Enable after install:

```bash
sudo mihomoctl enable
sudo systemctl enable --now mihomo-update.timer  # optional
```

## File Layout After Install

```
/usr/local/bin/mihomoctl
/usr/local/bin/mihomo
/usr/local/sbin/mihomo-update-config
/etc/mihomo/base.yaml          # subscription template (downloaded via sub update or install prompt)
/etc/mihomo/config.yaml        # generated config (do not edit directly)
/etc/systemd/system/mihomo.service
/etc/systemd/system/mihomo-update.service
/etc/systemd/system/mihomo-update.timer
/var/lib/mihomoctl/state.json
```

## License

GPL-3.0
