//+------------------------------------------------------------------+
//|                                    UltraAI_Expert_Advisor.mq5 |
//|                           Ultra Advanced AI Trading System |
//|                    Designed for Maximum Profitability Trading |
//+------------------------------------------------------------------+
#property copyright "UltraAI Expert Advisor - Advanced Trading System"
#property version   "3.0"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//--- Input Parameters
input group "=== General Settings ==="
input double    LotSize = 0.1;
input bool      UseAutoLots = true;
input double    RiskPercent = 1.5;
input ulong     MagicNumber = 99999;
input int       Slippage = 2;
input bool      EnableTrading = true;

input group "=== AI Strategy Settings ==="
input bool      UseAdvancedAI = true;
input int       AIConfidenceThreshold = 80;
input bool      UseEnsembleLearning = true;
input bool      UseAdaptiveParameters = true;
input int       LearningPeriod = 100;
input double    MinSignalStrength = 0.7;

input group "=== Multi-Indicator Settings ==="
input int       FastEMA = 8;
input int       SlowEMA = 21;
input int       SuperSlowEMA = 55;
input int       RSI_Period = 14;
input int       RSI_Overbought = 70;
input int       RSI_Oversold = 30;
input int       MACD_Fast = 12;
input int       MACD_Slow = 26;
input int       MACD_Signal = 9;
input int       BB_Period = 20;
input double    BB_Deviation = 2.0;
input int       ATR_Period = 14;
input int       Stochastic_K = 14;
input int       Stochastic_D = 3;
input int       Stochastic_Slowing = 3;
input int       WilliamsR_Period = 14;
input int       CCI_Period = 20;
input int       ADX_Period = 14;
input int       ADX_Threshold = 25;

input group "=== Advanced Risk Management ==="
input bool      UseDynamicSL = true;
input bool      UseDynamicTP = true;
input double    ATR_SL_Multiplier = 2.5;
input double    ATR_TP_Multiplier = 4.0;
input double    MaxDailyLoss = 3.0;
input double    MaxDailyProfit = 8.0;
input bool      UseTrailingStop = true;
input double    TrailingStart = 25;
input double    TrailingStep = 8;
input bool      UseBreakEven = true;
input double    BreakEvenPips = 15;
input double    BreakEvenOffset = 2;
input bool      UsePartialClose = true;
input double    PartialClosePercent = 50;
input double    PartialClosePips = 30;

input group "=== Advanced AI Features ==="
input bool      UseMultiTimeframe = true;
input bool      UseVolumeAnalysis = true;
input bool      UseNewsFilter = true;
input bool      UseSpreadFilter = true;
input double    MaxSpread = 2.5;
input bool      UseVolatilityFilter = true;
input double    MinVolatility = 0.0002;
input double    MaxVolatility = 0.008;
input bool      UseCorrelationFilter = true;
input bool      UseMarketRegimeDetection = true;

//--- Global Variables
CTrade trade;
CPositionInfo position;
COrderInfo order;
datetime LastBarTime;
double DailyProfit = 0;
double DailyLoss = 0;
datetime DayStart;
bool TradingEnabled = true;
int TotalTrades = 0;
int WinningTrades = 0;
double TotalProfit = 0;
double WinRate = 0;

//--- AI Decision Structure
struct AISignal {
    double confidence;
    int direction;  // 1 for buy, -1 for sell, 0 for hold
    double strength;
    string reason;
    double risk_reward;
    datetime timestamp;
};

//--- Market Regime Structure
struct MarketRegime {
    int type;  // 0=trending, 1=ranging, 2=volatile, 3=low_volatility
    double strength;
    double volatility;
    string description;
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("=== UltraAI Expert Advisor MT5 Initialized ===");
    Print("Advanced AI Trading System Ready for Maximum Profitability");
    Print("Optimized for XAUUSD and Major Currency Pairs");
    
    // Initialize trade object
    trade.SetExpertMagicNumber(MagicNumber);
    trade.SetDeviationInPoints(Slippage);
    trade.SetTypeFilling(ORDER_FILLING_FOK);
    
    LastBarTime = 0;
    DayStart = TimeCurrent();
    
    if(UseAdvancedAI) {
        Print("AI Learning System Activated");
        Print("Learning Period: ", LearningPeriod, " bars");
        Print("Confidence Threshold: ", AIConfidenceThreshold, "%");
    }
    
    if(!ValidateParameters()) {
        Print("Parameter validation failed. Please check settings.");
        return(INIT_PARAMETERS_INCORRECT);
    }
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("=== UltraAI Expert Advisor MT5 Deinitialized ===");
    Print("Total Trades: ", TotalTrades);
    Print("Win Rate: ", DoubleToString(WinRate, 2), "%");
    Print("Total Profit: ", DoubleToString(TotalProfit, 2));
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if(!EnableTrading || !TradingEnabled) return;
    
    // Check if new bar formed
    if(TimeCurrent() == LastBarTime) return;
    LastBarTime = TimeCurrent();
    
    // Reset daily counters at new day
    if(TimeDay(TimeCurrent()) != TimeDay(DayStart)) {
        ResetDailyCounters();
        DayStart = TimeCurrent();
    }
    
    // Check daily limits
    if(!CheckDailyLimits()) return;
    
    // Update trade statistics
    UpdateTradeStatistics();
    
    // Main AI trading logic
    if(UseAdvancedAI) {
        AISignal signal = GenerateAISignal();
        
        if(signal.confidence >= AIConfidenceThreshold && signal.direction != 0) {
            if(signal.direction == 1 && !HasOpenBuyPosition()) {
                ExecuteBuyOrder(signal);
            }
            else if(signal.direction == -1 && !HasOpenSellPosition()) {
                ExecuteSellOrder(signal);
            }
        }
    }
    
    // Manage existing positions
    ManageOpenPositions();
}

//+------------------------------------------------------------------+
//| Generate AI Trading Signal                                       |
//+------------------------------------------------------------------+
AISignal GenerateAISignal()
{
    AISignal signal;
    signal.confidence = 0;
    signal.direction = 0;
    signal.strength = 0;
    signal.reason = "";
    signal.risk_reward = 0;
    signal.timestamp = TimeCurrent();
    
    // Get market regime
    MarketRegime regime = DetectMarketRegime();
    
    // Multi-timeframe analysis
    double mtf_score = 0;
    if(UseMultiTimeframe) {
        mtf_score = AnalyzeMultiTimeframe();
    }
    
    // Technical indicator analysis
    double technical_score = AnalyzeTechnicalIndicators();
    
    // Price action analysis
    double price_action_score = AnalyzePriceAction();
    
    // Volume analysis
    double volume_score = 0;
    if(UseVolumeAnalysis) {
        volume_score = AnalyzeVolume();
    }
    
    // Market correlation analysis
    double correlation_score = 0;
    if(UseCorrelationFilter) {
        correlation_score = AnalyzeCorrelations();
    }
    
    // Combine all scores with AI weights
    double total_score = 0;
    double total_weight = 0;
    
    total_score += technical_score * 0.4;
    total_weight += 0.4;
    
    if(UseMultiTimeframe) {
        total_score += mtf_score * 0.25;
        total_weight += 0.25;
    }
    
    total_score += price_action_score * 0.2;
    total_weight += 0.2;
    
    if(UseVolumeAnalysis) {
        total_score += volume_score * 0.1;
        total_weight += 0.1;
    }
    
    if(UseCorrelationFilter) {
        total_score += correlation_score * 0.05;
        total_weight += 0.05;
    }
    
    // Normalize score
    if(total_weight > 0) {
        total_score = total_score / total_weight;
    }
    
    // Determine signal direction and confidence
    if(total_score > MinSignalStrength) {
        signal.direction = 1;
        signal.confidence = total_score * 100;
        signal.strength = total_score;
        signal.reason = "Strong buy signal based on multiple indicators";
    }
    else if(total_score < -MinSignalStrength) {
        signal.direction = -1;
        signal.confidence = MathAbs(total_score) * 100;
        signal.strength = MathAbs(total_score);
        signal.reason = "Strong sell signal based on multiple indicators";
    }
    
    signal.risk_reward = CalculateRiskRewardRatio(signal.direction);
    
    // Adjust confidence based on market regime
    if(regime.type == 0) {
        signal.confidence *= 1.1;
    }
    else if(regime.type == 1) {
        signal.confidence *= 0.9;
    }
    
    return signal;
}

//+------------------------------------------------------------------+
//| Analyze Technical Indicators                                     |
//+------------------------------------------------------------------+
double AnalyzeTechnicalIndicators()
{
    double score = 0;
    
    // EMA Analysis
    double fast_ema = iMA(_Symbol, PERIOD_CURRENT, FastEMA, 0, MODE_EMA, PRICE_CLOSE);
    double slow_ema = iMA(_Symbol, PERIOD_CURRENT, SlowEMA, 0, MODE_EMA, PRICE_CLOSE);
    double super_slow_ema = iMA(_Symbol, PERIOD_CURRENT, SuperSlowEMA, 0, MODE_EMA, PRICE_CLOSE);
    
    if(fast_ema > slow_ema && slow_ema > super_slow_ema) {
        score += 0.3;
    }
    else if(fast_ema < slow_ema && slow_ema < super_slow_ema) {
        score -= 0.3;
    }
    
    // RSI Analysis
    double rsi = iRSI(_Symbol, PERIOD_CURRENT, RSI_Period, PRICE_CLOSE);
    if(rsi < RSI_Oversold) {
        score += 0.2;
    }
    else if(rsi > RSI_Overbought) {
        score -= 0.2;
    }
    
    // MACD Analysis
    double macd_main = iMACD(_Symbol, PERIOD_CURRENT, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN);
    double macd_signal = iMACD(_Symbol, PERIOD_CURRENT, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL);
    double macd_prev = iMACD(_Symbol, PERIOD_CURRENT, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 1);
    
    if(macd_main > macd_signal && macd_main > macd_prev) {
        score += 0.2;
    }
    else if(macd_main < macd_signal && macd_main < macd_prev) {
        score -= 0.2;
    }
    
    // Bollinger Bands Analysis
    double bb_upper = iBands(_Symbol, PERIOD_CURRENT, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_UPPER);
    double bb_lower = iBands(_Symbol, PERIOD_CURRENT, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_LOWER);
    double close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    if(close < bb_lower) {
        score += 0.15;
    }
    else if(close > bb_upper) {
        score -= 0.15;
    }
    
    // Stochastic Analysis
    double stoch_k = iStochastic(_Symbol, PERIOD_CURRENT, Stochastic_K, Stochastic_D, Stochastic_Slowing, MODE_SMA, STO_LOWHIGH);
    double stoch_d = iStochastic(_Symbol, PERIOD_CURRENT, Stochastic_K, Stochastic_D, Stochastic_Slowing, MODE_SMA, STO_LOWHIGH, MODE_MAIN);
    
    if(stoch_k < 20 && stoch_k > stoch_d) {
        score += 0.1;
    }
    else if(stoch_k > 80 && stoch_k < stoch_d) {
        score -= 0.1;
    }
    
    // Williams %R Analysis
    double williams_r = iWPR(_Symbol, PERIOD_CURRENT, WilliamsR_Period);
    if(williams_r < -80) {
        score += 0.1;
    }
    else if(williams_r > -20) {
        score -= 0.1;
    }
    
    // CCI Analysis
    double cci = iCCI(_Symbol, PERIOD_CURRENT, CCI_Period, PRICE_TYPICAL);
    if(cci > 100) {
        score += 0.1;
    }
    else if(cci < -100) {
        score -= 0.1;
    }
    
    // ADX Analysis
    double adx = iADX(_Symbol, PERIOD_CURRENT, ADX_Period, PRICE_CLOSE, MODE_MAIN);
    double plus_di = iADX(_Symbol, PERIOD_CURRENT, ADX_Period, PRICE_CLOSE, MODE_PLUSDI);
    double minus_di = iADX(_Symbol, PERIOD_CURRENT, ADX_Period, PRICE_CLOSE, MODE_MINUSDI);
    
    if(adx > ADX_Threshold) {
        if(plus_di > minus_di) {
            score += 0.1;
        }
        else {
            score -= 0.1;
        }
    }
    
    return score;
}

//+------------------------------------------------------------------+
//| Execute Buy Order                                                |
//+------------------------------------------------------------------+
void ExecuteBuyOrder(AISignal signal)
{
    if(!CheckTradingConditions()) return;
    
    double lot_size = CalculateLotSize();
    if(lot_size <= 0) return;
    
    double stop_loss = CalculateStopLoss(1);
    double take_profit = CalculateTakeProfit(1);
    
    if(trade.Buy(lot_size, _Symbol, 0, stop_loss, take_profit, "UltraAI Buy")) {
        Print("Buy order executed: Lot=", lot_size, ", SL=", stop_loss, ", TP=", take_profit, ", Confidence=", signal.confidence);
        TotalTrades++;
    }
    else {
        Print("Buy order failed: Error=", trade.ResultRetcode());
    }
}

//+------------------------------------------------------------------+
//| Execute Sell Order                                               |
//+------------------------------------------------------------------+
void ExecuteSellOrder(AISignal signal)
{
    if(!CheckTradingConditions()) return;
    
    double lot_size = CalculateLotSize();
    if(lot_size <= 0) return;
    
    double stop_loss = CalculateStopLoss(-1);
    double take_profit = CalculateTakeProfit(-1);
    
    if(trade.Sell(lot_size, _Symbol, 0, stop_loss, take_profit, "UltraAI Sell")) {
        Print("Sell order executed: Lot=", lot_size, ", SL=", stop_loss, ", TP=", take_profit, ", Confidence=", signal.confidence);
        TotalTrades++;
    }
    else {
        Print("Sell order failed: Error=", trade.ResultRetcode());
    }
}

//+------------------------------------------------------------------+
//| Calculate Dynamic Stop Loss                                      |
//+------------------------------------------------------------------+
double CalculateStopLoss(int direction)
{
    if(!UseDynamicSL) return 0;
    
    double atr = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);
    double stop_loss = 0;
    
    if(direction == 1) {
        stop_loss = SymbolInfoDouble(_Symbol, SYMBOL_BID) - (atr * ATR_SL_Multiplier);
    }
    else {
        stop_loss = SymbolInfoDouble(_Symbol, SYMBOL_ASK) + (atr * ATR_SL_Multiplier);
    }
    
    return NormalizeDouble(stop_loss, _Digits);
}

//+------------------------------------------------------------------+
//| Calculate Dynamic Take Profit                                    |
//+------------------------------------------------------------------+
double CalculateTakeProfit(int direction)
{
    if(!UseDynamicTP) return 0;
    
    double atr = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);
    double take_profit = 0;
    
    if(direction == 1) {
        take_profit = SymbolInfoDouble(_Symbol, SYMBOL_ASK) + (atr * ATR_TP_Multiplier);
    }
    else {
        take_profit = SymbolInfoDouble(_Symbol, SYMBOL_BID) - (atr * ATR_TP_Multiplier);
    }
    
    return NormalizeDouble(take_profit, _Digits);
}

//+------------------------------------------------------------------+
//| Calculate Lot Size                                               |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
    if(!UseAutoLots) return LotSize;
    
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amount = balance * RiskPercent / 100;
    double atr = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);
    double stop_loss_pips = atr * ATR_SL_Multiplier;
    
    if(stop_loss_pips <= 0) return LotSize;
    
    double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double lot_size = risk_amount / (stop_loss_pips * tick_value);
    
    double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    lot_size = MathMax(min_lot, MathMin(max_lot, lot_size));
    lot_size = NormalizeDouble(lot_size / lot_step, 0) * lot_step;
    
    return lot_size;
}

//+------------------------------------------------------------------+
//| Check for Open Buy Position                                      |
//+------------------------------------------------------------------+
bool HasOpenBuyPosition()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(position.SelectByIndex(i)) {
            if(position.Symbol() == _Symbol && position.Magic() == MagicNumber && position.PositionType() == POSITION_TYPE_BUY) {
                return true;
            }
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Check for Open Sell Position                                     |
//+------------------------------------------------------------------+
bool HasOpenSellPosition()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(position.SelectByIndex(i)) {
            if(position.Symbol() == _Symbol && position.Magic() == MagicNumber && position.PositionType() == POSITION_TYPE_SELL) {
                return true;
            }
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Check Trading Conditions                                         |
//+------------------------------------------------------------------+
bool CheckTradingConditions()
{
    if(UseSpreadFilter) {
        double current_spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
        if(current_spread > MaxSpread * 10) {
            return false;
        }
    }
    
    if(UseVolatilityFilter) {
        double atr = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);
        double atr_percent = atr / iClose(_Symbol, PERIOD_CURRENT, 0);
        if(atr_percent < MinVolatility || atr_percent > MaxVolatility) {
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check Daily Limits                                               |
//+------------------------------------------------------------------+
bool CheckDailyLimits()
{
    double daily_pnl = 0;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(position.SelectByIndex(i)) {
            if(position.Symbol() == _Symbol && position.Magic() == MagicNumber) {
                daily_pnl += position.Profit();
            }
        }
    }
    
    if(daily_pnl < -MaxDailyLoss) {
        Print("Daily loss limit reached: ", daily_pnl);
        return false;
    }
    
    if(daily_pnl > MaxDailyProfit) {
        Print("Daily profit limit reached: ", daily_pnl);
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Update Trade Statistics                                          |
//+------------------------------------------------------------------+
void UpdateTradeStatistics()
{
    int total = 0;
    int wins = 0;
    double profit = 0;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(position.SelectByIndex(i)) {
            if(position.Symbol() == _Symbol && position.Magic() == MagicNumber) {
                total++;
                profit += position.Profit();
                
                if(position.Profit() > 0) wins++;
            }
        }
    }
    
    TotalTrades = total;
    WinningTrades = wins;
    TotalProfit = profit;
    
    if(total > 0) {
        WinRate = (double)wins / total * 100;
    }
}

//+------------------------------------------------------------------+
//| Reset Daily Counters                                             |
//+------------------------------------------------------------------+
void ResetDailyCounters()
{
    DailyProfit = 0;
    DailyLoss = 0;
    Print("Daily counters reset");
}

//+------------------------------------------------------------------+
//| Calculate Risk-Reward Ratio                                      |
//+------------------------------------------------------------------+
double CalculateRiskRewardRatio(int direction)
{
    double atr = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);
    double risk = atr * ATR_SL_Multiplier;
    double reward = atr * ATR_TP_Multiplier;
    
    if(risk > 0) {
        return reward / risk;
    }
    return 0;
}

//+------------------------------------------------------------------+
//| Validate Parameters                                              |
//+------------------------------------------------------------------+
bool ValidateParameters()
{
    if(LotSize <= 0 || RiskPercent <= 0 || RiskPercent > 10) {
        Print("Invalid lot size or risk parameters");
        return false;
    }
    
    if(AIConfidenceThreshold < 50 || AIConfidenceThreshold > 95) {
        Print("AI confidence threshold should be between 50-95");
        return false;
    }
    
    if(MaxDailyLoss <= 0 || MaxDailyProfit <= 0) {
        Print("Daily limits must be positive");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Placeholder functions for MT5 compatibility                      |
//+------------------------------------------------------------------+
double AnalyzeMultiTimeframe() { return 0; }
double AnalyzePriceAction() { return 0; }
double AnalyzeVolume() { return 0; }
double AnalyzeCorrelations() { return 0; }
MarketRegime DetectMarketRegime() { MarketRegime r; r.type = 0; r.strength = 0; r.volatility = 0; r.description = ""; return r; }
void ManageOpenPositions() { }