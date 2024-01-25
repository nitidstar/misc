#!/bin/sh

python3 change_port.py nginx /etc/nginx/conf.d
/etc/nginx/sbin/nginx -s reload
