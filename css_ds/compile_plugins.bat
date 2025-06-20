@echo off
setlocal

:: cstrike\addons\sourcemod\plugins
:: cstrike\addons\sourcemod\scripting\spcomp.exe

:: Paths (adjust if your layout differs)
set SRC_DIR=C:\MyPrograms\steamcmd\Scripts\server-ready
set OUT_DIR=C:\MyPrograms\steamcmd\css_ds\cstrike\addons\sourcemod\plugins
set COMPILER=C:\MyPrograms\steamcmd\css_ds\cstrike\addons\sourcemod\scripting\spcomp.exe

echo === Compiling all plugins from %SRC_DIR% ===

cd /d C:\MyPrograms\steamcmd\css_ds

for %%f in (%SRC_DIR%\*.sp) do (
    echo Compiling %%~nxf ...
    "%COMPILER%" "%%f" -o"%OUT_DIR%\%%~nf.smx"
)

echo === Done compiling. ===
endlocal