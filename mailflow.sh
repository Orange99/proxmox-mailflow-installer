#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2026 community-scripts ORG
# Author: Pascal
# License: MIT

APP="MailFlow"
var_tags="${var_tags:-adblock}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-15}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"

header_info "$APP"

function default_settings() {
  CT_TYPE="0"
  PW=""
  CT_ID=$NEXTID
  HOSTNAME="mailflow"
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRIDGE="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIPV6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERBOSE="no"
}

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/mailflow ]]; then
    msg_error "MailFlow installation not found"
    exit 1
  fi

  msg_info "Updating MailFlow"

  cd /opt/mailflow || exit 1
  docker compose pull
  docker compose up -d

  msg_ok "MailFlow updated"
  exit 0
}

start
build_container

msg_info "Updating Debian"
apt-get update
apt-get -y upgrade
msg_ok "System updated"

msg_info "Installing dependencies"
apt-get install -y \
  curl \
  git \
  openssl \
  ca-certificates \
  docker.io \
  docker-compose-plugin
msg_ok "Dependencies installed"

mkdir -p /opt/mailflow
cd /opt/mailflow

msg_info "Downloading MailFlow"

curl -fsSLo docker-compose.yml \
https://raw.githubusercontent.com/maathimself/mailflow/main/docker-compose.ghcr.yml

curl -fsSLo .env \
https://raw.githubusercontent.com/maathimself/mailflow/main/.env.example

msg_ok "Downloaded"

SESSION_SECRET=$(openssl rand -hex 32)
DB_PASSWORD=$(openssl rand -hex 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)

IP=$(hostname -I | awk '{print $1}')

sed -i "s|^SESSION_SECRET=.*|SESSION_SECRET=${SESSION_SECRET}|" .env
sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=${DB_PASSWORD}|" .env
sed -i "s|^ENCRYPTION_KEY=.*|ENCRYPTION_KEY=${ENCRYPTION_KEY}|" .env
sed -i "s|^APP_URL=.*|APP_URL=https://${IP}|" .env

msg_info "Starting MailFlow"

docker compose up -d

msg_ok "Containers started"

description

msg_ok "Completed Successfully!"

echo
echo "MailFlow should become available at:"
echo
echo "https://${IP}"
echo