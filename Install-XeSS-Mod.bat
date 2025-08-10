@echo off
setlocal enabledelayedexpansion

echo ========================================
echo DLSSG-to-XeSS Mod Installer
echo ========================================
echo.
echo This installer will copy the XeSS mod files to your game directory.
echo.
echo Supported GPUs:
echo - Intel Arc GPUs (with XMX support for best performance)
echo - AMD Radeon GPUs (with Shader Model 6.4 support)
echo - NVIDIA GeForce GPUs (with Shader Model 6.4 support)
echo.

:: Check if we're in the right directory
if not exist "dlssg_to_xess_intel_is_better.dll" (
    echo Error: dlssg_to_xess_intel_is_better.dll not found!
    echo Please run this script from the directory containing the mod files.
    echo.
    pause
    exit /b 1
)

:: Get game directory from user
echo Please enter the path to your game directory.
echo Example: C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077\bin\x64
echo.
set /p GAME_PATH="Game Path: "

:: Validate game directory
if not exist "%GAME_PATH%" (
    echo.
    echo Error: Game directory not found!
    echo Please check the path and try again.
    echo.
    pause
    exit /b 1
)

echo.
echo Installing to: %GAME_PATH%
echo.

:: Check if game executable exists
set "EXE_FOUND=0"
for %%f in ("%GAME_PATH%\*.exe") do (
    set "EXE_FOUND=1"
    echo Found executable: %%~nxf
)

if %EXE_FOUND% equ 0 (
    echo Warning: No executable files found in the game directory.
    echo Are you sure this is the correct game directory?
    echo.
    set /p confirm="Continue anyway? (Y/N): "
    if /i not "!confirm!"=="Y" (
        echo Installation cancelled.
        pause
        exit /b 1
    )
)

:: Create backup directory
set "BACKUP_DIR=%GAME_PATH%\dlssg_to_xess_backup"
if not exist "%BACKUP_DIR%" (
    echo Creating backup directory...
    mkdir "%BACKUP_DIR%"
)

:: Backup existing files if they exist
echo Checking for existing mod files...
if exist "%GAME_PATH%\dlssg_to_fsr3_amd_is_better.dll" (
    echo Backing up existing FSR 3 mod...
    copy "%GAME_PATH%\dlssg_to_fsr3_amd_is_better.dll" "%BACKUP_DIR%\" >nul 2>&1
)

if exist "%GAME_PATH%\dlssg_to_fsr3.ini" (
    echo Backing up existing FSR 3 config...
    copy "%GAME_PATH%\dlssg_to_fsr3.ini" "%BACKUP_DIR%\" >nul 2>&1
)

:: Copy mod files
echo.
echo Copying XeSS mod files...
echo.

:: Main mod DLL
if exist "dlssg_to_xess_intel_is_better.dll" (
    copy "dlssg_to_xess_intel_is_better.dll" "%GAME_PATH%\" >nul 2>&1
    if !errorlevel! equ 0 (
        echo ✓ dlssg_to_xess_intel_is_better.dll
    ) else (
        echo ✗ Failed to copy dlssg_to_xess_intel_is_better.dll
        set "ERROR=1"
    )
) else (
    echo ✗ dlssg_to_xess_intel_is_better.dll not found
    set "ERROR=1"
)

:: XeSS runtime DLLs
if exist "libxess_fg.dll" (
    copy "libxess_fg.dll" "%GAME_PATH%\" >nul 2>&1
    if !errorlevel! equ 0 (
        echo ✓ libxess_fg.dll
    ) else (
        echo ✗ Failed to copy libxess_fg.dll
        set "ERROR=1"
    )
) else (
    echo ✗ libxess_fg.dll not found
    set "ERROR=1"
)

if exist "libxell.dll" (
    copy "libxell.dll" "%GAME_PATH%\" >nul 2>&1
    if !errorlevel! equ 0 (
        echo ✓ libxell.dll
    ) else (
        echo ✗ Failed to copy libxell.dll
        set "ERROR=1"
    )
) else (
    echo ✗ libxell.dll not found
    set "ERROR=1"
)

:: Configuration file
if exist "dlssg_to_xess.ini" (
    copy "dlssg_to_xess.ini" "%GAME_PATH%\" >nul 2>&1
    if !errorlevel! equ 0 (
        echo ✓ dlssg_to_xess.ini
    ) else (
        echo ✗ Failed to copy dlssg_to_xess.ini
    )
) else (
    echo - dlssg_to_xess.ini (optional, not found)
)

:: Registry files
if exist "DisableNvidiaSignatureChecks.reg" (
    copy "DisableNvidiaSignatureChecks.reg" "%GAME_PATH%\" >nul 2>&1
    echo ✓ DisableNvidiaSignatureChecks.reg
)

if exist "RestoreNvidiaSignatureChecks.reg" (
    copy "RestoreNvidiaSignatureChecks.reg" "%GAME_PATH%\" >nul 2>&1
    echo ✓ RestoreNvidiaSignatureChecks.reg
)

:: Check for errors
if defined ERROR (
    echo.
    echo Installation completed with errors!
    echo Some files may not have been copied correctly.
    echo Please check the error messages above.
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Installation Complete!
echo ========================================
echo.
echo The XeSS mod has been successfully installed to:
echo %GAME_PATH%
echo.
echo Files installed:
echo - dlssg_to_xess_intel_is_better.dll (main mod)
echo - libxess_fg.dll (XeSS Frame Generation)
echo - libxell.dll (XeLL latency reduction)
echo - dlssg_to_xess.ini (debug configuration)
echo.
echo Next steps:
echo 1. Make sure your GPU supports Shader Model 6.4
echo 2. Launch your game
echo 3. Enable DLSS Frame Generation in the game settings
echo 4. The mod will automatically replace DLSS with XeSS
echo.
echo Troubleshooting:
echo - Check the game directory for dlssg_to_xess.log
echo - Make sure all DLL files are in the same directory as the game executable
echo - For NVIDIA GPUs, you may need to run DisableNvidiaSignatureChecks.reg
echo.
echo Backup files are stored in: %BACKUP_DIR%
echo.
pause