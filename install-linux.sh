#!/bin/bash

# XeSS Mod Linux Installation Script

set -e

echo "========================================"
echo "XeSS Mod Linux Installation"
echo "========================================"
echo

# Check if we're running from the correct directory
if [ ! -f "Makefile-Linux" ]; then
    echo "Error: This script must be run from the project root directory"
    echo "Please navigate to the directory containing Makefile-Linux and run this script again."
    exit 1
fi

# Check if build exists
if [ ! -d "build-linux" ]; then
    echo "Error: Build directory not found. Please run 'make -f Makefile-Linux all' first."
    exit 1
fi

# Set installation directories
INSTALL_DIR="/usr/local"
LIB_DIR="$INSTALL_DIR/lib"
BIN_DIR="$INSTALL_DIR/bin"
CONFIG_DIR="$INSTALL_DIR/etc/xess-mod"

echo "Installation directories:"
echo "  Libraries: $LIB_DIR"
echo "  Binaries: $BIN_DIR"
echo "  Configuration: $CONFIG_DIR"
echo

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Warning: This script is not running as root."
    echo "Some operations may require elevated privileges."
    echo
fi

# Create directories
echo "Creating installation directories..."
sudo mkdir -p "$LIB_DIR"
sudo mkdir -p "$BIN_DIR"
sudo mkdir -p "$CONFIG_DIR"

# Install library
echo "Installing XeSS mod library..."
sudo cp build-linux/lib/libxess_mod_linux.so "$LIB_DIR/"
sudo chmod 755 "$LIB_DIR/libxess_mod_linux.so"

# Install test executable
echo "Installing test executable..."
sudo cp build-linux/bin/xess_test_simple "$BIN_DIR/"
sudo chmod 755 "$BIN_DIR/xess_test_simple"

# Install configuration
echo "Installing configuration files..."
sudo cp build-linux/bin/dlssg_to_xess.ini "$CONFIG_DIR/"
sudo chmod 644 "$CONFIG_DIR/dlssg_to_xess.ini"

# Copy XeSS runtime files (for reference)
echo "Copying XeSS runtime files..."
sudo cp build-linux/bin/libxess_fg.dll "$CONFIG_DIR/"
sudo cp build-linux/bin/libxell.dll "$CONFIG_DIR/"
sudo chmod 644 "$CONFIG_DIR/libxess_fg.dll"
sudo chmod 644 "$CONFIG_DIR/libxell.dll"

# Update library cache
echo "Updating library cache..."
sudo ldconfig

# Create symbolic links for easy access
echo "Creating symbolic links..."
sudo ln -sf "$BIN_DIR/xess_test_simple" "$BIN_DIR/xess-test"

# Create desktop entry for test application
echo "Creating desktop entry..."
cat > /tmp/xess-test.desktop << EOF
[Desktop Entry]
Name=XeSS Mod Test
Comment=Test XeSS mod functionality
Exec=$BIN_DIR/xess_test_simple
Terminal=true
Type=Application
Categories=Utility;
EOF

sudo cp /tmp/xess-test.desktop /usr/share/applications/
rm /tmp/xess-test.desktop

# Create environment setup script
echo "Creating environment setup script..."
cat > /tmp/xess-env.sh << EOF
#!/bin/bash
# XeSS Mod Environment Setup

export XESS_MOD_LIBRARY="$LIB_DIR/libxess_mod_linux.so"
export XESS_CONFIG_DIR="$CONFIG_DIR"
export LD_LIBRARY_PATH="\$LD_LIBRARY_PATH:$LIB_DIR"

echo "XeSS Mod environment variables set:"
echo "  XESS_MOD_LIBRARY: \$XESS_MOD_LIBRARY"
echo "  XESS_CONFIG_DIR: \$XESS_CONFIG_DIR"
echo "  LD_LIBRARY_PATH updated"
EOF

sudo cp /tmp/xess-env.sh "$BIN_DIR/"
sudo chmod 755 "$BIN_DIR/xess-env.sh"
rm /tmp/xess-env.sh

# Create uninstall script
echo "Creating uninstall script..."
cat > /tmp/xess-uninstall.sh << EOF
#!/bin/bash
# XeSS Mod Uninstall Script

echo "Uninstalling XeSS Mod..."

sudo rm -f "$LIB_DIR/libxess_mod_linux.so"
sudo rm -f "$BIN_DIR/xess_test_simple"
sudo rm -f "$BIN_DIR/xess-test"
sudo rm -f "$BIN_DIR/xess-env.sh"
sudo rm -f /usr/share/applications/xess-test.desktop
sudo rm -rf "$CONFIG_DIR"

sudo ldconfig

echo "XeSS Mod uninstalled successfully."
EOF

sudo cp /tmp/xess-uninstall.sh "$BIN_DIR/"
sudo chmod 755 "$BIN_DIR/xess-uninstall.sh"
rm /tmp/xess-uninstall.sh

echo
echo "========================================"
echo "Installation Complete!"
echo "========================================"
echo
echo "Files installed:"
echo "  Library: $LIB_DIR/libxess_mod_linux.so"
echo "  Test executable: $BIN_DIR/xess_test_simple"
echo "  Configuration: $CONFIG_DIR/dlssg_to_xess.ini"
echo "  XeSS runtime files: $CONFIG_DIR/"
echo
echo "Available commands:"
echo "  xess_test_simple - Run the test application"
echo "  xess-test - Alternative name for test application"
echo "  xess-env.sh - Set up environment variables"
echo "  xess-uninstall.sh - Uninstall the mod"
echo
echo "To test the installation:"
echo "  xess_test_simple"
echo
echo "To set up environment variables:"
echo "  source $BIN_DIR/xess-env.sh"
echo
echo "To uninstall:"
echo "  sudo $BIN_DIR/xess-uninstall.sh"
echo

# Test the installation
echo "Testing installation..."
if [ -f "$BIN_DIR/xess_test_simple" ]; then
    echo "✅ Test executable found"
    echo "Running test..."
    "$BIN_DIR/xess_test_simple" || echo "Test completed"
else
    echo "❌ Test executable not found"
fi

echo
echo "Installation log saved to: /tmp/xess-install.log"
echo "For more information, see BUILD-SUMMARY.md"
echo