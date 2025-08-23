//+------------------------------------------------------------------+
//|                                        UltraAdvancedTrendEA.mq4 |
//|                                  Copyright 2024, Ultra Trader |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Ultra Trader"
#property link      ""
#property version   "2.00"
#property strict

//--- Input Parameters
input group "=== EA Settings ==="
input double  LotSize = 0.01;              // Lot size
input bool    AutoLotSize = true;          // Auto calculate lot size based on risk
input double  RiskPercent = 1.5;           // Risk percentage per trade
input int     MagicNumber = 2024;          // Magic number
input int     Slippage = 3;                // Maximum slippage

input group "=== Trend Following Settings ==="
input int     TrendTimeframe = 4;          // Trend timeframe (4=H1, 1=M1, 5=M5)
input int     EntryTimeframe = 1;          // Entry timeframe (1=M1, 5=M5)
input bool    MultiTimeframe = true;       // Use multi-timeframe analysis
input int     MaxOpenTrades = 5;           // Maximum open trades
input double  MinTrendStrength = 0.7;      // Minimum trend strength (0.0-1.0)

input group "=== Advanced Indicator Settings ==="
input int     RSI_Period = 14;             // RSI period
input int     RSI_Overbought = 75;         // RSI overbought level
input int     RSI_Oversold = 25;           // RSI oversold level
input int     MACD_Fast = 12;              // MACD fast EMA
input int     MACD_Slow = 26;              // MACD slow EMA
input int     MACD_Signal = 9;             // MACD signal line
input int     EMA_Fast = 8;                // Fast EMA period
input int     EMA_Slow = 21;               // Slow EMA period
input int     EMA_Trend = 50;              // Trend EMA period
input int     BB_Period = 20;              // Bollinger Bands period
input double  BB_Deviation = 2.2;          // Bollinger Bands deviation
input int     ATR_Period = 14;             // ATR period for volatility
input int     Stochastic_K = 14;           // Stochastic %K period
input int     Stochastic_D = 3;            // Stochastic %D period
input int     Stochastic_Slow = 3;         // Stochastic slowing
input int     WilliamsR_Period = 14;       // Williams %R period
input int     CCI_Period = 20;             // CCI period

input group "=== Advanced Risk Management ==="
input bool    UseATR_SL = true;            // Use ATR for dynamic stop loss
input double  ATR_SL_Multiplier = 2.5;     // ATR multiplier for SL
input double  FixedSL = 25;                // Fixed SL in pips (if not using ATR)
input double  RiskRewardRatio = 2.0;       // Risk:Reward ratio
input bool    UseTrailingStop = true;      // Use trailing stop
input double  TrailingStart = 15;          // Trailing start in pips
input double  TrailingStep = 8;            // Trailing step in pips
input bool    UseBreakEven = true;         // Use break-even stop
input double  BreakEvenPips = 10;          // Pips to move SL to break-even
input bool    UsePartialClose = true;      // Use partial position closing
input double  PartialClosePercent = 50;    // Percentage to close at first target
input double  PartialCloseTarget = 1.5;    // First target multiplier

input group "=== Profit Optimization ==="
input bool    UseDynamicTP = true;         // Use dynamic take profit
input double  BaseTP = 2.0;                // Base take profit multiplier
input double  VolatilityTP = 1.5;          // Volatility-based TP multiplier
input bool    UseMarketStructure = true;   // Use market structure for TP
input bool    UseFibonacciTP = true;       // Use Fibonacci levels for TP
input bool    UseSupportResistance = true; // Use S/R levels for TP

input group "=== Trading Time & Filters ==="
input bool    UseTimeFilter = true;        // Use time filter
input int     StartHour = 2;               // Start trading hour (GMT)
input int     EndHour = 22;                // End trading hour (GMT)
input bool    AvoidNews = true;            // Avoid trading during news
input bool    UseSpreadFilter = true;      // Use spread filter
input double  MaxSpread = 5;               // Maximum allowed spread
input bool    UseVolatilityFilter = true;  // Use volatility filter
input double  MinVolatility = 0.8;         // Minimum volatility threshold

//--- Global Variables
double point_factor;
int total_orders = 0;
datetime last_trade_time = 0;
double daily_profit = 0;
double max_daily_loss = -200;
double total_profit = 0;
int consecutive_losses = 0;
int consecutive_wins = 0;

// Market structure variables
double last_high = 0;
double last_low = 0;
int trend_direction = 0; // 1=bullish, -1=bearish, 0=sideways

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize point factor for 4/5 digit brokers
    if(Digits == 5 || Digits == 3)
        point_factor = 10;
    else
        point_factor = 1;
    
    // Initialize market structure
    InitializeMarketStructure();
    
    Print("=== Ultra Advanced Trend EA Initialized ===");
    Print("Point factor: ", point_factor);
    Print("Current spread: ", MarketInfo(Symbol(), MODE_SPREAD));
    Print("Account balance: ", AccountBalance());
    Print("Risk per trade: ", RiskPercent, "%");
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("Ultra Advanced Trend EA stopped. Reason: ", reason);
    Print("Total profit: ", total_profit);
    Print("Daily profit: ", daily_profit);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check if trading is allowed
    if(!IsTradeAllowed()) return;
    
    // Update global variables and market structure
    UpdateGlobalVariables();
    UpdateMarketStructure();
    
    // Check trading conditions
    if(!CheckTradingConditions()) return;
    
    // Check for new trade opportunities
    CheckForNewTrades();
    
    // Manage existing trades
    ManageExistingTrades();
    
    // Update trailing stops
    if(UseTrailingStop) UpdateTrailingStops();
}

//+------------------------------------------------------------------+
//| Initialize market structure                                     |
//+------------------------------------------------------------------+
void InitializeMarketStructure()
{
    last_high = High[iHighest(Symbol(), TrendTimeframe, MODE_HIGH, 20, 0)];
    last_low = Low[iLowest(Symbol(), TrendTimeframe, MODE_LOW, 20, 0)];
    trend_direction = 0;
}

//+------------------------------------------------------------------+
//| Update market structure                                         |
//+------------------------------------------------------------------+
void UpdateMarketStructure()
{
    double current_high = High[iHighest(Symbol(), TrendTimeframe, MODE_HIGH, 10, 0)];
    double current_low = Low[iLowest(Symbol(), TrendTimeframe, MODE_LOW, 10, 0)];
    
    // Update trend direction
    if(current_high > last_high && current_low > last_low)
        trend_direction = 1; // Bullish
    else if(current_high < last_high && current_low < last_low)
        trend_direction = -1; // Bearish
    else
        trend_direction = 0; // Sideways
    
    last_high = current_high;
    last_low = current_low;
}

//+------------------------------------------------------------------+
//| Update global variables                                         |
//+------------------------------------------------------------------+
void UpdateGlobalVariables()
{
    total_orders = CountOpenTrades();
    daily_profit = CalculateDailyProfit();
    total_profit = CalculateTotalProfit();
}

//+------------------------------------------------------------------+
//| Check trading conditions                                        |
//+------------------------------------------------------------------+
bool CheckTradingConditions()
{
    // Check time filter
    if(UseTimeFilter && !IsWithinTradingHours()) return false;
    
    // Check spread filter
    if(UseSpreadFilter && MarketInfo(Symbol(), MODE_SPREAD) > MaxSpread * point_factor) return false;
    
    // Check volatility filter
    if(UseVolatilityFilter && !IsVolatilitySufficient()) return false;
    
    // Check maximum open trades
    if(total_orders >= MaxOpenTrades) return false;
    
    // Check daily loss limit
    if(daily_profit < max_daily_loss) return false;
    
    // Check consecutive losses
    if(consecutive_losses >= 5) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Check for new trade opportunities                               |
//+------------------------------------------------------------------+
void CheckForNewTrades()
{
    // Get trend analysis
    int trend_signal = AnalyzeTrend();
    double trend_strength = CalculateTrendStrength();
    
    // Only trade if trend is strong enough
    if(trend_strength < MinTrendStrength) return;
    
    // Get entry signals
    int entry_signal = AnalyzeEntrySignals();
    
    // Execute trades based on signals
    if(trend_signal == 1 && entry_signal == 1) // Bullish trend + buy signal
    {
        OpenBuyTrade();
    }
    else if(trend_signal == -1 && entry_signal == -1) // Bearish trend + sell signal
    {
        OpenSellTrade();
    }
}

//+------------------------------------------------------------------+
//| Analyze trend direction                                         |
//+------------------------------------------------------------------+
int AnalyzeTrend()
{
    double ema_trend = iMA(Symbol(), TrendTimeframe, EMA_Trend, 0, MODE_EMA, PRICE_CLOSE, 0);
    double ema_fast = iMA(Symbol(), TrendTimeframe, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE, 0);
    double ema_slow = iMA(Symbol(), TrendTimeframe, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE, 0);
    double close = Close[0];
    
    // Multi-timeframe trend confirmation
    int mtf_trend = 0;
    if(MultiTimeframe)
    {
        double mtf_ema = iMA(Symbol(), TrendTimeframe * 4, EMA_Trend, 0, MODE_EMA, PRICE_CLOSE, 0);
        if(close > mtf_ema) mtf_trend = 1;
        else mtf_trend = -1;
    }
    
    // Trend analysis
    if(close > ema_trend && ema_fast > ema_slow && (MultiTimeframe ? mtf_trend == 1 : true))
        return 1; // Bullish
    else if(close < ema_trend && ema_fast < ema_slow && (MultiTimeframe ? mtf_trend == -1 : true))
        return -1; // Bearish
    
    return 0; // Sideways
}

//+------------------------------------------------------------------+
//| Calculate trend strength                                        |
//+------------------------------------------------------------------+
double CalculateTrendStrength()
{
    double atr = iATR(Symbol(), TrendTimeframe, ATR_Period, 0);
    double atr_avg = 0;
    
    // Calculate average ATR
    for(int i = 1; i <= 10; i++)
        atr_avg += iATR(Symbol(), TrendTimeframe, ATR_Period, i);
    atr_avg /= 10;
    
    // Normalize trend strength
    double strength = MathMin(atr / atr_avg, 2.0) / 2.0;
    
    // Add momentum confirmation
    double momentum = iMomentum(Symbol(), TrendTimeframe, 10, PRICE_CLOSE, 0);
    double momentum_avg = 0;
    for(int i = 1; i <= 5; i++)
        momentum_avg += iMomentum(Symbol(), TrendTimeframe, 10, PRICE_CLOSE, i);
    momentum_avg /= 5;
    
    if(momentum > momentum_avg) strength += 0.2;
    if(momentum < momentum_avg) strength -= 0.2;
    
    return MathMax(0.0, MathMin(1.0, strength));
}

//+------------------------------------------------------------------+
//| Analyze entry signals                                           |
//+------------------------------------------------------------------+
int AnalyzeEntrySignals()
{
    double rsi = iRSI(Symbol(), EntryTimeframe, RSI_Period, PRICE_CLOSE, 0);
    double macd_main = iMACD(Symbol(), EntryTimeframe, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 0);
    double macd_signal = iMACD(Symbol(), EntryTimeframe, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL, 0);
    double macd_main_prev = iMACD(Symbol(), EntryTimeframe, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 1);
    double macd_signal_prev = iMACD(Symbol(), EntryTimeframe, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL, 1);
    
    double bb_upper = iBands(Symbol(), EntryTimeframe, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_UPPER, 0);
    double bb_lower = iBands(Symbol(), EntryTimeframe, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_LOWER, 0);
    double close = Close[0];
    
    double stoch_k = iStochastic(Symbol(), EntryTimeframe, Stochastic_K, Stochastic_D, Stochastic_Slow, MODE_SMA, 0, MODE_MAIN, 0);
    double stoch_d = iStochastic(Symbol(), EntryTimeframe, Stochastic_K, Stochastic_D, Stochastic_Slow, MODE_SMA, 0, MODE_SIGNAL, 0);
    
    double williams_r = iWPR(Symbol(), EntryTimeframe, WilliamsR_Period, 0);
    double cci = iCCI(Symbol(), EntryTimeframe, CCI_Period, PRICE_TYPICAL, 0);
    
    // Buy signals
    int buy_signals = 0;
    if(rsi < RSI_Oversold) buy_signals++;
    if(macd_main > macd_signal && macd_main_prev <= macd_signal_prev) buy_signals++;
    if(close < bb_lower) buy_signals++;
    if(stoch_k < 20 && stoch_k > stoch_d) buy_signals++;
    if(williams_r < -80) buy_signals++;
    if(cci < -100) buy_signals++;
    
    // Sell signals
    int sell_signals = 0;
    if(rsi > RSI_Overbought) sell_signals++;
    if(macd_main < macd_signal && macd_main_prev >= macd_signal_prev) sell_signals++;
    if(close > bb_upper) sell_signals++;
    if(stoch_k > 80 && stoch_k < stoch_d) sell_signals++;
    if(williams_r > -20) sell_signals++;
    if(cci > 100) sell_signals++;
    
    // Decision logic
    if(buy_signals >= 3) return 1;  // Buy signal
    if(sell_signals >= 3) return -1; // Sell signal
    
    return 0; // No clear signal
}

//+------------------------------------------------------------------+
//| Open buy trade                                                  |
//+------------------------------------------------------------------+
void OpenBuyTrade()
{
    double lot_size = CalculateLotSize();
    double stop_loss = CalculateStopLoss(true);
    double take_profit = CalculateTakeProfit(true, stop_loss);
    
    int ticket = OrderSend(Symbol(), OP_BUY, lot_size, Ask, Slippage, stop_loss, take_profit, 
                          "UltraTrend Buy", MagicNumber, 0, clrGreen);
    
    if(ticket > 0)
    {
        Print("Buy order opened: Ticket=", ticket, " Lot=", lot_size, " SL=", stop_loss, " TP=", take_profit);
        last_trade_time = TimeCurrent();
    }
    else
    {
        Print("Error opening buy order: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Open sell trade                                                 |
//+------------------------------------------------------------------+
void OpenSellTrade()
{
    double lot_size = CalculateLotSize();
    double stop_loss = CalculateStopLoss(false);
    double take_profit = CalculateTakeProfit(false, stop_loss);
    
    int ticket = OrderSend(Symbol(), OP_SELL, lot_size, Bid, Slippage, stop_loss, take_profit, 
                          "UltraTrend Sell", MagicNumber, 0, clrRed);
    
    if(ticket > 0)
    {
        Print("Sell order opened: Ticket=", ticket, " Lot=", lot_size, " SL=", stop_loss, " TP=", take_profit);
        last_trade_time = TimeCurrent();
    }
    else
    {
        Print("Error opening sell order: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk                               |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
    if(!AutoLotSize) return LotSize;
    
    double account_balance = AccountBalance();
    double risk_amount = account_balance * RiskPercent / 100;
    double atr = iATR(Symbol(), TrendTimeframe, ATR_Period, 0);
    double stop_loss_pips = UseATR_SL ? atr * ATR_SL_Multiplier / Point : FixedSL;
    
    double lot_size = risk_amount / (stop_loss_pips * MarketInfo(Symbol(), MODE_TICKVALUE));
    lot_size = MathFloor(lot_size / MarketInfo(Symbol(), MODE_LOTSTEP)) * MarketInfo(Symbol(), MODE_LOTSTEP);
    
    // Ensure lot size is within limits
    double min_lot = MarketInfo(Symbol(), MODE_MINLOT);
    double max_lot = MarketInfo(Symbol(), MODE_MAXLOT);
    
    return MathMax(min_lot, MathMin(max_lot, lot_size));
}

//+------------------------------------------------------------------+
//| Calculate stop loss                                             |
//+------------------------------------------------------------------+
double CalculateStopLoss(bool is_buy)
{
    if(UseATR_SL)
    {
        double atr = iATR(Symbol(), TrendTimeframe, ATR_Period, 0);
        double atr_stop = atr * ATR_SL_Multiplier;
        
        if(is_buy)
            return Bid - atr_stop;
        else
            return Ask + atr_stop;
    }
    else
    {
        if(is_buy)
            return Bid - FixedSL * Point * point_factor;
        else
            return Ask + FixedSL * Point * point_factor;
    }
}

//+------------------------------------------------------------------+
//| Calculate take profit                                           |
//+------------------------------------------------------------------+
double CalculateTakeProfit(bool is_buy, double stop_loss)
{
    double stop_loss_pips = MathAbs((is_buy ? Bid - stop_loss : stop_loss - Ask) / (Point * point_factor));
    
    if(UseDynamicTP)
    {
        double atr = iATR(Symbol(), TrendTimeframe, ATR_Period, 0);
        double volatility_tp = stop_loss_pips * VolatilityTP * (atr / (Point * point_factor));
        
        double base_tp = stop_loss_pips * BaseTP;
        double final_tp = MathMax(base_tp, volatility_tp);
        
        if(UseMarketStructure)
        {
            if(is_buy && trend_direction == 1)
                final_tp *= 1.2; // Increase TP for strong bullish trends
            else if(!is_buy && trend_direction == -1)
                final_tp *= 1.2; // Increase TP for strong bearish trends
        }
        
        if(is_buy)
            return Ask + final_tp * Point * point_factor;
        else
            return Bid - final_tp * Point * point_factor;
    }
    else
    {
        double take_profit_pips = stop_loss_pips * RiskRewardRatio;
        
        if(is_buy)
            return Ask + take_profit_pips * Point * point_factor;
        else
            return Bid - take_profit_pips * Point * point_factor;
    }
}

//+------------------------------------------------------------------+
//| Manage existing trades                                          |
//+------------------------------------------------------------------+
void ManageExistingTrades()
{
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
                // Check for break-even
                if(UseBreakEven) CheckBreakEven();
                
                // Check for partial close
                if(UsePartialClose) CheckPartialClose();
                
                // Check for manual close conditions
                CheckManualCloseConditions();
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check break-even conditions                                     |
//+------------------------------------------------------------------+
void CheckBreakEven()
{
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
                double open_price = OrderOpenPrice();
                double current_price = (OrderType() == OP_BUY) ? Bid : Ask;
                double profit_pips = MathAbs(current_price - open_price) / (Point * point_factor);
                
                if(profit_pips >= BreakEvenPips)
                {
                    double new_stop_loss = open_price;
                    
                    if(OrderModify(OrderTicket(), open_price, new_stop_loss, OrderTakeProfit(), 0, clrBlue))
                    {
                        Print("Stop loss moved to break-even for order: ", OrderTicket());
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check partial close conditions                                  |
//+------------------------------------------------------------------+
void CheckPartialClose()
{
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
                double open_price = OrderOpenPrice();
                double current_price = (OrderType() == OP_BUY) ? Bid : Ask;
                double profit_pips = MathAbs(current_price - open_price) / (Point * point_factor);
                
                double target_pips = MathAbs(OrderStopLoss() - open_price) / (Point * point_factor) * PartialCloseTarget;
                
                if(profit_pips >= target_pips)
                {
                    double partial_lot = OrderLots() * PartialClosePercent / 100;
                    
                    if(OrderClose(OrderTicket(), partial_lot, current_price, Slippage, clrOrange))
                    {
                        Print("Partial close executed for order: ", OrderTicket(), " Lot: ", partial_lot);
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check manual close conditions                                   |
//+------------------------------------------------------------------+
void CheckManualCloseConditions()
{
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
                // Close if trend reverses
                int current_trend = AnalyzeTrend();
                if((OrderType() == OP_BUY && current_trend == -1) || 
                   (OrderType() == OP_SELL && current_trend == 1))
                {
                    double close_price = (OrderType() == OP_BUY) ? Bid : Ask;
                    if(OrderClose(OrderTicket(), OrderLots(), close_price, Slippage, clrRed))
                    {
                        Print("Order closed due to trend reversal: ", OrderTicket());
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Update trailing stops                                            |
//+------------------------------------------------------------------+
void UpdateTrailingStops()
{
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
                double current_price = (OrderType() == OP_BUY) ? Bid : Ask;
                double open_price = OrderOpenPrice();
                double profit_pips = MathAbs(current_price - open_price) / (Point * point_factor);
                
                if(profit_pips >= TrailingStart)
                {
                    double new_stop_loss = 0;
                    
                    if(OrderType() == OP_BUY)
                    {
                        new_stop_loss = current_price - TrailingStep * Point * point_factor;
                        if(new_stop_loss > OrderStopLoss())
                        {
                            if(OrderModify(OrderTicket(), open_price, new_stop_loss, OrderTakeProfit(), 0, clrBlue))
                            {
                                Print("Trailing stop updated for buy order: ", OrderTicket());
                            }
                        }
                    }
                    else if(OrderType() == OP_SELL)
                    {
                        new_stop_loss = current_price + TrailingStep * Point * point_factor;
                        if(new_stop_loss < OrderStopLoss() || OrderStopLoss() == 0)
                        {
                            if(OrderModify(OrderTicket(), open_price, new_stop_loss, OrderTakeProfit(), 0, clrBlue))
                            {
                                Print("Trailing stop updated for sell order: ", OrderTicket());
                            }
                        }
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Utility functions                                               |
//+------------------------------------------------------------------+
int CountOpenTrades()
{
    int count = 0;
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
                count++;
        }
    }
    return count;
}

double CalculateDailyProfit()
{
    double profit = 0;
    datetime today_start = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
    
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
                if(OrderCloseTime() >= today_start)
                {
                    profit += OrderProfit() + OrderSwap() + OrderCommission();
                }
            }
        }
    }
    
    return profit;
}

double CalculateTotalProfit()
{
    double profit = 0;
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
                profit += OrderProfit() + OrderSwap() + OrderCommission();
            }
        }
    }
    return profit;
}

bool IsWithinTradingHours()
{
    int current_hour = TimeHour(TimeCurrent());
    return (current_hour >= StartHour && current_hour < EndHour);
}

bool IsVolatilitySufficient()
{
    double atr = iATR(Symbol(), TrendTimeframe, ATR_Period, 0);
    double atr_avg = 0;
    
    for(int i = 1; i <= 20; i++)
        atr_avg += iATR(Symbol(), TrendTimeframe, ATR_Period, i);
    atr_avg /= 20;
    
    return (atr / atr_avg) >= MinVolatility;
}

//+------------------------------------------------------------------+
//| Order history functions                                         |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                       const MqlTradeRequest& request,
                       const MqlTradeResult& result)
{
    if(trans.symbol == Symbol() && trans.magic == MagicNumber)
    {
        if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
        {
            // Update statistics
            if(trans.deal_type == DEAL_TYPE_BUY || trans.deal_type == DEAL_TYPE_SELL)
            {
                if(trans.price_profit > 0)
                {
                    consecutive_wins++;
                    consecutive_losses = 0;
                }
                else if(trans.price_profit < 0)
                {
                    consecutive_losses++;
                    consecutive_wins = 0;
                }
            }
        }
    }
}