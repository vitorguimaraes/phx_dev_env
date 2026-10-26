#!/bin/bash

printf "\nInstalling Docker...\n"

sudo apt install ca-certificates curl gnupg -y

sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
| sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo docker run hello-world

# docker cli config (only if it doesn't exist, to avoid breaking an existing one)
mkdir -p $HOME/.docker
if [[ ! -f $HOME/.docker/config.json ]]; then
  echo '{' > $HOME/.docker/config.json
  echo '"psFormat": "\\nName: \\t\\t{{.Names}}\\tCommand: {{.Command}}\\nNetworks: \\t{{.Networks}}\\nRunningFor: \\t{{.RunningFor}}\\nPorts: \\t\\t{{.Ports}}"' >> $HOME/.docker/config.json
  echo '}' >> $HOME/.docker/config.json
fi

sudo usermod -aG docker $USER

clear

if command -v docker >/dev/null && sudo docker compose version >/dev/null 2>&1; then
  docker --version
  sudo docker compose version
  printf "Docker and Docker Compose installed!\n"
else
  printf "Docker installation failed!\n"
  exit 1
fi
printf "\n*******************************************************************\n"
