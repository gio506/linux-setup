#!/usr/bin/env bash
# Beginner-friendly Linux setup automation
# Stages:
# 1) Internet check
# 2) Detect distro/version and ask for update actions
# 3) Minimal packages
# 4) Full packages
# 5) System specs and disk check

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
AUTO_YES="${AUTO_YES:-0}"         # AUTO_YES=1 -> answer yes to all prompts
SKIP_PROMPTS="${SKIP_PROMPTS:-0}" # SKIP_PROMPTS=1 -> no prompt, use defaults
DRY_RUN="${DRY_RUN:-0}"            # DRY_RUN=1 -> print commands, don't execute
PIPELINE_MODE="${PIPELINE_MODE:-0}" # PIPELINE_MODE=1 -> safe defaults for CI
SKIP_INTERNET_CHECK="${SKIP_INTERNET_CHECK:-0}" # SKIP_INTERNET_CHECK=1 -> skip ping stage
INTERNET_CHECK_HOST="${INTERNET_CHECK_HOST:-8.8.8.8}" # host used in ping test

usage() {
  cat <<USAGE
Usage:
  ./$SCRIPT_NAME

Environment variables:
  AUTO_YES=1            Answer yes to all stages (non-interactive)
  SKIP_PROMPTS=1        Skip questions and use default stage values
  DRY_RUN=1             Print commands only (good for tests)
  PIPELINE_MODE=1       Pipeline-safe mode: SKIP_PROMPTS=1 + DRY_RUN=1
  SKIP_INTERNET_CHECK=1 Skip ping stage (useful in CI without external network)
  INTERNET_CHECK_HOST   Ping host (default: 8.8.8.8)

Quick meaning:
  update = refresh package index + upgrade existing software
  install = add packages/tools that may not exist yet
USAGE
}

# ---------- Small helper functions ----------
log() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }
err() { printf '[ERROR] %s\n' "$*"; }
line() { printf '%s\n' "------------------------------------------------------------"; }

run_cmd() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[DRY-RUN] %s\n' "$*"
  else
    bash -lc "$*"
  fi
}

ask_yes_no() {
  # ask_yes_no "Question text" "default" -> returns 0=yes, 1=no
  local question="$1"
  local default="${2:-n}"
  local answer=""

  if [[ "$AUTO_YES" == "1" ]]; then
    log "$question [auto-yes enabled -> y]"
    return 0
  fi

  if [[ "$SKIP_PROMPTS" == "1" ]]; then
    log "$question [prompts skipped -> default=$default]"
    [[ "$default" == "y" ]] && return 0 || return 1
  fi

  while true; do
    read -r -p "$question [y/n] (default: $default): " answer
    answer="${answer:-$default}"
    case "${answer,,}" in
      y|yes) return 0 ;;
      n|no) return 1 ;;
      *) warn "Please type y or n." ;;
    esac
  done
}

# ---------- Stage 1: Connection check ----------
check_connection() {
  line
  log "Stage 1: Checking internet connection"

  if [[ "$SKIP_INTERNET_CHECK" == "1" ]]; then
    warn "Internet check skipped (SKIP_INTERNET_CHECK=1)."
    return 0
  fi

  if ping -c 2 -W 2 "$INTERNET_CHECK_HOST" >/dev/null 2>&1; then
    log "Internet is reachable via $INTERNET_CHECK_HOST. Continuing with setup."
    return 0
  fi

  err "Something went wrong with internet. Skipping all stages."
  return 1
}

# ---------- Detect distro/package manager ----------
DISTRO_ID="unknown"
DISTRO_VERSION="unknown"
PKG_MANAGER=""

detect_linux() {
  line
  log "Stage 2: Detecting Linux distribution/version"

  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    DISTRO_ID="${ID:-unknown}"
    DISTRO_VERSION="${VERSION_ID:-unknown}"
  fi

  case "$DISTRO_ID" in
    ubuntu|debian) PKG_MANAGER="apt" ;;
    centos|rhel|fedora|rocky|almalinux) PKG_MANAGER="dnf" ;;
    arch) PKG_MANAGER="pacman" ;;
    *) PKG_MANAGER="unsupported" ;;
  esac

  log "Detected distro: $DISTRO_ID"
  log "Detected version: $DISTRO_VERSION"
  log "Detected package manager: $PKG_MANAGER"
}

run_updates() {
  line
  log "Stage 2A: Update/upgrade/full-upgrade"
  log "Short note: update/upgrade refreshes and updates existing software."

  if ! ask_yes_no "Do you want to start update/upgrade/full-upgrade?" "n"; then
    log "Skipped update stage by user choice."
    return 0
  fi

  case "$PKG_MANAGER" in
    apt)
      run_cmd "sudo apt update"
      run_cmd "sudo apt upgrade -y"
      run_cmd "sudo apt full-upgrade -y"
      ;;
    dnf)
      run_cmd "sudo dnf check-update || true"
      run_cmd "sudo dnf upgrade --refresh -y"
      ;;
    pacman)
      run_cmd "sudo pacman -Syu --noconfirm"
      ;;
    *) warn "Unsupported distro for auto update commands." ;;
  esac
}

install_minimal_packages() {
  line
  log "Stage 3: Install minimal packages"
  log "Short note: install adds new tools (if missing)."

  if ! ask_yes_no "Install minimal package set (curl, wget, git, vim, htop)?" "y"; then
    log "Skipped minimal package stage."
    return 0
  fi

  case "$PKG_MANAGER" in
    apt) run_cmd "sudo apt install -y curl wget git vim htop" ;;
    dnf) run_cmd "sudo dnf install -y curl wget git vim htop" ;;
    pacman) run_cmd "sudo pacman -S --noconfirm curl wget git vim htop" ;;
    *) warn "Unsupported distro for package installation." ;;
  esac
}

install_full_packages() {
  line
  log "Stage 4: Install full package set"
  log "Includes developer tools and Python runtime/pip for automation scripts."

  if ! ask_yes_no "Install full package set (build tools + utils + Python)?" "n"; then
    log "Skipped full package stage."
    return 0
  fi

  case "$PKG_MANAGER" in
    apt)
      run_cmd "sudo apt install -y build-essential net-tools unzip zip tmux tree jq python3 python3-pip python3-venv"
      ;;
    dnf)
      run_cmd "sudo dnf groupinstall -y 'Development Tools' || true"
      run_cmd "sudo dnf install -y net-tools unzip zip tmux tree jq python3 python3-pip"
      ;;
    pacman)
      run_cmd "sudo pacman -S --noconfirm base-devel net-tools unzip zip tmux tree jq python python-pip"
      ;;
    *) warn "Unsupported distro for package installation." ;;
  esac
}

show_system_info() {
  line
  log "Stage 5: System specs, memory, disk"

  if ! ask_yes_no "Show system specs/space information now?" "y"; then
    log "Skipped system info stage."
    return 0
  fi

  echo "Hostname: $(hostname)"
  echo "Kernel:   $(uname -r)"
  echo "CPU:"
  lscpu | sed -n '1,8p'
  echo
  echo "Memory:"
  free -h
  echo
  echo "Disk:"
  df -h
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  if [[ "$PIPELINE_MODE" == "1" ]]; then
    SKIP_PROMPTS=1
    DRY_RUN=1
    log "PIPELINE_MODE=1 detected -> SKIP_PROMPTS=1 and DRY_RUN=1 enabled"
  fi

  log "Starting $SCRIPT_NAME"

  if ! check_connection; then
    exit 1
  fi

  detect_linux
  run_updates
  install_minimal_packages
  install_full_packages
  show_system_info

  line
  log "Automation finished."
}

main "$@"
