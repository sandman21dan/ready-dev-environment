![Build](https://github.com/sandman21dan/ready-dev-environment/workflows/Publish%20Docker/badge.svg?branch=master)
# ready-dev-environment
A docker image with common dev dependencies installed such as git, asdf,
python and a nice shell (ZSH) environment

It also contains an automated setup if you want to install these utilities into
a machine rather than a container

This is based on my personal development preferences and is very opinionated

## What does it have?

- Pre-configured ZSH
- Pre-configured tmux
- `pbpaste` and `pbcopy` for Mac, Linux and WSL2
- git
- wget
- asdf
- Nice default for vim
- NeoVim configured with its native LSP client (pyright, ruff, gopls, lua-language-server, TypeScript and Svelte)
- Python build dependencies
- [ag](https://github.com/ggreer/the_silver_searcher)
- Common database drivers
- Claude Code and the Antigravity CLI
- `my-scripts`, a small CLI that runs my helper scripts from anywhere (see [Helper scripts](#helper-scripts))

## Docker usage

To run it in a useful manner I'd suggest starting this image with
`docker-compose` to make it sharing volumes and exposing ports
easier, as reference you can use [this](./docker-compose.yaml) docker-compose.yaml file

If you just want to try the image, you can start it by running:

```sh
docker run -d --name dev sandman21dan/ready-dev-environment
```

Then to attach to it

```sh
docker exec -it dev zsh
```

### docker-compose

To run with docker compose, I would recommend using a file similar
to the one provided [here](./docker-compose.yaml) so the home directory
can be persisted after you stop or restart the container

The commands to run are the following:

```sh
docker compose up -d
```

```sh
docker compose exec -it dev zsh
```

## Building the image locally

You can build the Docker image locally using Docker Buildx for multi-platform support:

### Build for AMD64 (x86_64)
```sh
docker buildx build --platform linux/amd64 -t ready-dev-environment:amd64 .
```

### Build for ARM64 (Apple Silicon/M1/M2)
```sh
docker buildx build --platform linux/arm64 -t ready-dev-environment:arm64 .
```

### Build for both architectures
```sh
docker buildx build --platform linux/amd64,linux/arm64 -t ready-dev-environment:latest .
```

**Note:** Multi-platform builds require Docker Buildx to be enabled. You can enable it with:
```sh
docker buildx create --use
```

## Local usage

To get the automated setup running locally, `Ansible` must already be installed, check
[here](https://docs.ansible.com/ansible/2.5/installation_guide/intro_installation.html) for a guide

To run locally run the following commands from the `ansible/` directory:

```sh
ansible-galaxy collection install community.general
ansible-playbook --connection=local --inventory 127.0.0.1, index.yaml
```

There's some variables that can be used to customise what gets installed

* `python_version`: default `latest`
* `skip_install_python`: default `false`
* `node_version`: default `latest`
* `skip_install_node`: default `false`

currently `apt` and `brew` are the supported package managers but others can be easily swapped or added

### Running only part of it

Every task and role is tagged, so you don't have to redo the whole setup to change one thing. For example, to
redeploy just the helper scripts:

```sh
ansible-playbook --connection=local --inventory 127.0.0.1, --tags scripts index.yaml
```

Run `ansible-playbook --list-tags index.yaml` for the full list. The useful ones:

| Tag | What it runs |
| --- | --- |
| `packages` | apt / brew dependencies |
| `asdf`, `git`, `neovim`, `language-servers` | that role only |
| `ai-tools` | Claude Code, the Antigravity CLI and the language servers |
| `scripts` | deploy `~/.local/scripts` and the generated `update.sh` |
| `my-scripts` | build and install the `my-scripts` CLI (and the compiled tools below) |
| `tools` | build only the compiled tools in `roles/my-scripts/files/tools/` |
| `zsh`, `vim`, `tmux` | that part of the shell/editor setup |
| `dotfiles` | only the config files: zshrc, vimrc, tmux.conf, nvim config and `update.sh` |

`my-scripts` also installs the latest Go. To rebuild the CLI without touching your Go version, use
`--tags my-scripts --skip-tags go-toolchain`.

**Heads up:** `dotfiles`, `zsh`, `vim` and `tmux` overwrite `~/.zshrc`, `~/.vimrc` and `~/.tmux.conf` with the
templates from this repo. They are meant for setting up a new machine, not for re-running on one you've customised.

## Helper scripts

The playbook installs a small CLI, `my-scripts`, that exposes everything in `~/.local/scripts` as a subcommand:

```sh
my-scripts                      # list the available scripts and what they do
my-scripts join_lines --help    # run one, arguments and stdin pass straight through
my-scripts update               # update brew/apt packages, oh-my-zsh, npm globals and code assistants
```

A script's exit status is passed through, so it is safe in `&&` chains and pipelines.

To add your own:

- **Plain scripts** (`.py`, `.sh`, `.js`): put them in `ansible/scripts/` and add a `# @description: ...` line near the
  top, which becomes the help text. Redeploy with `--tags scripts`.
- **Compiled tools** (Go or Rust): put the source in `ansible/roles/my-scripts/files/tools/<name>/`. Each machine builds
  its own binary because binaries are platform specific and never committed. Build with `--tags tools`, see the
  [README in that folder](./ansible/roles/my-scripts/files/tools/README.md).

`update` is generated from `ansible/templates/update.sh.j2`, since macOS uses brew and Linux/WSL use apt with a sudo
prompt. Edit the template rather than the deployed file.

## How does it work?

Everything is built via an ansible playbook to make dependencies
repeatable and consistent, this also achieves the ability to
install these dependencies on a computer outside of docker, such as a server
or your local development PC/mac

## Why?

I created this after hearing about the upcoming WSL 2 being a big time user of the current
iteration of the WSL and got inspired into creating a VM based (VM through docker on Windows)
so I could have an idea of how the WSL 2 would work in terms of performance and usability

Turns out this is actually quite usable, portable and takes very little time to set up!

By using the compose file you can quickly add more volumes you'd want to share with your
host computer or open ports for projects you might be running inside your
container (like web-servers or such)
