@echo off
setlocal enabledelayedexpansion

echo ========================================
echo XeSS Mod Windows Auto-Installation
echo ========================================
echo.
echo This script will automatically install all necessary components
echo to build the XeSS mod on Windows.
echo.

:: Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Warning: This script is not running as administrator.
    echo Some installations may require elevated privileges.
    echo.
)

:: Create installation log
set "LOG_FILE=%~dp0auto_install_log.txt"
echo XeSS Mod Auto-Installation Log > "%LOG_FILE%"
echo Date: %date% %time% >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

:: Function to log messages
:log
echo %~1
echo %~1 >> "%LOG_FILE%"
goto :eof

call :log "Starting automatic installation process..."

:: Step 1: Install Chocolatey (if not present)
call :log "Step 1: Checking for Chocolatey package manager..."
where choco >nul 2>&1
if %errorlevel% neq 0 (
    call :log "Chocolatey not found. Installing Chocolatey..."
    echo Installing Chocolatey package manager...
    powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    if %errorlevel% equ 0 (
        call :log "Chocolatey installed successfully"
        :: Refresh environment
        call refreshenv
    ) else (
        call :log "Failed to install Chocolatey. Trying alternative method..."
        echo Please install Chocolatey manually from: https://chocolatey.org/install
        pause
    )
) else (
    call :log "Chocolatey already installed"
)

:: Step 2: Install Git
call :log "Step 2: Installing Git..."
where git >nul 2>&1
if %errorlevel% neq 0 (
    call :log "Git not found. Installing Git..."
    choco install git -y
    if %errorlevel% equ 0 (
        call :log "Git installed successfully"
        :: Refresh environment
        call refreshenv
    ) else (
        call :log "Failed to install Git via Chocolatey. Trying manual download..."
        echo Please download and install Git from: https://git-scm.com/download/win
        pause
    )
) else (
    git --version
    call :log "Git already installed"
)

:: Step 3: Install CMake
call :log "Step 3: Installing CMake..."
where cmake >nul 2>&1
if %errorlevel% neq 0 (
    call :log "CMake not found. Installing CMake..."
    choco install cmake -y
    if %errorlevel% equ 0 (
        call :log "CMake installed successfully"
        :: Refresh environment
        call refreshenv
    ) else (
        call :log "Failed to install CMake via Chocolatey. Trying manual download..."
        echo Please download and install CMake from: https://cmake.org/download/
        pause
    )
) else (
    cmake --version
    call :log "CMake already installed"
)

:: Step 4: Install Visual Studio 2022 Build Tools
call :log "Step 4: Installing Visual Studio 2022 Build Tools..."
set "VS_FOUND=0"

:: Check for Visual Studio 2022
for %%v in (Community Professional Enterprise) do (
    if exist "C:\Program Files\Microsoft Visual Studio\2022\%%v\VC\Auxiliary\Build\vcvars64.bat" (
        set "VS_FOUND=1"
        call :log "Visual Studio 2022 %%v found"
    )
)

:: Check for Build Tools
if exist "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" (
    for /f "tokens=*" %%i in ('"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationpath') do (
        set "VS_FOUND=1"
        call :log "Visual Studio Build Tools found"
    )
)

if %VS_FOUND% equ 0 (
    call :log "Visual Studio 2022 not found. Installing Build Tools..."
    echo Installing Visual Studio 2022 Build Tools...
    echo This may take a while. Please wait...
    
    :: Download Visual Studio Build Tools installer
    powershell -Command "Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vs_buildtools.exe' -OutFile '%TEMP%\vs_buildtools.exe'"
    
    if exist "%TEMP%\vs_buildtools.exe" (
        echo Running Visual Studio Build Tools installer...
        "%TEMP%\vs_buildtools.exe" --quiet --wait --norestart --nocache ^
            --installPath "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools" ^
            --add Microsoft.VisualStudio.Workload.VCTools ^
            --add Microsoft.VisualStudio.Component.Windows10SDK.19041 ^
            --add Microsoft.VisualStudio.Component.CMake.Project
        
        if %errorlevel% equ 0 (
            call :log "Visual Studio Build Tools installed successfully"
        ) else (
            call :log "Failed to install Visual Studio Build Tools automatically"
            echo Please install Visual Studio 2022 Build Tools manually from:
            echo https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022
            pause
        )
    ) else (
        call :log "Failed to download Visual Studio Build Tools installer"
        echo Please install Visual Studio 2022 Build Tools manually from:
        echo https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022
        pause
    )
) else (
    call :log "Visual Studio 2022 already installed"
)

:: Step 5: Install vcpkg
call :log "Step 5: Installing vcpkg..."
if not defined VCPKG_ROOT (
    call :log "VCPKG_ROOT not set. Installing vcpkg..."
    
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
    )
    
    if %VCPKG_FOUND% equ 0 (
        call :log "vcpkg not found. Installing vcpkg..."
        echo Installing vcpkg to %USERPROFILE%\vcpkg...
        
        cd /d "%USERPROFILE%"
        git clone https://github.com/Microsoft/vcpkg.git
        if %errorlevel% equ 0 (
            cd vcpkg
            call bootstrap-vcpkg.bat
            if %errorlevel% equ 0 (
                call vcpkg integrate install
                set "VCPKG_ROOT=%USERPROFILE%\vcpkg"
                setx VCPKG_ROOT "%VCPKG_ROOT%"
                call :log "vcpkg installed successfully at %VCPKG_ROOT%"
            ) else (
                call :log "Failed to bootstrap vcpkg"
            )
        ) else (
            call :log "Failed to clone vcpkg repository"
        )
        
        cd /d "%~dp0"
    ) else (
        :: Set the environment variable
        call :log "Setting VCPKG_ROOT environment variable..."
        setx VCPKG_ROOT "%VCPKG_ROOT%"
        call :log "VCPKG_ROOT set to: %VCPKG_ROOT%"
    )
) else (
    call :log "VCPKG_ROOT already set to: %VCPKG_ROOT%"
)

:: Step 6: Install Vulkan SDK
call :log "Step 6: Installing Vulkan SDK..."
if not defined VULKAN_SDK (
    call :log "VULKAN_SDK not set. Installing Vulkan SDK..."
    
    :: Check if Vulkan SDK exists in common locations
    set "VULKAN_FOUND=0"
    
    for /d %%d in ("C:\VulkanSDK\*") do (
        if exist "%%d\Bin\vulkan-1.dll" (
            set "VULKAN_SDK=%%d"
            set "VULKAN_FOUND=1"
            call :log "Found Vulkan SDK at: !VULKAN_SDK!"
        )
    )
    
    if %VULKAN_FOUND% equ 0 (
        call :log "Vulkan SDK not found. Installing Vulkan SDK..."
        echo Installing Vulkan SDK...
        
        :: Download Vulkan SDK installer
        powershell -Command "Invoke-WebRequest -Uri 'https://sdk.lunarg.com/sdk/download/latest/windows/vulkan-sdk.exe' -OutFile '%TEMP%\vulkan-sdk.exe'"
        
        if exist "%TEMP%\vulkan-sdk.exe" (
            echo Running Vulkan SDK installer...
            "%TEMP%\vulkan-sdk.exe" /S
            if %errorlevel% equ 0 (
                call :log "Vulkan SDK installed successfully"
                :: Wait a moment for installation to complete
                timeout /t 10 /nobreak >nul
                
                :: Try to find the installed SDK
                for /d %%d in ("C:\VulkanSDK\*") do (
                    if exist "%%d\Bin\vulkan-1.dll" (
                        set "VULKAN_SDK=%%d"
                        setx VULKAN_SDK "!VULKAN_SDK!"
                        call :log "VULKAN_SDK set to: !VULKAN_SDK!"
                    )
                )
            ) else (
                call :log "Failed to install Vulkan SDK automatically"
                echo Please download and install Vulkan SDK from:
                echo https://vulkan.lunarg.com/sdk/home#windows
                pause
            )
        ) else (
            call :log "Failed to download Vulkan SDK installer"
            echo Please download and install Vulkan SDK from:
            echo https://vulkan.lunarg.com/sdk/home#windows
            pause
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

:: Step 7: Install additional dependencies via vcpkg
call :log "Step 7: Installing additional dependencies..."
if defined VCPKG_ROOT (
    if exist "%VCPKG_ROOT%\vcpkg.exe" (
        call :log "Installing spdlog..."
        "%VCPKG_ROOT%\vcpkg.exe" install spdlog:x64-windows-static
        
        call :log "Installing detours..."
        "%VCPKG_ROOT%\vcpkg.exe" install detours:x64-windows-static
        
        call :log "Installing directx-headers..."
        "%VCPKG_ROOT%\vcpkg.exe" install directx-headers:x64-windows-static
        
        call :log "Installing quickdllproxy..."
        "%VCPKG_ROOT%\vcpkg.exe" install quickdllproxy:x64-windows-static
    ) else (
        call :log "vcpkg.exe not found at %VCPKG_ROOT%"
    )
) else (
    call :log "VCPKG_ROOT not set, skipping vcpkg dependencies"
)

:: Step 8: Verify all installations
call :log "Step 8: Verifying installations..."

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

:: Step 9: Set up the project
call :log "Step 9: Setting up the project..."

:: Initialize Git submodules
if exist ".git" (
    call :log "Initializing Git submodules..."
    git submodule update --init --recursive
    if %errorlevel% equ 0 (
        call :log "Git submodules initialized successfully"
    ) else (
        call :log "Failed to initialize Git submodules"
    )
) else (
    call :log "Not a Git repository, skipping submodule initialization"
)

:: Check if XeSS SDK is available
if not exist "dependencies\xess" (
    call :log "XeSS SDK not found. Cloning from Intel repository..."
    if exist "dependencies" (
        cd dependencies
        git clone https://github.com/intel/xess.git
        if %errorlevel% equ 0 (
            call :log "XeSS SDK cloned successfully"
        ) else (
            call :log "Failed to clone XeSS SDK"
        )
        cd ..
    ) else (
        call :log "dependencies directory not found"
    )
) else (
    call :log "XeSS SDK found. Updating..."
    cd dependencies\xess
    git pull origin main
    cd ..\..
)

:: Step 10: Test build environment
call :log "Step 10: Testing build environment..."

:: Check if we can now run the build
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
    echo Please restart your command prompt and run this script again.
    echo.
    echo You may need to:
    echo 1. Restart your command prompt to pick up new environment variables
    echo 2. Restart your computer if you installed new software
    echo 3. Install missing software manually
)

:: Summary
echo.
echo ========================================
echo Installation Summary
echo ========================================
echo.
call :log "Auto-installation process completed."

echo Installation log saved to: %LOG_FILE%
echo.
echo Next steps:
echo 1. Restart your command prompt to pick up new environment variables
echo 2. Run Build-XeSS-Mod.bat to build the XeSS mod
echo 3. Or run Simple-Build-XeSS-Mod.bat for a more flexible build
echo.
echo For troubleshooting, see TROUBLESHOOTING.md
echo.

pause