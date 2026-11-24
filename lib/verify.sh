#!/usr/bin/env bash

verify_github_ssh() {
  [[ -f "${SSH_KEY:-}" ]] || { warn "No SSH key selected; skipping SSH test."; return 1; }
  # Establish GitHub host trust only after comparing its ED25519 fingerprint against
  # GitHub's published fingerprint. Avoid an interactive yes/no prompt in validation.
  local known="$HOME/.ssh/known_hosts" scan fingerprint expected="SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU"
  if ! ssh-keygen -F github.com -f "$known" >/dev/null 2>&1; then
    if (( NONINTERACTIVE )); then warn "github.com host key not recorded; cannot safely trust it automatically."; return 1; fi
    log "Checking GitHub host fingerprint before recording it."
    scan=$(ssh-keyscan -t ed25519 github.com 2>/dev/null) || { warn "Could not retrieve GitHub host key."; return 1; }
    fingerprint=$(printf '%s\n' "$scan" | ssh-keygen -lf - 2>/dev/null | awk '{print $2; exit}')
    if [[ "$fingerprint" != "$expected" ]]; then warn "GitHub host fingerprint mismatch ($fingerprint); refusing to record host key."; return 1; fi
    printf '%s\n' "$scan" >> "$known"
    chmod 600 "$known"
    log "GitHub ED25519 host fingerprint verified and recorded."
  fi
  local output status
  output=$(ssh -T -o BatchMode=yes git@github.com 2>&1) || status=$?
  status=${status:-0}
  printf '%s\n' "$output"
  if [[ "$output" == *"You've successfully authenticated"* ]]; then log "GitHub SSH authentication succeeded (SSH exit code $status is expected to be nonzero)."; return 0; fi
  warn "GitHub SSH authentication did not succeed."
  return 1
}

run_checks() {
  log "Validation"
  command -v git >/dev/null 2>&1 && log "Git: available" || warn "Git: missing"
  command -v ssh >/dev/null 2>&1 && log "SSH: available" || warn "SSH: missing"
  command -v gh >/dev/null 2>&1 && log "GitHub CLI: available" || warn "GitHub CLI: missing"
  command -v tldr >/dev/null 2>&1 && log "tldr: available" || warn "tldr: missing"
  command -v nano >/dev/null 2>&1 && log "nano: available" || warn "nano: missing"
  if (( DRY_RUN )); then log "Skipping live checks in dry-run mode."; return; fi
  if [[ -n "${SSH_AUTH_SOCK:-}" ]]; then ssh-add -l >/dev/null 2>&1 && log "Agent: key loaded" || warn "Agent: no key loaded or agent unavailable"; else warn "SSH_AUTH_SOCK is unset."; fi
  verify_github_ssh || true
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
