@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Fixing XeSS Mod Build Environment
echo ========================================
echo.
echo This script will help fix the build environment issues.
echo.

:: Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Warning: This script is not running as administrator.
    echo Some operations may require elevated privileges.
    echo.
)

:: Create a fix log
set "LOG_FILE=%~dp0fix_environment_log.txt"
echo XeSS Mod Environment Fix Log > "%LOG_FILE%"
echo Date: %date% %time% >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

:: Function to log messages
:log
echo %~1
echo %~1 >> "%LOG_FILE%"
goto :eof

call :log "Starting environment fix process..."

:: Step 1: Fix Visual Studio 2022 detection
call :log "Step 1: Fixing Visual Studio 2022 detection..."

set "VS_FOUND=0"
set "VS_PATH="

:: Check common Visual Studio 2022 installation paths
for %%v in (Community Professional Enterprise) do (
    if exist "C:\Program Files\Microsoft Visual Studio\2022\%%v\VC\Auxiliary\Build\vcvars64.bat" (
        set "VS_FOUND=1"
        set "VS_PATH=C:\Program Files\Microsoft Visual Studio\2022\%%v"
        set "VS_EDITION=%%v"
        call :log "Found Visual Studio 2022 %%v at: !VS_PATH!"
    )
)

if %VS_FOUND% equ 0 (
    call :log "Visual Studio 2022 not found in standard locations."
    call :log "Checking for Visual Studio Build Tools..."
    
    if exist "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" (
        for /f "tokens=*" %%i in ('"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationpath') do (
            set "VS_PATH=%%i"
            set "VS_FOUND=1"
            call :log "Found Visual Studio installation at: !VS_PATH!"
        )
    )
)

if %VS_FOUND% equ 0 (
    call :log "ERROR: Visual Studio 2022 not found!"
    call :log "Please install Visual Studio 2022 with C++ development tools."
    call :log "Download from: https://visualstudio.microsoft.com/downloads/"
    call :log "Make sure to include:"
    call :log "- MSVC v143 - VS 2022 C++ x64/x86 build tools"
    call :log "- Windows 10/11 SDK"
    call :log "- CMake tools for Visual Studio"
    goto :install_vs
) else (
    call :log "Visual Studio 2022: FIXED"
    
    :: Try to set up the environment
    if exist "!VS_PATH!\VC\Auxiliary\Build\vcvars64.bat" (
        call :log "Setting up Visual Studio environment..."
        call "!VS_PATH!\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1
        if %errorlevel% equ 0 (
            call :log "Visual Studio environment set up successfully"
        ) else (
            call :log "Warning: Could not set up Visual Studio environment automatically"
        )
    )
)

:: Step 2: Fix vcpkg
call :log "Step 2: Fixing vcpkg..."

if not defined VCPKG_ROOT (
    call :log "VCPKG_ROOT not set. Setting up vcpkg..."
    
    :: Check if vcpkg exists in common locations
    set "VCPKG_FOUND=0"
    
    if exist "%USERPROFILE%\vcpkg\vcpkg.exe" (
        set "VCPKG_ROOT=%USERPROFILE%\vcpkg"
        set "VCPKG_FOUND=1"
        call :log "Found vcpkg at: %VCPKG_ROOT%"
    ) else if exist "C:\vcpkg\vcpkg.exe" (
        set "VCPKG_ROOT=C:\vcpkg"
        set "VCPKG_FOUND=1"
        call :log "Found vcpkg at: %VCPKG_ROOT%"
    ) else if exist "C:\dev\vcpkg\vcpkg.exe" (
        set "VCPKG_ROOT=C:\dev\vcpkg"
        set "VCPKG_FOUND=1"
        call :log "Found vcpkg at: %VCPKG_ROOT%"
    )
    
    if %VCPKG_FOUND% equ 0 (
        call :log "vcpkg not found. Would you like to install it? (Y/N)"
        set /p choice="Choice: "
        if /i "%choice%"=="Y" (
            goto :install_vcpkg
        ) else (
            call :log "vcpkg setup skipped. You may need to install it manually."
        )
    ) else (
        :: Set the environment variable
        call :log "Setting VCPKG_ROOT environment variable..."
        setx VCPKG_ROOT "%VCPKG_ROOT%"
        call :log "VCPKG_ROOT set to: %VCPKG_ROOT%"
    )
) else (
    call :log "VCPKG_ROOT already set to: %VCPKG_ROOT%"
)

:: Step 3: Fix Vulkan SDK
call :log "Step 3: Fixing Vulkan SDK..."

if not defined VULKAN_SDK (
    call :log "VULKAN_SDK not set. Looking for Vulkan SDK..."
    
    :: Check common Vulkan SDK installation paths
    set "VULKAN_FOUND=0"
    
    for /d %%d in ("C:\VulkanSDK\*") do (
        if exist "%%d\Bin\vulkan-1.dll" (
            set "VULKAN_SDK=%%d"
            set "VULKAN_FOUND=1"
            call :log "Found Vulkan SDK at: !VULKAN_SDK!"
        )
    )
    
    if %VULKAN_FOUND% equ 0 (
        call :log "Vulkan SDK not found. Would you like to install it? (Y/N)"
        set /p choice="Choice: "
        if /i "%choice%"=="Y" (
            goto :install_vulkan
        ) else (
            call :log "Vulkan SDK setup skipped. You may need to install it manually."
        )
    ) else (
        :: Set the environment variable
        call :log "Setting VULKAN_SDK environment variable..."
        setx VULKAN_SDK "!VULKAN_SDK!"
        call :log "VULKAN_SDK set to: !VULKAN_SDK!"
    )
) else (
    call :log "VULKAN_SDK already set to: %VULKAN_SDK%"
)

:: Step 4: Verify all tools
call :log "Step 4: Verifying all tools..."

:: Test Visual Studio
where cl >nul 2>&1
if %errorlevel% equ 0 (
    call :log "✓ Visual Studio compiler (cl.exe) found"
) else (
    call :log "✗ Visual Studio compiler not found in PATH"
    call :log "You may need to restart your command prompt or computer"
)

:: Test CMake
where cmake >nul 2>&1
if %errorlevel% equ 0 (
    cmake --version | findstr "version"
    call :log "✓ CMake found"
) else (
    call :log "✗ CMake not found in PATH"
)

:: Test Git
where git >nul 2>&1
if %errorlevel% equ 0 (
    git --version
    call :log "✓ Git found"
) else (
    call :log "✗ Git not found in PATH"
)

:: Test vcpkg
if defined VCPKG_ROOT (
    if exist "%VCPKG_ROOT%\vcpkg.exe" (
        call :log "✓ vcpkg found at: %VCPKG_ROOT%"
    ) else (
        call :log "✗ vcpkg.exe not found at: %VCPKG_ROOT%"
    )
) else (
    call :log "✗ VCPKG_ROOT not set"
)

:: Test Vulkan SDK
if defined VULKAN_SDK (
    if exist "%VULKAN_SDK%\Bin\vulkan-1.dll" (
        call :log "✓ Vulkan SDK found at: %VULKAN_SDK%"
    ) else (
        call :log "✗ Vulkan SDK files not found at: %VULKAN_SDK%"
    )
) else (
    call :log "✗ VULKAN_SDK not set"
)

goto :summary

:install_vs
echo.
echo ========================================
echo Installing Visual Studio 2022
echo ========================================
echo.
echo Please download and install Visual Studio 2022:
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

:install_vcpkg
echo.
echo ========================================
echo Installing vcpkg
echo ========================================
echo.
echo Installing vcpkg to %USERPROFILE%\vcpkg...
cd /d "%USERPROFILE%"
git clone https://github.com/Microsoft/vcpkg.git
if %errorlevel% neq 0 (
    call :log "ERROR: Failed to clone vcpkg repository"
    pause
    goto :end
)

cd vcpkg
call bootstrap-vcpkg.bat
if %errorlevel% neq 0 (
    call :log "ERROR: Failed to bootstrap vcpkg"
    pause
    goto :end
)

call vcpkg integrate install
if %errorlevel% neq 0 (
    call :log "WARNING: Failed to integrate vcpkg"
)

set "VCPKG_ROOT=%USERPROFILE%\vcpkg"
setx VCPKG_ROOT "%VCPKG_ROOT%"
call :log "vcpkg installed successfully at: %VCPKG_ROOT%"

cd /d "%~dp0"
goto :check_vulkan

:install_vulkan
echo.
echo ========================================
echo Installing Vulkan SDK
echo ========================================
echo.
echo Please download and install Vulkan SDK from:
echo https://vulkan.lunarg.com/sdk/home#windows
echo.
echo After installation, the VULKAN_SDK environment variable should be set automatically.
echo If not, you may need to restart your computer or set it manually.
echo.
pause
goto :end

:check_vulkan
:: Re-check Vulkan SDK after vcpkg setup
if not defined VULKAN_SDK (
    call :log "VULKAN_SDK still not set after vcpkg setup."
    call :log "You may need to install Vulkan SDK manually or restart your computer."
)

:summary
echo.
echo ========================================
echo Environment Fix Summary
echo ========================================
echo.
call :log "Environment fix process completed."

:: Check if we can now run the build
echo.
echo Testing if build environment is ready...
set "READY=1"

where cl >nul 2>&1
if %errorlevel% neq 0 (
    echo ✗ Visual Studio compiler not available
    set "READY=0"
)

where cmake >nul 2>&1
if %errorlevel% neq 0 (
    echo ✗ CMake not available
    set "READY=0"
)

where git >nul 2>&1
if %errorlevel% neq 0 (
    echo ✗ Git not available
    set "READY=0"
)

if not defined VCPKG_ROOT (
    echo ✗ VCPKG_ROOT not set
    set "READY=0"
)

if not defined VULKAN_SDK (
    echo ✗ VULKAN_SDK not set
    set "READY=0"
)

if %READY% equ 1 (
    echo.
    echo ✓ Build environment is ready!
    echo You can now run Build-XeSS-Mod.bat
    echo.
    
    echo Would you like to run the build now? (Y/N)
    set /p choice="Choice: "
    if /i "%choice%"=="Y" (
        echo.
        echo Starting build process...
        call Build-XeSS-Mod.bat
    )
) else (
    echo.
    echo ✗ Build environment is not ready.
    echo Please fix the issues above and run this script again.
    echo.
    echo You may need to:
    echo 1. Restart your command prompt to pick up new environment variables
    echo 2. Restart your computer if you installed new software
    echo 3. Install missing software manually
)

:end
echo.
echo Fix log saved to: %LOG_FILE%
echo.
pause