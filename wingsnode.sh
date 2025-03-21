apt update && apt upgrade -y
apt install -y curl sudo apt-transport-https ca-certificates gnupg unzip tar software-properties-common

# Docker installeren
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
systemctl enable --now docker

# Wings downloaden
curl -Lo /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
chmod +x /usr/local/bin/wings

# Configmap aanmaken
mkdir -p /etc/pterodactyl

apt install certbot -y

certbot certonly --standalone -d "domeinname" \
--agree-tos --email "own e-mail" --non-interactive
