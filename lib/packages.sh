#!/usr/bin/env bash

install_dependencies() {
  local missing=() pkg sudo_cmd=()
  for pkg in git gh ssh ssh-keygen ssh-agent tldr nano; do command -v "$pkg" >/dev/null 2>&1 || missing+=("$pkg"); done
  # ssh-related command names are provided by OpenSSH packages; map binaries to package names below.
  if command -v git >/dev/null 2>&1 && command -v gh >/dev/null 2>&1 && command -v ssh >/dev/null 2>&1 && command -v tldr >/dev/null 2>&1 && command -v nano >/dev/null 2>&1; then log "Dependencies already installed (git, gh, openssh, tldr, nano)."; return; fi
  [[ -n "$PKG_MANAGER" ]] || { warn "Install git, GitHub CLI (gh), OpenSSH, tldr and nano manually."; return; }
  if [[ $EUID -ne 0 ]] && command -v sudo >/dev/null 2>&1; then sudo_cmd=(sudo); elif [[ $EUID -ne 0 ]]; then warn "Root privileges are required to install packages; skipping."; return; fi
  case "$PKG_MANAGER" in
    pacman) run "${sudo_cmd[@]}" pacman -S --needed git github-cli openssh tldr nano;;
    apt) run "${sudo_cmd[@]}" apt-get update; run "${sudo_cmd[@]}" apt-get install -y git gh openssh-client tldr nano;;
    dnf) run "${sudo_cmd[@]}" dnf install -y git gh openssh-clients tldr nano;;
    zypper) run "${sudo_cmd[@]}" zypper install -y git gh openssh tldr nano;;
    apk) run "${sudo_cmd[@]}" apk add git github-cli openssh tldr nano;;
  esac
}
