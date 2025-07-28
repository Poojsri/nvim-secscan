#!/bin/bash
# Setup script for nvim-secscan

echo "Setting up nvim-secscan..."

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "❌ curl is required but not installed"
    echo "Install with: sudo apt install curl"
    exit 1
fi

# Install bandit if not present
if ! command -v bandit &> /dev/null; then
    echo "Installing bandit..."
    pip3 install bandit
else
    echo "✅ bandit already installed"
fi

# Make CLI script executable
chmod +x scripts/secscan-cli.py

echo "✅ Setup complete!"
echo ""
echo "Usage in Neovim:"
echo "  :SecScan        - Scan current file"
echo "  :SecScanClear   - Clear diagnostics"
echo ""
echo "CLI usage:"
echo "  python3 scripts/secscan-cli.py test/vulnerable_app.py"