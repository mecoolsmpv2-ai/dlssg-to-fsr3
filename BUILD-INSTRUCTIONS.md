# DLSSG-to-XeSS Mod Build Instructions

This document provides detailed instructions for building the DLSSG-to-XeSS mod, which replaces NVIDIA's DLSS Frame Generation with Intel's XeSS 2.1 Frame Generation.

## Prerequisites

### Required Software

1. **Windows 10/11** (64-bit)
2. **Visual Studio 2022** (Community, Professional, or Enterprise)
   - Install with C++ development tools
   - Include MSVC v143 build tools
   - Include Windows 10/11 SDK
   - Include CMake tools for Visual Studio

3. **Git** (for cloning repositories)
4. **CMake** (3.26 or newer)
5. **vcpkg** (C++ package manager)
6. **Vulkan SDK** (for Vulkan support)

### GPU Requirements

The mod supports all GPUs with Shader Model 6.4 support:
- **Intel Arc GPUs** (with XMX support for best performance)
- **AMD Radeon GPUs** (with Shader Model 6.4 support)
- **NVIDIA GeForce GPUs** (with Shader Model 6.4 support)

## Quick Setup

### Option 1: Automated Setup (Recommended)

1. Run `Setup-XeSS-Environment.bat` to check and install required tools
2. Run `Build-XeSS-Mod.bat` to build the mod
3. Use the generated `Install-XeSS-Mod.bat` to install to your games

### Option 2: Manual Setup

Follow the detailed instructions below if you prefer manual setup.

## Manual Build Process

### Step 1: Environment Setup

#### Install Visual Studio 2022
1. Download Visual Studio 2022 from [Microsoft's website](https://visualstudio.microsoft.com/downloads/)
2. During installation, select:
   - MSVC v143 - VS 2022 C++ x64/x86 build tools
   - Windows 10/11 SDK
   - CMake tools for Visual Studio

#### Install Git
1. Download Git from [git-scm.com](https://git-scm.com/download/win)
2. Install with default settings

#### Install CMake
1. Download CMake from [cmake.org](https://cmake.org/download/)
2. Install and add to system PATH

#### Install vcpkg
```cmd
cd %USERPROFILE%
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
bootstrap-vcpkg.bat
vcpkg integrate install
setx VCPKG_ROOT "%USERPROFILE%\vcpkg"
```

#### Install Vulkan SDK
1. Download Vulkan SDK from [LunarG](https://vulkan.lunarg.com/sdk/home#windows)
2. Install with default settings
3. The `VULKAN_SDK` environment variable should be set automatically

### Step 2: Clone and Prepare the Project

```cmd
git clone <repository-url>
cd dlssg-to-xess
git submodule update --init --recursive
```

### Step 3: Build the Project

#### Using CMake Presets (Recommended)

```cmd
# Build Universal version (works with most games)
cmake --preset final-universal
cmake --build --preset final-universal-release

# Build NVNGX wrapper version (for specific games)
cmake --preset final-nvngxwrapper
cmake --build --preset final-nvngxwrapper-release

# Build DLSSTweaks wrapper version
cmake --preset final-dtwrapper
cmake --build --preset final-dtwrapper-release
```

#### Using Visual Studio

1. Open the project in Visual Studio 2022
2. Select the desired configuration (Universal, NVNGX, or DLSSTweaks)
3. Build the solution

### Step 4: Create Release Packages

```cmd
# Create packages for all configurations
cpack --preset final-universal
cpack --preset final-nvngxwrapper
cpack --preset final-dtwrapper
```

## Output Files

After a successful build, you'll find the following files in the `bin/` directory:

### Main Mod Files
- `dlssg_to_xess_intel_is_better.dll` - Main mod DLL
- `libxess_fg.dll` - XeSS Frame Generation runtime
- `libxell.dll` - XeLL latency reduction runtime
- `dlssg_to_xess.ini` - Debug configuration file

### Installation Files
- `Install-XeSS-Mod.bat` - Automated installer
- `BUILD-README.txt` - Installation instructions
- `DisableNvidiaSignatureChecks.reg` - Registry file for NVIDIA GPUs
- `RestoreNvidiaSignatureChecks.reg` - Registry restore file

## Installation

### Automated Installation

1. Run `Install-XeSS-Mod.bat`
2. Enter the path to your game directory
3. The script will automatically copy all necessary files

### Manual Installation

1. Copy the following files to your game directory:
   - `dlssg_to_xess_intel_is_better.dll`
   - `libxess_fg.dll`
   - `libxell.dll`
   - `dlssg_to_xess.ini` (optional)

2. For NVIDIA GPUs, run `DisableNvidiaSignatureChecks.reg` as administrator

3. Launch your game and enable DLSS Frame Generation

## Troubleshooting

### Build Issues

#### CMake Configuration Fails
- Ensure all prerequisites are installed
- Check that environment variables are set correctly
- Verify Visual Studio 2022 is installed with C++ tools

#### Compilation Errors
- Make sure you're using Visual Studio 2022
- Check that the XeSS SDK is properly cloned
- Verify all dependencies are available

#### Missing DLLs
- Ensure XeSS SDK is cloned to `dependencies/xess/`
- Check that `libxess_fg.dll` and `libxell.dll` exist in `dependencies/xess/bin/`

### Runtime Issues

#### Game Crashes
- Check `dlssg_to_xess.log` in the game directory
- Verify your GPU supports Shader Model 6.4
- Make sure all DLL files are in the same directory as the game executable

#### Frame Generation Not Working
- Ensure DLSS Frame Generation is enabled in the game
- Check that the mod DLL is being loaded (check the log file)
- Verify XeSS runtime DLLs are present

#### Performance Issues
- Intel Arc GPUs provide the best performance with XMX support
- AMD and NVIDIA GPUs use DP4a instructions (slower but functional)
- Check that your GPU drivers are up to date

## Configuration

### Debug Options

Edit `dlssg_to_xess.ini` to enable debug features:

```ini
[Debug]
EnableDebugOverlay=1      ; Show debug overlay
EnableDebugTearLines=0    ; Show tear lines
EnableInterpolatedFramesOnly=0  ; Show only interpolated frames
```

### Environment Variables

You can set these environment variables for additional control:

- `XESS_DEBUG=1` - Enable verbose logging
- `XESS_DISABLE=1` - Disable the mod entirely

## Game Compatibility

The mod should work with any game that supports DLSS Frame Generation. Known compatible games include:

- Cyberpunk 2077
- Hogwarts Legacy
- The Witcher 3: Wild Hunt
- Dying Light 2
- And many more...

## Support

For issues and questions:

1. Check the log file (`dlssg_to_xess.log`) in your game directory
2. Verify your GPU supports Shader Model 6.4
3. Ensure all files are properly installed
4. Check that the game supports DLSS Frame Generation

## License

This mod is based on the original DLSSG-to-FSR3 project and is licensed under GPLv3. See the LICENSE.md file for details.

## Acknowledgments

- Original DLSSG-to-FSR3 project by Nukem9
- Intel XeSS SDK and documentation
- AMD FidelityFX SDK (for reference implementation)