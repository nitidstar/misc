#!/bin/sh

domain=$1
cd "$(dirname "$0")"
python3 update_conf.py v2ray_server_config.json /usr/local/etc/v2ray $domain
service v2ray restart
