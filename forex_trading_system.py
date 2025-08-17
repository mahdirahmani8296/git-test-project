#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
سیستم معاملات فارکس با دقت بالا
Forex Trading System with High Precision

این سیستم شامل استراتژی‌های پیشرفته و مدیریت ریسک است
This system includes advanced strategies and risk management
"""

import numpy as np
import pandas as pd
import yfinance as yf
import talib
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime, timedelta
import warnings
warnings.filterwarnings('ignore')

class AdvancedForexTrader:
    def __init__(self, symbol="EURUSD=X", initial_balance=10000, risk_percent=2):
        """
        مقداردهی اولیه سیستم معاملات
        Initialize the trading system
        """
        self.symbol = symbol
        self.initial_balance = initial_balance
        self.balance = initial_balance
        self.risk_percent = risk_percent
        self.positions = []
        self.trade_history = []
        self.current_position = None
        
        # پارامترهای استراتژی
        # Strategy parameters
        self.rsi_period = 14
        self.macd_fast = 12
        self.macd_slow = 26
        self.macd_signal = 9
        self.ema_short = 9
        self.ema_long = 21
        self.ema_trend = 50
        self.bollinger_period = 20
        self.bollinger_std = 2
        self.atr_period = 14
        self.stochastic_k = 14
        self.stochastic_d = 3
        
    def fetch_data(self, period="1y", interval="1h"):
        """
        دریافت داده‌های قیمت
        Fetch price data
        """
        try:
            ticker = yf.Ticker(self.symbol)
            data = ticker.history(period=period, interval=interval)
            return data
        except Exception as e:
            print(f"خطا در دریافت داده‌ها: {e}")
            return None
    
    def calculate_indicators(self, data):
        """
        محاسبه اندیکاتورهای تکنیکال پیشرفته
        Calculate advanced technical indicators
        """
        df = data.copy()
        
        # RSI
        df['RSI'] = talib.RSI(df['Close'], timeperiod=self.rsi_period)
        
        # MACD
        df['MACD'], df['MACD_Signal'], df['MACD_Hist'] = talib.MACD(
            df['Close'], fastperiod=self.macd_fast, slowperiod=self.macd_slow, signalperiod=self.macd_signal
        )
        
        # EMA ها
        df['EMA_Short'] = talib.EMA(df['Close'], timeperiod=self.ema_short)
        df['EMA_Long'] = talib.EMA(df['Close'], timeperiod=self.ema_long)
        df['EMA_Trend'] = talib.EMA(df['Close'], timeperiod=self.ema_trend)
        
        # Bollinger Bands
        df['BB_Upper'], df['BB_Middle'], df['BB_Lower'] = talib.BBANDS(
            df['Close'], timeperiod=self.bollinger_period, nbdevup=self.bollinger_std, nbdevdn=self.bollinger_std
        )
        
        # ATR برای مدیریت ریسک
        df['ATR'] = talib.ATR(df['High'], df['Low'], df['Close'], timeperiod=self.atr_period)
        
        # Stochastic
        df['Stoch_K'], df['Stoch_D'] = talib.STOCH(
            df['High'], df['Low'], df['Close'], fastk_period=self.stochastic_k, slowk_period=3, slowd_period=self.stochastic_d
        )
        
        # Williams %R
        df['Williams_R'] = talib.WILLR(df['High'], df['Low'], df['Close'], timeperiod=14)
        
        # CCI (Commodity Channel Index)
        df['CCI'] = talib.CCI(df['High'], df['Low'], df['Close'], timeperiod=14)
        
        # ADX برای تشخیص روند
        df['ADX'] = talib.ADX(df['High'], df['Low'], df['Close'], timeperiod=14)
        
        # Parabolic SAR
        df['SAR'] = talib.SAR(df['High'], df['Low'], acceleration=0.02, maximum=0.2)
        
        return df
    
    def generate_signals(self, df):
        """
        تولید سیگنال‌های معاملاتی پیشرفته
        Generate advanced trading signals
        """
        signals = pd.DataFrame(index=df.index)
        signals['Signal'] = 0  # 0: Hold, 1: Buy, -1: Sell
        
        # استراتژی ترکیبی پیشرفته
        # Advanced combined strategy
        
        # 1. روند کلی (Trend Analysis)
        trend_bullish = (df['EMA_Short'] > df['EMA_Long']) & (df['EMA_Long'] > df['EMA_Trend'])
        trend_bearish = (df['EMA_Short'] < df['EMA_Long']) & (df['EMA_Long'] < df['EMA_Trend'])
        
        # 2. RSI شرایط
        rsi_oversold = df['RSI'] < 30
        rsi_overbought = df['RSI'] > 70
        rsi_neutral = (df['RSI'] >= 40) & (df['RSI'] <= 60)
        
        # 3. MACD سیگنال
        macd_bullish = (df['MACD'] > df['MACD_Signal']) & (df['MACD_Hist'] > 0)
        macd_bearish = (df['MACD'] < df['MACD_Signal']) & (df['MACD_Hist'] < 0)
        
        # 4. Bollinger Bands
        bb_lower_touch = df['Close'] <= df['BB_Lower'] * 1.01
        bb_upper_touch = df['Close'] >= df['BB_Upper'] * 0.99
        
        # 5. Stochastic
        stoch_oversold = (df['Stoch_K'] < 20) & (df['Stoch_D'] < 20)
        stoch_overbought = (df['Stoch_K'] > 80) & (df['Stoch_D'] > 80)
        
        # 6. Williams %R
        williams_oversold = df['Williams_R'] < -80
        williams_overbought = df['Williams_R'] > -20
        
        # 7. ADX برای قدرت روند
        strong_trend = df['ADX'] > 25
        
        # سیگنال‌های خرید (Buy Signals)
        buy_conditions = (
            trend_bullish &  # روند صعودی
            (rsi_oversold | rsi_neutral) &  # RSI مناسب
            macd_bullish &  # MACD مثبت
            (bb_lower_touch | stoch_oversold | williams_oversold) &  # یکی از اندیکاتورهای اشباع فروش
            strong_trend  # روند قوی
        )
        
        # سیگنال‌های فروش (Sell Signals)
        sell_conditions = (
            trend_bearish &  # روند نزولی
            (rsi_overbought | rsi_neutral) &  # RSI مناسب
            macd_bearish &  # MACD منفی
            (bb_upper_touch | stoch_overbought | williams_overbought) &  # یکی از اندیکاتورهای اشباع خرید
            strong_trend  # روند قوی
        )
        
        signals.loc[buy_conditions, 'Signal'] = 1
        signals.loc[sell_conditions, 'Signal'] = -1
        
        return signals
    
    def calculate_position_size(self, entry_price, stop_loss, df):
        """
        محاسبه اندازه پوزیشن بر اساس مدیریت ریسک
        Calculate position size based on risk management
        """
        risk_amount = self.balance * (self.risk_percent / 100)
        atr = df['ATR'].iloc[-1]
        
        # استفاده از ATR برای تعیین حد ضرر
        if stop_loss is None:
            stop_loss = entry_price - (2 * atr)  # برای خرید
        
        risk_per_share = abs(entry_price - stop_loss)
        position_size = risk_amount / risk_per_share
        
        # محدود کردن اندازه پوزیشن
        max_position_value = self.balance * 0.1  # حداکثر 10% موجودی
        max_shares = max_position_value / entry_price
        
        return min(position_size, max_shares)
    
    def execute_trade(self, signal, price, df, timestamp):
        """
        اجرای معامله
        Execute trade
        """
        if signal == 1 and self.current_position is None:  # خرید
            position_size = self.calculate_position_size(price, None, df)
            cost = position_size * price
            
            if cost <= self.balance:
                self.current_position = {
                    'type': 'BUY',
                    'entry_price': price,
                    'size': position_size,
                    'entry_time': timestamp,
                    'stop_loss': price - (2 * df['ATR'].iloc[-1]),
                    'take_profit': price + (3 * df['ATR'].iloc[-1])
                }
                self.balance -= cost
                print(f"🟢 خرید: {position_size:.2f} واحد در قیمت {price:.5f}")
                
        elif signal == -1 and self.current_position is not None:  # فروش
            if self.current_position['type'] == 'BUY':
                revenue = self.current_position['size'] * price
                profit = revenue - (self.current_position['size'] * self.current_position['entry_price'])
                self.balance += revenue
                
                trade_record = {
                    'entry_time': self.current_position['entry_time'],
                    'exit_time': timestamp,
                    'entry_price': self.current_position['entry_price'],
                    'exit_price': price,
                    'size': self.current_position['size'],
                    'profit': profit,
                    'profit_percent': (profit / (self.current_position['size'] * self.current_position['entry_price'])) * 100
                }
                self.trade_history.append(trade_record)
                
                print(f"🔴 فروش: {self.current_position['size']:.2f} واحد در قیمت {price:.5f}")
                print(f"💰 سود/زیان: {profit:.2f} ({trade_record['profit_percent']:.2f}%)")
                
                self.current_position = None
    
    def check_stop_loss_take_profit(self, current_price, timestamp):
        """
        بررسی حد ضرر و حد سود
        Check stop loss and take profit
        """
        if self.current_position is None:
            return
        
        # بررسی حد ضرر
        if current_price <= self.current_position['stop_loss']:
            revenue = self.current_position['size'] * self.current_position['stop_loss']
            loss = revenue - (self.current_position['size'] * self.current_position['entry_price'])
            self.balance += revenue
            
            trade_record = {
                'entry_time': self.current_position['entry_time'],
                'exit_time': timestamp,
                'entry_price': self.current_position['entry_price'],
                'exit_price': self.current_position['stop_loss'],
                'size': self.current_position['size'],
                'profit': loss,
                'profit_percent': (loss / (self.current_position['size'] * self.current_position['entry_price'])) * 100,
                'exit_reason': 'Stop Loss'
            }
            self.trade_history.append(trade_record)
            
            print(f"🛑 حد ضرر: {self.current_position['size']:.2f} واحد در قیمت {self.current_position['stop_loss']:.5f}")
            print(f"💸 زیان: {loss:.2f} ({trade_record['profit_percent']:.2f}%)")
            
            self.current_position = None
            
        # بررسی حد سود
        elif current_price >= self.current_position['take_profit']:
            revenue = self.current_position['size'] * self.current_position['take_profit']
            profit = revenue - (self.current_position['size'] * self.current_position['entry_price'])
            self.balance += revenue
            
            trade_record = {
                'entry_time': self.current_position['entry_time'],
                'exit_time': timestamp,
                'entry_price': self.current_position['entry_price'],
                'exit_price': self.current_position['take_profit'],
                'size': self.current_position['size'],
                'profit': profit,
                'profit_percent': (profit / (self.current_position['size'] * self.current_position['entry_price'])) * 100,
                'exit_reason': 'Take Profit'
            }
            self.trade_history.append(trade_record)
            
            print(f"🎯 حد سود: {self.current_position['size']:.2f} واحد در قیمت {self.current_position['take_profit']:.5f}")
            print(f"💰 سود: {profit:.2f} ({trade_record['profit_percent']:.2f}%)")
            
            self.current_position = None
    
    def run_backtest(self, period="6mo", interval="1h"):
        """
        اجرای بک تست
        Run backtest
        """
        print("🔄 شروع بک تست...")
        print(f"📊 جفت ارز: {self.symbol}")
        print(f"💰 موجودی اولیه: ${self.initial_balance:,.2f}")
        print(f"⚠️ درصد ریسک: {self.risk_percent}%")
        print("-" * 50)
        
        # دریافت داده‌ها
        data = self.fetch_data(period, interval)
        if data is None:
            print("❌ خطا در دریافت داده‌ها")
            return
        
        # محاسبه اندیکاتورها
        df = self.calculate_indicators(data)
        
        # تولید سیگنال‌ها
        signals = self.generate_signals(df)
        
        # اجرای معاملات
        for i in range(len(df)):
            current_price = df['Close'].iloc[i]
            current_signal = signals['Signal'].iloc[i]
            timestamp = df.index[i]
            
            # بررسی حد ضرر و حد سود
            self.check_stop_loss_take_profit(current_price, timestamp)
            
            # اجرای معامله جدید
            if current_signal != 0:
                self.execute_trade(current_signal, current_price, df.iloc[:i+1], timestamp)
        
        # بستن پوزیشن باز در پایان
        if self.current_position is not None:
            final_price = df['Close'].iloc[-1]
            revenue = self.current_position['size'] * final_price
            profit = revenue - (self.current_position['size'] * self.current_position['entry_price'])
            self.balance += revenue
            
            trade_record = {
                'entry_time': self.current_position['entry_time'],
                'exit_time': df.index[-1],
                'entry_price': self.current_position['entry_price'],
                'exit_price': final_price,
                'size': self.current_position['size'],
                'profit': profit,
                'profit_percent': (profit / (self.current_position['size'] * self.current_position['entry_price'])) * 100,
                'exit_reason': 'End of Period'
            }
            self.trade_history.append(trade_record)
            
            self.current_position = None
        
        # نمایش نتایج
        self.show_results()
    
    def show_results(self):
        """
        نمایش نتایج معاملات
        Show trading results
        """
        print("\n" + "="*60)
        print("📈 نتایج بک تست")
        print("="*60)
        
        total_trades = len(self.trade_history)
        profitable_trades = len([t for t in self.trade_history if t['profit'] > 0])
        losing_trades = len([t for t in self.trade_history if t['profit'] < 0])
        
        win_rate = (profitable_trades / total_trades * 100) if total_trades > 0 else 0
        
        total_profit = sum([t['profit'] for t in self.trade_history])
        total_profit_percent = ((self.balance - self.initial_balance) / self.initial_balance) * 100
        
        avg_profit = np.mean([t['profit'] for t in self.trade_history]) if self.trade_history else 0
        max_profit = max([t['profit'] for t in self.trade_history]) if self.trade_history else 0
        max_loss = min([t['profit'] for t in self.trade_history]) if self.trade_history else 0
        
        print(f"💰 موجودی نهایی: ${self.balance:,.2f}")
        print(f"📊 سود/زیان کل: ${total_profit:,.2f} ({total_profit_percent:.2f}%)")
        print(f"🔄 تعداد معاملات: {total_trades}")
        print(f"✅ معاملات سودده: {profitable_trades}")
        print(f"❌ معاملات زیانده: {losing_trades}")
        print(f"📈 درصد موفقیت: {win_rate:.2f}%")
        print(f"📊 میانگین سود/زیان: ${avg_profit:.2f}")
        print(f"🚀 بیشترین سود: ${max_profit:.2f}")
        print(f"📉 بیشترین زیان: ${max_loss:.2f}")
        
        if self.trade_history:
            print("\n📋 جزئیات معاملات:")
            print("-" * 80)
            for i, trade in enumerate(self.trade_history, 1):
                print(f"{i:2d}. {trade['entry_time'].strftime('%Y-%m-%d %H:%M')} | "
                      f"ورود: {trade['entry_price']:.5f} | خروج: {trade['exit_price']:.5f} | "
                      f"سود/زیان: ${trade['profit']:.2f} ({trade['profit_percent']:.2f}%)")
    
    def plot_results(self, data):
        """
        رسم نمودار نتایج
        Plot trading results
        """
        df = self.calculate_indicators(data)
        signals = self.generate_signals(df)
        
        fig, axes = plt.subplots(3, 1, figsize=(15, 12))
        
        # نمودار قیمت و سیگنال‌ها
        axes[0].plot(df.index, df['Close'], label='قیمت', alpha=0.7)
        axes[0].plot(df.index, df['EMA_Short'], label=f'EMA {self.ema_short}', alpha=0.8)
        axes[0].plot(df.index, df['EMA_Long'], label=f'EMA {self.ema_long}', alpha=0.8)
        axes[0].plot(df.index, df['BB_Upper'], label='Bollinger Upper', alpha=0.6, linestyle='--')
        axes[0].plot(df.index, df['BB_Lower'], label='Bollinger Lower', alpha=0.6, linestyle='--')
        
        # نمایش سیگنال‌های خرید و فروش
        buy_signals = signals[signals['Signal'] == 1]
        sell_signals = signals[signals['Signal'] == -1]
        
        axes[0].scatter(buy_signals.index, df.loc[buy_signals.index, 'Close'], 
                       color='green', marker='^', s=100, label='سیگنال خرید')
        axes[0].scatter(sell_signals.index, df.loc[sell_signals.index, 'Close'], 
                       color='red', marker='v', s=100, label='سیگنال فروش')
        
        axes[0].set_title('نمودار قیمت و سیگنال‌های معاملاتی')
        axes[0].legend()
        axes[0].grid(True, alpha=0.3)
        
        # نمودار RSI
        axes[1].plot(df.index, df['RSI'], label='RSI', color='purple')
        axes[1].axhline(y=70, color='r', linestyle='--', alpha=0.7, label='اشباع خرید')
        axes[1].axhline(y=30, color='g', linestyle='--', alpha=0.7, label='اشباع فروش')
        axes[1].set_title('RSI')
        axes[1].legend()
        axes[1].grid(True, alpha=0.3)
        
        # نمودار MACD
        axes[2].plot(df.index, df['MACD'], label='MACD', color='blue')
        axes[2].plot(df.index, df['MACD_Signal'], label='Signal', color='red')
        axes[2].bar(df.index, df['MACD_Hist'], label='Histogram', alpha=0.3, color='gray')
        axes[2].set_title('MACD')
        axes[2].legend()
        axes[2].grid(True, alpha=0.3)
        
        plt.tight_layout()
        plt.savefig('forex_trading_results.png', dpi=300, bbox_inches='tight')
        plt.show()

def main():
    """
    تابع اصلی
    Main function
    """
    print("🚀 سیستم معاملات فارکس با دقت بالا")
    print("=" * 50)
    
    # ایجاد نمونه از سیستم معاملات
    trader = AdvancedForexTrader(
        symbol="EURUSD=X",  # جفت ارز یورو/دلار
        initial_balance=10000,  # موجودی اولیه 10,000 دلار
        risk_percent=2  # ریسک 2% در هر معامله
    )
    
    # اجرای بک تست
    trader.run_backtest(period="6mo", interval="1h")
    
    # دریافت داده‌ها برای رسم نمودار
    data = trader.fetch_data("6mo", "1h")
    if data is not None:
        trader.plot_results(data)

if __name__ == "__main__":
    main()