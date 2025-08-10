@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Simple XeSS Mod Builder
echo ========================================
echo.
echo This is a simplified build script that will help you build the XeSS mod
echo even if some environment variables are not set.
echo.

:: Check if we're running from the correct directory
if not exist "CMakeLists.txt" (
    echo Error: This script must be run from the project root directory
    echo Please navigate to the directory containing CMakeLists.txt and run this script again.
    pause
    exit /b 1
)

:: Set error handling
set "ErrorCount=0"
set "WarningCount=0"

echo Checking for required tools...
echo.

:: Check for Visual Studio 2022 - More flexible detection
echo Checking for Visual Studio 2022...
set "VS_FOUND=0"
set "VS_PATH="

:: Try multiple detection methods
for %%v in (Community Professional Enterprise) do (
    if exist "C:\Program Files\Microsoft Visual Studio\2022\%%v\VC\Auxiliary\Build\vcvars64.bat" (
        set "VS_FOUND=1"
        set "VS_PATH=C:\Program Files\Microsoft Visual Studio\2022\%%v"
        set "VS_EDITION=%%v"
        echo Found Visual Studio 2022 %%v
    )
)

:: Try vswhere if standard detection failed
if %VS_FOUND% equ 0 (
    if exist "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" (
        for /f "tokens=*" %%i in ('"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationpath') do (
            set "VS_PATH=%%i"
            set "VS_FOUND=1"
            echo Found Visual Studio installation via vswhere
        )
    )
)

if %VS_FOUND% equ 0 (
    echo Error: Visual Studio 2022 not found!
    echo Please install Visual Studio 2022 with C++ development tools.
    echo Download from: https://visualstudio.microsoft.com/downloads/
    echo.
    echo Make sure to include:
    echo - MSVC v143 - VS 2022 C++ x64/x86 build tools
    echo - Windows 10/11 SDK
    echo - CMake tools for Visual Studio
    set /a ErrorCount+=1
) else (
    echo Visual Studio 2022: OK
    :: Try to set up the environment
    if exist "!VS_PATH!\VC\Auxiliary\Build\vcvars64.bat" (
        echo Setting up Visual Studio environment...
        call "!VS_PATH!\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1
    )
)

:: Check for CMake
echo Checking for CMake...
where "cmake.exe" >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: CMake not found. Please install CMake and add it to your PATH.
    echo Download from: https://cmake.org/download/
    set /a ErrorCount+=1
) else (
    cmake --version
    echo CMake: OK
)

:: Check for Git
echo Checking for Git...
where "git.exe" >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Git not found. Please install Git and add it to your PATH.
    echo Download from: https://git-scm.com/download/win
    set /a ErrorCount+=1
) else (
    git --version
    echo Git: OK
)

:: Check for vcpkg - More flexible
echo Checking for vcpkg...
set "VCPKG_FOUND=0"

if defined VCPKG_ROOT (
    if exist "%VCPKG_ROOT%\vcpkg.exe" (
        set "VCPKG_FOUND=1"
        echo vcpkg: OK (VCPKG_ROOT=%VCPKG_ROOT%)
    )
)

if %VCPKG_FOUND% equ 0 (
    :: Try to find vcpkg in common locations
    if exist "%USERPROFILE%\vcpkg\vcpkg.exe" (
        set "VCPKG_ROOT=%USERPROFILE%\vcpkg"
        set "VCPKG_FOUND=1"
        echo vcpkg: Found at %VCPKG_ROOT%
    ) else if exist "C:\vcpkg\vcpkg.exe" (
        set "VCPKG_ROOT=C:\vcpkg"
        set "VCPKG_FOUND=1"
        echo vcpkg: Found at %VCPKG_ROOT%
    ) else if exist "C:\dev\vcpkg\vcpkg.exe" (
        set "VCPKG_ROOT=C:\dev\vcpkg"
        set "VCPKG_FOUND=1"
        echo vcpkg: Found at %VCPKG_ROOT%
    )
)

if %VCPKG_FOUND% equ 0 (
    echo Warning: vcpkg not found. Would you like to install it now? (Y/N)
    set /p choice="Choice: "
    if /i "%choice%"=="Y" (
        echo Installing vcpkg...
        cd /d "%USERPROFILE%"
        git clone https://github.com/Microsoft/vcpkg.git
        if %errorlevel% equ 0 (
            cd vcpkg
            call bootstrap-vcpkg.bat
            call vcpkg integrate install
            set "VCPKG_ROOT=%USERPROFILE%\vcpkg"
            setx VCPKG_ROOT "%VCPKG_ROOT%"
            echo vcpkg installed successfully at %VCPKG_ROOT%
            cd /d "%~dp0"
        ) else (
            echo Failed to install vcpkg
            set /a ErrorCount+=1
        )
    ) else (
        echo vcpkg setup skipped. Build may fail.
        set /a WarningCount+=1
    )
)

:: Check for Vulkan SDK - More flexible
echo Checking for Vulkan SDK...
set "VULKAN_FOUND=0"

if defined VULKAN_SDK (
    if exist "%VULKAN_SDK%\Bin\vulkan-1.dll" (
        set "VULKAN_FOUND=1"
        echo Vulkan SDK: OK (VULKAN_SDK=%VULKAN_SDK%)
    )
)

if %VULKAN_FOUND% equ 0 (
    :: Try to find Vulkan SDK in common locations
    for /d %%d in ("C:\VulkanSDK\*") do (
        if exist "%%d\Bin\vulkan-1.dll" (
            set "VULKAN_SDK=%%d"
            set "VULKAN_FOUND=1"
            echo Vulkan SDK: Found at !VULKAN_SDK!
        )
    )
)

if %VULKAN_FOUND% equ 0 (
    echo Warning: Vulkan SDK not found. Would you like to install it now? (Y/N)
    set /p choice="Choice: "
    if /i "%choice%"=="Y" (
        echo Please download and install Vulkan SDK from:
        echo https://vulkan.lunarg.com/sdk/home#windows
        echo.
        echo After installation, restart your command prompt and run this script again.
        pause
        exit /b 1
    ) else (
        echo Vulkan SDK setup skipped. Build may fail.
        set /a WarningCount+=1
    )
)

if %ErrorCount% gtr 0 (
    echo.
    echo Please fix the above errors before continuing.
    pause
    exit /b 1
)

echo.
echo All required tools found!
echo.

:: Create build directory
echo Creating build directory...
if not exist "build" mkdir build
cd build

:: Initialize and update submodules
echo.
echo ========================================
echo Setting up dependencies...
echo ========================================
echo.

cd ..
echo Initializing Git submodules...
git submodule update --init --recursive
if %errorlevel% neq 0 (
    echo Error: Failed to initialize Git submodules
    pause
    exit /b 1
)

:: Check if XeSS SDK is available
echo Checking XeSS SDK...
if not exist "dependencies\xess" (
    echo XeSS SDK not found. Cloning from Intel repository...
    cd dependencies
    git clone https://github.com/intel/xess.git
    if %errorlevel% neq 0 (
        echo Error: Failed to clone XeSS SDK
        pause
        exit /b 1
    )
    cd ..
) else (
    echo XeSS SDK found. Updating...
    cd dependencies\xess
    git pull origin main
    cd ..\..
)

cd build

:: Try to build with current environment
echo.
echo ========================================
echo Attempting to build XeSS Mod...
echo ========================================
echo.

:: Set environment variables if not already set
if not defined VCPKG_ROOT (
    echo Setting VCPKG_ROOT environment variable for this session...
    set "VCPKG_ROOT=%VCPKG_ROOT%"
)

if not defined VULKAN_SDK (
    echo Setting VULKAN_SDK environment variable for this session...
    set "VULKAN_SDK=%VULKAN_SDK%"
)

:: Try to build Universal version first
echo Building Universal version...
cmake --preset final-universal
if %errorlevel% neq 0 (
    echo.
    echo CMake configuration failed. This might be due to missing environment variables.
    echo.
    echo Trying alternative approach...
    echo.
    
    :: Try manual CMake configuration
    cmake -B build-universal -S .. -G "Visual Studio 17 2022" -A x64 -DCMAKE_TOOLCHAIN_FILE="%VCPKG_ROOT%/scripts/buildsystems/vcpkg.cmake" -DVCPKG_TARGET_TRIPLET=x64-windows-static -DBUILD_OUTPUT_WRAPPER=UNIVERSAL
    if %errorlevel% neq 0 (
        echo Error: Alternative CMake configuration also failed.
        echo.
        echo Please ensure you have:
        echo 1. Visual Studio 2022 with C++ tools installed
        echo 2. vcpkg properly installed and VCPKG_ROOT set
        echo 3. Vulkan SDK installed and VULKAN_SDK set
        echo.
        echo You can run Fix-Build-Environment.bat to help set up the environment.
        pause
        exit /b 1
    )
    
    echo Alternative CMake configuration successful!
    cmake --build build-universal --config Release
    if %errorlevel% neq 0 (
        echo Error: Build failed
        pause
        exit /b 1
    )
    
    echo Build completed successfully!
    goto :copy_files
) else (
    echo CMake configuration successful!
    cmake --build --preset final-universal-release
    if %errorlevel% neq 0 (
        echo Error: Build failed for Universal version
        pause
        exit /b 1
    )
)

:copy_files
:: Copy XeSS DLLs to output directories
echo.
echo ========================================
echo Copying XeSS runtime files...
echo ========================================
echo.

:: Find the bin directory
for /d %%d in (bin\*) do (
    if exist "%%d\dlssg_to_xess_intel_is_better.dll" (
        echo Copying XeSS DLLs to %%d...
        copy "dependencies\xess\bin\libxess_fg.dll" "%%d\" >nul 2>&1
        copy "dependencies\xess\bin\libxell.dll" "%%d\" >nul 2>&1
        copy "resources\dlssg_to_xess.ini" "%%d\" >nul 2>&1
        copy "resources\DisableNvidiaSignatureChecks.reg" "%%d\" >nul 2>&1
        copy "resources\RestoreNvidiaSignatureChecks.reg" "%%d\" >nul 2>&1
    )
)

:: Summary
echo.
echo ========================================
echo Build Summary
echo ========================================
echo.
echo Build completed successfully!
echo.
echo Output directories:
for /d %%d in (bin\*) do (
    if exist "%%d\dlssg_to_xess_intel_is_better.dll" (
        echo - %%d
    )
)
echo.
echo Files created:
echo - dlssg_to_xess_intel_is_better.dll (main mod)
echo - libxess_fg.dll (XeSS Frame Generation)
echo - libxell.dll (XeLL latency reduction)
echo - dlssg_to_xess.ini (debug config)
echo.
echo Next steps:
echo 1. Use Install-XeSS-Mod.bat to install to a game
echo 2. Or manually copy files to your game directory
echo 3. Make sure your GPU supports Shader Model 6.4
echo.

cd ..

pause