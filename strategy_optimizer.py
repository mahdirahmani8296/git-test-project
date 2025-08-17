#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
بهینه‌ساز استراتژی معاملات فارکس
Forex Trading Strategy Optimizer

این فایل شامل الگوریتم‌های بهینه‌سازی پیشرفته برای یافتن بهترین پارامترها است
This file includes advanced optimization algorithms to find the best parameters
"""

import numpy as np
import pandas as pd
from sklearn.model_selection import TimeSeriesSplit
from sklearn.metrics import sharpe_ratio, max_drawdown
import itertools
from concurrent.futures import ProcessPoolExecutor
import warnings
warnings.filterwarnings('ignore')

class StrategyOptimizer:
    def __init__(self, data, initial_balance=10000):
        """
        مقداردهی اولیه بهینه‌ساز
        Initialize the optimizer
        """
        self.data = data
        self.initial_balance = initial_balance
        self.best_params = None
        self.best_score = -np.inf
        
    def calculate_sharpe_ratio(self, returns, risk_free_rate=0.02):
        """
        محاسبه نسبت شارپ
        Calculate Sharpe ratio
        """
        if len(returns) == 0 or np.std(returns) == 0:
            return 0
        excess_returns = returns - risk_free_rate/252  # روزانه
        return np.mean(excess_returns) / np.std(excess_returns) * np.sqrt(252)
    
    def calculate_max_drawdown(self, equity_curve):
        """
        محاسبه حداکثر افت سرمایه
        Calculate maximum drawdown
        """
        peak = equity_curve.expanding(min_periods=1).max()
        drawdown = (equity_curve - peak) / peak
        return drawdown.min()
    
    def calculate_profit_factor(self, profits, losses):
        """
        محاسبه فاکتور سود
        Calculate profit factor
        """
        if losses == 0:
            return np.inf
        return abs(profits / losses)
    
    def backtest_strategy(self, params):
        """
        بک تست استراتژی با پارامترهای مشخص
        Backtest strategy with specific parameters
        """
        try:
            # استخراج پارامترها
            rsi_period = params['rsi_period']
            macd_fast = params['macd_fast']
            macd_slow = params['macd_slow']
            ema_short = params['ema_short']
            ema_long = params['ema_long']
            risk_percent = params['risk_percent']
            
            # محاسبه اندیکاتورها
            df = self.data.copy()
            
            # RSI
            df['RSI'] = self.calculate_rsi(df['Close'], rsi_period)
            
            # MACD
            df['MACD'], df['MACD_Signal'], _ = self.calculate_macd(
                df['Close'], macd_fast, macd_slow, 9
            )
            
            # EMA
            df['EMA_Short'] = self.calculate_ema(df['Close'], ema_short)
            df['EMA_Long'] = self.calculate_ema(df['Close'], ema_long)
            
            # ATR
            df['ATR'] = self.calculate_atr(df['High'], df['Low'], df['Close'], 14)
            
            # تولید سیگنال‌ها
            signals = self.generate_signals_optimized(df, params)
            
            # اجرای معاملات
            balance = self.initial_balance
            position = None
            trades = []
            equity_curve = [balance]
            
            for i in range(len(df)):
                current_price = df['Close'].iloc[i]
                current_signal = signals.iloc[i]
                
                # بررسی حد ضرر و حد سود
                if position is not None:
                    if current_price <= position['stop_loss'] or current_price >= position['take_profit']:
                        # بستن پوزیشن
                        exit_price = position['stop_loss'] if current_price <= position['stop_loss'] else position['take_profit']
                        profit = (exit_price - position['entry_price']) * position['size']
                        balance += profit
                        
                        trades.append({
                            'entry_price': position['entry_price'],
                            'exit_price': exit_price,
                            'profit': profit,
                            'size': position['size']
                        })
                        
                        position = None
                
                # اجرای سیگنال جدید
                if current_signal == 1 and position is None:  # خرید
                    atr = df['ATR'].iloc[i]
                    stop_loss = current_price - (2 * atr)
                    take_profit = current_price + (3 * atr)
                    
                    risk_amount = balance * (risk_percent / 100)
                    position_size = risk_amount / (current_price - stop_loss)
                    
                    position = {
                        'entry_price': current_price,
                        'stop_loss': stop_loss,
                        'take_profit': take_profit,
                        'size': position_size
                    }
                
                equity_curve.append(balance)
            
            # محاسبه معیارهای عملکرد
            returns = pd.Series(equity_curve).pct_change().dropna()
            sharpe = self.calculate_sharpe_ratio(returns)
            max_dd = self.calculate_max_drawdown(pd.Series(equity_curve))
            
            total_trades = len(trades)
            if total_trades > 0:
                profits = sum([t['profit'] for t in trades if t['profit'] > 0])
                losses = abs(sum([t['profit'] for t in trades if t['profit'] < 0]))
                profit_factor = self.calculate_profit_factor(profits, losses)
                win_rate = len([t for t in trades if t['profit'] > 0]) / total_trades
            else:
                profit_factor = 0
                win_rate = 0
            
            # امتیاز ترکیبی
            score = (sharpe * 0.4 + 
                    (1 + max_dd) * 0.2 + 
                    profit_factor * 0.2 + 
                    win_rate * 0.2)
            
            return {
                'score': score,
                'sharpe': sharpe,
                'max_drawdown': max_dd,
                'profit_factor': profit_factor,
                'win_rate': win_rate,
                'total_trades': total_trades,
                'final_balance': balance
            }
            
        except Exception as e:
            return {
                'score': -np.inf,
                'sharpe': 0,
                'max_drawdown': 0,
                'profit_factor': 0,
                'win_rate': 0,
                'total_trades': 0,
                'final_balance': self.initial_balance
            }
    
    def calculate_rsi(self, prices, period=14):
        """محاسبه RSI"""
        delta = prices.diff()
        gain = (delta.where(delta > 0, 0)).rolling(window=period).mean()
        loss = (-delta.where(delta < 0, 0)).rolling(window=period).mean()
        rs = gain / loss
        rsi = 100 - (100 / (1 + rs))
        return rsi
    
    def calculate_macd(self, prices, fast=12, slow=26, signal=9):
        """محاسبه MACD"""
        ema_fast = self.calculate_ema(prices, fast)
        ema_slow = self.calculate_ema(prices, slow)
        macd = ema_fast - ema_slow
        signal_line = self.calculate_ema(macd, signal)
        histogram = macd - signal_line
        return macd, signal_line, histogram
    
    def calculate_ema(self, prices, period):
        """محاسبه EMA"""
        return prices.ewm(span=period).mean()
    
    def calculate_atr(self, high, low, close, period=14):
        """محاسبه ATR"""
        tr1 = high - low
        tr2 = abs(high - close.shift())
        tr3 = abs(low - close.shift())
        tr = pd.concat([tr1, tr2, tr3], axis=1).max(axis=1)
        return tr.rolling(window=period).mean()
    
    def generate_signals_optimized(self, df, params):
        """تولید سیگنال‌های بهینه‌سازی شده"""
        signals = pd.Series(0, index=df.index)
        
        # شرایط خرید
        buy_conditions = (
            (df['EMA_Short'] > df['EMA_Long']) &
            (df['RSI'] < params.get('rsi_oversold', 30)) &
            (df['MACD'] > df['MACD_Signal'])
        )
        
        # شرایط فروش
        sell_conditions = (
            (df['EMA_Short'] < df['EMA_Long']) &
            (df['RSI'] > params.get('rsi_overbought', 70)) &
            (df['MACD'] < df['MACD_Signal'])
        )
        
        signals[buy_conditions] = 1
        signals[sell_conditions] = -1
        
        return signals
    
    def grid_search_optimization(self, param_ranges, max_workers=4):
        """
        بهینه‌سازی با جستجوی شبکه‌ای
        Grid search optimization
        """
        print("🔍 شروع بهینه‌سازی با جستجوی شبکه‌ای...")
        
        # تولید تمام ترکیبات پارامترها
        param_combinations = [dict(zip(param_ranges.keys(), v)) 
                            for v in itertools.product(*param_ranges.values())]
        
        print(f"📊 تعداد ترکیبات: {len(param_combinations)}")
        
        best_result = None
        best_score = -np.inf
        
        # اجرای موازی
        with ProcessPoolExecutor(max_workers=max_workers) as executor:
            results = list(executor.map(self.backtest_strategy, param_combinations))
        
        # یافتن بهترین نتیجه
        for i, result in enumerate(results):
            if result['score'] > best_score:
                best_score = result['score']
                best_result = result
                self.best_params = param_combinations[i]
        
        return best_result, self.best_params
    
    def genetic_algorithm_optimization(self, param_ranges, population_size=50, generations=20):
        """
        بهینه‌سازی با الگوریتم ژنتیک
        Genetic algorithm optimization
        """
        print("🧬 شروع بهینه‌سازی با الگوریتم ژنتیک...")
        
        # تولید جمعیت اولیه
        population = self.generate_initial_population(param_ranges, population_size)
        
        best_score = -np.inf
        best_params = None
        
        for generation in range(generations):
            print(f"🔄 نسل {generation + 1}/{generations}")
            
            # ارزیابی جمعیت
            scores = []
            for params in population:
                result = self.backtest_strategy(params)
                scores.append(result['score'])
            
            # یافتن بهترین
            best_idx = np.argmax(scores)
            if scores[best_idx] > best_score:
                best_score = scores[best_idx]
                best_params = population[best_idx]
                self.best_params = best_params
            
            # انتخاب والدین
            parents = self.select_parents(population, scores)
            
            # تولید نسل جدید
            new_population = []
            for _ in range(population_size):
                parent1, parent2 = np.random.choice(parents, 2, replace=False)
                child = self.crossover(parent1, parent2)
                child = self.mutate(child, param_ranges)
                new_population.append(child)
            
            population = new_population
            
            print(f"📈 بهترین امتیاز: {best_score:.4f}")
        
        return {'score': best_score}, best_params
    
    def generate_initial_population(self, param_ranges, size):
        """تولید جمعیت اولیه"""
        population = []
        for _ in range(size):
            params = {}
            for param, (min_val, max_val) in param_ranges.items():
                if isinstance(min_val, int):
                    params[param] = np.random.randint(min_val, max_val + 1)
                else:
                    params[param] = np.random.uniform(min_val, max_val)
            population.append(params)
        return population
    
    def select_parents(self, population, scores):
        """انتخاب والدین با روش tournament"""
        tournament_size = 3
        parents = []
        
        for _ in range(len(population)):
            tournament_idx = np.random.choice(len(population), tournament_size, replace=False)
            tournament_scores = [scores[i] for i in tournament_idx]
            winner_idx = tournament_idx[np.argmax(tournament_scores)]
            parents.append(population[winner_idx])
        
        return parents
    
    def crossover(self, parent1, parent2):
        """ترکیب والدین"""
        child = {}
        for param in parent1.keys():
            if np.random.random() < 0.5:
                child[param] = parent1[param]
            else:
                child[param] = parent2[param]
        return child
    
    def mutate(self, params, param_ranges, mutation_rate=0.1):
        """جهش پارامترها"""
        for param, (min_val, max_val) in param_ranges.items():
            if np.random.random() < mutation_rate:
                if isinstance(min_val, int):
                    params[param] = np.random.randint(min_val, max_val + 1)
                else:
                    params[param] = np.random.uniform(min_val, max_val)
        return params
    
    def optimize_strategy(self, optimization_method='genetic'):
        """
        بهینه‌سازی استراتژی
        Optimize strategy
        """
        # تعریف محدوده پارامترها
        param_ranges = {
            'rsi_period': (10, 20),
            'macd_fast': (8, 16),
            'macd_slow': (20, 30),
            'ema_short': (5, 15),
            'ema_long': (15, 30),
            'risk_percent': (1.0, 5.0),
            'rsi_oversold': (20, 35),
            'rsi_overbought': (65, 80)
        }
        
        if optimization_method == 'grid':
            best_result, best_params = self.grid_search_optimization(param_ranges)
        elif optimization_method == 'genetic':
            best_result, best_params = self.genetic_algorithm_optimization(param_ranges)
        else:
            raise ValueError("روش بهینه‌سازی نامعتبر")
        
        print("\n" + "="*60)
        print("🎯 نتایج بهینه‌سازی")
        print("="*60)
        print(f"📊 بهترین امتیاز: {best_result['score']:.4f}")
        print(f"📈 نسبت شارپ: {best_result['sharpe']:.4f}")
        print(f"📉 حداکثر افت: {best_result['max_drawdown']:.4f}")
        print(f"💰 فاکتور سود: {best_result['profit_factor']:.4f}")
        print(f"✅ درصد موفقیت: {best_result['win_rate']:.2%}")
        print(f"🔄 تعداد معاملات: {best_result['total_trades']}")
        print(f"💵 موجودی نهایی: ${best_result['final_balance']:,.2f}")
        
        print("\n🔧 بهترین پارامترها:")
        for param, value in best_params.items():
            print(f"   {param}: {value}")
        
        return best_result, best_params

def main():
    """تابع اصلی"""
    print("🚀 بهینه‌ساز استراتژی معاملات فارکس")
    print("=" * 50)
    
    # دریافت داده‌ها (مثال)
    from forex_trading_system import AdvancedForexTrader
    
    trader = AdvancedForexTrader()
    data = trader.fetch_data("1y", "1h")
    
    if data is not None:
        optimizer = StrategyOptimizer(data)
        
        # اجرای بهینه‌سازی
        best_result, best_params = optimizer.optimize_strategy('genetic')
        
        print("\n✅ بهینه‌سازی تکمیل شد!")
    else:
        print("❌ خطا در دریافت داده‌ها")

if __name__ == "__main__":
    main()