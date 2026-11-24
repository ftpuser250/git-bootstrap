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
