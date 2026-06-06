# mihomoctl

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

CLI tool for managing Mihomo (Clash.Meta) subscriptions on Linux. No Electron, no bloat — just a terminal and your mouse-free workflow.

[Русская версия](README.ru.md)

## What is this?

mihomoctl lets you control a Mihomo proxy daemon entirely from the command line. Switch nodes, change routing profiles, toggle between TUN and proxy mode, manage subscriptions — all without touching a GUI.

Built for Linux systems with systemd (Ubuntu, Fedora, Arch, Debian, etc.).

## Quick Start

```bash
git clone https://github.com/MrJefter/mihomoctl.git
cd mihomoctl
sudo make install
sudo ./install.sh          # installs deps, mihomo, optionally RoscomVPN template
sudo mihomoctl enable      # start mihomo
sudo mihomoctl group pick  # choose your proxy group
sudo mihomoctl node pick   # choose a node
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
- [License](#license)

## Features

- **Subscription management** — set URL, auto-update via timer
- **Interactive selection** — fzf-based node/group/profile pickers (numbered fallback if no fzf)
- **Routing profiles** — switch which group handles traffic for YouTube, Discord, games, etc.
- **Mode switching** — toggle between TUN (full system proxy) and proxy-only mode
- **Service control** — enable/disable mihomo directly from CLI
- **Distro-universal** — works on any systemd-based Linux (apt/dnf/pacman auto-detected)
- **Auto-install** — downloads mihomo binary, installs dependencies, no manual steps

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

### Group & Node Selection

```bash
mihomoctl group pick       # fzf: choose your default proxy group
mihomoctl group profile    # fzf: choose a routing profile (YouTube, Discord, Games...)
mihomoctl node pick        # fzf: pick a node in the current default group
```

**Workflow:** `group pick` sets which group you're working with → `node pick` selects the actual server within that group → `group profile` configures routing for specific services.

### Service Control

```bash
mihomoctl enable           # systemctl enable --now mihomo.service
mihomoctl disable          # systemctl disable --now mihomo.service
mihomoctl restart          # systemctl restart mihomo.service
mihomoctl status           # show mode, group, node, API status, service state
mihomoctl logs             # tail -f journalctl -u mihomo.service
```

### Subscription Management

```bash
mihomoctl sub set [url]    # set subscription URL (prompts if no arg)
mihomoctl sub update       # download config from URL, regenerate, restart
```

### Mode Switching

```bash
mihomoctl mode             # show current mode
mihomoctl mode tun         # switch to TUN mode (full system proxy)
mihomoctl mode proxy       # switch to proxy mode (app-level only)
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
cd /path/to/mihomoctl
sudo make update
sudo mihomoctl restart
```

This pulls the latest code and reinstalls files. Your config and state are preserved.

## Uninstall

```bash
sudo make uninstall
```

Then optionally remove config and state:

```bash
sudo rm -rf /etc/mihomo /var/lib/mihomoctl
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

## License

[GPL-3.0](LICENSE)
