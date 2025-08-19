#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Forex Bot Installation Script
============================
Automated installation and setup script.
"""

import os
import sys
import subprocess
import json

def install_requirements():
    """Install required Python packages."""
    print("📦 نصب وابستگی‌ها...")
    try:
        subprocess.check_call([sys.executable, '-m', 'pip', 'install', '-r', 'requirements.txt'])
        print("✅ وابستگی‌ها با موفقیت نصب شدند")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ خطا در نصب وابستگی‌ها: {e}")
        return False

def create_directories():
    """Create necessary directories."""
    dirs = ['templates', 'logs']
    for dir_name in dirs:
        if not os.path.exists(dir_name):
            os.makedirs(dir_name)
            print(f"📁 پوشه {dir_name} ایجاد شد")

def setup_config():
    """Setup configuration file."""
    if not os.path.exists('config.json'):
        print("⚙️ ایجاد فایل پیکربندی...")
        
        config = {
            "mt5_login": 0,
            "mt5_password": "",
            "mt5_server": "",
            "symbols": ["EURUSD", "GBPUSD", "USDJPY", "AUDUSD"],
            "timeframe": "M15",
            "lot_size": 0.01,
            "max_positions": 5,
            "risk_percent": 2.0,
            "stop_loss_pips": 50,
            "take_profit_pips": 100,
            "rsi_period": 14,
            "rsi_overbought": 70,
            "rsi_oversold": 30,
            "ma_fast": 10,
            "ma_slow": 20,
            "macd_fast": 12,
            "macd_slow": 26,
            "macd_signal": 9,
            "trading_hours": {
                "start": "08:00",
                "end": "18:00"
            },
            "max_daily_loss": 100.0,
            "max_daily_profit": 200.0
        }
        
        with open('config.json', 'w', encoding='utf-8') as f:
            json.dump(config, f, indent=4, ensure_ascii=False)
        
        print("✅ فایل پیکربندی ایجاد شد")
        print("⚠️ لطفاً اطلاعات MT5 خود را در config.json وارد کنید")

def print_instructions():
    """Print setup instructions."""
    print("\n" + "="*60)
    print("🎉 نصب با موفقیت تکمیل شد!")
    print("="*60)
    print("\n📋 مراحل بعدی:")
    print("1. فایل config.json را ویرایش کرده و اطلاعات MT5 خود را وارد کنید")
    print("2. MetaTrader 5 را باز کنید و Algorithmic Trading را فعال کنید")
    print("3. ابتدا روی حساب Demo تست کنید")
    print("\n🚀 اجرای ربات:")
    print("• حالت کنسول: python run_bot.py")
    print("• رابط وب: python run_bot.py --mode web")
    print("\n📖 مستندات کامل در فایل README.md موجود است")
    print("\n⚠️ هشدار: ابتدا روی حساب Demo تست کنید!")

def main():
    """Main installation function."""
    print("🤖 نصب ربات معاملاتی فارکس")
    print("="*40)
    
    # Check Python version
    if sys.version_info < (3, 8):
        print("❌ نسخه پایتون 3.8 یا بالاتر مورد نیاز است")
        return
    
    print(f"✅ Python {sys.version.split()[0]}")
    
    # Install requirements
    if not install_requirements():
        return
    
    # Create directories
    create_directories()
    
    # Setup configuration
    setup_config()
    
    # Print instructions
    print_instructions()

if __name__ == "__main__":
    main()