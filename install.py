#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
اسکریپت نصب سیستم معاملات فارکس
Forex Trading System Installation Script
"""

import subprocess
import sys
import os
import platform

def check_python_version():
    """بررسی نسخه Python"""
    print("🐍 بررسی نسخه Python...")
    version = sys.version_info
    if version.major < 3 or (version.major == 3 and version.minor < 8):
        print("❌ خطا: Python 3.8 یا بالاتر مورد نیاز است")
        print(f"نسخه فعلی: {version.major}.{version.minor}.{version.micro}")
        return False
    print(f"✅ Python {version.major}.{version.minor}.{version.micro} نصب است")
    return True

def install_packages():
    """نصب پکیج‌های مورد نیاز"""
    print("\n📦 نصب پکیج‌های مورد نیاز...")
    
    packages = [
        "numpy>=1.21.0",
        "pandas>=1.3.0",
        "yfinance>=0.1.70",
        "matplotlib>=3.5.0",
        "seaborn>=0.11.0",
        "scikit-learn>=1.0.0",
        "plotly>=5.0.0",
        "dash>=2.0.0",
        "dash-bootstrap-components>=1.0.0"
    ]
    
    for package in packages:
        try:
            print(f"نصب {package}...")
            subprocess.check_call([sys.executable, "-m", "pip", "install", package])
            print(f"✅ {package} نصب شد")
        except subprocess.CalledProcessError:
            print(f"❌ خطا در نصب {package}")
            return False
    
    return True

def install_talib():
    """نصب TA-Lib"""
    print("\n📊 نصب TA-Lib...")
    
    system = platform.system().lower()
    
    try:
        # تلاش برای نصب مستقیم
        subprocess.check_call([sys.executable, "-m", "pip", "install", "TA-Lib>=0.4.24"])
        print("✅ TA-Lib نصب شد")
        return True
    except subprocess.CalledProcessError:
        print("⚠️ نصب مستقیم TA-Lib ناموفق بود")
        
        if system == "linux":
            print("🔧 نصب TA-Lib در Ubuntu/Debian:")
            print("sudo apt-get update")
            print("sudo apt-get install ta-lib")
            print("pip install TA-Lib")
        elif system == "darwin":  # macOS
            print("🔧 نصب TA-Lib در macOS:")
            print("brew install ta-lib")
            print("pip install TA-Lib")
        elif system == "windows":
            print("🔧 نصب TA-Lib در Windows:")
            print("1. دانلود از: https://www.lfd.uci.edu/~gohlke/pythonlibs/#ta-lib")
            print("2. نصب فایل .whl دانلود شده")
            print("3. pip install TA-Lib")
        
        return False

def test_installation():
    """تست نصب"""
    print("\n🧪 تست نصب...")
    
    try:
        import numpy
        import pandas
        import yfinance
        import matplotlib
        import plotly
        import dash
        import talib
        print("✅ تمام پکیج‌ها با موفقیت نصب شدند")
        return True
    except ImportError as e:
        print(f"❌ خطا در تست نصب: {e}")
        return False

def create_demo_script():
    """ایجاد اسکریپت دمو"""
    print("\n🎯 ایجاد اسکریپت دمو...")
    
    demo_script = '''#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
اسکریپت دمو سیستم معاملات فارکس
"""

from forex_trading_system import AdvancedForexTrader

def main():
    print("🚀 راه‌اندازی سیستم معاملات فارکس...")
    
    # ایجاد نمونه از سیستم
    trader = AdvancedForexTrader(
        symbol="EURUSD=X",
        initial_balance=10000,
        risk_percent=2
    )
    
    # اجرای بک تست کوتاه
    print("📊 اجرای بک تست 1 ماهه...")
    trader.run_backtest(period="1mo", interval="1h")
    
    print("✅ دمو تکمیل شد!")

if __name__ == "__main__":
    main()
'''
    
    with open("demo.py", "w", encoding="utf-8") as f:
        f.write(demo_script)
    
    print("✅ اسکریپت دمو ایجاد شد: demo.py")

def main():
    """تابع اصلی"""
    print("🚀 نصب سیستم معاملات فارکس")
    print("=" * 50)
    
    # بررسی نسخه Python
    if not check_python_version():
        return
    
    # نصب پکیج‌های پایه
    if not install_packages():
        print("❌ خطا در نصب پکیج‌های پایه")
        return
    
    # نصب TA-Lib
    if not install_talib():
        print("⚠️ لطفاً TA-Lib را به صورت دستی نصب کنید")
    
    # تست نصب
    if not test_installation():
        print("❌ خطا در تست نصب")
        return
    
    # ایجاد اسکریپت دمو
    create_demo_script()
    
    print("\n" + "="*50)
    print("✅ نصب با موفقیت تکمیل شد!")
    print("\n📋 دستورات مفید:")
    print("python demo.py                    # اجرای دمو")
    print("python forex_trading_system.py    # سیستم اصلی")
    print("python strategy_optimizer.py      # بهینه‌ساز")
    print("python trading_dashboard.py       # داشبورد")
    print("\n🌐 داشبورد: http://127.0.0.1:8050")
    print("\n📖 برای اطلاعات بیشتر README.md را مطالعه کنید")

if __name__ == "__main__":
    main()