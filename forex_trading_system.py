#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
سیستم معاملاتی فارکس با دقت بالا
Forex Trading System with High Precision
"""

import numpy as np
import pandas as pd
import talib
import yfinance as yf
from datetime import datetime, timedelta
import logging
import json
from typing import Dict, List, Tuple, Optional
import warnings
warnings.filterwarnings('ignore')

# تنظیمات لاگینگ
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class AdvancedForexTrader:
    """
    سیستم معاملاتی پیشرفته فارکس با استراتژی‌های چندگانه
    """
    
    def __init__(self, initial_balance: float = 10000, risk_per_trade: float = 0.02):
        self.initial_balance = initial_balance
        self.balance = initial_balance
        self.risk_per_trade = risk_per_trade
        self.positions = []
        self.trade_history = []
        self.current_position = None
        
        # پارامترهای استراتژی
        self.strategy_params = {
            'rsi_period': 14,
            'rsi_overbought': 70,
            'rsi_oversold': 30,
            'ema_short': 9,
            'ema_long': 21,
            'macd_fast': 12,
            'macd_slow': 26,
            'macd_signal': 9,
            'bollinger_period': 20,
            'bollinger_std': 2,
            'atr_period': 14,
            'stoch_k': 14,
            'stoch_d': 3,
            'volume_sma': 20
        }
    
    def fetch_market_data(self, symbol: str, period: str = "1y", interval: str = "1h") -> pd.DataFrame:
        """
        دریافت داده‌های بازار از Yahoo Finance
        """
        try:
            ticker = yf.Ticker(symbol)
            data = ticker.history(period=period, interval=interval)
            
            if data.empty:
                raise ValueError(f"داده‌ای برای {symbol} یافت نشد")
            
            # محاسبه شاخص‌های تکنیکال
            data = self.calculate_technical_indicators(data)
            return data
            
        except Exception as e:
            logger.error(f"خطا در دریافت داده‌های {symbol}: {e}")
            return pd.DataFrame()
    
    def calculate_technical_indicators(self, data: pd.DataFrame) -> pd.DataFrame:
        """
        محاسبه شاخص‌های تکنیکال پیشرفته
        """
        try:
            # RSI
            data['RSI'] = talib.RSI(data['Close'], timeperiod=self.strategy_params['rsi_period'])
            
            # EMA
            data['EMA_short'] = talib.EMA(data['Close'], timeperiod=self.strategy_params['ema_short'])
            data['EMA_long'] = talib.EMA(data['Close'], timeperiod=self.strategy_params['ema_long'])
            
            # MACD
            macd, macd_signal, macd_hist = talib.MACD(
                data['Close'], 
                fastperiod=self.strategy_params['macd_fast'],
                slowperiod=self.strategy_params['macd_slow'],
                signalperiod=self.strategy_params['macd_signal']
            )
            data['MACD'] = macd
            data['MACD_signal'] = macd_signal
            data['MACD_histogram'] = macd_hist
            
            # Bollinger Bands
            bb_upper, bb_middle, bb_lower = talib.BBANDS(
                data['Close'],
                timeperiod=self.strategy_params['bollinger_period'],
                nbdevup=self.strategy_params['bollinger_std'],
                nbdevdn=self.strategy_params['bollinger_std']
            )
            data['BB_upper'] = bb_upper
            data['BB_middle'] = bb_middle
            data['BB_lower'] = bb_lower
            
            # ATR (Average True Range)
            data['ATR'] = talib.ATR(
                data['High'], 
                data['Low'], 
                data['Close'], 
                timeperiod=self.strategy_params['atr_period']
            )
            
            # Stochastic Oscillator
            stoch_k, stoch_d = talib.STOCH(
                data['High'], 
                data['Low'], 
                data['Close'],
                fastk_period=self.strategy_params['stoch_k'],
                slowk_period=3,
                slowd_period=self.strategy_params['stoch_d']
            )
            data['Stoch_K'] = stoch_k
            data['Stoch_D'] = stoch_d
            
            # Volume SMA
            data['Volume_SMA'] = talib.SMA(data['Volume'], timeperiod=self.strategy_params['volume_sma'])
            
            # Price Action Patterns
            data['Doji'] = talib.CDLDOJI(data['Open'], data['High'], data['Low'], data['Close'])
            data['Hammer'] = talib.CDLHAMMER(data['Open'], data['High'], data['Low'], data['Close'])
            data['Engulfing'] = talib.CDLENGULFING(data['Open'], data['High'], data['Low'], data['Close'])
            
            # Support and Resistance Levels
            data['Support'] = self.calculate_support_levels(data)
            data['Resistance'] = self.calculate_resistance_levels(data)
            
            # Trend Strength
            data['ADX'] = talib.ADX(data['High'], data['Low'], data['Close'], timeperiod=14)
            
            return data
            
        except Exception as e:
            logger.error(f"خطا در محاسبه شاخص‌های تکنیکال: {e}")
            return data
    
    def calculate_support_levels(self, data: pd.DataFrame) -> pd.Series:
        """
        محاسبه سطوح حمایت
        """
        support_levels = []
        for i in range(len(data)):
            if i < 2 or i >= len(data) - 2:
                support_levels.append(np.nan)
            else:
                # تشخیص الگوی حمایت
                if (data['Low'].iloc[i] < data['Low'].iloc[i-1] and 
                    data['Low'].iloc[i] < data['Low'].iloc[i-2] and
                    data['Low'].iloc[i] < data['Low'].iloc[i+1] and
                    data['Low'].iloc[i] < data['Low'].iloc[i+2]):
                    support_levels.append(data['Low'].iloc[i])
                else:
                    support_levels.append(np.nan)
        return pd.Series(support_levels, index=data.index)
    
    def calculate_resistance_levels(self, data: pd.DataFrame) -> pd.Series:
        """
        محاسبه سطوح مقاومت
        """
        resistance_levels = []
        for i in range(len(data)):
            if i < 2 or i >= len(data) - 2:
                resistance_levels.append(np.nan)
            else:
                # تشخیص الگوی مقاومت
                if (data['High'].iloc[i] > data['High'].iloc[i-1] and 
                    data['High'].iloc[i] > data['High'].iloc[i-2] and
                    data['High'].iloc[i] > data['High'].iloc[i+1] and
                    data['High'].iloc[i] > data['High'].iloc[i+2]):
                    resistance_levels.append(data['High'].iloc[i])
                else:
                    resistance_levels.append(np.nan)
        return pd.Series(resistance_levels, index=data.index)
    
    def advanced_signal_generator(self, data: pd.DataFrame) -> Dict[str, float]:
        """
        تولید سیگنال‌های معاملاتی پیشرفته با ترکیب چندین استراتژی
        """
        if len(data) < 50:
            return {'signal': 0, 'confidence': 0, 'reason': 'داده‌های ناکافی'}
        
        current = data.iloc[-1]
        prev = data.iloc[-2]
        
        # امتیازدهی به سیگنال‌ها
        signal_score = 0
        reasons = []
        
        # 1. استراتژی RSI + Stochastic
        if (current['RSI'] < self.strategy_params['rsi_oversold'] and 
            current['Stoch_K'] < 20 and current['Stoch_D'] < 20):
            signal_score += 2
            reasons.append("RSI و Stochastic در منطقه اشباع فروش")
        elif (current['RSI'] > self.strategy_params['rsi_overbought'] and 
              current['Stoch_K'] > 80 and current['Stoch_D'] > 80):
            signal_score -= 2
            reasons.append("RSI و Stochastic در منطقه اشباع خرید")
        
        # 2. استراتژی EMA Crossover
        if (current['EMA_short'] > current['EMA_long'] and 
            prev['EMA_short'] <= prev['EMA_long']):
            signal_score += 1.5
            reasons.append("کراس اور EMA صعودی")
        elif (current['EMA_short'] < current['EMA_long'] and 
              prev['EMA_short'] >= prev['EMA_long']):
            signal_score -= 1.5
            reasons.append("کراس اور EMA نزولی")
        
        # 3. استراتژی MACD
        if (current['MACD'] > current['MACD_signal'] and 
            prev['MACD'] <= prev['MACD_signal']):
            signal_score += 1
            reasons.append("کراس اور MACD صعودی")
        elif (current['MACD'] < current['MACD_signal'] and 
              prev['MACD'] >= prev['MACD_signal']):
            signal_score -= 1
            reasons.append("کراس اور MACD نزولی")
        
        # 4. استراتژی Bollinger Bands
        if current['Close'] < current['BB_lower']:
            signal_score += 1.5
            reasons.append("قیمت زیر باند پایین بولینگر")
        elif current['Close'] > current['BB_upper']:
            signal_score -= 1.5
            reasons.append("قیمت بالای باند بالای بولینگر")
        
        # 5. استراتژی Volume
        if current['Volume'] > current['Volume_SMA'] * 1.5:
            signal_score += 0.5
            reasons.append("حجم معاملات بالا")
        
        # 6. استراتژی Price Action
        if current['Hammer'] > 0:
            signal_score += 1
            reasons.append("الگوی چکش")
        elif current['Engulfing'] > 0:
            signal_score += 1.5
            reasons.append("الگوی احاطه‌کننده صعودی")
        elif current['Engulfing'] < 0:
            signal_score -= 1.5
            reasons.append("الگوی احاطه‌کننده نزولی")
        
        # 7. استراتژی Support/Resistance
        if not pd.isna(current['Support']) and abs(current['Close'] - current['Support']) / current['Close'] < 0.01:
            signal_score += 1
            reasons.append("نزدیک به سطح حمایت")
        elif not pd.isna(current['Resistance']) and abs(current['Close'] - current['Resistance']) / current['Close'] < 0.01:
            signal_score -= 1
            reasons.append("نزدیک به سطح مقاومت")
        
        # 8. استراتژی Trend Strength
        if current['ADX'] > 25:
            signal_score += 0.5
            reasons.append("روند قوی")
        
        # تعیین سیگنال نهایی
        if signal_score >= 3:
            signal = 1  # خرید
            confidence = min(abs(signal_score) / 8, 1.0)
        elif signal_score <= -3:
            signal = -1  # فروش
            confidence = min(abs(signal_score) / 8, 1.0)
        else:
            signal = 0  # بی‌طرف
            confidence = 0
        
        return {
            'signal': signal,
            'confidence': confidence,
            'score': signal_score,
            'reasons': reasons,
            'price': current['Close'],
            'timestamp': current.name
        }
    
    def calculate_position_size(self, signal: Dict, stop_loss_pips: float = 50) -> float:
        """
        محاسبه اندازه پوزیشن بر اساس مدیریت ریسک
        """
        if signal['signal'] == 0:
            return 0
        
        risk_amount = self.balance * self.risk_per_trade
        pip_value = 0.0001  # برای جفت ارزهای اصلی
        stop_loss_amount = stop_loss_pips * pip_value
        
        if stop_loss_amount > 0:
            position_size = risk_amount / stop_loss_amount
            return min(position_size, self.balance * 0.1)  # حداکثر 10% موجودی
        return 0
    
    def execute_trade(self, symbol: str, signal: Dict, position_size: float) -> bool:
        """
        اجرای معامله
        """
        try:
            if signal['signal'] == 0 or position_size == 0:
                return False
            
            trade = {
                'symbol': symbol,
                'type': 'BUY' if signal['signal'] == 1 else 'SELL',
                'price': signal['price'],
                'size': position_size,
                'timestamp': signal['timestamp'],
                'confidence': signal['confidence'],
                'reasons': signal['reasons']
            }
            
            # محاسبه هزینه معامله
            commission = position_size * signal['price'] * 0.001  # 0.1% کارمزد
            trade['commission'] = commission
            
            if signal['signal'] == 1:  # خرید
                cost = position_size * signal['price'] + commission
                if cost <= self.balance:
                    self.balance -= cost
                    self.current_position = trade
                    logger.info(f"خرید {position_size} {symbol} در قیمت {signal['price']}")
                    return True
            else:  # فروش
                if self.current_position:
                    # بستن پوزیشن قبلی
                    profit = (signal['price'] - self.current_position['price']) * self.current_position['size']
                    self.balance += self.current_position['size'] * signal['price'] - commission + profit
                    
                    # ثبت معامله
                    closed_trade = self.current_position.copy()
                    closed_trade['exit_price'] = signal['price']
                    closed_trade['exit_time'] = signal['timestamp']
                    closed_trade['profit'] = profit
                    self.trade_history.append(closed_trade)
                    
                    self.current_position = None
                    logger.info(f"فروش {position_size} {symbol} در قیمت {signal['price']}, سود: {profit:.2f}")
                    return True
            
            return False
            
        except Exception as e:
            logger.error(f"خطا در اجرای معامله: {e}")
            return False
    
    def run_strategy(self, symbol: str, period: str = "1y", interval: str = "1h") -> Dict:
        """
        اجرای استراتژی معاملاتی
        """
        try:
            # دریافت داده‌ها
            data = self.fetch_market_data(symbol, period, interval)
            if data.empty:
                return {'success': False, 'error': 'داده‌ای یافت نشد'}
            
            # تولید سیگنال
            signal = self.advanced_signal_generator(data)
            
            # محاسبه اندازه پوزیشن
            position_size = self.calculate_position_size(signal)
            
            # اجرای معامله
            trade_executed = self.execute_trade(symbol, signal, position_size)
            
            return {
                'success': True,
                'signal': signal,
                'position_size': position_size,
                'trade_executed': trade_executed,
                'current_balance': self.balance,
                'data_points': len(data)
            }
            
        except Exception as e:
            logger.error(f"خطا در اجرای استراتژی: {e}")
            return {'success': False, 'error': str(e)}
    
    def get_performance_metrics(self) -> Dict:
        """
        محاسبه معیارهای عملکرد
        """
        if not self.trade_history:
            return {'total_trades': 0, 'win_rate': 0, 'total_profit': 0}
        
        total_trades = len(self.trade_history)
        winning_trades = len([t for t in self.trade_history if t['profit'] > 0])
        total_profit = sum([t['profit'] for t in self.trade_history])
        
        return {
            'total_trades': total_trades,
            'winning_trades': winning_trades,
            'win_rate': winning_trades / total_trades if total_trades > 0 else 0,
            'total_profit': total_profit,
            'average_profit': total_profit / total_trades if total_trades > 0 else 0,
            'current_balance': self.balance,
            'return_percentage': ((self.balance - self.initial_balance) / self.initial_balance) * 100
        }

# مثال استفاده
if __name__ == "__main__":
    # ایجاد نمونه از سیستم معاملاتی
    trader = AdvancedForexTrader(initial_balance=10000, risk_per_trade=0.02)
    
    # اجرای استراتژی روی جفت ارز EUR/USD
    result = trader.run_strategy("EURUSD=X", period="6mo", interval="1h")
    
    if result['success']:
        print("نتایج استراتژی:")
        print(f"سیگنال: {result['signal']['signal']}")
        print(f"اعتماد: {result['signal']['confidence']:.2f}")
        print(f"دلایل: {', '.join(result['signal']['reasons'])}")
        print(f"اندازه پوزیشن: {result['position_size']:.2f}")
        print(f"موجودی فعلی: ${result['current_balance']:.2f}")
        
        # نمایش معیارهای عملکرد
        metrics = trader.get_performance_metrics()
        print(f"\nمعیارهای عملکرد:")
        print(f"تعداد کل معاملات: {metrics['total_trades']}")
        print(f"نرخ موفقیت: {metrics['win_rate']:.2%}")
        print(f"سود کل: ${metrics['total_profit']:.2f}")
        print(f"بازده: {metrics['return_percentage']:.2f}%")
    else:
        print(f"خطا: {result['error']}")