//+------------------------------------------------------------------+
//|                                    UltraAI_Expert_Advisor.mq4 |
//|                           Ultra Advanced AI Trading System |
//|                    Designed for Maximum Profitability Trading |
//+------------------------------------------------------------------+
#property copyright "UltraAI Expert Advisor - Advanced Trading System"
#property version   "3.0"
#property strict

//--- Input Parameters
input string    Settings_General = "=== General Settings ===";
input double    LotSize = 0.1;
input bool      UseAutoLots = true;
input double    RiskPercent = 1.5;
input int       MagicNumber = 99999;
input int       Slippage = 2;
input bool      EnableTrading = true;

input string    Settings_Strategy = "=== AI Strategy Settings ===";
input bool      UseAdvancedAI = true;
input int       AIConfidenceThreshold = 80;
input bool      UseEnsembleLearning = true;
input bool      UseAdaptiveParameters = true;
input int       LearningPeriod = 100;
input double    MinSignalStrength = 0.7;

input string    Settings_Indicators = "=== Multi-Indicator Settings ===";
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

input string    Settings_Risk = "=== Advanced Risk Management ===";
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

input string    Settings_Advanced = "=== Advanced AI Features ===";
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

//--- Trade Management Structure
struct TradeInfo {
    int ticket;
    double openPrice;
    double stopLoss;
    double takeProfit;
    double lotSize;
    int type;
    datetime openTime;
    double currentProfit;
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("=== UltraAI Expert Advisor Initialized ===");
    Print("Advanced AI Trading System Ready for Maximum Profitability");
    Print("Optimized for XAUUSD and Major Currency Pairs");
    
    LastBarTime = Time[0];
    DayStart = TimeCurrent();
    
    // Initialize AI learning parameters
    if(UseAdvancedAI) {
        Print("AI Learning System Activated");
        Print("Learning Period: ", LearningPeriod, " bars");
        Print("Confidence Threshold: ", AIConfidenceThreshold, "%");
    }
    
    // Validate input parameters
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
    Print("=== UltraAI Expert Advisor Deinitialized ===");
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
    if(Time[0] == LastBarTime) return;
    LastBarTime = Time[0];
    
    // Reset daily counters at new day
    if(TimeDay(Time[0]) != TimeDay(DayStart)) {
        ResetDailyCounters();
        DayStart = Time[0];
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
    signal.timestamp = Time[0];
    
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
    
    // Technical indicators (40% weight)
    total_score += technical_score * 0.4;
    total_weight += 0.4;
    
    // Multi-timeframe (25% weight)
    if(UseMultiTimeframe) {
        total_score += mtf_score * 0.25;
        total_weight += 0.25;
    }
    
    // Price action (20% weight)
    total_score += price_action_score * 0.2;
    total_weight += 0.2;
    
    // Volume (10% weight)
    if(UseVolumeAnalysis) {
        total_score += volume_score * 0.1;
        total_weight += 0.1;
    }
    
    // Correlation (5% weight)
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
        signal.direction = 1;  // Buy signal
        signal.confidence = total_score * 100;
        signal.strength = total_score;
        signal.reason = "Strong buy signal based on multiple indicators";
    }
    else if(total_score < -MinSignalStrength) {
        signal.direction = -1;  // Sell signal
        signal.confidence = MathAbs(total_score) * 100;
        signal.strength = MathAbs(total_score);
        signal.reason = "Strong sell signal based on multiple indicators";
    }
    
    // Calculate risk-reward ratio
    signal.risk_reward = CalculateRiskRewardRatio(signal.direction);
    
    // Adjust confidence based on market regime
    if(regime.type == 0) { // Trending market
        signal.confidence *= 1.1;
    }
    else if(regime.type == 1) { // Ranging market
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
    double fast_ema = iMA(Symbol(), 0, FastEMA, 0, MODE_EMA, PRICE_CLOSE, 0);
    double slow_ema = iMA(Symbol(), 0, SlowEMA, 0, MODE_EMA, PRICE_CLOSE, 0);
    double super_slow_ema = iMA(Symbol(), 0, SuperSlowEMA, 0, MODE_EMA, PRICE_CLOSE, 0);
    
    if(fast_ema > slow_ema && slow_ema > super_slow_ema) {
        score += 0.3;  // Strong uptrend
    }
    else if(fast_ema < slow_ema && slow_ema < super_slow_ema) {
        score -= 0.3;  // Strong downtrend
    }
    
    // RSI Analysis
    double rsi = iRSI(Symbol(), 0, RSI_Period, PRICE_CLOSE, 0);
    if(rsi < RSI_Oversold) {
        score += 0.2;  // Oversold condition
    }
    else if(rsi > RSI_Overbought) {
        score -= 0.2;  // Overbought condition
    }
    
    // MACD Analysis
    double macd_main = iMACD(Symbol(), 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 0);
    double macd_signal = iMACD(Symbol(), 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL, 0);
    double macd_prev = iMACD(Symbol(), 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 1);
    
    if(macd_main > macd_signal && macd_main > macd_prev) {
        score += 0.2;  // MACD bullish
    }
    else if(macd_main < macd_signal && macd_main < macd_prev) {
        score -= 0.2;  // MACD bearish
    }
    
    // Bollinger Bands Analysis
    double bb_upper = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_UPPER, 0);
    double bb_lower = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_LOWER, 0);
    double bb_middle = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_MAIN, 0);
    double close = Close[0];
    
    if(close < bb_lower) {
        score += 0.15;  // Price below lower band
    }
    else if(close > bb_upper) {
        score -= 0.15;  // Price above upper band
    }
    
    // Stochastic Analysis
    double stoch_k = iStochastic(Symbol(), 0, Stochastic_K, Stochastic_D, Stochastic_Slowing, MODE_SMA, 0, MODE_MAIN, 0);
    double stoch_d = iStochastic(Symbol(), 0, Stochastic_K, Stochastic_D, Stochastic_Slowing, MODE_SMA, 0, MODE_SIGNAL, 0);
    
    if(stoch_k < 20 && stoch_k > stoch_d) {
        score += 0.1;  // Stochastic bullish crossover
    }
    else if(stoch_k > 80 && stoch_k < stoch_d) {
        score -= 0.1;  // Stochastic bearish crossover
    }
    
    // Williams %R Analysis
    double williams_r = iWPR(Symbol(), 0, WilliamsR_Period, 0);
    if(williams_r < -80) {
        score += 0.1;  // Oversold
    }
    else if(williams_r > -20) {
        score -= 0.1;  // Overbought
    }
    
    // CCI Analysis
    double cci = iCCI(Symbol(), 0, CCI_Period, PRICE_TYPICAL, 0);
    if(cci > 100) {
        score += 0.1;  // Bullish momentum
    }
    else if(cci < -100) {
        score -= 0.1;  // Bearish momentum
    }
    
    // ADX Analysis
    double adx = iADX(Symbol(), 0, ADX_Period, PRICE_CLOSE, MODE_MAIN, 0);
    double plus_di = iADX(Symbol(), 0, ADX_Period, PRICE_CLOSE, MODE_PLUSDI, 0);
    double minus_di = iADX(Symbol(), 0, ADX_Period, PRICE_CLOSE, MODE_MINUSDI, 0);
    
    if(adx > ADX_Threshold) {
        if(plus_di > minus_di) {
            score += 0.1;  // Strong uptrend
        }
        else {
            score -= 0.1;  // Strong downtrend
        }
    }
    
    return score;
}

//+------------------------------------------------------------------+
//| Analyze Multi-Timeframe                                          |
//+------------------------------------------------------------------+
double AnalyzeMultiTimeframe()
{
    double score = 0;
    
    // Current timeframe (M1)
    double tf1_score = AnalyzeTimeframe(1);
    
    // M5 timeframe
    double tf5_score = AnalyzeTimeframe(5);
    
    // M15 timeframe
    double tf15_score = AnalyzeTimeframe(15);
    
    // M30 timeframe
    double tf30_score = AnalyzeTimeframe(30);
    
    // H1 timeframe
    double tf60_score = AnalyzeTimeframe(60);
    
    // H4 timeframe
    double tf240_score = AnalyzeTimeframe(240);
    
    // Weighted average (higher timeframes have more weight)
    score = (tf1_score * 0.1 + tf5_score * 0.15 + tf15_score * 0.2 + 
             tf30_score * 0.25 + tf60_score * 0.2 + tf240_score * 0.1);
    
    return score;
}

//+------------------------------------------------------------------+
//| Analyze Specific Timeframe                                       |
//+------------------------------------------------------------------+
double AnalyzeTimeframe(int timeframe)
{
    double score = 0;
    
    // EMA analysis for this timeframe
    double fast_ema = iMA(Symbol(), timeframe, FastEMA, 0, MODE_EMA, PRICE_CLOSE, 0);
    double slow_ema = iMA(Symbol(), timeframe, SlowEMA, 0, MODE_EMA, PRICE_CLOSE, 0);
    
    if(fast_ema > slow_ema) {
        score += 0.5;
    }
    else {
        score -= 0.5;
    }
    
    // RSI analysis for this timeframe
    double rsi = iRSI(Symbol(), timeframe, RSI_Period, PRICE_CLOSE, 0);
    if(rsi < 30) {
        score += 0.3;
    }
    else if(rsi > 70) {
        score -= 0.3;
    }
    
    // MACD analysis for this timeframe
    double macd_main = iMACD(Symbol(), timeframe, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 0);
    double macd_signal = iMACD(Symbol(), timeframe, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL, 0);
    
    if(macd_main > macd_signal) {
        score += 0.2;
    }
    else {
        score -= 0.2;
    }
    
    return score;
}

//+------------------------------------------------------------------+
//| Analyze Price Action                                             |
//+------------------------------------------------------------------+
double AnalyzePriceAction()
{
    double score = 0;
    
    // Candlestick patterns
    double open1 = Open[1], high1 = High[1], low1 = Low[1], close1 = Close[1];
    double open2 = Open[2], high2 = High[2], low2 = Low[2], close2 = Close[2];
    double open3 = Open[3], high3 = High[3], low3 = Low[3], close3 = Close[3];
    
    // Bullish engulfing
    if(close1 > open1 && open2 > close2 && close1 > open2 && open1 < close2) {
        score += 0.3;
    }
    
    // Bearish engulfing
    if(close1 < open1 && open2 < close2 && close1 < open2 && open1 > close2) {
        score -= 0.3;
    }
    
    // Hammer
    if(close1 > open1 && (high1 - low1) > 3 * (close1 - open1) && 
       (close1 - low1) > 0.6 * (high1 - low1)) {
        score += 0.2;
    }
    
    // Shooting star
    if(close1 < open1 && (high1 - low1) > 3 * (open1 - close1) && 
       (high1 - open1) > 0.6 * (high1 - low1)) {
        score -= 0.2;
    }
    
    // Support and resistance levels
    double current_price = Close[0];
    double support = FindSupport();
    double resistance = FindResistance();
    
    if(current_price < support + 0.0005) {
        score += 0.2;  // Near support
    }
    else if(current_price > resistance - 0.0005) {
        score -= 0.2;  // Near resistance
    }
    
    // Trend strength
    double trend_strength = CalculateTrendStrength();
    if(trend_strength > 0.7) {
        score += 0.1;
    }
    else if(trend_strength < 0.3) {
        score -= 0.1;
    }
    
    return score;
}

//+------------------------------------------------------------------+
//| Detect Market Regime                                             |
//+------------------------------------------------------------------+
MarketRegime DetectMarketRegime()
{
    MarketRegime regime;
    regime.type = 0;
    regime.strength = 0;
    regime.volatility = 0;
    regime.description = "";
    
    // Calculate volatility using ATR
    double atr = iATR(Symbol(), 0, ATR_Period, 0);
    double atr_percent = atr / Close[0] * 100;
    regime.volatility = atr_percent;
    
    // Calculate trend strength using ADX
    double adx = iADX(Symbol(), 0, ADX_Period, PRICE_CLOSE, MODE_MAIN, 0);
    
    // Determine market regime
    if(adx > 25 && atr_percent > 0.1) {
        regime.type = 0;  // Trending
        regime.strength = adx / 100;
        regime.description = "Strong Trending Market";
    }
    else if(adx < 20 && atr_percent < 0.05) {
        regime.type = 1;  // Ranging
        regime.strength = (20 - adx) / 20;
        regime.description = "Ranging Market";
    }
    else if(atr_percent > 0.15) {
        regime.type = 2;  // Volatile
        regime.strength = atr_percent / 0.2;
        regime.description = "High Volatility Market";
    }
    else {
        regime.type = 3;  // Low volatility
        regime.strength = 1 - (atr_percent / 0.05);
        regime.description = "Low Volatility Market";
    }
    
    return regime;
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
    
    int ticket = OrderSend(Symbol(), OP_BUY, lot_size, Ask, Slippage, stop_loss, take_profit, 
                          "UltraAI Buy", MagicNumber, 0, clrGreen);
    
    if(ticket > 0) {
        Print("Buy order executed: Ticket=", ticket, ", Lot=", lot_size, 
              ", SL=", stop_loss, ", TP=", take_profit, ", Confidence=", signal.confidence);
        TotalTrades++;
    }
    else {
        Print("Buy order failed: Error=", GetLastError());
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
    
    int ticket = OrderSend(Symbol(), OP_SELL, lot_size, Bid, Slippage, stop_loss, take_profit, 
                          "UltraAI Sell", MagicNumber, 0, clrRed);
    
    if(ticket > 0) {
        Print("Sell order executed: Ticket=", ticket, ", Lot=", lot_size, 
              ", SL=", stop_loss, ", TP=", take_profit, ", Confidence=", signal.confidence);
        TotalTrades++;
    }
    else {
        Print("Sell order failed: Error=", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Calculate Dynamic Stop Loss                                      |
//+------------------------------------------------------------------+
double CalculateStopLoss(int direction)
{
    if(!UseDynamicSL) return 0;
    
    double atr = iATR(Symbol(), 0, ATR_Period, 0);
    double stop_loss = 0;
    
    if(direction == 1) {  // Buy
        stop_loss = Bid - (atr * ATR_SL_Multiplier);
    }
    else {  // Sell
        stop_loss = Ask + (atr * ATR_SL_Multiplier);
    }
    
    return NormalizeDouble(stop_loss, Digits);
}

//+------------------------------------------------------------------+
//| Calculate Dynamic Take Profit                                    |
//+------------------------------------------------------------------+
double CalculateTakeProfit(int direction)
{
    if(!UseDynamicTP) return 0;
    
    double atr = iATR(Symbol(), 0, ATR_Period, 0);
    double take_profit = 0;
    
    if(direction == 1) {  // Buy
        take_profit = Ask + (atr * ATR_TP_Multiplier);
    }
    else {  // Sell
        take_profit = Bid - (atr * ATR_TP_Multiplier);
    }
    
    return NormalizeDouble(take_profit, Digits);
}

//+------------------------------------------------------------------+
//| Calculate Lot Size                                               |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
    if(!UseAutoLots) return LotSize;
    
    double balance = AccountBalance();
    double risk_amount = balance * RiskPercent / 100;
    double atr = iATR(Symbol(), 0, ATR_Period, 0);
    double stop_loss_pips = atr * ATR_SL_Multiplier;
    
    if(stop_loss_pips <= 0) return LotSize;
    
    double tick_value = MarketInfo(Symbol(), MODE_TICKVALUE);
    double lot_size = risk_amount / (stop_loss_pips * tick_value);
    
    // Normalize lot size
    double min_lot = MarketInfo(Symbol(), MODE_MINLOT);
    double max_lot = MarketInfo(Symbol(), MODE_MAXLOT);
    double lot_step = MarketInfo(Symbol(), MODE_LOTSTEP);
    
    lot_size = MathMax(min_lot, MathMin(max_lot, lot_size));
    lot_size = NormalizeDouble(lot_size / lot_step, 0) * lot_step;
    
    return lot_size;
}

//+------------------------------------------------------------------+
//| Manage Open Positions                                            |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) {
                
                // Trailing stop
                if(UseTrailingStop) {
                    ApplyTrailingStop(OrderTicket());
                }
                
                // Break even
                if(UseBreakEven) {
                    ApplyBreakEven(OrderTicket());
                }
                
                // Partial close
                if(UsePartialClose) {
                    ApplyPartialClose(OrderTicket());
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Apply Trailing Stop                                              |
//+------------------------------------------------------------------+
void ApplyTrailingStop(int ticket)
{
    if(!OrderSelect(ticket, SELECT_BY_TICKET)) return;
    
    double current_sl = OrderStopLoss();
    double new_sl = 0;
    bool modify = false;
    
    if(OrderType() == OP_BUY) {
        double profit_pips = (Bid - OrderOpenPrice()) / Point;
        if(profit_pips >= TrailingStart) {
            new_sl = Bid - (TrailingStep * Point);
            if(new_sl > current_sl) {
                modify = true;
            }
        }
    }
    else if(OrderType() == OP_SELL) {
        double profit_pips = (OrderOpenPrice() - Ask) / Point;
        if(profit_pips >= TrailingStart) {
            new_sl = Ask + (TrailingStep * Point);
            if(new_sl < current_sl || current_sl == 0) {
                modify = true;
            }
        }
    }
    
    if(modify) {
        OrderModify(ticket, OrderOpenPrice(), new_sl, OrderTakeProfit(), 0, clrBlue);
    }
}

//+------------------------------------------------------------------+
//| Apply Break Even                                                 |
//+------------------------------------------------------------------+
void ApplyBreakEven(int ticket)
{
    if(!OrderSelect(ticket, SELECT_BY_TICKET)) return;
    
    double current_sl = OrderStopLoss();
    double new_sl = 0;
    bool modify = false;
    
    if(OrderType() == OP_BUY) {
        double profit_pips = (Bid - OrderOpenPrice()) / Point;
        if(profit_pips >= BreakEvenPips) {
            new_sl = OrderOpenPrice() + (BreakEvenOffset * Point);
            if(new_sl > current_sl) {
                modify = true;
            }
        }
    }
    else if(OrderType() == OP_SELL) {
        double profit_pips = (OrderOpenPrice() - Ask) / Point;
        if(profit_pips >= BreakEvenPips) {
            new_sl = OrderOpenPrice() - (BreakEvenOffset * Point);
            if(new_sl < current_sl || current_sl == 0) {
                modify = true;
            }
        }
    }
    
    if(modify) {
        OrderModify(ticket, OrderOpenPrice(), new_sl, OrderTakeProfit(), 0, clrYellow);
    }
}

//+------------------------------------------------------------------+
//| Apply Partial Close                                              |
//+------------------------------------------------------------------+
void ApplyPartialClose(int ticket)
{
    if(!OrderSelect(ticket, SELECT_BY_TICKET)) return;
    
    double profit_pips = 0;
    if(OrderType() == OP_BUY) {
        profit_pips = (Bid - OrderOpenPrice()) / Point;
    }
    else if(OrderType() == OP_SELL) {
        profit_pips = (OrderOpenPrice() - Ask) / Point;
    }
    
    if(profit_pips >= PartialClosePips) {
        double close_lots = OrderLots() * PartialClosePercent / 100;
        if(OrderClose(ticket, close_lots, OrderType() == OP_BUY ? Bid : Ask, Slippage, clrOrange)) {
            Print("Partial close executed: Ticket=", ticket, ", Lots=", close_lots);
        }
    }
}

//+------------------------------------------------------------------+
//| Check Trading Conditions                                         |
//+------------------------------------------------------------------+
bool CheckTradingConditions()
{
    // Spread filter
    if(UseSpreadFilter) {
        double current_spread = (Ask - Bid) / Point;
        if(current_spread > MaxSpread) {
            return false;
        }
    }
    
    // Volatility filter
    if(UseVolatilityFilter) {
        double atr = iATR(Symbol(), 0, ATR_Period, 0);
        double atr_percent = atr / Close[0];
        if(atr_percent < MinVolatility || atr_percent > MaxVolatility) {
            return false;
        }
    }
    
    // News filter (basic implementation)
    if(UseNewsFilter) {
        if(IsNewsTime()) {
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
    
    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) {
                daily_pnl += OrderProfit() + OrderSwap() + OrderCommission();
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
    
    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) {
                total++;
                double order_profit = OrderProfit() + OrderSwap() + OrderCommission();
                profit += order_profit;
                
                if(order_profit > 0) wins++;
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
//| Check for Open Buy Position                                      |
//+------------------------------------------------------------------+
bool HasOpenBuyPosition()
{
    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == OP_BUY) {
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
    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
                if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == OP_SELL) {
                    return true;
                }
            }
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Calculate Risk-Reward Ratio                                      |
//+------------------------------------------------------------------+
double CalculateRiskRewardRatio(int direction)
{
    double atr = iATR(Symbol(), 0, ATR_Period, 0);
    double risk = atr * ATR_SL_Multiplier;
    double reward = atr * ATR_TP_Multiplier;
    
    if(risk > 0) {
        return reward / risk;
    }
    return 0;
}

//+------------------------------------------------------------------+
//| Find Support Level                                               |
//+------------------------------------------------------------------+
double FindSupport()
{
    double support = Low[0];
    for(int i = 1; i < 20; i++) {
        if(Low[i] < support) {
            support = Low[i];
        }
    }
    return support;
}

//+------------------------------------------------------------------+
//| Find Resistance Level                                            |
//+------------------------------------------------------------------+
double FindResistance()
{
    double resistance = High[0];
    for(int i = 1; i < 20; i++) {
        if(High[i] > resistance) {
            resistance = High[i];
        }
    }
    return resistance;
}

//+------------------------------------------------------------------+
//| Calculate Trend Strength                                         |
//+------------------------------------------------------------------+
double CalculateTrendStrength()
{
    double ema_fast = iMA(Symbol(), 0, FastEMA, 0, MODE_EMA, PRICE_CLOSE, 0);
    double ema_slow = iMA(Symbol(), 0, SlowEMA, 0, MODE_EMA, PRICE_CLOSE, 0);
    double ema_super_slow = iMA(Symbol(), 0, SuperSlowEMA, 0, MODE_EMA, PRICE_CLOSE, 0);
    
    double strength = 0;
    
    if(ema_fast > ema_slow && ema_slow > ema_super_slow) {
        strength = (ema_fast - ema_super_slow) / ema_super_slow;
    }
    else if(ema_fast < ema_slow && ema_slow < ema_super_slow) {
        strength = (ema_super_slow - ema_fast) / ema_super_slow;
    }
    
    return MathMin(strength, 1.0);
}

//+------------------------------------------------------------------+
//| Analyze Volume                                                   |
//+------------------------------------------------------------------+
double AnalyzeVolume()
{
    // Basic volume analysis (MT4 has limited volume data)
    double volume = Volume[0];
    double avg_volume = 0;
    
    for(int i = 1; i < 20; i++) {
        avg_volume += Volume[i];
    }
    avg_volume /= 19;
    
    if(volume > avg_volume * 1.5) {
        return 0.2;  // High volume
    }
    else if(volume < avg_volume * 0.5) {
        return -0.1;  // Low volume
    }
    
    return 0;
}

//+------------------------------------------------------------------+
//| Analyze Correlations                                             |
//+------------------------------------------------------------------+
double AnalyzeCorrelations()
{
    // Basic correlation analysis with major pairs
    double correlation_score = 0;
    
    // EURUSD correlation
    double eurusd_change = (iClose("EURUSD", 0, 0) - iClose("EURUSD", 0, 1)) / iClose("EURUSD", 0, 1);
    double current_change = (Close[0] - Close[1]) / Close[1];
    
    if(MathAbs(eurusd_change) > 0.0001 && MathAbs(current_change) > 0.0001) {
        if((eurusd_change > 0 && current_change > 0) || (eurusd_change < 0 && current_change < 0)) {
            correlation_score += 0.1;
        }
        else {
            correlation_score -= 0.1;
        }
    }
    
    return correlation_score;
}

//+------------------------------------------------------------------+
//| Check if it's News Time                                         |
//+------------------------------------------------------------------+
bool IsNewsTime()
{
    // Basic news time filter (you can enhance this with actual news data)
    int hour = TimeHour(TimeCurrent());
    
    // Avoid trading during major news times (example: 8:00-9:00 GMT)
    if(hour == 8) {
        return true;
    }
    
    return false;
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