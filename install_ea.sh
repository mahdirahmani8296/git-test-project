#!/bin/bash

echo "========================================"
echo "Advanced Scalper EA Installation Helper"
echo "========================================"
echo ""
echo "This script will help you install the Advanced Scalper EA"
echo "in MetaTrader 4/5."
echo ""
echo "Prerequisites:"
echo "1. MetaTrader 4 or 5 must be installed"
echo "2. MetaTrader must be closed during installation"
echo ""
read -p "Press Enter to continue..."

echo ""
echo "Step 1: Locating MetaTrader installation..."
echo ""

# Try to find MT4/MT5 installation
MT4_PATH=""
MT5_PATH=""

# Check common MT4 paths
if [ -d "/opt/metaquotes/metaeditor/MQL4/Experts" ]; then
    MT4_PATH="/opt/metaquotes/metaeditor/MQL4/Experts"
    echo "Found MT4 at: /opt/metaquotes/metaeditor"
elif [ -d "$HOME/.wine/drive_c/Program Files/MetaTrader 4/MQL4/Experts" ]; then
    MT4_PATH="$HOME/.wine/drive_c/Program Files/MetaTrader 4/MQL4/Experts"
    echo "Found MT4 at: $HOME/.wine/drive_c/Program Files/MetaTrader 4"
fi

# Check common MT5 paths
if [ -d "/opt/metaquotes/terminal/Common/MQL5/Experts" ]; then
    MT5_PATH="/opt/metaquotes/terminal/Common/MQL5/Experts"
    echo "Found MT5 at: /opt/metaquotes/terminal"
elif [ -d "$HOME/.wine/drive_c/Program Files/MetaTrader 5/Terminal/Common/MQL5/Experts" ]; then
    MT5_PATH="$HOME/.wine/drive_c/Program Files/MetaTrader 5/Terminal/Common/MQL5/Experts"
    echo "Found MT5 at: $HOME/.wine/drive_c/Program Files/MetaTrader 5"
fi

# Check Wine installations
if [ -z "$MT4_PATH" ] && [ -z "$MT5_PATH" ]; then
    echo "ERROR: Could not find MetaTrader installation!"
    echo "Please install MetaTrader 4 or 5 first."
    echo ""
    echo "For Linux users, you may need to install via Wine:"
    echo "1. Install Wine: sudo apt-get install wine (Ubuntu/Debian)"
    echo "2. Download MetaTrader from https://www.metatrader5.com/"
    echo "3. Install using: wine MetaTrader5Setup.exe"
    read -p "Press Enter to exit..."
    exit 1
fi

echo ""
echo "Step 2: Copying EA files..."
echo ""

# Copy EA file to MT4 if found
if [ -n "$MT4_PATH" ]; then
    if [ -f "AdvancedScalperEA.mq4" ]; then
        cp "AdvancedScalperEA.mq4" "$MT4_PATH/"
        echo "Copied EA to MT4 Experts folder"
    else
        echo "ERROR: AdvancedScalperEA.mq4 not found in current directory!"
        read -p "Press Enter to exit..."
        exit 1
    fi
fi

# Copy EA file to MT5 if found
if [ -n "$MT5_PATH" ]; then
    if [ -f "AdvancedScalperEA.mq4" ]; then
        cp "AdvancedScalperEA.mq4" "$MT5_PATH/"
        echo "Copied EA to MT5 Experts folder"
    else
        echo "ERROR: AdvancedScalperEA.mq4 not found in current directory!"
        read -p "Press Enter to exit..."
        exit 1
    fi
fi

echo ""
echo "Step 3: Installation complete!"
echo ""
echo "Next steps:"
echo "1. Open MetaTrader 4/5"
echo "2. Press F4 to open MetaEditor"
echo "3. Find 'AdvancedScalperEA' in the Navigator"
echo "4. Right-click and select 'Modify'"
echo "5. Press F7 to compile"
echo "6. Ensure no compilation errors"
echo "7. Close MetaEditor"
echo "8. Drag EA from Navigator to your chart"
echo "9. Configure parameters and enable live trading"
echo ""
echo "For detailed instructions, see README.md"
echo ""
read -p "Press Enter to exit..."