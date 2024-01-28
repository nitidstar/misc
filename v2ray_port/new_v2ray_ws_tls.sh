#!/bin/bash

function blue(){
    echo -e "\033[34m\033[01m $1 \033[0m"
}

function green(){
    echo -e "\033[32m\033[01m $1 \033[0m"
}

function red(){
    echo -e "\033[31m\033[01m $1 \033[0m"
}

function yellow(){
    echo -e "\033[33m\033[01m $1 \033[0m"
}

init_os() {
    if [[ ! -f /etc/centos-release ]];then
        red "系统不是CentOS"
        exit 1
    fi
    CHECK=$(grep SELINUX= /etc/selinux/config | grep -v "#")
    if [ "$CHECK" == "SELINUX=enforcing" ]; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
    if [ "$CHECK" == "SELINUX=permissive" ]; then
        sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

install_bbr() {
    result=$(lsmod | grep bbr)
    if [[ "$result" != "" ]]; then
        yellow " BBR模块已安装"
        INSTALL_BBR=false
        return
    fi
    res=$(hostnamectl | grep -i openvz)
    if [[ "$res" != "" ]]; then
        yellow " openvz机器，跳过安装"
        INSTALL_BBR=false
        return
    fi

    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
    result=$(lsmod | grep bbr)
    if [[ "$result" != "" ]]; then
        green " BBR模块已启用"
        INSTALL_BBR=false
        return
    fi

    blue " 安装BBR模块..."
    if [[ "$V6_PROXY" = "" ]]; then
        rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
        rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-4.el7.elrepo.noarch.rpm
        yum --enablerepo=elrepo-kernel install kernel-ml -y
        grub2-set-default 0
        echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
        INSTALL_BBR=true
    fi
}

install() {
  yum install -y wget
  yum install -y python3
  yum install -y nginx
  mkdir -p /etc/nginx/ssl
  bash <(curl -L -s https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
  systemctl enable v2ray
}

remove() {
  nginx -s stop
  yum -y remove nginx
  systemctl stop v2ray.service
  systemctl disable v2ray.service

  rm -rf /usr/local/bin/v2ray
  rm -rf /usr/local/share/v2ray
  rm -rf /usr/local/etc/v2ray
}

config() {
  nginx
  green " 输入域名:"
  read domain
  cd "$(dirname "$0")"
  ./nginx.sh $domain
  ./nginx_cert.sh $domain
  ./v2ray_server.sh $domain
}

deploy() {
  init_os
  install
  config
}

start_menu(){
    clear
    green " ===================================="
    green "     一键安装v2ray+nginx+ws+tls       "
    green "     适用 centos 7,8,9               "
    green " ===================================="
    echo
    green " 1. 安装v2ray+ws+tls"
    green " 2. 卸载v2ray+nginx"
    yellow " 0. 退出脚本"
    echo
    read -p "请输入数字:" num
    case "$num" in
    0)
    exit 1
    ;;
    1)
    deploy
    ;;
    2)
    remove
    ;;
    *)
    clear
    red "请输入正确数字"
    sleep 2s
    start_menu
    ;;
    esac
}

start_menu
