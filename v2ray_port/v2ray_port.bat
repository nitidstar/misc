@echo off

set target=windows
set directory=%1
set config_directory=%directory%/guiConfigs

echo %config_directory%
python change_port.py %target% %config_directory%

start /d "%directory%" v2rayN.exe

exit
