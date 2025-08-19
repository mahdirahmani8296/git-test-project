#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Forex Trading Bot
================
A comprehensive forex trading bot with technical analysis and risk management.
"""

import MetaTrader5 as mt5
import pandas as pd
import numpy as np
import time
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
import json
import os

class ForexTradingBot:
    """
    Main Forex Trading Bot class with technical analysis and automated trading capabilities.
    """
    
    def __init__(self, config_file: str = "config.json"):
        """Initialize the trading bot with configuration."""
        self.config = self.load_config(config_file)
        self.setup_logging()
        self.mt5_connected = False
        self.positions = {}
        self.trading_active = False
        
        # Technical indicators data
        self.market_data = {}
        
    def load_config(self, config_file: str) -> Dict:
        """Load trading configuration from JSON file."""
        default_config = {
            "mt5_login": 0,
            "mt5_password": "",
            "mt5_server": "",
            "symbols": ["EURUSD", "GBPUSD", "USDJPY", "AUDUSD"],
            "timeframe": "M15",
            "lot_size": 0.01,
            "max_positions": 5,
            "risk_percent": 2.0,
            "stop_loss_pips": 50,
            "take_profit_pips": 100,
            "rsi_period": 14,
            "rsi_overbought": 70,
            "rsi_oversold": 30,
            "ma_fast": 10,
            "ma_slow": 20,
            "macd_fast": 12,
            "macd_slow": 26,
            "macd_signal": 9,
            "trading_hours": {
                "start": "08:00",
                "end": "18:00"
            },
            "max_daily_loss": 100.0,
            "max_daily_profit": 200.0
        }
        
        if os.path.exists(config_file):
            try:
                with open(config_file, 'r', encoding='utf-8') as f:
                    user_config = json.load(f)
                default_config.update(user_config)
            except Exception as e:
                logging.error(f"خطا در بارگذاری فایل پیکربندی: {e}")
        else:
            # Create default config file
            with open(config_file, 'w', encoding='utf-8') as f:
                json.dump(default_config, f, indent=4, ensure_ascii=False)
            logging.info(f"فایل پیکربندی پیش‌فرض در {config_file} ایجاد شد")
        
        return default_config
    
    def setup_logging(self):
        """Setup logging configuration."""
        log_format = '%(asctime)s - %(levelname)s - %(message)s'
        logging.basicConfig(
            level=logging.INFO,
            format=log_format,
            handlers=[
                logging.FileHandler('forex_bot.log', encoding='utf-8'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    def connect_mt5(self) -> bool:
        """Connect to MetaTrader 5 terminal."""
        if not mt5.initialize():
            self.logger.error("خطا در اتصال به MetaTrader 5")
            return False
        
        if self.config["mt5_login"] and self.config["mt5_password"]:
            authorized = mt5.login(
                login=self.config["mt5_login"],
                password=self.config["mt5_password"],
                server=self.config["mt5_server"]
            )
            if not authorized:
                self.logger.error("خطا در احراز هویت MetaTrader 5")
                return False
        
        self.mt5_connected = True
        self.logger.info("اتصال موفق به MetaTrader 5")
        return True
    
    def disconnect_mt5(self):
        """Disconnect from MetaTrader 5."""
        mt5.shutdown()
        self.mt5_connected = False
        self.logger.info("اتصال به MetaTrader 5 قطع شد")
    
    def get_market_data(self, symbol: str, timeframe: str = None, count: int = 100) -> pd.DataFrame:
        """Get market data for a symbol."""
        if not self.mt5_connected:
            return pd.DataFrame()
        
        tf = getattr(mt5, f"TIMEFRAME_{timeframe or self.config['timeframe']}")
        rates = mt5.copy_rates_from_pos(symbol, tf, 0, count)
        
        if rates is None:
            self.logger.warning(f"داده‌های بازار برای {symbol} دریافت نشد")
            return pd.DataFrame()
        
        df = pd.DataFrame(rates)
        df['time'] = pd.to_datetime(df['time'], unit='s')
        return df
    
    def calculate_rsi(self, prices: pd.Series, period: int = 14) -> pd.Series:
        """Calculate RSI indicator."""
        delta = prices.diff()
        gain = (delta.where(delta > 0, 0)).rolling(window=period).mean()
        loss = (-delta.where(delta < 0, 0)).rolling(window=period).mean()
        rs = gain / loss
        rsi = 100 - (100 / (1 + rs))
        return rsi
    
    def calculate_macd(self, prices: pd.Series, fast: int = 12, slow: int = 26, signal: int = 9) -> Dict:
        """Calculate MACD indicator."""
        exp1 = prices.ewm(span=fast).mean()
        exp2 = prices.ewm(span=slow).mean()
        macd = exp1 - exp2
        signal_line = macd.ewm(span=signal).mean()
        histogram = macd - signal_line
        
        return {
            'macd': macd,
            'signal': signal_line,
            'histogram': histogram
        }
    
    def calculate_moving_averages(self, prices: pd.Series, fast: int = 10, slow: int = 20) -> Dict:
        """Calculate moving averages."""
        return {
            'ma_fast': prices.rolling(window=fast).mean(),
            'ma_slow': prices.rolling(window=slow).mean()
        }
    
    def analyze_market(self, symbol: str) -> Dict:
        """Perform technical analysis on market data."""
        df = self.get_market_data(symbol)
        if df.empty:
            return {}
        
        close_prices = df['close']
        
        # Calculate indicators
        rsi = self.calculate_rsi(close_prices, self.config['rsi_period'])
        macd_data = self.calculate_macd(
            close_prices, 
            self.config['macd_fast'], 
            self.config['macd_slow'], 
            self.config['macd_signal']
        )
        ma_data = self.calculate_moving_averages(
            close_prices,
            self.config['ma_fast'],
            self.config['ma_slow']
        )
        
        current_price = close_prices.iloc[-1]
        current_rsi = rsi.iloc[-1] if not rsi.empty else 50
        current_macd = macd_data['macd'].iloc[-1] if not macd_data['macd'].empty else 0
        current_signal = macd_data['signal'].iloc[-1] if not macd_data['signal'].empty else 0
        current_ma_fast = ma_data['ma_fast'].iloc[-1] if not ma_data['ma_fast'].empty else current_price
        current_ma_slow = ma_data['ma_slow'].iloc[-1] if not ma_data['ma_slow'].empty else current_price
        
        analysis = {
            'symbol': symbol,
            'current_price': current_price,
            'rsi': current_rsi,
            'macd': current_macd,
            'macd_signal': current_signal,
            'ma_fast': current_ma_fast,
            'ma_slow': current_ma_slow,
            'trend': 'BULLISH' if current_ma_fast > current_ma_slow else 'BEARISH',
            'rsi_signal': 'OVERSOLD' if current_rsi < self.config['rsi_oversold'] else 'OVERBOUGHT' if current_rsi > self.config['rsi_overbought'] else 'NEUTRAL',
            'macd_signal_trend': 'BULLISH' if current_macd > current_signal else 'BEARISH'
        }
        
        return analysis
    
    def generate_trading_signal(self, analysis: Dict) -> str:
        """Generate trading signal based on technical analysis."""
        if not analysis:
            return "NO_SIGNAL"
        
        signals = []
        
        # RSI signals
        if analysis['rsi_signal'] == 'OVERSOLD' and analysis['trend'] == 'BULLISH':
            signals.append('BUY')
        elif analysis['rsi_signal'] == 'OVERBOUGHT' and analysis['trend'] == 'BEARISH':
            signals.append('SELL')
        
        # MACD signals
        if analysis['macd_signal_trend'] == 'BULLISH' and analysis['trend'] == 'BULLISH':
            signals.append('BUY')
        elif analysis['macd_signal_trend'] == 'BEARISH' and analysis['trend'] == 'BEARISH':
            signals.append('SELL')
        
        # Consensus signal
        if signals.count('BUY') >= 2:
            return 'BUY'
        elif signals.count('SELL') >= 2:
            return 'SELL'
        
        return 'NO_SIGNAL'
    
    def calculate_position_size(self, symbol: str, risk_percent: float = None) -> float:
        """Calculate position size based on risk management."""
        if not risk_percent:
            risk_percent = self.config['risk_percent']
        
        account_info = mt5.account_info()
        if not account_info:
            return self.config['lot_size']
        
        balance = account_info.balance
        risk_amount = balance * (risk_percent / 100)
        
        symbol_info = mt5.symbol_info(symbol)
        if not symbol_info:
            return self.config['lot_size']
        
        pip_value = symbol_info.trade_tick_value
        stop_loss_pips = self.config['stop_loss_pips']
        
        if pip_value > 0 and stop_loss_pips > 0:
            position_size = risk_amount / (stop_loss_pips * pip_value)
            return min(position_size, 1.0)  # Max 1 lot
        
        return self.config['lot_size']
    
    def place_order(self, symbol: str, order_type: str, volume: float = None) -> bool:
        """Place a trading order."""
        if not self.mt5_connected:
            return False
        
        if not volume:
            volume = self.calculate_position_size(symbol)
        
        symbol_info = mt5.symbol_info(symbol)
        if not symbol_info:
            self.logger.error(f"اطلاعات نماد {symbol} دریافت نشد")
            return False
        
        if not symbol_info.visible:
            if not mt5.symbol_select(symbol, True):
                self.logger.error(f"انتخاب نماد {symbol} ناموفق")
                return False
        
        price = mt5.symbol_info_tick(symbol).ask if order_type == 'BUY' else mt5.symbol_info_tick(symbol).bid
        
        # Calculate stop loss and take profit
        pip_size = symbol_info.point * 10  # For most forex pairs
        
        if order_type == 'BUY':
            sl = price - (self.config['stop_loss_pips'] * pip_size)
            tp = price + (self.config['take_profit_pips'] * pip_size)
            order_type_mt5 = mt5.ORDER_TYPE_BUY
        else:
            sl = price + (self.config['stop_loss_pips'] * pip_size)
            tp = price - (self.config['take_profit_pips'] * pip_size)
            order_type_mt5 = mt5.ORDER_TYPE_SELL
        
        request = {
            "action": mt5.TRADE_ACTION_DEAL,
            "symbol": symbol,
            "volume": volume,
            "type": order_type_mt5,
            "price": price,
            "sl": sl,
            "tp": tp,
            "deviation": 20,
            "magic": 234000,
            "comment": "Forex Bot Trade",
            "type_time": mt5.ORDER_TIME_GTC,
            "type_filling": mt5.ORDER_FILLING_IOC,
        }
        
        result = mt5.order_send(request)
        
        if result.retcode != mt5.TRADE_RETCODE_DONE:
            self.logger.error(f"سفارش ناموفق برای {symbol}: {result.comment}")
            return False
        
        self.logger.info(f"سفارش موفق {order_type} برای {symbol} - حجم: {volume}")
        return True
    
    def get_open_positions(self) -> List[Dict]:
        """Get all open positions."""
        positions = mt5.positions_get()
        if positions is None:
            return []
        
        return [
            {
                'ticket': pos.ticket,
                'symbol': pos.symbol,
                'type': 'BUY' if pos.type == mt5.ORDER_TYPE_BUY else 'SELL',
                'volume': pos.volume,
                'price_open': pos.price_open,
                'price_current': pos.price_current,
                'profit': pos.profit,
                'sl': pos.sl,
                'tp': pos.tp
            }
            for pos in positions
        ]
    
    def is_trading_time(self) -> bool:
        """Check if current time is within trading hours."""
        current_time = datetime.now().time()
        start_time = datetime.strptime(self.config['trading_hours']['start'], '%H:%M').time()
        end_time = datetime.strptime(self.config['trading_hours']['end'], '%H:%M').time()
        
        return start_time <= current_time <= end_time
    
    def check_daily_limits(self) -> bool:
        """Check if daily profit/loss limits are reached."""
        # This would need to be implemented with proper trade history analysis
        # For now, return True (no limits reached)
        return True
    
    def run_trading_cycle(self):
        """Run one complete trading cycle."""
        if not self.is_trading_time():
            self.logger.info("خارج از ساعات معاملاتی")
            return
        
        if not self.check_daily_limits():
            self.logger.warning("حد روزانه سود/زیان رسیده است")
            return
        
        open_positions = self.get_open_positions()
        
        if len(open_positions) >= self.config['max_positions']:
            self.logger.info(f"حداکثر موقعیت‌ها ({self.config['max_positions']}) باز است")
            return
        
        for symbol in self.config['symbols']:
            try:
                analysis = self.analyze_market(symbol)
                signal = self.generate_trading_signal(analysis)
                
                if signal in ['BUY', 'SELL']:
                    # Check if we already have a position for this symbol
                    has_position = any(pos['symbol'] == symbol for pos in open_positions)
                    
                    if not has_position:
                        self.logger.info(f"سیگنال {signal} برای {symbol} - قیمت: {analysis['current_price']:.5f}")
                        success = self.place_order(symbol, signal)
                        
                        if success:
                            time.sleep(1)  # Small delay between orders
                
            except Exception as e:
                self.logger.error(f"خطا در تحلیل {symbol}: {e}")
    
    def start_trading(self):
        """Start the automated trading bot."""
        if not self.connect_mt5():
            return False
        
        self.trading_active = True
        self.logger.info("ربات معاملاتی شروع شد")
        
        try:
            while self.trading_active:
                self.run_trading_cycle()
                time.sleep(60)  # Wait 1 minute between cycles
                
        except KeyboardInterrupt:
            self.logger.info("ربات توسط کاربر متوقف شد")
        except Exception as e:
            self.logger.error(f"خطای غیرمنتظره: {e}")
        finally:
            self.stop_trading()
    
    def stop_trading(self):
        """Stop the trading bot."""
        self.trading_active = False
        self.disconnect_mt5()
        self.logger.info("ربات معاملاتی متوقف شد")
    
    def get_performance_report(self) -> Dict:
        """Generate performance report."""
        positions = self.get_open_positions()
        total_profit = sum(pos['profit'] for pos in positions)
        
        account_info = mt5.account_info()
        if account_info:
            balance = account_info.balance
            equity = account_info.equity
        else:
            balance = equity = 0
        
        return {
            'timestamp': datetime.now().isoformat(),
            'balance': balance,
            'equity': equity,
            'open_positions': len(positions),
            'total_floating_profit': total_profit,
            'positions': positions
        }


def main():
    """Main function to run the forex trading bot."""
    bot = ForexTradingBot()
    
    print("=== ربات معاملاتی فارکس ===")
    print("1. شروع معاملات خودکار")
    print("2. نمایش موقعیت‌های باز")
    print("3. گزارش عملکرد")
    print("4. خروج")
    
    while True:
        try:
            choice = input("\nانتخاب کنید (1-4): ").strip()
            
            if choice == '1':
                bot.start_trading()
            elif choice == '2':
                if bot.connect_mt5():
                    positions = bot.get_open_positions()
                    if positions:
                        print(f"\n--- {len(positions)} موقعیت باز ---")
                        for pos in positions:
                            print(f"{pos['symbol']} - {pos['type']} - حجم: {pos['volume']} - سود: {pos['profit']:.2f}")
                    else:
                        print("هیچ موقعیت بازی وجود ندارد")
                    bot.disconnect_mt5()
            elif choice == '3':
                if bot.connect_mt5():
                    report = bot.get_performance_report()
                    print(f"\n--- گزارش عملکرد ---")
                    print(f"موجودی: {report['balance']:.2f}")
                    print(f"حقوق صاحبان سهام: {report['equity']:.2f}")
                    print(f"موقعیت‌های باز: {report['open_positions']}")
                    print(f"سود شناور کل: {report['total_floating_profit']:.2f}")
                    bot.disconnect_mt5()
            elif choice == '4':
                print("خروج از برنامه...")
                break
            else:
                print("انتخاب نامعتبر!")
                
        except KeyboardInterrupt:
            print("\nخروج از برنامه...")
            break
        except Exception as e:
            print(f"خطا: {e}")


if __name__ == "__main__":
    main()