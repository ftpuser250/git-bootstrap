#!/usr/bin/env bash

configure_ssh() {
  log "SSH key and configuration"
  local ssh_dir="$HOME/.ssh" key="$HOME/.ssh/id_ed25519" pub="$HOME/.ssh/id_ed25519.pub" key_choice
  if (( DRY_RUN )); then log "Would ensure SSH directory and key/config permissions."; fi
  if [[ ! -d "$ssh_dir" ]]; then run install -d -m 700 "$ssh_dir"; elif (( DRY_RUN == 0 )); then chmod 700 "$ssh_dir"; fi
  if [[ -f "$key" && -f "$pub" ]]; then
    if ask "Reuse existing ed25519 SSH key at $key?" y; then :
    else key_choice=$(ask_value "Enter key filename (absolute path) or leave blank to skip" ""); if [[ -n "$key_choice" ]]; then key="$key_choice"; pub="$key_choice.pub"; fi
    fi
  elif [[ ! -f "$key" ]]; then
    if ask "Generate a new ed25519 SSH key?" y; then
      if (( DRY_RUN )); then log "Would generate SSH key at $key"; else ssh-keygen -t ed25519 -C "${HOSTNAME:-linux}" -f "$key"; fi
    else warn "No SSH key generated. SSH transport and signing may need manual setup."; return; fi
  else warn "Incomplete keypair found; will not overwrite it. Please repair or choose another key."; return
  fi
  SSH_KEY="$key"; SSH_PUB="$pub"
  if [[ -f "$SSH_KEY" && -f "$SSH_PUB" && DRY_RUN -eq 0 ]]; then chmod 600 "$SSH_KEY"; chmod 644 "$SSH_PUB"; fi
  local block
  block=$(cat <<CFG
Host github.com
    User git
    IdentityFile $SSH_KEY
    AddKeysToAgent yes
    IdentitiesOnly yes
CFG
)
  replace_managed_block "$ssh_dir/config" "# BEGIN git-bootstrap" "# END git-bootstrap" "$block"
  if (( DRY_RUN == 0 )); then chmod 600 "$ssh_dir/config"; fi
  # if [[ -f "$SSH_KEY" ]] && (( DRY_RUN == 0 )); then ssh-add "$SSH_KEY" || warn "Could not add SSH key. Check that an agent is running."; fi
}
