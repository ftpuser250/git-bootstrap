#!/usr/bin/env bash

detect_environment() {
  OS_ID=unknown; OS_LIKE=""; OS_NAME="Unknown Linux"; PKG_MANAGER=""; INIT_SYSTEM="unknown"; DE="unknown"
  if [[ -r /etc/os-release ]]; then source /etc/os-release; OS_ID=${ID:-unknown}; OS_LIKE=${ID_LIKE:-}; OS_NAME=${PRETTY_NAME:-$OS_ID}; fi
  if command -v pacman >/dev/null 2>&1; then PKG_MANAGER=pacman
  elif command -v apt-get >/dev/null 2>&1; then PKG_MANAGER=apt
  elif command -v dnf >/dev/null 2>&1; then PKG_MANAGER=dnf
  elif command -v zypper >/dev/null 2>&1; then PKG_MANAGER=zypper
  elif command -v apk >/dev/null 2>&1; then PKG_MANAGER=apk
  fi
  if [[ -n "${SYSTEMD_EXEC_PID:-}" ]] || command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then INIT_SYSTEM=systemd-user; fi
  DE=${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-unknown}}
  XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-"/run/user/$(id -u)"}
}
show_environment() {
  log "Environment: $OS_NAME | package manager: ${PKG_MANAGER:-unsupported} | session: $INIT_SYSTEM | desktop: $DE"
  [[ -n "$PKG_MANAGER" ]] || warn "No supported package manager detected. Dependencies will not be installed automatically."
}
