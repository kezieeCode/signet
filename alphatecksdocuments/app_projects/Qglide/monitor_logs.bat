@echo off
REM QGlide Wireless Log Monitor Script (Windows)
REM Usage: monitor_logs.bat [filter]
REM Examples:
REM   monitor_logs.bat              REM Monitor all QGlide logs
REM   monitor_logs.bat zego         REM Monitor Zego-related logs
REM   monitor_logs.bat error        REM Monitor errors only

setlocal enabledelayedexpansion

set FILTER=%1
if "%FILTER%"=="" set FILTER=qglide

echo === QGlide Log Monitor ===
echo Filter: %FILTER%
echo Press Ctrl+C to stop
echo.

REM Check if device is connected
adb devices | findstr "device" >nul
if errorlevel 1 (
    echo No device connected!
    echo Connecting wirelessly...
    set /p DEVICE_IP="Enter device IP address (or press Enter to skip): "
    if not "!DEVICE_IP!"=="" (
        adb connect !DEVICE_IP!:5555
        timeout /t 2 /nobreak >nul
    )
    
    adb devices | findstr "device" >nul
    if errorlevel 1 (
        echo Failed to connect. Please connect device first.
        exit /b 1
    )
)

echo Device connected!
echo.

REM Clear previous logs
adb logcat -c

REM Monitor logs with filter
if "%FILTER%"=="zego" (
    echo Monitoring Zego/Call Service logs...
    adb logcat | findstr /i /r "zego callservice token room"
) else if "%FILTER%"=="error" (
    echo Monitoring errors only...
    adb logcat | findstr /i /r "qglide zego callservice" | findstr /i /r "error exception failed"
) else if "%FILTER%"=="login" (
    echo Monitoring login/auth logs...
    adb logcat | findstr /i /r "login auth token zego callservice"
) else if "%FILTER%"=="api" (
    echo Monitoring API logs...
    adb logcat | findstr /i /r "api response token data keys"
) else if "%FILTER%"=="all" (
    echo Monitoring all logs...
    adb logcat
) else (
    echo Monitoring QGlide logs (filter: %FILTER%)...
    adb logcat | findstr /i "%FILTER%"
)


