@echo off
echo ========================================
echo Advanced Scalper EA Installation Helper
echo ========================================
echo.
echo This script will help you install the Advanced Scalper EA
echo in MetaTrader 4/5.
echo.
echo Prerequisites:
echo 1. MetaTrader 4 or 5 must be installed
echo 2. MetaTrader must be closed during installation
echo.
pause

echo.
echo Step 1: Locating MetaTrader installation...
echo.

REM Try to find MT4/MT5 installation
set "MT4_PATH="
set "MT5_PATH="

REM Check common MT4 paths
if exist "C:\Program Files\MetaTrader 4\MQL4\Experts" (
    set "MT4_PATH=C:\Program Files\MetaTrader 4\MQL4\Experts"
    echo Found MT4 at: C:\Program Files\MetaTrader 4
)

REM Check common MT5 paths
if exist "C:\Users\%USERNAME%\AppData\Roaming\MetaQuotes\Terminal\Common\MQL5\Experts" (
    set "MT5_PATH=C:\Users\%USERNAME%\AppData\Roaming\MetaQuotes\Terminal\Common\MQL5\Experts"
    echo Found MT5 at: C:\Users\%USERNAME%\AppData\Roaming\MetaQuotes\Terminal\Common
)

if exist "C:\Program Files\MetaTrader 5\Terminal\Common\MQL5\Experts" (
    set "MT5_PATH=C:\Program Files\MetaTrader 5\Terminal\Common\MQL5\Experts"
    echo Found MT5 at: C:\Program Files\MetaTrader 5
)

if "%MT4_PATH%"=="" if "%MT5_PATH%"=="" (
    echo ERROR: Could not find MetaTrader installation!
    echo Please install MetaTrader 4 or 5 first.
    pause
    exit /b 1
)

echo.
echo Step 2: Copying EA files...
echo.

REM Copy EA file to MT4 if found
if not "%MT4_PATH%"=="" (
    if exist "AdvancedScalperEA.mq4" (
        copy "AdvancedScalperEA.mq4" "%MT4_PATH%"
        echo Copied EA to MT4 Experts folder
    ) else (
        echo ERROR: AdvancedScalperEA.mq4 not found in current directory!
        pause
        exit /b 1
    )
)

REM Copy EA file to MT5 if found
if not "%MT5_PATH%"=="" (
    if exist "AdvancedScalperEA.mq4" (
        copy "AdvancedScalperEA.mq4" "%MT5_PATH%"
        echo Copied EA to MT5 Experts folder
    ) else (
        echo ERROR: AdvancedScalperEA.mq4 not found in current directory!
        pause
        exit /b 1
    )
)

echo.
echo Step 3: Installation complete!
echo.
echo Next steps:
echo 1. Open MetaTrader 4/5
echo 2. Press F4 to open MetaEditor
echo 3. Find "AdvancedScalperEA" in the Navigator
echo 4. Right-click and select "Modify"
echo 5. Press F7 to compile
echo 6. Ensure no compilation errors
echo 7. Close MetaEditor
echo 8. Drag EA from Navigator to your chart
echo 9. Configure parameters and enable live trading
echo.
echo For detailed instructions, see README.md
echo.
pause