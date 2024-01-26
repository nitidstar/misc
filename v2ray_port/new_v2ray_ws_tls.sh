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

install_nginx(){
    yum install -y nginx
    res=$(command -v nginx)
    if [[ "$res" = "" ]]; then
        red "nginx安装失败"
        exit 1
    fi
    systemctl enable nginx

    green "======================"
    green " 输入解析到此VPS的域名"
    green "======================"
    read domain

cat > /etc/nginx/nginx.conf <<-EOF
user  root;
worker_processes  1;
error_log  /etc/nginx/logs/error.log info;
pid        /etc/nginx/logs/nginx.pid;
events {
    worker_connections  1024;
}
http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log  /etc/nginx/logs/access.log  main;
    sendfile        on;
    #tcp_nopush     on;
    keepalive_timeout  120;
    client_max_body_size 20m;
    #gzip  on;
    include /etc/nginx/conf.d/*.conf;
}
EOF

cat > /etc/nginx/conf.d/default.conf<<-EOF
server {
    listen       80;
    server_name  $domain;
    root /etc/nginx/html;
    index index.php index.html index.htm;
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /etc/nginx/html;
    }
}
EOF

    mkdir -p /etc/nginx/ssl
    /etc/nginx/sbin/nginx

    curl https://get.acme.sh | sh
    ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    ~/.acme.sh/acme.sh  --issue  -d $domain  --webroot /etc/nginx/html/
    ~/.acme.sh/acme.sh  --installcert  -d  $domain   \
        --key-file   /etc/nginx/ssl/$domain.key \
        --fullchain-file /etc/nginx/ssl/fullchain.cer \
        --reloadcmd  "/etc/nginx/sbin/nginx -s reload"

cat > /etc/nginx/conf.d/default.conf<<-EOF
server {
    listen       10101;
    server_name  $domain;
    charset utf-8;
    root    /opt/data/nginx;             # 文件存放目录

    location / {
        autoindex on;                         # 启用自动首页功能
        autoindex_format html;                # 首页格式为HTML
        autoindex_exact_size off;             # 文件大小自动换算
        autoindex_localtime on;               # 按照服务器时间显示文件时间

        default_type application/octet-stream;# 将当前目录中所有文件的默认MIME类型设置为
                                              # application/octet-stream

        if (\$request_filename ~* ^.*?\.(txt|doc|pdf|rar|gz|zip|docx|exe|xlsx|ppt|pptx)$){
            # 当文件格式为上述格式时，将头字段属性Content-Disposition的值设置为"attachment"
            add_header Content-Disposition: 'attachment;';
        }
        sendfile on;                          # 开启零复制文件传输功能
        sendfile_max_chunk 1m;                # 每个sendfile调用的最大传输量为1MB
        tcp_nopush on;                        # 启用最小传输限制功能

        #aio on;                               # 启用异步传输
        directio 5m;                          # 当文件大于5MB时以直接读取磁盘的方式读取文件
        directio_alignment 4096;              # 与磁盘的文件系统对齐
        output_buffers 4 32k;                 # 文件输出的缓冲区大小为128KB

        max_ranges 4096;                      # 客户端执行范围读取的最大值是4096B
        send_timeout 20s;                     # 客户端引发传输超时时间为20s
        postpone_output 2048;                 # 当缓冲区的数据达到2048B时再向客户端发送
        chunked_transfer_encoding on;         # 启用分块传输标识
    }
}

server {
    listen 443 ssl http2;
    server_name $domain;
    root /etc/nginx/html;
    index index.php index.html;
    ssl_certificate /etc/nginx/ssl/fullchain.cer;
    ssl_certificate_key /etc/nginx/ssl/$domain.key;
    #TLS 版本控制
    ssl_protocols   TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_ciphers     'TLS13-AES-256-GCM-SHA384:TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-128-GCM-SHA256:TLS13-AES-128-CCM-8-SHA256:TLS13-AES-128-CCM-SHA256:EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+ECDSA+AES128:EECDH+aRSA+AES128:RSA+AES128:EECDH+ECDSA+AES256:EECDH+aRSA+AES256:RSA+AES256:EECDH+ECDSA+3DES:EECDH+aRSA+3DES:RSA+3DES:!MD5';
    ssl_prefer_server_ciphers   on;
    # 开启 1.3 0-RTT
    ssl_early_data  on;
    ssl_stapling on;
    ssl_stapling_verify on;
    #add_header Strict-Transport-Security "max-age=31536000";
    #access_log /var/log/nginx/access.log combined;
    location /mypath {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:11234;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        # Show real IP in v2ray access.log
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    location / {
       try_files \$uri \$uri/ /index.php?\$args;
    }
}
EOF
}

install_v2ray(){
    yum install -y wget
    bash <(curl -L -s https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
    mkdir -p /usr/local/etc/v2ray
    cd /usr/local/etc/v2ray/
    rm -f config.json
    wget https://raw.githubusercontent.com/luyiming1016/ladderbackup/master/config.json
#    v2uuid=$(cat /proc/sys/kernel/random/uuid)
    v2uuid=b16dde59-7c20-43b7-a557-8c6bb55f935c
    sed -i "s/aaaa/$v2uuid/;" config.json
#    newpath=$(cat /dev/urandom | head -1 | md5sum | head -c 4)
    newpath=3b71
    sed -i "s/mypath/$newpath/;" config.json
    sed -i "s/mypath/$newpath/;" /etc/nginx/conf.d/default.conf

    cd /etc/nginx/html
    rm -rf /etc/nginx/html/*
#    wget https://raw.githubusercontent.com/nitidstar/misc/master/web.zip
    wget https://github.com/atrandys/v2ray-ws-tls/raw/master/web.zip
    unzip web.zip

    /etc/nginx/sbin/nginx -s stop
    /etc/nginx/sbin/nginx
    systemctl restart v2ray.service

    #增加自启动脚本
cat > /etc/rc.d/init.d/autov2ray<<-EOF
#!/bin/sh
#chkconfig: 2345 80 90
#description:autov2ray
/etc/nginx/sbin/nginx
EOF

    #设置脚本权限
    chmod +x /etc/rc.d/init.d/autov2ray
    chkconfig --add autov2ray
    chkconfig autov2ray on

cat > /usr/local/etc/v2ray/myconfig.json<<-EOF
{
===========配置参数=============
地址：${domain}
端口：443
uuid：${v2uuid}
额外id：64
加密方式：aes-128-gcm
传输协议：ws
别名：myws
路径：${newpath}
底层传输：tls
}
EOF

clear
green
green "安装已经完成"
green
green "===========配置参数============"
green "地址：${domain}"
green "端口：443"
green "uuid：${v2uuid}"
green "额外id：64"
green "加密方式：aes-128-gcm"
green "传输协议：ws"
green "别名：myws"
green "路径：${newpath}"
green "底层传输：tls"
green
}

remove_v2ray(){
    /etc/nginx/sbin/nginx -s stop
    systemctl stop v2ray.service
    systemctl disable v2ray.service

    rm -rf /usr/bin/v2ray /usr/local/etc/v2ray
    rm -rf /usr/local/etc/v2ray

    green "v2ray已删除"
}

start_menu(){
    clear
    green " ===================================="
    green " 介绍：一键安装v2ray+ws+tls             "
    green " 系统：centos 7,8,9                   "
    green " ===================================="
    echo
    green " 1. 安装v2ray+ws+tls"
    green " 2. 升级v2ray"
    red " 3. 卸载v2ray"
    yellow " 0. 退出脚本"
    echo
    read -p "请输入数字:" num
    case "$num" in
    1)
    init_os
    install_nginx
    install_v2ray
    ;;
    2)
    bash <(curl -L -s https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
    ;;
    3)
    remove_v2ray
    ;;
    0)
    exit 1
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
