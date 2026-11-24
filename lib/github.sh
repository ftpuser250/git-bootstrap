#!/usr/bin/env bash

authenticate_github() {
  log "GitHub CLI authentication"
  if ! command -v gh >/dev/null 2>&1; then warn "gh not installed; skipping authentication."; return; fi
  if ! gh auth status >/dev/null 2>&1; then
    if (( DRY_RUN )); then log "Would run gh auth login -h github.com -p ssh -w -s admin:ssh_signing_key"; return; fi
    # gh handles device-flow authentication even on headless machines; it prints the URL/code
    # when no browser launcher is available. Do not separately upload an auth key here:
    # gh auth login's SSH protocol flow already offers that step.
    gh auth login -h github.com -p ssh -w -s admin:ssh_signing_key || warn "GitHub authentication did not complete. Retry with gh auth login."
  else
    log "gh already authenticated."
  fi
  if (( DRY_RUN == 0 )) && gh auth status >/dev/null 2>&1; then
    gh config set git_protocol ssh || warn "Could not set GitHub CLI Git protocol to SSH."
  fi
}
