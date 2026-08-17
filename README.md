# mihomoctl

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

One-liner CLI for Mihomo on Linux. Paste your subscription URL, pick your routes and nodes, done.

[Русская версия](README.ru.md)

## What is this?

mihomoctl installs and manages [Mihomo](https://wiki.metacubex.one/) (Clash-meta) on any Linux system with systemd. One command installs everything — the binary, the service, shell completions, and the update timer.

Works with any Mihomo-compatible subscription (Remnawave, RoscomVPN, or your own provider).

```bash
curl -fsSL https://cdn.jsdelivr.net/gh/Jefter5549/mihomoctl@master/install.sh | sudo bash
```

## Quick Start

**Install or update (everything in one command):**

```bash
curl -fsSL https://cdn.jsdelivr.net/gh/Jefter5549/mihomoctl@master/install.sh | sudo bash
```

*(Alternative raw GitHub link)*:
```bash
curl -fsSL "https://raw.githubusercontent.com/Jefter5549/mihomoctl/master/install.sh?v=$(date +%s)" | sudo bash
```

The installer auto-detects your package manager (apt on Debian/Ubuntu, dnf on Fedora, pacman on Arch, zypper, apk), installs dependencies (`python3`, `python3-yaml`, `curl`, `gzip`), downloads the latest mihomo binary, installs shell completions and systemd services, and asks whether to download the RoscomVPN routing template.

**Set your subscription and start:**

```bash
sudo mihomoctl sub set <your-subscription-url>
sudo mihomoctl sub update
sudo mihomoctl enable
```

**Remove everything:**

```bash
curl -fsSL https://cdn.jsdelivr.net/gh/Jefter5549/mihomoctl@master/install.sh | sudo bash -s -- --remove
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
- [See Also](#see-also)
- [License](#license)

## Features

- **One-command install** — auto-detects apt/dnf/pacman/zypper/apk, installs dependencies and binary
- **Subscription management** — set URL, auto-update via systemd timer, configurable update cycles
- **Interactive routing & node picker** — fzf-based route selection (numbered fallback if no fzf)
- **Policy group control** — list, inspect, select members, pin/unpin URLTest & Fallback groups
- **Proxy latency testing** — test individual targets or all leaf proxies
- **Mode switching** — toggle between TUN capture, proxy-only ports, or inherit from subscription
- **Runtime rule overrides** — inspect, dynamically add, or clear runtime rules
- **Shell completions** — automatic bash, zsh, and fish completions

## Requirements

- Linux with systemd (Debian 12/13, Ubuntu, Fedora, Arch Linux, etc.)
- Python >= 3.10
- PyYAML (`python3-yaml`)
- fzf (optional, for interactive pickers)

## Install

### Full install (recommended)

```bash
git clone https://github.com/Jefter5549/mihomoctl.git
cd mihomoctl
sudo make install
sudo ./install.sh
```

### Manual install

If you prefer to handle dependencies yourself:

```bash
sudo make install    # copies binaries, completions, and services
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
- 40+ rule-sets for routing
- Rule-providers for ad blocking, spyware, torrents
- Direct access for local services

If you decline, configure your own subscription URL with `sudo mihomoctl sub set`.

## Commands

### Status & Control

```bash
mihomoctl status           # show service, subscription, mode, and traffic summary
sudo mihomoctl enable      # enable and start mihomo service
sudo mihomoctl disable     # stop and disable mihomo service
sudo mihomoctl restart     # restart mihomo service
mihomoctl logs             # tail mihomo logs (journalctl)
```

### Route & Group Management

```bash
mihomoctl group list [--all]               # list policy groups
mihomoctl group show <group>               # inspect group and its members
mihomoctl group select <group> <member>    # select member for selector group
mihomoctl group pin <group> <member>       # pin URLTest/Fallback group to specific member
mihomoctl group unpin <group>              # return group to automatic health-check mode
mihomoctl route status [roots...]          # display active route resolution paths
mihomoctl route pick [root]                # interactive nested route picker (fzf)
```

### Proxy Testing

```bash
mihomoctl proxy test <target>              # test latency for specific proxy
mihomoctl proxy test <group> --all         # test all leaf proxies under a group
```

### Capture Mode

```bash
mihomoctl mode                             # show current traffic capture mode
sudo mihomoctl mode tun                    # enable TUN full-system capture
sudo mihomoctl mode proxy                  # disable TUN (mixed-port proxy only)
sudo mihomoctl mode inherit                # inherit tun setting from subscription
```

### Subscription

```bash
sudo mihomoctl sub set [url]               # set subscription URL (prompts if omitted)
sudo mihomoctl sub update                  # download, generate config, and apply
sudo mihomoctl sub cycle                   # configure update timer interval
```

### Dynamic Rules

```bash
mihomoctl rules list                       # list active routing rules
sudo mihomoctl rules add <rule...>         # prepend runtime rules (e.g. 'DOMAIN-SUFFIX,example.com,DIRECT')
sudo mihomoctl rules clear                 # clear runtime rule overrides
```

## Systemd Units

| Unit | Purpose |
|---|---|
| `mihomo.service` | Mihomo daemon |
| `mihomo-update.service` | One-shot subscription update (triggered by timer) |
| `mihomo-update.timer` | Periodic update timer |

## File Layout After Install

```
/usr/local/bin/mihomoctl                            # main CLI tool
/usr/local/bin/mihomo                               # mihomo binary
/usr/local/sbin/mihomo-update-config                # update trigger script
/etc/bash_completion.d/mihomoctl                    # bash completions
/usr/share/zsh/site-functions/_mihomoctl            # zsh completions
/usr/share/fish/vendor_completions.d/mihomoctl.fish # fish completions
/etc/mihomo/base.yaml                               # subscription / base config
/etc/mihomo/config.yaml                             # generated runtime config
/etc/systemd/system/mihomo.service
/etc/systemd/system/mihomo-update.service
/etc/systemd/system/mihomo-update.timer
/var/lib/mihomoctl/state.json                       # persistent settings and overrides
```

## Updating

```bash
curl -fsSL "https://raw.githubusercontent.com/Jefter5549/mihomoctl/master/install.sh?v=$(date +%s)" | sudo bash
```

## Uninstall

```bash
curl -fsSL "https://raw.githubusercontent.com/Jefter5549/mihomoctl/master/install.sh?v=$(date +%s)" | sudo bash -s -- --remove
```

## See Also

- [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo) — official Mihomo core
- [hydraponique/roscomvpn-routing](https://github.com/hydraponique/roscomvpn-routing) — Russian routing rules and templates

## License

GPL-3.0
