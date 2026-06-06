#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[-]${NC} $*"; exit 1; }

if [[ $EUID -ne 0 ]]; then
    error "Run with sudo: sudo ./install.sh"
fi

PREFIX="${PREFIX:-/usr/local}"
BINDIR="${BINDIR:-$PREFIX/bin}"
SBINDIR="${SBINDIR:-$PREFIX/sbin}"
SYSCONFDIR="${SYSCONFDIR:-/etc}"
UNITDIR="${UNITDIR:-/etc/systemd/system}"

# --- detect package manager ---
detect_pkg_manager() {
    if command -v apt-get &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

install_deps() {
    local pm
    pm="$(detect_pkg_manager)"
    info "Detected package manager: $pm"

    if ! command -v python3 &>/dev/null; then
        warn "python3 not found, installing..."
        case "$pm" in
            apt)    apt-get update -qq && apt-get install -y -qq python3 ;;
            dnf)    dnf install -y -q python3 ;;
            pacman) pacman -S --noconfirm python ;;
            *)      error "Cannot install python3 automatically. Install it manually." ;;
        esac
    fi

    if ! python3 -c "import yaml" 2>/dev/null; then
        warn "PyYAML not found, installing..."
        case "$pm" in
            apt)    apt-get update -qq && apt-get install -y -qq python3-yaml ;;
            dnf)    dnf install -y -q python3-pyyaml ;;
            pacman) pacman -S --noconfirm python-yaml ;;
            *)      error "Cannot install python3-yaml automatically. Install it manually." ;;
        esac
    fi
}

install_mihomo() {
    if command -v mihomo &>/dev/null; then
        info "mihomo already installed: $(command -v mihomo)"
        return
    fi

    if [[ -x "$BINDIR/mihomo" ]]; then
        info "mihomo already at $BINDIR/mihomo"
        return
    fi

    info "Downloading mihomo..."
    local arch
    arch="$(uname -m)"
    case "$arch" in
        x86_64)  arch="amd64" ;;
        aarch64) arch="arm64" ;;
        armv7l)  arch="armv7" ;;
        *)       error "Unsupported architecture: $arch" ;;
    esac

    local tmpdir
    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' EXIT

    local url="https://github.com/MetaCubeX/mihomo/releases/latest/download/mihomo-linux-${arch}-compatible.gz"
    info "Fetching: $url"

    if command -v wget &>/dev/null; then
        wget -q -O "$tmpdir/mihomo.gz" "$url"
    elif command -v curl &>/dev/null; then
        curl -sL -o "$tmpdir/mihomo.gz" "$url"
    else
        error "Neither wget nor curl found. Install one of them."
    fi

    gunzip "$tmpdir/mihomo.gz"
    chmod +x "$tmpdir/mihomo"
    mv "$tmpdir/mihomo" "$BINDIR/mihomo"
    info "mihomo installed to $BINDIR/mihomo"
}

install_files() {
    info "Installing mihomoctl..."
    install -Dm755 "$SCRIPT_DIR/src/mihomoctl" "$BINDIR/mihomoctl"

    info "Installing mihomo-update-config..."
    install -Dm755 "$SCRIPT_DIR/lib/mihomo-update-config" "$SBINDIR/mihomo-update-config"

    info "Installing systemd units..."
    for f in mihomo.service mihomo-update.service mihomo-update.timer; do
        install -Dm644 "$SCRIPT_DIR/systemd/$f" "$UNITDIR/$f"
    done

    info "Installing default config..."
    mkdir -p "$SYSCONFDIR/mihomo"
    if [[ ! -f "$SYSCONFDIR/mihomo/config.yaml" ]]; then
        install -Dm600 "$SCRIPT_DIR/config/base.yaml" "$SYSCONFDIR/mihomo/config.yaml"
    else
        warn "$SYSCONFDIR/mihomo/config.yaml already exists, skipping (use your existing config)"
    fi

    mkdir -p /var/lib/mihomoctl
}

enable_services() {
    info "Reloading systemd..."
    systemctl daemon-reload

    echo ""
    info "Installation complete!"
    echo ""
    echo "Next steps:"
    echo ""
    echo "  1. Set your subscription URL:"
    echo "     sudo mihomoctl sub set"
    echo ""
    echo "  2. Enable and start mihomo:"
    echo "     sudo systemctl enable --now mihomo.service"
    echo ""
    echo "  3. (Optional) Enable auto-update timer:"
    echo "     sudo systemctl enable --now mihomo-update.timer"
    echo ""
    echo "  4. Manage:"
    echo "     mihomoctl status          # status"
    echo "     mihomoctl groups          # list proxy groups"
    echo "     mihomoctl nodes           # list nodes"
    echo "     mihomoctl use <node>      # select node"
    echo "     mihomoctl pick            # interactive select (needs fzf)"
    echo "     mihomoctl mode tun|proxy  # switch mode"
    echo ""
}

install_deps
install_mihomo
install_files
enable_services
