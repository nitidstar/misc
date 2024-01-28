#!/bin/bash

domain=$1
curl https://get.acme.sh | sh
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
~/.acme.sh/acme.sh  --issue  -d $domain  --webroot /etc/nginx/html/
~/.acme.sh/acme.sh  --installcert  -d  $domain   \
    --key-file   /etc/nginx/ssl/$domain.key \
    --fullchain-file /etc/nginx/ssl/fullchain.cer \
    --reloadcmd  "nginx -s reload"

