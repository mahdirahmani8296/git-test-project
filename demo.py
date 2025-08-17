#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
نمونه استفاده از سیستم معاملاتی فارکس
Demo script for Forex Trading System
"""

from forex_trading_system import AdvancedForexTrader
from backtesting_engine import BacktestingEngine
import time

def demo_basic_trading():
    """
    نمونه استفاده پایه از سیستم معاملاتی
    """
    print("=" * 60)
    print("نمونه استفاده پایه از سیستم معاملاتی فارکس")
    print("=" * 60)
    
    # ایجاد معامله‌گر
    trader = AdvancedForexTrader(initial_balance=10000, risk_per_trade=0.02)
    print(f"معامله‌گر با سرمایه اولیه ${trader.initial_balance} ایجاد شد")
    
    # اجرای استراتژی روی EUR/USD
    print("\nدر حال اجرای استراتژی روی EUR/USD...")
    result = trader.run_strategy("EURUSD=X", period="1mo", interval="1h")
    
    if result['success']:
        signal = result['signal']
        print(f"\nنتایج استراتژی:")
        print(f"سیگنال: {signal['signal']} ({'خرید' if signal['signal'] == 1 else 'فروش' if signal['signal'] == -1 else 'بی‌طرف'})")
        print(f"سطح اعتماد: {signal['confidence']:.2%}")
        print(f"امتیاز: {signal['score']:.2f}")
        print(f"قیمت فعلی: {signal['price']:.5f}")
        print(f"اندازه پوزیشن پیشنهادی: {result['position_size']:.2f}")
        print(f"دلایل:")
        for reason in signal['reasons']:
            print(f"  - {reason}")
    else:
        print(f"خطا: {result['error']}")

def demo_backtesting():
    """
    نمونه استفاده از بک‌تستینگ
    """
    print("\n" + "=" * 60)
    print("نمونه بک‌تستینگ استراتژی")
    print("=" * 60)
    
    # ایجاد موتور بک‌تستینگ
    backtester = BacktestingEngine(initial_balance=10000)
    
    # اجرای بک‌تست
    print("در حال اجرای بک‌تست روی EUR/USD (3 ماه گذشته)...")
    results = backtester.run_backtest(
        symbol="EURUSD=X",
        start_date="2023-10-01",
        end_date="2023-12-31",
        interval="1h"
    )
    
    if results['success']:
        performance = results['performance']
        print(f"\nنتایج بک‌تست:")
        print(f"تعداد کل معاملات: {performance['total_trades']}")
        print(f"معاملات سودده: {performance['winning_trades']}")
        print(f"نرخ موفقیت: {performance['win_rate']:.2%}")
        print(f"سود کل: ${performance['total_profit']:.2f}")
        print(f"سود متوسط: ${performance['average_profit']:.2f}")
        print(f"بازده: {performance['return_percentage']:.2f}%")
        print(f"Sharpe Ratio: {performance['sharpe_ratio']:.3f}")
        print(f"حداکثر افت: {performance['max_drawdown']:.2%}")
        print(f"Profit Factor: {performance['profit_factor']:.2f}")
        print(f"سرمایه نهایی: ${performance['final_equity']:.2f}")
    else:
        print(f"خطا در بک‌تست: {results['error']}")

def demo_optimization():
    """
    نمونه بهینه‌سازی پارامترها
    """
    print("\n" + "=" * 60)
    print("نمونه بهینه‌سازی پارامترهای استراتژی")
    print("=" * 60)
    
    # ایجاد موتور بک‌تستینگ
    backtester = BacktestingEngine(initial_balance=10000)
    
    # تعریف محدوده پارامترها برای بهینه‌سازی
    param_ranges = {
        'rsi_period': [10, 14, 20],
        'rsi_overbought': [65, 70, 75],
        'rsi_oversold': [25, 30, 35],
        'ema_short': [7, 9, 12],
        'ema_long': [18, 21, 26]
    }
    
    print("در حال بهینه‌سازی پارامترها...")
    print("این فرآیند ممکن است چند دقیقه طول بکشد...")
    
    optimization_results = backtester.optimize_strategy(
        "EURUSD=X", 
        "2023-10-01", 
        "2023-12-31", 
        param_ranges
    )
    
    print(f"\nبهترین پارامترها:")
    for param, value in optimization_results['best_params'].items():
        print(f"  {param}: {value}")
    print(f"بهترین Sharpe Ratio: {optimization_results['best_sharpe']:.3f}")

def demo_multiple_symbols():
    """
    نمونه تست روی چندین نماد
    """
    print("\n" + "=" * 60)
    print("نمونه تست روی چندین جفت ارز")
    print("=" * 60)
    
    symbols = ['EURUSD=X', 'GBPUSD=X', 'USDJPY=X', 'AUDUSD=X']
    trader = AdvancedForexTrader(initial_balance=10000)
    
    for symbol in symbols:
        print(f"\nتست روی {symbol}:")
        result = trader.run_strategy(symbol, period="1w", interval="1h")
        
        if result['success']:
            signal = result['signal']
            signal_text = 'خرید' if signal['signal'] == 1 else 'فروش' if signal['signal'] == -1 else 'بی‌طرف'
            print(f"  سیگنال: {signal_text}")
            print(f"  اعتماد: {signal['confidence']:.1%}")
            print(f"  قیمت: {signal['price']:.5f}")
        else:
            print(f"  خطا: {result['error']}")
        
        time.sleep(1)  # تاخیر کوتاه بین درخواست‌ها

def demo_risk_management():
    """
    نمونه مدیریت ریسک
    """
    print("\n" + "=" * 60)
    print("نمونه مدیریت ریسک")
    print("=" * 60)
    
    # تست با سطوح مختلف ریسک
    risk_levels = [0.01, 0.02, 0.05]  # 1%, 2%, 5%
    
    for risk in risk_levels:
        trader = AdvancedForexTrader(initial_balance=10000, risk_per_trade=risk)
        result = trader.run_strategy("EURUSD=X", period="1w", interval="1h")
        
        if result['success']:
            signal = result['signal']
            position_size = result['position_size']
            max_risk_amount = trader.balance * risk
            
            print(f"\nسطح ریسک: {risk:.1%}")
            print(f"  حداکثر ریسک در معامله: ${max_risk_amount:.2f}")
            print(f"  اندازه پوزیشن پیشنهادی: {position_size:.2f}")
            print(f"  ارزش معامله: ${position_size * signal['price']:.2f}")
        else:
            print(f"خطا در سطح ریسک {risk:.1%}: {result['error']}")

def main():
    """
    اجرای تمام نمونه‌ها
    """
    print("🚀 شروع نمونه‌های سیستم معاملاتی فارکس")
    print("این نمونه‌ها نشان می‌دهند که چگونه از سیستم استفاده کنید")
    
    try:
        # اجرای نمونه‌های مختلف
        demo_basic_trading()
        demo_backtesting()
        demo_multiple_symbols()
        demo_risk_management()
        
        # بهینه‌سازی (اختیاری - ممکن است طول بکشد)
        print("\nآیا می‌خواهید بهینه‌سازی پارامترها را اجرا کنید؟ (y/n): ", end="")
        choice = input().lower().strip()
        if choice == 'y':
            demo_optimization()
        
        print("\n" + "=" * 60)
        print("✅ تمام نمونه‌ها با موفقیت اجرا شدند!")
        print("برای استفاده از رابط وب، فایل web_interface.py را اجرا کنید")
        print("=" * 60)
        
    except KeyboardInterrupt:
        print("\n\n⏹️ اجرا توسط کاربر متوقف شد")
    except Exception as e:
        print(f"\n❌ خطا در اجرای نمونه‌ها: {e}")
        print("لطفاً مطمئن شوید که تمام وابستگی‌ها نصب شده‌اند")

if __name__ == "__main__":
    main()