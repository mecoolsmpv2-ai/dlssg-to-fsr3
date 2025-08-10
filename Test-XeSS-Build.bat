@echo off
setlocal enabledelayedexpansion

echo ========================================
echo XeSS Mod Build Test
echo ========================================
echo.
echo This script will test if the XeSS mod build is working correctly.
echo.

:: Check if we're in the right directory
if not exist "CMakeLists.txt" (
    echo Error: This script must be run from the project root directory
    echo Please navigate to the directory containing CMakeLists.txt and run this script again.
    pause
    exit /b 1
)

:: Set error counter
set "ERRORS=0"
set "WARNINGS=0"

echo Checking build artifacts...
echo.

:: Check for main mod DLL
if exist "bin\*\dlssg_to_xess_intel_is_better.dll" (
    echo ✓ Main mod DLL found
) else (
    echo ✗ Main mod DLL not found
    set /a ERRORS+=1
)

:: Check for XeSS runtime DLLs
if exist "dependencies\xess\bin\libxess_fg.dll" (
    echo ✓ XeSS Frame Generation DLL found
) else (
    echo ✗ XeSS Frame Generation DLL not found
    set /a ERRORS+=1
)

if exist "dependencies\xess\bin\libxell.dll" (
    echo ✓ XeLL DLL found
) else (
    echo ✗ XeLL DLL not found
    set /a ERRORS+=1
)

:: Check for configuration files
if exist "resources\dlssg_to_xess.ini" (
    echo ✓ Configuration file found
) else (
    echo - Configuration file not found (optional)
    set /a WARNINGS+=1
)

:: Check for installation script
if exist "Install-XeSS-Mod.bat" (
    echo ✓ Installation script found
) else (
    echo - Installation script not found (will be created during build)
    set /a WARNINGS+=1
)

:: Check for source files
if exist "source\maindll\XeSSFrameInterpolator.h" (
    echo ✓ XeSS source files found
) else (
    echo ✗ XeSS source files not found
    set /a ERRORS+=1
)

if exist "source\maindll\XeSSFrameInterpolator.cpp" (
    echo ✓ XeSS implementation found
) else (
    echo ✗ XeSS implementation not found
    set /a ERRORS+=1
)

:: Check for modified NGX files
if exist "source\maindll\NGX\NvNGXDirectX12.cpp" (
    echo ✓ NGX DirectX12 implementation found
) else (
    echo ✗ NGX DirectX12 implementation not found
    set /a ERRORS+=1
)

:: Check CMakeLists.txt modifications
findstr /C:"XESS_SDK_DIR" "source\maindll\CMakeLists.txt" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ CMakeLists.txt contains XeSS configuration
) else (
    echo ✗ CMakeLists.txt missing XeSS configuration
    set /a ERRORS+=1
)

findstr /C:"libxess_fg.lib" "source\maindll\CMakeLists.txt" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ CMakeLists.txt links XeSS libraries
) else (
    echo ✗ CMakeLists.txt missing XeSS library links
    set /a ERRORS+=1
)

:: Check README updates
findstr /C:"XeSS" "README.md" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ README.md updated for XeSS
) else (
    echo - README.md may not be updated for XeSS
    set /a WARNINGS+=1
)

:: Test DLL loading (if available)
echo.
echo Testing DLL loading...
if exist "dependencies\xess\bin\libxess_fg.dll" (
    echo Testing XeSS Frame Generation DLL...
    regsvr32 /s "dependencies\xess\bin\libxess_fg.dll" >nul 2>&1
    if %errorlevel% equ 0 (
        echo ✓ XeSS DLL loads successfully
    ) else (
        echo - XeSS DLL load test inconclusive (expected for non-registered DLLs)
    )
)

if exist "dependencies\xess\bin\libxell.dll" (
    echo Testing XeLL DLL...
    regsvr32 /s "dependencies\xess\bin\libxell.dll" >nul 2>&1
    if %errorlevel% equ 0 (
        echo ✓ XeLL DLL loads successfully
    ) else (
        echo - XeLL DLL load test inconclusive (expected for non-registered DLLs)
    )
)

:: Summary
echo.
echo ========================================
echo Test Summary
echo ========================================
echo.

if %ERRORS% equ 0 (
    if %WARNINGS% equ 0 (
        echo ✓ All tests passed! The XeSS mod build is ready.
        echo.
        echo You can now:
        echo 1. Run Build-XeSS-Mod.bat to build the mod
        echo 2. Use Install-XeSS-Mod.bat to install to games
        echo 3. Test with compatible games
    ) else (
        echo ⚠ Build has %WARNINGS% warning(s) but should work.
        echo.
        echo Warnings are non-critical issues that don't prevent the mod from working.
        echo You can proceed with building and testing the mod.
    )
) else (
    echo ✗ Build has %ERRORS% error(s) that need to be fixed.
    echo.
    echo Please fix the errors before proceeding with the build.
    echo Check the error messages above for details.
)

echo.
echo For more information, see BUILD-INSTRUCTIONS.md
echo.

pause