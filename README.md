# misc
### 各类小工具

| 子目录        | 说明          |
|------------|-------------|
| profiler   | 穷人的性能分析脚本   |
| v2ray_port | v2ray自动修改端口 |



## ./profiler
- profiler.sh： cpp 性能分析，利用gdb周期抓栈统计性能
- jprofiler.sh： java 性能分析，利用gdb周期抓栈统计性能

## ./v2ray_port
### v2ray
- v2ray_ws_tls.sh： 一键部署 v2ray+nginx+websocket，来源与网上，备忘用
- new_v2ray_ws_tls.sh： 改进版，直接 yum 安装nginx，固定uuid和path

### nginx
- nginx.sh： 配置到cron job，每天修改端口
- nginx_cert.sh： 配置到cron job，每两个月更新tls证书

### ubuntu
- v2ray_client_ubuntu.sh： 配置到开机启动

### windows
- v2ray_client_windows.bat： 生成快捷方式并修改启动参数，然后配置开机启动（shell:startup）

