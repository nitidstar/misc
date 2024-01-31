#!/bin/sh


. /etc/profile

domain=$1
cd "$(dirname "$0")"

port=1$(date -d "$(date '+%Y-%m-%d')" '+%m%d')

python3 update_conf.py v2ray_client_ubuntu_config.json /usr/local/etc/v2ray "$domain" "$port"
service v2ray restart
