#!/bin/bash

domain=$1
curl https://get.acme.sh | sh
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
# standalone模式，不依赖nginx，因为此时nginx配置未完成，不能启动
~/.acme.sh/acme.sh  --issue  -d "$domain"  --webroot /usr/share/nginx/html  --standalone
~/.acme.sh/acme.sh  --installcert  -d  "$domain"   \
    --key-file   /etc/nginx/conf/"$domain".key \
    --fullchain-file /etc/nginx/conf/"$domain".crt \
    --reloadcmd  "systemctl restart nginx"
