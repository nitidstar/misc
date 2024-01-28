@echo off

set target=v2ray_client_windows_guiNDB.db
set directory=%1
set domain=%2
set config_directory=%directory%\guiConfigs

python update_conf.py %target% %config_directory% %domain%

start /d "%directory%" v2rayN.exe

exit
