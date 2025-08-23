//+------------------------------------------------------------------+
//|                                        UltraAdvancedTrendEA.mq5 |
//|                                  Copyright 2024, Ultra Trader |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Ultra Trader"
#property link      ""
#property version   "2.00"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\OrderInfo.mqh>

//--- Input Parameters
input group "=== EA Settings ==="
input double  LotSize = 0.01;              // Lot size
input bool    AutoLotSize = true;          // Auto calculate lot size based on risk
input double  RiskPercent = 1.5;           // Risk percentage per trade
input ulong   MagicNumber = 2024;          // Magic number
input uint    Slippage = 3;                // Maximum slippage

input group "=== Trend Following Settings ==="
input ENUM_TIMEFRAMES TrendTimeframe = PERIOD_H1;    // Trend timeframe
input ENUM_TIMEFRAMES EntryTimeframe = PERIOD_M1;    // Entry timeframe
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
input int     Ichimoku_Tenkan = 9;         // Ichimoku Tenkan-sen
input int     Ichimoku_Kijun = 26;         // Ichimoku Kijun-sen
input int     Ichimoku_Senkou = 52;        // Ichimoku Senkou Span B

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
input bool    UseMartingale = false;       // Use martingale recovery
input double  MartingaleMultiplier = 1.5;  // Martingale lot multiplier
input int     MaxMartingaleLevel = 3;      // Maximum martingale levels

input group "=== Profit Optimization ==="
input bool    UseDynamicTP = true;         // Use dynamic take profit
input double  BaseTP = 2.0;                // Base take profit multiplier
input double  VolatilityTP = 1.5;          // Volatility-based TP multiplier
input bool    UseMarketStructure = true;   // Use market structure for TP
input bool    UseFibonacciTP = true;       // Use Fibonacci levels for TP
input bool    UseSupportResistance = true; // Use S/R levels for TP
input bool    UseIchimokuTP = true;        // Use Ichimoku levels for TP

input group "=== Trading Time & Filters ==="
input bool    UseTimeFilter = true;        // Use time filter
input int     StartHour = 2;               // Start trading hour (GMT)
input int     EndHour = 22;                // End trading hour (GMT)
input bool    AvoidNews = true;            // Avoid trading during news
input bool    UseSpreadFilter = true;      // Use spread filter
input double  MaxSpread = 5;               // Maximum allowed spread
input bool    UseVolatilityFilter = true;  // Use volatility filter
input double  MinVolatility = 0.8;         // Minimum volatility threshold
input bool    UseVolumeFilter = true;      // Use volume filter
input double  MinVolume = 1.2;             // Minimum volume threshold

//--- Global Variables
CTrade trade;
CPositionInfo position;
CAccountInfo account;
COrderInfo order;

double point_factor;
int total_orders = 0;
datetime last_trade_time = 0;
double daily_profit = 0;
double max_daily_loss = -200;
double total_profit = 0;
int consecutive_losses = 0;
int consecutive_wins = 0;
int martingale_level = 0;

// Market structure variables
double last_high = 0;
double last_low = 0;
int trend_direction = 0; // 1=bullish, -1=bearish, 0=sideways

// Indicator handles
int rsi_handle;
int macd_handle;
int ema_fast_handle;
int ema_slow_handle;
int ema_trend_handle;
int bb_handle;
int atr_handle;
int momentum_handle;
int stoch_handle;
int williams_r_handle;
int cci_handle;
int ichimoku_handle;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize trading class
    trade.SetExpertMagicNumber(MagicNumber);
    trade.SetDeviationInPoints(Slippage);
    trade.SetTypeFilling(ORDER_FILLING_FOK);
    
    // Initialize point factor
    point_factor = (Digits() == 5 || Digits() == 3) ? 10 : 1;
    
    // Initialize indicators
    rsi_handle = iRSI(Symbol(), EntryTimeframe, RSI_Period, PRICE_CLOSE);
    macd_handle = iMACD(Symbol(), EntryTimeframe, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE);
    ema_fast_handle = iMA(Symbol(), EntryTimeframe, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
    ema_slow_handle = iMA(Symbol(), EntryTimeframe, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
    ema_trend_handle = iMA(Symbol(), TrendTimeframe, EMA_Trend, 0, MODE_EMA, PRICE_CLOSE);
    bb_handle = iBands(Symbol(), EntryTimeframe, BB_Period, 0, BB_Deviation, PRICE_CLOSE);
    atr_handle = iATR(Symbol(), TrendTimeframe, ATR_Period);
    momentum_handle = iMomentum(Symbol(), EntryTimeframe, 10, PRICE_CLOSE);
    stoch_handle = iStochastic(Symbol(), EntryTimeframe, Stochastic_K, Stochastic_D, Stochastic_Slow, MODE_SMA, 0);
    williams_r_handle = iWPR(Symbol(), EntryTimeframe, WilliamsR_Period);
    cci_handle = iCCI(Symbol(), EntryTimeframe, CCI_Period, PRICE_TYPICAL);
    ichimoku_handle = iIchimoku(Symbol(), EntryTimeframe, Ichimoku_Tenkan, Ichimoku_Kijun, Ichimoku_Senkou);
    
    // Check indicator handles
    if(rsi_handle == INVALID_HANDLE || macd_handle == INVALID_HANDLE || 
       ema_fast_handle == INVALID_HANDLE || ema_slow_handle == INVALID_HANDLE ||
       ema_trend_handle == INVALID_HANDLE || bb_handle == INVALID_HANDLE ||
       atr_handle == INVALID_HANDLE || momentum_handle == INVALID_HANDLE ||
       stoch_handle == INVALID_HANDLE || williams_r_handle == INVALID_HANDLE ||
       cci_handle == INVALID_HANDLE || ichimoku_handle == INVALID_HANDLE)
    {
        Print("Error initializing indicators");
        return(INIT_FAILED);
    }
    
    // Initialize market structure
    InitializeMarketStructure();
    
    Print("=== Ultra Advanced Trend EA Initialized ===");
    Print("Point factor: ", point_factor);
    Print("Current spread: ", SymbolInfoInteger(Symbol(), SYMBOL_SPREAD));
    Print("Account balance: ", account.Balance());
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
    if(!MQLInfoInteger(MQL_TRADE_ALLOWED)) return;
    
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
    double high_array[], low_array[];
    ArraySetAsSeries(high_array, true);
    ArraySetAsSeries(low_array, true);
    
    int copied_high = CopyHigh(Symbol(), TrendTimeframe, 0, 20, high_array);
    int copied_low = CopyLow(Symbol(), TrendTimeframe, 0, 20, low_array);
    
    if(copied_high > 0 && copied_low > 0)
    {
        last_high = high_array[ArrayMaximum(high_array, 0, copied_high)];
        last_low = low_array[ArrayMinimum(low_array, 0, copied_low)];
    }
    
    trend_direction = 0;
}

//+------------------------------------------------------------------+
//| Update market structure                                         |
//+------------------------------------------------------------------+
void UpdateMarketStructure()
{
    double high_array[], low_array[];
    ArraySetAsSeries(high_array, true);
    ArraySetAsSeries(low_array, true);
    
    int copied_high = CopyHigh(Symbol(), TrendTimeframe, 0, 10, high_array);
    int copied_low = CopyLow(Symbol(), TrendTimeframe, 0, 10, low_array);
    
    if(copied_high > 0 && copied_low > 0)
    {
        double current_high = high_array[ArrayMaximum(high_array, 0, copied_high)];
        double current_low = low_array[ArrayMinimum(low_array, 0, copied_low)];
        
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
    if(UseSpreadFilter && SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) > MaxSpread * point_factor) return false;
    
    // Check volatility filter
    if(UseVolatilityFilter && !IsVolatilitySufficient()) return false;
    
    // Check volume filter
    if(UseVolumeFilter && !IsVolumeSufficient()) return false;
    
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
    double ema_trend_array[], ema_fast_array[], ema_slow_array[];
    ArraySetAsSeries(ema_trend_array, true);
    ArraySetAsSeries(ema_fast_array, true);
    ArraySetAsSeries(ema_slow_array, true);
    
    int copied_trend = CopyBuffer(ema_trend_handle, 0, 0, 1, ema_trend_array);
    int copied_fast = CopyBuffer(ema_fast_handle, 0, 0, 1, ema_fast_array);
    int copied_slow = CopyBuffer(ema_slow_handle, 0, 0, 1, ema_slow_array);
    
    if(copied_trend <= 0 || copied_fast <= 0 || copied_slow <= 0) return 0;
    
    double ema_trend = ema_trend_array[0];
    double ema_fast = ema_fast_array[0];
    double ema_slow = ema_slow_array[0];
    
    double close_array[];
    ArraySetAsSeries(close_array, true);
    int copied_close = CopyClose(Symbol(), TrendTimeframe, 0, 1, close_array);
    if(copied_close <= 0) return 0;
    
    double close = close_array[0];
    
    // Multi-timeframe trend confirmation
    int mtf_trend = 0;
    if(MultiTimeframe)
    {
        int mtf_ema_handle = iMA(Symbol(), (ENUM_TIMEFRAMES)((int)TrendTimeframe * 4), EMA_Trend, 0, MODE_EMA, PRICE_CLOSE);
        if(mtf_ema_handle != INVALID_HANDLE)
        {
            double mtf_ema_array[];
            ArraySetAsSeries(mtf_ema_array, true);
            int copied_mtf = CopyBuffer(mtf_ema_handle, 0, 0, 1, mtf_ema_array);
            if(copied_mtf > 0)
            {
                double mtf_ema = mtf_ema_array[0];
                if(close > mtf_ema) mtf_trend = 1;
                else mtf_trend = -1;
            }
            IndicatorRelease(mtf_ema_handle);
        }
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
    double atr_array[];
    ArraySetAsSeries(atr_array, true);
    int copied_atr = CopyBuffer(atr_handle, 0, 0, 10, atr_array);
    
    if(copied_atr <= 0) return 0.5;
    
    double atr = atr_array[0];
    double atr_avg = 0;
    
    // Calculate average ATR
    for(int i = 1; i < copied_atr; i++)
        atr_avg += atr_array[i];
    atr_avg /= (copied_atr - 1);
    
    // Normalize trend strength
    double strength = MathMin(atr / atr_avg, 2.0) / 2.0;
    
    // Add momentum confirmation
    double momentum_array[];
    ArraySetAsSeries(momentum_array, true);
    int copied_momentum = CopyBuffer(momentum_handle, 0, 0, 5, momentum_array);
    
    if(copied_momentum > 0)
    {
        double momentum = momentum_array[0];
        double momentum_avg = 0;
        for(int i = 1; i < copied_momentum; i++)
            momentum_avg += momentum_array[i];
        momentum_avg /= (copied_momentum - 1);
        
        if(momentum > momentum_avg) strength += 0.2;
        if(momentum < momentum_avg) strength -= 0.2;
    }
    
    return MathMax(0.0, MathMin(1.0, strength));
}

//+------------------------------------------------------------------+
//| Analyze entry signals                                           |
//+------------------------------------------------------------------+
int AnalyzeEntrySignals()
{
    double rsi_array[], macd_main_array[], macd_signal_array[];
    double bb_upper_array[], bb_lower_array[];
    double stoch_k_array[], stoch_d_array[];
    double williams_r_array[], cci_array[];
    
    ArraySetAsSeries(rsi_array, true);
    ArraySetAsSeries(macd_main_array, true);
    ArraySetAsSeries(macd_signal_array, true);
    ArraySetAsSeries(bb_upper_array, true);
    ArraySetAsSeries(bb_lower_array, true);
    ArraySetAsSeries(stoch_k_array, true);
    ArraySetAsSeries(stoch_d_array, true);
    ArraySetAsSeries(williams_r_array, true);
    ArraySetAsSeries(cci_array, true);
    
    int copied_rsi = CopyBuffer(rsi_handle, 0, 0, 2, rsi_array);
    int copied_macd_main = CopyBuffer(macd_handle, 0, 0, 2, macd_main_array);
    int copied_macd_signal = CopyBuffer(macd_handle, 1, 0, 2, macd_signal_array);
    int copied_bb_upper = CopyBuffer(bb_handle, 1, 0, 1, bb_upper_array);
    int copied_bb_lower = CopyBuffer(bb_handle, 2, 0, 1, bb_lower_array);
    int copied_stoch_k = CopyBuffer(stoch_handle, 0, 0, 1, stoch_k_array);
    int copied_stoch_d = CopyBuffer(stoch_handle, 1, 0, 1, stoch_d_array);
    int copied_williams_r = CopyBuffer(williams_r_handle, 0, 0, 1, williams_r_array);
    int copied_cci = CopyBuffer(cci_handle, 0, 0, 1, cci_array);
    
    if(copied_rsi <= 0 || copied_macd_main <= 0 || copied_macd_signal <= 0) return 0;
    
    double rsi = rsi_array[0];
    double macd_main = macd_main_array[0];
    double macd_signal = macd_signal_array[0];
    double macd_main_prev = macd_main_array[1];
    double macd_signal_prev = macd_signal_array[1];
    
    double close_array[];
    ArraySetAsSeries(close_array, true);
    int copied_close = CopyClose(Symbol(), EntryTimeframe, 0, 1, close_array);
    if(copied_close <= 0) return 0;
    
    double close = close_array[0];
    
    // Buy signals
    int buy_signals = 0;
    if(rsi < RSI_Oversold) buy_signals++;
    if(macd_main > macd_signal && macd_main_prev <= macd_signal_prev) buy_signals++;
    if(copied_bb_lower > 0 && close < bb_lower_array[0]) buy_signals++;
    if(copied_stoch_k > 0 && copied_stoch_d > 0 && stoch_k_array[0] < 20 && stoch_k_array[0] > stoch_d_array[0]) buy_signals++;
    if(copied_williams_r > 0 && williams_r_array[0] < -80) buy_signals++;
    if(copied_cci > 0 && cci_array[0] < -100) buy_signals++;
    
    // Sell signals
    int sell_signals = 0;
    if(rsi > RSI_Overbought) sell_signals++;
    if(macd_main < macd_signal && macd_main_prev >= macd_signal_prev) sell_signals++;
    if(copied_bb_upper > 0 && close > bb_upper_array[0]) sell_signals++;
    if(copied_stoch_k > 0 && copied_stoch_d > 0 && stoch_k_array[0] > 80 && stoch_k_array[0] < stoch_d_array[0]) sell_signals++;
    if(copied_williams_r > 0 && williams_r_array[0] > -20) sell_signals++;
    if(copied_cci > 0 && cci_array[0] > 100) sell_signals++;
    
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
    
    if(trade.Buy(lot_size, Symbol(), 0, stop_loss, take_profit, "UltraTrend Buy"))
    {
        Print("Buy order opened: Ticket=", trade.ResultOrder(), " Lot=", lot_size, " SL=", stop_loss, " TP=", take_profit);
        last_trade_time = TimeCurrent();
        martingale_level = 0;
    }
    else
    {
        Print("Error opening buy order: ", trade.ResultRetcodeDescription());
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
    
    if(trade.Sell(lot_size, Symbol(), 0, stop_loss, take_profit, "UltraTrend Sell"))
    {
        Print("Sell order opened: Ticket=", trade.ResultOrder(), " Lot=", lot_size, " SL=", stop_loss, " TP=", take_profit);
        last_trade_time = TimeCurrent();
        martingale_level = 0;
    }
    else
    {
        Print("Error opening sell order: ", trade.ResultRetcodeDescription());
    }
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk                               |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
    if(!AutoLotSize) return LotSize;
    
    // Apply martingale if enabled
    if(UseMartingale && martingale_level > 0 && martingale_level <= MaxMartingaleLevel)
    {
        return LotSize * MathPow(MartingaleMultiplier, martingale_level);
    }
    
    double account_balance = account.Balance();
    double risk_amount = account_balance * RiskPercent / 100;
    
    double atr_array[];
    ArraySetAsSeries(atr_array, true);
    int copied_atr = CopyBuffer(atr_handle, 0, 0, 1, atr_array);
    
    if(copied_atr <= 0) return LotSize;
    
    double atr = atr_array[0];
    double stop_loss_pips = UseATR_SL ? atr * ATR_SL_Multiplier / Point() : FixedSL;
    
    double tick_value = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
    double lot_size = risk_amount / (stop_loss_pips * tick_value);
    
    // Ensure lot size is within limits
    double min_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
    double lot_step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
    
    lot_size = MathFloor(lot_size / lot_step) * lot_step;
    
    return MathMax(min_lot, MathMin(max_lot, lot_size));
}

//+------------------------------------------------------------------+
//| Calculate stop loss                                             |
//+------------------------------------------------------------------+
double CalculateStopLoss(bool is_buy)
{
    if(UseATR_SL)
    {
        double atr_array[];
        ArraySetAsSeries(atr_array, true);
        int copied_atr = CopyBuffer(atr_handle, 0, 0, 1, atr_array);
        
        if(copied_atr <= 0) return 0;
        
        double atr = atr_array[0];
        double atr_stop = atr * ATR_SL_Multiplier;
        
        if(is_buy)
            return SymbolInfoDouble(Symbol(), SYMBOL_BID) - atr_stop;
        else
            return SymbolInfoDouble(Symbol(), SYMBOL_ASK) + atr_stop;
    }
    else
    {
        if(is_buy)
            return SymbolInfoDouble(Symbol(), SYMBOL_BID) - FixedSL * Point() * point_factor;
        else
            return SymbolInfoDouble(Symbol(), SYMBOL_ASK) + FixedSL * Point() * point_factor;
    }
}

//+------------------------------------------------------------------+
//| Calculate take profit                                           |
//+------------------------------------------------------------------+
double CalculateTakeProfit(bool is_buy, double stop_loss)
{
    double stop_loss_pips = 0;
    
    if(is_buy)
        stop_loss_pips = MathAbs((SymbolInfoDouble(Symbol(), SYMBOL_BID) - stop_loss) / (Point() * point_factor));
    else
        stop_loss_pips = MathAbs((stop_loss - SymbolInfoDouble(Symbol(), SYMBOL_ASK)) / (Point() * point_factor));
    
    if(UseDynamicTP)
    {
        double atr_array[];
        ArraySetAsSeries(atr_array, true);
        int copied_atr = CopyBuffer(atr_handle, 0, 0, 1, atr_array);
        
        if(copied_atr > 0)
        {
            double atr = atr_array[0];
            double volatility_tp = stop_loss_pips * VolatilityTP * (atr / (Point() * point_factor));
            
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
                return SymbolInfoDouble(Symbol(), SYMBOL_ASK) + final_tp * Point() * point_factor;
            else
                return SymbolInfoDouble(Symbol(), SYMBOL_BID) - final_tp * Point() * point_factor;
        }
    }
    
    // Default TP calculation
    double take_profit_pips = stop_loss_pips * RiskRewardRatio;
    
    if(is_buy)
        return SymbolInfoDouble(Symbol(), SYMBOL_ASK) + take_profit_pips * Point() * point_factor;
    else
        return SymbolInfoDouble(Symbol(), SYMBOL_BID) - take_profit_pips * Point() * point_factor;
}

//+------------------------------------------------------------------+
//| Manage existing trades                                          |
//+------------------------------------------------------------------+
void ManageExistingTrades()
{
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Symbol() == Symbol() && position.Magic() == MagicNumber)
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
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Symbol() == Symbol() && position.Magic() == MagicNumber)
            {
                double open_price = position.PriceOpen();
                double current_price = (position.PositionType() == POSITION_TYPE_BUY) ? 
                                     SymbolInfoDouble(Symbol(), SYMBOL_BID) : 
                                     SymbolInfoDouble(Symbol(), SYMBOL_ASK);
                double profit_pips = MathAbs(current_price - open_price) / (Point() * point_factor);
                
                if(profit_pips >= BreakEvenPips)
                {
                    double new_stop_loss = open_price;
                    
                    if(trade.PositionModify(position.Ticket(), new_stop_loss, position.TakeProfit()))
                    {
                        Print("Stop loss moved to break-even for position: ", position.Ticket());
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
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Symbol() == Symbol() && position.Magic() == MagicNumber)
            {
                double open_price = position.PriceOpen();
                double current_price = (position.PositionType() == POSITION_TYPE_BUY) ? 
                                     SymbolInfoDouble(Symbol(), SYMBOL_BID) : 
                                     SymbolInfoDouble(Symbol(), SYMBOL_ASK);
                double profit_pips = MathAbs(current_price - open_price) / (Point() * point_factor);
                
                double stop_loss_pips = MathAbs(position.StopLoss() - open_price) / (Point() * point_factor);
                double target_pips = stop_loss_pips * PartialCloseTarget;
                
                if(profit_pips >= target_pips)
                {
                    double partial_lot = position.Volume() * PartialClosePercent / 100;
                    
                    if(trade.PositionClosePartial(position.Ticket(), partial_lot))
                    {
                        Print("Partial close executed for position: ", position.Ticket(), " Lot: ", partial_lot);
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
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Symbol() == Symbol() && position.Magic() == MagicNumber)
            {
                // Close if trend reverses
                int current_trend = AnalyzeTrend();
                if((position.PositionType() == POSITION_TYPE_BUY && current_trend == -1) || 
                   (position.PositionType() == POSITION_TYPE_SELL && current_trend == 1))
                {
                    if(trade.PositionClose(position.Ticket()))
                    {
                        Print("Position closed due to trend reversal: ", position.Ticket());
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
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Symbol() == Symbol() && position.Magic() == MagicNumber)
            {
                double current_price = (position.PositionType() == POSITION_TYPE_BUY) ? 
                                     SymbolInfoDouble(Symbol(), SYMBOL_BID) : 
                                     SymbolInfoDouble(Symbol(), SYMBOL_ASK);
                double open_price = position.PriceOpen();
                double profit_pips = MathAbs(current_price - open_price) / (Point() * point_factor);
                
                if(profit_pips >= TrailingStart)
                {
                    double new_stop_loss = 0;
                    
                    if(position.PositionType() == POSITION_TYPE_BUY)
                    {
                        new_stop_loss = current_price - TrailingStep * Point() * point_factor;
                        if(new_stop_loss > position.StopLoss())
                        {
                            if(trade.PositionModify(position.Ticket(), new_stop_loss, position.TakeProfit()))
                            {
                                Print("Trailing stop updated for buy position: ", position.Ticket());
                            }
                        }
                    }
                    else if(position.PositionType() == POSITION_TYPE_SELL)
                    {
                        new_stop_loss = current_price + TrailingStep * Point() * point_factor;
                        if(new_stop_loss < position.StopLoss() || position.StopLoss() == 0)
                        {
                            if(trade.PositionModify(position.Ticket(), new_stop_loss, position.TakeProfit()))
                            {
                                Print("Trailing stop updated for sell position: ", position.Ticket());
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
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Symbol() == Symbol() && position.Magic() == MagicNumber)
                count++;
        }
    }
    return count;
}

double CalculateDailyProfit()
{
    double profit = 0;
    datetime today_start = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
    
    for(int i = 0; i < HistoryDealsTotal(); i++)
    {
        ulong ticket = HistoryDealGetTicket(i);
        if(HistoryDealSelect(ticket))
        {
            if(HistoryDealGetString(ticket, DEAL_SYMBOL) == Symbol() && 
               HistoryDealGetInteger(ticket, DEAL_MAGIC) == MagicNumber)
            {
                if(HistoryDealGetInteger(ticket, DEAL_TIME) >= today_start)
                {
                    profit += HistoryDealGetDouble(ticket, DEAL_PROFIT);
                }
            }
        }
    }
    
    return profit;
}

double CalculateTotalProfit()
{
    double profit = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Symbol() == Symbol() && position.Magic() == MagicNumber)
            {
                profit += position.Profit();
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
    double atr_array[];
    ArraySetAsSeries(atr_array, true);
    int copied_atr = CopyBuffer(atr_handle, 0, 0, 20, atr_array);
    
    if(copied_atr <= 0) return true;
    
    double atr = atr_array[0];
    double atr_avg = 0;
    
    for(int i = 1; i < copied_atr; i++)
        atr_avg += atr_array[i];
    atr_avg /= (copied_atr - 1);
    
    return (atr / atr_avg) >= MinVolatility;
}

bool IsVolumeSufficient()
{
    long volume_array[];
    ArraySetAsSeries(volume_array, true);
    int copied_volume = CopyTickVolume(Symbol(), EntryTimeframe, 0, 10, volume_array);
    
    if(copied_volume <= 0) return true;
    
    double current_volume = volume_array[0];
    double avg_volume = 0;
    
    for(int i = 1; i < copied_volume; i++)
        avg_volume += volume_array[i];
    avg_volume /= (copied_volume - 1);
    
    return (current_volume / avg_volume) >= MinVolume;
}

//+------------------------------------------------------------------+
//| Trade transaction handler                                       |
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
                    
                    // Increment martingale level for losses
                    if(UseMartingale && martingale_level < MaxMartingaleLevel)
                    {
                        martingale_level++;
                    }
                }
            }
        }
    }
}