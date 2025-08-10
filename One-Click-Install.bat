@echo off
setlocal enabledelayedexpansion

echo ========================================
echo XeSS Mod One-Click Installer
echo ========================================
echo.
echo This script will quickly install missing dependencies
echo and build the XeSS mod automatically.
echo.

:: Check if we're in the right directory
if not exist "CMakeLists.txt" (
    echo Error: This script must be run from the project root directory
    echo Please navigate to the directory containing CMakeLists.txt and run this script again.
    pause
    exit /b 1
)

:: Create a simple log
set "LOG_FILE=%~dp0one_click_install.log"
echo XeSS Mod One-Click Install Log > "%LOG_FILE%"
echo Date: %date% %time% >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

echo Starting one-click installation...
echo.

:: Step 1: Quick check for essential tools
echo Checking for essential tools...

set "MISSING_TOOLS=0"

:: Check Git
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing Git...
    powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"
    call refreshenv
    choco install git -y
    call refreshenv
    set "MISSING_TOOLS=1"
)

:: Check CMake
where cmake >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing CMake...
    choco install cmake -y
    call refreshenv
    set "MISSING_TOOLS=1"
)

:: Check Visual Studio
set "VS_FOUND=0"
for %%v in (Community Professional Enterprise) do (
    if exist "C:\Program Files\Microsoft Visual Studio\2022\%%v\VC\Auxiliary\Build\vcvars64.bat" (
        set "VS_FOUND=1"
    )
)

if %VS_FOUND% equ 0 (
    echo Installing Visual Studio 2022 Build Tools...
    echo This may take several minutes. Please wait...
    
    powershell -Command "Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vs_buildtools.exe' -OutFile '%TEMP%\vs_buildtools.exe'"
    
    if exist "%TEMP%\vs_buildtools.exe" (
        "%TEMP%\vs_buildtools.exe" --quiet --wait --norestart --nocache ^
            --installPath "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools" ^
            --add Microsoft.VisualStudio.Workload.VCTools ^
            --add Microsoft.VisualStudio.Component.Windows10SDK.19041 ^
            --add Microsoft.VisualStudio.Component.CMake.Project
        set "MISSING_TOOLS=1"
    )
)

:: Step 2: Install vcpkg if needed
if not defined VCPKG_ROOT (
    echo Installing vcpkg...
    if not exist "%USERPROFILE%\vcpkg" (
        cd /d "%USERPROFILE%"
        git clone https://github.com/Microsoft/vcpkg.git
        cd vcpkg
        call bootstrap-vcpkg.bat
        call vcpkg integrate install
        set "VCPKG_ROOT=%USERPROFILE%\vcpkg"
        setx VCPKG_ROOT "%VCPKG_ROOT%"
        cd /d "%~dp0"
        set "MISSING_TOOLS=1"
    ) else (
        set "VCPKG_ROOT=%USERPROFILE%\vcpkg"
        setx VCPKG_ROOT "%VCPKG_ROOT%"
    )
)

:: Step 3: Install Vulkan SDK if needed
if not defined VULKAN_SDK (
    echo Installing Vulkan SDK...
    powershell -Command "Invoke-WebRequest -Uri 'https://sdk.lunarg.com/sdk/download/latest/windows/vulkan-sdk.exe' -OutFile '%TEMP%\vulkan-sdk.exe'"
    
    if exist "%TEMP%\vulkan-sdk.exe" (
        "%TEMP%\vulkan-sdk.exe" /S
        timeout /t 15 /nobreak >nul
        
        :: Try to find the installed SDK
        for /d %%d in ("C:\VulkanSDK\*") do (
            if exist "%%d\Bin\vulkan-1.dll" (
                set "VULKAN_SDK=%%d"
                setx VULKAN_SDK "!VULKAN_SDK!"
            )
        )
        set "MISSING_TOOLS=1"
    )
)

:: Step 4: Install vcpkg dependencies
if defined VCPKG_ROOT (
    if exist "%VCPKG_ROOT%\vcpkg.exe" (
        echo Installing vcpkg dependencies...
        "%VCPKG_ROOT%\vcpkg.exe" install spdlog:x64-windows-static
        "%VCPKG_ROOT%\vcpkg.exe" install detours:x64-windows-static
        "%VCPKG_ROOT%\vcpkg.exe" install directx-headers:x64-windows-static
        "%VCPKG_ROOT%\vcpkg.exe" install quickdllproxy:x64-windows-static
    )
)

:: Step 5: Set up project dependencies
echo Setting up project dependencies...

:: Initialize Git submodules
if exist ".git" (
    git submodule update --init --recursive
)

:: Check if XeSS SDK is available
if not exist "dependencies\xess" (
    echo Cloning XeSS SDK...
    if exist "dependencies" (
        cd dependencies
        git clone https://github.com/intel/xess.git
        cd ..
    )
) else (
    echo Updating XeSS SDK...
    cd dependencies\xess
    git pull origin main
    cd ..\..
)

:: Step 6: Try to build
echo.
echo ========================================
echo Attempting to build XeSS Mod...
echo ========================================
echo.

if %MISSING_TOOLS% equ 1 (
    echo New tools were installed. Please restart your command prompt
    echo and run this script again to complete the build.
    echo.
    echo Alternatively, you can try building manually:
    echo   Build-XeSS-Mod.bat
    echo   or
    echo   Simple-Build-XeSS-Mod.bat
    pause
    exit /b 0
)

:: Try to build using the simple build script
if exist "Simple-Build-XeSS-Mod.bat" (
    echo Running Simple-Build-XeSS-Mod.bat...
    call Simple-Build-XeSS-Mod.bat
) else if exist "Build-XeSS-Mod.bat" (
    echo Running Build-XeSS-Mod.bat...
    call Build-XeSS-Mod.bat
) else (
    echo No build script found. Trying manual build...
    
    :: Create build directory
    if not exist "build" mkdir build
    cd build
    
    :: Try CMake configuration
    cmake --preset final-universal
    if %errorlevel% equ 0 (
        cmake --build --preset final-universal-release
        if %errorlevel% equ 0 (
            echo Build completed successfully!
        ) else (
            echo Build failed. Please check the error messages above.
        )
    ) else (
        echo CMake configuration failed. Please check the error messages above.
    )
    
    cd ..
)

echo.
echo ========================================
echo Installation Complete!
echo ========================================
echo.
echo Installation log saved to: %LOG_FILE%
echo.
echo If the build was successful, you can find the output files in:
echo   build/bin/
echo.
echo To install the mod to a game, use:
echo   Install-XeSS-Mod.bat
echo.
pause