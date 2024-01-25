#!/bin/sh

python3 change_port.py ubuntu /usr/local/etc/v2ray
service v2ray restart
