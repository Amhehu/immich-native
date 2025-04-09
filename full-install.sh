#!/bin/bash

# common
apt update
apt -y upgrade

apt install -y curl git gpg lsb-release postgresql-common
apt install -y --no-install-recommends python3-venv python3-dev uuid-runtime autoconf build-essential unzip jq perl libnet-ssleay-perl libio-socket-ssl-perl libcapture-tiny-perl libfile-which-perl libfile-chdir-perl libpkgconfig-perl libffi-checklib-perl libtest-warnings-perl libtest-fatal-perl libtest-needs-perl libtest2-suite-perl libsort-versions-perl libpath-tiny-perl libtry-tiny-perl libterm-table-perl libany-uri-escape-perl libmojolicious-perl libfile-slurper-perl liblcms2-2 wget

cd /tmp/

# nodejs
curl -fsSL https://deb.nodesource.com/setup_23.x -o nodesource_setup.sh
sudo -E bash nodesource_setup.sh
apt install -y nodejs

# redis
curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
chmod 644 /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list

apt update
apt install -y redis-server

# postgresql
YES="yes" /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
apt install -y postgresql postgresql-17-pgvector

PGPASSWORD=$(openssl rand -base64 16)
echo "Generiertes Passwort für User 'immich': $PGPASSWORD"

sudo -u postgres psql <<EOF
CREATE DATABASE immich;
CREATE USER immich WITH ENCRYPTED PASSWORD '$PGPASSWORD';
GRANT ALL PRIVILEGES ON DATABASE immich TO immich;
ALTER USER immich WITH SUPERUSER;
\c immich
CREATE EXTENSION IF NOT EXISTS vector;
EOF

# ffmpeg
wget https://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2024.9.1_all.deb
dpkg -i deb-multimedia-keyring_2024.9.1_all.deb
apt update
apt install -y ffmpeg

# immick user
adduser --home /var/lib/immich/home --shell=/sbin/nologin --no-create-home --disabled-password --disabled-login --gecos "" immich
mkdir -p /var/lib/immich
chown immich:immich /var/lib/immich
chmod 700 /var/lib/immich

# immick native
git clone https://github.com/arter97/immich-native

cp immich-native/env /var/lib/immich/
chown immich:immich /var/lib/immich/env
sed -i "s/YOUR_STRONG_RANDOM_PW/${PGPASSWORD}/g" /var/lib/immich/env
sed -i "s/IMMICH_HOST=127.0.0.1/IMMICH_HOST=0.0.0.0/g" /var/lib/immich/env

cd immich-native
./install.sh

systemctl daemon-reload
systemctl restart immich
systemctl status immich
