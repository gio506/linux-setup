# Linux Setup Beginner Bash Automation

Simple script for junior DevOps.

## Quick answer to your questions
- **On local computer**: script asks `y/n` at each checkpoint (no auto default in interactive mode).
- **In pipeline**: yes, you can use defaults only in pipeline with non-interactive mode.

## What this script does (easy view)
1. Check internet with ping.
2. Detect Linux distro + package manager.
3. Update system.
4. Install minimal packages.
5. Install full packages (includes Python/dev tools).
6. Show system info.
7. Print short success summary (updated + installed list).

If ping fails, script stops.

## Where it asks `y/n`
Prompts appear **after each completed stage**:
- After ping test passed.
- After update stage.
- After minimal package stage.
- After full package stage.

Flow: run stage -> ask continue -> next stage.

## Quick start (how to use)
1. Give execute permission:
   ```bash
   chmod +x beginner_linux_automation.sh
   ```
2. Run script:
   ```bash
   ./beginner_linux_automation.sh
   ```

## Pipeline / CI (default only in pipeline)
GitHub Actions file: `.github/workflows/bash-script-check.yml`

Recommended pipeline command:
```bash
SKIP_PROMPTS=1 NON_INTERACTIVE_DEFAULT=y DRY_RUN=1 SKIP_INTERNET_CHECK=1 ./beginner_linux_automation.sh
```

Or simple mode:
```bash
PIPELINE_MODE=1 ./beginner_linux_automation.sh
```

## Packages
### Minimal package stage
- Ubuntu/Debian: `curl wget git vim htop ca-certificates gnupg lsb-release software-properties-common rsync unzip`
- RHEL/Fedora: `curl wget git vim htop ca-certificates gnupg2 redhat-lsb-core rsync unzip`
- Arch: `curl wget git vim htop ca-certificates gnupg lsb-release rsync unzip`

### Full package stage
- Ubuntu/Debian: `build-essential net-tools zip tmux tree jq python3 python3-pip python3-venv python3-dev gcc make cmake pkg-config`
- RHEL/Fedora: `Development Tools` + `net-tools zip tmux tree jq python3 python3-pip python3-devel gcc make cmake pkgconf-pkg-config`
- Arch: `base-devel net-tools zip tmux tree jq python python-pip cmake pkgconf`

## Useful options
- `AUTO_YES=1` -> always continue at checkpoints.
- `SKIP_PROMPTS=1` -> no questions (non-interactive).
- `NON_INTERACTIVE_DEFAULT=y|n` -> default answer only for non-interactive mode.
- `DRY_RUN=1` -> print commands only.
- `PIPELINE_MODE=1` -> CI-safe preset.
- `RUN_UPDATE=0` / `RUN_MINIMAL=0` / `RUN_FULL=0` / `SHOW_SYSTEM_INFO=0` -> stage toggles.
- `SKIP_INTERNET_CHECK=1` -> skip ping stage (CI use).
