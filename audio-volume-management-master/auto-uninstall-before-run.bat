@echo off
:: 自动卸载脚本 - 在 DevEco Studio 运行前自动执行
:: 此脚本会在每次运行应用前自动卸载旧版本，解决签名不一致问题

setlocal enabledelayedexpansion

:: 查找 HDC 工具
set HDC_PATH=
for %%p in (
    "D:\DevEco Studio\tools\hdc\hdc.exe"
    "C:\Program Files\DevEco Studio\tools\hdc\hdc.exe"
    "C:\DevEco Studio\tools\hdc\hdc.exe"
    "E:\DevEco Studio\tools\hdc\hdc.exe"
) do (
    if exist %%p (
        set HDC_PATH=%%~p
        goto :hdc_found
    )
)

:hdc_found
if "%HDC_PATH%"=="" (
    echo [提示] 未找到 HDC 工具，跳过自动卸载
    exit /b 0
)

:: 卸载应用（静默执行）
set PACKAGE_NAME=com.example.audiostreamvolumemanagement
"%HDC_PATH%" shell bm uninstall -n %PACKAGE_NAME% >nul 2>&1
"%HDC_PATH%" shell aa force-stop %PACKAGE_NAME% >nul 2>&1
"%HDC_PATH%" shell bm uninstall -n %PACKAGE_NAME% >nul 2>&1

echo [自动卸载] 已卸载旧版本应用

exit /b 0
