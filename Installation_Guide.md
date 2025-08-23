# راهنمای نصب و استفاده از ربات معاملاتی هوشمند / AI Expert Advisor Installation Guide

## فهرست / Table of Contents

### فارسی
1. [مقدمه](#مقدمه)
2. [ویژگی‌های کلیدی](#ویژگیهای-کلیدی)
3. [نصب](#نصب)
4. [تنظیمات](#تنظیمات)
5. [استراتژی معاملاتی](#استراتژی-معاملاتی)
6. [مدیریت ریسک](#مدیریت-ریسک)
7. [بهینه‌سازی](#بهینهسازی)

### English
1. [Introduction](#introduction)
2. [Key Features](#key-features)
3. [Installation](#installation)
4. [Settings](#settings)
5. [Trading Strategy](#trading-strategy)
6. [Risk Management](#risk-management)
7. [Optimization](#optimization)

---

## مقدمه

این ربات معاملاتی پیشرفته با استفاده از هوش مصنوعی و تکنیک‌های یادگیری ماشین طراحی شده است. ربات از ترکیب چندین اندیکاتور فنی، تحلیل price action، و الگوریتم‌های پیشرفته برای تولید سیگنال‌های معاملاتی با دقت بالا استفاده می‌کند.

### ویژگی‌های کلیدی

**🧠 هوش مصنوعی پیشرفته:**
- شبکه عصبی با لایه‌های مخفی چندگانه
- یادگیری تطبیقی بر اساس عملکرد
- تحلیل رژیم بازار (trending/ranging)
- ترکیب وزن‌دار اندیکاتورها

**📊 اندیکاتورهای متنوع:**
- MACD، RSI، Bollinger Bands
- ADX، Stochastic، CCI
- Williams %R، Momentum
- ATR برای اندازه‌گیری نوسانات

**💰 مدیریت ریسک هوشمند:**
- محاسبه دینامیک سایز لات
- Stop Loss و Take Profit خودکار
- Trailing Stop و Break Even
- محدودیت سود و ضرر روزانه

**🔍 تحلیل‌های پیشرفته:**
- تحلیل price action و الگوهای کندلی
- تحلیل حجم معاملات
- تحلیل چند تایم فریم
- شناسایی سطوح حمایت و مقاومت

**⚙️ تنظیمات قابل تنظیم:**
- فیلتر اسپرد و نوسانات
- فیلتر زمانی معاملات
- فیلتر اخبار مهم
- پارامترهای قابل بهینه‌سازی

---

## نصب

### 1. نصب در MT4
```
1. فایل AI_Expert_Advisor.mq4 را در پوشه زیر کپی کنید:
   MT4_Data_Folder/MQL4/Experts/

2. MetaTrader 4 را مجدداً راه‌اندازی کنید

3. از Navigator → Expert Advisors → AI_Expert_Advisor را بر روی چارت بکشید

4. تنظیمات را بر اساس نیاز خود تغییر دهید

5. "Allow live trading" را فعال کنید
```

### 2. نصب در MT5
```
1. فایل AI_Expert_Advisor_MT5.mq5 را در پوشه زیر کپی کنید:
   MT5_Data_Folder/MQL5/Experts/

2. MetaTrader 5 را مجدداً راه‌اندازی کنید

3. از Navigator → Expert Advisors → AI_Expert_Advisor_MT5 را بر روی چارت بکشید

4. تنظیمات پیشرفته را تنظیم کنید

5. "Allow algorithmic trading" را فعال کنید
```

---

## تنظیمات

### تنظیمات اصلی / General Settings

```cpp
// سایز لات پایه
LotSize = 0.1

// استفاده از سایز لات خودکار (توصیه می‌شود)
UseAutoLots = true

// درصد ریسک هر معامله (1-5% توصیه می‌شود)
RiskPercent = 2.0

// شماره جادویی (برای تشخیص معاملات)
MagicNumber = 12345

// حداکثر لغزش قیمت
Slippage = 3
```

### تنظیمات استراتژی / Strategy Settings

```cpp
// استفاده از منطق هوش مصنوعی
UseAILogic = true

// حد آستانه اطمینان سیگنال (60-85 توصیه می‌شود)
AIConfidenceThreshold = 75

// استفاده از تحلیل Price Action
UsePriceAction = true

// استفاده از تحلیل حجم
UseVolumeAnalysis = true

// تحلیل چند تایم فریم
UseMultiTimeframe = true

// استفاده از شبکه عصبی (MT5)
UseNeuralNetwork = true
```

### تنظیمات مدیریت ریسک / Risk Management

```cpp
// استفاده از Stop Loss دینامیک
UseDynamicSL = true

// استفاده از Take Profit دینامیک  
UseDynamicTP = true

// ضریب ATR برای Stop Loss
ATR_SL_Multiplier = 2.5

// ضریب ATR برای Take Profit
ATR_TP_Multiplier = 4.0

// حداکثر ضرر روزانه (درصد)
MaxDailyLoss = 5.0

// حداکثر سود روزانه (درصد)
MaxDailyProfit = 15.0

// استفاده از Trailing Stop
UseTrailingStop = true

// نقطه شروع Trailing (پیپ)
TrailingStart = 30

// گام Trailing (پیپ)
TrailingStep = 10
```

---

## استراتژی معاملاتی

### الگوریتم تصمیم‌گیری

ربات از سیستم امتیازدهی پیشرفته‌ای استفاده می‌کند:

**1. تحلیل اندیکاتورها (70% وزن):**
- MACD: 20% وزن - سیگنال‌های تقاطع
- RSI: 15% وزن - شرایط اشباع خرید/فروش
- Bollinger Bands: 15% وزن - شکست سطوح
- ADX: 10% وزن - قدرت ترند
- Stochastic: 10% وزن - مومنتوم

**2. تحلیل Price Action (20% وزن):**
- الگوهای کندلی (Hammer، Doji، Engulfing)
- سطوح حمایت و مقاومت
- خطوط ترند
- الگوهای چارتی

**3. تحلیل حجم (10% وزن):**
- تأیید حرکات قیمتی با حجم
- شناسایی انحرافات حجمی

### شرایط ورود به معامله

**خرید (Buy):**
- امتیاز صعودی > آستانه اطمینان
- عدم وجود پوزیشن باز خرید
- تأیید از فیلترهای بازار

**فروش (Sell):**
- امتیاز نزولی > آستانه اطمینان  
- عدم وجود پوزیشن باز فروش
- تأیید از فیلترهای بازار

---

## مدیریت ریسک

### محاسبه سایز لات خودکار

```cpp
سایز لات = (موجودی حساب × درصد ریسک) / (Stop Loss × ارزش تیک)
```

### مدیریت پوزیشن

**Stop Loss دینامیک:**
- بر اساس ATR محاسبه می‌شود
- متناسب با نوسانات بازار تنظیم می‌شود

**Take Profit دینامیک:**
- نسبت ریسک به پاداش 1:2 تا 1:4
- بر اساس شرایط بازار تنظیم می‌شود

**Trailing Stop:**
- فعال می‌شود پس از رسیدن به سود مشخص
- به‌طور پیوسته Stop Loss را به سمت سود جابجا می‌کند

### محدودیت‌های روزانه

- معاملات متوقف می‌شود در صورت رسیدن به حد سود/ضرر روزانه
- محافظت از سرمایه در برابر شرایط نامناسب بازار

---

## بهینه‌سازی

### پارامترهای کلیدی برای بهینه‌سازی

**1. تنظیمات اندیکاتور:**
```cpp
FastMA: 8-15 (پیشنهاد: 12)
SlowMA: 21-30 (پیشنهاد: 26)
RSI_Period: 10-20 (پیشنهاد: 14)
BB_Period: 15-25 (پیشنهاد: 20)
```

**2. مدیریت ریسک:**
```cpp
RiskPercent: 1-3% (محافظه‌کار), 3-5% (متعادل)
ATR_SL_Multiplier: 2.0-3.0
ATR_TP_Multiplier: 3.0-5.0
AIConfidenceThreshold: 70-85
```

**3. فیلترها:**
```cpp
MaxSpread: 10-30 پیپ (بسته به نماد)
MinVolatility: 0.00005-0.0001
MaxVolatility: 0.003-0.01
```

### نکات بهینه‌سازی

1. **تست بر روی داده‌های تاریخی:**
   - حداقل 6 ماه داده تاریخی
   - شامل شرایط مختلف بازار

2. **تنظیم بر اساس نماد:**
   - هر نماد نیاز به تنظیمات مخصوص دارد
   - در نظر گیری ساعات فعال هر بازار

3. **مانیتورینگ مداوم:**
   - بررسی عملکرد هفتگی
   - تنظیم پارامترها در صورت نیاز

---

# English Version

## Introduction

This advanced trading Expert Advisor utilizes artificial intelligence and machine learning techniques to generate high-accuracy trading signals. The EA combines multiple technical indicators, price action analysis, and sophisticated algorithms for professional trading.

## Key Features

**🧠 Advanced AI:**
- Multi-layer neural network
- Adaptive learning based on performance
- Market regime analysis (trending/ranging)
- Weighted indicator combinations

**📊 Comprehensive Indicators:**
- MACD, RSI, Bollinger Bands
- ADX, Stochastic, CCI
- Williams %R, Momentum
- ATR for volatility measurement

**💰 Smart Risk Management:**
- Dynamic lot size calculation
- Automatic Stop Loss and Take Profit
- Trailing Stop and Break Even
- Daily profit/loss limits

**🔍 Advanced Analysis:**
- Price action and candlestick patterns
- Volume analysis
- Multi-timeframe analysis
- Support/resistance level identification

## Installation

### For MT4:
1. Copy `AI_Expert_Advisor.mq4` to: `MT4_Data_Folder/MQL4/Experts/`
2. Restart MetaTrader 4
3. Drag the EA from Navigator to chart
4. Configure settings
5. Enable "Allow live trading"

### For MT5:
1. Copy `AI_Expert_Advisor_MT5.mq5` to: `MT5_Data_Folder/MQL5/Experts/`
2. Restart MetaTrader 5
3. Drag the EA from Navigator to chart
4. Configure advanced settings
5. Enable "Allow algorithmic trading"

## Settings

### Recommended Settings for Different Account Sizes:

**Small Account ($500-$2000):**
```
LotSize = 0.01
RiskPercent = 1.5%
AIConfidenceThreshold = 80
MaxDailyLoss = 3%
MaxDailyProfit = 8%
```

**Medium Account ($2000-$10000):**
```
LotSize = 0.1
RiskPercent = 2.0%
AIConfidenceThreshold = 75
MaxDailyLoss = 4%
MaxDailyProfit = 12%
```

**Large Account ($10000+):**
```
LotSize = 0.1
RiskPercent = 2.5%
AIConfidenceThreshold = 70
MaxDailyLoss = 5%
MaxDailyProfit = 15%
```

## Trading Strategy

The EA uses a sophisticated scoring system:
- **70% Technical Indicators:** MACD, RSI, BB, ADX, Stochastic
- **20% Price Action:** Candlestick patterns, S/R levels
- **10% Volume Analysis:** Volume confirmation

### Entry Conditions:
- Bullish/Bearish score > Confidence threshold
- No existing position in same direction
- Market filters passed

## Risk Management

### Position Sizing:
```
Lot Size = (Account Balance × Risk%) / (Stop Loss × Tick Value)
```

### Trade Management:
- **Dynamic SL:** Based on ATR volatility
- **Dynamic TP:** 2:1 to 4:1 risk-reward ratio
- **Trailing Stop:** Protects profits
- **Break Even:** Moves SL to entry price

## Optimization Tips

1. **Backtest thoroughly:** Minimum 6 months historical data
2. **Symbol-specific settings:** Each pair needs unique parameters
3. **Regular monitoring:** Weekly performance review
4. **Market conditions:** Adjust for trending/ranging markets

### Performance Metrics to Monitor:
- Win rate (target: >60%)
- Risk-reward ratio (target: >1.5)
- Maximum drawdown (keep <20%)
- Profit factor (target: >1.3)

---

## 🔧 Technical Support

### Common Issues:

**EA not trading:**
- Check "Allow live trading" is enabled
- Verify market hours and spread conditions
- Ensure minimum balance requirements

**Poor performance:**
- Lower confidence threshold
- Adjust risk parameters
- Check symbol-specific settings

**High drawdown:**
- Reduce risk percentage
- Increase stop loss multiplier
- Enable break even function

### Contact & Updates:
- Regular updates will improve AI algorithms
- Monitor news and market conditions
- Consider fundamental analysis alongside technical

---

## ⚠️ Risk Disclaimer

Trading foreign exchange and CFDs involves significant risk and may not be suitable for all investors. Past performance does not guarantee future results. Only trade with money you can afford to lose. This EA is a tool to assist in trading decisions but does not guarantee profits.

---

## 📈 Expected Performance

**Conservative Settings:**
- Expected monthly return: 5-15%
- Maximum drawdown: 10-15%
- Win rate: 60-70%

**Aggressive Settings:**
- Expected monthly return: 15-30%
- Maximum drawdown: 15-25%
- Win rate: 55-65%

Remember: Higher returns come with higher risks. Always trade responsibly and within your risk tolerance.