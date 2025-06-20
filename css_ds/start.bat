@echo off
cd /d C:\MyPrograms\steamcmd\css_ds

:: Compile plugins before launch
:: call compile_plugins.bat

:: Then start the server
start srcds.exe -console -game cstrike -ip 192.168.1.68 -port 27015 -secure +maxplayers 22 +map de_dust2
