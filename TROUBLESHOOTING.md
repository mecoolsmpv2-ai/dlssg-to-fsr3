# XeSS Mod Build Troubleshooting Guide

This guide helps you resolve common issues when building the DLSSG-to-XeSS mod.

## Quick Fix Scripts

### Option 1: Automated Fix
Run `Fix-Build-Environment.bat` to automatically detect and fix most environment issues.

### Option 2: Simple Build
Run `Simple-Build-XeSS-Mod.bat` for a more flexible build process that handles missing environment variables.

## Common Issues and Solutions

### 1. Visual Studio 2022 Not Found

**Error**: `Error: Visual Studio 2022 not found`

**Solutions**:
1. **Install Visual Studio 2022**:
   - Download from: https://visualstudio.microsoft.com/downloads/
   - Choose Community (free), Professional, or Enterprise
   - During installation, select:
     - MSVC v143 - VS 2022 C++ x64/x86 build tools
     - Windows 10/11 SDK
     - CMake tools for Visual Studio

2. **Install Visual Studio Build Tools** (alternative):
   - Download Build Tools from: https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022
   - Install with C++ build tools

3. **Check Installation Path**:
   - Visual Studio 2022 is typically installed at:
     - `C:\Program Files\Microsoft Visual Studio\2022\Community\`
     - `C:\Program Files\Microsoft Visual Studio\2022\Professional\`
     - `C:\Program Files\Microsoft Visual Studio\2022\Enterprise\`

### 2. VCPKG_ROOT Not Set

**Error**: `Warning: VCPKG_ROOT environment variable not set`

**Solutions**:
1. **Automatic Installation**:
   - Run `Fix-Build-Environment.bat` and choose to install vcpkg
   - Or run `Simple-Build-XeSS-Mod.bat` and choose to install vcpkg

2. **Manual Installation**:
   ```cmd
   cd %USERPROFILE%
   git clone https://github.com/Microsoft/vcpkg.git
   cd vcpkg
   bootstrap-vcpkg.bat
   vcpkg integrate install
   setx VCPKG_ROOT "%USERPROFILE%\vcpkg"
   ```

3. **Check Common Locations**:
   - `%USERPROFILE%\vcpkg\`
   - `C:\vcpkg\`
   - `C:\dev\vcpkg\`

### 3. VULKAN_SDK Not Set

**Error**: `Warning: VULKAN_SDK environment variable not set`

**Solutions**:
1. **Install Vulkan SDK**:
   - Download from: https://vulkan.lunarg.com/sdk/home#windows
   - Install with default settings
   - Restart your command prompt after installation

2. **Manual Setup**:
   - Find your Vulkan SDK installation (typically `C:\VulkanSDK\1.x.x.x\`)
   - Set environment variable: `setx VULKAN_SDK "C:\VulkanSDK\1.x.x.x"`

3. **Check Common Locations**:
   - `C:\VulkanSDK\1.3.250.1\`
   - `C:\VulkanSDK\1.3.240.0\`
   - `C:\VulkanSDK\1.3.216.0\`

### 4. CMake Not Found

**Error**: `Error: CMake not found`

**Solutions**:
1. **Install CMake**:
   - Download from: https://cmake.org/download/
   - Choose Windows x64 Installer
   - During installation, select "Add CMake to the system PATH"

2. **Add to PATH manually**:
   - Find your CMake installation (typically `C:\Program Files\CMake\bin\`)
   - Add to system PATH environment variable

### 5. Git Not Found

**Error**: `Error: Git not found`

**Solutions**:
1. **Install Git**:
   - Download from: https://git-scm.com/download/win
   - Install with default settings
   - Git will be added to PATH automatically

### 6. CMake Configuration Fails

**Error**: `CMake configuration failed`

**Solutions**:
1. **Check Environment Variables**:
   ```cmd
   echo %VCPKG_ROOT%
   echo %VULKAN_SDK%
   ```

2. **Restart Command Prompt**:
   - Environment variables may not be loaded in current session
   - Close and reopen command prompt

3. **Use Alternative Build**:
   - Run `Simple-Build-XeSS-Mod.bat` instead
   - This script handles missing environment variables better

4. **Manual CMake Configuration**:
   ```cmd
   cmake -B build -S . -G "Visual Studio 17 2022" -A x64 -DCMAKE_TOOLCHAIN_FILE="%VCPKG_ROOT%/scripts/buildsystems/vcpkg.cmake" -DVCPKG_TARGET_TRIPLET=x64-windows-static
   ```

### 7. Build Fails with Compilation Errors

**Error**: Various compilation errors

**Solutions**:
1. **Check Visual Studio Installation**:
   - Ensure C++ build tools are installed
   - Try running Visual Studio Installer and modifying installation

2. **Update Dependencies**:
   ```cmd
   git submodule update --init --recursive
   ```

3. **Clean Build**:
   ```cmd
   rmdir /s build
   mkdir build
   cd build
   cmake --preset final-universal
   ```

### 8. XeSS SDK Not Found

**Error**: `XeSS SDK not found`

**Solutions**:
1. **Automatic Download**:
   - The build scripts should automatically clone the XeSS SDK
   - If it fails, try manually:
   ```cmd
   cd dependencies
   git clone https://github.com/intel/xess.git
   ```

2. **Check Network Connection**:
   - Ensure you have internet access
   - Check if GitHub is accessible

### 9. Missing DLLs After Build

**Error**: Runtime errors about missing DLLs

**Solutions**:
1. **Check Output Directory**:
   - Look in `bin\` directory for built DLLs
   - Ensure `libxess_fg.dll` and `libxell.dll` are copied

2. **Manual Copy**:
   ```cmd
   copy "dependencies\xess\bin\libxess_fg.dll" "bin\*\"
   copy "dependencies\xess\bin\libxell.dll" "bin\*\"
   ```

### 10. Environment Variables Not Persisting

**Issue**: Environment variables are lost after restarting command prompt

**Solutions**:
1. **Use setx Command**:
   ```cmd
   setx VCPKG_ROOT "C:\path\to\vcpkg"
   setx VULKAN_SDK "C:\path\to\VulkanSDK"
   ```

2. **Restart Computer**:
   - Some installations require a system restart

3. **Check System Environment Variables**:
   - Open System Properties → Environment Variables
   - Verify variables are set correctly

## Advanced Troubleshooting

### Check Build Logs
- Look for detailed error messages in the build output
- Check `fix_environment_log.txt` for environment setup issues

### Verify Tool Versions
```cmd
cmake --version
git --version
cl
```

### Test Individual Components
```cmd
# Test vcpkg
%VCPKG_ROOT%\vcpkg.exe --version

# Test Vulkan
%VULKAN_SDK%\Bin\vulkan-1.dll
```

### Alternative Build Methods
1. **Use Visual Studio IDE**:
   - Open the project in Visual Studio 2022
   - Build from the IDE interface

2. **Use PowerShell**:
   - Run `Make-Release.ps1` for PowerShell-based build

3. **Manual CMake**:
   - Use CMake GUI for configuration
   - Build with your preferred method

## Getting Help

If you're still having issues:

1. **Check the logs**: Look at `fix_environment_log.txt` and build output
2. **Verify prerequisites**: Ensure all required software is installed
3. **Try simple build**: Use `Simple-Build-XeSS-Mod.bat` for more flexible building
4. **Check system requirements**: Ensure Windows 10/11 and sufficient disk space

## System Requirements

- **OS**: Windows 10/11 (64-bit)
- **RAM**: 8GB minimum, 16GB recommended
- **Disk Space**: 10GB free space
- **GPU**: Any GPU with Shader Model 6.4 support
- **Internet**: Required for downloading dependencies