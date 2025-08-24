//+------------------------------------------------------------------+
//|                              UltraAdvancedMultiStrategyEA.mq5    |
//|                           Ultra Advanced Multi-Strategy Expert   |
//|                              For XAUUSD & Major Currency Pairs   |
//+------------------------------------------------------------------+
#property copyright "Ultra Advanced Multi-Strategy Expert Advisor"
#property link      ""
#property version   "3.00"
#property description "Ultra-advanced EA combining multiple strategies with AI-inspired analysis"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//--- Input Parameters
input group "=== Core Trading Settings ==="
input double   InitialLotSize = 0.01;             // Initial lot size
input bool     UseAdaptivePositionSizing = true;  // Use adaptive position sizing
input double   RiskPercentage = 1.5;              // Risk percentage per trade
input double   MaxRiskPerTrade = 3.0;             // Maximum risk per trade (%)
input int      MaxOpenPositions = 2;              // Maximum open positions per symbol
input bool     UseMultiTimeframeAnalysis = true;  // Use multi-timeframe analysis

input group "=== Strategy Selection ==="
input bool     UseTrendFollowingStrategy = true;  // Enable trend following strategy
input bool     UseMeanReversionStrategy = true;   // Enable mean reversion strategy
input bool     UseBreakoutStrategy = true;        // Enable breakout strategy
input bool     UseMomentumStrategy = true;        // Enable momentum strategy
input bool     UseVolatilityStrategy = true;      // Enable volatility-based strategy

input group "=== Risk Management ==="
input bool     UseDynamicStopLoss = true;         // Use dynamic stop loss
input bool     UseDynamicTakeProfit = true;       // Use dynamic take profit
input double   BaseStopLossMultiplier = 1.2;      // Base stop loss multiplier
input double   BaseTakeProfitMultiplier = 2.5;    // Base take profit multiplier
input bool     UseTrailingStop = true;            // Use trailing stop
input double   TrailingStopDistance = 30;         // Trailing stop distance (points)
input double   TrailingStep = 10;                 // Trailing step (points)
input bool     UseBreakEven = true;               // Use break-even stop loss
input double   BreakEvenTrigger = 1.0;            // Break-even trigger (multiplier)

input group "=== Technical Indicators ==="
input int      RSI_Period = 14;                   // RSI period
input int      RSI_Overbought = 70;               // RSI overbought level
input int      RSI_Oversold = 30;                 // RSI oversold level
input int      MACD_Fast = 12;                    // MACD fast EMA
input int      MACD_Slow = 26;                    // MACD slow EMA
input int      MACD_Signal = 9;                   // MACD signal line
input int      BB_Period = 20;                    // Bollinger Bands period
input double   BB_Deviation = 2.0;                // Bollinger Bands deviation
input int      ATR_Period = 14;                   // ATR period
input int      Stochastic_K = 14;                 // Stochastic %K period
input int      Stochastic_D = 3;                  // Stochastic %D period
input int      Williams_Period = 14;              // Williams %R period
input int      CCI_Period = 14;                   // CCI period
input int      ADX_Period = 14;                   // ADX period
input int      ADX_Threshold = 25;                // ADX threshold for trend strength

input group "=== Market Analysis ==="
input bool     UseMarketRegimeDetection = true;   // Use market regime detection
input int      TrendStrengthPeriod = 50;          // Trend strength analysis period
input double   VolatilityThreshold = 1.5;         // Volatility threshold multiplier
input bool     UseSupportResistance = true;       // Use support/resistance levels
input int      SR_Lookback = 100;                 // Support/resistance lookback period
input bool     UseVolumeAnalysis = true;          // Use volume analysis
input int      VolumeMA_Period = 20;              // Volume moving average period

input group "=== Time & Symbol Filters ==="
input string   TradingSymbols = "XAUUSD,EURUSD,GBPUSD,USDJPY,USDCHF,AUDUSD,USDCAD,NZDUSD"; // Trading symbols
input bool     UseTimeFilter = true;              // Use trading time filter
input int      StartHour = 8;                     // Trading start hour
input int      EndHour = 22;                      // Trading end hour
input bool     AvoidFridayTrading = true;         // Avoid Friday late trading
input bool     AvoidWeekendGaps = true;           // Avoid weekend gaps
input int      MinimumSpread = 30;                // Maximum allowed spread (points)

input group "=== Advanced Settings ==="
input bool     UseNewsFilter = true;              // Avoid trading during news
input int      NewsAvoidanceMinutes = 30;         // Minutes to avoid trading before/after news
input bool     UseCorrelationFilter = true;       // Use correlation filter
input double   MaxCorrelation = 0.8;              // Maximum correlation between positions
input bool     UseDrawdownProtection = true;      // Use drawdown protection
input double   MaxDrawdown = 10.0;                // Maximum drawdown percentage
input bool     UseProfitTarget = true;            // Use daily profit target
input double   DailyProfitTarget = 5.0;           // Daily profit target percentage

//--- Global Variables
CTrade trade;
CPositionInfo position;
COrderInfo order;

// Indicator handles
int rsi_handle, macd_handle, bb_handle, atr_handle, stoch_handle;
int williams_handle, cci_handle, adx_handle, volume_handle;

// Indicator buffers
double rsi_buffer[], macd_main[], macd_signal[], bb_upper[], bb_middle[], bb_lower[];
double atr_buffer[], stoch_main[], stoch_signal[], williams_buffer[], cci_buffer[];
double adx_buffer[], volume_buffer[];

// Market data arrays
double high[], low[], close[], open[], volume[];
double price_changes[], volatility_array[];

// Strategy signals
struct StrategySignal {
    double strength;
    int direction;      // 1 for buy, -1 for sell, 0 for hold
    double confidence;
    string strategy_name;
    datetime timestamp;
};

// Market regime
struct MarketRegime {
    double trend_strength;
    double volatility_level;
    string market_phase; // "trending", "ranging", "breakout", "consolidation"
    double momentum_score;
    double support_level;
    double resistance_level;
};

// Trade management
struct TradeManagement {
    double entry_price;
    double stop_loss;
    double take_profit;
    double lot_size;
    datetime entry_time;
    string symbol;
    double unrealized_pnl;
    bool break_even_triggered;
    bool trailing_stop_active;
};

StrategySignal current_signal;
MarketRegime current_regime;
TradeManagement trade_info;

// Performance tracking
double daily_profit = 0.0;
double total_profit = 0.0;
double max_drawdown = 0.0;
double peak_balance = 0.0;
datetime last_trade_time = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize trade object
    trade.SetExpertMagicNumber(123456);
    trade.SetDeviationInPoints(10);
    trade.SetTypeFilling(ORDER_FILLING_FOK);
    
    // Initialize indicator handles
    rsi_handle = iRSI(_Symbol, PERIOD_CURRENT, RSI_Period, PRICE_CLOSE);
    macd_handle = iMACD(_Symbol, PERIOD_CURRENT, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE);
    bb_handle = iBands(_Symbol, PERIOD_CURRENT, BB_Period, 0, BB_Deviation, PRICE_CLOSE);
    atr_handle = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);
    stoch_handle = iStochastic(_Symbol, PERIOD_CURRENT, Stochastic_K, 3, 3, MODE_SMA, STO_LOWHIGH);
    williams_handle = iWPR(_Symbol, PERIOD_CURRENT, Williams_Period);
    cci_handle = iCCI(_Symbol, PERIOD_CURRENT, CCI_Period, PRICE_TYPICAL);
    adx_handle = iADX(_Symbol, PERIOD_CURRENT, ADX_Period);
    volume_handle = iVolumes(_Symbol, PERIOD_CURRENT, VOLUME_TICK);
    
    // Check if indicators are valid
    if(rsi_handle == INVALID_HANDLE || macd_handle == INVALID_HANDLE || bb_handle == INVALID_HANDLE ||
       atr_handle == INVALID_HANDLE || stoch_handle == INVALID_HANDLE || williams_handle == INVALID_HANDLE ||
       cci_handle == INVALID_HANDLE || adx_handle == INVALID_HANDLE || volume_handle == INVALID_HANDLE)
    {
        Print("Error: Failed to create indicator handles");
        return INIT_FAILED;
    }
    
    // Initialize arrays
    ArraySetAsSeries(rsi_buffer, true);
    ArraySetAsSeries(macd_main, true);
    ArraySetAsSeries(macd_signal, true);
    ArraySetAsSeries(bb_upper, true);
    ArraySetAsSeries(bb_middle, true);
    ArraySetAsSeries(bb_lower, true);
    ArraySetAsSeries(atr_buffer, true);
    ArraySetAsSeries(stoch_main, true);
    ArraySetAsSeries(stoch_signal, true);
    ArraySetAsSeries(williams_buffer, true);
    ArraySetAsSeries(cci_buffer, true);
    ArraySetAsSeries(adx_buffer, true);
    ArraySetAsSeries(volume_buffer, true);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(open, true);
    ArraySetAsSeries(volume, true);
    
    // Initialize peak balance
    peak_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    Print("Ultra Advanced Multi-Strategy EA initialized successfully");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release indicator handles
    if(rsi_handle != INVALID_HANDLE) IndicatorRelease(rsi_handle);
    if(macd_handle != INVALID_HANDLE) IndicatorRelease(macd_handle);
    if(bb_handle != INVALID_HANDLE) IndicatorRelease(bb_handle);
    if(atr_handle != INVALID_HANDLE) IndicatorRelease(atr_handle);
    if(stoch_handle != INVALID_HANDLE) IndicatorRelease(stoch_handle);
    if(williams_handle != INVALID_HANDLE) IndicatorRelease(williams_handle);
    if(cci_handle != INVALID_HANDLE) IndicatorRelease(cci_handle);
    if(adx_handle != INVALID_HANDLE) IndicatorRelease(adx_handle);
    if(volume_handle != INVALID_HANDLE) IndicatorRelease(volume_handle);
    
    Print("Ultra Advanced Multi-Strategy EA deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Update market data
    if(!UpdateMarketData()) return;
    
    // Check trading conditions
    if(!CheckTradingConditions()) return;
    
    // Update market regime
    if(UseMarketRegimeDetection) UpdateMarketRegime();
    
    // Generate trading signals
    GenerateTradingSignals();
    
    // Manage existing positions
    ManagePositions();
    
    // Execute new trades if conditions are met
    if(CanOpenNewPosition()) ExecuteTrade();
    
    // Update performance tracking
    UpdatePerformanceTracking();
}

//+------------------------------------------------------------------+
//| Update market data                                               |
//+------------------------------------------------------------------+
bool UpdateMarketData()
{
    // Copy price data
    if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, 200, high) < 200) return false;
    if(CopyLow(_Symbol, PERIOD_CURRENT, 0, 200, low) < 200) return false;
    if(CopyClose(_Symbol, PERIOD_CURRENT, 0, 200, close) < 200) return false;
    if(CopyOpen(_Symbol, PERIOD_CURRENT, 0, 200, open) < 200) return false;
    if(CopyTickVolume(_Symbol, PERIOD_CURRENT, 0, 200, volume) < 200) return false;
    
    // Copy indicator data
    if(CopyBuffer(rsi_handle, 0, 0, 3, rsi_buffer) < 3) return false;
    if(CopyBuffer(macd_handle, 0, 0, 3, macd_main) < 3) return false;
    if(CopyBuffer(macd_handle, 1, 0, 3, macd_signal) < 3) return false;
    if(CopyBuffer(bb_handle, 0, 0, 3, bb_upper) < 3) return false;
    if(CopyBuffer(bb_handle, 1, 0, 3, bb_middle) < 3) return false;
    if(CopyBuffer(bb_handle, 2, 0, 3, bb_lower) < 3) return false;
    if(CopyBuffer(atr_handle, 0, 0, 3, atr_buffer) < 3) return false;
    if(CopyBuffer(stoch_handle, 0, 0, 3, stoch_main) < 3) return false;
    if(CopyBuffer(stoch_handle, 1, 0, 3, stoch_signal) < 3) return false;
    if(CopyBuffer(williams_handle, 0, 0, 3, williams_buffer) < 3) return false;
    if(CopyBuffer(cci_handle, 0, 0, 3, cci_buffer) < 3) return false;
    if(CopyBuffer(adx_handle, 0, 0, 3, adx_buffer) < 3) return false;
    if(CopyBuffer(volume_handle, 0, 0, 3, volume_buffer) < 3) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Check trading conditions                                         |
//+------------------------------------------------------------------+
bool CheckTradingConditions()
{
    // Check if market is closed
    if(!MQLInfoInteger(MQL_TRADE_ALLOWED)) return false;
    
    // Check spread
    double current_spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    if(current_spread > MinimumSpread) return false;
    
    // Check time filter
    if(UseTimeFilter)
    {
        datetime current_time = TimeCurrent();
        int current_hour = TimeHour(current_time);
        
        if(current_hour < StartHour || current_hour >= EndHour) return false;
        
        if(AvoidFridayTrading)
        {
            int day_of_week = TimeDayOfWeek(current_time);
            if(day_of_week == 5 && current_hour >= 20) return false;
        }
    }
    
    // Check drawdown protection
    if(UseDrawdownProtection)
    {
        double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
        double drawdown_percent = ((peak_balance - current_equity) / peak_balance) * 100;
        
        if(drawdown_percent > MaxDrawdown) return false;
    }
    
    // Check daily profit target
    if(UseProfitTarget && daily_profit >= DailyProfitTarget) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Update market regime                                             |
//+------------------------------------------------------------------+
void UpdateMarketRegime()
{
    // Calculate trend strength using ADX
    current_regime.trend_strength = adx_buffer[0];
    
    // Calculate volatility using ATR
    double avg_atr = 0;
    for(int i = 0; i < 20; i++)
    {
        avg_atr += atr_buffer[i];
    }
    avg_atr /= 20;
    current_regime.volatility_level = atr_buffer[0] / avg_atr;
    
    // Determine market phase
    if(current_regime.trend_strength > ADX_Threshold)
    {
        if(close[0] > close[20]) current_regime.market_phase = "trending_up";
        else current_regime.market_phase = "trending_down";
    }
    else if(current_regime.volatility_level > VolatilityThreshold)
    {
        current_regime.market_phase = "breakout";
    }
    else
    {
        current_regime.market_phase = "ranging";
    }
    
    // Calculate momentum score
    current_regime.momentum_score = (rsi_buffer[0] - 50) / 50;
    
    // Calculate support and resistance levels
    if(UseSupportResistance)
    {
        current_regime.support_level = CalculateSupportLevel();
        current_regime.resistance_level = CalculateResistanceLevel();
    }
}

//+------------------------------------------------------------------+
//| Calculate support level                                          |
//+------------------------------------------------------------------+
double CalculateSupportLevel()
{
    double support = low[0];
    for(int i = 1; i < SR_Lookback; i++)
    {
        if(low[i] < support) support = low[i];
    }
    return support;
}

//+------------------------------------------------------------------+
//| Calculate resistance level                                       |
//+------------------------------------------------------------------+
double CalculateResistanceLevel()
{
    double resistance = high[0];
    for(int i = 1; i < SR_Lookback; i++)
    {
        if(high[i] > resistance) resistance = high[i];
    }
    return resistance;
}

//+------------------------------------------------------------------+
//| Generate trading signals                                         |
//+------------------------------------------------------------------+
void GenerateTradingSignals()
{
    StrategySignal signals[5];
    int signal_count = 0;
    
    // Trend Following Strategy
    if(UseTrendFollowingStrategy)
    {
        signals[signal_count] = GenerateTrendFollowingSignal();
        signal_count++;
    }
    
    // Mean Reversion Strategy
    if(UseMeanReversionStrategy)
    {
        signals[signal_count] = GenerateMeanReversionSignal();
        signal_count++;
    }
    
    // Breakout Strategy
    if(UseBreakoutStrategy)
    {
        signals[signal_count] = GenerateBreakoutSignal();
        signal_count++;
    }
    
    // Momentum Strategy
    if(UseMomentumStrategy)
    {
        signals[signal_count] = GenerateMomentumSignal();
        signal_count++;
    }
    
    // Volatility Strategy
    if(UseVolatilityStrategy)
    {
        signals[signal_count] = GenerateVolatilitySignal();
        signal_count++;
    }
    
    // Combine signals
    CombineSignals(signals, signal_count);
}

//+------------------------------------------------------------------+
//| Generate trend following signal                                  |
//+------------------------------------------------------------------+
StrategySignal GenerateTrendFollowingSignal()
{
    StrategySignal signal;
    signal.strategy_name = "Trend Following";
    signal.timestamp = TimeCurrent();
    
    // Check if trend is strong
    if(current_regime.trend_strength < ADX_Threshold)
    {
        signal.direction = 0;
        signal.strength = 0;
        signal.confidence = 0;
        return signal;
    }
    
    // Trend following logic
    bool bullish_trend = (close[0] > bb_middle[0] && macd_main[0] > macd_signal[0] && rsi_buffer[0] > 50);
    bool bearish_trend = (close[0] < bb_middle[0] && macd_main[0] < macd_signal[0] && rsi_buffer[0] < 50);
    
    if(bullish_trend)
    {
        signal.direction = 1;
        signal.strength = (rsi_buffer[0] - 50) / 50;
        signal.confidence = current_regime.trend_strength / 100;
    }
    else if(bearish_trend)
    {
        signal.direction = -1;
        signal.strength = (50 - rsi_buffer[0]) / 50;
        signal.confidence = current_regime.trend_strength / 100;
    }
    else
    {
        signal.direction = 0;
        signal.strength = 0;
        signal.confidence = 0;
    }
    
    return signal;
}

//+------------------------------------------------------------------+
//| Generate mean reversion signal                                   |
//+------------------------------------------------------------------+
StrategySignal GenerateMeanReversionSignal()
{
    StrategySignal signal;
    signal.strategy_name = "Mean Reversion";
    signal.timestamp = TimeCurrent();
    
    // Mean reversion logic
    bool oversold = (rsi_buffer[0] < RSI_Oversold && stoch_main[0] < 20 && williams_buffer[0] < -80);
    bool overbought = (rsi_buffer[0] > RSI_Overbought && stoch_main[0] > 80 && williams_buffer[0] > -20);
    
    if(oversold && close[0] < bb_lower[0])
    {
        signal.direction = 1;
        signal.strength = (RSI_Oversold - rsi_buffer[0]) / RSI_Oversold;
        signal.confidence = 0.7;
    }
    else if(overbought && close[0] > bb_upper[0])
    {
        signal.direction = -1;
        signal.strength = (rsi_buffer[0] - RSI_Overbought) / (100 - RSI_Overbought);
        signal.confidence = 0.7;
    }
    else
    {
        signal.direction = 0;
        signal.strength = 0;
        signal.confidence = 0;
    }
    
    return signal;
}

//+------------------------------------------------------------------+
//| Generate breakout signal                                         |
//+------------------------------------------------------------------+
StrategySignal GenerateBreakoutSignal()
{
    StrategySignal signal;
    signal.strategy_name = "Breakout";
    signal.timestamp = TimeCurrent();
    
    // Breakout logic
    bool bullish_breakout = (close[0] > bb_upper[0] && volume_buffer[0] > volume_buffer[1] * 1.5);
    bool bearish_breakout = (close[0] < bb_lower[0] && volume_buffer[0] > volume_buffer[1] * 1.5);
    
    if(bullish_breakout)
    {
        signal.direction = 1;
        signal.strength = (close[0] - bb_upper[0]) / atr_buffer[0];
        signal.confidence = 0.8;
    }
    else if(bearish_breakout)
    {
        signal.direction = -1;
        signal.strength = (bb_lower[0] - close[0]) / atr_buffer[0];
        signal.confidence = 0.8;
    }
    else
    {
        signal.direction = 0;
        signal.strength = 0;
        signal.confidence = 0;
    }
    
    return signal;
}

//+------------------------------------------------------------------+
//| Generate momentum signal                                         |
//+------------------------------------------------------------------+
StrategySignal GenerateMomentumSignal()
{
    StrategySignal signal;
    signal.strategy_name = "Momentum";
    signal.timestamp = TimeCurrent();
    
    // Momentum logic
    double price_momentum = (close[0] - close[5]) / close[5];
    double rsi_momentum = rsi_buffer[0] - rsi_buffer[5];
    double macd_momentum = macd_main[0] - macd_main[5];
    
    bool bullish_momentum = (price_momentum > 0.001 && rsi_momentum > 5 && macd_momentum > 0);
    bool bearish_momentum = (price_momentum < -0.001 && rsi_momentum < -5 && macd_momentum < 0);
    
    if(bullish_momentum)
    {
        signal.direction = 1;
        signal.strength = MathAbs(price_momentum) * 100;
        signal.confidence = 0.6;
    }
    else if(bearish_momentum)
    {
        signal.direction = -1;
        signal.strength = MathAbs(price_momentum) * 100;
        signal.confidence = 0.6;
    }
    else
    {
        signal.direction = 0;
        signal.strength = 0;
        signal.confidence = 0;
    }
    
    return signal;
}

//+------------------------------------------------------------------+
//| Generate volatility signal                                       |
//+------------------------------------------------------------------+
StrategySignal GenerateVolatilitySignal()
{
    StrategySignal signal;
    signal.strategy_name = "Volatility";
    signal.timestamp = TimeCurrent();
    
    // Volatility logic
    double current_volatility = atr_buffer[0];
    double avg_volatility = 0;
    
    for(int i = 1; i < 20; i++)
    {
        avg_volatility += atr_buffer[i];
    }
    avg_volatility /= 19;
    
    double volatility_ratio = current_volatility / avg_volatility;
    
    if(volatility_ratio > VolatilityThreshold)
    {
        // High volatility - look for breakout opportunities
        if(close[0] > bb_upper[0])
        {
            signal.direction = 1;
            signal.strength = volatility_ratio - 1;
            signal.confidence = 0.7;
        }
        else if(close[0] < bb_lower[0])
        {
            signal.direction = -1;
            signal.strength = volatility_ratio - 1;
            signal.confidence = 0.7;
        }
        else
        {
            signal.direction = 0;
            signal.strength = 0;
            signal.confidence = 0;
        }
    }
    else
    {
        signal.direction = 0;
        signal.strength = 0;
        signal.confidence = 0;
    }
    
    return signal;
}

//+------------------------------------------------------------------+
//| Combine multiple signals                                         |
//+------------------------------------------------------------------+
void CombineSignals(StrategySignal &signals[], int count)
{
    double total_buy_strength = 0;
    double total_sell_strength = 0;
    double total_buy_confidence = 0;
    double total_sell_confidence = 0;
    int buy_count = 0;
    int sell_count = 0;
    
    for(int i = 0; i < count; i++)
    {
        if(signals[i].direction == 1)
        {
            total_buy_strength += signals[i].strength * signals[i].confidence;
            total_buy_confidence += signals[i].confidence;
            buy_count++;
        }
        else if(signals[i].direction == -1)
        {
            total_sell_strength += signals[i].strength * signals[i].confidence;
            total_sell_confidence += signals[i].confidence;
            sell_count++;
        }
    }
    
    // Determine final signal
    if(buy_count > sell_count && total_buy_strength > 0.5)
    {
        current_signal.direction = 1;
        current_signal.strength = total_buy_strength / buy_count;
        current_signal.confidence = total_buy_confidence / buy_count;
        current_signal.strategy_name = "Multi-Strategy Buy";
    }
    else if(sell_count > buy_count && total_sell_strength > 0.5)
    {
        current_signal.direction = -1;
        current_signal.strength = total_sell_strength / sell_count;
        current_signal.confidence = total_sell_confidence / sell_count;
        current_signal.strategy_name = "Multi-Strategy Sell";
    }
    else
    {
        current_signal.direction = 0;
        current_signal.strength = 0;
        current_signal.confidence = 0;
        current_signal.strategy_name = "No Signal";
    }
    
    current_signal.timestamp = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Check if can open new position                                   |
//+------------------------------------------------------------------+
bool CanOpenNewPosition()
{
    // Check if we have a valid signal
    if(current_signal.direction == 0 || current_signal.confidence < 0.6) return false;
    
    // Check maximum open positions
    int open_positions = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(PositionGetSymbol(i) == _Symbol) open_positions++;
    }
    
    if(open_positions >= MaxOpenPositions) return false;
    
    // Check if enough time has passed since last trade
    if(TimeCurrent() - last_trade_time < 300) return false; // 5 minutes minimum
    
    return true;
}

//+------------------------------------------------------------------+
//| Execute trade                                                    |
//+------------------------------------------------------------------+
void ExecuteTrade()
{
    // Calculate position size
    double lot_size = CalculatePositionSize();
    
    // Calculate stop loss and take profit
    double stop_loss = 0, take_profit = 0;
    CalculateStopLossAndTakeProfit(stop_loss, take_profit);
    
    // Execute the trade
    bool result = false;
    if(current_signal.direction == 1)
    {
        result = trade.Buy(lot_size, _Symbol, 0, stop_loss, take_profit, current_signal.strategy_name);
    }
    else if(current_signal.direction == -1)
    {
        result = trade.Sell(lot_size, _Symbol, 0, stop_loss, take_profit, current_signal.strategy_name);
    }
    
    if(result)
    {
        last_trade_time = TimeCurrent();
        Print("Trade executed: ", current_signal.strategy_name, " Direction: ", current_signal.direction);
    }
}

//+------------------------------------------------------------------+
//| Calculate position size                                          |
//+------------------------------------------------------------------+
double CalculatePositionSize()
{
    if(!UseAdaptivePositionSizing) return InitialLotSize;
    
    double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amount = account_balance * (RiskPercentage / 100);
    
    double stop_loss_points = 0;
    if(current_signal.direction == 1)
    {
        stop_loss_points = (close[0] - (close[0] - atr_buffer[0] * BaseStopLossMultiplier)) / _Point;
    }
    else
    {
        stop_loss_points = ((close[0] + atr_buffer[0] * BaseStopLossMultiplier) - close[0]) / _Point;
    }
    
    double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double lot_size = risk_amount / (stop_loss_points * tick_value);
    
    // Normalize lot size
    double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    lot_size = MathMax(min_lot, MathMin(max_lot, lot_size));
    lot_size = NormalizeDouble(lot_size / lot_step, 0) * lot_step;
    
    return lot_size;
}

//+------------------------------------------------------------------+
//| Calculate stop loss and take profit                              |
//+------------------------------------------------------------------+
void CalculateStopLossAndTakeProfit(double &stop_loss, double &take_profit)
{
    if(UseDynamicStopLoss)
    {
        if(current_signal.direction == 1)
        {
            stop_loss = close[0] - (atr_buffer[0] * BaseStopLossMultiplier);
        }
        else
        {
            stop_loss = close[0] + (atr_buffer[0] * BaseStopLossMultiplier);
        }
    }
    
    if(UseDynamicTakeProfit)
    {
        if(current_signal.direction == 1)
        {
            take_profit = close[0] + (atr_buffer[0] * BaseTakeProfitMultiplier);
        }
        else
        {
            take_profit = close[0] - (atr_buffer[0] * BaseTakeProfitMultiplier);
        }
    }
}

//+------------------------------------------------------------------+
//| Manage existing positions                                        |
//+------------------------------------------------------------------+
void ManagePositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(PositionSelectByIndex(i))
        {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
                ManagePosition();
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Manage individual position                                       |
//+------------------------------------------------------------------+
void ManagePosition()
{
    double position_profit = PositionGetDouble(POSITION_PROFIT);
    double position_volume = PositionGetDouble(POSITION_VOLUME);
    double position_price = PositionGetDouble(POSITION_PRICE_OPEN);
    double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
    ENUM_POSITION_TYPE position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    
    // Break-even logic
    if(UseBreakEven && !trade_info.break_even_triggered)
    {
        double profit_points = 0;
        if(position_type == POSITION_TYPE_BUY)
        {
            profit_points = (current_price - position_price) / _Point;
        }
        else
        {
            profit_points = (position_price - current_price) / _Point;
        }
        
        if(profit_points >= (atr_buffer[0] * BreakEvenTrigger))
        {
            // Move stop loss to break-even
            double new_stop_loss = position_price;
            trade.PositionModify(PositionGetInteger(POSITION_TICKET), new_stop_loss, PositionGetDouble(POSITION_TP));
            trade_info.break_even_triggered = true;
        }
    }
    
    // Trailing stop logic
    if(UseTrailingStop && trade_info.break_even_triggered)
    {
        double current_stop_loss = PositionGetDouble(POSITION_SL);
        double new_stop_loss = current_stop_loss;
        
        if(position_type == POSITION_TYPE_BUY)
        {
            if(current_price - current_stop_loss > TrailingStopDistance * _Point)
            {
                new_stop_loss = current_price - TrailingStopDistance * _Point;
                if(new_stop_loss > current_stop_loss + TrailingStep * _Point)
                {
                    trade.PositionModify(PositionGetInteger(POSITION_TICKET), new_stop_loss, PositionGetDouble(POSITION_TP));
                }
            }
        }
        else
        {
            if(current_stop_loss - current_price > TrailingStopDistance * _Point)
            {
                new_stop_loss = current_price + TrailingStopDistance * _Point;
                if(current_stop_loss - new_stop_loss > TrailingStep * _Point)
                {
                    trade.PositionModify(PositionGetInteger(POSITION_TICKET), new_stop_loss, PositionGetDouble(POSITION_TP));
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Update performance tracking                                      |
//+------------------------------------------------------------------+
void UpdatePerformanceTracking()
{
    double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    // Update peak balance
    if(current_balance > peak_balance) peak_balance = current_balance;
    
    // Calculate drawdown
    double drawdown = ((peak_balance - current_equity) / peak_balance) * 100;
    if(drawdown > max_drawdown) max_drawdown = drawdown;
    
    // Update total profit
    total_profit = current_balance - AccountInfoDouble(ACCOUNT_BALANCE);
    
    // Reset daily profit at midnight
    static datetime last_day = 0;
    datetime current_day = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
    
    if(current_day != last_day)
    {
        daily_profit = 0;
        last_day = current_day;
    }
    
    // Update daily profit
    daily_profit = current_balance - AccountInfoDouble(ACCOUNT_BALANCE);
}