## ربات معامله‌گر فارکس (OANDA)

این پروژه یک ربات معامله‌گر ساده برای فارکس است که با استفاده از API پلتفرم OANDA (حساب دمو/پراکیتس) کار می‌کند. استراتژی پیش‌فرض، کراس میانگین متحرک (SMA کراس) با مدیریت ریسک بر اساس ATR است.

### راه‌اندازی سریع

1) پیش‌نیازها:
   - Python 3.10+
   - یک حساب دمو در OANDA و دریافت `API Token`

2) نصب:

```bash
cd /workspace/forex-bot
python3 -m venv .venv
/workspace/forex-bot/.venv/bin/pip install -U pip
/workspace/forex-bot/.venv/bin/pip install -r requirements.txt
```

3) پیکربندی:

فایل `.env` را بر اساس `.env.example` بسازید و مقادیر را پر کنید:

```
OANDA_API_TOKEN=...   # توکن دمو
OANDA_ACCOUNT_ID=...  # آیدی حساب دمو
OANDA_ENV=practice    # یا live (فقط با ریسک خودتان)
INSTRUMENT=EUR_USD
GRANULARITY=M5
RISK_PER_TRADE=0.01   # 1% از موجودی به ازای هر معامله
```

4) اجرای CLI:

```bash
/workspace/forex-bot/.venv/bin/python main.py --help
```

اجرای یک بار (بدون ارسال سفارش واقعی):

```bash
/workspace/forex-bot/.venv/bin/python main.py live --dry-run --once
```

اجرای پیوسته هر 60 ثانیه (ارسال سفارش واقعی فقط در صورت حذف `--dry-run`):

```bash
/workspace/forex-bot/.venv/bin/python main.py live --interval 60
```

### نکات استراتژی و محدودیت‌ها

- این نسخه نمونه آموزشی است و برای استفاده در حساب واقعی نیاز به توسعه، آزمون و مدیریت ریسک حرفه‌ای دارد.
- محاسبه اندازه موقعیت برای جفت‌هایی با USD به عنوان ارز مظنه (quote) ساده‌سازی شده است. برای ارزهای دیگر یا واحد پول حساب متفاوت، نیاز به تبدیل ارزی دارید.
- پیش‌فرض فقط حدضرر (Stop Loss) را تنظیم می‌کند. می‌توانید هدف سود (Take Profit) را نیز اضافه/تنظیم کنید.

### مسئولیت‌پذیری

معاملات دارای ریسک بالاست. نویسنده/سازنده هیچ مسئولیتی در قبال زیان‌های احتمالی ندارد. از این پروژه تنها در حساب دمو استفاده کنید تا زمانی که به‌خوبی آن را درک و بهبود دهید.

