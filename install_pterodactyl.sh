#!/bin/bash

# Stop bij fouten
set -e

# Variabelen
DB_PASSWORD=""
PANEL_DOMAIN=""
EMAIL=""
ADMIN_USERNAME=""
ADMIN_PASSWORD=""
ADMIN_FIRSTNAME=""
ADMIN_LASTNAME=""

# Systeem bijwerken en pakketten installeren
apt update && apt upgrade -y
apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg

# PHP repository toevoegen
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php

# Redis repository toevoegen
curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list

apt update

# Vereiste pakketten installeren
apt -y install php8.3 php8.3-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server certbot python3-certbot-nginx

# Composer installeren
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# MariaDB configureren
mysql -u root <<-EOF
DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1';
CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$DB_PASSWORD';
CREATE DATABASE IF NOT EXISTS panel;
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# Pterodactyl downloaden
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/
cp .env.example .env
composer install --no-dev --optimize-autoloader
php artisan key:generate --force

# Verwijder bestaande admin-gebruiker als deze al bestaat
mysql -u root -p$DB_PASSWORD -e "DELETE FROM panel.users WHERE email = '$EMAIL';"

# Omgeving instellen
php artisan p:environment:database <<-EOF
127.0.0.1
3306
panel
pterodactyl
$DB_PASSWORD
EOF

php artisan migrate --seed --force

# Admin-gebruiker opnieuw aanmaken
php artisan p:user:make <<-EOF
yes
$EMAIL
$ADMIN_USERNAME
$ADMIN_FIRSTNAME
$ADMIN_LASTNAME
$ADMIN_PASSWORD
EOF

if [ $? -ne 0 ]; then
    echo "Er is een fout opgetreden bij het aanmaken van de gebruiker. Controleer of het wachtwoord voldoet aan de vereisten."
    exit 1
fi

chown -R www-data:www-data /var/www/pterodactyl/*

# Cronjob instellen
(crontab -l ; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -

# Pterodactyl Queue Worker
cat <<EOT > /etc/systemd/system/pteroq.service
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3

[Install]
WantedBy=multi-user.target
EOT

systemctl enable --now pteroq.service
systemctl enable --now redis-server

# NGINX configuratie
cat <<EOT > /etc/nginx/sites-available/pterodactyl.conf
server {
    listen 80;
    server_name $PANEL_DOMAIN;
    root /var/www/pterodactyl/public;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOT

if [ ! -f /etc/nginx/sites-enabled/pterodactyl.conf ]; then
    ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/
fi

nginx -t
systemctl restart nginx

# Let's Encrypt certificaat aanvragen
certbot --nginx -d $PANEL_DOMAIN --non-interactive --agree-tos -m $EMAIL --redirect

# Klaar
echo "Installatie voltooid. Je Pterodactyl-panel is bereikbaar op https://$PANEL_DOMAIN"

