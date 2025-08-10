@echo off
setlocal enabledelayedexpansion

echo ========================================
echo XeSS Mod Environment Setup
echo ========================================
echo.
echo This script will help you set up the development environment
echo for building the DLSSG-to-XeSS mod.
echo.

:: Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Warning: This script is not running as administrator.
    echo Some operations may require elevated privileges.
    echo.
)

:: Create a setup log
set "LOG_FILE=%~dp0setup_log.txt"
echo XeSS Mod Environment Setup Log > "%LOG_FILE%"
echo Date: %date% %time% >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

:: Function to log messages
:log
echo %~1
echo %~1 >> "%LOG_FILE%"
goto :eof

:: Check Windows version
call :log "Checking Windows version..."
ver | findstr /i "10\.0\|11\.0" >nul
if %errorlevel% neq 0 (
    call :log "Warning: Windows 10/11 is recommended for XeSS support."
) else (
    call :log "Windows version: OK"
)

:: Check for Visual Studio 2022
call :log "Checking for Visual Studio 2022..."
set "VS_FOUND=0"
for %%v in (Community Professional Enterprise) do (
    if exist "C:\Program Files\Microsoft Visual Studio\2022\%%v\VC\Auxiliary\Build\vcvars64.bat" (
        call :log "Found Visual Studio 2022 %%v"
        set "VS_FOUND=1"
        set "VS_EDITION=%%v"
    )
)

if %VS_FOUND% equ 0 (
    call :log "Error: Visual Studio 2022 not found!"
    call :log "Please install Visual Studio 2022 with C++ development tools."
    call :log "Download from: https://visualstudio.microsoft.com/downloads/"
    goto :install_vs
) else (
    call :log "Visual Studio 2022: OK"
)

:: Check for Git
call :log "Checking for Git..."
where git >nul 2>&1
if %errorlevel% neq 0 (
    call :log "Error: Git not found!"
    call :log "Please install Git from: https://git-scm.com/download/win"
    goto :install_git
) else (
    git --version
    call :log "Git: OK"
)

:: Check for CMake
call :log "Checking for CMake..."
where cmake >nul 2>&1
if %errorlevel% neq 0 (
    call :log "Error: CMake not found!"
    call :log "Please install CMake from: https://cmake.org/download/"
    goto :install_cmake
) else (
    cmake --version
    call :log "CMake: OK"
)

:: Check for vcpkg
call :log "Checking for vcpkg..."
if not defined VCPKG_ROOT (
    call :log "Warning: VCPKG_ROOT environment variable not set."
    call :log "Setting up vcpkg..."
    goto :setup_vcpkg
) else (
    call :log "vcpkg: OK (VCPKG_ROOT=%VCPKG_ROOT%)"
)

:: Check for Vulkan SDK
call :log "Checking for Vulkan SDK..."
if not defined VULKAN_SDK (
    call :log "Warning: VULKAN_SDK environment variable not set."
    call :log "Setting up Vulkan SDK..."
    goto :setup_vulkan
) else (
    call :log "Vulkan SDK: OK (VULKAN_SDK=%VULKAN_SDK%)"
)

:: All checks passed
call :log "All required tools are installed!"
call :log "You can now run Build-XeSS-Mod.bat to build the mod."
goto :end

:install_vs
echo.
echo ========================================
echo Installing Visual Studio 2022
echo ========================================
echo.
echo Please download and install Visual Studio 2022 Community Edition:
echo https://visualstudio.microsoft.com/downloads/
echo.
echo Make sure to include:
echo - MSVC v143 - VS 2022 C++ x64/x86 build tools
echo - Windows 10/11 SDK
echo - CMake tools for Visual Studio
echo.
echo After installation, run this script again.
pause
goto :end

:install_git
echo.
echo ========================================
echo Installing Git
echo ========================================
echo.
echo Please download and install Git:
echo https://git-scm.com/download/win
echo.
echo After installation, run this script again.
pause
goto :end

:install_cmake
echo.
echo ========================================
echo Installing CMake
echo ========================================
echo.
echo Please download and install CMake:
echo https://cmake.org/download/
echo.
echo Make sure to add CMake to your system PATH during installation.
echo After installation, run this script again.
pause
goto :end

:setup_vcpkg
echo.
echo ========================================
echo Setting up vcpkg
echo ========================================
echo.
echo vcpkg is a C++ package manager. Would you like to install it now? (Y/N)
set /p choice="Choice: "
if /i "%choice%"=="Y" (
    echo Installing vcpkg...
    cd /d "%USERPROFILE%"
    git clone https://github.com/Microsoft/vcpkg.git
    cd vcpkg
    call bootstrap-vcpkg.bat
    call vcpkg integrate install
    
    echo Setting VCPKG_ROOT environment variable...
    setx VCPKG_ROOT "%USERPROFILE%\vcpkg"
    set "VCPKG_ROOT=%USERPROFILE%\vcpkg"
    
    call :log "vcpkg installed successfully!"
    call :log "VCPKG_ROOT set to: %VCPKG_ROOT%"
) else (
    call :log "vcpkg setup skipped."
)
goto :check_vulkan

:setup_vulkan
echo.
echo ========================================
echo Setting up Vulkan SDK
echo ========================================
echo.
echo Vulkan SDK is required for the build. Would you like to install it now? (Y/N)
set /p choice="Choice: "
if /i "%choice%"=="Y" (
    echo Please download and install Vulkan SDK from:
    echo https://vulkan.lunarg.com/sdk/home#windows
    echo.
    echo After installation, the VULKAN_SDK environment variable should be set automatically.
    echo If not, you may need to set it manually or restart your computer.
    pause
) else (
    call :log "Vulkan SDK setup skipped."
)
goto :end

:check_vulkan
:: Re-check Vulkan SDK after vcpkg setup
if not defined VULKAN_SDK (
    call :log "Warning: VULKAN_SDK still not set after vcpkg setup."
    call :log "You may need to install Vulkan SDK manually or restart your computer."
)

:end
echo.
echo ========================================
echo Setup Complete
echo ========================================
echo.
echo Setup log saved to: %LOG_FILE%
echo.
echo If all tools are installed correctly, you can now:
echo 1. Run Build-XeSS-Mod.bat to build the mod
echo 2. Or use the pre-built packages if available
echo.
echo For more information, see the README.md file.
echo.
pause