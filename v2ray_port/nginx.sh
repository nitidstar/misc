#!/bin/sh

domain=$1
cd "$(dirname "$0")"
#python3 update_conf.py nginx_nginx.conf /etc/nginx/ $domain
python3 update_conf.py nginx_default.conf /etc/nginx/conf.d $domain
#service nginx restart
nginx -s reload
