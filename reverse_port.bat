@echo off
chcp 65001 >nul
title KET NOI DIEN THOAI THAT VOI C# WEB API

echo ======================================================================
echo    TIEN ICH CHUYEN TIEP CONG 5000 SANG DIEN THOAI THAT (ADB REVERSE)
echo ======================================================================
echo.

set ADB_EXE=adb

where adb >nul 2>&1
if %errorlevel% neq 0 (
    if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" (
        set ADB_EXE="%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
    )
)

echo [*] Dang kiem tra thiet bi dien thoai ket noi qua cap USB...
%ADB_EXE% devices
echo.

echo [*] Dang chuyen tiep cong 5000 (C# Web API)...
%ADB_EXE% reverse tcp:5000 tcp:5000

if %errorlevel% equ 0 (
    echo.
    echo ======================================================================
    echo  [THANH CONG] Dien thoai da noi thanh cong voi C# API qua cong 5000!
    echo  Bay gio ban co the mo App tren dien thoai that de su dung:
    echo  - Dang nhap / Dang ky tai khoan thuc te
    echo  - Xem thuc don, danh gia, dat mon, thanh toan VNPay
    echo ======================================================================
) else (
    echo.
    echo ======================================================================
    echo  [CHU Y] Khong the gui lenh den dien thoai. Vui long kiem tra:
    echo  1. Da cam cap USB noi dien thoai vao may tinh chua?
    echo  2. Da bat 'Tuy chon nha phat trien' ^> 'Go loi USB' (USB Debugging)?
    echo  3. Tren man hinh dien thoai da chon 'Cho phep' (Allow USB Debugging)?
    echo ======================================================================
)

echo.
pause

