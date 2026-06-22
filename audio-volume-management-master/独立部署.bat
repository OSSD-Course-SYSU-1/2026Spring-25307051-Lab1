@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo.
echo ========================================
echo   独立部署工具（不依赖 DevEco Studio）
echo ========================================
echo.
echo 说明：此脚本会独立完成所有部署步骤
echo       不需要 DevEco Studio 的参与
echo.

:: 设置路径
set PROJECT_DIR=d:\test\audio-volume-management-master
set PACKAGE_NAME=com.example.audiostreamvolumemanagement
set HAP_FILE=entry\build\default\outputs\default\entry-default-signed.hap
set ABILITY_NAME=EntryAbility

:: 步骤 1: 查找 HDC 工具
echo [步骤 1/7] 查找 HDC 工具...
set HDC_PATH=

for %%p in (
    "D:\DevEco Studio\tools\hdc\hdc.exe"
    "C:\Program Files\DevEco Studio\tools\hdc\hdc.exe"
    "C:\DevEco Studio\tools\hdc\hdc.exe"
    "E:\DevEco Studio\tools\hdc\hdc.exe"
) do (
    if exist %%p (
        set HDC_PATH=%%~p
        echo 找到 HDC: %%~p
        goto :hdc_found
    )
)

if "%HDC_PATH%"=="" (
    echo [错误] 未找到 HDC 工具
    echo.
    echo 请执行以下步骤：
    echo 1. 打开 DevEco Studio
    echo 2. 在底部工具栏点击 "HDC Terminal"
    echo 3. 在 Terminal 中输入: where hdc
    echo 4. 将显示的路径告诉我
    echo.
    pause
    exit /b 1
)

:hdc_found
echo.

:: 步骤 2: 检查设备连接
echo [步骤 2/7] 检查设备连接...
"%HDC_PATH%" list targets 2>&1 >nul
if errorlevel 1 (
    echo [错误] 未检测到设备连接
    echo.
    echo 请确保：
    echo 1. 设备已通过 USB 连接
    echo 2. 设备已开启开发者模式
    echo 3. 设备已授权 USB 调试
    echo.
    pause
    exit /b 1
)

echo 已连接的设备：
"%HDC_PATH%" list targets
echo.

:: 步骤 3: 强制卸载旧版本（多次尝试）
echo [步骤 3/7] 强制卸载旧版本应用...
echo.

echo 尝试方法 1: 正常卸载
"%HDC_PATH%" shell bm uninstall -n %PACKAGE_NAME% 2>nul
timeout /t 1 /nobreak >nul

echo 尝试方法 2: 强制停止后卸载
"%HDC_PATH%" shell aa force-stop %PACKAGE_NAME% 2>nul
"%HDC_PATH%" shell bm uninstall -n %PACKAGE_NAME% 2>nul
timeout /t 1 /nobreak >nul

echo 尝试方法 3: 再次卸载
"%HDC_PATH%" shell bm uninstall -n %PACKAGE_NAME% 2>nul
timeout /t 2 /nobreak >nul

echo 卸载完成
echo.

:: 步骤 4: 检查 HAP 文件是否存在
echo [步骤 4/7] 检查 HAP 文件...
if not exist "%HAP_FILE%" (
    echo [提示] HAP 文件不存在，需要先构建
    echo.
    goto :build
) else (
    echo [成功] HAP 文件已存在
    echo.
    goto :install
)

:build
:: 步骤 5: 构建项目
echo [步骤 5/7] 构建项目...
echo 这可能需要几分钟，请耐心等待...
echo.

cd /d "%PROJECT_DIR%"
call hvigorw clean >nul 2>&1
call hvigorw assembleHap

if errorlevel 1 (
    echo.
    echo [错误] 构建失败
    echo 请检查构建日志
    pause
    exit /b 1
)

echo.
echo [成功] 构建完成
echo.

:install
:: 步骤 6: 安装新版本
echo [步骤 6/7] 安装新版本应用...

if not exist "%HAP_FILE%" (
    echo [错误] 未找到 HAP 文件
    pause
    exit /b 1
)

set TEMP_DIR=data/local/tmp/deploy_%RANDOM%%TIME:~0,2%%TIME:~3,2%
"%HDC_PATH%" shell mkdir %TEMP_DIR% >nul 2>&1

echo 发送 HAP 文件到设备...
"%HDC_PATH%" file send "%HAP_FILE%" %TEMP_DIR% >nul 2>&1
if errorlevel 1 (
    echo [错误] 文件传输失败
    "%HDC_PATH%" shell rm -rf %TEMP_DIR% >nul 2>&1
    pause
    exit /b 1
)

echo 安装应用...
"%HDC_PATH%" shell bm install -p %TEMP_DIR% 2>&1
if errorlevel 1 (
    echo.
    echo [错误] 安装失败
    echo.
    echo 可能的原因：
    echo 1. 设备上仍有旧版本应用（签名不一致）
    echo 2. 设备存储空间不足
    echo.
    echo 解决方案：
    echo 1. 在设备上手动卸载应用
    echo 2. 重启设备后重试
    echo.
    "%HDC_PATH%" shell rm -rf %TEMP_DIR% >nul 2>&1
    pause
    exit /b 1
)

"%HDC_PATH%" shell rm -rf %TEMP_DIR% >nul 2>&1
echo [成功] 应用安装完成
echo.

:: 步骤 7: 启动应用
echo [步骤 7/7] 启动应用...
"%HDC_PATH%" shell aa start -a %ABILITY_NAME% -b %PACKAGE_NAME% >nul 2>&1
if errorlevel 1 (
    echo [警告] 应用启动失败，请手动启动
) else (
    echo [成功] 应用已启动
)
echo.

echo ========================================
echo   部署完成！
echo ========================================
echo.
echo 提示：
echo - 此脚本独立运行，不依赖 DevEco Studio
echo - 可以在任何时候运行此脚本
echo - 如果仍有签名问题，请在设备上手动卸载应用
echo.
pause
