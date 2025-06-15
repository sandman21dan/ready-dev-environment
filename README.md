![Build](https://github.com/sandman21dan/ready-dev-environment/workflows/Publish%20Docker/badge.svg?branch=master)
# ready-dev-environment
A docker image with common dev dependencies installed such as git, nvm,
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
- Python build dependencies
- [ag](https://github.com/ggreer/the_silver_searcher)
- Common database drivers
- [Fabric](https://github.com/danielmiessler/fabric)

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

To run locally run the following commands:

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
