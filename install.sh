#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/MrJefter/mihomoctl.git"
REAL_HOME="${SUDO_USER:-$HOME}"
INSTALL_DIR="${MIHOMOCTL_DIR:-$REAL_HOME/.local/share/mihomoctl}"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[-]${NC} $*"; exit 1; }

if [[ $EUID -ne 0 ]]; then
    error "Run with sudo: sudo bash install.sh"
fi

PREFIX="${PREFIX:-/usr/local}"
BINDIR="${BINDIR:-$PREFIX/bin}"
SBINDIR="${SBINDIR:-$PREFIX/sbin}"
SYSCONFDIR="${SYSCONFDIR:-/etc}"
UNITDIR="${UNITDIR:-/etc/systemd/system}"

# --- detect if running from repo or piped ---
find_repo_dir() {
    if [[ -f "./src/mihomoctl" && -f "./Makefile" ]]; then
        echo "$(pwd)"
    elif [[ -f "./install.sh" && -d "./src" ]]; then
        echo "$(pwd)"
    else
        echo ""
    fi
}

clone_repo() {
    info "Cloning mihomoctl to $INSTALL_DIR..."
    if [[ -d "$INSTALL_DIR/.git" ]]; then
        info "Repository already exists at $INSTALL_DIR, pulling..."
        git -C "$INSTALL_DIR" pull --ff-only || error "Git pull failed"
    else
        mkdir -p "$(dirname "$INSTALL_DIR")"
        git clone "$REPO" "$INSTALL_DIR"
    fi
    echo "$INSTALL_DIR"
}

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
    trap 'rm -rf "${tmpdir:-}"' EXIT

    local tag
    tag="$(curl -sL "https://api.github.com/repos/MetaCubeX/mihomo/releases/latest" | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4)"
    if [[ -z "$tag" ]]; then
        error "Failed to fetch latest mihomo version from GitHub"
    fi

    local url="https://github.com/MetaCubeX/mihomo/releases/download/${tag}/mihomo-linux-${arch}-compatible-${tag}.gz"
    info "Fetching: $url"

    if command -v wget &>/dev/null; then
        if ! wget -q -O "$tmpdir/mihomo.gz" "$url"; then
            error "Download failed. Check your network or URL: $url"
        fi
    elif command -v curl &>/dev/null; then
        if ! curl -sL -o "$tmpdir/mihomo.gz" "$url"; then
            error "Download failed. Check your network or URL: $url"
        fi
    else
        error "Neither wget nor curl found. Install one of them."
    fi

    if [[ ! -s "$tmpdir/mihomo.gz" ]]; then
        error "Downloaded file is empty"
    fi

    gunzip "$tmpdir/mihomo.gz"
    chmod +x "$tmpdir/mihomo"
    mv "$tmpdir/mihomo" "$BINDIR/mihomo"

    if command -v restorecon &>/dev/null; then
        restorecon "$BINDIR/mihomo"
    fi

    info "mihomo installed to $BINDIR/mihomo"
}

install_files() {
    local repo_dir="$1"

    info "Installing mihomoctl..."
    install -Dm755 "$repo_dir/src/mihomoctl" "$BINDIR/mihomoctl"

    info "Installing mihomo-update-config..."
    install -Dm755 "$repo_dir/lib/mihomo-update-config" "$SBINDIR/mihomo-update-config"

    info "Installing systemd units..."
    for f in mihomo.service mihomo-update.service mihomo-update.timer; do
        install -Dm644 "$repo_dir/systemd/$f" "$UNITDIR/$f"
    done

    mkdir -p "$SYSCONFDIR/mihomo"
    mkdir -p /var/lib/mihomoctl
}

enable_services() {
    info "Reloading systemd..."
    systemctl daemon-reload
}

show_install_complete() {
    echo ""
    info "Installation complete!"
    echo ""
    echo "Next steps:"
    echo ""
    echo "  1. Enable and start mihomo:"
    echo "     sudo mihomoctl enable"
    echo ""
    echo "  2. (Optional) Enable auto-update timer:"
    echo "     sudo systemctl enable --now mihomo-update.timer"
    echo ""
    echo "  3. Manage:"
    echo "     mihomoctl group pick       # pick default group"
    echo "     mihomoctl group profile    # pick routing profile"
    echo "     mihomoctl node pick        # pick node in current group"
    echo "     mihomoctl mode tun|proxy   # switch mode"
    echo ""
    echo "  Update:  curl -fsSL $REPO/raw/master/install.sh | sudo bash -s -- --update"
    echo "  Remove:  curl -fsSL $REPO/raw/master/install.sh | sudo bash -s -- --remove"
    echo ""
}

download_roscomvpn() {
    local base="$SYSCONFDIR/mihomo/base.yaml"
    if [[ -f "$base" ]]; then
        warn "$base already exists, skipping"
        return
    fi

    echo ""
    read -rp "Download RoscomVPN routing template? [Y/n] " answer
    case "${answer,,}" in
        n|no) info "Skipped. Run 'sudo mihomoctl sub set' to configure manually." ;;
        *)
            info "Downloading RoscomVPN template..."
            local url="https://raw.githubusercontent.com/hydraponique/roscomvpn-routing/main/MIHOMO/template_remnawave.yaml"
            if command -v wget &>/dev/null; then
                wget -q -O "$base" "$url"
            elif command -v curl &>/dev/null; then
                curl -sL -o "$base" "$url"
            else
                warn "Neither wget nor curl found. Download manually: $url"
                return
            fi
            chmod 600 "$base"
            info "Saved: $base"
            ;;
    esac
}

do_install() {
    local repo_dir
    repo_dir="$(find_repo_dir)"

    if [[ -z "$repo_dir" ]]; then
        info "Not running from repository, cloning..."
        repo_dir="$(clone_repo)"
    fi

    install_deps
    install_mihomo
    install_files "$repo_dir"
    download_roscomvpn
    enable_services
    show_install_complete
}

do_update() {
    if [[ ! -d "$INSTALL_DIR/.git" ]]; then
        error "Repository not found at $INSTALL_DIR. Run install first."
    fi

    info "Updating mihomoctl..."
    git -C "$INSTALL_DIR" pull --ff-only || error "Git pull failed"
    install_files "$INSTALL_DIR"
    enable_services

    info "Update complete!"
    if systemctl is-active --quiet mihomo.service 2>/dev/null; then
        systemctl restart mihomo.service
        info "mihomo service restarted"
    fi
}

do_remove() {
    info "Removing mihomoctl..."
    rm -f "$BINDIR/mihomoctl"
    rm -f "$SBINDIR/mihomo-update-config"
    rm -f "$UNITDIR/mihomo.service"
    rm -f "$UNITDIR/mihomo-update.service"
    rm -f "$UNITDIR/mihomo-update.timer"

    if systemctl is-active --quiet mihomo.service 2>/dev/null; then
        systemctl stop mihomo.service
    fi
    if systemctl is-enabled --quiet mihomo.service 2>/dev/null; then
        systemctl disable mihomo.service
    fi

    systemctl daemon-reload 2>/dev/null || true

    echo ""
    info "mihomoctl removed."
    echo ""
    echo "Remaining (manual removal if needed):"
    echo "  $BINDIR/mihomo"
    echo "  $SYSCONFDIR/mihomo/"
    echo "  /var/lib/mihomoctl/"
    echo "  $INSTALL_DIR/"
    echo ""
    echo "To remove everything:"
    echo "  sudo rm -rf $SYSCONFDIR/mihomo /var/lib/mihomoctl $INSTALL_DIR $BINDIR/mihomo"
    echo ""
}

# --- main ---
ACTION="${1:-install}"
case "$ACTION" in
    --update|-u)  do_update ;;
    --remove|-r)  do_remove ;;
    --help|-h)
        echo "Usage: install.sh [OPTION]"
        echo ""
        echo "Options:"
        echo "  (no args)   Full install"
        echo "  --update    Update mihomoctl from git"
        echo "  --remove    Remove mihomoctl"
        echo "  --help      Show this help"
        echo ""
        echo "One-liner install:"
        echo "  curl -fsSL $REPO/raw/master/install.sh | sudo bash"
        echo ""
        echo "One-liner update:"
        echo "  curl -fsSL $REPO/raw/master/install.sh | sudo bash -s -- --update"
        echo ""
        echo "One-liner remove:"
        echo "  curl -fsSL $REPO/raw/master/install.sh | sudo bash -s -- --remove"
        echo ""
        ;;
    install)      do_install ;;
    *)            error "Unknown option: $ACTION. Use --help for usage." ;;
esac
