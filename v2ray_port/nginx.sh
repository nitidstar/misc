#!/bin/sh


. /etc/profile

domain=$1
cd "$(dirname "$0")"
#python3 update_conf.py nginx_nginx.conf /etc/nginx/ $domain
python3 update_conf.py nginx_default.conf /etc/nginx/conf.d "$domain"

if [ -n "$2" ]; then
  action=$2
  systemctl "$action" nginx
fi
