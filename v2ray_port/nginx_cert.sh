#!/bin/bash

domain=$1
action=$2
curl https://get.acme.sh | sh
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
~/.acme.sh/acme.sh  --issue  -d "$domain"  --webroot /etc/nginx/html/
~/.acme.sh/acme.sh  --installcert  -d  "$domain"   \
    --key-file   /etc/nginx/conf/"$domain".key \
    --fullchain-file /etc/nginx/conf/"$domain".crt

if [ -n "$2" ]; then
  action=$2
  systemctl "$action" nginx
fi
