#!/bin/sh

cd /root/nginx_port/
python3 change_port.py
cp default.conf /etc/nginx/conf.d
/etc/nginx/sbin/nginx -s reload
