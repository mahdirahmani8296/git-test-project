#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
موتور بک‌تستینگ برای استراتژی فارکس
Backtesting Engine for Forex Strategy
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime, timedelta
import yfinance as yf
from forex_trading_system import AdvancedForexTrader
import warnings
warnings.filterwarnings('ignore')

class BacktestingEngine:
    """
    موتور بک‌تستینگ پیشرفته برای تست استراتژی‌های فارکس
    """
    
    def __init__(self, initial_balance: float = 10000):
        self.initial_balance = initial_balance
        self.results = []
        self.equity_curve = []
        
    def run_backtest(self, symbol: str, start_date: str, end_date: str, 
                    interval: str = "1h", strategy_params: dict = None) -> dict:
        """
        اجرای بک‌تست کامل
        """
        try:
            # دریافت داده‌های تاریخی
            data = self.fetch_historical_data(symbol, start_date, end_date, interval)
            if data.empty:
                return {'success': False, 'error': 'داده‌ای یافت نشد'}
            
            # ایجاد نمونه از سیستم معاملاتی
            trader = AdvancedForexTrader(initial_balance=self.initial_balance)
            
            # اعمال پارامترهای سفارشی استراتژی
            if strategy_params:
                trader.strategy_params.update(strategy_params)
            
            # اجرای استراتژی روی داده‌های تاریخی
            results = self.simulate_trading(data, trader)
            
            # محاسبه معیارهای عملکرد
            performance_metrics = self.calculate_performance_metrics(results, data)
            
            return {
                'success': True,
                'data': data,
                'results': results,
                'performance': performance_metrics,
                'trader': trader
            }
            
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    def fetch_historical_data(self, symbol: str, start_date: str, end_date: str, 
                            interval: str = "1h") -> pd.DataFrame:
        """
        دریافت داده‌های تاریخی
        """
        try:
            ticker = yf.Ticker(symbol)
            data = ticker.history(start=start_date, end=end_date, interval=interval)
            
            if data.empty:
                raise ValueError(f"داده‌ای برای {symbol} در بازه زمانی مشخص شده یافت نشد")
            
            return data
            
        except Exception as e:
            print(f"خطا در دریافت داده‌های تاریخی: {e}")
            return pd.DataFrame()
    
    def simulate_trading(self, data: pd.DataFrame, trader: AdvancedForexTrader) -> list:
        """
        شبیه‌سازی معاملات روی داده‌های تاریخی
        """
        results = []
        equity = self.initial_balance
        
        for i in range(50, len(data)):  # شروع از 50 برای داشتن داده‌های کافی
            # انتخاب داده‌های تا نقطه فعلی
            current_data = data.iloc[:i+1].copy()
            
            # محاسبه شاخص‌های تکنیکال
            current_data = trader.calculate_technical_indicators(current_data)
            
            # تولید سیگنال
            signal = trader.advanced_signal_generator(current_data)
            
            # محاسبه اندازه پوزیشن
            position_size = trader.calculate_position_size(signal)
            
            # شبیه‌سازی معامله
            if signal['signal'] != 0 and position_size > 0:
                trade_result = self.simulate_trade(trader, signal, position_size, equity)
                if trade_result['executed']:
                    equity = trade_result['new_equity']
                    results.append(trade_result)
            
            # ثبت منحنی سرمایه
            self.equity_curve.append({
                'timestamp': data.index[i],
                'equity': equity,
                'price': data['Close'].iloc[i]
            })
        
        return results
    
    def simulate_trade(self, trader: AdvancedForexTrader, signal: dict, 
                      position_size: float, current_equity: float) -> dict:
        """
        شبیه‌سازی یک معامله
        """
        try:
            if signal['signal'] == 0 or position_size == 0:
                return {'executed': False}
            
            # محاسبه هزینه معامله
            commission = position_size * signal['price'] * 0.001
            
            if signal['signal'] == 1:  # خرید
                cost = position_size * signal['price'] + commission
                if cost <= current_equity:
                    new_equity = current_equity - cost
                    return {
                        'executed': True,
                        'type': 'BUY',
                        'price': signal['price'],
                        'size': position_size,
                        'timestamp': signal['timestamp'],
                        'commission': commission,
                        'new_equity': new_equity,
                        'confidence': signal['confidence'],
                        'reasons': signal['reasons']
                    }
            else:  # فروش
                # شبیه‌سازی بستن پوزیشن
                if hasattr(trader, 'current_position') and trader.current_position:
                    profit = (signal['price'] - trader.current_position['price']) * trader.current_position['size']
                    new_equity = current_equity + trader.current_position['size'] * signal['price'] - commission + profit
                    
                    return {
                        'executed': True,
                        'type': 'SELL',
                        'price': signal['price'],
                        'size': trader.current_position['size'],
                        'timestamp': signal['timestamp'],
                        'commission': commission,
                        'profit': profit,
                        'new_equity': new_equity,
                        'exit_price': signal['price']
                    }
            
            return {'executed': False}
            
        except Exception as e:
            print(f"خطا در شبیه‌سازی معامله: {e}")
            return {'executed': False}
    
    def calculate_performance_metrics(self, results: list, data: pd.DataFrame) -> dict:
        """
        محاسبه معیارهای عملکرد پیشرفته
        """
        if not results:
            return {
                'total_trades': 0,
                'win_rate': 0,
                'total_profit': 0,
                'sharpe_ratio': 0,
                'max_drawdown': 0,
                'profit_factor': 0
            }
        
        # محاسبه معیارهای پایه
        total_trades = len([r for r in results if r['type'] == 'SELL'])
        winning_trades = len([r for r in results if r['type'] == 'SELL' and r.get('profit', 0) > 0])
        
        profits = [r.get('profit', 0) for r in results if r['type'] == 'SELL']
        total_profit = sum(profits)
        
        # محاسبه Sharpe Ratio
        if len(profits) > 1:
            returns = np.diff(profits)
            sharpe_ratio = np.mean(returns) / np.std(returns) if np.std(returns) > 0 else 0
        else:
            sharpe_ratio = 0
        
        # محاسبه Maximum Drawdown
        equity_values = [e['equity'] for e in self.equity_curve]
        peak = equity_values[0]
        max_drawdown = 0
        
        for equity in equity_values:
            if equity > peak:
                peak = equity
            drawdown = (peak - equity) / peak
            max_drawdown = max(max_drawdown, drawdown)
        
        # محاسبه Profit Factor
        gross_profit = sum([p for p in profits if p > 0])
        gross_loss = abs(sum([p for p in profits if p < 0]))
        profit_factor = gross_profit / gross_loss if gross_loss > 0 else float('inf')
        
        # محاسبه Average Win/Loss
        wins = [p for p in profits if p > 0]
        losses = [p for p in profits if p < 0]
        avg_win = np.mean(wins) if wins else 0
        avg_loss = np.mean(losses) if losses else 0
        
        return {
            'total_trades': total_trades,
            'winning_trades': winning_trades,
            'win_rate': winning_trades / total_trades if total_trades > 0 else 0,
            'total_profit': total_profit,
            'average_profit': np.mean(profits) if profits else 0,
            'sharpe_ratio': sharpe_ratio,
            'max_drawdown': max_drawdown,
            'profit_factor': profit_factor,
            'average_win': avg_win,
            'average_loss': avg_loss,
            'final_equity': equity_values[-1] if equity_values else self.initial_balance,
            'return_percentage': ((equity_values[-1] - self.initial_balance) / self.initial_balance * 100) if equity_values else 0
        }
    
    def plot_results(self, results: dict):
        """
        رسم نمودارهای نتایج
        """
        if not results['success']:
            print("خطا در رسم نمودارها")
            return
        
        data = results['data']
        performance = results['performance']
        equity_curve = self.equity_curve
        
        # ایجاد نمودارها
        fig, axes = plt.subplots(2, 2, figsize=(15, 12))
        fig.suptitle('نتایج بک‌تست استراتژی فارکس', fontsize=16, fontweight='bold')
        
        # نمودار 1: قیمت و منحنی سرمایه
        ax1 = axes[0, 0]
        ax1.plot(data.index, data['Close'], label='قیمت', alpha=0.7)
        ax1.set_title('قیمت و منحنی سرمایه')
        ax1.set_ylabel('قیمت')
        ax1.legend()
        
        # نمودار منحنی سرمایه
        equity_df = pd.DataFrame(equity_curve)
        ax1_twin = ax1.twinx()
        ax1_twin.plot(equity_df['timestamp'], equity_df['equity'], 
                     color='green', label='سرمایه', linewidth=2)
        ax1_twin.set_ylabel('سرمایه ($)')
        ax1_twin.legend(loc='upper right')
        
        # نمودار 2: توزیع سود/زیان
        ax2 = axes[0, 1]
        profits = [r.get('profit', 0) for r in results['results'] if r['type'] == 'SELL']
        if profits:
            ax2.hist(profits, bins=20, alpha=0.7, color='skyblue', edgecolor='black')
            ax2.axvline(0, color='red', linestyle='--', alpha=0.7)
            ax2.set_title('توزیع سود/زیان')
            ax2.set_xlabel('سود/زیان ($)')
            ax2.set_ylabel('تعداد معاملات')
        
        # نمودار 3: معیارهای عملکرد
        ax3 = axes[1, 0]
        metrics = ['نرخ موفقیت', 'Sharpe Ratio', 'Profit Factor']
        values = [
            performance['win_rate'] * 100,
            performance['sharpe_ratio'],
            min(performance['profit_factor'], 10)  # محدود کردن برای نمایش بهتر
        ]
        
        bars = ax3.bar(metrics, values, color=['green', 'blue', 'orange'])
        ax3.set_title('معیارهای عملکرد')
        ax3.set_ylabel('مقدار')
        
        # اضافه کردن مقادیر روی نمودار
        for bar, value in zip(bars, values):
            height = bar.get_height()
            ax3.text(bar.get_x() + bar.get_width()/2., height + 0.01,
                    f'{value:.2f}', ha='center', va='bottom')
        
        # نمودار 4: خلاصه نتایج
        ax4 = axes[1, 1]
        ax4.axis('off')
        
        summary_text = f"""
        خلاصه نتایج:
        
        تعداد کل معاملات: {performance['total_trades']}
        معاملات سودده: {performance['winning_trades']}
        نرخ موفقیت: {performance['win_rate']:.2%}
        
        سود کل: ${performance['total_profit']:.2f}
        سود متوسط: ${performance['average_profit']:.2f}
        بازده: {performance['return_percentage']:.2f}%
        
        حداکثر افت: {performance['max_drawdown']:.2%}
        Sharpe Ratio: {performance['sharpe_ratio']:.2f}
        Profit Factor: {performance['profit_factor']:.2f}
        
        سرمایه نهایی: ${performance['final_equity']:.2f}
        """
        
        ax4.text(0.1, 0.9, summary_text, transform=ax4.transAxes, 
                fontsize=12, verticalalignment='top',
                bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
        
        plt.tight_layout()
        plt.savefig('backtest_results.png', dpi=300, bbox_inches='tight')
        plt.show()
    
    def optimize_strategy(self, symbol: str, start_date: str, end_date: str,
                         param_ranges: dict) -> dict:
        """
        بهینه‌سازی پارامترهای استراتژی
        """
        best_params = {}
        best_sharpe = -float('inf')
        results_summary = []
        
        # تولید ترکیبات مختلف پارامترها
        param_combinations = self.generate_param_combinations(param_ranges)
        
        print(f"شروع بهینه‌سازی با {len(param_combinations)} ترکیب پارامتری...")
        
        for i, params in enumerate(param_combinations):
            # اجرای بک‌تست با پارامترهای فعلی
            result = self.run_backtest(symbol, start_date, end_date, "1h", params)
            
            if result['success']:
                performance = result['performance']
                sharpe = performance['sharpe_ratio']
                
                results_summary.append({
                    'params': params,
                    'sharpe_ratio': sharpe,
                    'win_rate': performance['win_rate'],
                    'total_profit': performance['total_profit'],
                    'max_drawdown': performance['max_drawdown']
                })
                
                if sharpe > best_sharpe:
                    best_sharpe = sharpe
                    best_params = params.copy()
                
                if (i + 1) % 10 == 0:
                    print(f"پیشرفت: {i + 1}/{len(param_combinations)} - بهترین Sharpe: {best_sharpe:.3f}")
        
        return {
            'best_params': best_params,
            'best_sharpe': best_sharpe,
            'all_results': results_summary
        }
    
    def generate_param_combinations(self, param_ranges: dict) -> list:
        """
        تولید ترکیبات مختلف پارامترها
        """
        import itertools
        
        param_names = list(param_ranges.keys())
        param_values = list(param_ranges.values())
        
        combinations = []
        for values in itertools.product(*param_values):
            combination = dict(zip(param_names, values))
            combinations.append(combination)
        
        return combinations

# مثال استفاده
if __name__ == "__main__":
    # ایجاد موتور بک‌تستینگ
    backtester = BacktestingEngine(initial_balance=10000)
    
    # اجرای بک‌تست
    print("شروع بک‌تست استراتژی فارکس...")
    results = backtester.run_backtest(
        symbol="EURUSD=X",
        start_date="2023-01-01",
        end_date="2023-12-31",
        interval="1h"
    )
    
    if results['success']:
        print("بک‌تست با موفقیت انجام شد!")
        
        # نمایش نتایج
        performance = results['performance']
        print(f"\nنتایج بک‌تست:")
        print(f"تعداد کل معاملات: {performance['total_trades']}")
        print(f"نرخ موفقیت: {performance['win_rate']:.2%}")
        print(f"سود کل: ${performance['total_profit']:.2f}")
        print(f"بازده: {performance['return_percentage']:.2f}%")
        print(f"Sharpe Ratio: {performance['sharpe_ratio']:.3f}")
        print(f"حداکثر افت: {performance['max_drawdown']:.2%}")
        print(f"Profit Factor: {performance['profit_factor']:.2f}")
        
        # رسم نمودارها
        backtester.plot_results(results)
        
        # بهینه‌سازی پارامترها (اختیاری)
        print("\nشروع بهینه‌سازی پارامترها...")
        param_ranges = {
            'rsi_period': [10, 14, 20],
            'rsi_overbought': [65, 70, 75],
            'rsi_oversold': [25, 30, 35],
            'ema_short': [7, 9, 12],
            'ema_long': [18, 21, 26]
        }
        
        optimization_results = backtester.optimize_strategy(
            "EURUSD=X", "2023-01-01", "2023-12-31", param_ranges
        )
        
        print(f"\nبهترین پارامترها:")
        for param, value in optimization_results['best_params'].items():
            print(f"{param}: {value}")
        print(f"بهترین Sharpe Ratio: {optimization_results['best_sharpe']:.3f}")
        
    else:
        print(f"خطا در بک‌تست: {results['error']}")