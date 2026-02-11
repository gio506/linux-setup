# Linux Setup Beginner Bash Automation

Simple automation for junior DevOps practice.

## Short script details
Script: `beginner_linux_automation.sh`

- Stage 1: check internet with ping.
- Stage 2: detect distro/version + ask update/upgrade/full-upgrade.
- Stage 3: ask and install minimal tools.
- Stage 4: ask and install full tools **including Python**.
- Stage 5: ask and print CPU/RAM/disk info.

If internet check fails, script stops and prints a clear error.

## Quick checklist (what happens when you run it)
- [ ] Start script and print basic info.
- [ ] Stage 1: Check internet (ping).
  - If failed -> stop all next stages.
- [ ] Stage 2: Detect distro/version and package manager.
- [ ] Stage 2A: Ask to run update/upgrade/full-upgrade.
- [ ] Stage 3: Ask to install minimal packages (`curl`, `wget`, `git`, `vim`, `htop`).
- [ ] Stage 4: Ask to install full packages (build + utility tools + Python).
  - Ubuntu/Debian: `build-essential`, `net-tools`, `unzip`, `zip`, `tmux`, `tree`, `jq`, `python3`, `python3-pip`, `python3-venv`
  - RHEL/Fedora: `Development Tools` group, `net-tools`, `unzip`, `zip`, `tmux`, `tree`, `jq`, `python3`, `python3-pip`
  - Arch: `base-devel`, `net-tools`, `unzip`, `zip`, `tmux`, `tree`, `jq`, `python`, `python-pip`
  - Note: this is heavier than minimal install and can take more time.
- [ ] Stage 5: Ask to show system specs (CPU/RAM/disk).
- [ ] Finish and print completion message.

## What is **update** vs **install**?
- **Update/Upgrade**: refresh package metadata + upgrade already-installed software.
- **Install**: add new packages/tools not currently installed.

## Pipeline (GitHub Actions)
A ready workflow is included:
- `.github/workflows/bash-script-check.yml`

It checks:
1. Bash syntax (`bash -n`)
2. Help output
3. Pipeline-mode execution in safe dry-run

Workflow command used for run stage:
```bash
SKIP_INTERNET_CHECK=1 PIPELINE_MODE=1 ./beginner_linux_automation.sh
```

Why `SKIP_INTERNET_CHECK=1`?
- CI environments can block external ping.
- This lets pipeline test all script stages logic safely.

## Run locally
```bash
chmod +x beginner_linux_automation.sh
./beginner_linux_automation.sh
```

## Help
```bash
./beginner_linux_automation.sh --help
```

## Important options
- `AUTO_YES=1` -> force yes for all questions.
- `SKIP_PROMPTS=1` -> use stage defaults (y/n) without asking.
- `DRY_RUN=1` -> print commands only.
- `PIPELINE_MODE=1` -> `SKIP_PROMPTS=1` + `DRY_RUN=1`.
- `SKIP_INTERNET_CHECK=1` -> skip ping stage (good for CI).
