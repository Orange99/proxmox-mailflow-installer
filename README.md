# MailFlow LXC Installer for Proxmox VE

> **Community-Scripts-style installer for [MailFlow](https://mailflow.sh/) on Proxmox VE.**  
> **Native installation** (no Docker) — Node.js, PostgreSQL, Redis, nginx  
> Follows the conventions of [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE).

---

## 🚀 One-Line Install

Run this command **directly on your Proxmox host** in the shell:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Orange99/proxmox-mailflow-installer/main/ct/mailflow.sh)"
```

> If you fork this repo, replace `Orange99` with your GitHub username in the URL.

---

## 📦 What gets installed

| Component | Details |
|-----------|---------|
| **OS** | Debian 12 (Bookworm) LXC |
| **Node.js** | v20 (latest LTS) |
| **PostgreSQL** | v16 (database) |
| **Redis** | v7 (session store) |
| **nginx** | Reverse proxy + TLS termination |
| **MailFlow** | Latest release from [maathimself/mailflow](https://github.com/maathimself/mailflow) |
| **Auto-secrets** | `SESSION_SECRET`, `DB_PASSWORD`, `ENCRYPTION_KEY` generated with `openssl rand` |

**Default LXC resources:**

| Resource | Default |
|----------|---------|
| CPU cores | 1 |
| RAM | 1024 MB |
| Disk | 8 GB |
| Network | DHCP on vmbr0 |
| Container type | **Privileged** (for systemd/TTY) |
| LXC features | `keyctl=1,nesting=1` |

---

## 🔄 Updating MailFlow

The script creates an **update function** that runs automatically when called again inside the container:

```bash
# On Proxmox host, run the same installer again
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Orange99/proxmox-mailflow-installer/main/ct/mailflow.sh)"
```

The script detects an existing installation and:
1. Pulls the latest code from GitHub
2. Rebuilds the frontend
3. Updates backend dependencies
4. Restarts the systemd service

Alternatively, inside the container:

```bash
cd /opt/mailflow
git pull
cd frontend && npm ci && npm run build && cd ..
cd backend && npm ci --omit=dev && cd ..
sudo systemctl restart mailflow
```

---

## 🗂 Repository structure

```
proxmox-mailflow-installer/
├── ct/
│   └── mailflow.sh                  # Runs on Proxmox host → creates LXC
├── install/
│   └── mailflow-install.sh          # Runs inside container → installs MailFlow
├── json/
│   └── mailflow.json                # Metadata for community-scripts
└── README.md
```

---

## 🌐 After installation

MailFlow will be available at:

```
https://<CONTAINER_IP>
```

**Default credentials:**
- The **first registered user becomes the admin**
- No pre-set password — you set it during signup

> The container uses a **self-signed TLS certificate**. Accept the browser security warning on first visit.

**All secrets stored in:** `/opt/mailflow/.env`

---

## 📋 Inside the container

```bash
# Check service status
sudo systemctl status mailflow

# View logs
sudo journalctl -u mailflow -f

# Stop/restart
sudo systemctl stop mailflow
sudo systemctl restart mailflow

# Access MailFlow directory
cd /opt/mailflow
ls -la        # Shows: backend/, frontend/, dist/, .env, etc.
```

---

## 🔧 Troubleshooting

### "Invalid credentials" im Frontend

Wenn die MailFlow-UI erreichbar ist, aber "Invalid credentials" anzeigt, ist oft bereits ein anderer Benutzer in der Datenbank vorhanden.

**1. Überprüfen Sie, ob das Backend läuft:**
```bash
# Inside container
sudo systemctl status mailflow
sudo journalctl -u mailflow -f  # View live logs
```

**2. Überprüfen Sie die PostgreSQL-Verbindung:**
```bash
# Inside container
psql -h 127.0.0.1 -U mailflow -d mailflow -c "SELECT 1"  # Should return: 1
```

**3. Login-Flow prüfen:**
- Es gibt keine Default-Credentials.
- Der erste registrierte Benutzer wird Admin.

**4. Neu-Setup durchführen:**
Wenn alles oben fehlschlägt, können Sie den Installer erneut ausführen — der vorhandene MailFlow-Container wird erkannt und aktualisiert:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Orange99/proxmox-mailflow-installer/main/ct/mailflow.sh)"
```

### Backend startet nicht

**Überprüfen Sie die .env-Datei:**
```bash
cat /opt/mailflow/.env
```

**Überprüfen Sie die Logs:**
```bash
journalctl -u mailflow -n 100 --no-pager
```

**Überprüfen Sie PostgreSQL:**
```bash
sudo systemctl status postgresql
sudo -u postgres psql -d mailflow -c "\dt"  # Should show tables
```

---

## 🤝 Contributing to community-scripts

To submit this to the official [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE) repository:

1. Fork [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE)
2. Copy `ct/mailflow.sh` → `ct/mailflow.sh`
3. Copy `install/mailflow-install.sh` → `install/mailflow-install.sh`
4. Copy `json/mailflow.json` → `json/mailflow.json`
5. Add an entry in `frontend/public/json/apps.json` (see existing entries for format)
6. Open a Pull Request

---

## 📄 License

MIT — see [LICENSE](https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE)

---

## 🙏 Credits

- [MailFlow](https://mailflow.sh/) by [@maathimself](https://github.com/maathimself)
- Installer style based on [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE)

