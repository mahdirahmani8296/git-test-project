import pandas as pd
import numpy as np
import yfinance as yf
import talib
from datetime import datetime, timedelta
import matplotlib.pyplot as plt
import seaborn as sns
from typing import Dict, List, Tuple, Optional
import logging
import warnings
warnings.filterwarnings('ignore')

from risk_manager import AdvancedRiskManager

class ForexBacktester:
    """
    Comprehensive Forex Strategy Backtester
    بک‌تستر جامع استراتژی فارکس
    """
    
    def __init__(self, initial_balance: float = 10000):
        """
        Initialize the backtester
        
        Args:
            initial_balance: Starting balance for backtesting
        """
        self.initial_balance = initial_balance
        self.current_balance = initial_balance
        
        # Risk manager
        self.risk_manager = AdvancedRiskManager(initial_balance)
        
        # Backtest results
        self.trades = []
        self.equity_curve = []
        self.daily_returns = []
        self.performance_metrics = {}
        
        # Setup logging
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
    
    def get_forex_data(self, symbol: str, start_date: str, end_date: str, 
                      interval: str = '15m') -> pd.DataFrame:
        """
        Get forex data using yfinance (for major pairs)
        دریافت داده‌های فارکس با استفاده از yfinance
        """
        try:
            # Convert forex symbol to Yahoo Finance format
            if symbol == 'EURUSD':
                yahoo_symbol = 'EURUSD=X'
            elif symbol == 'GBPUSD':
                yahoo_symbol = 'GBPUSD=X'
            elif symbol == 'USDJPY':
                yahoo_symbol = 'USDJPY=X'
            elif symbol == 'USDCHF':
                yahoo_symbol = 'USDCHF=X'
            elif symbol == 'AUDUSD':
                yahoo_symbol = 'AUDUSD=X'
            elif symbol == 'USDCAD':
                yahoo_symbol = 'USDCAD=X'
            else:
                yahoo_symbol = f'{symbol}=X'
            
            # Download data
            data = yf.download(yahoo_symbol, start=start_date, end=end_date, 
                             interval=interval, progress=False)
            
            if data.empty:
                self.logger.error(f"No data found for {symbol}")
                return pd.DataFrame()
            
            # Rename columns to match our format
            data.columns = ['open', 'high', 'low', 'close', 'adj_close', 'volume']
            data = data.drop('adj_close', axis=1)
            
            # Add tick_volume (simulate)
            data['tick_volume'] = data['volume'].fillna(1000)
            
            return data
            
        except Exception as e:
            self.logger.error(f"Error getting forex data: {e}")
            return pd.DataFrame()
    
    def calculate_technical_indicators(self, df: pd.DataFrame) -> pd.DataFrame:
        """Calculate technical indicators (same as main bot)"""
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
    
    def generate_signals(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Generate trading signals using the same logic as main bot
        تولید سیگنال‌های معاملاتی با همان منطق ربات اصلی
        """
        try:
            signals = []
            
            for i in range(100, len(df)):  # Start after indicators are calculated
                try:
                    current_data = df.iloc[i-50:i+1]  # Get recent data for analysis
                    
                    if len(current_data) < 50:
                        signals.append({
                            'action': 'HOLD',
                            'strength': 0,
                            'confidence': 0,
                            'entry_price': df.iloc[i]['close'],
                            'stop_loss': 0,
                            'take_profit': 0
                        })
                        continue
                    
                    # Simplified multi-timeframe analysis for backtesting
                    signal = self.analyze_signal(current_data)
                    signals.append(signal)
                    
                except Exception as e:
                    signals.append({
                        'action': 'HOLD',
                        'strength': 0,
                        'confidence': 0,
                        'entry_price': df.iloc[i]['close'],
                        'stop_loss': 0,
                        'take_profit': 0
                    })
            
            # Add signals to dataframe
            signal_df = pd.DataFrame(signals, index=df.index[100:])
            df = df.iloc[100:].copy()  # Align indices
            
            for col in signal_df.columns:
                df[f'signal_{col}'] = signal_df[col]
            
            return df
            
        except Exception as e:
            self.logger.error(f"Error generating signals: {e}")
            return df
    
    def analyze_signal(self, data: pd.DataFrame) -> Dict:
        """Analyze current market conditions and generate signal"""
        try:
            current_price = data['close'].iloc[-1]
            
            # Trend analysis
            trend_score = 0
            if data['EMA_9'].iloc[-1] > data['EMA_21'].iloc[-1]:
                trend_score += 0.3
            elif data['EMA_9'].iloc[-1] < data['EMA_21'].iloc[-1]:
                trend_score -= 0.3
                
            if data['EMA_21'].iloc[-1] > data['EMA_50'].iloc[-1]:
                trend_score += 0.4
            elif data['EMA_21'].iloc[-1] < data['EMA_50'].iloc[-1]:
                trend_score -= 0.4
            
            # Momentum analysis
            momentum_score = 0
            rsi = data['RSI'].iloc[-1]
            if 30 < rsi < 70:
                if rsi > 50:
                    momentum_score += 0.3
                else:
                    momentum_score -= 0.3
            
            # MACD
            if data['MACD'].iloc[-1] > data['MACD_signal'].iloc[-1]:
                momentum_score += 0.3
            else:
                momentum_score -= 0.3
            
            # Stochastic
            if data['Stoch_K'].iloc[-1] > data['Stoch_D'].iloc[-1] and data['Stoch_K'].iloc[-1] < 80:
                momentum_score += 0.2
            elif data['Stoch_K'].iloc[-1] < data['Stoch_D'].iloc[-1] and data['Stoch_K'].iloc[-1] > 20:
                momentum_score -= 0.2
            
            # Volume analysis
            volume_score = 0
            if len(data) >= 5:
                obv_trend = data['OBV'].iloc[-5:].diff().mean()
                if obv_trend > 0:
                    volume_score += 0.2
                elif obv_trend < 0:
                    volume_score -= 0.2
            
            # Support/Resistance analysis
            sr_score = 0
            bb_upper = data['BB_upper'].iloc[-1]
            bb_lower = data['BB_lower'].iloc[-1]
            bb_position = (current_price - bb_lower) / (bb_upper - bb_lower)
            
            if 0.2 < bb_position < 0.4:
                sr_score += 0.3
            elif 0.6 < bb_position < 0.8:
                sr_score -= 0.3
            
            # Market structure
            structure_score = 0
            if data['ADX'].iloc[-1] > 25:
                if data['DI_plus'].iloc[-1] > data['DI_minus'].iloc[-1]:
                    structure_score += 0.3
                else:
                    structure_score -= 0.3
            
            # SAR
            if current_price > data['SAR'].iloc[-1]:
                structure_score += 0.2
            else:
                structure_score -= 0.2
            
            # Combine scores
            total_score = (trend_score * 0.3 + momentum_score * 0.25 + 
                          volume_score * 0.15 + sr_score * 0.15 + structure_score * 0.15)
            
            confidence = min(abs(total_score) * 100, 100)
            
            # Generate signal
            signal = {
                'action': 'HOLD',
                'strength': total_score,
                'confidence': confidence,
                'entry_price': current_price,
                'stop_loss': 0,
                'take_profit': 0
            }
            
            if total_score > 0.6:
                signal['action'] = 'BUY'
                signal['stop_loss'] = current_price - (data['ATR'].iloc[-1] * 2)
                signal['take_profit'] = current_price + (data['ATR'].iloc[-1] * 4)
            elif total_score < -0.6:
                signal['action'] = 'SELL'
                signal['stop_loss'] = current_price + (data['ATR'].iloc[-1] * 2)
                signal['take_profit'] = current_price - (data['ATR'].iloc[-1] * 4)
            
            return signal
            
        except Exception as e:
            self.logger.error(f"Error analyzing signal: {e}")
            return {
                'action': 'HOLD',
                'strength': 0,
                'confidence': 0,
                'entry_price': current_price,
                'stop_loss': 0,
                'take_profit': 0
            }
    
    def run_backtest(self, symbol: str, start_date: str, end_date: str,
                    confidence_threshold: float = 75.0) -> Dict:
        """
        Run comprehensive backtest
        اجرای بک‌تست جامع
        """
        try:
            self.logger.info(f"Starting backtest for {symbol} from {start_date} to {end_date}")
            
            # Get data
            df = self.get_forex_data(symbol, start_date, end_date, '15m')
            if df.empty:
                return {}
            
            # Calculate indicators
            df = self.calculate_technical_indicators(df)
            
            # Generate signals
            df = self.generate_signals(df)
            
            # Initialize tracking
            self.trades = []
            self.equity_curve = [self.initial_balance]
            self.current_balance = self.initial_balance
            self.risk_manager = AdvancedRiskManager(self.initial_balance)
            
            open_positions = {}
            
            # Process each bar
            for i, (timestamp, row) in enumerate(df.iterrows()):
                try:
                    current_price = row['close']
                    
                    # Check for position exits first
                    positions_to_close = []
                    for pos_id, position in open_positions.items():
                        should_close = False
                        close_reason = ""
                        
                        if position['type'] == 'BUY':
                            # Check stop loss
                            if current_price <= position['stop_loss']:
                                should_close = True
                                close_reason = "Stop Loss"
                            # Check take profit
                            elif current_price >= position['take_profit']:
                                should_close = True
                                close_reason = "Take Profit"
                        else:  # SELL
                            # Check stop loss
                            if current_price >= position['stop_loss']:
                                should_close = True
                                close_reason = "Stop Loss"
                            # Check take profit
                            elif current_price <= position['take_profit']:
                                should_close = True
                                close_reason = "Take Profit"
                        
                        if should_close:
                            positions_to_close.append((pos_id, close_reason))
                    
                    # Close positions
                    for pos_id, close_reason in positions_to_close:
                        position = open_positions[pos_id]
                        
                        # Calculate P&L
                        if position['type'] == 'BUY':
                            pnl = (current_price - position['entry_price']) * position['size'] * 10
                        else:
                            pnl = (position['entry_price'] - current_price) * position['size'] * 10
                        
                        # Update balance
                        self.current_balance += pnl
                        
                        # Record trade
                        trade_record = {
                            'entry_time': position['entry_time'],
                            'exit_time': timestamp,
                            'symbol': symbol,
                            'type': position['type'],
                            'size': position['size'],
                            'entry_price': position['entry_price'],
                            'exit_price': current_price,
                            'stop_loss': position['stop_loss'],
                            'take_profit': position['take_profit'],
                            'pnl': pnl,
                            'pnl_pct': (pnl / self.initial_balance) * 100,
                            'exit_reason': close_reason,
                            'duration': (timestamp - position['entry_time']).total_seconds() / 3600,
                            'confidence': position['confidence']
                        }
                        
                        self.trades.append(trade_record)
                        
                        # Update risk manager
                        self.risk_manager.close_position(pos_id, current_price, timestamp)
                        
                        # Remove from open positions
                        del open_positions[pos_id]
                    
                    # Check for new entry signals
                    if (row['signal_action'] in ['BUY', 'SELL'] and 
                        row['signal_confidence'] >= confidence_threshold and
                        len(open_positions) < 3):  # Max 3 concurrent positions for backtest
                        
                        # Calculate position size
                        volatility = row['ATR'] / current_price
                        position_size = self.risk_manager.calculate_position_size(
                            symbol, current_price, row['signal_stop_loss'], 
                            self.current_balance, volatility
                        )
                        
                        # Check if position can be opened
                        can_open, reason = self.risk_manager.can_open_position(
                            symbol, position_size, current_price
                        )
                        
                        if can_open:
                            # Create position
                            pos_id = f"{symbol}_{timestamp.strftime('%Y%m%d_%H%M%S')}"
                            
                            position = {
                                'id': pos_id,
                                'entry_time': timestamp,
                                'type': row['signal_action'],
                                'size': position_size,
                                'entry_price': current_price,
                                'stop_loss': row['signal_stop_loss'],
                                'take_profit': row['signal_take_profit'],
                                'confidence': row['signal_confidence']
                            }
                            
                            open_positions[pos_id] = position
                            
                            # Update risk manager
                            self.risk_manager.add_position(
                                symbol, position_size, current_price,
                                row['signal_stop_loss'], row['signal_take_profit'],
                                row['signal_action']
                            )
                    
                    # Update equity curve
                    unrealized_pnl = 0
                    for position in open_positions.values():
                        if position['type'] == 'BUY':
                            unrealized_pnl += (current_price - position['entry_price']) * position['size'] * 10
                        else:
                            unrealized_pnl += (position['entry_price'] - current_price) * position['size'] * 10
                    
                    current_equity = self.current_balance + unrealized_pnl
                    self.equity_curve.append(current_equity)
                    
                except Exception as e:
                    self.logger.error(f"Error processing bar {i}: {e}")
                    continue
            
            # Close any remaining positions at the end
            for pos_id, position in open_positions.items():
                final_price = df['close'].iloc[-1]
                
                if position['type'] == 'BUY':
                    pnl = (final_price - position['entry_price']) * position['size'] * 10
                else:
                    pnl = (position['entry_price'] - final_price) * position['size'] * 10
                
                self.current_balance += pnl
                
                trade_record = {
                    'entry_time': position['entry_time'],
                    'exit_time': df.index[-1],
                    'symbol': symbol,
                    'type': position['type'],
                    'size': position['size'],
                    'entry_price': position['entry_price'],
                    'exit_price': final_price,
                    'stop_loss': position['stop_loss'],
                    'take_profit': position['take_profit'],
                    'pnl': pnl,
                    'pnl_pct': (pnl / self.initial_balance) * 100,
                    'exit_reason': 'End of Test',
                    'duration': (df.index[-1] - position['entry_time']).total_seconds() / 3600,
                    'confidence': position['confidence']
                }
                
                self.trades.append(trade_record)
            
            # Calculate performance metrics
            self.performance_metrics = self.calculate_performance_metrics()
            
            self.logger.info(f"Backtest completed. Total trades: {len(self.trades)}")
            self.logger.info(f"Final balance: ${self.current_balance:.2f}")
            
            return self.performance_metrics
            
        except Exception as e:
            self.logger.error(f"Error running backtest: {e}")
            return {}
    
    def calculate_performance_metrics(self) -> Dict:
        """Calculate comprehensive performance metrics"""
        try:
            if not self.trades:
                return {}
            
            trades_df = pd.DataFrame(self.trades)
            
            # Basic metrics
            total_trades = len(trades_df)
            winning_trades = trades_df[trades_df['pnl'] > 0]
            losing_trades = trades_df[trades_df['pnl'] < 0]
            
            win_rate = len(winning_trades) / total_trades * 100
            loss_rate = len(losing_trades) / total_trades * 100
            
            # P&L metrics
            total_pnl = trades_df['pnl'].sum()
            total_return = (self.current_balance - self.initial_balance) / self.initial_balance * 100
            
            avg_win = winning_trades['pnl'].mean() if not winning_trades.empty else 0
            avg_loss = losing_trades['pnl'].mean() if not losing_trades.empty else 0
            
            largest_win = winning_trades['pnl'].max() if not winning_trades.empty else 0
            largest_loss = losing_trades['pnl'].min() if not losing_trades.empty else 0
            
            # Profit factor
            gross_profit = winning_trades['pnl'].sum() if not winning_trades.empty else 0
            gross_loss = abs(losing_trades['pnl'].sum()) if not losing_trades.empty else 0
            profit_factor = gross_profit / gross_loss if gross_loss > 0 else float('inf')
            
            # Risk metrics
            equity_series = pd.Series(self.equity_curve)
            returns = equity_series.pct_change().dropna()
            
            # Drawdown calculation
            peak = equity_series.expanding().max()
            drawdown = (equity_series - peak) / peak * 100
            max_drawdown = drawdown.min()
            
            # Sharpe ratio
            if len(returns) > 1 and returns.std() > 0:
                sharpe_ratio = returns.mean() / returns.std() * np.sqrt(252 * 24 * 4)  # 15min intervals
            else:
                sharpe_ratio = 0
            
            # Sortino ratio
            negative_returns = returns[returns < 0]
            if len(negative_returns) > 1 and negative_returns.std() > 0:
                sortino_ratio = returns.mean() / negative_returns.std() * np.sqrt(252 * 24 * 4)
            else:
                sortino_ratio = 0
            
            # Calmar ratio
            calmar_ratio = total_return / abs(max_drawdown) if max_drawdown < 0 else 0
            
            # Trade duration analysis
            avg_trade_duration = trades_df['duration'].mean()
            avg_winning_duration = winning_trades['duration'].mean() if not winning_trades.empty else 0
            avg_losing_duration = losing_trades['duration'].mean() if not losing_trades.empty else 0
            
            # Consecutive wins/losses
            consecutive_wins = 0
            consecutive_losses = 0
            max_consecutive_wins = 0
            max_consecutive_losses = 0
            
            for pnl in trades_df['pnl']:
                if pnl > 0:
                    consecutive_wins += 1
                    consecutive_losses = 0
                    max_consecutive_wins = max(max_consecutive_wins, consecutive_wins)
                else:
                    consecutive_losses += 1
                    consecutive_wins = 0
                    max_consecutive_losses = max(max_consecutive_losses, consecutive_losses)
            
            # Monthly returns
            trades_df['month'] = pd.to_datetime(trades_df['entry_time']).dt.to_period('M')
            monthly_returns = trades_df.groupby('month')['pnl'].sum()
            winning_months = len(monthly_returns[monthly_returns > 0])
            total_months = len(monthly_returns)
            monthly_win_rate = winning_months / total_months * 100 if total_months > 0 else 0
            
            return {
                # Basic metrics
                'total_trades': total_trades,
                'winning_trades': len(winning_trades),
                'losing_trades': len(losing_trades),
                'win_rate': win_rate,
                'loss_rate': loss_rate,
                
                # P&L metrics
                'total_pnl': total_pnl,
                'total_return': total_return,
                'gross_profit': gross_profit,
                'gross_loss': gross_loss,
                'profit_factor': profit_factor,
                'avg_win': avg_win,
                'avg_loss': avg_loss,
                'largest_win': largest_win,
                'largest_loss': largest_loss,
                
                # Risk metrics
                'max_drawdown': max_drawdown,
                'sharpe_ratio': sharpe_ratio,
                'sortino_ratio': sortino_ratio,
                'calmar_ratio': calmar_ratio,
                
                # Duration metrics
                'avg_trade_duration': avg_trade_duration,
                'avg_winning_duration': avg_winning_duration,
                'avg_losing_duration': avg_losing_duration,
                
                # Streak metrics
                'max_consecutive_wins': max_consecutive_wins,
                'max_consecutive_losses': max_consecutive_losses,
                
                # Monthly metrics
                'monthly_win_rate': monthly_win_rate,
                'winning_months': winning_months,
                'total_months': total_months,
                
                # Balance info
                'initial_balance': self.initial_balance,
                'final_balance': self.current_balance,
                'peak_balance': max(self.equity_curve),
            }
            
        except Exception as e:
            self.logger.error(f"Error calculating performance metrics: {e}")
            return {}
    
    def plot_results(self, save_path: str = None):
        """
        Plot comprehensive backtest results
        رسم نتایج جامع بک‌تست
        """
        try:
            if not self.trades or not self.performance_metrics:
                self.logger.error("No backtest results to plot")
                return
            
            # Create subplots
            fig, axes = plt.subplots(2, 2, figsize=(15, 12))
            fig.suptitle('Forex Strategy Backtest Results', fontsize=16, fontweight='bold')
            
            # 1. Equity Curve
            axes[0, 0].plot(self.equity_curve, linewidth=2, color='blue')
            axes[0, 0].set_title('Equity Curve', fontweight='bold')
            axes[0, 0].set_xlabel('Time')
            axes[0, 0].set_ylabel('Balance ($)')
            axes[0, 0].grid(True, alpha=0.3)
            
            # Add drawdown
            equity_series = pd.Series(self.equity_curve)
            peak = equity_series.expanding().max()
            drawdown = (equity_series - peak) / peak * 100
            
            ax_dd = axes[0, 0].twinx()
            ax_dd.fill_between(range(len(drawdown)), drawdown, 0, alpha=0.3, color='red')
            ax_dd.set_ylabel('Drawdown (%)', color='red')
            
            # 2. Trade Distribution
            trades_df = pd.DataFrame(self.trades)
            axes[0, 1].hist(trades_df['pnl'], bins=30, alpha=0.7, color='green', edgecolor='black')
            axes[0, 1].axvline(x=0, color='red', linestyle='--', linewidth=2)
            axes[0, 1].set_title('Trade P&L Distribution', fontweight='bold')
            axes[0, 1].set_xlabel('P&L ($)')
            axes[0, 1].set_ylabel('Frequency')
            axes[0, 1].grid(True, alpha=0.3)
            
            # 3. Monthly Returns
            trades_df['month'] = pd.to_datetime(trades_df['entry_time']).dt.to_period('M')
            monthly_returns = trades_df.groupby('month')['pnl'].sum()
            
            colors = ['green' if x > 0 else 'red' for x in monthly_returns.values]
            axes[1, 0].bar(range(len(monthly_returns)), monthly_returns.values, color=colors, alpha=0.7)
            axes[1, 0].set_title('Monthly Returns', fontweight='bold')
            axes[1, 0].set_xlabel('Month')
            axes[1, 0].set_ylabel('P&L ($)')
            axes[1, 0].grid(True, alpha=0.3)
            axes[1, 0].axhline(y=0, color='black', linestyle='-', linewidth=1)
            
            # 4. Performance Metrics Summary
            axes[1, 1].axis('off')
            
            metrics_text = f"""
            PERFORMANCE SUMMARY
            
            Total Trades: {self.performance_metrics['total_trades']}
            Win Rate: {self.performance_metrics['win_rate']:.1f}%
            
            Total Return: {self.performance_metrics['total_return']:.2f}%
            Profit Factor: {self.performance_metrics['profit_factor']:.2f}
            Max Drawdown: {self.performance_metrics['max_drawdown']:.2f}%
            
            Sharpe Ratio: {self.performance_metrics['sharpe_ratio']:.2f}
            Sortino Ratio: {self.performance_metrics['sortino_ratio']:.2f}
            
            Avg Win: ${self.performance_metrics['avg_win']:.2f}
            Avg Loss: ${self.performance_metrics['avg_loss']:.2f}
            
            Max Consecutive Wins: {self.performance_metrics['max_consecutive_wins']}
            Max Consecutive Losses: {self.performance_metrics['max_consecutive_losses']}
            """
            
            axes[1, 1].text(0.1, 0.9, metrics_text, transform=axes[1, 1].transAxes,
                           fontsize=10, verticalalignment='top',
                           bbox=dict(boxstyle='round', facecolor='lightgray', alpha=0.8))
            
            plt.tight_layout()
            
            if save_path:
                plt.savefig(save_path, dpi=300, bbox_inches='tight')
                self.logger.info(f"Results plot saved to {save_path}")
            
            plt.show()
            
        except Exception as e:
            self.logger.error(f"Error plotting results: {e}")
    
    def generate_report(self, save_path: str = None) -> str:
        """Generate detailed backtest report"""
        try:
            if not self.performance_metrics:
                return "No backtest results available"
            
            report = f"""
            ==========================================
            FOREX STRATEGY BACKTEST REPORT
            تقریر بک‌تست استراتژی فارکس
            ==========================================
            
            BASIC METRICS:
            - Total Trades: {self.performance_metrics['total_trades']}
            - Winning Trades: {self.performance_metrics['winning_trades']}
            - Losing Trades: {self.performance_metrics['losing_trades']}
            - Win Rate: {self.performance_metrics['win_rate']:.2f}%
            
            PROFITABILITY METRICS:
            - Initial Balance: ${self.performance_metrics['initial_balance']:,.2f}
            - Final Balance: ${self.performance_metrics['final_balance']:,.2f}
            - Total Return: {self.performance_metrics['total_return']:.2f}%
            - Total P&L: ${self.performance_metrics['total_pnl']:,.2f}
            - Gross Profit: ${self.performance_metrics['gross_profit']:,.2f}
            - Gross Loss: ${abs(self.performance_metrics['gross_loss']):,.2f}
            - Profit Factor: {self.performance_metrics['profit_factor']:.2f}
            
            TRADE ANALYSIS:
            - Average Win: ${self.performance_metrics['avg_win']:.2f}
            - Average Loss: ${self.performance_metrics['avg_loss']:.2f}
            - Largest Win: ${self.performance_metrics['largest_win']:.2f}
            - Largest Loss: ${self.performance_metrics['largest_loss']:.2f}
            - Average Trade Duration: {self.performance_metrics['avg_trade_duration']:.1f} hours
            
            RISK METRICS:
            - Maximum Drawdown: {self.performance_metrics['max_drawdown']:.2f}%
            - Sharpe Ratio: {self.performance_metrics['sharpe_ratio']:.2f}
            - Sortino Ratio: {self.performance_metrics['sortino_ratio']:.2f}
            - Calmar Ratio: {self.performance_metrics['calmar_ratio']:.2f}
            
            CONSISTENCY METRICS:
            - Max Consecutive Wins: {self.performance_metrics['max_consecutive_wins']}
            - Max Consecutive Losses: {self.performance_metrics['max_consecutive_losses']}
            - Monthly Win Rate: {self.performance_metrics['monthly_win_rate']:.1f}%
            - Winning Months: {self.performance_metrics['winning_months']}/{self.performance_metrics['total_months']}
            
            STRATEGY ASSESSMENT:
            """
            
            # Add strategy assessment
            if self.performance_metrics['win_rate'] >= 60:
                report += "\n✓ EXCELLENT: High win rate strategy"
            elif self.performance_metrics['win_rate'] >= 50:
                report += "\n✓ GOOD: Decent win rate"
            else:
                report += "\n⚠ WARNING: Low win rate - needs improvement"
            
            if self.performance_metrics['profit_factor'] >= 2.0:
                report += "\n✓ EXCELLENT: High profit factor"
            elif self.performance_metrics['profit_factor'] >= 1.5:
                report += "\n✓ GOOD: Acceptable profit factor"
            else:
                report += "\n⚠ WARNING: Low profit factor"
            
            if abs(self.performance_metrics['max_drawdown']) <= 10:
                report += "\n✓ EXCELLENT: Low drawdown"
            elif abs(self.performance_metrics['max_drawdown']) <= 20:
                report += "\n✓ ACCEPTABLE: Moderate drawdown"
            else:
                report += "\n⚠ WARNING: High drawdown - risky strategy"
            
            if self.performance_metrics['sharpe_ratio'] >= 1.0:
                report += "\n✓ GOOD: Positive risk-adjusted returns"
            else:
                report += "\n⚠ POOR: Low risk-adjusted returns"
            
            report += f"\n\nGenerated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
            report += "\n=========================================="
            
            if save_path:
                with open(save_path, 'w', encoding='utf-8') as f:
                    f.write(report)
                self.logger.info(f"Report saved to {save_path}")
            
            return report
            
        except Exception as e:
            self.logger.error(f"Error generating report: {e}")
            return "Error generating report"

# Example usage
if __name__ == "__main__":
    # Create backtester
    backtester = ForexBacktester(initial_balance=10000)
    
    # Run backtest
    results = backtester.run_backtest(
        symbol='EURUSD',
        start_date='2024-01-01',
        end_date='2024-12-01',
        confidence_threshold=75.0
    )
    
    if results:
        # Generate report
        report = backtester.generate_report('backtest_report.txt')
        print(report)
        
        # Plot results
        backtester.plot_results('backtest_results.png')
    else:
        print("Backtest failed - no results generated")