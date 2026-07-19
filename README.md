# MailFlow LXC Installer for Proxmox VE

> **Community-Scripts-style installer for [MailFlow](https://mailflow.sh/) on Proxmox VE.**  
> Follows the conventions of [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE).

---

## 🚀 One-Line Install

Run this command **directly on your Proxmox host** in the shell:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/<YOUR_GITHUB_USER>/proxmox-mailflow-installer/main/ct/mailflow.sh)"
```

> Replace `<YOUR_GITHUB_USER>` with your actual GitHub username once the repo is public.

---

## 📦 What gets installed

| Component | Details |
|-----------|---------|
| **OS** | Debian 12 (Bookworm) LXC |
| **Docker Engine** | Latest stable via official Docker apt repo |
| **MailFlow** | Latest release via `docker compose` (ghcr.io images) |
| **Auto-secrets** | `SESSION_SECRET`, `DB_PASSWORD`, `ENCRYPTION_KEY` generated with `openssl rand` |

**Default LXC resources:**

| Resource | Default |
|----------|---------|
| CPU cores | 2 |
| RAM | 2048 MB |
| Disk | 10 GB |
| Network | DHCP on vmbr0 |
| Container type | **Privileged** (required for Docker-in-LXC) |
| LXC features | `keyctl=1,nesting=1` |

---

## 🔄 Updating MailFlow

Run the **same script** again inside the already-created LXC container:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/<YOUR_GITHUB_USER>/proxmox-mailflow-installer/main/ct/mailflow.sh)"
```

The script detects an existing installation at `/opt/mailflow` and performs a `docker compose pull && docker compose up -d` instead.

---

## 🗂 Repository structure

```
proxmox-mailflow-installer/
├── ct/
│   └── mailflow.sh          # Run on Proxmox host — creates the LXC + triggers install
├── install/
│   └── mailflow-install.sh  # Runs inside the container — installs Docker + MailFlow
├── json/
│   └── mailflow.json        # Metadata (compatible with community-scripts website format)
└── README.md
```

---

## 🌐 After installation

MailFlow will be available at:

```
https://<CONTAINER_IP>
```

> The container uses a **self-signed TLS certificate**. Accept the browser security warning on first visit.

All generated secrets are stored in `/opt/mailflow/.env` inside the container.

---

## 🤝 Contributing to community-scripts

To submit this to the official [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE) repository:

1. Fork [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE)
2. Copy `ct/mailflow.sh` → `ct/mailflow.sh`
3. Copy `install/mailflow-install.sh` → `install/mailflow-install.sh`
4. Copy `json/mailflow.json` → `json/mailflow.json`
5. Add an entry in `frontend/public/json/apps.json` (see existing entries for format)
6. Open a Pull Request — include a short description of MailFlow and a screenshot

---

## 📄 License

MIT — see [LICENSE](https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE)

---

## 🙏 Credits

- [MailFlow](https://mailflow.sh/) by [@maathimself](https://github.com/maathimself)
- Installer style based on [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE)

