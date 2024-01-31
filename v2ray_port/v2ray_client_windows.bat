@echo off

set target=v2ray_client_windows_guiNDB.db
set directory=%1
set domain=%2
set config_directory=%directory%\guiConfigs


for /f "tokens=2 delims==" %%G in ('wmic os get localdatetime /value') do set datetime=%%G
set month=%datetime:~4,2%
set day=%datetime:~6,2%
set port=1%month%%day%

python update_conf.py %target% %config_directory% %domain% %port%

start /d "%directory%" v2rayN.exe

exit
