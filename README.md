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
- git
- wget
- nvm
- goenv
- jenv
- Nice default for vim
- Python build dependencies
- pyenv
- pipenv
- [ag](https://github.com/ggreer/the_silver_searcher)
- Common database drivers

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
docker-compose up -d
```

```sh
docker exec -it dev zsh
```

## Local usage

To get the automated setup running locally, `Ansible` must already be installed, check
[here](https://docs.ansible.com/ansible/2.5/installation_guide/intro_installation.html) for a guide

To run locally run the following commands:

```sh
ansible-galaxy collection install community.general
ansible-playbook --connection=local --inventory 127.0.0.1, index.yaml
```

There's some variables that can be used to customise what gets installed or for which OS

* `sql_server_deps`: default `false`

    Whether to install MS SQL Server drivers
    Linux only
* `python_version`: default `3.10.6`
* `skip_install_python`: default `false`

    Skips installing python but will still install pyenv
* `os`: default `linux`

    Options are `linux` and `macos`
* `wsl`: default `false`

    WSL toggle, adds scripts for pbcopy and pbpaste
    that work against Windows

### MacOs

For usage in MacOS the following commands needs to be run:

```sh
ansible-galaxy collection install community.general
ansible-playbook --connection=local --inventory 127.0.0.1, index.yaml --extra-vars "os=macos"
```

currently `apt` and `brew` are the supported package managers but others can be easily swapped

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
