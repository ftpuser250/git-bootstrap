#!/usr/bin/env bash

authenticate_github() {
  log "GitHub CLI authentication"
  if ! command -v gh >/dev/null 2>&1; then warn "gh not installed; skipping authentication."; return; fi
  if gh auth status >/dev/null 2>&1; then log "gh already authenticated."; else
    if (( DRY_RUN )); then log "Would run gh auth login -h github.com -p ssh -w -s admin:ssh_signing_key"; return; fi
    gh auth login -h github.com -p ssh -w -s admin:ssh_signing_key || warn "GitHub authentication did not complete. You can retry with gh auth login."
  fi
  if (( DRY_RUN == 0 )) && gh auth status >/dev/null 2>&1; then
    gh config set git_protocol ssh || warn "Could not set GitHub CLI Git protocol to SSH."
    if [[ -f "${SSH_PUB:-}" ]]; then
      if ask "Upload this SSH public key for GitHub authentication (if not already uploaded)?" y; then
        gh ssh-key add "$SSH_PUB" --title "${HOSTNAME:-linux}-auth" --type authentication || warn "Could not upload SSH authentication key (it may already be registered)."
      fi
    fi
  fi
}
