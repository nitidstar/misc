#!/bin/sh

cd "$(dirname "$0")"
python3 change_port.py nginx /etc/nginx/conf.d
/etc/nginx/sbin/nginx -s reload
