#!/usr/bin/env bash

run_checks() {
  log "Validation"
  command -v git >/dev/null 2>&1 && log "Git: available" || warn "Git: missing"
  command -v ssh >/dev/null 2>&1 && log "SSH: available" || warn "SSH: missing"
  command -v gh >/dev/null 2>&1 && log "GitHub CLI: available" || warn "GitHub CLI: missing"
  command -v tldr >/dev/null 2>&1 && log "tldr: available" || warn "tldr: missing"
  command -v nano >/dev/null 2>&1 && log "nano: available" || warn "nano: missing"
  if (( DRY_RUN )); then log "Skipping live checks in dry-run mode."; return; fi
  if [[ -n "${SSH_AUTH_SOCK:-}" ]]; then ssh-add -l >/dev/null 2>&1 && log "Agent: key loaded" || warn "Agent: no key loaded or agent unavailable"; else warn "SSH_AUTH_SOCK is unset."; fi
  if [[ -f "${SSH_KEY:-}" ]]; then ssh -T git@github.com || warn "GitHub SSH check did not succeed (first connection may require host-key confirmation)."; fi
  gh auth status || warn "GitHub CLI authentication not verified."
  git config --global --get gpg.format >/dev/null && log "Signing format configured" || warn "Signing format not configured"
}
summary() {
  banner "Setup summary"
  printf 'OS:             %s\n' "$OS_NAME"
  printf 'Package manager: %s\n' "${PKG_MANAGER:-unsupported}"
  printf 'Git identity:   %s <%s>\n' "$(git config --global --get user.name 2>/dev/null || echo unset)" "$(git config --global --get user.email 2>/dev/null || echo unset)"
  printf 'SSH key:        %s\n' "${SSH_KEY:-not selected}"
  printf 'Git signing:    %s\n' "$(git config --global --get commit.gpgsign 2>/dev/null || echo not-enabled)"
  printf '\nReview any warnings above. See README.md for troubleshooting and manual steps.\n'
}
