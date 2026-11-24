#!/usr/bin/env bash

configure_agent() {
  log "SSH agent"
  local runtime socket service envfile agent_cmd
  runtime="${XDG_RUNTIME_DIR:-}"
  service="$HOME/.config/systemd/user/ssh-agent.service"
  envfile="$HOME/.config/environment.d/ssh-agent.conf"
  if [[ -n "${SSH_AUTH_SOCK:-}" ]] && ssh-add -l >/dev/null 2>&1; then log "A working SSH agent is already available."; load_agent_key; return; fi

  # Prefer systemd user service when a real user manager is available.
  if [[ "$INIT_SYSTEM" == systemd-user && -d "$runtime" && -n "$runtime" ]] && systemctl --user show-environment >/dev/null 2>&1; then
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
    write_file_with_backup "$envfile" 'SSH_AUTH_SOCK=${XDG_RUNTIME_DIR}/ssh-agent.socket'
    if (( DRY_RUN == 0 )); then export SSH_AUTH_SOCK="$runtime/ssh-agent.socket"; fi
  else
    # Fallback for console sessions without a systemd user manager. Socket is user-owned.
    if [[ -z "$runtime" || ! -d "$runtime" ]]; then runtime="$HOME/.ssh"; fi
    socket="$runtime/ssh-agent.socket"
    if (( DRY_RUN )); then log "Would start ssh-agent on $socket"; else
      mkdir -p "$runtime"; chmod 700 "$runtime"
      if [[ -S "$socket" ]] && SSH_AUTH_SOCK="$socket" ssh-add -l >/dev/null 2>&1; then export SSH_AUTH_SOCK="$socket"
      else eval "$(ssh-agent -s -a "$socket")"; export SSH_AUTH_SOCK="$socket"; fi
    fi
    warn "No systemd user manager available; started/reused a session agent fallback. SSH_AUTH_SOCK is set for this run."
  fi
  load_agent_key
}

load_agent_key() {
  if [[ -f "${SSH_KEY:-}" ]] && (( DRY_RUN == 0 )) && [[ -n "${SSH_AUTH_SOCK:-}" ]]; then
    if ssh-add -l 2>/dev/null | grep -Fq "$(ssh-keygen -lf "$SSH_KEY" 2>/dev/null | awk '{print $2}')"; then log "SSH key is already loaded."; else ssh-add "$SSH_KEY" || warn "Could not load SSH key into agent."; fi
  fi
}
