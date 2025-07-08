@echo off
echo Building Kubernetes Context Switcher Plugin...

REM Check if .NET is installed
dotnet --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: .NET 7.0 SDK is not installed or not in PATH
    echo Please install .NET 7.0 SDK from https://dotnet.microsoft.com/download
    pause
    exit /b 1
)

REM Clean previous builds
echo Cleaning previous builds...
dotnet clean

REM Build the project
echo Building project...
dotnet build -c Release

if %errorlevel% equ 0 (
    echo.
    echo Build successful!
    echo.
    echo To install the plugin:
    echo 1. Copy the entire KubernetesContextSwitcher folder to:
    echo    %%APPDATA%%\FlowLauncher\Plugins\
    echo 2. Restart Flow Launcher
    echo 3. Use 'k8s' to activate the plugin
    echo.
) else (
    echo.
    echo Build failed! Please check the error messages above.
    echo.
)

pause 