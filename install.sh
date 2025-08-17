#!/bin/bash

# اسکریپت نصب سیستم معاملاتی فارکس
# Forex Trading System Installation Script

echo "🚀 شروع نصب سیستم معاملاتی فارکس پیشرفته"
echo "=========================================="

# بررسی وجود Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 یافت نشد. لطفاً Python 3.8 یا بالاتر را نصب کنید."
    exit 1
fi

echo "✅ Python 3 یافت شد: $(python3 --version)"

# بررسی وجود pip
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 یافت نشد. لطفاً pip را نصب کنید."
    exit 1
fi

echo "✅ pip3 یافت شد"

# ایجاد محیط مجازی
echo "📦 ایجاد محیط مجازی..."
python3 -m venv venv

if [ $? -eq 0 ]; then
    echo "✅ محیط مجازی ایجاد شد"
else
    echo "❌ خطا در ایجاد محیط مجازی"
    exit 1
fi

# فعال‌سازی محیط مجازی
echo "🔧 فعال‌سازی محیط مجازی..."
source venv/bin/activate

if [ $? -eq 0 ]; then
    echo "✅ محیط مجازی فعال شد"
else
    echo "❌ خطا در فعال‌سازی محیط مجازی"
    exit 1
fi

# به‌روزرسانی pip
echo "⬆️ به‌روزرسانی pip..."
pip install --upgrade pip

# نصب وابستگی‌ها
echo "📚 نصب وابستگی‌ها..."
pip install -r requirements.txt

if [ $? -eq 0 ]; then
    echo "✅ وابستگی‌ها با موفقیت نصب شدند"
else
    echo "❌ خطا در نصب وابستگی‌ها"
    echo "💡 نکته: ممکن است نیاز به نصب TA-Lib به صورت جداگانه داشته باشید"
    echo "   برای Ubuntu/Debian: sudo apt-get install ta-lib"
    echo "   برای macOS: brew install ta-lib"
    echo "   برای Windows: دانلود از https://www.lfd.uci.edu/~gohlke/pythonlibs/#ta-lib"
    exit 1
fi

# تست نصب TA-Lib
echo "🧪 تست نصب TA-Lib..."
python3 -c "import talib; print('✅ TA-Lib نصب شده است')" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "⚠️ هشدار: TA-Lib نصب نشده است"
    echo "💡 برای نصب TA-Lib:"
    echo "   Ubuntu/Debian: sudo apt-get install ta-lib && pip install TA-Lib"
    echo "   macOS: brew install ta-lib && pip install TA-Lib"
    echo "   Windows: دانلود wheel file و نصب با pip"
fi

# ایجاد فایل‌های نمونه
echo "📝 ایجاد فایل‌های نمونه..."

# فایل تنظیمات نمونه
cat > config_sample.py << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
فایل تنظیمات نمونه - کپی کنید و تغییر دهید
Sample configuration file - copy and modify
"""

from config import *

# تغییر تنظیمات سیستم
SYSTEM_CONFIG['default_initial_balance'] = 50000  # سرمایه اولیه بیشتر
SYSTEM_CONFIG['default_risk_per_trade'] = 0.01    # ریسک کمتر (1%)

# تغییر پارامترهای استراتژی
DEFAULT_STRATEGY_PARAMS['rsi_period'] = 21        # RSI دوره طولانی‌تر
DEFAULT_STRATEGY_PARAMS['rsi_overbought'] = 75    # سطح اشباع خرید بالاتر
DEFAULT_STRATEGY_PARAMS['rsi_oversold'] = 25      # سطح اشباع فروش پایین‌تر

print("تنظیمات سفارشی اعمال شد")
EOF

echo "✅ فایل config_sample.py ایجاد شد"

# فایل اجرای نمونه
cat > run_demo.py << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
اسکریپت اجرای نمونه
Sample execution script
"""

import sys
import os

# اضافه کردن مسیر فعلی به Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

def main():
    print("🎯 انتخاب کنید:")
    print("1. اجرای نمونه‌های پایه")
    print("2. اجرای رابط وب")
    print("3. اجرای بک‌تستینگ")
    print("4. خروج")
    
    choice = input("\nانتخاب شما (1-4): ").strip()
    
    if choice == "1":
        print("\n🚀 اجرای نمونه‌های پایه...")
        from demo import main as demo_main
        demo_main()
    elif choice == "2":
        print("\n🌐 اجرای رابط وب...")
        print("در مرورگر به آدرس http://localhost:5000 مراجعه کنید")
        from web_interface import app, socketio
        socketio.run(app, host='0.0.0.0', port=5000, debug=True)
    elif choice == "3":
        print("\n📊 اجرای بک‌تستینگ...")
        from backtesting_engine import BacktestingEngine
        backtester = BacktestingEngine(initial_balance=10000)
        results = backtester.run_backtest("EURUSD=X", "2023-01-01", "2023-12-31", "1h")
        if results['success']:
            print("نتایج بک‌تست:")
            print(f"سود کل: ${results['performance']['total_profit']:.2f}")
            print(f"نرخ موفقیت: {results['performance']['win_rate']:.2%}")
        else:
            print(f"خطا: {results['error']}")
    elif choice == "4":
        print("👋 خداحافظ!")
    else:
        print("❌ انتخاب نامعتبر")

if __name__ == "__main__":
    main()
EOF

echo "✅ فایل run_demo.py ایجاد شد"

# تست نصب
echo "🧪 تست نصب..."
python3 -c "
import sys
sys.path.append('.')
try:
    from forex_trading_system import AdvancedForexTrader
    from backtesting_engine import BacktestingEngine
    from web_interface import app
    print('✅ تمام ماژول‌ها با موفقیت import شدند')
except ImportError as e:
    print(f'❌ خطا در import: {e}')
    sys.exit(1)
"

if [ $? -eq 0 ]; then
    echo "✅ تست نصب موفقیت‌آمیز بود"
else
    echo "❌ خطا در تست نصب"
    exit 1
fi

echo ""
echo "🎉 نصب با موفقیت تکمیل شد!"
echo "=========================================="
echo ""
echo "📋 مراحل بعدی:"
echo "1. فعال‌سازی محیط مجازی: source venv/bin/activate"
echo "2. اجرای نمونه‌ها: python run_demo.py"
echo "3. اجرای رابط وب: python web_interface.py"
echo "4. مطالعه مستندات: cat README.md"
echo ""
echo "💡 نکات مهم:"
echo "- این سیستم برای اهداف آموزشی طراحی شده است"
echo "- قبل از استفاده در معاملات واقعی، حتماً تست کامل انجام دهید"
echo "- معاملات فارکس دارای ریسک بالایی است"
echo ""
echo "🔗 منابع مفید:"
echo "- مستندات: README.md"
echo "- نمونه‌ها: demo.py"
echo "- تنظیمات: config.py"
echo ""
echo "برای شروع، دستور زیر را اجرا کنید:"
echo "source venv/bin/activate && python run_demo.py"