#!/usr/bin/env bash
set -Eeuo pipefail

PANEL_DIR="/opt/pterodactyl-panel"
LOG_DIR="/var/log/pterodactyl"
TIMESTAMP="$(date +'%Y-%m-%d_%H-%M-%S')"
LOG_FILE="${LOG_DIR}/panel-update-${TIMESTAMP}.log"

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[$(date +'%F %T')] Start Pterodactyl panel update"

run() {
  echo "[$(date +'%F %T')] RUN: $*"
  "$@"
}

cd "$PANEL_DIR"

run php artisan down
run bash -c "curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv"
run chmod -R 755 storage/* bootstrap/cache
run composer install --no-dev --optimize-autoloader
run php artisan view:clear
run php artisan config:clear
run php artisan migrate --seed --force
run chown -R www-data:www-data "${PANEL_DIR}"/*
run php artisan queue:restart
run php artisan up
run bash -c "ps aux | egrep '(apache|nginx|caddy)'"

echo "[$(date +'%F %T')] Klaar. Logbestand: $LOG_FILE"
