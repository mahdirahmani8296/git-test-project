import pandas as pd
import numpy as np
import MetaTrader5 as mt5
import talib
from datetime import datetime, timedelta
import logging
import json
import time
from typing import Dict, List, Tuple, Optional
import warnings
warnings.filterwarnings('ignore')

class AdvancedForexTradingBot:
    """
    Advanced Forex Trading Bot with Multi-Strategy Approach
    استراتژی پیشرفته معاملات فارکس با دقت بالا
    """
    
    def __init__(self, account: int, password: str, server: str, symbol: str = "EURUSD"):
        """
        Initialize the trading bot
        
        Args:
            account: MT5 account number
            password: MT5 password
            server: MT5 server name
            symbol: Trading symbol (default: EURUSD)
        """
        self.account = account
        self.password = password
        self.server = server
        self.symbol = symbol
        
        # Trading parameters
        self.lot_size = 0.1
        self.max_risk_per_trade = 0.02  # 2% risk per trade
        self.max_daily_loss = 0.05      # 5% max daily loss
        self.target_profit_ratio = 2.0   # Risk:Reward = 1:2
        
        # Strategy parameters
        self.timeframes = {
            'M15': mt5.TIMEFRAME_M15,
            'H1': mt5.TIMEFRAME_H1,
            'H4': mt5.TIMEFRAME_H4,
            'D1': mt5.TIMEFRAME_D1
        }
        
        # Performance tracking
        self.trades_today = []
        self.daily_pnl = 0.0
        self.total_trades = 0
        self.winning_trades = 0
        
        # Setup logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('forex_bot.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
        
    def initialize_mt5(self) -> bool:
        """Initialize MT5 connection"""
        try:
            if not mt5.initialize():
                self.logger.error(f"MT5 initialization failed: {mt5.last_error()}")
                return False
                
            if not mt5.login(self.account, self.password, self.server):
                self.logger.error(f"MT5 login failed: {mt5.last_error()}")
                return False
                
            self.logger.info("MT5 connection established successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"MT5 initialization error: {e}")
            return False
    
    def get_market_data(self, timeframe: str, count: int = 500) -> pd.DataFrame:
        """Get market data for analysis"""
        try:
            rates = mt5.copy_rates_from_pos(
                self.symbol, 
                self.timeframes[timeframe], 
                0, 
                count
            )
            
            if rates is None:
                self.logger.error(f"Failed to get market data: {mt5.last_error()}")
                return pd.DataFrame()
                
            df = pd.DataFrame(rates)
            df['time'] = pd.to_datetime(df['time'], unit='s')
            df.set_index('time', inplace=True)
            
            return df
            
        except Exception as e:
            self.logger.error(f"Error getting market data: {e}")
            return pd.DataFrame()
    
    def calculate_technical_indicators(self, df: pd.DataFrame) -> pd.DataFrame:
        """Calculate comprehensive technical indicators"""
        try:
            # Price data
            high = df['high'].values
            low = df['low'].values
            close = df['close'].values
            volume = df['tick_volume'].values
            
            # Moving Averages
            df['EMA_9'] = talib.EMA(close, timeperiod=9)
            df['EMA_21'] = talib.EMA(close, timeperiod=21)
            df['EMA_50'] = talib.EMA(close, timeperiod=50)
            df['EMA_200'] = talib.EMA(close, timeperiod=200)
            
            df['SMA_20'] = talib.SMA(close, timeperiod=20)
            df['SMA_50'] = talib.SMA(close, timeperiod=50)
            
            # MACD
            df['MACD'], df['MACD_signal'], df['MACD_hist'] = talib.MACD(close)
            
            # RSI
            df['RSI'] = talib.RSI(close, timeperiod=14)
            df['RSI_9'] = talib.RSI(close, timeperiod=9)
            
            # Stochastic
            df['Stoch_K'], df['Stoch_D'] = talib.STOCH(high, low, close)
            
            # Bollinger Bands
            df['BB_upper'], df['BB_middle'], df['BB_lower'] = talib.BBANDS(close)
            
            # ATR for volatility
            df['ATR'] = talib.ATR(high, low, close, timeperiod=14)
            
            # ADX for trend strength
            df['ADX'] = talib.ADX(high, low, close, timeperiod=14)
            df['DI_plus'] = talib.PLUS_DI(high, low, close, timeperiod=14)
            df['DI_minus'] = talib.MINUS_DI(high, low, close, timeperiod=14)
            
            # Williams %R
            df['Williams_R'] = talib.WILLR(high, low, close, timeperiod=14)
            
            # CCI
            df['CCI'] = talib.CCI(high, low, close, timeperiod=14)
            
            # Parabolic SAR
            df['SAR'] = talib.SAR(high, low)
            
            # Volume indicators
            df['OBV'] = talib.OBV(close, volume)
            df['AD'] = talib.AD(high, low, close, volume)
            
            # Support and Resistance levels
            df = self.calculate_support_resistance(df)
            
            return df
            
        except Exception as e:
            self.logger.error(f"Error calculating indicators: {e}")
            return df
    
    def calculate_support_resistance(self, df: pd.DataFrame, window: int = 20) -> pd.DataFrame:
        """Calculate dynamic support and resistance levels"""
        try:
            df['Support'] = df['low'].rolling(window=window).min()
            df['Resistance'] = df['high'].rolling(window=window).max()
            
            # Pivot points
            df['Pivot'] = (df['high'] + df['low'] + df['close']) / 3
            df['R1'] = 2 * df['Pivot'] - df['low']
            df['S1'] = 2 * df['Pivot'] - df['high']
            df['R2'] = df['Pivot'] + (df['high'] - df['low'])
            df['S2'] = df['Pivot'] - (df['high'] - df['low'])
            
            return df
            
        except Exception as e:
            self.logger.error(f"Error calculating support/resistance: {e}")
            return df
    
    def advanced_signal_generation(self, df_m15: pd.DataFrame, df_h1: pd.DataFrame, 
                                 df_h4: pd.DataFrame, df_d1: pd.DataFrame) -> Dict:
        """
        Advanced multi-timeframe signal generation
        تولید سیگنال پیشرفته با تحلیل چند تایم فریم
        """
        try:
            signal = {
                'action': 'HOLD',
                'strength': 0,
                'entry_price': 0,
                'stop_loss': 0,
                'take_profit': 0,
                'confidence': 0,
                'reasons': []
            }
            
            # Current price
            current_price = df_m15['close'].iloc[-1]
            signal['entry_price'] = current_price
            
            # Multi-timeframe trend analysis
            trend_score = self.analyze_trend(df_m15, df_h1, df_h4, df_d1)
            
            # Momentum analysis
            momentum_score = self.analyze_momentum(df_m15, df_h1)
            
            # Volume analysis
            volume_score = self.analyze_volume(df_m15, df_h1)
            
            # Support/Resistance analysis
            sr_score = self.analyze_support_resistance(df_m15, df_h4)
            
            # Market structure analysis
            structure_score = self.analyze_market_structure(df_m15, df_h1, df_h4)
            
            # Combine all scores
            total_score = (trend_score * 0.3 + momentum_score * 0.25 + 
                          volume_score * 0.15 + sr_score * 0.15 + structure_score * 0.15)
            
            signal['strength'] = total_score
            signal['confidence'] = min(abs(total_score) * 10, 100)
            
            # Generate trading decision
            if total_score > 0.6:
                signal['action'] = 'BUY'
                signal['stop_loss'] = current_price - (df_m15['ATR'].iloc[-1] * 2)
                signal['take_profit'] = current_price + (df_m15['ATR'].iloc[-1] * 4)
            elif total_score < -0.6:
                signal['action'] = 'SELL'
                signal['stop_loss'] = current_price + (df_m15['ATR'].iloc[-1] * 2)
                signal['take_profit'] = current_price - (df_m15['ATR'].iloc[-1] * 4)
            
            return signal
            
        except Exception as e:
            self.logger.error(f"Error in signal generation: {e}")
            return signal
    
    def analyze_trend(self, df_m15: pd.DataFrame, df_h1: pd.DataFrame, 
                     df_h4: pd.DataFrame, df_d1: pd.DataFrame) -> float:
        """Analyze multi-timeframe trend"""
        try:
            trend_score = 0
            
            # Daily trend (highest weight)
            if df_d1['EMA_21'].iloc[-1] > df_d1['EMA_50'].iloc[-1]:
                trend_score += 0.4
            elif df_d1['EMA_21'].iloc[-1] < df_d1['EMA_50'].iloc[-1]:
                trend_score -= 0.4
                
            # H4 trend
            if df_h4['EMA_21'].iloc[-1] > df_h4['EMA_50'].iloc[-1]:
                trend_score += 0.3
            elif df_h4['EMA_21'].iloc[-1] < df_h4['EMA_50'].iloc[-1]:
                trend_score -= 0.3
                
            # H1 trend
            if df_h1['EMA_9'].iloc[-1] > df_h1['EMA_21'].iloc[-1]:
                trend_score += 0.2
            elif df_h1['EMA_9'].iloc[-1] < df_h1['EMA_21'].iloc[-1]:
                trend_score -= 0.2
                
            # M15 trend confirmation
            if df_m15['EMA_9'].iloc[-1] > df_m15['EMA_21'].iloc[-1]:
                trend_score += 0.1
            elif df_m15['EMA_9'].iloc[-1] < df_m15['EMA_21'].iloc[-1]:
                trend_score -= 0.1
                
            return trend_score
            
        except Exception as e:
            self.logger.error(f"Error in trend analysis: {e}")
            return 0
    
    def analyze_momentum(self, df_m15: pd.DataFrame, df_h1: pd.DataFrame) -> float:
        """Analyze momentum indicators"""
        try:
            momentum_score = 0
            
            # RSI analysis
            rsi_m15 = df_m15['RSI'].iloc[-1]
            rsi_h1 = df_h1['RSI'].iloc[-1]
            
            if 30 < rsi_m15 < 70 and 30 < rsi_h1 < 70:
                if rsi_m15 > 50 and rsi_h1 > 50:
                    momentum_score += 0.3
                elif rsi_m15 < 50 and rsi_h1 < 50:
                    momentum_score -= 0.3
            
            # MACD analysis
            macd_m15 = df_m15['MACD'].iloc[-1]
            macd_signal_m15 = df_m15['MACD_signal'].iloc[-1]
            macd_h1 = df_h1['MACD'].iloc[-1]
            macd_signal_h1 = df_h1['MACD_signal'].iloc[-1]
            
            if macd_m15 > macd_signal_m15 and macd_h1 > macd_signal_h1:
                momentum_score += 0.3
            elif macd_m15 < macd_signal_m15 and macd_h1 < macd_signal_h1:
                momentum_score -= 0.3
            
            # Stochastic analysis
            stoch_k_m15 = df_m15['Stoch_K'].iloc[-1]
            stoch_d_m15 = df_m15['Stoch_D'].iloc[-1]
            
            if stoch_k_m15 > stoch_d_m15 and stoch_k_m15 > 20 and stoch_k_m15 < 80:
                momentum_score += 0.2
            elif stoch_k_m15 < stoch_d_m15 and stoch_k_m15 > 20 and stoch_k_m15 < 80:
                momentum_score -= 0.2
            
            # Williams %R
            williams_r = df_m15['Williams_R'].iloc[-1]
            if -80 < williams_r < -20:
                if williams_r > -50:
                    momentum_score += 0.2
                else:
                    momentum_score -= 0.2
            
            return momentum_score
            
        except Exception as e:
            self.logger.error(f"Error in momentum analysis: {e}")
            return 0
    
    def analyze_volume(self, df_m15: pd.DataFrame, df_h1: pd.DataFrame) -> float:
        """Analyze volume indicators"""
        try:
            volume_score = 0
            
            # OBV trend
            obv_m15 = df_m15['OBV'].iloc[-5:].diff().mean()
            obv_h1 = df_h1['OBV'].iloc[-3:].diff().mean()
            
            if obv_m15 > 0 and obv_h1 > 0:
                volume_score += 0.5
            elif obv_m15 < 0 and obv_h1 < 0:
                volume_score -= 0.5
            
            # Volume spike detection
            avg_volume_m15 = df_m15['tick_volume'].iloc[-20:-1].mean()
            current_volume_m15 = df_m15['tick_volume'].iloc[-1]
            
            if current_volume_m15 > avg_volume_m15 * 1.5:
                # High volume confirms the move
                price_change = (df_m15['close'].iloc[-1] - df_m15['close'].iloc[-2]) / df_m15['close'].iloc[-2]
                if price_change > 0:
                    volume_score += 0.3
                else:
                    volume_score -= 0.3
            
            return volume_score
            
        except Exception as e:
            self.logger.error(f"Error in volume analysis: {e}")
            return 0
    
    def analyze_support_resistance(self, df_m15: pd.DataFrame, df_h4: pd.DataFrame) -> float:
        """Analyze support and resistance levels"""
        try:
            sr_score = 0
            current_price = df_m15['close'].iloc[-1]
            
            # Distance from support/resistance
            support_h4 = df_h4['Support'].iloc[-1]
            resistance_h4 = df_h4['Resistance'].iloc[-1]
            
            support_distance = (current_price - support_h4) / current_price
            resistance_distance = (resistance_h4 - current_price) / current_price
            
            # Favor trades away from strong S/R levels
            if support_distance > 0.002:  # 20 pips away from support
                sr_score += 0.3
            if resistance_distance > 0.002:  # 20 pips away from resistance
                sr_score -= 0.3
            
            # Bollinger Bands position
            bb_upper = df_m15['BB_upper'].iloc[-1]
            bb_lower = df_m15['BB_lower'].iloc[-1]
            bb_middle = df_m15['BB_middle'].iloc[-1]
            
            bb_position = (current_price - bb_lower) / (bb_upper - bb_lower)
            
            if 0.2 < bb_position < 0.4:  # Near lower band but not extreme
                sr_score += 0.4
            elif 0.6 < bb_position < 0.8:  # Near upper band but not extreme
                sr_score -= 0.4
            
            return sr_score
            
        except Exception as e:
            self.logger.error(f"Error in S/R analysis: {e}")
            return 0
    
    def analyze_market_structure(self, df_m15: pd.DataFrame, df_h1: pd.DataFrame, 
                               df_h4: pd.DataFrame) -> float:
        """Analyze market structure and price action"""
        try:
            structure_score = 0
            
            # ADX trend strength
            adx_h1 = df_h1['ADX'].iloc[-1]
            adx_h4 = df_h4['ADX'].iloc[-1]
            
            if adx_h1 > 25 and adx_h4 > 25:  # Strong trend
                di_plus_h1 = df_h1['DI_plus'].iloc[-1]
                di_minus_h1 = df_h1['DI_minus'].iloc[-1]
                
                if di_plus_h1 > di_minus_h1:
                    structure_score += 0.4
                else:
                    structure_score -= 0.4
            
            # Price action patterns
            # Higher highs and higher lows (uptrend)
            recent_highs = df_h1['high'].iloc[-5:]
            recent_lows = df_h1['low'].iloc[-5:]
            
            if recent_highs.iloc[-1] > recent_highs.iloc[-3] and recent_lows.iloc[-1] > recent_lows.iloc[-3]:
                structure_score += 0.3
            elif recent_highs.iloc[-1] < recent_highs.iloc[-3] and recent_lows.iloc[-1] < recent_lows.iloc[-3]:
                structure_score -= 0.3
            
            # Parabolic SAR
            sar_m15 = df_m15['SAR'].iloc[-1]
            current_price = df_m15['close'].iloc[-1]
            
            if current_price > sar_m15:
                structure_score += 0.3
            else:
                structure_score -= 0.3
            
            return structure_score
            
        except Exception as e:
            self.logger.error(f"Error in structure analysis: {e}")
            return 0
    
    def calculate_position_size(self, stop_loss_pips: float, account_balance: float) -> float:
        """Calculate optimal position size based on risk management"""
        try:
            risk_amount = account_balance * self.max_risk_per_trade
            pip_value = 10  # For EURUSD, 1 pip = $10 for 1 lot
            
            if stop_loss_pips > 0:
                position_size = risk_amount / (stop_loss_pips * pip_value)
                return min(position_size, 1.0)  # Max 1 lot
            
            return self.lot_size
            
        except Exception as e:
            self.logger.error(f"Error calculating position size: {e}")
            return self.lot_size
    
    def execute_trade(self, signal: Dict) -> bool:
        """Execute trade based on signal"""
        try:
            if signal['action'] == 'HOLD':
                return False
            
            # Get account info
            account_info = mt5.account_info()
            if account_info is None:
                self.logger.error("Failed to get account info")
                return False
            
            # Check daily loss limit
            if abs(self.daily_pnl) >= account_info.balance * self.max_daily_loss:
                self.logger.warning("Daily loss limit reached. No new trades.")
                return False
            
            # Calculate position size
            stop_loss_pips = abs(signal['entry_price'] - signal['stop_loss']) * 10000
            position_size = self.calculate_position_size(stop_loss_pips, account_info.balance)
            
            # Prepare trade request
            trade_type = mt5.ORDER_TYPE_BUY if signal['action'] == 'BUY' else mt5.ORDER_TYPE_SELL
            
            request = {
                "action": mt5.TRADE_ACTION_DEAL,
                "symbol": self.symbol,
                "volume": position_size,
                "type": trade_type,
                "price": signal['entry_price'],
                "sl": signal['stop_loss'],
                "tp": signal['take_profit'],
                "deviation": 10,
                "magic": 123456,
                "comment": f"Advanced Bot - Confidence: {signal['confidence']:.1f}%",
                "type_time": mt5.ORDER_TIME_GTC,
                "type_filling": mt5.ORDER_FILLING_IOC,
            }
            
            # Send trade request
            result = mt5.order_send(request)
            
            if result.retcode != mt5.TRADE_RETCODE_DONE:
                self.logger.error(f"Trade failed: {result.retcode} - {result.comment}")
                return False
            
            # Log successful trade
            self.logger.info(f"Trade executed: {signal['action']} {position_size} lots at {signal['entry_price']}")
            self.logger.info(f"SL: {signal['stop_loss']}, TP: {signal['take_profit']}, Confidence: {signal['confidence']:.1f}%")
            
            # Update statistics
            self.total_trades += 1
            self.trades_today.append({
                'time': datetime.now(),
                'action': signal['action'],
                'volume': position_size,
                'price': signal['entry_price'],
                'sl': signal['stop_loss'],
                'tp': signal['take_profit'],
                'confidence': signal['confidence']
            })
            
            return True
            
        except Exception as e:
            self.logger.error(f"Error executing trade: {e}")
            return False
    
    def monitor_positions(self):
        """Monitor open positions and update statistics"""
        try:
            positions = mt5.positions_get(symbol=self.symbol)
            
            if positions is None:
                return
            
            for position in positions:
                # Check for position updates
                if position.profit != 0:
                    self.daily_pnl += position.profit
            
            # Update win rate
            history_deals = mt5.history_deals_get(
                datetime.now().replace(hour=0, minute=0, second=0),
                datetime.now()
            )
            
            if history_deals:
                today_deals = [deal for deal in history_deals if deal.symbol == self.symbol]
                profitable_deals = [deal for deal in today_deals if deal.profit > 0]
                
                if len(today_deals) > 0:
                    self.winning_trades = len(profitable_deals)
                    win_rate = (self.winning_trades / len(today_deals)) * 100
                    self.logger.info(f"Today's Win Rate: {win_rate:.1f}% ({self.winning_trades}/{len(today_deals)})")
            
        except Exception as e:
            self.logger.error(f"Error monitoring positions: {e}")
    
    def run_strategy(self):
        """Main strategy execution loop"""
        try:
            self.logger.info("Starting Advanced Forex Trading Bot...")
            
            if not self.initialize_mt5():
                return
            
            while True:
                try:
                    # Get multi-timeframe data
                    df_m15 = self.get_market_data('M15', 200)
                    df_h1 = self.get_market_data('H1', 200)
                    df_h4 = self.get_market_data('H4', 200)
                    df_d1 = self.get_market_data('D1', 100)
                    
                    if any(df.empty for df in [df_m15, df_h1, df_h4, df_d1]):
                        self.logger.warning("Failed to get market data, retrying...")
                        time.sleep(60)
                        continue
                    
                    # Calculate indicators for all timeframes
                    df_m15 = self.calculate_technical_indicators(df_m15)
                    df_h1 = self.calculate_technical_indicators(df_h1)
                    df_h4 = self.calculate_technical_indicators(df_h4)
                    df_d1 = self.calculate_technical_indicators(df_d1)
                    
                    # Generate trading signal
                    signal = self.advanced_signal_generation(df_m15, df_h1, df_h4, df_d1)
                    
                    # Log signal information
                    self.logger.info(f"Signal: {signal['action']} | Strength: {signal['strength']:.2f} | Confidence: {signal['confidence']:.1f}%")
                    
                    # Execute trade if signal is strong enough
                    if signal['confidence'] >= 75:  # High confidence threshold
                        self.execute_trade(signal)
                    
                    # Monitor existing positions
                    self.monitor_positions()
                    
                    # Wait before next analysis (15 minutes)
                    time.sleep(900)
                    
                except KeyboardInterrupt:
                    self.logger.info("Bot stopped by user")
                    break
                except Exception as e:
                    self.logger.error(f"Error in main loop: {e}")
                    time.sleep(60)
                    
        except Exception as e:
            self.logger.error(f"Critical error: {e}")
        finally:
            mt5.shutdown()
            self.logger.info("MT5 connection closed")

# Example usage
if __name__ == "__main__":
    # Configuration - Replace with your MT5 credentials
    ACCOUNT = 12345678  # Your MT5 account number
    PASSWORD = "your_password"  # Your MT5 password
    SERVER = "MetaQuotes-Demo"  # Your broker's server
    SYMBOL = "EURUSD"  # Trading symbol
    
    # Create and run the bot
    bot = AdvancedForexTradingBot(ACCOUNT, PASSWORD, SERVER, SYMBOL)
    bot.run_strategy()