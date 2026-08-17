#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/Jefter5549/mihomoctl.git"
if [[ -n "${SUDO_USER:-}" ]]; then
    REAL_HOME="$(getent passwd "$SUDO_USER" 2>/dev/null | cut -d: -f6)"
    if [[ -z "$REAL_HOME" || ! -d "$REAL_HOME" ]]; then
        REAL_HOME="$(eval echo "~$SUDO_USER")"
    fi
else
    REAL_HOME="$HOME"
fi
INSTALL_DIR="${MIHOMOCTL_DIR:-$REAL_HOME/.local/share/mihomoctl}"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $*" >&2; }
warn()  { echo -e "${YELLOW}[!]${NC} $*" >&2; }
error() { echo -e "${RED}[-]${NC} $*" >&2; exit 1; }

ACTION="${1:-install}"
if [[ "$ACTION" == "--help" || "$ACTION" == "-h" ]]; then
    echo "Usage: install.sh [OPTION]"
    echo ""
    echo "Options:"
    echo "  (no args)   Install or update mihomoctl"
    echo "  --remove    Remove mihomoctl"
    echo "  --help      Show this help"
    echo ""
    echo "Install / update:"
    echo "  curl -fsSL \"https://raw.githubusercontent.com/Jefter5549/mihomoctl/master/install.sh?v=\$(date +%s)\" | sudo bash"
    echo ""
    echo "Remove:"
    echo "  curl -fsSL \"https://raw.githubusercontent.com/Jefter5549/mihomoctl/master/install.sh?v=\$(date +%s)\" | sudo bash -s -- --remove"
    echo ""
    exit 0
fi

if [[ $EUID -ne 0 ]]; then
    error "Run with sudo: sudo bash install.sh"
fi

PREFIX="${PREFIX:-/usr/local}"
BINDIR="${BINDIR:-$PREFIX/bin}"
SBINDIR="${SBINDIR:-$PREFIX/sbin}"
SYSCONFDIR="${SYSCONFDIR:-/etc}"
UNITDIR="${UNITDIR:-/etc/systemd/system}"

clone_repo() {
    info "Cloning mihomoctl to $INSTALL_DIR..."
    if [[ -d "$INSTALL_DIR/.git" ]]; then
        info "Repository already exists at $INSTALL_DIR, pulling..."
        git -C "$INSTALL_DIR" pull --ff-only >&2 || error "Git pull failed"
    else
        mkdir -p "$(dirname "$INSTALL_DIR")"
        git clone "$REPO" "$INSTALL_DIR" >&2
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
    elif command -v zypper &>/dev/null; then
        echo "zypper"
    elif command -v apk &>/dev/null; then
        echo "apk"
    else
        echo "unknown"
    fi
}

install_deps() {
    local pm
    pm="$(detect_pkg_manager)"
    info "Detected package manager: $pm"

    local need_pkg=()

    if ! command -v python3 &>/dev/null; then
        case "$pm" in
            apt)    need_pkg+=(python3) ;;
            dnf)    need_pkg+=(python3) ;;
            pacman) need_pkg+=(python) ;;
            zypper) need_pkg+=(python3) ;;
            apk)    need_pkg+=(python3) ;;
        esac
    fi

    if ! python3 -c "import yaml" 2>/dev/null; then
        case "$pm" in
            apt)    need_pkg+=(python3-yaml) ;;
            dnf)    need_pkg+=(python3-pyyaml) ;;
            pacman) need_pkg+=(python-yaml) ;;
            zypper) need_pkg+=(python3-PyYAML) ;;
            apk)    need_pkg+=(py3-yaml) ;;
        esac
    fi

    if ! command -v curl &>/dev/null && ! command -v wget &>/dev/null; then
        case "$pm" in
            apt|dnf|pacman|zypper|apk) need_pkg+=(curl) ;;
        esac
    fi

    if ! command -v gunzip &>/dev/null; then
        case "$pm" in
            apt|dnf|zypper) need_pkg+=(gzip) ;;
            pacman) need_pkg+=(gzip) ;;
            apk) need_pkg+=(gzip) ;;
        esac
    fi

    if ! command -v git &>/dev/null; then
        case "$pm" in
            apt|dnf|pacman|zypper|apk) need_pkg+=(git) ;;
        esac
    fi

    if [[ ${#need_pkg[@]} -gt 0 ]]; then
        info "Installing required dependencies: ${need_pkg[*]}..."
        case "$pm" in
            apt)
                export DEBIAN_FRONTEND=noninteractive
                apt-get update -qq && apt-get install -y -qq "${need_pkg[@]}"
                ;;
            dnf)
                dnf install -y -q "${need_pkg[@]}"
                ;;
            pacman)
                pacman -S --noconfirm "${need_pkg[@]}"
                ;;
            zypper)
                zypper install -y "${need_pkg[@]}"
                ;;
            apk)
                apk add --no-cache "${need_pkg[@]}"
                ;;
            *)
                error "Cannot install dependencies automatically: ${need_pkg[*]}. Install them manually."
                ;;
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
        *)       error "Unsupported architecture: $arch (supported: x86_64, aarch64, armv7l)" ;;
    esac

    local tmpdir
    tmpdir="$(mktemp -d)"

    local tag=""
    if command -v curl &>/dev/null; then
        tag="$(curl -sL --max-time 10 "https://api.github.com/repos/MetaCubeX/mihomo/releases/latest" 2>/dev/null | grep -o '"tag_name": *"[^"]*"' | head -n1 | cut -d'"' -f4 || true)"
        if [[ -z "$tag" ]]; then
            local redir
            redir="$(curl -sIL -o /dev/null -w "%{url_effective}" --max-time 10 "https://github.com/MetaCubeX/mihomo/releases/latest" 2>/dev/null || true)"
            tag="${redir##*/}"
        fi
    elif command -v wget &>/dev/null; then
        tag="$(wget -qO- --timeout=10 "https://api.github.com/repos/MetaCubeX/mihomo/releases/latest" 2>/dev/null | grep -o '"tag_name": *"[^"]*"' | head -n1 | cut -d'"' -f4 || true)"
    fi

    if [[ -z "$tag" || "$tag" == "latest" ]]; then
        rm -rf "$tmpdir"
        error "Failed to fetch latest mihomo version from GitHub"
    fi

    local url="https://github.com/MetaCubeX/mihomo/releases/download/${tag}/mihomo-linux-${arch}-compatible-${tag}.gz"
    info "Fetching: $url"

    if command -v curl &>/dev/null; then
        if ! curl -sL -o "$tmpdir/mihomo.gz" "$url"; then
            rm -rf "$tmpdir"
            error "Download failed. Check your network or URL: $url"
        fi
    elif command -v wget &>/dev/null; then
        if ! wget -q -O "$tmpdir/mihomo.gz" "$url"; then
            rm -rf "$tmpdir"
            error "Download failed. Check your network or URL: $url"
        fi
    else
        rm -rf "$tmpdir"
        error "Neither wget nor curl found. Install one of them."
    fi

    if [[ ! -s "$tmpdir/mihomo.gz" ]]; then
        rm -rf "$tmpdir"
        error "Downloaded file is empty"
    fi

    if ! gunzip "$tmpdir/mihomo.gz"; then
        rm -rf "$tmpdir"
        error "Failed to decompress mihomo binary. Download may be corrupted."
    fi
    chmod +x "$tmpdir/mihomo"
    mv "$tmpdir/mihomo" "$BINDIR/mihomo"
    rm -rf "$tmpdir"

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

    info "Installing shell completions..."
    mkdir -p /etc/bash_completion.d
    install -Dm644 "$repo_dir/lib/mihomoctl-completion.bash" "/etc/bash_completion.d/mihomoctl"

    mkdir -p /usr/share/zsh/site-functions
    install -Dm644 "$repo_dir/lib/mihomoctl-completion.zsh" "/usr/share/zsh/site-functions/_mihomoctl"

    mkdir -p /usr/share/fish/vendor_completions.d
    install -Dm644 "$repo_dir/lib/mihomoctl-completion.fish" "/usr/share/fish/vendor_completions.d/mihomoctl.fish"

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
    echo "  1. Set subscription URL:"
    echo "     sudo mihomoctl sub set"
    echo ""
    echo "  2. Enable and start mihomo:"
    echo "     sudo mihomoctl enable"
    echo ""
    echo "  3. (Optional) Enable auto-update timer:"
    echo "     sudo systemctl enable --now mihomo-update.timer"
    echo ""
    echo "  4. Manage:"
    echo "     mihomoctl status           # check status"
    echo "     mihomoctl group list       # list policy groups"
    echo "     mihomoctl route pick       # interactively select route"
    echo "     mihomoctl proxy test --all # test proxy latencies"
    echo "     mihomoctl mode tun|proxy   # switch mode"
    echo ""
    echo "  Update:  curl -fsSL \"$REPO/raw/master/install.sh?v=\$(date +%s)\" | sudo bash"
    echo "  Remove:  curl -fsSL \"$REPO/raw/master/install.sh?v=\$(date +%s)\" | sudo bash -s -- --remove"
    echo ""
}

download_template() {
    local base="$1"
    local url="https://raw.githubusercontent.com/hydraponique/roscomvpn-routing/main/MIHOMO/template_remnawave.yaml"
    if command -v curl &>/dev/null; then
        curl -sL -o "$base" "$url"
    elif command -v wget &>/dev/null; then
        wget -q -O "$base" "$url"
    else
        warn "Neither wget nor curl found. Download manually: $url"
        return 1
    fi
    chmod 600 "$base"
    info "Saved: $base"
}

download_roscomvpn() {
    local base="$SYSCONFDIR/mihomo/base.yaml"

    if [[ ! -t 0 ]]; then
        info "Running non-interactively, skipping RoscomVPN template prompt."
        return
    fi

    if [[ -f "$base" ]]; then
        echo ""
        warn "$base already exists."
        read -rp "Overwrite with RoscomVPN template? [y/N] " answer
        case "${answer,,}" in
            y|yes)
                info "Downloading RoscomVPN template..."
                download_template "$base"
                ;;
            *)
                info "Keeping existing $base"
                ;;
        esac
    else
        echo ""
        read -rp "Download RoscomVPN routing template? [Y/n] " answer
        case "${answer,,}" in
            n|no) info "Skipped. Run 'sudo mihomoctl sub set' to configure manually." ;;
            *)    download_template "$base" ;;
        esac
    fi
}

do_install() {
    local repo_dir
    repo_dir="$(clone_repo)"

    install_deps
    install_mihomo
    install_files "$repo_dir"
    download_roscomvpn
    enable_services
    show_install_complete
}

do_remove() {
    info "Removing mihomoctl..."

    if systemctl is-active --quiet mihomo-update.timer 2>/dev/null; then
        systemctl stop mihomo-update.timer
    fi
    if systemctl is-enabled --quiet mihomo-update.timer 2>/dev/null; then
        systemctl disable mihomo-update.timer
    fi
    if systemctl is-active --quiet mihomo.service 2>/dev/null; then
        systemctl stop mihomo.service
    fi
    if systemctl is-enabled --quiet mihomo.service 2>/dev/null; then
        systemctl disable mihomo.service
    fi

    rm -f "$BINDIR/mihomoctl"
    rm -f "$SBINDIR/mihomo-update-config"
    rm -f "$UNITDIR/mihomo.service"
    rm -f "$UNITDIR/mihomo-update.service"
    rm -f "$UNITDIR/mihomo-update.timer"
    rm -f "/etc/bash_completion.d/mihomoctl"
    rm -f "/usr/share/zsh/site-functions/_mihomoctl"
    rm -f "/usr/share/fish/vendor_completions.d/mihomoctl.fish"

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
case "$ACTION" in
    --remove|-r)  do_remove ;;
    install)      do_install ;;
    *)            error "Unknown option: $ACTION. Use --help for usage." ;;
esac
