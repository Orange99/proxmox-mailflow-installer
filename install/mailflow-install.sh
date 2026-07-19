#!/usr/bin/env bash

# Copyright (c) 2026 community-scripts ORG
# Author: Pascal
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://mailflow.sh/

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  git \
  openssl \
  ca-certificates \
  gnupg \
  lsb-release \
  apt-transport-https
msg_ok "Installed Dependencies"

msg_info "Installing Docker"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list
$STD apt-get update
$STD apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin
systemctl enable --now docker
msg_ok "Installed Docker"

msg_info "Setting up MailFlow"
mkdir -p /opt/mailflow
cd /opt/mailflow || exit 1

RELEASE=$(curl -fsSL https://api.github.com/repos/maathimself/mailflow/releases/latest \
  | grep '"tag_name"' | sed 's/.*"tag_name": "\(.*\)".*/\1/')

curl -fsSLo docker-compose.yml \
  https://raw.githubusercontent.com/maathimself/mailflow/${RELEASE}/docker-compose.ghcr.yml 2>/dev/null \
  || curl -fsSLo docker-compose.yml \
  https://raw.githubusercontent.com/maathimself/mailflow/main/docker-compose.ghcr.yml

curl -fsSLo .env \
  https://raw.githubusercontent.com/maathimself/mailflow/${RELEASE}/.env.example 2>/dev/null \
  || curl -fsSLo .env \
  https://raw.githubusercontent.com/maathimself/mailflow/main/.env.example
msg_ok "Downloaded MailFlow ${RELEASE}"

msg_info "Configuring MailFlow"
SESSION_SECRET=$(openssl rand -hex 32)
DB_PASSWORD=$(openssl rand -hex 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)
IP=$(hostname -I | awk '{print $1}')

sed -i "s|^SESSION_SECRET=.*|SESSION_SECRET=${SESSION_SECRET}|" .env
sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=${DB_PASSWORD}|" .env
sed -i "s|^ENCRYPTION_KEY=.*|ENCRYPTION_KEY=${ENCRYPTION_KEY}|" .env
sed -i "s|^APP_URL=.*|APP_URL=https://${IP}|" .env

# Persist version for update tracking
echo "${RELEASE}" >/opt/mailflow/version.txt
msg_ok "Configured MailFlow"

msg_info "Starting MailFlow"
docker compose up -d
msg_ok "Started MailFlow"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get autoremove -y
$STD apt-get autoclean -y
msg_ok "Cleaned"

