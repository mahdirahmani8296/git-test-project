#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Forex Bot Launcher
==================
Simple launcher script for the forex trading bot.
"""

import os
import sys
import subprocess
import argparse

def check_requirements():
    """Check if required packages are installed."""
    try:
        import MetaTrader5
        import pandas
        import numpy
        import flask
        print("✅ تمام وابستگی‌ها نصب شده‌اند")
        return True
    except ImportError as e:
        print(f"❌ وابستگی مفقود: {e}")
        print("لطفاً ابتدا وابستگی‌ها را نصب کنید:")
        print("pip install -r requirements.txt")
        return False

def check_config():
    """Check if configuration file exists."""
    if os.path.exists('config.json'):
        print("✅ فایل پیکربندی یافت شد")
        return True
    else:
        print("⚠️ فایل پیکربندی یافت نشد - فایل پیش‌فرض ایجاد خواهد شد")
        return True

def run_console_bot():
    """Run the console version of the bot."""
    print("🤖 اجرای ربات در حالت کنسول...")
    try:
        from forex_bot import main
        main()
    except KeyboardInterrupt:
        print("\n👋 خروج از برنامه...")
    except Exception as e:
        print(f"❌ خطا: {e}")

def run_web_interface():
    """Run the web interface."""
    print("🌐 اجرای رابط وب...")
    print("📱 آدرس: http://localhost:5000")
    try:
        subprocess.run([sys.executable, 'web_interface.py'])
    except KeyboardInterrupt:
        print("\n👋 خروج از رابط وب...")
    except Exception as e:
        print(f"❌ خطا: {e}")

def main():
    parser = argparse.ArgumentParser(description='Forex Trading Bot Launcher')
    parser.add_argument('--mode', choices=['console', 'web'], default='console',
                       help='حالت اجرا: console یا web (پیش‌فرض: console)')
    
    args = parser.parse_args()
    
    print("=" * 50)
    print("🤖 ربات معاملاتی فارکس")
    print("=" * 50)
    
    # Check requirements
    if not check_requirements():
        return
    
    # Check configuration
    check_config()
    
    print()
    
    if args.mode == 'web':
        run_web_interface()
    else:
        run_console_bot()

if __name__ == "__main__":
    main()