#!/usr/bin/env bash
# Beginner-friendly Linux setup automation
# Flow:
# 1) Ping check
# 2) Update system
# 3) Minimal packages
# 4) Full packages
# 5) System info + short success summary

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
AUTO_YES="${AUTO_YES:-0}"               # AUTO_YES=1 -> answer yes on all checkpoints
SKIP_PROMPTS="${SKIP_PROMPTS:-0}"       # SKIP_PROMPTS=1 -> no checkpoints, use NON_INTERACTIVE_DEFAULT
DRY_RUN="${DRY_RUN:-0}"                 # DRY_RUN=1 -> print commands only
PIPELINE_MODE="${PIPELINE_MODE:-0}"     # PIPELINE_MODE=1 -> CI-safe defaults
SKIP_INTERNET_CHECK="${SKIP_INTERNET_CHECK:-0}"
INTERNET_CHECK_HOST="${INTERNET_CHECK_HOST:-8.8.8.8}"

# Stage toggles (useful for CI)
RUN_UPDATE="${RUN_UPDATE:-1}"
RUN_MINIMAL="${RUN_MINIMAL:-1}"
RUN_FULL="${RUN_FULL:-1}"
SHOW_SYSTEM_INFO="${SHOW_SYSTEM_INFO:-1}"
NON_INTERACTIVE_DEFAULT="${NON_INTERACTIVE_DEFAULT:-y}" # used only with SKIP_PROMPTS=1

# Summary arrays
UPDATED_ACTIONS=()
MINIMAL_INSTALLED=()
FULL_INSTALLED=()

usage() {
  cat <<USAGE
Usage:
  ./$SCRIPT_NAME

Main environment variables:
  AUTO_YES=1            Answer yes on all checkpoints
  SKIP_PROMPTS=1        Skip checkpoints and use NON_INTERACTIVE_DEFAULT
  DRY_RUN=1             Print commands only
  PIPELINE_MODE=1       Safe CI mode (SKIP_PROMPTS=1 + DRY_RUN=1 + skip full stage)
  SKIP_INTERNET_CHECK=1 Skip ping stage in CI

Optional stage toggles:
  RUN_UPDATE=0          Skip update stage
  RUN_MINIMAL=0         Skip minimal packages stage
  RUN_FULL=0            Skip full packages stage
  SHOW_SYSTEM_INFO=0    Skip system information stage
  NON_INTERACTIVE_DEFAULT=y|n  Default answer in non-interactive mode
USAGE
}

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

checkpoint_continue() {
  # checkpoint_continue "message"
  local question="$1"
  local answer=""

  if [[ "$AUTO_YES" == "1" ]]; then
    log "$question [auto-yes -> y]"
    return 0
  fi

  if [[ "$SKIP_PROMPTS" == "1" ]]; then
    log "$question [non-interactive -> default=$NON_INTERACTIVE_DEFAULT]"
    [[ "${NON_INTERACTIVE_DEFAULT,,}" == "y" || "${NON_INTERACTIVE_DEFAULT,,}" == "yes" ]]
    return
  fi

  while true; do
    read -r -p "$question [y/n]: " answer
    case "${answer,,}" in
      y|yes) return 0 ;;
      n|no) return 1 ;;
      *) warn "Please type y or n (no default in interactive mode)." ;;
    esac
  done
}

DISTRO_ID="unknown"
DISTRO_VERSION="unknown"
PKG_MANAGER="unsupported"

detect_linux() {
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

  line
  log "Detected distro: $DISTRO_ID $DISTRO_VERSION"
  log "Package manager: $PKG_MANAGER"
}

check_connection() {
  line
  log "Stage 1: Internet check"

  if [[ "$SKIP_INTERNET_CHECK" == "1" ]]; then
    warn "Internet check skipped."
    return 0
  fi

  if ping -c 2 -W 2 "$INTERNET_CHECK_HOST" >/dev/null 2>&1; then
    log "Internet is reachable."
    return 0
  fi

  err "Internet check failed. Stopping all stages."
  return 1
}

run_updates() {
  line
  log "Stage 2: Update system"

  if [[ "$RUN_UPDATE" != "1" ]]; then
    warn "Update stage disabled (RUN_UPDATE=0)."
    return 0
  fi

  case "$PKG_MANAGER" in
    apt)
      run_cmd "sudo apt update"; UPDATED_ACTIONS+=("apt update")
      run_cmd "sudo apt upgrade -y"; UPDATED_ACTIONS+=("apt upgrade")
      run_cmd "sudo apt full-upgrade -y"; UPDATED_ACTIONS+=("apt full-upgrade")
      ;;
    dnf)
      run_cmd "sudo dnf check-update || true"; UPDATED_ACTIONS+=("dnf check-update")
      run_cmd "sudo dnf upgrade --refresh -y"; UPDATED_ACTIONS+=("dnf upgrade --refresh")
      ;;
    pacman)
      run_cmd "sudo pacman -Syu --noconfirm"; UPDATED_ACTIONS+=("pacman -Syu")
      ;;
    *) warn "Unsupported distro for update stage." ;;
  esac
}

install_minimal_packages() {
  line
  log "Stage 3: Install minimal packages"

  if [[ "$RUN_MINIMAL" != "1" ]]; then
    warn "Minimal stage disabled (RUN_MINIMAL=0)."
    return 0
  fi

  case "$PKG_MANAGER" in
    apt)
      run_cmd "sudo apt install -y curl wget git vim htop ca-certificates gnupg lsb-release software-properties-common rsync unzip"
      MINIMAL_INSTALLED+=(curl wget git vim htop ca-certificates gnupg lsb-release software-properties-common rsync unzip)
      ;;
    dnf)
      run_cmd "sudo dnf install -y curl wget git vim htop ca-certificates gnupg2 redhat-lsb-core rsync unzip"
      MINIMAL_INSTALLED+=(curl wget git vim htop ca-certificates gnupg2 redhat-lsb-core rsync unzip)
      ;;
    pacman)
      run_cmd "sudo pacman -S --noconfirm curl wget git vim htop ca-certificates gnupg lsb-release rsync unzip"
      MINIMAL_INSTALLED+=(curl wget git vim htop ca-certificates gnupg lsb-release rsync unzip)
      ;;
    *) warn "Unsupported distro for minimal stage." ;;
  esac
}

install_full_packages() {
  line
  log "Stage 4: Install full packages"

  if [[ "$RUN_FULL" != "1" ]]; then
    warn "Full stage disabled (RUN_FULL=0)."
    return 0
  fi

  case "$PKG_MANAGER" in
    apt)
      run_cmd "sudo apt install -y build-essential net-tools zip tmux tree jq python3 python3-pip python3-venv python3-dev gcc make cmake pkg-config"
      FULL_INSTALLED+=(build-essential net-tools zip tmux tree jq python3 python3-pip python3-venv python3-dev gcc make cmake pkg-config)
      ;;
    dnf)
      run_cmd "sudo dnf groupinstall -y 'Development Tools' || true"
      run_cmd "sudo dnf install -y net-tools zip tmux tree jq python3 python3-pip python3-devel gcc make cmake pkgconf-pkg-config"
      FULL_INSTALLED+=(Development-Tools net-tools zip tmux tree jq python3 python3-pip python3-devel gcc make cmake pkgconf-pkg-config)
      ;;
    pacman)
      run_cmd "sudo pacman -S --noconfirm base-devel net-tools zip tmux tree jq python python-pip cmake pkgconf"
      FULL_INSTALLED+=(base-devel net-tools zip tmux tree jq python python-pip cmake pkgconf)
      ;;
    *) warn "Unsupported distro for full stage." ;;
  esac
}

show_system_info() {
  line
  log "Stage 5: System information"

  if [[ "$SHOW_SYSTEM_INFO" != "1" ]]; then
    warn "System info stage disabled (SHOW_SYSTEM_INFO=0)."
    return 0
  fi

  echo "Hostname: $(hostname)"
  echo "Kernel:   $(uname -r)"
  echo "CPU (top lines):"
  lscpu | sed -n '1,8p'
  echo
  echo "Memory:"
  free -h
  echo
  echo "Disk:"
  df -h
}

print_summary() {
  line
  log "Succeeded install summary"
  echo "Update actions: ${UPDATED_ACTIONS[*]:-none}"
  echo "Minimal packages: ${MINIMAL_INSTALLED[*]:-none}"
  echo "Full packages: ${FULL_INSTALLED[*]:-none}"
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  if [[ "$PIPELINE_MODE" == "1" ]]; then
    SKIP_PROMPTS=1
    NON_INTERACTIVE_DEFAULT=y
    DRY_RUN=1
    SKIP_INTERNET_CHECK=1
    RUN_FULL=0
    SHOW_SYSTEM_INFO=0
    log "PIPELINE_MODE=1 -> prompts skipped, dry-run enabled, full stage off"
  fi

  log "Starting $SCRIPT_NAME"
  detect_linux

  check_connection
  checkpoint_continue "Ping passed. Continue to update stage?" || exit 0

  run_updates
  checkpoint_continue "Update stage completed. Continue to minimal packages?" || exit 0

  install_minimal_packages
  checkpoint_continue "Minimal stage completed. Continue to full packages?" || exit 0

  install_full_packages
  checkpoint_continue "Full stage completed. Continue to final output?" || exit 0

  show_system_info
  print_summary

  line
  log "Automation finished successfully."
}

main "$@"
