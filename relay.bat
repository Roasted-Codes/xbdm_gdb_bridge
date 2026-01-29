@echo off
setlocal enabledelayedexpansion

:: XBDM Relay for Windows
:: Run as Administrator to set up port forwarding
::
:: This script:
::   1. Sets up Windows port forwarding (netsh portproxy)
::   2. Starts socat relay in WSL
::
:: Windows apps connect to 127.0.0.1:731 (XBDM)

set "SCRIPT_DIR=%~dp0"
set "CONFIG_FILE=%SCRIPT_DIR%xbdm_config.ini"

:: Convert Windows path to WSL path
set "WSL_PATH=%SCRIPT_DIR:\=/%"
set "WSL_PATH=%WSL_PATH:C:=/mnt/c%"
set "WSL_PATH=%WSL_PATH:D:=/mnt/d%"
set "WSL_PATH=%WSL_PATH:E:=/mnt/e%"

:: Check if config exists
if not exist "%CONFIG_FILE%" (
    echo.
    echo  No configuration found. Run setup.ps1 first.
    echo.
    pause
    exit /b 1
)

:: Handle --status
if "%~1"=="--status" (
    echo.
    echo  Checking relay status...
    echo.
    wsl -e bash -c "cd '%WSL_PATH%' && ./start_relay.sh --status"
    echo.
    echo  Windows port forwarding:
    netsh interface portproxy show v4tov4
    pause
    exit /b 0
)

:: Get WSL IP address
for /f "tokens=*" %%i in ('wsl -e hostname -I') do set "WSL_IP=%%i"
:: Trim whitespace
for /f "tokens=1" %%a in ("%WSL_IP%") do set "WSL_IP=%%a"

if "%WSL_IP%"=="" (
    echo.
    echo  Error: Could not get WSL IP address.
    echo  Make sure WSL is running.
    echo.
    pause
    exit /b 1
)

:: Check for admin privileges
net session >nul 2>&1
if errorlevel 1 (
    echo.
    echo  =====================================================
    echo.
    echo    This script requires Administrator privileges
    echo    to set up Windows port forwarding.
    echo.
    echo    Right-click relay.bat and select:
    echo    "Run as administrator"
    echo.
    echo  =====================================================
    echo.
    pause
    exit /b 1
)

:: Set up port forwarding
echo.
echo  Setting up Windows port forwarding...
echo.

:: Remove old rule (ignore errors)
netsh interface portproxy delete v4tov4 listenport=731 listenaddress=127.0.0.1 >nul 2>&1

:: Add new rule
netsh interface portproxy add v4tov4 listenport=731 listenaddress=127.0.0.1 connectport=7310 connectaddress=%WSL_IP%
if errorlevel 1 (
    echo  Error: Failed to set up XBDM port forwarding.
    pause
    exit /b 1
)

echo  Port forwarding configured:
echo    127.0.0.1:731 -^> %WSL_IP%:7310 (XBDM)
echo.

:: Show connection info
echo  =====================================================
echo.
echo    Configure your Windows applications with:
echo.
echo      XBDM:  127.0.0.1:731
echo.
echo  =====================================================
echo.
echo  Starting WSL relay...
echo  Press Ctrl+C to stop.
echo.

:: Start WSL relay (no root needed)
wsl -e bash -c "cd '%WSL_PATH%' && sed -i 's/\r$//' start_relay.sh && chmod +x start_relay.sh && ./start_relay.sh"

:: Cleanup port forwarding on exit
echo.
echo  Cleaning up port forwarding...
netsh interface portproxy delete v4tov4 listenport=731 listenaddress=127.0.0.1 >nul 2>&1

pause
