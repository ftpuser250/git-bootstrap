#!/usr/bin/env bash

configure_git_identity() {
  log "Git identity and defaults"
  local name email branch current
  name=$(git config --global --get user.name || true)
  email=$(git config --global --get user.email || true)
  branch=$(git config --global --get init.defaultBranch || true)
  name=$(ask_value "Git user.name" "$name")
  email=$(ask_value "Git user.email (verified GitHub email or noreply)" "$email")
  branch=$(ask_value "Default initial branch" "${branch:-main}")
  if [[ -n "$name" ]]; then run git config --global user.name "$name"; fi
  if [[ -n "$email" ]]; then run git config --global user.email "$email"; fi
  if [[ -n "$branch" ]]; then run git config --global init.defaultBranch "$branch"; fi
  current=$(git config --global --get user.name || true); [[ -n "$current" ]] || warn "Git name not set."
}
