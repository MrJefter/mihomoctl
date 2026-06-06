PREFIX      ?= /usr/local
BINDIR      ?= $(PREFIX)/bin
SBINDIR     ?= $(PREFIX)/sbin
SYSCONFDIR  ?= /etc
UNITDIR     ?= /etc/systemd/system
DESTDIR     ?=

INSTALL_DIR  = $(DESTDIR)$(BINDIR)
SBIN_DIR     = $(DESTDIR)$(SBINDIR)
CONF_DIR     = $(DESTDIR)$(SYSCONFDIR)/mihomo
UNIT_DIR     = $(DESTDIR)$(UNITDIR)
STATE_DIR    = $(DESTDIR)/var/lib/mihomoctl

.PHONY: help install uninstall update

help:
	@echo "mihomoctl - Mihomo subscription manager"
	@echo ""
	@echo "Targets:"
	@echo "  install     - Install all files (run with sudo)"
	@echo "  update      - Pull latest and reinstall (run with sudo)"
	@echo "  uninstall   - Remove all installed files (run with sudo)"
	@echo ""
	@echo "Variables:"
	@echo "  PREFIX      = $(PREFIX)"
	@echo "  BINDIR      = $(BINDIR)"
	@echo "  SBINDIR     = $(SBINDIR)"
	@echo "  SYSCONFDIR  = $(SYSCONFDIR)"
	@echo "  UNITDIR     = $(UNITDIR)"
	@echo "  DESTDIR     = $(DESTDIR)"
	@echo ""
	@echo "Usage:"
	@echo "  sudo make install"
	@echo "  sudo make update"
	@echo "  sudo make uninstall"

install:
	@echo "Installing mihomoctl..."
	@install -Dm755 src/mihomoctl           $(INSTALL_DIR)/mihomoctl
	@echo "Installing mihomo-update-config..."
	@install -Dm755 lib/mihomo-update-config $(SBIN_DIR)/mihomo-update-config
	@echo "Installing systemd units..."
	@install -Dm644 systemd/mihomo.service          $(UNIT_DIR)/mihomo.service
	@install -Dm644 systemd/mihomo-update.service   $(UNIT_DIR)/mihomo-update.service
	@install -Dm644 systemd/mihomo-update.timer     $(UNIT_DIR)/mihomo-update.timer
	@mkdir -p $(CONF_DIR)
	@mkdir -p $(STATE_DIR)
	@systemctl daemon-reload 2>/dev/null || true
	@echo ""
	@echo "Done. Run 'sudo ./install.sh' for full setup (deps + mihomo binary)."

update:
	@git pull
	@$(MAKE) install

uninstall:
	@echo "Removing mihomoctl..."
	@rm -f $(INSTALL_DIR)/mihomoctl
	@echo "Removing mihomo-update-config..."
	@rm -f $(SBIN_DIR)/mihomo-update-config
	@echo "Removing systemd units..."
	@rm -f $(UNIT_DIR)/mihomo.service
	@rm -f $(UNIT_DIR)/mihomo-update.service
	@rm -f $(UNIT_DIR)/mihomo-update.timer
	@systemctl daemon-reload 2>/dev/null || true
	@echo ""
	@echo "Remaining (manual removal if needed):"
	@echo "  $(CONF_DIR)/config.yaml"
	@echo "  /var/lib/mihomoctl/"
	@echo "  $(INSTALL_DIR)/mihomo  (mihomo binary, if installed by this project)"
	@echo ""
	@echo "To remove config and state:"
	@echo "  sudo rm -rf $(CONF_DIR) /var/lib/mihomoctl"
