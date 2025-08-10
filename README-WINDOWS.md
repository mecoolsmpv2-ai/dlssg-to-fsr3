# XeSS Mod - Windows Installation

This project allows games using NVIDIA DLSS Frame Generation to use Intel XeSS 2.1 Frame Generation instead.

## 🚀 Quick Start (Recommended)

**For the easiest installation, just run:**
```cmd
One-Click-Install.bat
```

This script will automatically:
- ✅ Install all missing dependencies
- ✅ Set up the build environment  
- ✅ Build the XeSS mod
- ✅ Provide installation instructions

## 📋 Installation Options

### Option 1: One-Click Installation
```cmd
One-Click-Install.bat
```
**Best for**: New users who want the simplest setup

### Option 2: Auto-Installation
```cmd
Auto-Install-Windows.bat
```
**Best for**: Users who want to understand what's being installed

### Option 3: Simple Build
```cmd
Simple-Build-XeSS-Mod.bat
```
**Best for**: Users with existing development environment

### Option 4: Manual Installation
See `WINDOWS-INSTALLATION.md` for detailed manual steps

## 🔧 What Gets Installed

The scripts will automatically install:
- **Visual Studio 2022 Build Tools** (C++ compiler)
- **Git** (version control)
- **CMake** (build system)
- **vcpkg** (C++ package manager)
- **Vulkan SDK** (graphics API)
- **Required libraries**: spdlog, detours, directx-headers, quickdllproxy

## 🎮 After Building

Once the build is complete:
1. **Install to a game**: `Install-XeSS-Mod.bat`
2. **Test the mod**: Copy files to a compatible game
3. **Configure settings**: Edit `dlssg_to_xess.ini`

## 📁 Build Output

You'll find these files in `build/bin/`:
- `dlssg_to_xess_intel_is_better.dll` - Main mod DLL
- `libxess_fg.dll` - XeSS Frame Generation runtime
- `libxell.dll` - XeLL latency reduction runtime
- `dlssg_to_xess.ini` - Configuration file

## ❓ Troubleshooting

If you encounter issues:
1. **Check logs**: Look at generated log files
2. **Run diagnostics**: `Test-XeSS-Build.bat`
3. **See troubleshooting**: `TROUBLESHOOTING.md`
4. **Try one-click installer**: `One-Click-Install.bat`

## 📖 Documentation

- `WINDOWS-INSTALLATION.md` - Detailed installation guide
- `TROUBLESHOOTING.md` - Common issues and solutions
- `BUILD-INSTRUCTIONS.md` - Build process documentation

## 🖥️ System Requirements

- **OS**: Windows 10/11 (64-bit)
- **RAM**: 8GB minimum, 16GB recommended
- **Disk Space**: 10GB free space
- **GPU**: Any GPU with Shader Model 6.4 support
- **Internet**: Required for downloading dependencies

## 🎯 Supported Games

Game compatibility can be found in the original project's wiki. Using this mod in multiplayer games may lead to account bans. **Use at your own risk.**

---

**Need help?** Start with `One-Click-Install.bat` for the easiest setup!