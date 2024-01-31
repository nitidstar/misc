#!/bin/sh


. /etc/profile

domain=$1
cd "$(dirname "$0")"

old_port=1$(date -d "$(date --date="yesterday" +"%Y-%m-%d")" '+%m%d')
new_port=1$(date -d "$(date '+%Y-%m-%d')" '+%m%d')

python3 update_conf.py nginx_default.conf /etc/nginx/conf.d "$domain" "$new_port"

if [ -n "$2" ]; then
  action=$2
  systemctl "$action" nginx
fi

firewall-cmd --zone=public --add-port="$new_port"/tcp --permanent
firewall-cmd --zone=public --remove-port="$old_port"/tcp --permanent
firewall-cmd --reload
