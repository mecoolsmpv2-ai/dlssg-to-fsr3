@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Building DLSSG-to-XeSS Mod
echo ========================================
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

:: Check for required tools
echo Checking for required tools...
echo.

:: Check for Visual Studio 2022
echo Checking for Visual Studio 2022...
where "cl.exe" >nul 2>&1
if %errorlevel% neq 0 (
    echo Setting up Visual Studio 2022 environment...
    call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1
    if %errorlevel% neq 0 (
        call "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1
        if %errorlevel% neq 0 (
            call "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1
            if %errorlevel% neq 0 (
                echo Error: Visual Studio 2022 not found. Please install Visual Studio 2022 with C++ development tools.
                set /a ErrorCount+=1
            )
        )
    )
)

:: Check for CMake
echo Checking for CMake...
where "cmake.exe" >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: CMake not found. Please install CMake and add it to your PATH.
    set /a ErrorCount+=1
) else (
    cmake --version
)

:: Check for Git
echo Checking for Git...
where "git.exe" >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Git not found. Please install Git and add it to your PATH.
    set /a ErrorCount+=1
)

:: Check for vcpkg
echo Checking for vcpkg...
if not defined VCPKG_ROOT (
    echo Warning: VCPKG_ROOT environment variable not set.
    echo Please set VCPKG_ROOT to your vcpkg installation directory.
    echo Example: set VCPKG_ROOT=C:\vcpkg
    set /a ErrorCount+=1
)

:: Check for Vulkan SDK
echo Checking for Vulkan SDK...
if not defined VULKAN_SDK (
    echo Warning: VULKAN_SDK environment variable not set.
    echo Please install Vulkan SDK and set VULKAN_SDK environment variable.
    echo Example: set VULKAN_SDK=C:\VulkanSDK\1.3.250.1
    set /a ErrorCount+=1
)

if %ErrorCount% gtr 0 (
    echo.
    echo Please fix the above errors before continuing.
    pause
    exit /b 1
)

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

:: Check if FidelityFX SDK is available (for reference, but we won't use it)
echo Checking FidelityFX SDK...
if not exist "dependencies\FidelityFX-SDK" (
    echo Warning: FidelityFX SDK not found. This is expected since we're using XeSS.
    echo The build will continue with XeSS only.
) else (
    echo FidelityFX SDK found (not needed for XeSS build).
)

cd build

:: Configure and build the project
echo.
echo ========================================
echo Building XeSS Mod...
echo ========================================
echo.

:: Build Universal version (recommended)
echo Building Universal version...
cmake --preset final-universal
if %errorlevel% neq 0 (
    echo Error: CMake configuration failed for Universal version
    pause
    exit /b 1
)

cmake --build --preset final-universal-release
if %errorlevel% neq 0 (
    echo Error: Build failed for Universal version
    pause
    exit /b 1
)

:: Build NVNGX wrapper version
echo.
echo Building NVNGX wrapper version...
cmake --preset final-nvngxwrapper
if %errorlevel% neq 0 (
    echo Error: CMake configuration failed for NVNGX wrapper version
    pause
    exit /b 1
)

cmake --build --preset final-nvngxwrapper-release
if %errorlevel% neq 0 (
    echo Error: Build failed for NVNGX wrapper version
    pause
    exit /b 1
)

:: Build DLSSTweaks wrapper version
echo.
echo Building DLSSTweaks wrapper version...
cmake --preset final-dtwrapper
if %errorlevel% neq 0 (
    echo Error: CMake configuration failed for DLSSTweaks wrapper version
    pause
    exit /b 1
)

cmake --build --preset final-dtwrapper-release
if %errorlevel% neq 0 (
    echo Error: Build failed for DLSSTweaks wrapper version
    pause
    exit /b 1
)

:: Create release packages
echo.
echo ========================================
echo Creating release packages...
echo ========================================
echo.

cpack --preset final-universal
if %errorlevel% neq 0 (
    echo Warning: Failed to create Universal package
)

cpack --preset final-nvngxwrapper
if %errorlevel% neq 0 (
    echo Warning: Failed to create NVNGX wrapper package
)

cpack --preset final-dtwrapper
if %errorlevel% neq 0 (
    echo Warning: Failed to create DLSSTweaks wrapper package
)

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

:: Create installation script
echo.
echo ========================================
echo Creating installation script...
echo ========================================
echo.

echo @echo off > "Install-XeSS-Mod.bat"
echo echo Installing DLSSG-to-XeSS Mod... >> "Install-XeSS-Mod.bat"
echo echo. >> "Install-XeSS-Mod.bat"
echo echo Please enter the path to your game directory: >> "Install-XeSS-Mod.bat"
echo set /p GAME_PATH="Game Path: " >> "Install-XeSS-Mod.bat"
echo echo. >> "Install-XeSS-Mod.bat"
echo if not exist "%%GAME_PATH%%" ( >> "Install-XeSS-Mod.bat"
echo     echo Error: Game directory not found! >> "Install-XeSS-Mod.bat"
echo     pause >> "Install-XeSS-Mod.bat"
echo     exit /b 1 >> "Install-XeSS-Mod.bat"
echo ) >> "Install-XeSS-Mod.bat"
echo echo Copying files to %%GAME_PATH%%... >> "Install-XeSS-Mod.bat"
echo copy "dlssg_to_xess_intel_is_better.dll" "%%GAME_PATH%%\" >> "Install-XeSS-Mod.bat"
echo copy "libxess_fg.dll" "%%GAME_PATH%%\" >> "Install-XeSS-Mod.bat"
echo copy "libxell.dll" "%%GAME_PATH%%\" >> "Install-XeSS-Mod.bat"
echo copy "dlssg_to_xess.ini" "%%GAME_PATH%%\" >> "Install-XeSS-Mod.bat"
echo echo. >> "Install-XeSS-Mod.bat"
echo echo Installation complete! >> "Install-XeSS-Mod.bat"
echo echo Please read the README for usage instructions. >> "Install-XeSS-Mod.bat"
echo pause >> "Install-XeSS-Mod.bat"

:: Copy installation script to output directories
for /d %%d in (bin\*) do (
    if exist "%%d\dlssg_to_xess_intel_is_better.dll" (
        copy "Install-XeSS-Mod.bat" "%%d\" >nul 2>&1
    )
)

:: Create README for the build
echo.
echo ========================================
echo Creating build README...
echo ========================================
echo.

echo DLSSG-to-XeSS Mod Build Complete! > "BUILD-README.txt"
echo. >> "BUILD-README.txt"
echo This mod replaces NVIDIA's DLSS Frame Generation with Intel's XeSS 2.1 Frame Generation. >> "BUILD-README.txt"
echo. >> "BUILD-README.txt"
echo Supported GPUs: >> "BUILD-README.txt"
echo - Intel Arc GPUs (with XMX support for best performance) >> "BUILD-README.txt"
echo - AMD Radeon GPUs (with Shader Model 6.4 support) >> "BUILD-README.txt"
echo - NVIDIA GeForce GPUs (with Shader Model 6.4 support) >> "BUILD-README.txt"
echo. >> "BUILD-README.txt"
echo Installation: >> "BUILD-README.txt"
echo 1. Run Install-XeSS-Mod.bat and follow the prompts >> "BUILD-README.txt"
echo 2. Or manually copy the DLL files to your game directory >> "BUILD-README.txt"
echo. >> "BUILD-README.txt"
echo Files included: >> "BUILD-README.txt"
echo - dlssg_to_xess_intel_is_better.dll (main mod DLL) >> "BUILD-README.txt"
echo - libxess_fg.dll (XeSS Frame Generation runtime) >> "BUILD-README.txt"
echo - libxell.dll (XeLL latency reduction runtime) >> "BUILD-README.txt"
echo - dlssg_to_xess.ini (debug configuration) >> "BUILD-README.txt"
echo. >> "BUILD-README.txt"
echo For more information, see the main README.md file. >> "BUILD-README.txt"

:: Copy README to output directories
for /d %%d in (bin\*) do (
    if exist "%%d\dlssg_to_xess_intel_is_better.dll" (
        copy "BUILD-README.txt" "%%d\" >nul 2>&1
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
echo - Install-XeSS-Mod.bat (installer)
echo - BUILD-README.txt (instructions)
echo.
echo Next steps:
echo 1. Run Install-XeSS-Mod.bat to install to a game
echo 2. Or manually copy files to your game directory
echo 3. Make sure your GPU supports Shader Model 6.4
echo.
echo Note: This mod requires the XeSS runtime DLLs to be present
echo in the same directory as the game executable.
echo.

cd ..

pause