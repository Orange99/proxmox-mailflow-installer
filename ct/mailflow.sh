#!/usr/bin/env bash
# shellcheck source=/dev/null
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2026 community-scripts ORG
# Author: Pascal
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://mailflow.sh/

APP="MailFlow"
var_tags="${var_tags:-email;webmail;native}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-0}"
var_features="${var_features:-keyctl=1,nesting=1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/mailflow ]]; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/maathimself/mailflow/releases/latest | grep '"tag_name"' | sed 's/.*"tag_name": "\(.*\)".*/\1/')

  msg_info "Updating ${APP} to ${RELEASE}"
  cd /opt/mailflow || exit 1

  git fetch --all --tags --force
  git checkout -f "$RELEASE" 2>/dev/null || git checkout -f main

  msg_info "Rebuilding frontend"
  cd /opt/mailflow/frontend || exit 1
  npm ci
  npm run build

  msg_info "Updating backend dependencies"
  cd /opt/mailflow/backend || exit 1
  npm ci --omit=dev

  msg_info "Restarting ${APP}"
  systemctl restart mailflow

  msg_ok "Updated ${APP} to ${RELEASE}"
  exit 0
}

start
build_container

IP=$(pct exec "$CTID" -- hostname -I | awk '{print $1}')

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}https://${IP}${CL}"

