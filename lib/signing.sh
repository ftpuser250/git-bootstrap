#!/usr/bin/env bash

configure_signing() {
  log "SSH commit and tag signing"
  if [[ ! -f "${SSH_PUB:-}" ]]; then warn "Public SSH key unavailable; skipping signing configuration."; return; fi
  local email publine allowed="$HOME/.ssh/allowed_signers" signing_choice
  email=$(git config --global --get user.email || true)
  [[ -n "$email" ]] || { warn "Git email is not configured. Skipping signing setup."; return; }
  signing_choice=$(ask_value "Signing key public file" "$SSH_PUB")
  if [[ ! -f "$signing_choice" ]]; then warn "Signing key file not found: $signing_choice"; return; fi
  run git config --global gpg.format ssh
  run git config --global user.signingkey "$signing_choice"
  if ask "Enable signed commits globally?" y; then run git config --global commit.gpgsign true; fi
  if ask "Enable signed tags globally?" y; then run git config --global tag.gpgsign true; fi
  if (( DRY_RUN )); then log "Would register SSH signing key with GitHub and update allowed_signers."; return; fi
  gh ssh-key add "$signing_choice" --type signing --title "${HOSTNAME:-linux}-signing" || warn "Signing key upload failed or key may already be registered."
  publine=$(cat "$signing_choice")
  local entry="$email $publine"
  if [[ -f "$allowed" ]] && grep -Fxq "$entry" "$allowed"; then log "Signer already present in allowed_signers."; else
    if [[ -e "$allowed" ]]; then backup_file "$allowed"; fi
    mkdir -p "$HOME/.ssh"; touch "$allowed"; chmod 600 "$allowed"
    printf '%s\n' "$entry" >> "$allowed"
  fi
  run git config --global gpg.ssh.allowedSignersFile "$allowed"
}
