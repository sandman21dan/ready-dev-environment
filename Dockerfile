FROM ubuntu:20.04

# Install dependencies
RUN apt-get update && apt-get upgrade -y
RUN apt-get install software-properties-common -y
RUN apt-add-repository ppa:ansible/ansible
RUN apt-get install python ansible sudo -y

# Add sudoer user named 'docker'
RUN adduser --disabled-password --gecos '' docker
RUN adduser docker sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER docker
COPY ./ansible/ /home/docker/ansible-playbook
RUN ansible-galaxy collection install community.general && \
  ansible-playbook --connection=local --inventory 127.0.0.1, /home/docker/ansible-playbook/index.yaml && \
  sudo rm -rf /home/docker/ansible-playbook

ENTRYPOINT tail -f /dev/null
