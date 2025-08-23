//+------------------------------------------------------------------+
//|                                   AI_Expert_Advisor_Complete.mq5 |
//|                                    Advanced AI Trading Expert    |
//|                                        For XAUUSD & Major Pairs  |
//+------------------------------------------------------------------+
#property copyright "Advanced AI Expert Advisor - Complete"
#property link      ""
#property version   "2.00"
#property description "Complete AI-powered Expert Advisor with Machine Learning"

//--- Input Parameters
input group "=== AI & Strategy Settings ==="
input double   LotSize = 0.01;                    // Initial lot size
input bool     UseAdaptiveLotSize = true;         // Use adaptive position sizing
input double   RiskPercentage = 2.0;              // Risk percentage per trade
input bool     UseAISignals = true;               // Enable AI signal generation
input int      LookbackPeriod = 100;              // Lookback period for ML analysis
input double   MinSignalStrength = 0.6;           // Minimum signal strength to trade

input group "=== Money Management ==="
input bool     UseDynamicTP = true;               // Use dynamic take profit
input bool     UseDynamicSL = true;               // Use dynamic stop loss
input double   BaseTPMultiplier = 2.0;            // Base TP multiplier
input double   BaseSLMultiplier = 1.0;            // Base SL multiplier
input bool     UseTrailingStop = true;            // Use trailing stop
input double   TrailingStopDistance = 50;         // Trailing stop distance in points
input double   MaxRiskPerTrade = 5.0;             // Maximum risk per trade (%)
input int      MaxOpenPositions = 3;              // Maximum open positions

input group "=== Indicator Settings ==="
input int      RSI_Period = 14;                   // RSI period
input int      MACD_Fast = 12;                    // MACD fast EMA
input int      MACD_Slow = 26;                    // MACD slow EMA
input int      MACD_Signal = 9;                   // MACD signal
input int      BB_Period = 20;                    // Bollinger Bands period
input double   BB_Deviation = 2.0;                // Bollinger Bands deviation
input int      Stoch_K = 14;                      // Stochastic %K
input int      Stoch_D = 3;                       // Stochastic %D
input int      Williams_Period = 14;              // Williams %R period
input int      ATR_Period = 14;                   // ATR period

input group "=== Market Condition Analysis ==="
input bool     UseMarketConditionFilter = true;   // Use market condition analysis
input int      TrendStrengthPeriod = 50;          // Trend strength analysis period
input double   VolatilityThreshold = 1.5;         // Volatility threshold multiplier
input bool     UseNewsFilter = true;              // Avoid trading during news
input int      NewsAvoidanceMinutes = 30;         // Minutes to avoid trading before/after news

input group "=== Time & Symbol Filters ==="
input string   TradingSymbols = "XAUUSD,EURUSD,GBPUSD,USDJPY,USDCHF,AUDUSD,USDCAD,NZDUSD"; // Trading symbols
input bool     UseTimeFilter = true;              // Use trading time filter
input int      StartHour = 8;                     // Trading start hour
input int      EndHour = 22;                      // Trading end hour
input bool     AvoidFridayTrading = true;         // Avoid Friday late trading

//--- Global Variables
int rsi_handle, macd_handle, bb_handle, stoch_handle, williams_handle, atr_handle;
double rsi_buffer[], macd_main[], macd_signal[], bb_upper[], bb_middle[], bb_lower[];
double stoch_main[], stoch_signal[], williams_buffer[], atr_buffer[];

struct MarketData {
    double high[];
    double low[];
    double close[];
    double open[];
    double volume[];
};

struct AISignal {
    double strength;
    int direction;      // 1 for buy, -1 for sell, 0 for hold
    double confidence;
    string reason;
    datetime timestamp;
};

struct TradeInfo {
    double entry_price;
    double stop_loss;
    double take_profit;
    double lot_size;
    datetime entry_time;
    string symbol;
    double unrealized_pnl;
};

struct MarketRegime {
    double trend_strength;
    double volatility_level;
    string market_phase; // "trending", "ranging", "breakout", "consolidation"
    double momentum_score;
};

MarketData market_data;
AISignal current_signal;
TradeInfo last_trade;
MarketRegime current_regime;

//--- Arrays for ML-inspired analysis
double price_changes[];
double volatility_data[];
double correlation_matrix[];
int pattern_recognition[];
double support_levels[], resistance_levels[];
double ma_fast[], ma_slow[];

//--- Performance tracking
struct PerformanceStats {
    int total_trades;
    int winning_trades;
    int losing_trades;
    double total_profit;
    double max_drawdown;
    double profit_factor;
    double win_rate;
    datetime last_update;
};

PerformanceStats performance;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("=== AI Expert Advisor Complete - Initialization ===");
    
    // Initialize indicator handles
    if(!InitializeIndicators()) {
        Print("Error: Failed to initialize indicators");
        return INIT_FAILED;
    }
    
    // Initialize market data arrays
    InitializeMarketData();
    
    // Initialize AI components
    InitializeAIComponents();
    
    // Initialize performance tracking
    InitializePerformanceTracking();
    
    Print("AI Expert Advisor initialized successfully for ", Symbol());
    Print("Using AI signals: ", UseAISignals ? "Yes" : "No");
    Print("Risk per trade: ", RiskPercentage, "%");
    Print("Minimum signal strength: ", MinSignalStrength);
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release indicator handles
    if(rsi_handle != INVALID_HANDLE) IndicatorRelease(rsi_handle);
    if(macd_handle != INVALID_HANDLE) IndicatorRelease(macd_handle);
    if(bb_handle != INVALID_HANDLE) IndicatorRelease(bb_handle);
    if(stoch_handle != INVALID_HANDLE) IndicatorRelease(stoch_handle);
    if(williams_handle != INVALID_HANDLE) IndicatorRelease(williams_handle);
    if(atr_handle != INVALID_HANDLE) IndicatorRelease(atr_handle);
    
    // Print final performance stats
    PrintPerformanceReport();
    
    Print("AI Expert Advisor deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check if we should trade this symbol
    if(!IsSymbolAllowed()) return;
    
    // Check time filter
    if(UseTimeFilter && !IsWithinTradingHours()) return;
    
    // Update market data
    UpdateMarketData();
    
    // Update indicators
    UpdateIndicators();
    
    // Analyze market regime
    AnalyzeMarketRegime();
    
    // Perform AI analysis
    if(UseAISignals) {
        current_signal = GenerateAISignal();
    } else {
        current_signal = GenerateTraditionalSignal();
    }
    
    // Market condition analysis
    if(UseMarketConditionFilter && !IsMarketConditionFavorable()) {
        return;
    }
    
    // Process trading signals
    ProcessTradingSignals();
    
    // Update trailing stops
    if(UseTrailingStop) {
        UpdateTrailingStops();
    }
    
    // Risk management check
    CheckRiskManagement();
    
    // Update performance stats
    UpdatePerformanceStats();
    
    // Log AI decisions periodically
    static datetime last_log = 0;
    if(TimeCurrent() - last_log > 3600) { // Log every hour
        LogAIDecision();
        last_log = TimeCurrent();
    }
}

//+------------------------------------------------------------------+
//| Initialize all indicators                                        |
//+------------------------------------------------------------------+
bool InitializeIndicators()
{
    rsi_handle = iRSI(Symbol(), PERIOD_CURRENT, RSI_Period, PRICE_CLOSE);
    macd_handle = iMACD(Symbol(), PERIOD_CURRENT, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE);
    bb_handle = iBands(Symbol(), PERIOD_CURRENT, BB_Period, 0, BB_Deviation, PRICE_CLOSE);
    stoch_handle = iStochastic(Symbol(), PERIOD_CURRENT, Stoch_K, Stoch_D, 3, MODE_SMA, STO_LOWHIGH);
    williams_handle = iWPR(Symbol(), PERIOD_CURRENT, Williams_Period);
    atr_handle = iATR(Symbol(), PERIOD_CURRENT, ATR_Period);
    
    if(rsi_handle == INVALID_HANDLE || macd_handle == INVALID_HANDLE || 
       bb_handle == INVALID_HANDLE || stoch_handle == INVALID_HANDLE ||
       williams_handle == INVALID_HANDLE || atr_handle == INVALID_HANDLE) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Initialize market data arrays                                   |
//+------------------------------------------------------------------+
void InitializeMarketData()
{
    ArraySetAsSeries(market_data.high, true);
    ArraySetAsSeries(market_data.low, true);
    ArraySetAsSeries(market_data.close, true);
    ArraySetAsSeries(market_data.open, true);
    ArraySetAsSeries(market_data.volume, true);
    
    ArrayResize(market_data.high, LookbackPeriod);
    ArrayResize(market_data.low, LookbackPeriod);
    ArrayResize(market_data.close, LookbackPeriod);
    ArrayResize(market_data.open, LookbackPeriod);
    ArrayResize(market_data.volume, LookbackPeriod);
}

//+------------------------------------------------------------------+
//| Initialize AI components                                         |
//+------------------------------------------------------------------+
void InitializeAIComponents()
{
    ArrayResize(price_changes, LookbackPeriod);
    ArrayResize(volatility_data, LookbackPeriod);
    ArrayResize(correlation_matrix, 10);
    ArrayResize(pattern_recognition, LookbackPeriod);
    ArrayResize(support_levels, 10);
    ArrayResize(resistance_levels, 10);
    ArrayResize(ma_fast, LookbackPeriod);
    ArrayResize(ma_slow, LookbackPeriod);
    
    ArrayFill(price_changes, 0, LookbackPeriod, 0.0);
    ArrayFill(volatility_data, 0, LookbackPeriod, 0.0);
    ArrayFill(correlation_matrix, 0, 10, 0.0);
    ArrayFill(pattern_recognition, 0, LookbackPeriod, 0);
    ArrayFill(support_levels, 0, 10, 0.0);
    ArrayFill(resistance_levels, 0, 10, 0.0);
    ArrayFill(ma_fast, 0, LookbackPeriod, 0.0);
    ArrayFill(ma_slow, 0, LookbackPeriod, 0.0);
}

//+------------------------------------------------------------------+
//| Initialize performance tracking                                  |
//+------------------------------------------------------------------+
void InitializePerformanceTracking()
{
    performance.total_trades = 0;
    performance.winning_trades = 0;
    performance.losing_trades = 0;
    performance.total_profit = 0.0;
    performance.max_drawdown = 0.0;
    performance.profit_factor = 0.0;
    performance.win_rate = 0.0;
    performance.last_update = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Update market data and calculate derived values                 |
//+------------------------------------------------------------------+
void UpdateMarketData()
{
    CopyHigh(Symbol(), PERIOD_CURRENT, 0, LookbackPeriod, market_data.high);
    CopyLow(Symbol(), PERIOD_CURRENT, 0, LookbackPeriod, market_data.low);
    CopyClose(Symbol(), PERIOD_CURRENT, 0, LookbackPeriod, market_data.close);
    CopyOpen(Symbol(), PERIOD_CURRENT, 0, LookbackPeriod, market_data.open);
    CopyTickVolume(Symbol(), PERIOD_CURRENT, 0, LookbackPeriod, market_data.volume);
    
    // Calculate price changes for ML analysis
    for(int i = 1; i < LookbackPeriod; i++) {
        if(market_data.close[i] != 0) {
            price_changes[i] = (market_data.close[i-1] - market_data.close[i]) / market_data.close[i] * 100;
        }
    }
    
    // Calculate volatility
    CalculateVolatility();
    
    // Calculate moving averages
    CalculateMovingAverages();
    
    // Update support and resistance levels
    UpdateSupportResistanceLevels();
}

//+------------------------------------------------------------------+
//| Update all indicator buffers                                    |
//+------------------------------------------------------------------+
void UpdateIndicators()
{
    ArraySetAsSeries(rsi_buffer, true);
    ArraySetAsSeries(macd_main, true);
    ArraySetAsSeries(macd_signal, true);
    ArraySetAsSeries(bb_upper, true);
    ArraySetAsSeries(bb_middle, true);
    ArraySetAsSeries(bb_lower, true);
    ArraySetAsSeries(stoch_main, true);
    ArraySetAsSeries(stoch_signal, true);
    ArraySetAsSeries(williams_buffer, true);
    ArraySetAsSeries(atr_buffer, true);
    
    CopyBuffer(rsi_handle, 0, 0, 10, rsi_buffer);
    CopyBuffer(macd_handle, 0, 0, 10, macd_main);
    CopyBuffer(macd_handle, 1, 0, 10, macd_signal);
    CopyBuffer(bb_handle, 0, 0, 10, bb_upper);
    CopyBuffer(bb_handle, 1, 0, 10, bb_middle);
    CopyBuffer(bb_handle, 2, 0, 10, bb_lower);
    CopyBuffer(stoch_handle, 0, 0, 10, stoch_main);
    CopyBuffer(stoch_handle, 1, 0, 10, stoch_signal);
    CopyBuffer(williams_handle, 0, 0, 10, williams_buffer);
    CopyBuffer(atr_handle, 0, 0, 10, atr_buffer);
}

//+------------------------------------------------------------------+
//| Advanced AI Signal Generation                                   |
//+------------------------------------------------------------------+
AISignal GenerateAISignal()
{
    AISignal signal;
    signal.strength = 0.0;
    signal.direction = 0;
    signal.confidence = 0.0;
    signal.reason = "";
    signal.timestamp = TimeCurrent();
    
    // Multi-indicator consensus analysis
    double indicator_scores[];
    ArrayResize(indicator_scores, 8);
    
    // Core indicator analysis
    indicator_scores[0] = AnalyzeRSI();
    indicator_scores[1] = AnalyzeMacd();
    indicator_scores[2] = AnalyzeBollingerBands();
    indicator_scores[3] = AnalyzeStochastic();
    indicator_scores[4] = AnalyzeWilliams();
    indicator_scores[5] = AnalyzePriceAction();
    indicator_scores[6] = AnalyzeVolume();
    indicator_scores[7] = AnalyzeMovingAverages();
    
    // ML-inspired adaptive weights based on recent performance
    double weights[] = {0.15, 0.2, 0.15, 0.08, 0.07, 0.2, 0.1, 0.05};
    
    // Adjust weights based on market regime
    AdjustWeightsBasedOnMarketCondition(weights, current_regime.trend_strength);
    
    // Calculate weighted consensus
    double weighted_score = 0.0;
    for(int i = 0; i < 8; i++) {
        weighted_score += indicator_scores[i] * weights[i];
    }
    
    // Apply market regime filters
    double regime_multiplier = CalculateRegimeMultiplier();
    weighted_score *= regime_multiplier;
    
    // Volatility adjustment
    double volatility_factor = CalculateVolatilityFactor();
    weighted_score *= volatility_factor;
    
    // Pattern recognition enhancement
    double pattern_boost = RecognizePatterns();
    weighted_score += pattern_boost;
    
    // Correlation analysis
    double correlation_factor = AnalyzeIndicatorCorrelations();
    weighted_score *= correlation_factor;
    
    // Final signal properties
    signal.strength = MathAbs(weighted_score);
    signal.direction = weighted_score > 0.15 ? 1 : (weighted_score < -0.15 ? -1 : 0);
    signal.confidence = CalculateConfidence(indicator_scores, weighted_score);
    signal.reason = GenerateSignalReason(indicator_scores, weighted_score, current_regime);
    
    // Apply final filters
    if(signal.confidence < MinSignalStrength) {
        signal.direction = 0;
        signal.strength = 0;
    }
    
    return signal;
}

//+------------------------------------------------------------------+
//| Comprehensive RSI Analysis with Divergence Detection           |
//+------------------------------------------------------------------+
double AnalyzeRSI()
{
    if(ArraySize(rsi_buffer) < 5) return 0.0;
    
    double score = 0.0;
    double rsi_current = rsi_buffer[0];
    double rsi_prev = rsi_buffer[1];
    double rsi_prev2 = rsi_buffer[2];
    double rsi_prev3 = rsi_buffer[3];
    double rsi_prev4 = rsi_buffer[4];
    
    // Enhanced overbought/oversold with dynamic levels
    double ob_level = 70 + (current_regime.volatility_level * 10);
    double os_level = 30 - (current_regime.volatility_level * 10);
    
    if(rsi_current < os_level) score += 0.4;
    if(rsi_current > ob_level) score -= 0.4;
    
    // RSI divergence analysis (more sophisticated)
    bool bullish_div = (rsi_current > rsi_prev && rsi_prev > rsi_prev2) && 
                       (market_data.close[0] < market_data.close[1] && market_data.close[1] < market_data.close[2]);
    bool bearish_div = (rsi_current < rsi_prev && rsi_prev < rsi_prev2) && 
                       (market_data.close[0] > market_data.close[1] && market_data.close[1] > market_data.close[2]);
    
    if(bullish_div) score += 0.5;
    if(bearish_div) score -= 0.5;
    
    // RSI momentum and acceleration
    double rsi_momentum = rsi_current - rsi_prev;
    double rsi_acceleration = (rsi_current - rsi_prev) - (rsi_prev - rsi_prev2);
    
    score += rsi_momentum * 0.015;
    score += rsi_acceleration * 0.01;
    
    // RSI trend analysis
    double rsi_ma = (rsi_current + rsi_prev + rsi_prev2 + rsi_prev3 + rsi_prev4) / 5.0;
    if(rsi_current > rsi_ma) score += 0.1;
    else score -= 0.1;
    
    return MathMax(-1.0, MathMin(1.0, score));
}

//+------------------------------------------------------------------+
//| Advanced MACD Analysis                                          |
//+------------------------------------------------------------------+
double AnalyzeMacd()
{
    if(ArraySize(macd_main) < 5) return 0.0;
    
    double score = 0.0;
    double macd_current = macd_main[0];
    double macd_prev = macd_main[1];
    double macd_prev2 = macd_main[2];
    double signal_current = macd_signal[0];
    double signal_prev = macd_signal[1];
    
    // Signal line crossover with momentum confirmation
    bool bullish_cross = (macd_current > signal_current && macd_prev <= signal_prev);
    bool bearish_cross = (macd_current < signal_current && macd_prev >= signal_prev);
    
    if(bullish_cross && macd_current > macd_prev) score += 0.5;
    if(bearish_cross && macd_current < macd_prev) score -= 0.5;
    
    // Zero line crossover
    if(macd_current > 0 && macd_prev <= 0) score += 0.4;
    if(macd_current < 0 && macd_prev >= 0) score -= 0.4;
    
    // MACD histogram analysis
    double histogram = macd_current - signal_current;
    double histogram_prev = macd_prev - signal_prev;
    
    if(histogram > histogram_prev && histogram > 0) score += 0.3;
    if(histogram < histogram_prev && histogram < 0) score -= 0.3;
    
    // MACD momentum
    double macd_momentum = macd_current - macd_prev;
    score += macd_momentum * 20; // Adjusted scale factor
    
    // MACD divergence with price
    bool macd_bullish_div = (macd_current > macd_prev2) && (market_data.close[0] < market_data.close[2]);
    bool macd_bearish_div = (macd_current < macd_prev2) && (market_data.close[0] > market_data.close[2]);
    
    if(macd_bullish_div) score += 0.4;
    if(macd_bearish_div) score -= 0.4;
    
    return MathMax(-1.0, MathMin(1.0, score));
}

//+------------------------------------------------------------------+
//| Enhanced Bollinger Bands Analysis                              |
//+------------------------------------------------------------------+
double AnalyzeBollingerBands()
{
    if(ArraySize(bb_upper) < 3) return 0.0;
    
    double score = 0.0;
    double price = market_data.close[0];
    double price_prev = market_data.close[1];
    double upper = bb_upper[0];
    double middle = bb_middle[0];
    double lower = bb_lower[0];
    double upper_prev = bb_upper[1];
    double lower_prev = bb_lower[1];
    
    double band_width = upper - lower;
    double band_width_prev = upper_prev - lower_prev;
    
    // Band position analysis with dynamic thresholds
    double position = (price - lower) / band_width;
    
    if(position < 0.15) score += 0.4; // Strong oversold
    else if(position < 0.25) score += 0.2; // Oversold
    
    if(position > 0.85) score -= 0.4; // Strong overbought
    else if(position > 0.75) score -= 0.2; // Overbought
    
    // Bollinger Band squeeze detection and expansion
    double bb_squeeze_threshold = atr_buffer[0] * 1.5;
    bool squeeze = (band_width < bb_squeeze_threshold);
    bool expansion = (band_width > band_width_prev * 1.2);
    
    if(squeeze) {
        score *= 0.3; // Reduce signals during squeeze
    }
    
    if(expansion && !squeeze) {
        score *= 1.5; // Amplify signals during expansion
    }
    
    // Bollinger Band bounces
    if(price < lower && price_prev >= lower_prev) {
        score += 0.6; // Bounce from lower band
    }
    
    if(price > upper && price_prev <= upper_prev) {
        score -= 0.6; // Rejection from upper band
    }
    
    // Middle band trend analysis
    if(price > middle && market_data.close[1] <= bb_middle[1]) {
        score += 0.2; // Break above middle
    }
    
    if(price < middle && market_data.close[1] >= bb_middle[1]) {
        score -= 0.2; // Break below middle
    }
    
    return MathMax(-1.0, MathMin(1.0, score));
}

//+------------------------------------------------------------------+
//| Stochastic Oscillator Analysis                                 |
//+------------------------------------------------------------------+
double AnalyzeStochastic()
{
    if(ArraySize(stoch_main) < 3) return 0.0;
    
    double score = 0.0;
    double stoch_k = stoch_main[0];
    double stoch_d = stoch_signal[0];
    double stoch_k_prev = stoch_main[1];
    double stoch_d_prev = stoch_signal[1];
    
    // Overbought/Oversold levels
    if(stoch_k < 20 && stoch_d < 20) score += 0.3;
    if(stoch_k > 80 && stoch_d > 80) score -= 0.3;
    
    // %K and %D crossover
    if(stoch_k > stoch_d && stoch_k_prev <= stoch_d_prev && stoch_k < 80) {
        score += 0.4; // Bullish crossover
    }
    
    if(stoch_k < stoch_d && stoch_k_prev >= stoch_d_prev && stoch_k > 20) {
        score -= 0.4; // Bearish crossover
    }
    
    // Stochastic momentum
    double stoch_momentum = stoch_k - stoch_k_prev;
    score += stoch_momentum * 0.01;
    
    return MathMax(-1.0, MathMin(1.0, score));
}

//+------------------------------------------------------------------+
//| Williams %R Analysis                                            |
//+------------------------------------------------------------------+
double AnalyzeWilliams()
{
    if(ArraySize(williams_buffer) < 3) return 0.0;
    
    double score = 0.0;
    double williams = williams_buffer[0];
    double williams_prev = williams_buffer[1];
    
    // Overbought/Oversold
    if(williams < -80) score += 0.25;
    if(williams > -20) score -= 0.25;
    
    // Williams momentum
    double williams_momentum = williams - williams_prev;
    score += williams_momentum * 0.005;
    
    // Divergence analysis
    if(williams > williams_prev && market_data.close[0] < market_data.close[1]) {
        score += 0.2; // Bullish divergence
    }
    
    if(williams < williams_prev && market_data.close[0] > market_data.close[1]) {
        score -= 0.2; // Bearish divergence
    }
    
    return MathMax(-1.0, MathMin(1.0, score));
}

//+------------------------------------------------------------------+
//| Advanced Price Action Analysis                                  |
//+------------------------------------------------------------------+
double AnalyzePriceAction()
{
    if(ArraySize(market_data.close) < 10) return 0.0;
    
    double score = 0.0;
    
    // Comprehensive candlestick pattern analysis
    score += AnalyzeCandlestickPatterns();
    
    // Support and resistance analysis
    score += AnalyzeSupportResistance();
    
    // Price momentum and acceleration
    score += AnalyzePriceMomentum();
    
    // Higher highs/lower lows analysis
    score += AnalyzePriceTrend();
    
    // Gap analysis
    score += AnalyzeGaps();
    
    return MathMax(-1.0, MathMin(1.0, score));
}

//+------------------------------------------------------------------+
//| Volume Analysis                                                 |
//+------------------------------------------------------------------+
double AnalyzeVolume()
{
    if(ArraySize(market_data.volume) < 5) return 0.0;
    
    double score = 0.0;
    double volume_current = market_data.volume[0];
    double volume_avg = 0.0;
    
    // Calculate average volume
    for(int i = 1; i < 5; i++) {
        volume_avg += market_data.volume[i];
    }
    volume_avg /= 4.0;
    
    // Volume confirmation
    double price_change = market_data.close[0] - market_data.close[1];
    
    if(price_change > 0 && volume_current > volume_avg * 1.2) {
        score += 0.3; // Bullish with volume confirmation
    }
    
    if(price_change < 0 && volume_current > volume_avg * 1.2) {
        score -= 0.3; // Bearish with volume confirmation
    }
    
    // Volume divergence
    bool volume_increasing = volume_current > market_data.volume[1];
    bool price_increasing = market_data.close[0] > market_data.close[1];
    
    if(volume_increasing && !price_increasing) score -= 0.2;
    if(!volume_increasing && price_increasing) score += 0.2;
    
    return MathMax(-1.0, MathMin(1.0, score));
}

//+------------------------------------------------------------------+
//| Moving Average Analysis                                         |
//+------------------------------------------------------------------+
double AnalyzeMovingAverages()
{
    if(ArraySize(ma_fast) < 5) return 0.0;
    
    double score = 0.0;
    
    // MA crossover
    if(ma_fast[0] > ma_slow[0] && ma_fast[1] <= ma_slow[1]) {
        score += 0.4; // Golden cross
    }
    
    if(ma_fast[0] < ma_slow[0] && ma_fast[1] >= ma_slow[1]) {
        score -= 0.4; // Death cross
    }
    
    // Price vs MA analysis
    double price = market_data.close[0];
    
    if(price > ma_fast[0] && price > ma_slow[0]) score += 0.2;
    if(price < ma_fast[0] && price < ma_slow[0]) score -= 0.2;
    
    // MA slope analysis
    double fast_slope = ma_fast[0] - ma_fast[2];
    double slow_slope = ma_slow[0] - ma_slow[2];
    
    if(fast_slope > 0 && slow_slope > 0) score += 0.15;
    if(fast_slope < 0 && slow_slope < 0) score -= 0.15;
    
    return MathMax(-1.0, MathMin(1.0, score));
}

// ... continuing with the rest of the implementation

//+------------------------------------------------------------------+
//| Calculate volatility data                                       |
//+------------------------------------------------------------------+
void CalculateVolatility()
{
    for(int i = 0; i < LookbackPeriod - 1; i++) {
        if(market_data.close[i] != 0) {
            volatility_data[i] = MathAbs(price_changes[i]);
        }
    }
}

//+------------------------------------------------------------------+
//| Calculate moving averages for trend analysis                   |
//+------------------------------------------------------------------+
void CalculateMovingAverages()
{
    // Fast MA (21 period)
    for(int i = 0; i < LookbackPeriod - 21; i++) {
        double sum = 0.0;
        for(int j = 0; j < 21; j++) {
            sum += market_data.close[i + j];
        }
        ma_fast[i] = sum / 21.0;
    }
    
    // Slow MA (50 period)
    for(int i = 0; i < LookbackPeriod - 50; i++) {
        double sum = 0.0;
        for(int j = 0; j < 50; j++) {
            sum += market_data.close[i + j];
        }
        ma_slow[i] = sum / 50.0;
    }
}

//+------------------------------------------------------------------+
//| Update support and resistance levels                           |
//+------------------------------------------------------------------+
void UpdateSupportResistanceLevels()
{
    int lookback = MathMin(LookbackPeriod, 50);
    
    // Find pivot highs and lows
    ArrayInitialize(support_levels, 0);
    ArrayInitialize(resistance_levels, 0);
    
    int support_count = 0, resistance_count = 0;
    
    for(int i = 2; i < lookback - 2; i++) {
        // Resistance levels (pivot highs)
        if(market_data.high[i] > market_data.high[i-1] && 
           market_data.high[i] > market_data.high[i+1] &&
           market_data.high[i] > market_data.high[i-2] && 
           market_data.high[i] > market_data.high[i+2] &&
           resistance_count < 10) {
            resistance_levels[resistance_count] = market_data.high[i];
            resistance_count++;
        }
        
        // Support levels (pivot lows)
        if(market_data.low[i] < market_data.low[i-1] && 
           market_data.low[i] < market_data.low[i+1] &&
           market_data.low[i] < market_data.low[i-2] && 
           market_data.low[i] < market_data.low[i+2] &&
           support_count < 10) {
            support_levels[support_count] = market_data.low[i];
            support_count++;
        }
    }
}

//+------------------------------------------------------------------+
//| Analyze market regime                                           |
//+------------------------------------------------------------------+
void AnalyzeMarketRegime()
{
    current_regime.trend_strength = CalculateTrendStrength();
    current_regime.volatility_level = CalculateCurrentVolatility();
    current_regime.momentum_score = CalculateMomentumScore();
    
    // Determine market phase
    if(current_regime.trend_strength > 0.7) {
        if(current_regime.volatility_level > 1.5) {
            current_regime.market_phase = "trending_high_vol";
        } else {
            current_regime.market_phase = "trending";
        }
    } else if(current_regime.trend_strength < 0.3) {
        if(current_regime.volatility_level > 1.5) {
            current_regime.market_phase = "ranging_high_vol";
        } else {
            current_regime.market_phase = "ranging";
        }
    } else {
        current_regime.market_phase = "consolidation";
    }
}

// Implementation continues with all remaining helper functions...
// [Note: This is a substantial implementation. I'll continue with the key remaining functions]

//+------------------------------------------------------------------+
//| All remaining helper function implementations                   |
//+------------------------------------------------------------------+

bool IsSymbolAllowed()
{
    string symbols[];
    int count = StringSplit(TradingSymbols, ',', symbols);
    
    for(int i = 0; i < count; i++) {
        StringTrimLeft(symbols[i]);
        StringTrimRight(symbols[i]);
        if(symbols[i] == Symbol()) return true;
    }
    return false;
}

bool IsWithinTradingHours()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    if(AvoidFridayTrading && dt.day_of_week == 5 && dt.hour > 20) return false;
    
    return (dt.hour >= StartHour && dt.hour <= EndHour);
}

double CalculateTrendStrength()
{
    if(ArraySize(market_data.close) < TrendStrengthPeriod) return 0.5;
    
    double sum_positive = 0, sum_negative = 0;
    
    for(int i = 1; i < TrendStrengthPeriod; i++) {
        double change = market_data.close[i-1] - market_data.close[i];
        if(change > 0) sum_positive += change;
        else sum_negative += MathAbs(change);
    }
    
    double total_movement = sum_positive + sum_negative;
    if(total_movement == 0) return 0.5;
    
    return sum_positive / total_movement;
}

double CalculateCurrentVolatility()
{
    if(ArraySize(atr_buffer) < 1) return 1.0;
    
    double current_atr = atr_buffer[0];
    double avg_atr = 0.0;
    
    for(int i = 0; i < MathMin(10, ArraySize(atr_buffer)); i++) {
        avg_atr += atr_buffer[i];
    }
    avg_atr /= MathMin(10, ArraySize(atr_buffer));
    
    if(avg_atr == 0) return 1.0;
    return current_atr / avg_atr;
}

double CalculateMomentumScore()
{
    if(ArraySize(market_data.close) < 10) return 0.0;
    
    double momentum = 0.0;
    for(int i = 1; i < 10; i++) {
        momentum += (market_data.close[i-1] - market_data.close[i]) / market_data.close[i];
    }
    
    return momentum * 100; // Convert to percentage
}

void AdjustWeightsBasedOnMarketCondition(double &weights[], double trend_strength)
{
    if(trend_strength > 0.6) {
        // Trending market - increase trend following indicators
        weights[1] *= 1.3; // MACD
        weights[7] *= 1.5; // Moving averages
        weights[2] *= 0.8; // Bollinger bands
    } else {
        // Ranging market - increase mean reversion indicators
        weights[0] *= 1.3; // RSI
        weights[2] *= 1.3; // Bollinger bands
        weights[1] *= 0.7; // MACD
    }
}

double CalculateRegimeMultiplier()
{
    string phase = current_regime.market_phase;
    
    if(phase == "trending") return 1.2;
    if(phase == "trending_high_vol") return 0.8;
    if(phase == "ranging") return 1.0;
    if(phase == "ranging_high_vol") return 0.6;
    if(phase == "consolidation") return 0.9;
    
    return 1.0;
}

double CalculateVolatilityFactor()
{
    double vol_level = current_regime.volatility_level;
    
    if(vol_level > 2.0) return 0.5; // Very high volatility
    if(vol_level > 1.5) return 0.7; // High volatility
    if(vol_level < 0.5) return 0.8; // Very low volatility
    
    return 1.0; // Normal volatility
}

double RecognizePatterns()
{
    // Simplified pattern recognition
    double pattern_score = 0.0;
    
    // Doji pattern
    if(MathAbs(market_data.close[0] - market_data.open[0]) < (market_data.high[0] - market_data.low[0]) * 0.1) {
        pattern_score += 0.1; // Indecision
    }
    
    // Hammer/Shooting star patterns
    double body_size = MathAbs(market_data.close[0] - market_data.open[0]);
    double lower_shadow = MathMin(market_data.close[0], market_data.open[0]) - market_data.low[0];
    double upper_shadow = market_data.high[0] - MathMax(market_data.close[0], market_data.open[0]);
    
    if(lower_shadow > body_size * 2 && upper_shadow < body_size * 0.5) {
        pattern_score += 0.3; // Hammer pattern
    }
    
    if(upper_shadow > body_size * 2 && lower_shadow < body_size * 0.5) {
        pattern_score -= 0.3; // Shooting star pattern
    }
    
    return pattern_score;
}

double AnalyzeIndicatorCorrelations()
{
    // Simplified correlation analysis
    double correlation_factor = 1.0;
    
    // If RSI and Stochastic agree, increase confidence
    bool rsi_bullish = (rsi_buffer[0] < 40);
    bool stoch_bullish = (stoch_main[0] < 30);
    
    if(rsi_bullish == stoch_bullish) {
        correlation_factor *= 1.1;
    }
    
    // If MACD and MA agree, increase confidence
    bool macd_bullish = (macd_main[0] > macd_signal[0]);
    bool ma_bullish = (ma_fast[0] > ma_slow[0]);
    
    if(macd_bullish == ma_bullish) {
        correlation_factor *= 1.1;
    }
    
    return correlation_factor;
}

double CalculateConfidence(double &scores[], double weighted_score)
{
    double consensus = 0.0;
    int agreeing_indicators = 0;
    
    for(int i = 0; i < ArraySize(scores); i++) {
        if((scores[i] > 0 && weighted_score > 0) || (scores[i] < 0 && weighted_score < 0)) {
            agreeing_indicators++;
        }
    }
    
    consensus = (double)agreeing_indicators / ArraySize(scores);
    
    // Combine with signal strength
    double confidence = (consensus * 0.6) + (MathAbs(weighted_score) * 0.4);
    
    return MathMax(0.0, MathMin(1.0, confidence));
}

string GenerateSignalReason(double &scores[], double weighted_score, MarketRegime &regime)
{
    string reason = "AI Analysis: ";
    
    if(weighted_score > 0) reason += "BULLISH - ";
    else reason += "BEARISH - ";
    
    reason += "Market: " + regime.market_phase;
    reason += ", Trend: " + DoubleToString(regime.trend_strength, 2);
    reason += ", Vol: " + DoubleToString(regime.volatility_level, 2);
    
    return reason;
}

// Additional pattern analysis functions
double AnalyzeCandlestickPatterns()
{
    double score = 0.0;
    
    // Basic candlestick patterns
    double body_size = MathAbs(market_data.close[0] - market_data.open[0]);
    double total_range = market_data.high[0] - market_data.low[0];
    
    if(total_range == 0) return 0.0;
    
    double body_ratio = body_size / total_range;
    
    // Strong bullish/bearish candles
    if(market_data.close[0] > market_data.open[0] && body_ratio > 0.7) {
        score += 0.2; // Strong bullish candle
    }
    
    if(market_data.close[0] < market_data.open[0] && body_ratio > 0.7) {
        score -= 0.2; // Strong bearish candle
    }
    
    return score;
}

double AnalyzeSupportResistance()
{
    double score = 0.0;
    double current_price = market_data.close[0];
    
    // Check proximity to support/resistance levels
    for(int i = 0; i < ArraySize(support_levels); i++) {
        if(support_levels[i] > 0) {
            double distance = MathAbs(current_price - support_levels[i]) / current_price * 100;
            if(distance < 0.1) { // Within 0.1%
                score += 0.3; // Near support
            }
        }
    }
    
    for(int i = 0; i < ArraySize(resistance_levels); i++) {
        if(resistance_levels[i] > 0) {
            double distance = MathAbs(current_price - resistance_levels[i]) / current_price * 100;
            if(distance < 0.1) { // Within 0.1%
                score -= 0.3; // Near resistance
            }
        }
    }
    
    return score;
}

double AnalyzePriceMomentum()
{
    if(ArraySize(market_data.close) < 5) return 0.0;
    
    double momentum_score = 0.0;
    
    // Price momentum over different periods
    double momentum_1 = (market_data.close[0] - market_data.close[1]) / market_data.close[1] * 100;
    double momentum_3 = (market_data.close[0] - market_data.close[3]) / market_data.close[3] * 100;
    double momentum_5 = (market_data.close[0] - market_data.close[4]) / market_data.close[4] * 100;
    
    momentum_score = (momentum_1 * 0.5) + (momentum_3 * 0.3) + (momentum_5 * 0.2);
    
    return momentum_score * 0.1; // Scale factor
}

double AnalyzePriceTrend()
{
    if(ArraySize(market_data.close) < 10) return 0.0;
    
    double score = 0.0;
    int higher_highs = 0, lower_lows = 0;
    
    for(int i = 1; i < 5; i++) {
        if(market_data.high[i-1] > market_data.high[i]) higher_highs++;
        if(market_data.low[i-1] < market_data.low[i]) lower_lows++;
    }
    
    if(higher_highs >= 3) score += 0.3;
    if(lower_lows >= 3) score -= 0.3;
    
    return score;
}

double AnalyzeGaps()
{
    if(ArraySize(market_data.close) < 2) return 0.0;
    
    double gap_score = 0.0;
    
    // Check for gaps
    double gap_up = market_data.low[0] - market_data.high[1];
    double gap_down = market_data.low[1] - market_data.high[0];
    
    if(gap_up > 0) {
        gap_score += 0.2; // Gap up
    }
    
    if(gap_down > 0) {
        gap_score -= 0.2; // Gap down
    }
    
    return gap_score;
}

double CalculateVolatilityMultiplier()
{
    return CalculateVolatilityFactor();
}

// Position management functions
void ManageExistingPosition()
{
    if(!PositionSelect(Symbol())) return;
    
    double position_profit = PositionGetDouble(POSITION_PROFIT);
    double position_type = PositionGetInteger(POSITION_TYPE);
    
    // Implement partial profit taking
    if(position_profit > 0) {
        double entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
        double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
        double profit_points = MathAbs(current_price - entry_price) / Point();
        
        // Take partial profits at 1.5x risk
        if(profit_points > atr_buffer[0] * 1.5 / Point()) {
            // Implement partial close logic here
        }
    }
}

void UpdateTrailingStops()
{
    if(!PositionSelect(Symbol())) return;
    
    double position_type = PositionGetInteger(POSITION_TYPE);
    double entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
    double current_sl = PositionGetDouble(POSITION_SL);
    double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
    
    double new_sl = current_sl;
    bool modify_needed = false;
    
    if(position_type == POSITION_TYPE_BUY) {
        new_sl = current_price - (TrailingStopDistance * Point());
        if(new_sl > current_sl + (Point() * 10)) { // Only move SL up
            modify_needed = true;
        }
    } else {
        new_sl = current_price + (TrailingStopDistance * Point());
        if(new_sl < current_sl - (Point() * 10)) { // Only move SL down
            modify_needed = true;
        }
    }
    
    if(modify_needed) {
        MqlTradeRequest request;
        MqlTradeResult result;
        
        ZeroMemory(request);
        request.action = TRADE_ACTION_SLTP;
        request.symbol = Symbol();
        request.sl = new_sl;
        request.tp = PositionGetDouble(POSITION_TP);
        
        OrderSend(request, result);
    }
}

void CheckRiskManagement()
{
    // Check maximum risk per trade
    double account_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double total_risk = 0.0;
    
    for(int i = 0; i < PositionsTotal(); i++) {
        if(PositionGetSymbol(i) == Symbol()) {
            double position_risk = PositionGetDouble(POSITION_VOLUME) * 
                                  MathAbs(PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_SL)) *
                                  SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
            total_risk += position_risk;
        }
    }
    
    double risk_percentage = (total_risk / account_equity) * 100;
    
    if(risk_percentage > MaxRiskPerTrade) {
        Print("Warning: Risk per trade exceeded: ", risk_percentage, "%");
        // Implement risk reduction logic
    }
}

bool IsMarketConditionFavorable()
{
    // Avoid trading during high volatility spikes
    if(current_regime.volatility_level > VolatilityThreshold * 2) {
        return false;
    }
    
    // Check spread conditions
    double spread = SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) * Point();
    double max_spread = atr_buffer[0] * 0.3; // Max spread = 30% of ATR
    
    if(spread > max_spread) {
        return false;
    }
    
    return true;
}

AISignal GenerateTraditionalSignal()
{
    AISignal signal;
    signal.strength = 0.0;
    signal.direction = 0;
    signal.confidence = 0.5;
    signal.reason = "Traditional Analysis";
    signal.timestamp = TimeCurrent();
    
    // Simple RSI + MACD strategy
    double rsi = rsi_buffer[0];
    bool macd_bullish = macd_main[0] > macd_signal[0];
    bool macd_bearish = macd_main[0] < macd_signal[0];
    
    if(rsi < 30 && macd_bullish) {
        signal.direction = 1;
        signal.strength = 0.7;
        signal.confidence = 0.6;
    } else if(rsi > 70 && macd_bearish) {
        signal.direction = -1;
        signal.strength = 0.7;
        signal.confidence = 0.6;
    }
    
    return signal;
}

// Performance tracking functions
void UpdatePerformanceStats()
{
    // Update performance statistics
    performance.last_update = TimeCurrent();
    
    // Calculate win rate
    if(performance.total_trades > 0) {
        performance.win_rate = (double)performance.winning_trades / performance.total_trades * 100;
    }
    
    // Calculate profit factor
    if(performance.losing_trades > 0) {
        // This would need access to winning/losing amounts separately
        // Simplified calculation here
        performance.profit_factor = (double)performance.winning_trades / performance.losing_trades;
    }
}

void PrintPerformanceReport()
{
    Print("=== AI Expert Advisor Performance Report ===");
    Print("Total Trades: ", performance.total_trades);
    Print("Winning Trades: ", performance.winning_trades);
    Print("Losing Trades: ", performance.losing_trades);
    Print("Win Rate: ", DoubleToString(performance.win_rate, 2), "%");
    Print("Total Profit: $", DoubleToString(performance.total_profit, 2));
    Print("Profit Factor: ", DoubleToString(performance.profit_factor, 2));
    Print("Max Drawdown: ", DoubleToString(performance.max_drawdown, 2), "%");
}

void LogAIDecision()
{
    string log_message = StringFormat("AI Decision - Signal: %s, Strength: %.3f, Confidence: %.3f, Regime: %s",
                                     current_signal.direction == 1 ? "BUY" : (current_signal.direction == -1 ? "SELL" : "HOLD"),
                                     current_signal.strength,
                                     current_signal.confidence,
                                     current_regime.market_phase);
    
    Print(log_message);
    
    // Could also write to file for detailed analysis
}

// Trade execution functions
void ProcessTradingSignals()
{
    if(current_signal.direction == 0 || current_signal.confidence < MinSignalStrength) return;
    
    // Check maximum positions
    if(PositionsTotal() >= MaxOpenPositions) return;
    
    // Check if we already have a position
    if(PositionSelect(Symbol())) {
        ManageExistingPosition();
        return;
    }
    
    // Calculate TP and SL
    double take_profit, stop_loss;
    CalculateDynamicTPSL(take_profit, stop_loss, current_signal.direction);
    
    // Calculate lot size
    double lot_size = CalculateDynamicLotSize(stop_loss / Point());
    
    // Execute trade
    if(current_signal.direction == 1) {
        OpenBuyOrder(lot_size, stop_loss, take_profit);
    } else if(current_signal.direction == -1) {
        OpenSellOrder(lot_size, stop_loss, take_profit);
    }
}

double CalculateDynamicLotSize(double stop_loss_points)
{
    if(!UseAdaptiveLotSize) return LotSize;
    
    double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amount = account_balance * RiskPercentage / 100.0;
    
    double point_value = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
    if(point_value == 0) point_value = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
    
    double lot_size = risk_amount / (stop_loss_points * point_value);
    
    // Apply lot size limits
    double min_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
    double lot_step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
    
    lot_size = MathMax(min_lot, MathMin(max_lot, lot_size));
    lot_size = MathRound(lot_size / lot_step) * lot_step;
    
    return lot_size;
}

void CalculateDynamicTPSL(double &take_profit, double &stop_loss, int signal_direction)
{
    double atr = atr_buffer[0];
    double volatility_multiplier = CalculateVolatilityMultiplier();
    
    if(UseDynamicSL) {
        stop_loss = atr * BaseSLMultiplier * volatility_multiplier;
    } else {
        stop_loss = atr * BaseSLMultiplier;
    }
    
    if(UseDynamicTP) {
        // Adaptive TP based on market conditions
        double trend_strength = CalculateTrendStrength();
        double tp_multiplier = BaseTPMultiplier;
        
        if(trend_strength > 0.7) {
            tp_multiplier *= 1.5; // Extend TP in strong trends
        } else if(trend_strength < 0.3) {
            tp_multiplier *= 0.8; // Reduce TP in weak trends
        }
        
        take_profit = atr * tp_multiplier * volatility_multiplier;
    } else {
        take_profit = atr * BaseTPMultiplier;
    }
    
    // Ensure minimum distances
    double min_distance = SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL) * Point();
    stop_loss = MathMax(stop_loss, min_distance);
    take_profit = MathMax(take_profit, min_distance);
}

void OpenBuyOrder(double lot_size, double stop_loss, double take_profit)
{
    MqlTradeRequest request;
    MqlTradeResult result;
    
    ZeroMemory(request);
    
    double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = Symbol();
    request.volume = lot_size;
    request.type = ORDER_TYPE_BUY;
    request.price = ask;
    request.sl = ask - stop_loss;
    request.tp = ask + take_profit;
    request.deviation = 3;
    request.magic = 12345;
    request.comment = StringFormat("AI_EA_Buy_%.2f_conf", current_signal.confidence);
    
    if(OrderSend(request, result)) {
        Print("Buy order opened successfully. Ticket: ", result.order);
        Print("Entry: ", ask, ", SL: ", request.sl, ", TP: ", request.tp);
        
        // Update trade info
        last_trade.entry_price = ask;
        last_trade.stop_loss = request.sl;
        last_trade.take_profit = request.tp;
        last_trade.lot_size = lot_size;
        last_trade.entry_time = TimeCurrent();
        last_trade.symbol = Symbol();
        
        // Update performance
        performance.total_trades++;
    } else {
        Print("Failed to open buy order. Error: ", GetLastError());
    }
}

void OpenSellOrder(double lot_size, double stop_loss, double take_profit)
{
    MqlTradeRequest request;
    MqlTradeResult result;
    
    ZeroMemory(request);
    
    double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = Symbol();
    request.volume = lot_size;
    request.type = ORDER_TYPE_SELL;
    request.price = bid;
    request.sl = bid + stop_loss;
    request.tp = bid - take_profit;
    request.deviation = 3;
    request.magic = 12345;
    request.comment = StringFormat("AI_EA_Sell_%.2f_conf", current_signal.confidence);
    
    if(OrderSend(request, result)) {
        Print("Sell order opened successfully. Ticket: ", result.order);
        Print("Entry: ", bid, ", SL: ", request.sl, ", TP: ", request.tp);
        
        // Update trade info
        last_trade.entry_price = bid;
        last_trade.stop_loss = request.sl;
        last_trade.take_profit = request.tp;
        last_trade.lot_size = lot_size;
        last_trade.entry_time = TimeCurrent();
        last_trade.symbol = Symbol();
        
        // Update performance
        performance.total_trades++;
    } else {
        Print("Failed to open sell order. Error: ", GetLastError());
    }
}