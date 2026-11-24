#!/usr/bin/env bash
# Shared helpers. Sourced by bootstrap.sh.

log() { printf '\n\033[1;34m[+]\033[0m %s\n' "$*"; }
warn() { printf '\n\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
die() { printf '\n\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }
ask() {
  local prompt="$1" default="${2:-y}" answer
  if (( NONINTERACTIVE )); then [[ "$default" == y ]]; return; fi
  if [[ "$default" == y ]]; then prompt="$prompt [Y/n] "; else prompt="$prompt [y/N] "; fi
  read -r -p "$prompt" answer || answer=""
  answer=${answer,,}
  [[ -z "$answer" ]] && answer="$default"
  [[ "$answer" == y || "$answer" == yes ]]
}
ask_value() {
  local prompt="$1" default="${2:-}" value
  if (( NONINTERACTIVE )); then printf '%s' "$default"; return; fi
  if [[ -n "$default" ]]; then read -r -p "$prompt [$default]: " value || value=""; else read -r -p "$prompt: " value || value=""; fi
  printf '%s' "${value:-$default}"
}
run() {
  if (( DRY_RUN )); then printf '\033[1;33m[DRY RUN]\033[0m'; printf ' %q' "$@"; printf '\n'; else "$@"; fi
}
backup_file() {
  local file="$1" bak
  [[ -e "$file" ]] || return 0
  bak="$file.bak"
  if [[ -e "$bak" ]]; then
    local stamp; stamp=$(date +%Y%m%d-%H%M%S)
    bak="$file.bak.$stamp"
    local n=1
    while [[ -e "$bak" ]]; do bak="$file.bak.$stamp.$n"; ((n+=1)); done
  fi
  if (( DRY_RUN )); then log "Would preserve existing file: $file -> $bak"; else cp -a -- "$file" "$bak"; log "Backup created: $bak"; fi
}
write_file_with_backup() {
  local file="$1" content="$2"
  if [[ -e "$file" ]]; then backup_file "$file"; fi
  if (( DRY_RUN )); then log "Would write $file"; return; fi
  mkdir -p "$(dirname -- "$file")"
  printf '%s\n' "$content" > "$file"
}
replace_managed_block() {
  # Replace/add a managed block in an existing file, backing up the original first.
  # Arguments: file, start-marker, end-marker, block-content
  local file="$1" start="$2" end="$3" content="$4" tmp
  if [[ -e "$file" ]]; then backup_file "$file"; fi
  if (( DRY_RUN )); then log "Would update managed block in $file"; return; fi
  mkdir -p "$(dirname -- "$file")"
  tmp=$(mktemp)
  if [[ -f "$file" ]]; then
    awk -v s="$start" -v e="$end" 'BEGIN{skip=0} $0==s{skip=1;next} $0==e{skip=0;next} !skip{print}' "$file" > "$tmp"
  fi
  { cat "$tmp"; [[ -s "$tmp" ]] && printf '\n'; printf '%s\n%s\n%s\n' "$start" "$content" "$end"; } > "$file"
  rm -f "$tmp"
}
err_report() { warn "An unexpected error occurred near line $1. Review the output above; existing files are preserved where managed changes were made."; }
usage() {
  cat <<'USAGE'
Usage: ./bootstrap.sh [options]
  --dry-run          Print planned actions without applying changes
  --skip-auth        Skip gh authentication
  --skip-signing     Skip commit/tag signing setup
  --non-interactive  Use defaults and avoid prompts (requires suitable defaults)
  --help             Show this help
USAGE
}
banner() { printf '\n\033[1;36m=========================================\n  %s\n=========================================\033[0m\n' "$*"; }

# When invoked as root, offer to run the bootstrap as a regular account.
handoff_to_user() {
  log "Running as root. Git and GitHub configuration should normally belong to a regular user."
  local users=() u choice username home shell
  while IFS=: read -r username _ uid _ _ home shell; do
    if [[ "$uid" =~ ^[0-9]+$ ]] && (( uid >= 1000 && uid < 60000 )) && [[ "$shell" != */nologin && "$shell" != */false ]] && [[ "$username" != "nobody" ]]; then users+=("$username"); fi
  done < <(getent passwd)
  if (( NONINTERACTIVE )); then
    warn "Non-interactive root run: proceeding as root. Use --non-interactive as a regular user for personal setup."
    return
  fi
  if ((${#users[@]})); then
    printf '\nAvailable regular users:\n'
    local i=1
    for u in "${users[@]}"; do printf '  %d) %s\n' "$i" "$u"; ((i+=1)); done
    printf '  %d) Create a new user\n' "$i"
    read -r -p "Choose user [1-$i]: " choice || choice=""
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice>=1 && choice<=${#users[@]} )); then
      u=${users[choice-1]}
    elif [[ "$choice" == "$i" ]]; then
      u=$(create_bootstrap_user)
      [[ -n "$u" ]] || return
    else
      warn "Invalid selection; continuing as root."
      return
    fi
  else
    warn "No regular user accounts found."
    if ask "Create a regular user now?" y; then u=$(create_bootstrap_user); else return; fi
    [[ -n "$u" ]] || return
  fi
  home=$(getent passwd "$u" | cut -d: -f6)
  log "Re-launching bootstrap as $u (HOME=$home)."
  export GIT_BOOTSTRAP_HANDOFF=1
  exec runuser -u "$u" -- env HOME="$home" USER="$u" LOGNAME="$u" GIT_BOOTSTRAP_HANDOFF=1 bash "$SCRIPT_DIR/bootstrap.sh" "${ORIGINAL_ARGS[@]}"
}

create_bootstrap_user() {
  local username
  username=$(ask_value "New username" "")
  [[ -n "$username" ]] || { warn "Username cannot be empty."; return 1; }
  if getent passwd "$username" >/dev/null; then warn "User already exists: $username"; printf '%s' "$username"; return 0; fi
  if (( DRY_RUN )); then log "Dry-run: would create user $username and set password"; printf '%s' "$username"; return 0; fi
  if command -v useradd >/dev/null; then
    useradd -m -s "$(command -v bash)" "$username" || { warn "Failed to create user."; return 1; }
    # Add to a conventional sudo-capable group where present.
    if getent group sudo >/dev/null; then usermod -aG sudo "$username"; elif getent group wheel >/dev/null; then usermod -aG wheel "$username"; fi
    passwd "$username" || warn "Password setup failed; user created without a usable password."
  else warn "useradd not available."; return 1; fi
  printf '%s' "$username"
}
