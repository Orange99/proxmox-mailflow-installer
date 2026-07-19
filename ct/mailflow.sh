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

# Override description() – not in community-scripts registry, suppresses API 404
function description() { return 0; }

start
# build_container creates and customizes the LXC; the install-script fetch will
# 404 (we are not in the official repo) and run empty – that is expected here.
# Suppress only that specific curl error line to keep output clean.
build_container 2> >(grep -v 'The requested URL returned error' >&2)

# Run our own install script explicitly via lxc-attach, with install.func injected
msg_info "Preparing ${APP} installer"
curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/install.func \
  | pct exec "$CTID" -- bash -c "cat > /tmp/install.func"
curl -fsSL https://raw.githubusercontent.com/Orange99/proxmox-mailflow-installer/main/install/mailflow-install.sh \
  | pct exec "$CTID" -- bash -c "cat > /tmp/mailflow-install.sh; chmod +x /tmp/mailflow-install.sh"
msg_ok "Prepared ${APP} installer"

msg_info "Running ${APP} installer in container (this may take several minutes)"
lxc-attach -n "$CTID" -- bash -c '
  export FUNCTIONS_FILE_PATH="$(cat /tmp/install.func)"
  bash /tmp/mailflow-install.sh
  rm -f /tmp/install.func /tmp/mailflow-install.sh
'
msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}https://${IP}${CL}"

