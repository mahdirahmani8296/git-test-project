# راهنمای نصب و استفاده از ربات اسکالپینگ پیشرفته
# Advanced Scalping EA Setup Guide

## مقدمه / Introduction

این ربات اسکالپینگ پیشرفته برای MetaTrader 4 و 5 طراحی شده است و استراتژی معاملاتی کوتاه‌مدت با مدیریت ریسک خودکار را پیاده‌سازی می‌کند.

This advanced scalping robot is designed for MetaTrader 4 and 5, implementing short-term trading strategies with automatic risk management.

## ویژگی‌های کلیدی / Key Features

### 🎯 استراتژی معاملاتی / Trading Strategy
- **اسکالپینگ**: معاملات کوتاه‌مدت با سود کم اما تعداد زیاد
- **تحلیل تکنیکال**: استفاده از 6 اندیکاتور مختلف
- **خروج سریع**: بستن خودکار معاملات در سود مناسب

### 📊 اندیکاتورهای استفاده شده / Indicators Used
1. **RSI** (Relative Strength Index) - شناسایی نواحی خرید/فروش بیش از حد
2. **MACD** (Moving Average Convergence Divergence) - تشخیص ترند
3. **EMA** (Exponential Moving Average) - میانگین متحرک سریع و کند
4. **Bollinger Bands** - نواحی حمایت و مقاومت
5. **ATR** (Average True Range) - محاسبه نوسانات بازار
6. **Momentum** - تأیید قدرت حرکت قیمت

### 💰 مدیریت ریسک / Risk Management
- محاسبه خودکار اندازه لات بر اساس درصد ریسک
- Stop Loss و Take Profit خودکار
- Trailing Stop برای حداکثر سود
- محدودیت حداکثر ضرر روزانه

## نصب / Installation

### مرحله 1: دانلود فایل‌ها
1. فایل `AdvancedScalpingEA.mq4` برای MetaTrader 4
2. فایل `AdvancedScalpingEA.mq5` برای MetaTrader 5

### مرحله 2: کپی فایل‌ها
**برای MT4:**
```
C:\Users\[username]\AppData\Roaming\MetaQuotes\Terminal\[terminal_id]\MQL4\Experts\
```

**برای MT5:**
```
C:\Users\[username]\AppData\Roaming\MetaQuotes\Terminal\[terminal_id]\MQL5\Experts\
```

### مرحله 3: کامپایل
1. MetaEditor را باز کنید
2. فایل EA را باز کنید
3. F7 را فشار دهید یا روی Compile کلیک کنید

### مرحله 4: راه‌اندازی
1. MetaTrader را مجدداً راه‌اندازی کنید
2. EA را روی چارت مورد نظر drag کنید
3. تنظیمات را طبق راهنما زیر انجام دهید

## تنظیمات پارامترها / Parameter Settings

### ⚙️ تنظیمات اصلی EA / EA Settings
- **LotSize**: اندازه لات ثابت (0.01 پیشنهادی)
- **AutoLotSize**: محاسبه خودکار اندازه لات (true پیشنهادی)
- **RiskPercent**: درصد ریسک هر معامله (2% پیشنهادی)
- **MagicNumber**: شماره منحصر به فرد ربات (12345)
- **Slippage**: حداکثر لغزش مجاز (3)

### 📈 تنظیمات اسکالپینگ / Scalping Settings
- **ScalpingTimeframe**: تایم فریم اسکالپینگ (M1 پیشنهادی)
- **MinProfitPips**: حداقل سود برای خروج سریع (5 پیپ)
- **MaxSpread**: حداکثر اسپرد مجاز (3 پیپ)
- **UseFastExit**: استفاده از خروج سریع (true)
- **MaxOpenTrades**: حداکثر معاملات همزمان (3)

### 🔧 تنظیمات اندیکاتورها / Indicator Settings
- **RSI_Period**: دوره RSI (14)
- **RSI_Overbought**: سطح خرید بیش از حد (70)
- **RSI_Oversold**: سطح فروش بیش از حد (30)
- **MACD_Fast**: EMA سریع MACD (12)
- **MACD_Slow**: EMA کند MACD (26)
- **MACD_Signal**: خط سیگنال MACD (9)
- **EMA_Fast**: دوره EMA سریع (10)
- **EMA_Slow**: دوره EMA کند (21)
- **BB_Period**: دوره Bollinger Bands (20)
- **BB_Deviation**: انحراف Bollinger Bands (2.0)
- **ATR_Period**: دوره ATR (14)

### 🛡️ مدیریت ریسک / Risk Management
- **UseATR_SL**: استفاده از ATR برای Stop Loss (true)
- **ATR_SL_Multiplier**: ضریب ATR برای SL (2.0)
- **FixedSL**: Stop Loss ثابت (20 پیپ)
- **RiskRewardRatio**: نسبت ریسک به ریوارد (1.5)
- **UseTrailingStop**: استفاده از Trailing Stop (true)
- **TrailingStart**: شروع Trailing Stop (10 پیپ)
- **TrailingStep**: گام Trailing Stop (5 پیپ)

### ⏰ تنظیمات زمانی / Time Settings
- **UseTimeFilter**: استفاده از فیلتر زمانی (true)
- **StartHour**: ساعت شروع معاملات (8)
- **EndHour**: ساعت پایان معاملات (18)
- **AvoidNews**: اجتناب از معاملات حین اخبار (true)

## استراتژی معاملاتی / Trading Strategy

### شرایط خرید / Buy Conditions
1. RSI < 30 (فروش بیش از حد)
2. MACD Main > MACD Signal
3. EMA سریع > EMA کند
4. قیمت < نوار پایین Bollinger
5. Ask > EMA سریع
6. Momentum صعودی

### شرایط فروش / Sell Conditions
1. RSI > 70 (خرید بیش از حد)
2. MACD Main < MACD Signal
3. EMA سریع < EMA کند
4. قیمت > نوار بالای Bollinger
5. Bid < EMA سریع
6. Momentum نزولی

### خروج از معامله / Exit Strategy
1. **Take Profit**: محاسبه خودکار بر اساس Risk:Reward
2. **Stop Loss**: محاسبه خودکار بر اساس ATR یا مقدار ثابت
3. **Fast Exit**: بستن سریع در صورت رسیدن به سود مناسب و تغییر RSI
4. **Trailing Stop**: دنبال کردن قیمت برای حداکثر سود

## نکات مهم / Important Notes

### ✅ بهترین شرایط استفاده
- جفت ارزهای پرنوسان مانند EUR/USD، GBP/USD، USD/JPY
- تایم فریم M1 یا M5
- ساعات پرترافیک بازار فارکس
- اسپرد کم (زیر 3 پیپ)

### ⚠️ هشدارها
- همیشه ابتدا روی حساب دمو تست کنید
- مدیریت ریسک را جدی بگیرید
- از معاملات حین اخبار مهم اجتناب کنید
- تنظیمات را بر اساس شرایط بازار تنظیم کنید

### 🔧 بهینه‌سازی
- پارامترهای اندیکاتورها را برای هر جفت ارز جداگانه تست کنید
- درصد ریسک را بر اساس سرمایه خود تنظیم کنید
- حداکثر معاملات همزمان را محدود کنید

## عیب‌یابی / Troubleshooting

### مشکلات رایج / Common Issues

1. **EA کار نمی‌کند**
   - بررسی کنید Live Trading فعال باشد
   - بررسی کنید تنظیمات EA صحیح باشد
   - لاگ‌ها را بررسی کنید

2. **معاملاتی باز نمی‌شود**
   - اسپرد را بررسی کنید
   - تنظیمات زمانی را بررسی کنید
   - موجودی حساب را بررسی کنید

3. **خطاهای کامپایل**
   - نسخه MetaTrader را بررسی کنید
   - فایل را مجدداً دانلود کنید
   - MetaEditor را مجدداً راه‌اندازی کنید

## مثال تنظیمات برای جفت‌های مختلف / Sample Settings

### EUR/USD (M1)
```
RiskPercent: 1.5%
MaxSpread: 2
MinProfitPips: 3
RSI_Overbought: 75
RSI_Oversold: 25
```

### GBP/USD (M1)
```
RiskPercent: 1.0%
MaxSpread: 3
MinProfitPips: 5
ATR_SL_Multiplier: 2.5
```

### USD/JPY (M1)
```
RiskPercent: 2.0%
MaxSpread: 2
MinProfitPips: 4
RiskRewardRatio: 2.0
```

## پشتیبانی / Support

در صورت بروز مشکل:
1. ابتدا این راهنما را مطالعه کنید
2. تنظیمات را مجدداً بررسی کنید
3. روی حساب دمو تست کنید

## مسئولیت / Disclaimer

- این ربات صرفاً برای اهداف آموزشی و تست طراحی شده است
- همیشه ابتدا روی حساب دمو تست کنید
- معاملات فارکس دارای ریسک بالایی است
- مسئولیت ضررهای احتمالی بر عهده کاربر است
- از سرمایه‌ای استفاده کنید که از دست دادن آن برایتان مشکل‌ساز نباشد

---

**نسخه**: 1.00  
**تاریخ**: 2024  
**سازگار با**: MetaTrader 4 & 5  
**نوع**: Expert Advisor (EA)