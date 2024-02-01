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
  bash <(curl -L -s https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
}

remove() {
  systemctl stop nginx
  systemctl disable nginx.service
  yum -y remove nginx
  rm -rf /etc/nginx

  systemctl stop v2ray.service
  systemctl disable v2ray.service
  rm -rf /usr/local/bin/v2ray
  rm -rf /usr/local/share/v2ray
  rm -rf /usr/local/etc/v2ray
}

config() {
  mkdir -p /etc/nginx/conf
  mkdir -p /etc/nginx/conf.d
  mkdir -p /opt/data/nginx

  cd /usr/share/nginx/html && rm -f *
  wget https://github.com/nitidstar/misc/raw/master/v2ray_port/web.zip
  unzip web.zip
  cd -

  # 1. 先启动nginx，nginx_cert.sh申请证书需要访问nginx
  systemctl start nginx

  green " 输入域名:"
  read domain

  # 2. 生成nginx配置，此时还没有证书，所以nginx必须在此之前启动，否则启动会失败
  cd "$(dirname "$0")"
  ./nginx.sh $domain
  # 3. 申请证书，此时nginx所有配置完成，可以重启
  ./nginx_cert.sh $domain restart
  ./v2ray_server.sh $domain start

  systemctl enable nginx
  systemctl enable v2ray
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
