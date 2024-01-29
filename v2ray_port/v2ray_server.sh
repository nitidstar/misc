#!/bin/sh


. /etc/profile

domain=$1
cd "$(dirname "$0")"
python3 update_conf.py v2ray_server_config.json /usr/local/etc/v2ray $domain

if [ -n "$2" ]; then
  action=$2
  systemctl "$action" v2ray
fi
