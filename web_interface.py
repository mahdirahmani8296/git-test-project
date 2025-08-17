#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
رابط وب برای سیستم معاملاتی فارکس
Web Interface for Forex Trading System
"""

from flask import Flask, render_template, request, jsonify, session
from flask_socketio import SocketIO, emit
import threading
import time
import json
from datetime import datetime, timedelta
import pandas as pd
import numpy as np
from forex_trading_system import AdvancedForexTrader
from backtesting_engine import BacktestingEngine
import yfinance as yf

app = Flask(__name__)
app.config['SECRET_KEY'] = 'forex_trading_secret_key_2024'
socketio = SocketIO(app, cors_allowed_origins="*")

# متغیرهای سراسری
traders = {}
current_data = {}
is_monitoring = False
monitoring_thread = None

class TradingManager:
    """
    مدیریت معاملات و داده‌های زنده
    """
    
    def __init__(self):
        self.traders = {}
        self.symbols = ['EURUSD=X', 'GBPUSD=X', 'USDJPY=X', 'AUDUSD=X', 'USDCAD=X']
        self.data_cache = {}
        self.last_update = {}
    
    def create_trader(self, trader_id: str, initial_balance: float = 10000):
        """
        ایجاد معامله‌گر جدید
        """
        if trader_id not in self.traders:
            self.traders[trader_id] = AdvancedForexTrader(initial_balance=initial_balance)
            return True
        return False
    
    def get_trader(self, trader_id: str):
        """
        دریافت معامله‌گر
        """
        return self.traders.get(trader_id)
    
    def update_market_data(self, symbol: str):
        """
        به‌روزرسانی داده‌های بازار
        """
        try:
            ticker = yf.Ticker(symbol)
            data = ticker.history(period="1d", interval="5m")
            
            if not data.empty:
                # محاسبه شاخص‌های تکنیکال
                trader = AdvancedForexTrader()
                data = trader.calculate_technical_indicators(data)
                
                self.data_cache[symbol] = data
                self.last_update[symbol] = datetime.now()
                
                return data
        except Exception as e:
            print(f"خطا در به‌روزرسانی داده‌های {symbol}: {e}")
        
        return None
    
    def get_latest_data(self, symbol: str):
        """
        دریافت آخرین داده‌ها
        """
        if symbol in self.data_cache:
            # بررسی اینکه آیا داده‌ها قدیمی هستند
            if symbol in self.last_update:
                time_diff = datetime.now() - self.last_update[symbol]
                if time_diff.total_seconds() > 300:  # 5 دقیقه
                    return self.update_market_data(symbol)
                else:
                    return self.data_cache[symbol]
            else:
                return self.update_market_data(symbol)
        else:
            return self.update_market_data(symbol)
    
    def run_strategy_for_symbol(self, trader_id: str, symbol: str):
        """
        اجرای استراتژی برای یک نماد
        """
        trader = self.get_trader(trader_id)
        if not trader:
            return None
        
        data = self.get_latest_data(symbol)
        if data is None or data.empty:
            return None
        
        # تولید سیگنال
        signal = trader.advanced_signal_generator(data)
        
        # محاسبه اندازه پوزیشن
        position_size = trader.calculate_position_size(signal)
        
        return {
            'symbol': symbol,
            'signal': signal,
            'position_size': position_size,
            'current_price': data['Close'].iloc[-1] if not data.empty else 0,
            'timestamp': datetime.now().isoformat()
        }

# ایجاد نمونه از مدیر معاملات
trading_manager = TradingManager()

@app.route('/')
def index():
    """
    صفحه اصلی
    """
    return render_template('index.html')

@app.route('/api/create_trader', methods=['POST'])
def create_trader():
    """
    ایجاد معامله‌گر جدید
    """
    try:
        data = request.get_json()
        trader_id = data.get('trader_id', f'trader_{int(time.time())}')
        initial_balance = data.get('initial_balance', 10000)
        
        success = trading_manager.create_trader(trader_id, initial_balance)
        
        if success:
            return jsonify({
                'success': True,
                'trader_id': trader_id,
                'message': 'معامله‌گر با موفقیت ایجاد شد'
            })
        else:
            return jsonify({
                'success': False,
                'message': 'معامله‌گر قبلاً وجود دارد'
            })
    
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'خطا: {str(e)}'
        })

@app.route('/api/run_strategy', methods=['POST'])
def run_strategy():
    """
    اجرای استراتژی
    """
    try:
        data = request.get_json()
        trader_id = data.get('trader_id')
        symbol = data.get('symbol', 'EURUSD=X')
        
        if not trader_id:
            return jsonify({
                'success': False,
                'message': 'شناسه معامله‌گر الزامی است'
            })
        
        result = trading_manager.run_strategy_for_symbol(trader_id, symbol)
        
        if result:
            return jsonify({
                'success': True,
                'result': result
            })
        else:
            return jsonify({
                'success': False,
                'message': 'خطا در اجرای استراتژی'
            })
    
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'خطا: {str(e)}'
        })

@app.route('/api/execute_trade', methods=['POST'])
def execute_trade():
    """
    اجرای معامله
    """
    try:
        data = request.get_json()
        trader_id = data.get('trader_id')
        symbol = data.get('symbol')
        signal = data.get('signal')
        position_size = data.get('position_size')
        
        if not all([trader_id, symbol, signal, position_size]):
            return jsonify({
                'success': False,
                'message': 'تمام پارامترها الزامی هستند'
            })
        
        trader = trading_manager.get_trader(trader_id)
        if not trader:
            return jsonify({
                'success': False,
                'message': 'معامله‌گر یافت نشد'
            })
        
        # اجرای معامله
        success = trader.execute_trade(symbol, signal, position_size)
        
        if success:
            return jsonify({
                'success': True,
                'message': 'معامله با موفقیت اجرا شد',
                'current_balance': trader.balance
            })
        else:
            return jsonify({
                'success': False,
                'message': 'خطا در اجرای معامله'
            })
    
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'خطا: {str(e)}'
        })

@app.route('/api/get_performance', methods=['GET'])
def get_performance():
    """
    دریافت معیارهای عملکرد
    """
    try:
        trader_id = request.args.get('trader_id')
        
        if not trader_id:
            return jsonify({
                'success': False,
                'message': 'شناسه معامله‌گر الزامی است'
            })
        
        trader = trading_manager.get_trader(trader_id)
        if not trader:
            return jsonify({
                'success': False,
                'message': 'معامله‌گر یافت نشد'
            })
        
        metrics = trader.get_performance_metrics()
        
        return jsonify({
            'success': True,
            'metrics': metrics
        })
    
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'خطا: {str(e)}'
        })

@app.route('/api/run_backtest', methods=['POST'])
def run_backtest():
    """
    اجرای بک‌تست
    """
    try:
        data = request.get_json()
        symbol = data.get('symbol', 'EURUSD=X')
        start_date = data.get('start_date', '2023-01-01')
        end_date = data.get('end_date', '2023-12-31')
        initial_balance = data.get('initial_balance', 10000)
        
        # ایجاد موتور بک‌تستینگ
        backtester = BacktestingEngine(initial_balance=initial_balance)
        
        # اجرای بک‌تست
        results = backtester.run_backtest(symbol, start_date, end_date, "1h")
        
        if results['success']:
            return jsonify({
                'success': True,
                'results': results['performance'],
                'message': 'بک‌تست با موفقیت انجام شد'
            })
        else:
            return jsonify({
                'success': False,
                'message': results['error']
            })
    
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'خطا: {str(e)}'
        })

@app.route('/api/get_market_data', methods=['GET'])
def get_market_data():
    """
    دریافت داده‌های بازار
    """
    try:
        symbol = request.args.get('symbol', 'EURUSD=X')
        
        data = trading_manager.get_latest_data(symbol)
        
        if data is not None and not data.empty:
            # تبدیل به فرمت JSON
            latest_data = {
                'symbol': symbol,
                'price': float(data['Close'].iloc[-1]),
                'change': float(data['Close'].iloc[-1] - data['Close'].iloc[-2]) if len(data) > 1 else 0,
                'volume': int(data['Volume'].iloc[-1]),
                'rsi': float(data['RSI'].iloc[-1]) if 'RSI' in data.columns else None,
                'macd': float(data['MACD'].iloc[-1]) if 'MACD' in data.columns else None,
                'timestamp': data.index[-1].isoformat()
            }
            
            return jsonify({
                'success': True,
                'data': latest_data
            })
        else:
            return jsonify({
                'success': False,
                'message': 'داده‌ای یافت نشد'
            })
    
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'خطا: {str(e)}'
        })

def start_monitoring():
    """
    شروع نظارت بر بازار
    """
    global is_monitoring
    is_monitoring = True
    
    while is_monitoring:
        try:
            # به‌روزرسانی داده‌های همه نمادها
            for symbol in trading_manager.symbols:
                data = trading_manager.update_market_data(symbol)
                if data is not None:
                    # ارسال داده‌ها به کلاینت‌ها
                    socketio.emit('market_update', {
                        'symbol': symbol,
                        'price': float(data['Close'].iloc[-1]),
                        'timestamp': datetime.now().isoformat()
                    })
            
            time.sleep(30)  # به‌روزرسانی هر 30 ثانیه
            
        except Exception as e:
            print(f"خطا در نظارت بر بازار: {e}")
            time.sleep(60)

@socketio.on('connect')
def handle_connect():
    """
    مدیریت اتصال کلاینت
    """
    print('کلاینت متصل شد')
    emit('status', {'message': 'متصل شدید'})

@socketio.on('disconnect')
def handle_disconnect():
    """
    مدیریت قطع اتصال کلاینت
    """
    print('کلاینت قطع شد')

@socketio.on('start_monitoring')
def handle_start_monitoring():
    """
    شروع نظارت بر بازار
    """
    global monitoring_thread, is_monitoring
    
    if not is_monitoring:
        monitoring_thread = threading.Thread(target=start_monitoring)
        monitoring_thread.daemon = True
        monitoring_thread.start()
        emit('status', {'message': 'نظارت بر بازار شروع شد'})

@socketio.on('stop_monitoring')
def handle_stop_monitoring():
    """
    توقف نظارت بر بازار
    """
    global is_monitoring
    is_monitoring = False
    emit('status', {'message': 'نظارت بر بازار متوقف شد'})

if __name__ == '__main__':
    print("شروع سرور معاملات فارکس...")
    print("دسترسی به رابط وب: http://localhost:5000")
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)