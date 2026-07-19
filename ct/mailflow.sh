#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2026 community-scripts ORG
# Author: Pascal
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://mailflow.sh/

APP="MailFlow"
var_tags="${var_tags:-email;docker}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-0}"
var_features="${var_features:-keyctl=1,nesting=1}"

header_info "$APP"
variables
color
catch_errors

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
  echo_default
}

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/mailflow ]]; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/maathimself/mailflow/releases/latest | grep '"tag_name"' | sed 's/.*"tag_name": "\(.*\)".*/\1/')

  msg_info "Stopping ${APP}"
  cd /opt/mailflow
  docker compose down
  msg_ok "Stopped ${APP}"

  msg_info "Updating ${APP} to ${RELEASE}"
  docker compose pull
  docker compose up -d
  msg_ok "Updated ${APP} to ${RELEASE}"

  msg_info "Cleaning up Docker images"
  docker image prune -f &>/dev/null
  msg_ok "Cleaned up old images"

  exit 0
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been completed successfully!${CL}
${INFO}${YW} Access it using the following URL:${CL}
${TAB}${GATEWAY}${BGN}https://$(pct exec "$CTID" -- hostname -I | awk '{print $1}')${CL}"

