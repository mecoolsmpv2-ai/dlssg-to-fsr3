# Windows Installation Guide for XeSS Mod

This guide provides multiple ways to install and build the XeSS mod on Windows, from the simplest one-click installation to manual setup.

## Quick Start Options

### Option 1: One-Click Installation (Recommended)
**For users who want the easiest setup:**

1. **Download the project** (if you haven't already)
2. **Run the one-click installer:**
   ```cmd
   One-Click-Install.bat
   ```
3. **Follow the prompts** - the script will automatically:
   - Install missing dependencies
   - Set up the build environment
   - Build the XeSS mod
   - Provide installation instructions

### Option 2: Auto-Installation with Manual Build
**For users who want more control:**

1. **Run the auto-installation script:**
   ```cmd
   Auto-Install-Windows.bat
   ```
2. **Restart your command prompt** (to pick up new environment variables)
3. **Run the build script:**
   ```cmd
   Build-XeSS-Mod.bat
   ```

### Option 3: Manual Installation
**For advanced users or troubleshooting:**

1. **Install dependencies manually** (see sections below)
2. **Run the simple build script:**
   ```cmd
   Simple-Build-XeSS-Mod.bat
   ```

## Required Dependencies

### Essential Tools

#### 1. **Visual Studio 2022** (or Build Tools)
- **Download**: https://visualstudio.microsoft.com/downloads/
- **Required Components**:
  - MSVC v143 - VS 2022 C++ x64/x86 build tools
  - Windows 10/11 SDK
  - CMake tools for Visual Studio

#### 2. **Git**
- **Download**: https://git-scm.com/download/win
- **Installation**: Use default settings

#### 3. **CMake**
- **Download**: https://cmake.org/download/
- **Installation**: Choose "Add CMake to the system PATH"

#### 4. **vcpkg** (C++ Package Manager)
- **Installation**:
  ```cmd
  cd %USERPROFILE%
  git clone https://github.com/Microsoft/vcpkg.git
  cd vcpkg
  bootstrap-vcpkg.bat
  vcpkg integrate install
  setx VCPKG_ROOT "%USERPROFILE%\vcpkg"
  ```

#### 5. **Vulkan SDK**
- **Download**: https://vulkan.lunarg.com/sdk/home#windows
- **Installation**: Use default settings

### vcpkg Dependencies

The following packages will be installed automatically by the scripts:
- `spdlog` - Logging library
- `detours` - API hooking library
- `directx-headers` - DirectX headers
- `quickdllproxy` - DLL proxy library

## Installation Scripts Explained

### `One-Click-Install.bat`
**Purpose**: Complete automation for new users
**Features**:
- Installs all missing dependencies automatically
- Downloads and installs Visual Studio Build Tools
- Sets up vcpkg and installs required packages
- Downloads and installs Vulkan SDK
- Attempts to build the project automatically
- Provides clear instructions for next steps

**Best for**: Users who want the simplest possible setup

### `Auto-Install-Windows.bat`
**Purpose**: Comprehensive dependency installation
**Features**:
- Detailed logging of all operations
- Step-by-step installation process
- Verification of all installations
- Project setup and dependency cloning
- Environment variable configuration
- Option to run build after installation

**Best for**: Users who want to understand what's being installed

### `Simple-Build-XeSS-Mod.bat`
**Purpose**: Flexible build process
**Features**:
- Handles missing environment variables gracefully
- Alternative build methods if CMake presets fail
- Automatic dependency detection and installation
- Better error handling and recovery

**Best for**: Users with existing development environment

## Step-by-Step Manual Installation

### Step 1: Install Visual Studio 2022
1. Download Visual Studio 2022 from Microsoft's website
2. During installation, select:
   - **Workloads**: Desktop development with C++
   - **Individual Components**: CMake tools for Visual Studio
3. Complete the installation

### Step 2: Install Git
1. Download Git for Windows
2. Install with default settings
3. Verify installation: `git --version`

### Step 3: Install CMake
1. Download CMake from the official website
2. Install with "Add to PATH" option
3. Verify installation: `cmake --version`

### Step 4: Install vcpkg
```cmd
cd %USERPROFILE%
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
bootstrap-vcpkg.bat
vcpkg integrate install
setx VCPKG_ROOT "%USERPROFILE%\vcpkg"
```

### Step 5: Install Vulkan SDK
1. Download Vulkan SDK from LunarG
2. Install with default settings
3. Restart your command prompt

### Step 6: Install vcpkg Dependencies
```cmd
%VCPKG_ROOT%\vcpkg.exe install spdlog:x64-windows-static
%VCPKG_ROOT%\vcpkg.exe install detours:x64-windows-static
%VCPKG_ROOT%\vcpkg.exe install directx-headers:x64-windows-static
%VCPKG_ROOT%\vcpkg.exe install quickdllproxy:x64-windows-static
```

### Step 7: Build the Project
```cmd
# Navigate to project directory
cd path\to\xess-mod

# Initialize submodules
git submodule update --init --recursive

# Build using CMake
mkdir build
cd build
cmake --preset final-universal
cmake --build --preset final-universal-release
```

## Troubleshooting

### Common Issues

#### 1. **"Visual Studio 2022 not found"**
**Solution**: Install Visual Studio 2022 Build Tools
- Download from: https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022
- Install with C++ build tools workload

#### 2. **"VCPKG_ROOT environment variable not set"**
**Solution**: Install and configure vcpkg
```cmd
cd %USERPROFILE%
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
bootstrap-vcpkg.bat
setx VCPKG_ROOT "%USERPROFILE%\vcpkg"
```

#### 3. **"VULKAN_SDK environment variable not set"**
**Solution**: Install Vulkan SDK
- Download from: https://vulkan.lunarg.com/sdk/home#windows
- Install with default settings
- Restart command prompt

#### 4. **"CMake configuration failed"**
**Solutions**:
- Restart command prompt to pick up new environment variables
- Ensure all dependencies are installed
- Try `Simple-Build-XeSS-Mod.bat` for more flexible building

#### 5. **"Build failed with compilation errors"**
**Solutions**:
- Ensure Visual Studio 2022 is properly installed
- Update vcpkg dependencies: `%VCPKG_ROOT%\vcpkg.exe upgrade`
- Clean build: `rmdir /s build && mkdir build`

### Getting Help

1. **Check the logs**: Look at the generated log files
2. **Run diagnostics**: Use `Test-XeSS-Build.bat` to check your setup
3. **Check troubleshooting**: See `TROUBLESHOOTING.md` for detailed solutions
4. **Verify prerequisites**: Ensure all required software is installed

## Environment Variables

The installation scripts will set these environment variables:

- `VCPKG_ROOT`: Path to vcpkg installation
- `VULKAN_SDK`: Path to Vulkan SDK installation

## Build Output

After successful build, you'll find:
- `build/bin/dlssg_to_xess_intel_is_better.dll` - Main mod DLL
- `build/bin/libxess_fg.dll` - XeSS Frame Generation runtime
- `build/bin/libxell.dll` - XeLL latency reduction runtime
- `build/bin/dlssg_to_xess.ini` - Configuration file

## Next Steps

After building:
1. **Install to a game**: Use `Install-XeSS-Mod.bat`
2. **Test the mod**: Copy files to a compatible game
3. **Configure settings**: Edit `dlssg_to_xess.ini` for debug options

## System Requirements

- **OS**: Windows 10/11 (64-bit)
- **RAM**: 8GB minimum, 16GB recommended
- **Disk Space**: 10GB free space
- **GPU**: Any GPU with Shader Model 6.4 support
- **Internet**: Required for downloading dependencies

## Support

If you encounter issues:
1. Check the troubleshooting guide
2. Verify all prerequisites are installed
3. Try the one-click installer for automatic setup
4. Check the build logs for specific error messages