import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from typing import Dict, List, Tuple, Optional
import logging

class AdvancedRiskManager:
    """
    Advanced Risk Management System for Forex Trading
    سیستم مدیریت ریسک پیشرفته برای معاملات فارکس
    """
    
    def __init__(self, initial_balance: float = 10000):
        """
        Initialize risk manager
        
        Args:
            initial_balance: Starting account balance
        """
        self.initial_balance = initial_balance
        self.current_balance = initial_balance
        self.peak_balance = initial_balance
        
        # Risk parameters
        self.max_risk_per_trade = 0.02      # 2% per trade
        self.max_daily_risk = 0.05          # 5% per day
        self.max_weekly_risk = 0.10         # 10% per week
        self.max_monthly_risk = 0.20        # 20% per month
        self.max_drawdown = 0.15            # 15% maximum drawdown
        
        # Position limits
        self.max_positions = 5              # Maximum concurrent positions
        self.max_correlation = 0.7          # Maximum correlation between positions
        self.max_exposure_per_currency = 0.3  # 30% exposure per currency
        
        # Volatility adjustments
        self.volatility_lookback = 20       # Days for volatility calculation
        self.volatility_multiplier = 1.5    # Volatility adjustment factor
        
        # Performance tracking
        self.trade_history = []
        self.daily_pnl = []
        self.weekly_pnl = []
        self.monthly_pnl = []
        self.drawdown_history = []
        
        # Current positions
        self.open_positions = {}
        self.currency_exposure = {}
        
        # Setup logging
        self.logger = logging.getLogger(__name__)
    
    def calculate_position_size(self, symbol: str, entry_price: float, 
                              stop_loss: float, current_balance: float,
                              volatility: float = None) -> float:
        """
        Calculate optimal position size using advanced risk management
        محاسبه اندازه پوزیشن بهینه با مدیریت ریسک پیشرفته
        """
        try:
            # Basic risk amount
            base_risk_amount = current_balance * self.max_risk_per_trade
            
            # Calculate stop loss distance in pips
            pip_value = self._get_pip_value(symbol)
            stop_loss_pips = abs(entry_price - stop_loss) / pip_value
            
            if stop_loss_pips == 0:
                return 0
            
            # Base position size
            base_position_size = base_risk_amount / (stop_loss_pips * self._get_pip_cost(symbol))
            
            # Volatility adjustment
            if volatility is not None:
                volatility_factor = self._calculate_volatility_adjustment(volatility)
                base_position_size *= volatility_factor
            
            # Drawdown adjustment
            drawdown_factor = self._calculate_drawdown_adjustment()
            base_position_size *= drawdown_factor
            
            # Correlation adjustment
            correlation_factor = self._calculate_correlation_adjustment(symbol)
            base_position_size *= correlation_factor
            
            # Currency exposure check
            exposure_factor = self._calculate_exposure_adjustment(symbol)
            base_position_size *= exposure_factor
            
            # Apply position limits
            final_position_size = min(base_position_size, 2.0)  # Max 2 lots
            final_position_size = max(final_position_size, 0.01)  # Min 0.01 lots
            
            self.logger.info(f"Position size calculation for {symbol}:")
            self.logger.info(f"  Base size: {base_position_size:.4f}")
            self.logger.info(f"  Volatility factor: {volatility_factor if volatility else 1:.4f}")
            self.logger.info(f"  Drawdown factor: {drawdown_factor:.4f}")
            self.logger.info(f"  Correlation factor: {correlation_factor:.4f}")
            self.logger.info(f"  Exposure factor: {exposure_factor:.4f}")
            self.logger.info(f"  Final size: {final_position_size:.4f}")
            
            return final_position_size
            
        except Exception as e:
            self.logger.error(f"Error calculating position size: {e}")
            return 0.01
    
    def _get_pip_value(self, symbol: str) -> float:
        """Get pip value for symbol"""
        if 'JPY' in symbol:
            return 0.01
        else:
            return 0.0001
    
    def _get_pip_cost(self, symbol: str) -> float:
        """Get pip cost in account currency"""
        # Simplified - in real implementation, this should be dynamic
        if symbol == 'EURUSD':
            return 10  # $10 per pip for 1 lot
        elif symbol == 'GBPUSD':
            return 10
        elif symbol == 'USDJPY':
            return 9.09  # Approximate
        else:
            return 10  # Default
    
    def _calculate_volatility_adjustment(self, volatility: float) -> float:
        """Calculate position size adjustment based on volatility"""
        try:
            # Normalize volatility (assuming ATR as percentage)
            normalized_volatility = volatility * 100
            
            # Reduce position size for high volatility
            if normalized_volatility > 1.5:  # High volatility
                return 0.7
            elif normalized_volatility > 1.0:  # Medium volatility
                return 0.85
            elif normalized_volatility < 0.5:  # Low volatility
                return 1.2
            else:
                return 1.0
                
        except Exception as e:
            self.logger.error(f"Error calculating volatility adjustment: {e}")
            return 1.0
    
    def _calculate_drawdown_adjustment(self) -> float:
        """Calculate position size adjustment based on current drawdown"""
        try:
            current_drawdown = (self.peak_balance - self.current_balance) / self.peak_balance
            
            if current_drawdown > 0.10:  # 10% drawdown
                return 0.5  # Reduce position size by 50%
            elif current_drawdown > 0.05:  # 5% drawdown
                return 0.75  # Reduce position size by 25%
            else:
                return 1.0
                
        except Exception as e:
            self.logger.error(f"Error calculating drawdown adjustment: {e}")
            return 1.0
    
    def _calculate_correlation_adjustment(self, symbol: str) -> float:
        """Calculate adjustment based on correlation with existing positions"""
        try:
            if not self.open_positions:
                return 1.0
            
            # Simplified correlation check
            symbol_base = symbol[:3]
            symbol_quote = symbol[3:]
            
            high_correlation_count = 0
            
            for pos_symbol in self.open_positions.keys():
                pos_base = pos_symbol[:3]
                pos_quote = pos_symbol[3:]
                
                # Check for currency overlap
                if (symbol_base == pos_base or symbol_base == pos_quote or 
                    symbol_quote == pos_base or symbol_quote == pos_quote):
                    high_correlation_count += 1
            
            # Reduce position size if high correlation
            if high_correlation_count >= 2:
                return 0.5
            elif high_correlation_count == 1:
                return 0.75
            else:
                return 1.0
                
        except Exception as e:
            self.logger.error(f"Error calculating correlation adjustment: {e}")
            return 1.0
    
    def _calculate_exposure_adjustment(self, symbol: str) -> float:
        """Calculate adjustment based on currency exposure"""
        try:
            symbol_base = symbol[:3]
            symbol_quote = symbol[3:]
            
            base_exposure = self.currency_exposure.get(symbol_base, 0)
            quote_exposure = self.currency_exposure.get(symbol_quote, 0)
            
            max_exposure = max(base_exposure, quote_exposure)
            
            if max_exposure > self.max_exposure_per_currency:
                return 0.3  # Significantly reduce
            elif max_exposure > self.max_exposure_per_currency * 0.8:
                return 0.6
            else:
                return 1.0
                
        except Exception as e:
            self.logger.error(f"Error calculating exposure adjustment: {e}")
            return 1.0
    
    def can_open_position(self, symbol: str, position_size: float, 
                         entry_price: float) -> Tuple[bool, str]:
        """
        Check if a new position can be opened based on risk rules
        بررسی امکان باز کردن پوزیشن جدید بر اساس قوانین ریسک
        """
        try:
            # Check maximum positions
            if len(self.open_positions) >= self.max_positions:
                return False, "Maximum number of positions reached"
            
            # Check daily risk limit
            daily_risk = self._calculate_daily_risk()
            if daily_risk >= self.max_daily_risk:
                return False, "Daily risk limit exceeded"
            
            # Check weekly risk limit
            weekly_risk = self._calculate_weekly_risk()
            if weekly_risk >= self.max_weekly_risk:
                return False, "Weekly risk limit exceeded"
            
            # Check monthly risk limit
            monthly_risk = self._calculate_monthly_risk()
            if monthly_risk >= self.max_monthly_risk:
                return False, "Monthly risk limit exceeded"
            
            # Check maximum drawdown
            current_drawdown = (self.peak_balance - self.current_balance) / self.peak_balance
            if current_drawdown >= self.max_drawdown:
                return False, "Maximum drawdown reached"
            
            # Check currency exposure
            symbol_base = symbol[:3]
            symbol_quote = symbol[3:]
            
            position_value = position_size * entry_price
            base_exposure = self.currency_exposure.get(symbol_base, 0)
            quote_exposure = self.currency_exposure.get(symbol_quote, 0)
            
            if (base_exposure + position_value) / self.current_balance > self.max_exposure_per_currency:
                return False, f"Maximum {symbol_base} exposure would be exceeded"
            
            if (quote_exposure + position_value) / self.current_balance > self.max_exposure_per_currency:
                return False, f"Maximum {symbol_quote} exposure would be exceeded"
            
            return True, "Position can be opened"
            
        except Exception as e:
            self.logger.error(f"Error checking position eligibility: {e}")
            return False, "Error in risk check"
    
    def _calculate_daily_risk(self) -> float:
        """Calculate current daily risk exposure"""
        try:
            today = datetime.now().date()
            today_trades = [trade for trade in self.trade_history 
                          if trade['date'].date() == today and trade['status'] == 'open']
            
            total_risk = sum(trade['risk_amount'] for trade in today_trades)
            return total_risk / self.current_balance
            
        except Exception as e:
            self.logger.error(f"Error calculating daily risk: {e}")
            return 0
    
    def _calculate_weekly_risk(self) -> float:
        """Calculate current weekly risk exposure"""
        try:
            week_start = datetime.now() - timedelta(days=7)
            week_trades = [trade for trade in self.trade_history 
                          if trade['date'] >= week_start and trade['status'] == 'open']
            
            total_risk = sum(trade['risk_amount'] for trade in week_trades)
            return total_risk / self.current_balance
            
        except Exception as e:
            self.logger.error(f"Error calculating weekly risk: {e}")
            return 0
    
    def _calculate_monthly_risk(self) -> float:
        """Calculate current monthly risk exposure"""
        try:
            month_start = datetime.now() - timedelta(days=30)
            month_trades = [trade for trade in self.trade_history 
                           if trade['date'] >= month_start and trade['status'] == 'open']
            
            total_risk = sum(trade['risk_amount'] for trade in month_trades)
            return total_risk / self.current_balance
            
        except Exception as e:
            self.logger.error(f"Error calculating monthly risk: {e}")
            return 0
    
    def add_position(self, symbol: str, position_size: float, entry_price: float,
                    stop_loss: float, take_profit: float, position_type: str):
        """Add a new position to tracking"""
        try:
            position_id = f"{symbol}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
            
            risk_amount = abs(entry_price - stop_loss) * position_size * self._get_pip_cost(symbol)
            
            position = {
                'id': position_id,
                'symbol': symbol,
                'size': position_size,
                'entry_price': entry_price,
                'stop_loss': stop_loss,
                'take_profit': take_profit,
                'type': position_type,
                'entry_time': datetime.now(),
                'risk_amount': risk_amount,
                'status': 'open'
            }
            
            self.open_positions[position_id] = position
            
            # Update currency exposure
            symbol_base = symbol[:3]
            symbol_quote = symbol[3:]
            position_value = position_size * entry_price
            
            self.currency_exposure[symbol_base] = self.currency_exposure.get(symbol_base, 0) + position_value
            self.currency_exposure[symbol_quote] = self.currency_exposure.get(symbol_quote, 0) + position_value
            
            # Add to trade history
            self.trade_history.append(position.copy())
            
            self.logger.info(f"Position added: {position_id}")
            
        except Exception as e:
            self.logger.error(f"Error adding position: {e}")
    
    def close_position(self, position_id: str, close_price: float, close_time: datetime = None):
        """Close a position and update statistics"""
        try:
            if position_id not in self.open_positions:
                self.logger.warning(f"Position {position_id} not found")
                return
            
            position = self.open_positions[position_id]
            
            if close_time is None:
                close_time = datetime.now()
            
            # Calculate P&L
            if position['type'] == 'BUY':
                pnl = (close_price - position['entry_price']) * position['size'] * self._get_pip_cost(position['symbol'])
            else:  # SELL
                pnl = (position['entry_price'] - close_price) * position['size'] * self._get_pip_cost(position['symbol'])
            
            # Update position
            position['close_price'] = close_price
            position['close_time'] = close_time
            position['pnl'] = pnl
            position['status'] = 'closed'
            
            # Update balance
            self.current_balance += pnl
            if self.current_balance > self.peak_balance:
                self.peak_balance = self.current_balance
            
            # Update currency exposure
            symbol_base = position['symbol'][:3]
            symbol_quote = position['symbol'][3:]
            position_value = position['size'] * position['entry_price']
            
            self.currency_exposure[symbol_base] = max(0, self.currency_exposure.get(symbol_base, 0) - position_value)
            self.currency_exposure[symbol_quote] = max(0, self.currency_exposure.get(symbol_quote, 0) - position_value)
            
            # Remove from open positions
            del self.open_positions[position_id]
            
            # Update trade history
            for trade in self.trade_history:
                if trade['id'] == position_id:
                    trade.update(position)
                    break
            
            self.logger.info(f"Position closed: {position_id}, P&L: ${pnl:.2f}")
            
        except Exception as e:
            self.logger.error(f"Error closing position: {e}")
    
    def get_portfolio_metrics(self) -> Dict:
        """Get comprehensive portfolio performance metrics"""
        try:
            closed_trades = [trade for trade in self.trade_history if trade['status'] == 'closed']
            
            if not closed_trades:
                return {
                    'total_trades': 0,
                    'win_rate': 0,
                    'profit_factor': 0,
                    'sharpe_ratio': 0,
                    'max_drawdown': 0,
                    'current_drawdown': 0,
                    'total_return': 0,
                    'average_win': 0,
                    'average_loss': 0
                }
            
            # Basic metrics
            total_trades = len(closed_trades)
            winning_trades = [trade for trade in closed_trades if trade['pnl'] > 0]
            losing_trades = [trade for trade in closed_trades if trade['pnl'] < 0]
            
            win_rate = len(winning_trades) / total_trades * 100 if total_trades > 0 else 0
            
            total_profit = sum(trade['pnl'] for trade in winning_trades)
            total_loss = abs(sum(trade['pnl'] for trade in losing_trades))
            
            profit_factor = total_profit / total_loss if total_loss > 0 else float('inf')
            
            average_win = total_profit / len(winning_trades) if winning_trades else 0
            average_loss = total_loss / len(losing_trades) if losing_trades else 0
            
            # Return calculation
            total_return = (self.current_balance - self.initial_balance) / self.initial_balance * 100
            
            # Drawdown calculation
            current_drawdown = (self.peak_balance - self.current_balance) / self.peak_balance * 100
            
            # Calculate maximum drawdown
            balance_history = [self.initial_balance]
            running_balance = self.initial_balance
            max_dd = 0
            peak = self.initial_balance
            
            for trade in closed_trades:
                running_balance += trade['pnl']
                balance_history.append(running_balance)
                
                if running_balance > peak:
                    peak = running_balance
                
                drawdown = (peak - running_balance) / peak * 100
                max_dd = max(max_dd, drawdown)
            
            # Sharpe ratio (simplified)
            if len(closed_trades) > 1:
                returns = [trade['pnl'] / self.initial_balance for trade in closed_trades]
                avg_return = np.mean(returns)
                std_return = np.std(returns)
                sharpe_ratio = avg_return / std_return * np.sqrt(252) if std_return > 0 else 0
            else:
                sharpe_ratio = 0
            
            return {
                'total_trades': total_trades,
                'winning_trades': len(winning_trades),
                'losing_trades': len(losing_trades),
                'win_rate': win_rate,
                'profit_factor': profit_factor,
                'sharpe_ratio': sharpe_ratio,
                'max_drawdown': max_dd,
                'current_drawdown': current_drawdown,
                'total_return': total_return,
                'average_win': average_win,
                'average_loss': average_loss,
                'total_profit': total_profit,
                'total_loss': total_loss,
                'current_balance': self.current_balance,
                'peak_balance': self.peak_balance
            }
            
        except Exception as e:
            self.logger.error(f"Error calculating portfolio metrics: {e}")
            return {}
    
    def should_stop_trading(self) -> Tuple[bool, str]:
        """Determine if trading should be stopped due to risk limits"""
        try:
            # Check maximum drawdown
            current_drawdown = (self.peak_balance - self.current_balance) / self.peak_balance
            if current_drawdown >= self.max_drawdown:
                return True, f"Maximum drawdown reached: {current_drawdown:.2%}"
            
            # Check daily loss limit
            daily_risk = self._calculate_daily_risk()
            if daily_risk >= self.max_daily_risk:
                return True, f"Daily risk limit exceeded: {daily_risk:.2%}"
            
            # Check if balance is too low
            if self.current_balance < self.initial_balance * 0.5:
                return True, "Account balance too low (50% of initial)"
            
            return False, "Trading can continue"
            
        except Exception as e:
            self.logger.error(f"Error checking stop conditions: {e}")
            return True, "Error in risk check - stopping trading"
    
    def get_risk_summary(self) -> Dict:
        """Get current risk exposure summary"""
        try:
            return {
                'current_balance': self.current_balance,
                'peak_balance': self.peak_balance,
                'current_drawdown': (self.peak_balance - self.current_balance) / self.peak_balance * 100,
                'open_positions': len(self.open_positions),
                'daily_risk': self._calculate_daily_risk() * 100,
                'weekly_risk': self._calculate_weekly_risk() * 100,
                'monthly_risk': self._calculate_monthly_risk() * 100,
                'currency_exposure': self.currency_exposure,
                'risk_limits': {
                    'max_risk_per_trade': self.max_risk_per_trade * 100,
                    'max_daily_risk': self.max_daily_risk * 100,
                    'max_weekly_risk': self.max_weekly_risk * 100,
                    'max_monthly_risk': self.max_monthly_risk * 100,
                    'max_drawdown': self.max_drawdown * 100,
                    'max_positions': self.max_positions
                }
            }
            
        except Exception as e:
            self.logger.error(f"Error getting risk summary: {e}")
            return {}