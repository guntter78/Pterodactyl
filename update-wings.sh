#!/usr/bin/env bash
set -e

LOG="/var/log/pterodactyl-wings-update.log"
exec > >(tee -a "$LOG") 2>&1

systemctl stop wings
curl -L -o /usr/local/bin/wings \
  "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64"
chmod u+x /usr/local/bin/wings
systemctl restart wings

echo "Update voltooid: $(date)"
