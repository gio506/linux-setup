# Linux Setup Beginner Bash Automation

Simple script for junior DevOps.

## What this script does (easy view)
1. Check internet with ping.
2. Detect Linux distro + package manager.
3. Update system.
4. Install minimal packages.
5. Install full packages (includes Python/dev tools).
6. Show system info.
7. Print short success summary (what was updated/installed).

If ping fails, script stops.

## Where it asks `y/n`
Prompts now appear **after each completed stage**:
- After ping test passed.
- After update stage.
- After minimal package stage.
- After full package stage.

So flow is: run stage -> ask to continue -> next stage.

## Packages
### Minimal package stage
- Ubuntu/Debian: `curl wget git vim htop ca-certificates gnupg lsb-release software-properties-common rsync unzip`
- RHEL/Fedora: `curl wget git vim htop ca-certificates gnupg2 redhat-lsb-core rsync unzip`
- Arch: `curl wget git vim htop ca-certificates gnupg lsb-release rsync unzip`

### Full package stage
- Ubuntu/Debian: `build-essential net-tools zip tmux tree jq python3 python3-pip python3-venv python3-dev gcc make cmake pkg-config`
- RHEL/Fedora: `Development Tools` + `net-tools zip tmux tree jq python3 python3-pip python3-devel gcc make cmake pkgconf-pkg-config`
- Arch: `base-devel net-tools zip tmux tree jq python python-pip cmake pkgconf`

## Run
```bash
chmod +x beginner_linux_automation.sh
./beginner_linux_automation.sh
```

## Pipeline / CI
GitHub Actions file: `.github/workflows/bash-script-check.yml`

Pipeline has separate jobs:
1. syntax check
2. help output check
3. pipeline smoke run
4. stage-toggle checks

## Useful env options
- `AUTO_YES=1` -> always continue at checkpoints.
- `SKIP_PROMPTS=1` -> no questions, use defaults.
- `DRY_RUN=1` -> print commands only, do not execute.
- `PIPELINE_MODE=1` -> CI-safe: skip prompts + dry-run + skip full/system info.
- `RUN_UPDATE=0` -> disable update stage.
- `RUN_MINIMAL=0` -> disable minimal stage.
- `RUN_FULL=0` -> disable full stage.
- `SHOW_SYSTEM_INFO=0` -> disable final system info.
- `SKIP_INTERNET_CHECK=1` -> skip ping stage (CI use).

## Short meaning
- **Update** = refresh + upgrade existing software.
- **Install** = add software packages that may be missing.
