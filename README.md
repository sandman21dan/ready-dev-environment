# ready-dev-environment
A docker image with common dev dependencies installed such as git, nvm,
python and a nice shell (ZSH) environment

It also contains an automated setup if you want to install these utilities into
a machine rather than a container

This is based on my personal development preferences and is very opinionated

## Docker usage

## Local usage

To get the automated setup running locally, `Ansible` must already be installed, check
[here](https://docs.ansible.com/ansible/2.5/installation_guide/intro_installation.html) for a guide

To run locally run the following command:

```sh
ansible-playbook --connection=local --inventory 127.0.0.1, index.yaml
```

currently `apt` is the package manager that is supported but others can be easily swapped
