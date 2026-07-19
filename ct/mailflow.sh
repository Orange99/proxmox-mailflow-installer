#!/usr/bin/env bash
# shellcheck source=/dev/null
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

APP="MailFlow"
INSTALL_REPO="${INSTALL_REPO:-Orange99/proxmox-mailflow-installer}"
HEADER_REPO="${HEADER_REPO:-${INSTALL_REPO}}"
CS_BASE_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
var_tags="${var_tags:-email;webmail}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"
var_features="${var_features:-keyctl=1,nesting=1}"

get_latest_release() {
  local release
  release="$(curl -fsSL https://api.github.com/repos/maathimself/mailflow/releases/latest \
    | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n1)"
  if [[ -z "${release}" ]]; then
    msg_warn "Could not detect latest release tag, falling back to main"
    release="main"
  fi
  printf '%s\n' "${release}"
}

show_mailflow_header() {
  clear
  if ! curl -fsSL "https://raw.githubusercontent.com/${HEADER_REPO}/main/ct/headers/mailflow"; then
    cat <<'EOF'
 __  __       _ _ _____ _
|  \/  | __ _(_) |  ___| | _____      __
| |\/| |/ _` | | | |_  | |/ _ \ \ /\ / /
| |  | | (_| | | |  _| | | (_) \ V  V /
|_|  |_|\__,_|_|_|_|   |_|\___/ \_/\_/
EOF
  fi
  echo
  _HEADER_SHOWN=1
}

set +x

show_mailflow_header
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

  RELEASE="$(get_latest_release)"

  msg_info "Updating ${APP} to ${RELEASE}"
  cd /opt/mailflow || exit 1

  $STD git fetch --all --tags --force
  if ! $STD git checkout -f "$RELEASE"; then
    msg_warn "Checkout of ${RELEASE} failed, falling back to main"
    $STD git checkout -f main
  fi

  msg_info "Rebuilding frontend"
  cd /opt/mailflow/frontend || exit 1
  $STD npm ci
  $STD npm run build

  msg_info "Updating backend dependencies"
  cd /opt/mailflow/backend || exit 1
  $STD npm ci --omit=dev

  msg_info "Restarting ${APP}"
  $STD systemctl restart mailflow

  msg_ok "Updated ${APP} to ${RELEASE}"
  exit 0
}
# Override description() – MailFlow is not in community-scripts registry yet
function description() { return 0; }

set_gui_notes() {
  local notes_html
  notes_html="$(cat <<'EOF'
<div align='center'>
  <a href='https://community-scripts.org' target='_blank' rel='noopener noreferrer'>
    <img src='https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/images/logo-81x112.png' alt='Logo' style='width:81px;height:112px;'/>
  </a>

  <h2 style='font-size: 24px; margin: 20px 0;'>MailFlow LXC</h2>

  <p style='margin: 16px 0;'>
    <a href='https://community-scripts.org/donate' target='_blank' rel='noopener noreferrer'>
      <img src='https://img.shields.io/badge/❤️-Sponsoring%20%26%20Donations-FF5E5B' alt='Sponsoring and donations' />
    </a>
  </p>

  <p style='margin: 12px 0;'>
    <a href='https://community-scripts.org/scripts/mailflow' target='_blank' rel='noopener noreferrer'>
      <img src='https://img.shields.io/badge/📦-Open%20Script%20Page-00617f' alt='Open script page' />
    </a>
  </p>

  <span style='margin: 0 10px;'>
    <i class="fa fa-github fa-fw" style="color: #f5f5f5;"></i>
    <a href='https://github.com/community-scripts/ProxmoxVE' target='_blank' rel='noopener noreferrer' style='text-decoration: none; color: #00617f;'>GitHub</a>
  </span>
  <span style='margin: 0 10px;'>
    <i class="fa fa-comments fa-fw" style="color: #f5f5f5;"></i>
    <a href='https://github.com/community-scripts/ProxmoxVE/discussions' target='_blank' rel='noopener noreferrer' style='text-decoration: none; color: #00617f;'>Discussions</a>
  </span>
  <span style='margin: 0 10px;'>
    <i class="fa fa-exclamation-circle fa-fw" style="color: #f5f5f5;"></i>
    <a href='https://github.com/community-scripts/ProxmoxVE/issues' target='_blank' rel='noopener noreferrer' style='text-decoration: none; color: #00617f;'>Issues</a>
  </span>
</div>
EOF
)"

  if ! pct set "${CTID}" -description "${notes_html}" >/dev/null 2>&1; then
    msg_warn "Could not set Proxmox GUI notes automatically"
  fi
}

enable_noop_official_install_fetch() {
  curl() {
    local last_arg="${!#}"
    local install_slug="${var_install:-mailflow}"
    local official_install_url="${CS_BASE_URL}/install/${install_slug}.sh"
    if [[ "${last_arg}" == "${official_install_url}" ]]; then
      printf ':\n'
      return 0
    fi
    command curl "$@"
  }
}

resolve_container_ip() {
  IP="${IP:-$(pct exec "${CTID}" -- hostname -I 2>/dev/null | awk '{print $1}')}"
  if [[ -z "${IP}" ]]; then
    msg_warn "Could not determine container IP automatically"
    IP="<check-container-ip>"
  fi
}

prepare_installer_files() {
  msg_info "Preparing ${APP} installer"
  curl -fsSL "${CS_BASE_URL}/misc/install.func" \
    | pct exec "${CTID}" -- bash -c "cat > /tmp/install.func"
  curl -fsSL "https://raw.githubusercontent.com/${INSTALL_REPO}/main/install/mailflow-install.sh" \
    | pct exec "${CTID}" -- bash -c "cat > /tmp/mailflow-install.sh"
  msg_ok "Prepared ${APP} installer"
}

run_container_installer() {
  msg_info "Running ${APP} installer in container (takes a few minutes)"
  if lxc-attach -n "${CTID}" -- bash -c '
    export FUNCTIONS_FILE_PATH="$(cat /tmp/install.func)"
    bash /tmp/mailflow-install.sh
    _exit=$?
    rm -f /tmp/install.func /tmp/mailflow-install.sh
    exit $_exit
  '; then
    msg_ok "${APP} installer finished"
  else
    msg_error "${APP} installer failed with exit code $?"
    exit 1
  fi
}

start

# build_container creates + customizes the LXC container.
# Important: do not redirect stderr here - whiptail renders on stderr and would
# otherwise appear to "hang" during advanced storage selection.
# A 404 from the official install-script fetch is expected for external apps.
# We intercept only that one URL and return a harmless no-op script.
enable_noop_official_install_fetch
build_container
unset -f curl

# build_container sets $IP from DHCP; fall back to querying the container
# if it was not set (happens when the official install script is missing).
resolve_container_ip
set_gui_notes

# --- Run our own install script -------------------------------------------
# build_container ran an empty script (404); we now push install.func and our
# install script into the container and execute it via lxc-attach.
prepare_installer_files
run_container_installer

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}https://${IP}${CL}"
echo -e "${INFO}${YW}Frontend login:${CL}"
echo -e "${TAB}${YWB}No default username/password.${CL}"
echo -e "${TAB}${YWB}Register the first account in the UI (first account becomes admin).${CL}"
