#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/detect.sh"
source "$SCRIPT_DIR/lib/packages.sh"
source "$SCRIPT_DIR/lib/git.sh"
source "$SCRIPT_DIR/lib/ssh.sh"
source "$SCRIPT_DIR/lib/agent.sh"
source "$SCRIPT_DIR/lib/github.sh"
source "$SCRIPT_DIR/lib/signing.sh"
source "$SCRIPT_DIR/lib/verify.sh"

DRY_RUN=0
SKIP_AUTH=0
SKIP_SIGNING=0
NONINTERACTIVE=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1;;
    --skip-auth) SKIP_AUTH=1;;
    --skip-signing) SKIP_SIGNING=1;;
    --non-interactive) NONINTERACTIVE=1;;
    --help|-h) usage; exit 0;;
    *) die "Unknown option: $arg";;
  esac
done

trap 'err_report $LINENO' ERR
banner "Linux Git & GitHub Bootstrap"
detect_environment
show_environment
install_dependencies
configure_git_identity
configure_ssh
configure_agent
if (( SKIP_AUTH == 0 )); then authenticate_github; else log "Skipping GitHub CLI authentication (--skip-auth)."; fi
if (( SKIP_SIGNING == 0 )); then configure_signing; else log "Skipping signing (--skip-signing)."; fi
run_checks
summary
