# Pterodactyl Installation and Update Scripts

Unofficial Bash scripts for installing and updating a Pterodactyl Panel and Wings node on an Ubuntu server.

## Included Scripts

| Script | Purpose |
| --- | --- |
| `install_pterodactyl.sh` | Installs the Panel, MariaDB, Redis, NGINX, PHP, Composer and Let's Encrypt SSL. |
| `wingsnode.sh` | Installs Docker, downloads Wings and requests an SSL certificate for a node. |
| `update-panel.sh` | Updates an existing Panel installation and writes a log file. |
| `update-wings.sh` | Updates an existing Wings installation and writes a log file. |

## Requirements

- Ubuntu server
- Root access or `sudo`
- A domain name pointing to your server
- Ports `80` and `443` open
- `amd64` / x86-64 CPU architecture for Wings

## Installation

Clone the repository:

```bash
git clone https://github.com/guntter78/Pterodactyl.git
cd Pterodactyl
chmod +x *.sh
```

## Install the Panel

Before running the script, edit the variables at the top of `install_pterodactyl.sh`:

```bash
nano install_pterodactyl.sh
```

Set your own values:

```bash
DB_PASSWORD="your database password"
PANEL_DOMAIN="panel.example.com"
EMAIL="you@example.com"
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="your admin password"
ADMIN_FIRSTNAME="Your first name"
ADMIN_LASTNAME="Your last name"
```

Run the installer:

```bash
sudo ./install_pterodactyl.sh
```

After installation, the Panel is available at:

```text
https://panel.example.com
```

## Install a Wings Node

Before running the script, edit the domain name and email address in `wingsnode.sh`:

```bash
nano wingsnode.sh
```

Run the installer:

```bash
sudo ./wingsnode.sh
```

The script installs Docker, downloads Wings and requests an SSL certificate.

Afterwards, create your node in the Pterodactyl admin panel and follow the official Wings configuration instructions:

https://pterodactyl.io/wings/1.0/installing.html

## Update the Panel

The installer places the Panel in:

```text
/var/www/pterodactyl
```

Before using `update-panel.sh`, change its `PANEL_DIR` value to match:

```bash
PANEL_DIR="/var/www/pterodactyl"
```

Run the update:

```bash
sudo ./update-panel.sh
```

Panel update logs are stored in:

```text
/var/log/pterodactyl/
```

## Update Wings

Run:

```bash
sudo ./update-wings.sh
```

The Wings update log is stored in:

```text
/var/log/pterodactyl-wings-update.log
```

## Important Notes

- Create a database backup before updating the Panel.
- Back up the Panel `.env` file and its `APP_KEY`.
- Review every script before running it as root.
- Replace all placeholder values before installation.
- Do not commit real passwords or API keys to this repository.
- These scripts do not provide automatic rollback.
- The Wings scripts download the `amd64` binary and are intended for x86-64 servers.

## Disclaimer

This is an unofficial project and is not affiliated with the official Pterodactyl project.

For official documentation, visit:

https://pterodactyl.io/
