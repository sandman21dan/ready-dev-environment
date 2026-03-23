# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a development environment setup repository that creates Docker containers and Ansible playbooks for installing common development tools and configurations. It provides both containerized and local installation methods for a pre-configured development environment.

## Core Architecture

- **Dockerfile**: Creates Ubuntu 24.04 container with Ansible, adds `docker` user with sudo privileges
- **docker-compose.yaml**: Orchestrates dev container with volume mounts (`~/development`, `~/.ssh`) and port 1234 forwarding
- **ansible/index.yaml**: Main playbook that detects OS/platform and installs tools via apt/brew
- **ansible/roles/**: Modular roles for asdf (language management), git plugins, neovim, and fabric AI
- **ansible/templates/**: Shell and editor configuration files (zshrc, vimrc, tmux.conf)
- **ansible/scripts/**: Text processing utilities installed to `~/.local/scripts/`

## Commands

### Build and Development
```bash
# Lint YAML files
make lint
make format

# Docker-based linting (no local dependencies)
make lint-with-docker
make format-with-docker

# Multi-platform Docker builds
docker buildx build --platform linux/amd64,linux/arm64 -t ready-dev-environment:latest .
```

### Container Usage
```bash
# Run with docker-compose (recommended)
docker compose up -d
docker compose exec -it dev zsh

# Direct usage
docker run -d --name dev sandman21dan/ready-dev-environment
docker exec -it dev zsh
```

### Local Installation
```bash
# Install Ansible dependencies and run locally
ansible-galaxy collection install community.general
ansible-playbook --connection=local --inventory 127.0.0.1, ansible/index.yaml
```

## Key Configuration Details

### Language Management (asdf)
- Downloads platform-specific asdf binary (Linux AMD64/ARM64)
- Installs plugins for Python, Node.js, Java, Go, Terraform, AWS CLI
- Auto-detects latest stable Python version when `python_version: "latest"`
- Uses `.default-npm-packages` template for global npm packages

### Platform Detection
- `wsl` variable: Detects WSL by checking for "microsoft" in kernel name
- `shorthand_arch`: Maps `x86_64` to `amd64`, `aarch64`/`arm64` to `arm64`
- Separate dependency lists for apt vs brew package managers

### Git Enhancements
- Installs git-fire and git-open utilities to `~/.local/bin/`
- Configures diff-so-fancy for enhanced git diff output
- Sets up color schemes and pager configuration globally

### Variables
- `python_version`: default "latest" (auto-detects stable release)
- `skip_install_python`: default false
- `node_version`: default "latest"
- `skip_install_node`: default false
- `sql_server_deps`: default false

## Utility Scripts
Text processing tools in `ansible/scripts/`:
- `calculate_percentage_difference.py`: Calculates percentage differences
- `camel_to_snake_converter.py`: Converts camelCase to snake_case
- `extract_from_json_lines.py`: Extracts fields from JSON Lines
- `join_lines.py`: Joins multiple lines into single line
- `minute_padding.py`: Time formatting utility
- `split_to_lines.py`: Splits input into multiple lines
- `timestamp_diff.py`: Calculates timestamp differences