FROM ubuntu:24.04

# Install dependencies
RUN apt-get update && apt-get upgrade -y
RUN apt-get install software-properties-common -y
RUN apt-add-repository ppa:ansible/ansible
RUN apt-get install python3 ansible sudo rsync -y

# Add sudoer user named 'docker'
RUN adduser --disabled-password --gecos '' docker
RUN adduser docker sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER docker
COPY ./ansible/ /home/docker/ansible-playbook
RUN ansible-galaxy collection install community.general && \
  ansible-playbook --connection=local --inventory 127.0.0.1, /home/docker/ansible-playbook/index.yaml --extra-vars "skip_install_node=true" && \
  sudo rm -rf /home/docker/ansible-playbook

CMD tail -f /dev/null
