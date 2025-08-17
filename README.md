# Advanced Forex Trading Bot / ربات پیشرفته معاملات فارکس

A sophisticated, high-accuracy forex trading system with advanced technical analysis, comprehensive risk management, and real-time monitoring capabilities.

یک سیستم پیشرفته و با دقت بالای معاملات فارکس با تحلیل تکنیکال پیشرفته، مدیریت ریسک جامع و قابلیت‌های نظارت بلادرنگ.

## 🌟 Features / ویژگی‌ها

### 📈 Advanced Trading Strategy / استراتژی پیشرفته معاملات
- **Multi-timeframe analysis** (M15, H1, H4, D1) / تحلیل چندگانه تایم‌فریم
- **20+ Technical indicators** including EMA, RSI, MACD, Bollinger Bands, ADX, Stochastic, Williams %R, CCI, Parabolic SAR / بیش از 20 اندیکاتور تکنیکال
- **Advanced signal generation** with confidence scoring / تولید سیگنال پیشرفته با امتیازدهی اعتماد
- **Support/Resistance detection** / تشخیص سطوح حمایت و مقاومت
- **Market structure analysis** / تحلیل ساختار بازار

### 🛡️ Comprehensive Risk Management / مدیریت ریسک جامع
- **Position sizing** based on volatility and account balance / اندازه‌گیری پوزیشن بر اساس نوسانات و موجودی حساب
- **Multi-level risk controls** (per trade, daily, weekly, monthly) / کنترل‌های ریسک چندسطحی
- **Drawdown protection** with automatic position reduction / حفاظت از افت با کاهش خودکار پوزیشن
- **Currency exposure limits** / محدودیت‌های مواجهه ارزی
- **Correlation-based position sizing** / اندازه‌گیری پوزیشن بر اساس همبستگی

### 📊 Advanced Backtesting / بک‌تست پیشرفته
- **Historical data analysis** using yfinance / تحلیل داده‌های تاریخی
- **Comprehensive performance metrics** / معیارهای عملکرد جامع
- **Visual results** with equity curves and trade distribution / نتایج بصری با منحنی‌های سرمایه
- **Strategy validation** before live trading / اعتبارسنجی استراتژی قبل از معاملات زنده

### 🔄 Live Trading Integration / ادغام معاملات زنده
- **MetaTrader 5** integration / ادغام با متاتریدر 5
- **Real-time market data** processing / پردازش داده‌های بازار بلادرنگ
- **Automated trade execution** / اجرای خودکار معاملات
- **Position monitoring** and management / نظارت و مدیریت پوزیشن‌ها

### 📱 Real-time Monitoring & Alerts / نظارت و هشدارهای بلادرنگ
- **Telegram notifications** for trades and alerts / اعلان‌های تلگرام برای معاملات و هشدارها
- **Performance tracking** with daily/weekly/monthly reports / ردیابی عملکرد با گزارش‌های روزانه/هفتگی/ماهانه
- **Risk alerts** for drawdown and exposure limits / هشدارهای ریسک برای افت و محدودیت‌های مواجهه
- **Automated reporting** / گزارش‌دهی خودکار

## 🚀 Quick Start / شروع سریع

### Prerequisites / پیش‌نیازها

1. **Python 3.8+** / پایتون 3.8 یا بالاتر
2. **MetaTrader 5** account / حساب متاتریدر 5
3. **TA-Lib** library / کتابخانه TA-Lib

### Installation / نصب

```bash
# Clone the repository / کلون کردن مخزن
git clone <repository-url>
cd forex-trading-bot

# Install dependencies / نصب وابستگی‌ها
pip install -r requirements.txt

# Install TA-Lib (Windows) / نصب TA-Lib (ویندوز)
# Download from: https://www.lfd.uci.edu/~gohlke/pythonlibs/#ta-lib
pip install TA_Lib-0.4.25-cp39-cp39-win_amd64.whl

# Install TA-Lib (Linux/Mac) / نصب TA-Lib (لینوکس/مک)
sudo apt-get install build-essential
wget http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz
tar -xzf ta-lib-0.4.0-src.tar.gz
cd ta-lib/
./configure --prefix=/usr
make
sudo make install
pip install TA-Lib
```

### Configuration / پیکربندی

1. **Create environment file** / ایجاد فایل محیط:

```bash
# Create .env file / ایجاد فایل .env
touch .env
```

2. **Add your credentials** / اضافه کردن اعتبارنامه‌ها:

```env
# MetaTrader 5 Credentials / اعتبارنامه‌های متاتریدر 5
MT5_ACCOUNT=12345678
MT5_PASSWORD=your_password
MT5_SERVER=MetaQuotes-Demo

# Telegram Bot (Optional) / ربات تلگرام (اختیاری)
TELEGRAM_BOT_TOKEN=your_bot_token
TELEGRAM_CHAT_ID=your_chat_id
```

3. **Configure trading parameters** / پیکربندی پارامترهای معاملاتی:

The system will create a `trading_config.json` file with default settings on first run.
سیستم در اولین اجرا فایل `trading_config.json` را با تنظیمات پیش‌فرض ایجاد می‌کند.

## 📋 Usage / نحوه استفاده

### Backtesting / بک‌تست

```python
from backtester import ForexBacktester

# Create backtester / ایجاد بک‌تستر
backtester = ForexBacktester(initial_balance=10000)

# Run backtest / اجرای بک‌تست
results = backtester.run_backtest(
    symbol='EURUSD',
    start_date='2024-01-01',
    end_date='2024-12-01',
    confidence_threshold=75.0
)

# Generate report / تولید گزارش
report = backtester.generate_report('backtest_report.txt')
print(report)

# Plot results / رسم نتایج
backtester.plot_results('backtest_results.png')
```

### Live Trading / معاملات زنده

```bash
# Start trading / شروع معاملات
python live_trader.py start

# Check status / بررسی وضعیت
python live_trader.py status

# Generate report / تولید گزارش
python live_trader.py report

# Stop trading / توقف معاملات
python live_trader.py stop

# Run backtest validation / اجرای اعتبارسنجی بک‌تست
python live_trader.py backtest EURUSD
```

### Manual Trading Bot / ربات معاملاتی دستی

```python
from forex_trading_bot import AdvancedForexTradingBot

# Initialize bot / مقداردهی اولیه ربات
bot = AdvancedForexTradingBot(
    account=12345678,
    password="your_password",
    server="MetaQuotes-Demo"
)

# Run strategy / اجرای استراتژی
bot.run_strategy()
```

## ⚙️ Configuration / پیکربندی

### Trading Configuration / پیکربندی معاملات

```json
{
    "trading": {
        "symbols": ["EURUSD", "GBPUSD", "USDJPY"],
        "confidence_threshold": 75.0,
        "max_concurrent_trades": 5,
        "trading_hours": {
            "start": "08:00",
            "end": "17:00",
            "timezone": "UTC"
        }
    }
}
```

### Risk Configuration / پیکربندی ریسک

```json
{
    "risk": {
        "max_risk_per_trade": 0.02,
        "max_daily_loss": 0.05,
        "max_drawdown": 0.15,
        "initial_balance": 10000
    }
}
```

### Alert Configuration / پیکربندی هشدارها

```json
{
    "alerts": {
        "max_drawdown_alert": 0.10,
        "daily_loss_alert": 0.03,
        "consecutive_losses_alert": 5,
        "low_balance_alert": 0.70
    }
}
```

## 📊 Performance Metrics / معیارهای عملکرد

The system tracks comprehensive performance metrics:
سیستم معیارهای عملکرد جامعی را ردیابی می‌کند:

### Basic Metrics / معیارهای پایه
- **Total Trades** / کل معاملات
- **Win Rate** / نرخ برد
- **Profit Factor** / ضریب سود
- **Average Win/Loss** / میانگین برد/باخت

### Risk Metrics / معیارهای ریسک
- **Maximum Drawdown** / حداکثر افت
- **Sharpe Ratio** / نسبت شارپ
- **Sortino Ratio** / نسبت سورتینو
- **Calmar Ratio** / نسبت کالمار

### Advanced Metrics / معیارهای پیشرفته
- **Monthly Win Rate** / نرخ برد ماهانه
- **Consecutive Wins/Losses** / بردها/باخت‌های متوالی
- **Trade Duration Analysis** / تحلیل مدت معاملات
- **Currency Exposure** / مواجهه ارزی

## 🔧 System Architecture / معماری سیستم

```
forex-trading-bot/
├── forex_trading_bot.py      # Main trading bot / ربات معاملاتی اصلی
├── risk_manager.py           # Risk management system / سیستم مدیریت ریسک
├── backtester.py            # Backtesting engine / موتور بک‌تست
├── live_trader.py           # Live trading manager / مدیر معاملات زنده
├── requirements.txt         # Dependencies / وابستگی‌ها
├── README.md               # Documentation / مستندات
├── .env                    # Environment variables / متغیرهای محیط
├── trading_config.json     # Trading configuration / پیکربندی معاملات
├── logs/                   # Log files / فایل‌های لاگ
├── data/                   # Performance data / داده‌های عملکرد
└── backtest_results/       # Backtest outputs / خروجی‌های بک‌تست
```

## 📈 Strategy Details / جزئیات استراتژی

### Signal Generation / تولید سیگنال

The bot uses a sophisticated multi-factor approach:
ربات از رویکرد چندعاملی پیچیده استفاده می‌کند:

1. **Trend Analysis (30%)** / تحلیل روند
   - EMA crossovers across timeframes / تقاطع‌های EMA در تایم‌فریم‌ها
   - Multi-timeframe trend confirmation / تأیید روند چندتایم‌فریمی

2. **Momentum Analysis (25%)** / تحلیل مومنتوم
   - RSI levels and divergences / سطوح RSI و واگرایی‌ها
   - MACD signal line crossovers / تقاطع‌های خط سیگنال MACD
   - Stochastic oscillator / نوسان‌گر استوکاستیک

3. **Volume Analysis (15%)** / تحلیل حجم
   - On-Balance Volume trends / روندهای حجم تعادلی
   - Volume confirmation / تأیید حجم

4. **Support/Resistance (15%)** / حمایت/مقاومت
   - Dynamic S/R levels / سطوح پویای حمایت/مقاومت
   - Bollinger Bands positioning / موقعیت‌یابی باندهای بولینگر

5. **Market Structure (15%)** / ساختار بازار
   - ADX trend strength / قدرت روند ADX
   - Price action patterns / الگوهای عمل قیمت
   - Parabolic SAR signals / سیگنال‌های پارابولیک SAR

### Entry Conditions / شرایط ورود

A trade is executed when:
یک معامله زمانی اجرا می‌شود که:

- **Confidence Score ≥ 75%** / امتیاز اعتماد ≥ 75%
- **Signal Strength > 0.6** / قدرت سیگنال > 0.6
- **Risk Management Approval** / تأیید مدیریت ریسک
- **Within Trading Hours** / در ساعات معاملاتی
- **Correlation Limits Met** / محدودیت‌های همبستگی رعایت شده

### Exit Strategy / استراتژی خروج

- **Take Profit: 2x ATR** / سود‌گیری: 2 برابر ATR
- **Stop Loss: 1x ATR** / ضرربند: 1 برابر ATR
- **Risk:Reward = 1:2** / ریسک:پاداش = 1:2

## 🚨 Risk Management / مدیریت ریسک

### Position Sizing / اندازه‌گیری پوزیشن

The system uses advanced position sizing based on:
سیستم از اندازه‌گیری پوزیشن پیشرفته بر اساس موارد زیر استفاده می‌کند:

- **Account Balance** / موجودی حساب
- **Volatility (ATR)** / نوسانات (ATR)
- **Current Drawdown** / افت فعلی
- **Correlation with Existing Positions** / همبستگی با پوزیشن‌های موجود
- **Currency Exposure** / مواجهه ارزی

### Risk Limits / محدودیت‌های ریسک

- **Per Trade: 2%** / هر معامله: 2%
- **Daily: 5%** / روزانه: 5%
- **Weekly: 10%** / هفتگی: 10%
- **Monthly: 20%** / ماهانه: 20%
- **Maximum Drawdown: 15%** / حداکثر افت: 15%

## 📱 Telegram Integration / ادغام تلگرام

### Setup Telegram Bot / راه‌اندازی ربات تلگرام

1. Create a bot with @BotFather / ایجاد ربات با @BotFather
2. Get bot token / دریافت توکن ربات
3. Get your chat ID / دریافت شناسه چت
4. Add to .env file / اضافه کردن به فایل .env

### Notification Types / انواع اعلان‌ها

- **🚀 Trading Started** / معاملات آغاز شد
- **💰 Trade Executed** / معامله اجرا شد
- **⚠️ Risk Alerts** / هشدارهای ریسک
- **🛑 Trading Stopped** / معاملات متوقف شد
- **📊 Daily Reports** / گزارش‌های روزانه

## 🐛 Troubleshooting / عیب‌یابی

### Common Issues / مشکلات رایج

1. **TA-Lib Installation Error** / خطای نصب TA-Lib
   ```bash
   # Windows
   pip install --find-links=https://www.lfd.uci.edu/~gohlke/pythonlibs/ TA-Lib
   
   # Linux/Mac
   brew install ta-lib  # Mac
   sudo apt-get install libta-lib-dev  # Linux
   ```

2. **MT5 Connection Failed** / اتصال MT5 ناموفق
   - Check account credentials / بررسی اعتبارنامه حساب
   - Ensure MT5 is running / اطمینان از اجرای MT5
   - Verify server name / تأیید نام سرور

3. **No Market Data** / عدم وجود داده‌های بازار
   - Check symbol availability / بررسی در دسترس بودن نماد
   - Verify market hours / تأیید ساعات بازار
   - Check internet connection / بررسی اتصال اینترنت

### Log Files / فایل‌های لاگ

- **Main Log**: `logs/forex_trader_YYYYMMDD.log`
- **Trade Log**: `logs/trades_YYYYMMDD.log`
- **Performance Log**: `logs/performance_YYYYMMDD.log`

## 📈 Performance Optimization / بهینه‌سازی عملکرد

### Strategy Optimization / بهینه‌سازی استراتژی

1. **Backtest Different Parameters** / بک‌تست پارامترهای مختلف
2. **Adjust Confidence Threshold** / تنظیم آستانه اعتماد
3. **Optimize Timeframe Weights** / بهینه‌سازی وزن‌های تایم‌فریم
4. **Fine-tune Risk Parameters** / تنظیم دقیق پارامترهای ریسک

### System Performance / عملکرد سیستم

- **Use SSD for faster data access** / استفاده از SSD برای دسترسی سریع‌تر به داده‌ها
- **Sufficient RAM (8GB+)** / RAM کافی (8 گیگابایت یا بیشتر)
- **Stable internet connection** / اتصال اینترنت پایدار
- **VPS for 24/7 operation** / VPS برای عملکرد 24/7

## 🔒 Security / امنیت

### Best Practices / بهترین شیوه‌ها

- **Never share credentials** / هرگز اعتبارنامه‌ها را به اشتراک نگذارید
- **Use demo account first** / ابتدا از حساب دمو استفاده کنید
- **Regular backups** / پشتیبان‌گیری منظم
- **Monitor logs regularly** / نظارت منظم بر لاگ‌ها
- **Keep software updated** / نرم‌افزار را به‌روز نگه دارید

## 📚 Additional Resources / منابع اضافی

### Learning Materials / مواد آموزشی

- [MetaTrader 5 Python Integration](https://www.mql5.com/en/docs/python_metatrader5)
- [TA-Lib Documentation](https://mrjbq7.github.io/ta-lib/)
- [Forex Trading Strategies](https://www.babypips.com/)

### Support / پشتیبانی

For issues and questions:
برای مسائل و سؤالات:

- Create an issue on GitHub / ایجاد مسئله در گیت‌هاب
- Check the logs for error details / بررسی لاگ‌ها برای جزئیات خطا
- Review configuration files / بررسی فایل‌های پیکربندی

## ⚠️ Disclaimer / سلب مسئولیت

**This trading bot is for educational and research purposes only. Trading forex involves significant risk and may not be suitable for all investors. Past performance does not guarantee future results. Always trade responsibly and never risk more than you can afford to lose.**

**این ربات معاملاتی تنها برای اهداف آموزشی و تحقیقاتی است. معاملات فارکس شامل ریسک قابل توجهی است و ممکن است برای همه سرمایه‌گذاران مناسب نباشد. عملکرد گذشته ضامن نتایج آینده نیست. همیشه مسئولانه معامله کنید و هرگز بیش از آنچه می‌توانید از دست بدهید، ریسک نکنید.**

## 📄 License / مجوز

This project is licensed under the MIT License - see the LICENSE file for details.
این پروژه تحت مجوز MIT منتشر شده است - برای جزئیات فایل LICENSE را ببینید.

---

**Happy Trading! / معاملات موفق!** 🚀📈