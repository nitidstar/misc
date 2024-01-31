#!/bin/sh


. /etc/profile

domain=$1
cd "$(dirname "$0")"

port=1$(date -d "$(date '+%Y-%m-%d')" '+%m%d')
python3 update_conf.py v2ray_server_config.json /usr/local/etc/v2ray "$domain" "$port"

if [ -n "$2" ]; then
  action=$2
  systemctl "$action" v2ray
fi
