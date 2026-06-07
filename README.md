# mihomoctl

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

One-liner CLI for Mihomo on Linux. Paste your subscription URL, pick a node, done.

[Русская версия](README.ru.md)

## What is this?

mihomoctl installs and manages [Mihomo](https://wiki.metacubex.one/) (Clash-meta) on any Linux system with systemd. One command installs everything — the binary, the service, the update timer. You paste your subscription URL, fzf picks a node, and you're online.

Works with any Mihomo-compatible subscription (Remnawave, RoscomVPN, or your own provider).

```bash
curl -fsSL https://raw.githubusercontent.com/MrJefter/mihomoctl/master/install.sh | sudo bash
```

## Quick Start

**Install or update (everything in one command):**

```bash
curl -fsSL "https://raw.githubusercontent.com/MrJefter/mihomoctl/master/install.sh?v=$(date +%s)" | sudo bash
```

The installer auto-detects your package manager, installs Python + PyYAML, downloads the latest mihomo binary, copies all files, and asks whether to download the RoscomVPN routing template.

**Set your subscription and start:**

```bash
sudo mihomoctl sub set <your-subscription-url>
sudo mihomoctl sub update
sudo mihomoctl enable
```

**Remove everything:**

```bash
curl -fsSL "https://raw.githubusercontent.com/MrJefter/mihomoctl/master/install.sh?v=$(date +%s)" | sudo bash -s -- --remove
```

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Install](#install)
- [Routing Template](#routing-template)
- [Commands](#commands)
- [Configuration](#configuration)
- [Systemd Units](#systemd-units)
- [File Layout](#file-layout-after-install)
- [Updating](#updating)
- [Uninstall](#uninstall)
- [Troubleshooting](#troubleshooting)
- [See Also](#see-also)
- [License](#license)

## Features

- **One-command install** — auto-detects apt/dnf/pacman, installs everything
- **Subscription management** — set URL, auto-update via timer, update cycle configurable
- **Interactive selection** — fzf-based node/group pickers (numbered fallback if no fzf)
- **DNS editor** — view all DNS fields, override nameservers/fallback, reset to subscription defaults
- **Node ping test** — test individual nodes or all nodes in a group
- **Mode switching** — toggle between TUN (full system proxy) and proxy-only
- **Service control** — enable/disable/restart mihomo from CLI
- **Persistent settings** — DNS overrides survive subscription updates

## Requirements

- Linux with systemd
- Python 3
- PyYAML (`python3-yaml`)
- fzf (optional, for interactive pickers)

## Install

### Full install (recommended)

```bash
git clone https://github.com/MrJefter/mihomoctl.git
cd mihomoctl
sudo make install
sudo ./install.sh
```

The installer will:
1. Detect your package manager and install `python3` + `python3-yaml`
2. Download the latest mihomo binary
3. Copy mihomoctl, systemd units, and helper scripts
4. Ask whether to download the RoscomVPN routing template

### Manual install

If you prefer to handle dependencies yourself:

```bash
sudo make install    # copies files only
sudo mihomoctl sub set
sudo mihomoctl sub update
sudo mihomoctl enable
```

## Routing Template

During installation you'll be asked:

```
Download RoscomVPN routing template? [Y/n]
```

This downloads a ready-made config from [hydraponique/roscomvpn-routing](https://github.com/hydraponique/roscomvpn-routing) with:

- Pre-configured proxy groups (VPN, YouTube, Discord, Games, etc.)
- 40+ rule-sets for Russian/Belarusian routing
- Rule-providers for ad blocking, Windows spyware, torrents
- Direct access for RU/BY services

If you decline, you'll need to set your own subscription URL:

```bash
sudo mihomoctl sub set <your-url>
sudo mihomoctl sub update
```

## Commands

### Node & Group Selection

```bash
mihomoctl node group       # fzf: pick selector group → pick node within it
mihomoctl node pick        # fzf: quick pick node in default group
mihomoctl node test        # ping current node
mihomoctl node test --all  # ping all nodes in default group
```

### Subscription Management

```bash
mihomoctl sub set [url]    # set subscription URL (prompts if no arg)
mihomoctl sub update       # download config, regenerate, restart
mihomoctl sub cycle        # change auto-update interval (1h–24h or custom)
```

### DNS Settings

```bash
mihomoctl dns set          # interactive DNS editor
```

Shows all DNS fields from your subscription (enhanced-mode, nameservers, fallback, default-nameserver, proxy-server-nameserver, etc.). Override any field, or reset to subscription defaults. DNS overrides persist through subscription updates.

### Service Control

```bash
mihomoctl enable           # systemctl enable --now mihomo.service
mihomoctl disable          # systemctl disable --now mihomo.service
mihomoctl restart          # systemctl restart mihomo.service
mihomoctl status           # show service, subscription, routing, network
mihomoctl logs             # tail -f journalctl -u mihomo.service
```

### Mode Switching

```bash
mihomoctl mode             # show current mode
mihomoctl mode tun         # TUN mode (full system proxy)
mihomoctl mode proxy       # proxy mode (app-level only)
```

## Configuration

### How it works

mihomoctl uses a two-file pipeline:

```
base.yaml → (generate_config) → config.yaml
```

- **`base.yaml`** — your subscription template or RoscomVPN config. Downloaded via `sub update` or install prompt. **Do not edit directly.**
- **`config.yaml`** — generated runtime config. Modified by `generate_config()` based on your mode (TUN/proxy). Also **do not edit directly.**

The flow:
1. `sub update` downloads your subscription to `base.yaml`
2. `generate_config()` reads `base.yaml`, applies runtime settings (mode, ports, DNS, TUN), writes `config.yaml`
3. Mihomo reads `config.yaml` on start

### Using your own subscription

If you have a Mihomo/Clash subscription (from any provider):

```bash
sudo mihomoctl sub set https://your-subscription-url
sudo mihomoctl sub update
sudo mihomoctl enable
```

### Using without RoscomVPN

Skip the RoscomVPN template during install, then set your subscription. The tool works with any Mihomo-compatible subscription.

## Systemd Units

| Unit | Purpose |
|---|---|
| `mihomo.service` | Mihomo daemon |
| `mihomo-update.service` | One-shot subscription update (triggered by timer) |
| `mihomo-update.timer` | Periodic update (every 6 hours) |

Enable after install:

```bash
sudo mihomoctl enable
sudo systemctl enable --now mihomo-update.timer  # optional, auto-updates subscription
```

## File Layout After Install

```
/usr/local/bin/mihomoctl              # main CLI
/usr/local/bin/mihomo                 # mihomo binary (downloaded by install.sh)
/usr/local/sbin/mihomo-update-config  # wrapper for sub update
/etc/mihomo/base.yaml                 # subscription template (do not edit)
/etc/mihomo/config.yaml               # generated config (do not edit)
/etc/systemd/system/mihomo.service
/etc/systemd/system/mihomo-update.service
/etc/systemd/system/mihomo-update.timer
/var/lib/mihomoctl/state.json         # saved group/node/mode selection
```

## Updating

```bash
curl -fsSL "https://raw.githubusercontent.com/MrJefter/mihomoctl/master/install.sh?v=$(date +%s)" | sudo bash
```

Or manually:

```bash
cd ~/.local/share/mihomoctl
git pull
sudo make install
sudo mihomoctl restart
```

This pulls the latest code and reinstalls files. Your config and state are preserved.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/MrJefter/mihomoctl/master/install.sh | sudo bash -s -- --remove
```

Or manually:

```bash
sudo make uninstall
sudo rm -rf /etc/mihomo /var/lib/mihomoctl ~/.local/share/mihomoctl
```

## Troubleshooting

### mihomo won't start

Check if the binary exists and config is valid:

```bash
/usr/local/bin/mihomo -t -d /etc/mihomo    # test config
sudo mihomoctl logs                          # check logs
```

### API not responding

Mihomo must be running for most commands to work. Check:

```bash
sudo mihomoctl status
systemctl status mihomo.service
```

If the API shows "down", restart mihomo:

```bash
sudo mihomoctl restart
```

### fzf not found

Install fzf for interactive pickers:

```bash
# Debian/Ubuntu
sudo apt install fzf

# Fedora
sudo dnf install fzf

# Arch
sudo pacman -S fzf
```

Without fzf, commands fall back to numbered lists.

### Permission denied

Most commands require root. Use `sudo`:

```bash
sudo mihomoctl enable
sudo mihomoctl sub update
```

## See Also

[vika2603/mihomoctl](https://github.com/vika2603/mihomoctl) — Go-based CLI for advanced runtime management: live connection monitoring, DNS debugging, proxy-provider health checks, rule inspection, and JSON scripting. Use both: this project to set up, vika2603's to debug.

## License

[GPL-3.0](LICENSE)
