import pandas as pd
import numpy as np
import MetaTrader5 as mt5
from datetime import datetime, timedelta
import logging
import time
import json
import schedule
import threading
from typing import Dict, List, Optional
import warnings
import os
from dotenv import load_dotenv
import requests

from forex_trading_bot import AdvancedForexTradingBot
from risk_manager import AdvancedRiskManager
from backtester import ForexBacktester

warnings.filterwarnings('ignore')
load_dotenv()

class LiveForexTrader:
    """
    Live Forex Trading Manager with Real-time Monitoring
    مدیر معاملات زنده فارکس با نظارت بلادرنگ
    """
    
    def __init__(self, config_file: str = "trading_config.json"):
        """
        Initialize live trading manager
        
        Args:
            config_file: Path to configuration file
        """
        self.config = self.load_config(config_file)
        
        # Initialize components
        self.trading_bot = None
        self.risk_manager = None
        self.performance_tracker = {}
        
        # Trading state
        self.is_trading = False
        self.trading_thread = None
        self.monitoring_thread = None
        
        # Performance metrics
        self.daily_stats = {}
        self.weekly_stats = {}
        self.monthly_stats = {}
        
        # Alerts and notifications
        self.alert_thresholds = self.config.get('alerts', {})
        self.telegram_bot_token = os.getenv('TELEGRAM_BOT_TOKEN')
        self.telegram_chat_id = os.getenv('TELEGRAM_CHAT_ID')
        
        # Setup logging
        self.setup_logging()
        self.logger = logging.getLogger(__name__)
        
        # Initialize trading bot
        self.initialize_trading_bot()
    
    def load_config(self, config_file: str) -> Dict:
        """Load trading configuration"""
        try:
            default_config = {
                "mt5": {
                    "account": int(os.getenv('MT5_ACCOUNT', 12345678)),
                    "password": os.getenv('MT5_PASSWORD', 'your_password'),
                    "server": os.getenv('MT5_SERVER', 'MetaQuotes-Demo')
                },
                "trading": {
                    "symbols": ["EURUSD", "GBPUSD", "USDJPY"],
                    "confidence_threshold": 75.0,
                    "max_concurrent_trades": 5,
                    "trading_hours": {
                        "start": "08:00",
                        "end": "17:00",
                        "timezone": "UTC"
                    }
                },
                "risk": {
                    "max_risk_per_trade": 0.02,
                    "max_daily_loss": 0.05,
                    "max_drawdown": 0.15,
                    "initial_balance": 10000
                },
                "alerts": {
                    "max_drawdown_alert": 0.10,
                    "daily_loss_alert": 0.03,
                    "consecutive_losses_alert": 5,
                    "low_balance_alert": 0.70
                },
                "monitoring": {
                    "update_interval": 300,  # 5 minutes
                    "save_stats_interval": 3600,  # 1 hour
                    "backup_interval": 86400  # 24 hours
                }
            }
            
            if os.path.exists(config_file):
                with open(config_file, 'r') as f:
                    user_config = json.load(f)
                    default_config.update(user_config)
            else:
                # Save default config
                with open(config_file, 'w') as f:
                    json.dump(default_config, f, indent=4)
                self.logger.info(f"Created default config file: {config_file}")
            
            return default_config
            
        except Exception as e:
            self.logger.error(f"Error loading config: {e}")
            return {}
    
    def setup_logging(self):
        """Setup comprehensive logging"""
        try:
            # Create logs directory
            os.makedirs('logs', exist_ok=True)
            
            # Configure logging
            log_format = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
            
            # Main log file
            logging.basicConfig(
                level=logging.INFO,
                format=log_format,
                handlers=[
                    logging.FileHandler(f'logs/forex_trader_{datetime.now().strftime("%Y%m%d")}.log'),
                    logging.StreamHandler()
                ]
            )
            
            # Trade log
            trade_logger = logging.getLogger('trades')
            trade_handler = logging.FileHandler(f'logs/trades_{datetime.now().strftime("%Y%m%d")}.log')
            trade_handler.setFormatter(logging.Formatter(log_format))
            trade_logger.addHandler(trade_handler)
            
            # Performance log
            perf_logger = logging.getLogger('performance')
            perf_handler = logging.FileHandler(f'logs/performance_{datetime.now().strftime("%Y%m%d")}.log')
            perf_handler.setFormatter(logging.Formatter(log_format))
            perf_logger.addHandler(perf_handler)
            
        except Exception as e:
            print(f"Error setting up logging: {e}")
    
    def initialize_trading_bot(self):
        """Initialize trading bot and risk manager"""
        try:
            mt5_config = self.config['mt5']
            risk_config = self.config['risk']
            
            # Initialize trading bot
            self.trading_bot = AdvancedForexTradingBot(
                account=mt5_config['account'],
                password=mt5_config['password'],
                server=mt5_config['server']
            )
            
            # Initialize risk manager
            self.risk_manager = AdvancedRiskManager(
                initial_balance=risk_config['initial_balance']
            )
            
            # Update risk parameters
            self.risk_manager.max_risk_per_trade = risk_config['max_risk_per_trade']
            self.risk_manager.max_daily_risk = risk_config['max_daily_loss']
            self.risk_manager.max_drawdown = risk_config['max_drawdown']
            
            self.logger.info("Trading bot and risk manager initialized successfully")
            
        except Exception as e:
            self.logger.error(f"Error initializing trading bot: {e}")
    
    def send_telegram_alert(self, message: str, priority: str = "INFO"):
        """Send alert via Telegram"""
        try:
            if not self.telegram_bot_token or not self.telegram_chat_id:
                return False
            
            # Format message
            priority_emoji = {
                "INFO": "ℹ️",
                "WARNING": "⚠️",
                "ERROR": "❌",
                "SUCCESS": "✅",
                "TRADE": "💰"
            }
            
            formatted_message = f"{priority_emoji.get(priority, 'ℹ️')} *Forex Bot Alert*\n\n{message}"
            
            # Send message
            url = f"https://api.telegram.org/bot{self.telegram_bot_token}/sendMessage"
            data = {
                'chat_id': self.telegram_chat_id,
                'text': formatted_message,
                'parse_mode': 'Markdown'
            }
            
            response = requests.post(url, data=data, timeout=10)
            return response.status_code == 200
            
        except Exception as e:
            self.logger.error(f"Error sending Telegram alert: {e}")
            return False
    
    def check_trading_hours(self) -> bool:
        """Check if current time is within trading hours"""
        try:
            trading_config = self.config['trading']['trading_hours']
            current_time = datetime.now().time()
            
            start_time = datetime.strptime(trading_config['start'], "%H:%M").time()
            end_time = datetime.strptime(trading_config['end'], "%H:%M").time()
            
            return start_time <= current_time <= end_time
            
        except Exception as e:
            self.logger.error(f"Error checking trading hours: {e}")
            return True  # Default to allow trading
    
    def run_backtest_validation(self, symbol: str, days: int = 30) -> Dict:
        """Run quick backtest validation before live trading"""
        try:
            self.logger.info(f"Running backtest validation for {symbol}")
            
            backtester = ForexBacktester(self.config['risk']['initial_balance'])
            
            end_date = datetime.now()
            start_date = end_date - timedelta(days=days)
            
            results = backtester.run_backtest(
                symbol=symbol,
                start_date=start_date.strftime('%Y-%m-%d'),
                end_date=end_date.strftime('%Y-%m-%d'),
                confidence_threshold=self.config['trading']['confidence_threshold']
            )
            
            if results:
                self.logger.info(f"Backtest validation completed for {symbol}")
                self.logger.info(f"Win Rate: {results.get('win_rate', 0):.1f}%")
                self.logger.info(f"Profit Factor: {results.get('profit_factor', 0):.2f}")
                self.logger.info(f"Max Drawdown: {results.get('max_drawdown', 0):.2f}%")
                
                # Send validation results
                if results.get('win_rate', 0) >= 50 and results.get('profit_factor', 0) >= 1.2:
                    message = f"✅ *Backtest Validation Passed*\n\n"
                    message += f"Symbol: {symbol}\n"
                    message += f"Win Rate: {results.get('win_rate', 0):.1f}%\n"
                    message += f"Profit Factor: {results.get('profit_factor', 0):.2f}\n"
                    message += f"Max Drawdown: {results.get('max_drawdown', 0):.2f}%\n"
                    message += f"Total Trades: {results.get('total_trades', 0)}"
                    
                    self.send_telegram_alert(message, "SUCCESS")
                else:
                    message = f"⚠️ *Backtest Validation Warning*\n\n"
                    message += f"Symbol: {symbol}\n"
                    message += f"Win Rate: {results.get('win_rate', 0):.1f}% (Target: ≥50%)\n"
                    message += f"Profit Factor: {results.get('profit_factor', 0):.2f} (Target: ≥1.2)\n"
                    message += "Strategy may need optimization"
                    
                    self.send_telegram_alert(message, "WARNING")
            
            return results
            
        except Exception as e:
            self.logger.error(f"Error running backtest validation: {e}")
            return {}
    
    def monitor_performance(self):
        """Monitor trading performance and send alerts"""
        try:
            if not self.risk_manager:
                return
            
            # Get current metrics
            portfolio_metrics = self.risk_manager.get_portfolio_metrics()
            risk_summary = self.risk_manager.get_risk_summary()
            
            if not portfolio_metrics:
                return
            
            # Check alert conditions
            alerts_sent = []
            
            # Drawdown alert
            current_drawdown = portfolio_metrics.get('current_drawdown', 0)
            if abs(current_drawdown) >= self.alert_thresholds.get('max_drawdown_alert', 10):
                message = f"🚨 *High Drawdown Alert*\n\n"
                message += f"Current Drawdown: {current_drawdown:.2f}%\n"
                message += f"Alert Threshold: {self.alert_thresholds.get('max_drawdown_alert', 10):.2f}%\n"
                message += f"Current Balance: ${portfolio_metrics.get('current_balance', 0):,.2f}"
                
                if self.send_telegram_alert(message, "ERROR"):
                    alerts_sent.append("drawdown")
            
            # Daily loss alert
            daily_risk = risk_summary.get('daily_risk', 0)
            if daily_risk >= self.alert_thresholds.get('daily_loss_alert', 3):
                message = f"⚠️ *Daily Loss Alert*\n\n"
                message += f"Daily Risk: {daily_risk:.2f}%\n"
                message += f"Alert Threshold: {self.alert_thresholds.get('daily_loss_alert', 3):.2f}%\n"
                message += "Consider reducing position sizes"
                
                if self.send_telegram_alert(message, "WARNING"):
                    alerts_sent.append("daily_loss")
            
            # Low balance alert
            current_balance = portfolio_metrics.get('current_balance', 0)
            initial_balance = self.config['risk']['initial_balance']
            balance_ratio = current_balance / initial_balance
            
            if balance_ratio <= self.alert_thresholds.get('low_balance_alert', 0.7):
                message = f"🔴 *Low Balance Alert*\n\n"
                message += f"Current Balance: ${current_balance:,.2f}\n"
                message += f"Initial Balance: ${initial_balance:,.2f}\n"
                message += f"Ratio: {balance_ratio:.2%}\n"
                message += "Alert Threshold: 70%"
                
                if self.send_telegram_alert(message, "ERROR"):
                    alerts_sent.append("low_balance")
            
            # Update performance tracking
            self.update_performance_stats(portfolio_metrics, risk_summary)
            
            if alerts_sent:
                self.logger.warning(f"Alerts sent: {', '.join(alerts_sent)}")
            
        except Exception as e:
            self.logger.error(f"Error monitoring performance: {e}")
    
    def update_performance_stats(self, portfolio_metrics: Dict, risk_summary: Dict):
        """Update performance statistics"""
        try:
            current_time = datetime.now()
            
            # Daily stats
            today_key = current_time.strftime('%Y-%m-%d')
            self.daily_stats[today_key] = {
                'timestamp': current_time.isoformat(),
                'balance': portfolio_metrics.get('current_balance', 0),
                'drawdown': portfolio_metrics.get('current_drawdown', 0),
                'total_trades': portfolio_metrics.get('total_trades', 0),
                'win_rate': portfolio_metrics.get('win_rate', 0),
                'profit_factor': portfolio_metrics.get('profit_factor', 0),
                'daily_risk': risk_summary.get('daily_risk', 0),
                'open_positions': risk_summary.get('open_positions', 0)
            }
            
            # Weekly stats (keep last 4 weeks)
            week_key = current_time.strftime('%Y-W%U')
            self.weekly_stats[week_key] = self.daily_stats[today_key].copy()
            
            # Keep only last 4 weeks
            if len(self.weekly_stats) > 4:
                oldest_week = min(self.weekly_stats.keys())
                del self.weekly_stats[oldest_week]
            
            # Monthly stats (keep last 12 months)
            month_key = current_time.strftime('%Y-%m')
            self.monthly_stats[month_key] = self.daily_stats[today_key].copy()
            
            # Keep only last 12 months
            if len(self.monthly_stats) > 12:
                oldest_month = min(self.monthly_stats.keys())
                del self.monthly_stats[oldest_month]
            
            # Save stats to file
            self.save_performance_stats()
            
        except Exception as e:
            self.logger.error(f"Error updating performance stats: {e}")
    
    def save_performance_stats(self):
        """Save performance statistics to file"""
        try:
            os.makedirs('data', exist_ok=True)
            
            stats_data = {
                'daily': self.daily_stats,
                'weekly': self.weekly_stats,
                'monthly': self.monthly_stats,
                'last_updated': datetime.now().isoformat()
            }
            
            with open('data/performance_stats.json', 'w') as f:
                json.dump(stats_data, f, indent=2)
                
        except Exception as e:
            self.logger.error(f"Error saving performance stats: {e}")
    
    def load_performance_stats(self):
        """Load performance statistics from file"""
        try:
            if os.path.exists('data/performance_stats.json'):
                with open('data/performance_stats.json', 'r') as f:
                    stats_data = json.load(f)
                    
                self.daily_stats = stats_data.get('daily', {})
                self.weekly_stats = stats_data.get('weekly', {})
                self.monthly_stats = stats_data.get('monthly', {})
                
                self.logger.info("Performance statistics loaded successfully")
            
        except Exception as e:
            self.logger.error(f"Error loading performance stats: {e}")
    
    def trading_loop(self):
        """Main trading loop"""
        try:
            self.logger.info("Starting trading loop...")
            
            symbols = self.config['trading']['symbols']
            confidence_threshold = self.config['trading']['confidence_threshold']
            
            while self.is_trading:
                try:
                    # Check trading hours
                    if not self.check_trading_hours():
                        self.logger.info("Outside trading hours - sleeping...")
                        time.sleep(300)  # Sleep 5 minutes
                        continue
                    
                    # Check if trading should be stopped due to risk limits
                    should_stop, reason = self.risk_manager.should_stop_trading()
                    if should_stop:
                        self.logger.warning(f"Trading stopped: {reason}")
                        self.send_telegram_alert(f"🛑 *Trading Stopped*\n\n{reason}", "ERROR")
                        self.stop_trading()
                        break
                    
                    # Process each symbol
                    for symbol in symbols:
                        try:
                            if not self.is_trading:
                                break
                            
                            # Get market data for multiple timeframes
                            df_m15 = self.trading_bot.get_market_data('M15', 200)
                            df_h1 = self.trading_bot.get_market_data('H1', 200)
                            df_h4 = self.trading_bot.get_market_data('H4', 200)
                            df_d1 = self.trading_bot.get_market_data('D1', 100)
                            
                            if any(df.empty for df in [df_m15, df_h1, df_h4, df_d1]):
                                self.logger.warning(f"Failed to get data for {symbol}")
                                continue
                            
                            # Calculate indicators
                            df_m15 = self.trading_bot.calculate_technical_indicators(df_m15)
                            df_h1 = self.trading_bot.calculate_technical_indicators(df_h1)
                            df_h4 = self.trading_bot.calculate_technical_indicators(df_h4)
                            df_d1 = self.trading_bot.calculate_technical_indicators(df_d1)
                            
                            # Generate signal
                            signal = self.trading_bot.advanced_signal_generation(
                                df_m15, df_h1, df_h4, df_d1
                            )
                            
                            self.logger.info(f"{symbol} Signal: {signal['action']} | "
                                           f"Confidence: {signal['confidence']:.1f}% | "
                                           f"Strength: {signal['strength']:.2f}")
                            
                            # Execute trade if confidence is high enough
                            if (signal['confidence'] >= confidence_threshold and 
                                signal['action'] in ['BUY', 'SELL']):
                                
                                # Check with risk manager
                                volatility = df_m15['ATR'].iloc[-1] / df_m15['close'].iloc[-1]
                                position_size = self.risk_manager.calculate_position_size(
                                    symbol, signal['entry_price'], signal['stop_loss'],
                                    self.risk_manager.current_balance, volatility
                                )
                                
                                can_open, reason = self.risk_manager.can_open_position(
                                    symbol, position_size, signal['entry_price']
                                )
                                
                                if can_open:
                                    # Execute trade
                                    if self.trading_bot.execute_trade(signal):
                                        # Update risk manager
                                        self.risk_manager.add_position(
                                            symbol, position_size, signal['entry_price'],
                                            signal['stop_loss'], signal['take_profit'],
                                            signal['action']
                                        )
                                        
                                        # Send trade alert
                                        message = f"💰 *Trade Executed*\n\n"
                                        message += f"Symbol: {symbol}\n"
                                        message += f"Action: {signal['action']}\n"
                                        message += f"Size: {position_size:.2f} lots\n"
                                        message += f"Entry: {signal['entry_price']:.5f}\n"
                                        message += f"SL: {signal['stop_loss']:.5f}\n"
                                        message += f"TP: {signal['take_profit']:.5f}\n"
                                        message += f"Confidence: {signal['confidence']:.1f}%"
                                        
                                        self.send_telegram_alert(message, "TRADE")
                                        
                                        trade_logger = logging.getLogger('trades')
                                        trade_logger.info(f"Trade executed: {symbol} {signal['action']} "
                                                        f"{position_size} lots at {signal['entry_price']}")
                                else:
                                    self.logger.info(f"Trade rejected for {symbol}: {reason}")
                            
                        except Exception as e:
                            self.logger.error(f"Error processing {symbol}: {e}")
                            continue
                    
                    # Monitor existing positions
                    self.trading_bot.monitor_positions()
                    
                    # Sleep before next iteration
                    time.sleep(self.config['monitoring']['update_interval'])
                    
                except Exception as e:
                    self.logger.error(f"Error in trading loop: {e}")
                    time.sleep(60)  # Sleep 1 minute on error
                    
        except Exception as e:
            self.logger.error(f"Critical error in trading loop: {e}")
        finally:
            self.logger.info("Trading loop stopped")
    
    def monitoring_loop(self):
        """Performance monitoring loop"""
        try:
            self.logger.info("Starting monitoring loop...")
            
            while self.is_trading:
                try:
                    # Monitor performance
                    self.monitor_performance()
                    
                    # Sleep for monitoring interval
                    time.sleep(self.config['monitoring']['update_interval'])
                    
                except Exception as e:
                    self.logger.error(f"Error in monitoring loop: {e}")
                    time.sleep(60)
                    
        except Exception as e:
            self.logger.error(f"Critical error in monitoring loop: {e}")
        finally:
            self.logger.info("Monitoring loop stopped")
    
    def start_trading(self, run_validation: bool = True):
        """Start live trading"""
        try:
            if self.is_trading:
                self.logger.warning("Trading is already running")
                return False
            
            self.logger.info("Starting live trading...")
            
            # Initialize MT5 connection
            if not self.trading_bot.initialize_mt5():
                self.logger.error("Failed to initialize MT5 connection")
                return False
            
            # Run backtest validation if requested
            if run_validation:
                for symbol in self.config['trading']['symbols']:
                    validation_results = self.run_backtest_validation(symbol, 30)
                    if not validation_results:
                        self.logger.warning(f"Backtest validation failed for {symbol}")
            
            # Load performance statistics
            self.load_performance_stats()
            
            # Start trading
            self.is_trading = True
            
            # Start trading thread
            self.trading_thread = threading.Thread(target=self.trading_loop, daemon=True)
            self.trading_thread.start()
            
            # Start monitoring thread
            self.monitoring_thread = threading.Thread(target=self.monitoring_loop, daemon=True)
            self.monitoring_thread.start()
            
            # Send start notification
            message = f"🚀 *Forex Trading Bot Started*\n\n"
            message += f"Symbols: {', '.join(self.config['trading']['symbols'])}\n"
            message += f"Confidence Threshold: {self.config['trading']['confidence_threshold']}%\n"
            message += f"Max Risk per Trade: {self.config['risk']['max_risk_per_trade']*100:.1f}%\n"
            message += f"Max Daily Loss: {self.config['risk']['max_daily_loss']*100:.1f}%"
            
            self.send_telegram_alert(message, "SUCCESS")
            
            self.logger.info("Live trading started successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Error starting trading: {e}")
            return False
    
    def stop_trading(self):
        """Stop live trading"""
        try:
            if not self.is_trading:
                self.logger.warning("Trading is not running")
                return
            
            self.logger.info("Stopping live trading...")
            
            # Stop trading flag
            self.is_trading = False
            
            # Wait for threads to finish
            if self.trading_thread and self.trading_thread.is_alive():
                self.trading_thread.join(timeout=10)
            
            if self.monitoring_thread and self.monitoring_thread.is_alive():
                self.monitoring_thread.join(timeout=10)
            
            # Close MT5 connection
            mt5.shutdown()
            
            # Send stop notification
            if self.risk_manager:
                portfolio_metrics = self.risk_manager.get_portfolio_metrics()
                
                message = f"🛑 *Forex Trading Bot Stopped*\n\n"
                message += f"Final Balance: ${portfolio_metrics.get('current_balance', 0):,.2f}\n"
                message += f"Total Trades: {portfolio_metrics.get('total_trades', 0)}\n"
                message += f"Win Rate: {portfolio_metrics.get('win_rate', 0):.1f}%\n"
                message += f"Current Drawdown: {portfolio_metrics.get('current_drawdown', 0):.2f}%"
                
                self.send_telegram_alert(message, "INFO")
            
            self.logger.info("Live trading stopped successfully")
            
        except Exception as e:
            self.logger.error(f"Error stopping trading: {e}")
    
    def get_status(self) -> Dict:
        """Get current trading status"""
        try:
            if not self.risk_manager:
                return {"status": "Not initialized"}
            
            portfolio_metrics = self.risk_manager.get_portfolio_metrics()
            risk_summary = self.risk_manager.get_risk_summary()
            
            return {
                "is_trading": self.is_trading,
                "current_balance": portfolio_metrics.get('current_balance', 0),
                "total_trades": portfolio_metrics.get('total_trades', 0),
                "win_rate": portfolio_metrics.get('win_rate', 0),
                "profit_factor": portfolio_metrics.get('profit_factor', 0),
                "current_drawdown": portfolio_metrics.get('current_drawdown', 0),
                "daily_risk": risk_summary.get('daily_risk', 0),
                "open_positions": risk_summary.get('open_positions', 0),
                "symbols": self.config['trading']['symbols'],
                "confidence_threshold": self.config['trading']['confidence_threshold']
            }
            
        except Exception as e:
            self.logger.error(f"Error getting status: {e}")
            return {"status": "Error"}
    
    def generate_daily_report(self):
        """Generate and send daily performance report"""
        try:
            if not self.risk_manager:
                return
            
            portfolio_metrics = self.risk_manager.get_portfolio_metrics()
            risk_summary = self.risk_manager.get_risk_summary()
            
            # Create daily report
            report = f"📊 *Daily Trading Report*\n"
            report += f"Date: {datetime.now().strftime('%Y-%m-%d')}\n\n"
            
            report += f"*PERFORMANCE:*\n"
            report += f"Current Balance: ${portfolio_metrics.get('current_balance', 0):,.2f}\n"
            report += f"Total Trades: {portfolio_metrics.get('total_trades', 0)}\n"
            report += f"Win Rate: {portfolio_metrics.get('win_rate', 0):.1f}%\n"
            report += f"Profit Factor: {portfolio_metrics.get('profit_factor', 0):.2f}\n\n"
            
            report += f"*RISK:*\n"
            report += f"Current Drawdown: {portfolio_metrics.get('current_drawdown', 0):.2f}%\n"
            report += f"Daily Risk: {risk_summary.get('daily_risk', 0):.2f}%\n"
            report += f"Open Positions: {risk_summary.get('open_positions', 0)}\n\n"
            
            if portfolio_metrics.get('total_trades', 0) > 0:
                report += f"*TRADE STATS:*\n"
                report += f"Avg Win: ${portfolio_metrics.get('average_win', 0):.2f}\n"
                report += f"Avg Loss: ${portfolio_metrics.get('average_loss', 0):.2f}\n"
                report += f"Largest Win: ${portfolio_metrics.get('largest_win', 0):.2f}\n"
                report += f"Largest Loss: ${portfolio_metrics.get('largest_loss', 0):.2f}\n"
            
            self.send_telegram_alert(report, "INFO")
            
        except Exception as e:
            self.logger.error(f"Error generating daily report: {e}")

# Example usage and CLI interface
if __name__ == "__main__":
    import sys
    
    def main():
        # Create live trader
        trader = LiveForexTrader("trading_config.json")
        
        if len(sys.argv) > 1:
            command = sys.argv[1].lower()
            
            if command == "start":
                trader.start_trading()
                
                # Keep running until interrupted
                try:
                    while trader.is_trading:
                        time.sleep(1)
                except KeyboardInterrupt:
                    print("\nShutting down...")
                    trader.stop_trading()
                    
            elif command == "stop":
                trader.stop_trading()
                
            elif command == "status":
                status = trader.get_status()
                print(json.dumps(status, indent=2))
                
            elif command == "report":
                trader.generate_daily_report()
                
            elif command == "backtest":
                symbol = sys.argv[2] if len(sys.argv) > 2 else "EURUSD"
                results = trader.run_backtest_validation(symbol, 30)
                print(json.dumps(results, indent=2))
                
            else:
                print("Usage: python live_trader.py [start|stop|status|report|backtest]")
        else:
            print("Usage: python live_trader.py [start|stop|status|report|backtest]")
    
    main()