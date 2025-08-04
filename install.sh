#!/bin/bash
# Install nvim-secscan as a system command

echo "Installing nvim-secscan..."

# Check if running as root for system-wide install
if [ "$EUID" -eq 0 ]; then
    INSTALL_DIR="/usr/local/bin"
    echo "Installing system-wide to $INSTALL_DIR"
else
    INSTALL_DIR="$HOME/.local/bin"
    echo "Installing to user directory $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
fi

# Copy the executable
cp nvim-secscan "$INSTALL_DIR/nvim-secscan"
chmod +x "$INSTALL_DIR/nvim-secscan"

# Add to PATH if not already there
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "Adding $INSTALL_DIR to PATH in ~/.bashrc"
    echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> ~/.bashrc
    echo "Run: source ~/.bashrc or restart your terminal"
fi

echo "✅ nvim-secscan installed successfully!"
echo ""
echo "Usage:"
echo "  nvim-secscan --help"
echo "  nvim-secscan app.py"
echo "  nvim-secscan --format text app.py"