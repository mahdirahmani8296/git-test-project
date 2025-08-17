#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
فایل تنظیمات سیستم معاملاتی فارکس
Configuration file for Forex Trading System
"""

# تنظیمات کلی سیستم
SYSTEM_CONFIG = {
    'default_initial_balance': 10000,  # سرمایه اولیه پیش‌فرض
    'default_risk_per_trade': 0.02,    # درصد ریسک پیش‌فرض (2%)
    'max_position_size': 0.1,          # حداکثر اندازه پوزیشن (10% موجودی)
    'commission_rate': 0.001,          # نرخ کارمزد (0.1%)
    'pip_value': 0.0001,              # ارزش پیپ برای جفت ارزهای اصلی
    'default_stop_loss_pips': 50,     # حد ضرر پیش‌فرض (پیپ)
}

# پارامترهای استراتژی پیش‌فرض
DEFAULT_STRATEGY_PARAMS = {
    # RSI
    'rsi_period': 14,
    'rsi_overbought': 70,
    'rsi_oversold': 30,
    
    # EMA
    'ema_short': 9,
    'ema_long': 21,
    
    # MACD
    'macd_fast': 12,
    'macd_slow': 26,
    'macd_signal': 9,
    
    # Bollinger Bands
    'bollinger_period': 20,
    'bollinger_std': 2,
    
    # ATR
    'atr_period': 14,
    
    # Stochastic
    'stoch_k': 14,
    'stoch_d': 3,
    
    # Volume
    'volume_sma': 20,
    
    # ADX
    'adx_period': 14,
}

# نمادهای پیش‌فرض
DEFAULT_SYMBOLS = [
    'EURUSD=X',  # یورو/دلار
    'GBPUSD=X',  # پوند/دلار
    'USDJPY=X',  # دلار/ین
    'AUDUSD=X',  # دلار استرالیا/دلار
    'USDCAD=X',  # دلار/دلار کانادا
    'USDCHF=X',  # دلار/فرانک سوئیس
    'NZDUSD=X',  # دلار نیوزیلند/دلار
]

# بازه‌های زمانی پیش‌فرض
DEFAULT_TIMEFRAMES = {
    '1m': '1 دقیقه',
    '5m': '5 دقیقه',
    '15m': '15 دقیقه',
    '30m': '30 دقیقه',
    '1h': '1 ساعت',
    '4h': '4 ساعت',
    '1d': '1 روز',
    '1w': '1 هفته',
}

# تنظیمات بک‌تستینگ
BACKTEST_CONFIG = {
    'default_start_date': '2023-01-01',
    'default_end_date': '2023-12-31',
    'default_interval': '1h',
    'min_data_points': 50,  # حداقل تعداد نقاط داده برای تحلیل
}

# تنظیمات بهینه‌سازی
OPTIMIZATION_CONFIG = {
    'max_combinations': 1000,  # حداکثر تعداد ترکیبات برای تست
    'target_metric': 'sharpe_ratio',  # معیار هدف برای بهینه‌سازی
    'min_trades': 10,  # حداقل تعداد معاملات برای اعتبارسنجی
}

# محدوده‌های پارامتر برای بهینه‌سازی
OPTIMIZATION_RANGES = {
    'rsi_period': [10, 14, 20, 25],
    'rsi_overbought': [65, 70, 75, 80],
    'rsi_oversold': [20, 25, 30, 35],
    'ema_short': [5, 7, 9, 12, 15],
    'ema_long': [15, 18, 21, 26, 30],
    'macd_fast': [8, 10, 12, 15],
    'macd_slow': [20, 24, 26, 30],
    'bollinger_period': [15, 20, 25, 30],
    'bollinger_std': [1.5, 2.0, 2.5],
}

# تنظیمات رابط وب
WEB_CONFIG = {
    'host': '0.0.0.0',
    'port': 5000,
    'debug': True,
    'secret_key': 'forex_trading_secret_key_2024',
    'update_interval': 30,  # فاصله به‌روزرسانی داده‌ها (ثانیه)
    'max_cache_age': 300,   # حداکثر سن کش داده‌ها (ثانیه)
}

# تنظیمات لاگینگ
LOGGING_CONFIG = {
    'level': 'INFO',
    'format': '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    'file': 'forex_trading.log',
    'max_file_size': 10 * 1024 * 1024,  # 10 MB
    'backup_count': 5,
}

# تنظیمات امنیتی
SECURITY_CONFIG = {
    'max_requests_per_minute': 60,
    'allowed_origins': ['*'],
    'session_timeout': 3600,  # 1 ساعت
}

# تنظیمات نمایش
DISPLAY_CONFIG = {
    'decimal_places': 5,  # تعداد اعشار برای نمایش قیمت‌ها
    'currency_symbol': '$',
    'date_format': '%Y-%m-%d %H:%M:%S',
    'timezone': 'UTC',
}

# تنظیمات هشدارها
ALERT_CONFIG = {
    'profit_threshold': 0.05,  # هشدار سود 5%
    'loss_threshold': -0.03,   # هشدار زیان 3%
    'drawdown_threshold': 0.1, # هشدار افت 10%
    'volume_threshold': 2.0,   # هشدار حجم 2 برابر متوسط
}

# تنظیمات پیشرفته
ADVANCED_CONFIG = {
    'enable_machine_learning': False,  # فعال‌سازی یادگیری ماشین
    'enable_sentiment_analysis': False,  # تحلیل احساسات
    'enable_news_analysis': False,  # تحلیل اخبار
    'enable_correlation_analysis': True,  # تحلیل همبستگی
    'enable_volatility_analysis': True,  # تحلیل نوسانات
}

# تنظیمات API
API_CONFIG = {
    'yfinance_timeout': 30,  # تایم‌اوت برای درخواست‌های yfinance
    'retry_attempts': 3,     # تعداد تلاش‌های مجدد
    'retry_delay': 5,        # تاخیر بین تلاش‌ها (ثانیه)
}

def get_config():
    """
    دریافت تمام تنظیمات
    """
    return {
        'system': SYSTEM_CONFIG,
        'strategy': DEFAULT_STRATEGY_PARAMS,
        'symbols': DEFAULT_SYMBOLS,
        'timeframes': DEFAULT_TIMEFRAMES,
        'backtest': BACKTEST_CONFIG,
        'optimization': OPTIMIZATION_CONFIG,
        'web': WEB_CONFIG,
        'logging': LOGGING_CONFIG,
        'security': SECURITY_CONFIG,
        'display': DISPLAY_CONFIG,
        'alerts': ALERT_CONFIG,
        'advanced': ADVANCED_CONFIG,
        'api': API_CONFIG,
    }

def update_strategy_params(new_params):
    """
    به‌روزرسانی پارامترهای استراتژی
    """
    global DEFAULT_STRATEGY_PARAMS
    DEFAULT_STRATEGY_PARAMS.update(new_params)

def get_strategy_params():
    """
    دریافت پارامترهای استراتژی
    """
    return DEFAULT_STRATEGY_PARAMS.copy()

def get_system_config():
    """
    دریافت تنظیمات سیستم
    """
    return SYSTEM_CONFIG.copy()

def get_optimization_ranges():
    """
    دریافت محدوده‌های بهینه‌سازی
    """
    return OPTIMIZATION_RANGES.copy()

# مثال استفاده
if __name__ == "__main__":
    print("تنظیمات سیستم معاملاتی فارکس:")
    print("=" * 50)
    
    config = get_config()
    for section, settings in config.items():
        print(f"\n{section.upper()}:")
        for key, value in settings.items():
            print(f"  {key}: {value}")
    
    print(f"\nپارامترهای استراتژی پیش‌فرض:")
    strategy_params = get_strategy_params()
    for param, value in strategy_params.items():
        print(f"  {param}: {value}")