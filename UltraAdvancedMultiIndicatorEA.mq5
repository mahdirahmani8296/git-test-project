//+------------------------------------------------------------------+
//|                                    UltraAdvancedMultiIndicatorEA.mq5 |
//|                                  Copyright 2024, Ultra Trader Pro |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Ultra Trader Pro"
#property link      ""
#property version   "3.00"
#property description "Ultra Advanced Multi-Indicator Expert Advisor with AI-like Decision Making"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Math\Stat\Math.mqh>

//--- Input Parameters
input group "=== EA Core Settings ==="
input double  LotSize = 0.01;              // Lot size
input bool    AutoLotSize = true;          // Auto calculate lot size based on risk
input double  RiskPercent = 1.0;           // Risk percentage per trade
input ulong   MagicNumber = 20241201;      // Magic number
input uint    Slippage = 3;                // Maximum slippage
input bool    EnableTrading = true;        // Enable/Disable trading

input group "=== Multi-Timeframe Analysis ==="
input ENUM_TIMEFRAMES TrendTimeframe = PERIOD_H4;    // Trend timeframe
input ENUM_TIMEFRAMES SignalTimeframe = PERIOD_H1;   // Signal timeframe
input ENUM_TIMEFRAMES EntryTimeframe = PERIOD_M15;   // Entry timeframe
input bool    MultiTimeframe = true;       // Use multi-timeframe analysis
input int     MaxOpenTrades = 3;           // Maximum open trades
input double  MinTrendStrength = 0.75;     // Minimum trend strength (0.0-1.0)

input group "=== Advanced Indicator Settings ==="
input int     RSI_Period = 14;             // RSI period
input int     RSI_Overbought = 70;         // RSI overbought level
input int     RSI_Oversold = 30;           // RSI oversold level
input int     MACD_Fast = 12;              // MACD fast EMA
input int     MACD_Slow = 26;              // MACD slow EMA
input int     MACD_Signal = 9;             // MACD signal line
input int     EMA_Fast = 8;                // Fast EMA period
input int     EMA_Slow = 21;               // Slow EMA period
input int     EMA_Trend = 50;              // Trend EMA period
input int     EMA_Long = 200;              // Long-term EMA period
input int     BB_Period = 20;              // Bollinger Bands period
input double  BB_Deviation = 2.0;          // Bollinger Bands deviation
input int     ATR_Period = 14;             // ATR period for volatility
input int     Stochastic_K = 14;           // Stochastic %K period
input int     Stochastic_D = 3;            // Stochastic %D period
input int     Stochastic_Slow = 3;         // Stochastic slowing
input int     WilliamsR_Period = 14;       // Williams %R period
input int     CCI_Period = 20;             // CCI period
input int     Ichimoku_Tenkan = 9;         // Ichimoku Tenkan-sen
input int     Ichimoku_Kijun = 26;         // Ichimoku Kijun-sen
input int     Ichimoku_Senkou = 52;        // Ichimoku Senkou Span B
input int     Ichimoku_Chikou = 26;        // Ichimoku Chikou Span
input int     ADX_Period = 14;             // ADX period for trend strength
input int     ADX_Threshold = 25;          // ADX threshold for trend confirmation
input int     ParabolicSAR_Step = 2;       // Parabolic SAR step
input double  ParabolicSAR_Max = 20;       // Parabolic SAR maximum

input group "=== Advanced Risk Management ==="
input bool    UseATR_SL = true;            // Use ATR for dynamic stop loss
input double  ATR_SL_Multiplier = 2.5;     // ATR multiplier for SL
input double  FixedSL = 30;                // Fixed SL in pips (if not using ATR)
input double  RiskRewardRatio = 2.5;       // Risk:Reward ratio
input bool    UseTrailingStop = true;      // Use trailing stop
input double  TrailingStart = 20;          // Trailing start in pips
input double  TrailingStep = 10;           // Trailing step in pips
input bool    UseBreakEven = true;         // Use break-even stop
input double  BreakEvenPips = 15;          // Pips to move SL to break-even
input bool    UsePartialClose = true;      // Use partial position closing
input double  PartialClosePercent = 50;    // Percentage to close at first target
input double  PartialCloseTarget = 1.8;    // First target multiplier
input bool    UseDynamicTP = true;         // Use dynamic take profit
input double  BaseTP = 2.5;                // Base take profit multiplier
input double  VolatilityTP = 1.8;          // Volatility-based TP multiplier

input group "=== Advanced Entry Filters ==="
input bool    UseVolumeFilter = true;      // Use volume filter
input double  MinVolume = 1.5;             // Minimum volume threshold
input bool    UseSpreadFilter = true;      // Use spread filter
input double  MaxSpread = 3;               // Maximum allowed spread
input bool    UseVolatilityFilter = true;  // Use volatility filter
input double  MinVolatility = 1.0;         // Minimum volatility threshold
input bool    UseTrendFilter = true;       // Use trend strength filter
input double  MinTrendStrength = 0.7;      // Minimum trend strength
input bool    UseMomentumFilter = true;    // Use momentum filter
input double  MinMomentum = 0.6;           // Minimum momentum strength

input group "=== Trading Time & Filters ==="
input bool    UseTimeFilter = true;        // Use time filter
input int     StartHour = 3;               // Start trading hour (GMT)
input int     EndHour = 21;                // End trading hour (GMT)
input bool    AvoidNews = true;            // Avoid trading during news
input bool    UseWeekendFilter = true;     // Avoid weekend trading

input group "=== Advanced Strategy Settings ==="
input bool    UseIchimokuStrategy = true;  // Use Ichimoku cloud strategy
input bool    UseBollingerStrategy = true; // Use Bollinger Bands strategy
input bool    UseRSIStrategy = true;       // Use RSI divergence strategy
input bool    UseMACDStrategy = true;      // Use MACD strategy
input bool    UseStochasticStrategy = true; // Use Stochastic strategy
input bool    UseWilliamsRStrategy = true; // Use Williams %R strategy
input bool    UseCCIStrategy = true;       // Use CCI strategy
input bool    UseADXStrategy = true;       // Use ADX trend strength strategy
input bool    UseParabolicSARStrategy = true; // Use Parabolic SAR strategy

//--- Global Variables
CTrade trade;
CPositionInfo position;
CAccountInfo account;
COrderInfo order;

double point_factor;
int total_orders = 0;
datetime last_trade_time = 0;
double daily_profit = 0;
double max_daily_loss = -150;
double total_profit = 0;
int consecutive_wins = 0;
int consecutive_losses = 0;

//--- Indicator handles
int rsi_handle, macd_handle, bb_handle, atr_handle;
int stoch_handle, williams_handle, cci_handle, adx_handle;
int ema_fast_handle, ema_slow_handle, ema_trend_handle, ema_long_handle;
int ichimoku_handle, parabolic_handle;

//--- Arrays for indicator values
double rsi[], macd_main[], macd_signal[], bb_upper[], bb_lower[], bb_middle[];
double atr[], stoch_main[], stoch_signal[], williams[], cci[];
double adx[], ema_fast[], ema_slow[], ema_trend[], ema_long[];
double ichimoku_tenkan[], ichimoku_kijun[], ichimoku_senkou_a[], ichimoku_senkou_b[];
double ichimoku_chikou[], parabolic[];

//--- Strategy signals
struct StrategySignal {
    bool buy_signal;
    bool sell_signal;
    double strength;
    string source;
};

StrategySignal current_signal;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    // Initialize trade object
    trade.SetExpertMagicNumber(MagicNumber);
    trade.SetDeviationInPoints(Slippage);
    trade.SetTypeFilling(ORDER_FILLING_FOK);
    
    // Set point factor
    point_factor = (SymbolInfoDouble(Symbol(), SYMBOL_POINT) == 0.00001) ? 10 : 1;
    
    // Initialize indicator handles
    InitializeIndicators();
    
    // Initialize arrays
    InitializeArrays();
    
    Print("Ultra Advanced Multi-Indicator EA initialized successfully!");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    // Release indicator handles
    if(rsi_handle != INVALID_HANDLE) IndicatorRelease(rsi_handle);
    if(macd_handle != INVALID_HANDLE) IndicatorRelease(macd_handle);
    if(bb_handle != INVALID_HANDLE) IndicatorRelease(bb_handle);
    if(atr_handle != INVALID_HANDLE) IndicatorRelease(atr_handle);
    if(stoch_handle != INVALID_HANDLE) IndicatorRelease(stoch_handle);
    if(williams_handle != INVALID_HANDLE) IndicatorRelease(williams_handle);
    if(cci_handle != INVALID_HANDLE) IndicatorRelease(cci_handle);
    if(adx_handle != INVALID_HANDLE) IndicatorRelease(adx_handle);
    if(ema_fast_handle != INVALID_HANDLE) IndicatorRelease(ema_fast_handle);
    if(ema_slow_handle != INVALID_HANDLE) IndicatorRelease(ema_slow_handle);
    if(ema_trend_handle != INVALID_HANDLE) IndicatorRelease(ema_trend_handle);
    if(ema_long_handle != INVALID_HANDLE) IndicatorRelease(ema_long_handle);
    if(ichimoku_handle != INVALID_HANDLE) IndicatorRelease(ichimoku_handle);
    if(parabolic_handle != INVALID_HANDLE) IndicatorRelease(parabolic_handle);
    
    Print("Ultra Advanced Multi-Indicator EA deinitialized!");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    if(!EnableTrading) return;
    
    // Check trading conditions
    if(!CheckTradingConditions()) return;
    
    // Update indicators
    if(!UpdateIndicators()) return;
    
    // Analyze market and generate signals
    AnalyzeMarket();
    
    // Execute trading logic
    ExecuteTradingLogic();
    
    // Manage open positions
    ManagePositions();
}

//+------------------------------------------------------------------+
//| Initialize indicators                                            |
//+------------------------------------------------------------------+
void InitializeIndicators() {
    // RSI
    rsi_handle = iRSI(Symbol(), TrendTimeframe, RSI_Period, PRICE_CLOSE);
    
    // MACD
    macd_handle = iMACD(Symbol(), TrendTimeframe, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE);
    
    // Bollinger Bands
    bb_handle = iBands(Symbol(), TrendTimeframe, BB_Period, 0, BB_Deviation, PRICE_CLOSE);
    
    // ATR
    atr_handle = iATR(Symbol(), TrendTimeframe, ATR_Period);
    
    // Stochastic
    stoch_handle = iStochastic(Symbol(), TrendTimeframe, Stochastic_K, Stochastic_D, Stochastic_Slow, MODE_SMA, STO_LOWHIGH);
    
    // Williams %R
    williams_handle = iWPR(Symbol(), TrendTimeframe, WilliamsR_Period);
    
    // CCI
    cci_handle = iCCI(Symbol(), TrendTimeframe, CCI_Period, PRICE_TYPICAL);
    
    // ADX
    adx_handle = iADX(Symbol(), TrendTimeframe, ADX_Period);
    
    // EMAs
    ema_fast_handle = iMA(Symbol(), TrendTimeframe, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
    ema_slow_handle = iMA(Symbol(), TrendTimeframe, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
    ema_trend_handle = iMA(Symbol(), TrendTimeframe, EMA_Trend, 0, MODE_EMA, PRICE_CLOSE);
    ema_long_handle = iMA(Symbol(), TrendTimeframe, EMA_Long, 0, MODE_EMA, PRICE_CLOSE);
    
    // Ichimoku
    ichimoku_handle = iIchimoku(Symbol(), TrendTimeframe, Ichimoku_Tenkan, Ichimoku_Kijun, Ichimoku_Senkou);
    
    // Parabolic SAR
    parabolic_handle = iSAR(Symbol(), TrendTimeframe, ParabolicSAR_Step, ParabolicSAR_Max, 0.02);
}

//+------------------------------------------------------------------+
//| Initialize arrays                                                |
//+------------------------------------------------------------------+
void InitializeArrays() {
    ArraySetAsSeries(rsi, true);
    ArraySetAsSeries(macd_main, true);
    ArraySetAsSeries(macd_signal, true);
    ArraySetAsSeries(bb_upper, true);
    ArraySetAsSeries(bb_lower, true);
    ArraySetAsSeries(bb_middle, true);
    ArraySetAsSeries(atr, true);
    ArraySetAsSeries(stoch_main, true);
    ArraySetAsSeries(stoch_signal, true);
    ArraySetAsSeries(williams, true);
    ArraySetAsSeries(cci, true);
    ArraySetAsSeries(adx, true);
    ArraySetAsSeries(ema_fast, true);
    ArraySetAsSeries(ema_slow, true);
    ArraySetAsSeries(ema_trend, true);
    ArraySetAsSeries(ema_long, true);
    ArraySetAsSeries(ichimoku_tenkan, true);
    ArraySetAsSeries(ichimoku_kijun, true);
    ArraySetAsSeries(ichimoku_senkou_a, true);
    ArraySetAsSeries(ichimoku_senkou_b, true);
    ArraySetAsSeries(ichimoku_chikou, true);
    ArraySetAsSeries(parabolic, true);
}

//+------------------------------------------------------------------+
//| Update indicators                                                |
//+------------------------------------------------------------------+
bool UpdateIndicators() {
    // Copy indicator data
    if(CopyBuffer(rsi_handle, 0, 0, 3, rsi) < 3) return false;
    if(CopyBuffer(macd_handle, 0, 0, 3, macd_main) < 3) return false;
    if(CopyBuffer(macd_handle, 1, 0, 3, macd_signal) < 3) return false;
    if(CopyBuffer(bb_handle, 0, 0, 3, bb_upper) < 3) return false;
    if(CopyBuffer(bb_handle, 1, 0, 3, bb_lower) < 3) return false;
    if(CopyBuffer(bb_handle, 2, 0, 3, bb_middle) < 3) return false;
    if(CopyBuffer(atr_handle, 0, 0, 3, atr) < 3) return false;
    if(CopyBuffer(stoch_handle, 0, 0, 3, stoch_main) < 3) return false;
    if(CopyBuffer(stoch_handle, 1, 0, 3, stoch_signal) < 3) return false;
    if(CopyBuffer(williams_handle, 0, 0, 3, williams) < 3) return false;
    if(CopyBuffer(cci_handle, 0, 0, 3, cci) < 3) return false;
    if(CopyBuffer(adx_handle, 0, 0, 3, adx) < 3) return false;
    if(CopyBuffer(ema_fast_handle, 0, 0, 3, ema_fast) < 3) return false;
    if(CopyBuffer(ema_slow_handle, 0, 0, 3, ema_slow) < 3) return false;
    if(CopyBuffer(ema_trend_handle, 0, 0, 3, ema_trend) < 3) return false;
    if(CopyBuffer(ema_long_handle, 0, 0, 3, ema_long) < 3) return false;
    if(CopyBuffer(ichimoku_handle, 0, 0, 3, ichimoku_tenkan) < 3) return false;
    if(CopyBuffer(ichimoku_handle, 1, 0, 3, ichimoku_kijun) < 3) return false;
    if(CopyBuffer(ichimoku_handle, 2, 0, 3, ichimoku_senkou_a) < 3) return false;
    if(CopyBuffer(ichimoku_handle, 3, 0, 3, ichimoku_senkou_b) < 3) return false;
    if(CopyBuffer(ichimoku_handle, 4, 0, 3, ichimoku_chikou) < 3) return false;
    if(CopyBuffer(parabolic_handle, 0, 0, 3, parabolic) < 3) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Check trading conditions                                         |
//+------------------------------------------------------------------+
bool CheckTradingConditions() {
    // Check if trading is enabled
    if(!EnableTrading) return false;
    
    // Check time filter
    if(UseTimeFilter) {
        int current_hour = TimeHour(TimeCurrent());
        if(current_hour < StartHour || current_hour >= EndHour) return false;
    }
    
    // Check weekend filter
    if(UseWeekendFilter) {
        int day_of_week = TimeDayOfWeek(TimeCurrent());
        if(day_of_week == 0 || day_of_week == 6) return false; // Sunday or Saturday
    }
    
    // Check spread filter
    if(UseSpreadFilter) {
        double current_spread = SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) * point_factor;
        if(current_spread > MaxSpread) return false;
    }
    
    // Check maximum open trades
    if(CountOpenTrades() >= MaxOpenTrades) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Analyze market and generate signals                              |
//+------------------------------------------------------------------+
void AnalyzeMarket() {
    // Reset signal
    current_signal.buy_signal = false;
    current_signal.sell_signal = false;
    current_signal.strength = 0;
    current_signal.source = "";
    
    double total_strength = 0;
    int signal_count = 0;
    
    // Ichimoku Strategy
    if(UseIchimokuStrategy) {
        StrategySignal ichimoku_signal = AnalyzeIchimoku();
        if(ichimoku_signal.buy_signal || ichimoku_signal.sell_signal) {
            total_strength += ichimoku_signal.strength;
            signal_count++;
            if(ichimoku_signal.strength > current_signal.strength) {
                current_signal = ichimoku_signal;
                current_signal.source = "Ichimoku";
            }
        }
    }
    
    // Bollinger Bands Strategy
    if(UseBollingerStrategy) {
        StrategySignal bb_signal = AnalyzeBollingerBands();
        if(bb_signal.buy_signal || bb_signal.sell_signal) {
            total_strength += bb_signal.strength;
            signal_count++;
            if(bb_signal.strength > current_signal.strength) {
                current_signal = bb_signal;
                current_signal.source = "Bollinger Bands";
            }
        }
    }
    
    // RSI Strategy
    if(UseRSIStrategy) {
        StrategySignal rsi_signal = AnalyzeRSI();
        if(rsi_signal.buy_signal || rsi_signal.sell_signal) {
            total_strength += rsi_signal.strength;
            signal_count++;
            if(rsi_signal.strength > current_signal.strength) {
                current_signal = rsi_signal;
                current_signal.source = "RSI";
            }
        }
    }
    
    // MACD Strategy
    if(UseMACDStrategy) {
        StrategySignal macd_signal = AnalyzeMACD();
        if(macd_signal.buy_signal || macd_signal.sell_signal) {
            total_strength += macd_signal.strength;
            signal_count++;
            if(macd_signal.strength > current_signal.strength) {
                current_signal = macd_signal;
                current_signal.source = "MACD";
            }
        }
    }
    
    // Stochastic Strategy
    if(UseStochasticStrategy) {
        StrategySignal stoch_signal = AnalyzeStochastic();
        if(stoch_signal.buy_signal || stoch_signal.sell_signal) {
            total_strength += stoch_signal.strength;
            signal_count++;
            if(stoch_signal.strength > current_signal.strength) {
                current_signal = stoch_signal;
                current_signal.source = "Stochastic";
            }
        }
    }
    
    // Williams %R Strategy
    if(UseWilliamsRStrategy) {
        StrategySignal williams_signal = AnalyzeWilliamsR();
        if(williams_signal.buy_signal || williams_signal.sell_signal) {
            total_strength += williams_signal.strength;
            signal_count++;
            if(williams_signal.strength > current_signal.strength) {
                current_signal = williams_signal;
                current_signal.source = "Williams %R";
            }
        }
    }
    
    // CCI Strategy
    if(UseCCIStrategy) {
        StrategySignal cci_signal = AnalyzeCCI();
        if(cci_signal.buy_signal || cci_signal.sell_signal) {
            total_strength += cci_signal.strength;
            signal_count++;
            if(cci_signal.strength > current_signal.strength) {
                current_signal = cci_signal;
                current_signal.source = "CCI";
            }
        }
    }
    
    // ADX Strategy
    if(UseADXStrategy) {
        StrategySignal adx_signal = AnalyzeADX();
        if(adx_signal.buy_signal || adx_signal.sell_signal) {
            total_strength += adx_signal.strength;
            signal_count++;
            if(adx_signal.strength > current_signal.strength) {
                current_signal = adx_signal;
                current_signal.source = "ADX";
            }
        }
    }
    
    // Parabolic SAR Strategy
    if(UseParabolicSARStrategy) {
        StrategySignal parabolic_signal = AnalyzeParabolicSAR();
        if(parabolic_signal.buy_signal || parabolic_signal.sell_signal) {
            total_strength += parabolic_signal.strength;
            signal_count++;
            if(parabolic_signal.strength > current_signal.strength) {
                current_signal = parabolic_signal;
                current_signal.source = "Parabolic SAR";
            }
        }
    }
    
    // Calculate average strength
    if(signal_count > 0) {
        current_signal.strength = total_strength / signal_count;
    }
    
    // Apply minimum strength filter
    if(current_signal.strength < MinTrendStrength) {
        current_signal.buy_signal = false;
        current_signal.sell_signal = false;
    }
}

//+------------------------------------------------------------------+
//| Analyze Ichimoku                                                 |
//+------------------------------------------------------------------+
StrategySignal AnalyzeIchimoku() {
    StrategySignal signal = {false, false, 0, ""};
    
    double current_price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    
    // Check if price is above/below cloud
    bool above_cloud = current_price > MathMax(ichimoku_senkou_a[0], ichimoku_senkou_b[0]);
    bool below_cloud = current_price < MathMin(ichimoku_senkou_a[0], ichimoku_senkou_b[0]);
    
    // Check Tenkan-sen vs Kijun-sen
    bool tenkan_above_kijun = ichimoku_tenkan[0] > ichimoku_kijun[0];
    bool tenkan_below_kijun = ichimoku_tenkan[0] < ichimoku_kijun[0];
    
    // Check Chikou Span
    bool chikou_above_price = ichimoku_chikou[0] > current_price;
    bool chikou_below_price = ichimoku_chikou[0] < current_price;
    
    // Generate signals
    if(above_cloud && tenkan_above_kijun && chikou_above_price) {
        signal.buy_signal = true;
        signal.strength = 0.9;
    }
    else if(below_cloud && tenkan_below_kijun && chikou_below_price) {
        signal.sell_signal = true;
        signal.strength = 0.9;
    }
    
    return signal;
}

//+------------------------------------------------------------------+
//| Analyze Bollinger Bands                                         |
//+------------------------------------------------------------------+
StrategySignal AnalyzeBollingerBands() {
    StrategySignal signal = {false, false, 0, ""};
    
    double current_price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    
    // Check for oversold/overbought conditions
    if(current_price <= bb_lower[0]) {
        signal.buy_signal = true;
        signal.strength = 0.8;
    }
    else if(current_price >= bb_upper[0]) {
        signal.sell_signal = true;
        signal.strength = 0.8;
    }
    
    // Check for squeeze (bands narrowing)
    double band_width = bb_upper[0] - bb_lower[0];
    double avg_band_width = (bb_upper[1] + bb_upper[2] + bb_lower[1] + bb_lower[2]) / 4;
    
    if(band_width < avg_band_width * 0.8) {
        // Potential breakout coming
        if(current_price > bb_middle[0]) {
            signal.buy_signal = true;
            signal.strength = 0.7;
        } else {
            signal.sell_signal = true;
            signal.strength = 0.7;
        }
    }
    
    return signal;
}

//+------------------------------------------------------------------+
//| Analyze RSI                                                      |
//+------------------------------------------------------------------+
StrategySignal AnalyzeRSI() {
    StrategySignal signal = {false, false, 0, ""};
    
    // Check for oversold/overbought conditions
    if(rsi[0] <= RSI_Oversold) {
        signal.buy_signal = true;
        signal.strength = 0.8;
    }
    else if(rsi[0] >= RSI_Overbought) {
        signal.sell_signal = true;
        signal.strength = 0.8;
    }
    
    // Check for divergence
    if(rsi[0] > rsi[1] && rsi[1] > rsi[2]) {
        // RSI rising
        if(rsi[0] < 50) { // Still in oversold territory
            signal.buy_signal = true;
            signal.strength = 0.7;
        }
    }
    else if(rsi[0] < rsi[1] && rsi[1] < rsi[2]) {
        // RSI falling
        if(rsi[0] > 50) { // Still in overbought territory
            signal.sell_signal = true;
            signal.strength = 0.7;
        }
    }
    
    return signal;
}

//+------------------------------------------------------------------+
//| Analyze MACD                                                     |
//+------------------------------------------------------------------+
StrategySignal AnalyzeMACD() {
    StrategySignal signal = {false, false, 0, ""};
    
    // Check for MACD crossover
    if(macd_main[0] > macd_signal[0] && macd_main[1] <= macd_signal[1]) {
        signal.buy_signal = true;
        signal.strength = 0.8;
    }
    else if(macd_main[0] < macd_signal[0] && macd_main[1] >= macd_signal[1]) {
        signal.sell_signal = true;
        signal.strength = 0.8;
    }
    
    // Check for MACD above/below zero
    if(macd_main[0] > 0 && macd_main[0] > macd_main[1]) {
        signal.buy_signal = true;
        signal.strength = 0.6;
    }
    else if(macd_main[0] < 0 && macd_main[0] < macd_main[1]) {
        signal.sell_signal = true;
        signal.strength = 0.6;
    }
    
    return signal;
}

//+------------------------------------------------------------------+
//| Analyze Stochastic                                               |
//+------------------------------------------------------------------+
StrategySignal AnalyzeStochastic() {
    StrategySignal signal = {false, false, 0, ""};
    
    // Check for oversold/overbought conditions
    if(stoch_main[0] <= 20 && stoch_main[0] > stoch_main[1]) {
        signal.buy_signal = true;
        signal.strength = 0.7;
    }
    else if(stoch_main[0] >= 80 && stoch_main[0] < stoch_main[1]) {
        signal.sell_signal = true;
        signal.strength = 0.7;
    }
    
    // Check for crossover
    if(stoch_main[0] > stoch_signal[0] && stoch_main[1] <= stoch_signal[1]) {
        signal.buy_signal = true;
        signal.strength = 0.6;
    }
    else if(stoch_main[0] < stoch_signal[0] && stoch_main[1] >= stoch_signal[1]) {
        signal.sell_signal = true;
        signal.strength = 0.6;
    }
    
    return signal;
}

//+------------------------------------------------------------------+
//| Analyze Williams %R                                              |
//+------------------------------------------------------------------+
StrategySignal AnalyzeWilliamsR() {
    StrategySignal signal = {false, false, 0, ""};
    
    // Check for oversold/overbought conditions
    if(williams[0] <= -80) {
        signal.buy_signal = true;
        signal.strength = 0.7;
    }
    else if(williams[0] >= -20) {
        signal.sell_signal = true;
        signal.strength = 0.7;
    }
    
    return signal;
}

//+------------------------------------------------------------------+
//| Analyze CCI                                                      |
//+------------------------------------------------------------------+
StrategySignal AnalyzeCCI() {
    StrategySignal signal = {false, false, 0, ""};
    
    // Check for oversold/overbought conditions
    if(cci[0] <= -100) {
        signal.buy_signal = true;
        signal.strength = 0.7;
    }
    else if(cci[0] >= 100) {
        signal.sell_signal = true;
        signal.strength = 0.7;
    }
    
    // Check for zero line crossover
    if(cci[0] > 0 && cci[1] <= 0) {
        signal.buy_signal = true;
        signal.strength = 0.6;
    }
    else if(cci[0] < 0 && cci[1] >= 0) {
        signal.sell_signal = true;
        signal.strength = 0.6;
    }
    
    return signal;
}

//+------------------------------------------------------------------+
//| Analyze ADX                                                      |
//+------------------------------------------------------------------+
StrategySignal AnalyzeADX() {
    StrategySignal signal = {false, false, 0, ""};
    
    // Check for strong trend
    if(adx[0] > ADX_Threshold) {
        // Strong trend exists
        if(adx[0] > adx[1]) {
            // Trend strengthening
            signal.buy_signal = true;
            signal.sell_signal = true;
            signal.strength = 0.8;
        }
    }
    
    return signal;
}

//+------------------------------------------------------------------+
//| Analyze Parabolic SAR                                            |
//+------------------------------------------------------------------+
StrategySignal AnalyzeParabolicSAR() {
    StrategySignal signal = {false, false, 0, ""};
    
    double current_price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    
    // Check SAR position relative to price
    if(parabolic[0] < current_price) {
        signal.buy_signal = true;
        signal.strength = 0.6;
    }
    else if(parabolic[0] > current_price) {
        signal.sell_signal = true;
        signal.strength = 0.6;
    }
    
    return signal;
}

//+------------------------------------------------------------------+
//| Execute trading logic                                            |
//+------------------------------------------------------------------+
void ExecuteTradingLogic() {
    if(!current_signal.buy_signal && !current_signal.sell_signal) return;
    
    // Check if we already have a position in this direction
    if(HasPositionInDirection(current_signal.buy_signal ? ORDER_TYPE_BUY : ORDER_TYPE_SELL)) return;
    
    // Calculate position size
    double lot_size = CalculateLotSize();
    
    // Calculate stop loss and take profit
    double stop_loss = 0, take_profit = 0;
    CalculateStopLossAndTakeProfit(current_signal.buy_signal ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, stop_loss, take_profit);
    
    // Execute trade
    if(current_signal.buy_signal) {
        trade.Buy(lot_size, Symbol(), 0, stop_loss, take_profit, "Ultra Advanced EA Buy");
    } else if(current_signal.sell_signal) {
        trade.Sell(lot_size, Symbol(), 0, stop_loss, take_profit, "Ultra Advanced EA Sell");
    }
    
    if(trade.ResultRetcode() == TRADE_RETCODE_DONE) {
        Print("Trade executed successfully: ", current_signal.source, " - Strength: ", current_signal.strength);
        last_trade_time = TimeCurrent();
    }
}

//+------------------------------------------------------------------+
//| Calculate lot size                                               |
//+------------------------------------------------------------------+
double CalculateLotSize() {
    if(!AutoLotSize) return LotSize;
    
    double account_balance = account.Balance();
    double risk_amount = account_balance * RiskPercent / 100;
    
    double stop_loss_pips = UseATR_SL ? atr[0] * ATR_SL_Multiplier / point_factor : FixedSL;
    double tick_value = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
    double lot_step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
    
    double lot_size = risk_amount / (stop_loss_pips * tick_value);
    lot_size = MathFloor(lot_size / lot_step) * lot_step;
    
    double min_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
    
    lot_size = MathMax(min_lot, MathMin(max_lot, lot_size));
    
    return lot_size;
}

//+------------------------------------------------------------------+
//| Calculate stop loss and take profit                              |
//+------------------------------------------------------------------+
void CalculateStopLossAndTakeProfit(ENUM_ORDER_TYPE order_type, double &stop_loss, double &take_profit) {
    double current_price = (order_type == ORDER_TYPE_BUY) ? SymbolInfoDouble(Symbol(), SYMBOL_ASK) : SymbolInfoDouble(Symbol(), SYMBOL_BID);
    
    if(UseATR_SL) {
        double atr_value = atr[0];
        if(order_type == ORDER_TYPE_BUY) {
            stop_loss = current_price - (atr_value * ATR_SL_Multiplier);
            take_profit = current_price + (atr_value * ATR_SL_Multiplier * RiskRewardRatio);
        } else {
            stop_loss = current_price + (atr_value * ATR_SL_Multiplier);
            take_profit = current_price - (atr_value * ATR_SL_Multiplier * RiskRewardRatio);
        }
    } else {
        double sl_pips = FixedSL * point_factor * SymbolInfoDouble(Symbol(), SYMBOL_POINT);
        if(order_type == ORDER_TYPE_BUY) {
            stop_loss = current_price - sl_pips;
            take_profit = current_price + (sl_pips * RiskRewardRatio);
        } else {
            stop_loss = current_price + sl_pips;
            take_profit = current_price - (sl_pips * RiskRewardRatio);
        }
    }
    
    // Normalize prices
    stop_loss = NormalizeDouble(stop_loss, _Digits);
    take_profit = NormalizeDouble(take_profit, _Digits);
}

//+------------------------------------------------------------------+
//| Check if position exists in direction                            |
//+------------------------------------------------------------------+
bool HasPositionInDirection(ENUM_ORDER_TYPE order_type) {
    for(int i = 0; i < PositionsTotal(); i++) {
        if(position.SelectByIndex(i)) {
            if(position.Symbol() == Symbol() && position.Magic() == MagicNumber) {
                if((order_type == ORDER_TYPE_BUY && position.PositionType() == POSITION_TYPE_BUY) ||
                   (order_type == ORDER_TYPE_SELL && position.PositionType() == POSITION_TYPE_SELL)) {
                    return true;
                }
            }
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Count open trades                                                |
//+------------------------------------------------------------------+
int CountOpenTrades() {
    int count = 0;
    for(int i = 0; i < PositionsTotal(); i++) {
        if(position.SelectByIndex(i)) {
            if(position.Symbol() == Symbol() && position.Magic() == MagicNumber) {
                count++;
            }
        }
    }
    return count;
}

//+------------------------------------------------------------------+
//| Manage open positions                                            |
//+------------------------------------------------------------------+
void ManagePositions() {
    for(int i = 0; i < PositionsTotal(); i++) {
        if(position.SelectByIndex(i)) {
            if(position.Symbol() == Symbol() && position.Magic() == MagicNumber) {
                ManagePosition(position);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Manage individual position                                       |
//+------------------------------------------------------------------+
void ManagePosition(CPositionInfo &pos) {
    double current_price = (pos.PositionType() == POSITION_TYPE_BUY) ? SymbolInfoDouble(Symbol(), SYMBOL_BID) : SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double open_price = pos.PriceOpen();
    double stop_loss = pos.StopLoss();
    double take_profit = pos.TakeProfit();
    
    // Calculate profit in pips
    double profit_pips = (pos.PositionType() == POSITION_TYPE_BUY) ? 
                        (current_price - open_price) / (point_factor * SymbolInfoDouble(Symbol(), SYMBOL_POINT)) :
                        (open_price - current_price) / (point_factor * SymbolInfoDouble(Symbol(), SYMBOL_POINT));
    
    // Break-even stop loss
    if(UseBreakEven && stop_loss != 0) {
        if(pos.PositionType() == POSITION_TYPE_BUY && profit_pips >= BreakEvenPips) {
            if(stop_loss < open_price) {
                trade.PositionModify(pos.Ticket(), open_price, take_profit);
            }
        }
        else if(pos.PositionType() == POSITION_TYPE_SELL && profit_pips >= BreakEvenPips) {
            if(stop_loss > open_price) {
                trade.PositionModify(pos.Ticket(), open_price, take_profit);
            }
        }
    }
    
    // Trailing stop
    if(UseTrailingStop && profit_pips >= TrailingStart) {
        double new_stop_loss = 0;
        
        if(pos.PositionType() == POSITION_TYPE_BUY) {
            new_stop_loss = current_price - (TrailingStep * point_factor * SymbolInfoDouble(Symbol(), SYMBOL_POINT));
            if(new_stop_loss > stop_loss) {
                trade.PositionModify(pos.Ticket(), new_stop_loss, take_profit);
            }
        }
        else {
            new_stop_loss = current_price + (TrailingStep * point_factor * SymbolInfoDouble(Symbol(), SYMBOL_POINT));
            if(new_stop_loss < stop_loss || stop_loss == 0) {
                trade.PositionModify(pos.Ticket(), new_stop_loss, take_profit);
            }
        }
    }
    
    // Partial close
    if(UsePartialClose && profit_pips >= (PartialCloseTarget * (stop_loss != 0 ? MathAbs(stop_loss - open_price) / (point_factor * SymbolInfoDouble(Symbol(), SYMBOL_POINT)) : FixedSL))) {
        double current_volume = pos.Volume();
        double partial_volume = current_volume * PartialClosePercent / 100;
        
        if(partial_volume >= SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) {
            trade.PositionClosePartial(pos.Ticket(), partial_volume);
        }
    }
}

//+------------------------------------------------------------------+
//| Expert start function                                            |
//+------------------------------------------------------------------+
void OnExpertStart() {
    Print("Ultra Advanced Multi-Indicator EA started!");
}

//+------------------------------------------------------------------+
//| Expert stop function                                             |
//+------------------------------------------------------------------+
void OnExpertStop() {
    Print("Ultra Advanced Multi-Indicator EA stopped!");
}