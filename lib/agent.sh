#!/usr/bin/env bash

configure_agent() {
  log "SSH agent"
  local runtime="$XDG_RUNTIME_DIR" service="$HOME/.config/systemd/user/ssh-agent.service" envfile="$HOME/.config/environment.d/ssh-agent.conf"
  if [[ -n "${SSH_AUTH_SOCK:-}" ]] && ssh-add -l >/dev/null 2>&1; then log "A working SSH agent is already available."; return; fi
  if [[ "$INIT_SYSTEM" == systemd-user && -d "$runtime" ]]; then
    local unit
    unit=$(cat <<'UNIT'
[Unit]
Description=SSH authentication agent

[Service]
Type=simple
ExecStart=/usr/bin/ssh-agent -D -a %t/ssh-agent.socket

[Install]
WantedBy=default.target
UNIT
)
    write_file_with_backup "$service" "$unit"
    run systemctl --user daemon-reload
    run systemctl --user enable --now ssh-agent.service
    local envcontent='SSH_AUTH_SOCK=${XDG_RUNTIME_DIR}/ssh-agent.socket'
    write_file_with_backup "$envfile" "$envcontent"
    if (( DRY_RUN == 0 )); then export SSH_AUTH_SOCK="$runtime/ssh-agent.socket"; fi
  else
    warn "No working systemd user manager detected. If an agent is not already provided by your desktop, start ssh-agent manually and set SSH_AUTH_SOCK."
    if [[ -d "$runtime" && -n "$runtime" ]]; then
      if (( DRY_RUN )); then log "Would start ssh-agent using socket $runtime/ssh-agent.socket"; else eval "$(ssh-agent -s -a "$runtime/ssh-agent.socket")"; fi
    fi
  fi
  if [[ -f "${SSH_KEY:-}" ]] && (( DRY_RUN == 0 )) && [[ -n "${SSH_AUTH_SOCK:-}" ]]; then ssh-add "$SSH_KEY" || warn "Agent/key loading needs attention."; fi
}
