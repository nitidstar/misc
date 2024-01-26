#!/bin/bash

domain=nitidstar.top
curl https://get.acme.sh | sh
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
~/.acme.sh/acme.sh  --issue  -d $domain  --webroot /etc/nginx/html/
~/.acme.sh/acme.sh  --installcert  -d  $domain   \
    --key-file   /etc/nginx/ssl/$domain.key \
    --fullchain-file /etc/nginx/ssl/fullchain.cer \
    --reloadcmd  "/etc/nginx/sbin/nginx -s reload"

