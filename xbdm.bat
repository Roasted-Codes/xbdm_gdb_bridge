@echo off
setlocal enabledelayedexpansion

:: xbdm_gdb_bridge Windows Launcher
:: Double-click to connect to Xbox/xemu

set "SCRIPT_DIR=%~dp0"
set "CONFIG_FILE=%SCRIPT_DIR%xbdm_config.ini"

:: Check if config exists
if not exist "%CONFIG_FILE%" (
    echo.
    echo  No configuration found. Running setup...
    echo.
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%setup.ps1"
    if errorlevel 1 exit /b 1
    if not exist "%CONFIG_FILE%" (
        echo Setup did not create config file. Exiting.
        pause
        exit /b 1
    )
)

:: Check WSL is available
wsl --status >nul 2>&1
if errorlevel 1 (
    echo.
    echo  ERROR: WSL is not installed or not configured.
    echo  Run setup.ps1 for instructions.
    echo.
    pause
    exit /b 1
)

:: Convert Windows path to WSL path
set "WSL_PATH=%SCRIPT_DIR:\=/%"
set "WSL_PATH=%WSL_PATH:C:=/mnt/c%"
set "WSL_PATH=%WSL_PATH:D:=/mnt/d%"
set "WSL_PATH=%WSL_PATH:E:=/mnt/e%"

:: Read Xbox IP from config for display
set "XBOX_IP=unknown"
for /f "tokens=1,* delims==" %%a in ('findstr /i "xbox_ip" "%CONFIG_FILE%"') do (
    set "XBOX_IP=%%b"
)
:: Trim whitespace
for /f "tokens=*" %%a in ("%XBOX_IP%") do set "XBOX_IP=%%a"

:: Get WSL IP for Windows apps
for /f "tokens=*" %%i in ('wsl -e hostname -I') do set "WSL_IP=%%i"
for /f "tokens=1" %%a in ("%WSL_IP%") do set "WSL_IP=%%a"

:: Launch xbdm via WSL
echo.
echo  =====================================================
echo  Connecting to xemu at %XBOX_IP%:731 ...
echo  =====================================================
echo.
echo  For Windows native apps, run relay.bat then use:
echo    IP: %WSL_IP%    Port: 731
echo.
echo  Type '?' for commands, 'quit' to exit.
echo  -------------------------------------------------

wsl -e bash -c "cd '%WSL_PATH%' && ./xbdm %*"

pause
