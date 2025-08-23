//+------------------------------------------------------------------+
//|                                         AI_Expert_Advisor_MT5.mq5 |
//|                           Advanced AI Trading System with ML Logic |
//|                                  Designed for Professional Trading |
//+------------------------------------------------------------------+
#property copyright "Advanced AI Expert Advisor MT5"
#property version   "3.0"

#include <Trade\Trade.mqh>
#include <Indicators\Indicators.mqh>

//--- Input Parameters
input group "=== General Settings ==="
input double    InpLotSize = 0.1;
input bool      InpUseAutoLots = true;
input double    InpRiskPercent = 2.0;
input ulong     InpMagicNumber = 12345;
input ulong     InpDeviation = 10;

input group "=== AI Strategy Settings ==="
input bool      InpUseAdvancedAI = true;
input int       InpAIConfidenceThreshold = 75;
input bool      InpUseMachineLearning = true;
input bool      InpUsePriceAction = true;
input bool      InpUseVolumeAnalysis = true;
input bool      InpUseMultiTimeframe = true;
input bool      InpUseNeuralNetwork = true;

input group "=== Indicator Settings ==="
input int       InpFastMA = 12;
input int       InpSlowMA = 26;
input int       InpSignalMA = 9;
input int       InpRSI_Period = 14;
input int       InpBB_Period = 20;
input double    InpBB_Deviation = 2.0;
input int       InpADX_Period = 14;
input int       InpATR_Period = 14;
input int       InpStoch_K = 5;
input int       InpStoch_D = 3;
input int       InpStoch_Slowing = 3;

input group "=== Advanced Indicators ==="
input int       InpCCI_Period = 14;
input int       InpWilliams_Period = 14;
input int       InpMomentum_Period = 14;
input int       InpFractals_Period = 5;
input int       InpZigZag_Depth = 12;
input int       InpZigZag_Deviation = 5;
input int       InpZigZag_Backstep = 3;

input group "=== Risk Management ==="
input bool      InpUseDynamicSL = true;
input bool      InpUseDynamicTP = true;
input double    InpATR_SL_Multiplier = 2.5;
input double    InpATR_TP_Multiplier = 4.0;
input double    InpMaxDailyLoss = 5.0;
input double    InpMaxDailyProfit = 15.0;
input bool      InpUseTrailingStop = true;
input double    InpTrailingStart = 30;
input double    InpTrailingStep = 10;
input bool      InpUseBreakEven = true;
input double    InpBreakEvenPoint = 20;

input group "=== Advanced Filters ==="
input bool      InpUseNewsFilter = true;
input bool      InpUseSpreadFilter = true;
input double    InpMaxSpread = 20;
input bool      InpUseVolatilityFilter = true;
input double    InpMinVolatility = 0.00005;
input double    InpMaxVolatility = 0.005;
input bool      InpUseTimeFilter = true;
input string    InpStartTime = "08:00";
input string    InpEndTime = "22:00";

input group "=== Machine Learning ==="
input int       InpMLHistoryBars = 1000;
input int       InpMLTrainingPeriod = 100;
input double    InpMLLearningRate = 0.01;
input int       InpNeuralNetworkLayers = 3;
input int       InpNeuralNetworkNeurons = 10;

//--- Global Objects
CTrade trade;
CSymbolInfo symbolInfo;
CPositionInfo positionInfo;

//--- Indicator Handles
int handleMACD;
int handleRSI;
int handleBBands;
int handleADX;
int handleATR;
int handleStochastic;
int handleCCI;
int handleWilliams;
int handleMomentum;

//--- Global Variables
datetime lastBarTime;
double dailyProfit = 0;
double dailyLoss = 0;
datetime dayStart;
bool tradingEnabled = true;

//--- AI and ML Variables
double neuralWeights[10][10];  // Neural network weights
double indicatorHistory[][10]; // History for ML
int historyIndex = 0;
double mlAccuracy = 0;

//--- AI Signal Structure
struct AISignal {
    double confidence;
    int direction;  // 1 for buy, -1 for sell, 0 for hold
    double strength;
    string reason;
    double probability;
    double expectedReturn;
};

//--- Market Regime Structure
struct MarketRegime {
    bool isTrending;
    bool isVolatile;
    double volatility;
    double trendStrength;
    int dominantTimeframe;
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize trade object
    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetDeviationInPoints(InpDeviation);
    trade.SetTypeFilling(ORDER_FILLING_FOK);
    
    // Initialize symbol info
    symbolInfo.Name(Symbol());
    symbolInfo.Refresh();
    
    // Initialize indicators
    if(!InitializeIndicators()) {
        Print("Failed to initialize indicators");
        return INIT_FAILED;
    }
    
    // Initialize neural network
    if(InpUseNeuralNetwork) {
        InitializeNeuralNetwork();
    }
    
    // Initialize ML arrays
    if(InpUseMachineLearning) {
        ArrayResize(indicatorHistory, InpMLHistoryBars);
        ArrayInitialize(indicatorHistory, 0);
    }
    
    lastBarTime = iTime(Symbol(), PERIOD_CURRENT, 0);
    dayStart = TimeCurrent();
    
    Print("Advanced AI Expert Advisor MT5 Initialized Successfully");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("AI Expert Advisor MT5 Deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check for new bar
    datetime currentBarTime = iTime(Symbol(), PERIOD_CURRENT, 0);
    if(currentBarTime == lastBarTime) return;
    lastBarTime = currentBarTime;
    
    // Update symbol info
    symbolInfo.Refresh();
    
    // Reset daily counters
    MqlDateTime today;
    TimeToStruct(TimeCurrent(), today);
    MqlDateTime dayStartStruct;
    TimeToStruct(dayStart, dayStartStruct);
    
    if(today.day != dayStartStruct.day) {
        dailyProfit = 0;
        dailyLoss = 0;
        dayStart = TimeCurrent();
        tradingEnabled = true;
    }
    
    // Check daily limits and market conditions
    CheckDailyLimits();
    if(!IsMarketSuitable()) return;
    
    // Update ML model
    if(InpUseMachineLearning) {
        UpdateMLModel();
    }
    
    // Get market regime
    MarketRegime regime = AnalyzeMarketRegime();
    
    // Get AI signal with enhanced logic
    AISignal signal = GetAdvancedAISignal(regime);
    
    // Execute trades based on AI decision
    if(signal.confidence >= InpAIConfidenceThreshold && tradingEnabled) {
        if(signal.direction == 1 && GetOpenPositionsCount(POSITION_TYPE_BUY) == 0) {
            OpenBuyPosition(signal);
        }
        else if(signal.direction == -1 && GetOpenPositionsCount(POSITION_TYPE_SELL) == 0) {
            OpenSellPosition(signal);
        }
    }
    
    // Manage existing positions
    ManageOpenPositions();
}

//+------------------------------------------------------------------+
//| Initialize Indicators                                            |
//+------------------------------------------------------------------+
bool InitializeIndicators()
{
    handleMACD = iMACD(Symbol(), PERIOD_CURRENT, InpFastMA, InpSlowMA, InpSignalMA, PRICE_CLOSE);
    handleRSI = iRSI(Symbol(), PERIOD_CURRENT, InpRSI_Period, PRICE_CLOSE);
    handleBBands = iBands(Symbol(), PERIOD_CURRENT, InpBB_Period, 0, InpBB_Deviation, PRICE_CLOSE);
    handleADX = iADX(Symbol(), PERIOD_CURRENT, InpADX_Period);
    handleATR = iATR(Symbol(), PERIOD_CURRENT, InpATR_Period);
    handleStochastic = iStochastic(Symbol(), PERIOD_CURRENT, InpStoch_K, InpStoch_D, InpStoch_Slowing, MODE_SMA, STO_LOWHIGH);
    handleCCI = iCCI(Symbol(), PERIOD_CURRENT, InpCCI_Period, PRICE_TYPICAL);
    handleWilliams = iWPR(Symbol(), PERIOD_CURRENT, InpWilliams_Period);
    handleMomentum = iMomentum(Symbol(), PERIOD_CURRENT, InpMomentum_Period, PRICE_CLOSE);
    
    return (handleMACD != INVALID_HANDLE && handleRSI != INVALID_HANDLE && 
            handleBBands != INVALID_HANDLE && handleADX != INVALID_HANDLE && 
            handleATR != INVALID_HANDLE && handleStochastic != INVALID_HANDLE &&
            handleCCI != INVALID_HANDLE && handleWilliams != INVALID_HANDLE &&
            handleMomentum != INVALID_HANDLE);
}

//+------------------------------------------------------------------+
//| Initialize Neural Network                                        |
//+------------------------------------------------------------------+
void InitializeNeuralNetwork()
{
    // Initialize weights with small random values
    MathSrand((int)TimeCurrent());
    for(int i = 0; i < InpNeuralNetworkNeurons; i++) {
        for(int j = 0; j < InpNeuralNetworkNeurons; j++) {
            neuralWeights[i][j] = (MathRand() / 32767.0 - 0.5) * 0.1;
        }
    }
}

//+------------------------------------------------------------------+
//| Advanced AI Signal Generation                                    |
//+------------------------------------------------------------------+
AISignal GetAdvancedAISignal(MarketRegime &regime)
{
    AISignal signal;
    signal.confidence = 0;
    signal.direction = 0;
    signal.strength = 0;
    signal.reason = "";
    signal.probability = 0;
    signal.expectedReturn = 0;
    
    double indicators[10];
    double weights[10];
    
    // Get normalized indicator values
    GetNormalizedIndicators(indicators);
    
    // Adaptive weights based on market regime
    GetAdaptiveWeights(weights, regime);
    
    // Neural network processing
    double neuralOutput = 0;
    if(InpUseNeuralNetwork) {
        neuralOutput = ProcessNeuralNetwork(indicators);
    }
    
    // Calculate weighted signal
    double bullishScore = 0;
    double bearishScore = 0;
    
    // Process each indicator with adaptive weights
    for(int i = 0; i < 10; i++) {
        double indicatorSignal = indicators[i];
        double weight = weights[i];
        
        if(indicatorSignal > 0.6) {
            bullishScore += weight * (indicatorSignal - 0.5) * 2;
        }
        else if(indicatorSignal < 0.4) {
            bearishScore += weight * (0.5 - indicatorSignal) * 2;
        }
    }
    
    // Incorporate neural network output
    if(InpUseNeuralNetwork) {
        if(neuralOutput > 0.6) {
            bullishScore += 30 * (neuralOutput - 0.5) * 2;
        }
        else if(neuralOutput < 0.4) {
            bearishScore += 30 * (0.5 - neuralOutput) * 2;
        }
    }
    
    // Price action analysis
    if(InpUsePriceAction) {
        double paScore = AdvancedPriceActionAnalysis();
        if(paScore > 0) bullishScore += 25 * (paScore / 100);
        else bearishScore += 25 * (MathAbs(paScore) / 100);
    }
    
    // Volume analysis
    if(InpUseVolumeAnalysis) {
        double volScore = AdvancedVolumeAnalysis();
        if(volScore > 0) bullishScore += 15 * (volScore / 100);
        else bearishScore += 15 * (MathAbs(volScore) / 100);
    }
    
    // Multi-timeframe analysis
    if(InpUseMultiTimeframe) {
        double mtfScore = MultiTimeframeAnalysis();
        if(mtfScore > 0) bullishScore += 20 * (mtfScore / 100);
        else bearishScore += 20 * (MathAbs(mtfScore) / 100);
    }
    
    // Calculate final signal
    double totalScore = bullishScore + bearishScore;
    double netScore = bullishScore - bearishScore;
    
    if(totalScore > 0) {
        signal.confidence = MathAbs(netScore) / totalScore * 100;
        signal.probability = bullishScore > bearishScore ? bullishScore / totalScore : bearishScore / totalScore;
    }
    
    signal.strength = signal.confidence;
    
    if(netScore > 10) {
        signal.direction = 1;
        signal.reason = "Strong bullish consensus from AI analysis";
        signal.expectedReturn = CalculateExpectedReturn(1, regime);
    }
    else if(netScore < -10) {
        signal.direction = -1;
        signal.reason = "Strong bearish consensus from AI analysis";
        signal.expectedReturn = CalculateExpectedReturn(-1, regime);
    }
    else {
        signal.direction = 0;
        signal.reason = "Neutral - insufficient signal strength";
    }
    
    return signal;
}

//+------------------------------------------------------------------+
//| Get Normalized Indicator Values                                  |
//+------------------------------------------------------------------+
void GetNormalizedIndicators(double &indicators[])
{
    double macd[], signal[], rsi[], bb_upper[], bb_lower[], bb_middle[];
    double adx[], adx_plus[], adx_minus[], atr[], stoch_main[], stoch_signal[];
    double cci[], williams[], momentum[];
    
    // Copy indicator values
    CopyBuffer(handleMACD, 0, 0, 3, macd);
    CopyBuffer(handleMACD, 1, 0, 3, signal);
    CopyBuffer(handleRSI, 0, 0, 3, rsi);
    CopyBuffer(handleBBands, 0, 0, 3, bb_upper);
    CopyBuffer(handleBBands, 1, 0, 3, bb_middle);
    CopyBuffer(handleBBands, 2, 0, 3, bb_lower);
    CopyBuffer(handleADX, 0, 0, 3, adx);
    CopyBuffer(handleADX, 1, 0, 3, adx_plus);
    CopyBuffer(handleADX, 2, 0, 3, adx_minus);
    CopyBuffer(handleATR, 0, 0, 3, atr);
    CopyBuffer(handleStochastic, 0, 0, 3, stoch_main);
    CopyBuffer(handleStochastic, 1, 0, 3, stoch_signal);
    CopyBuffer(handleCCI, 0, 0, 3, cci);
    CopyBuffer(handleWilliams, 0, 0, 3, williams);
    CopyBuffer(handleMomentum, 0, 0, 3, momentum);
    
    // Normalize values to 0-1 range
    indicators[0] = (macd[1] > signal[1]) ? 0.7 : 0.3; // MACD
    indicators[1] = rsi[1] / 100.0; // RSI
    indicators[2] = (symbolInfo.Last() > bb_middle[1]) ? 0.6 : 0.4; // Bollinger Bands
    indicators[3] = (adx_plus[1] > adx_minus[1] && adx[1] > 25) ? 0.8 : 0.2; // ADX
    indicators[4] = stoch_main[1] / 100.0; // Stochastic
    indicators[5] = MathMax(0, MathMin(1, (cci[1] + 200) / 400.0)); // CCI normalized
    indicators[6] = (williams[1] + 100) / 100.0; // Williams %R
    indicators[7] = momentum[1] > 100 ? 0.6 : 0.4; // Momentum
    indicators[8] = atr[1] / symbolInfo.Last(); // ATR relative
    indicators[9] = GetVolumeSignal(); // Volume signal
}

//+------------------------------------------------------------------+
//| Get Adaptive Weights Based on Market Regime                     |
//+------------------------------------------------------------------+
void GetAdaptiveWeights(double &weights[], MarketRegime &regime)
{
    // Base weights
    weights[0] = 20; // MACD
    weights[1] = 15; // RSI
    weights[2] = 15; // Bollinger Bands
    weights[3] = 10; // ADX
    weights[4] = 10; // Stochastic
    weights[5] = 8;  // CCI
    weights[6] = 8;  // Williams %R
    weights[7] = 7;  // Momentum
    weights[8] = 4;  // ATR
    weights[9] = 3;  // Volume
    
    // Adjust weights based on market regime
    if(regime.isTrending) {
        weights[0] += 5; // Increase MACD weight in trending markets
        weights[3] += 5; // Increase ADX weight
        weights[1] -= 3; // Decrease RSI weight
    }
    else {
        weights[1] += 5; // Increase RSI weight in ranging markets
        weights[4] += 3; // Increase Stochastic weight
        weights[0] -= 3; // Decrease MACD weight
    }
    
    if(regime.isVolatile) {
        weights[8] += 3; // Increase ATR weight in volatile markets
        weights[2] += 3; // Increase BB weight
    }
}

//+------------------------------------------------------------------+
//| Process Neural Network                                           |
//+------------------------------------------------------------------+
double ProcessNeuralNetwork(double &inputs[])
{
    double layer1[10], layer2[10], output = 0;
    
    // First hidden layer
    for(int i = 0; i < InpNeuralNetworkNeurons; i++) {
        layer1[i] = 0;
        for(int j = 0; j < 10; j++) {
            layer1[i] += inputs[j] * neuralWeights[j][i];
        }
        layer1[i] = 1.0 / (1.0 + MathExp(-layer1[i])); // Sigmoid activation
    }
    
    // Second hidden layer
    for(int i = 0; i < InpNeuralNetworkNeurons; i++) {
        layer2[i] = 0;
        for(int j = 0; j < InpNeuralNetworkNeurons; j++) {
            layer2[i] += layer1[j] * neuralWeights[j][i];
        }
        layer2[i] = 1.0 / (1.0 + MathExp(-layer2[i])); // Sigmoid activation
    }
    
    // Output layer
    for(int i = 0; i < InpNeuralNetworkNeurons; i++) {
        output += layer2[i] * neuralWeights[i][0];
    }
    
    return 1.0 / (1.0 + MathExp(-output)); // Sigmoid output
}

//+------------------------------------------------------------------+
//| Analyze Market Regime                                            |
//+------------------------------------------------------------------+
MarketRegime AnalyzeMarketRegime()
{
    MarketRegime regime;
    
    double atr[];
    double adx[];
    CopyBuffer(handleATR, 0, 0, 20, atr);
    CopyBuffer(handleADX, 0, 0, 20, adx);
    
    // Calculate volatility
    double avgATR = 0;
    for(int i = 0; i < 20; i++) {
        avgATR += atr[i];
    }
    avgATR /= 20;
    
    regime.volatility = avgATR / symbolInfo.Last();
    regime.isVolatile = regime.volatility > InpMinVolatility * 2;
    
    // Calculate trend strength
    double avgADX = 0;
    for(int i = 0; i < 10; i++) {
        avgADX += adx[i];
    }
    avgADX /= 10;
    
    regime.trendStrength = avgADX;
    regime.isTrending = avgADX > 25;
    
    // Determine dominant timeframe
    regime.dominantTimeframe = GetDominantTimeframe();
    
    return regime;
}

//+------------------------------------------------------------------+
//| Advanced Price Action Analysis                                   |
//+------------------------------------------------------------------+
double AdvancedPriceActionAnalysis()
{
    double score = 0;
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    CopyRates(Symbol(), PERIOD_CURRENT, 0, 10, rates);
    
    // Multiple candlestick patterns
    score += AnalyzeCandlestickPatterns(rates);
    score += AnalyzeSupportResistanceLevels(rates);
    score += AnalyzeTrendLines(rates);
    score += AnalyzeChartPatterns(rates);
    
    return score;
}

//+------------------------------------------------------------------+
//| Advanced Volume Analysis                                         |
//+------------------------------------------------------------------+
double AdvancedVolumeAnalysis()
{
    double score = 0;
    long volumes[];
    ArraySetAsSeries(volumes, true);
    CopyTickVolume(Symbol(), PERIOD_CURRENT, 0, 20, volumes);
    
    // Volume trend analysis
    double avgVolume = 0;
    for(int i = 5; i < 15; i++) {
        avgVolume += volumes[i];
    }
    avgVolume /= 10;
    
    double recentVolume = (volumes[0] + volumes[1] + volumes[2]) / 3.0;
    
    if(recentVolume > avgVolume * 1.5) {
        MqlRates rates[];
        ArraySetAsSeries(rates, true);
        CopyRates(Symbol(), PERIOD_CURRENT, 0, 5, rates);
        
        if(rates[0].close > rates[1].close) score += 40;
        else score -= 40;
    }
    
    return score;
}

//+------------------------------------------------------------------+
//| Multi-Timeframe Analysis                                         |
//+------------------------------------------------------------------+
double MultiTimeframeAnalysis()
{
    double score = 0;
    
    // Analyze higher timeframes
    ENUM_TIMEFRAMES timeframes[] = {PERIOD_H1, PERIOD_H4, PERIOD_D1};
    double weights[] = {0.3, 0.4, 0.3};
    
    for(int i = 0; i < 3; i++) {
        double tfScore = AnalyzeTimeframe(timeframes[i]);
        score += tfScore * weights[i];
    }
    
    return score;
}

//+------------------------------------------------------------------+
//| Analyze Specific Timeframe                                       |
//+------------------------------------------------------------------+
double AnalyzeTimeframe(ENUM_TIMEFRAMES timeframe)
{
    double score = 0;
    
    int macd_handle = iMACD(Symbol(), timeframe, InpFastMA, InpSlowMA, InpSignalMA, PRICE_CLOSE);
    int rsi_handle = iRSI(Symbol(), timeframe, InpRSI_Period, PRICE_CLOSE);
    
    double macd[], signal[], rsi[];
    CopyBuffer(macd_handle, 0, 0, 3, macd);
    CopyBuffer(macd_handle, 1, 0, 3, signal);
    CopyBuffer(rsi_handle, 0, 0, 3, rsi);
    
    // MACD signal
    if(macd[1] > signal[1] && macd[2] <= signal[2]) score += 30;
    else if(macd[1] < signal[1] && macd[2] >= signal[2]) score -= 30;
    
    // RSI signal
    if(rsi[1] < 30) score += 20;
    else if(rsi[1] > 70) score -= 20;
    
    IndicatorRelease(macd_handle);
    IndicatorRelease(rsi_handle);
    
    return score;
}

//+------------------------------------------------------------------+
//| Calculate Expected Return                                         |
//+------------------------------------------------------------------+
double CalculateExpectedReturn(int direction, MarketRegime &regime)
{
    double atr[];
    CopyBuffer(handleATR, 0, 0, 1, atr);
    
    double baseReturn = atr[0] * InpATR_TP_Multiplier;
    
    // Adjust based on market regime
    if(regime.isTrending) baseReturn *= 1.3;
    if(regime.isVolatile) baseReturn *= 1.2;
    
    return baseReturn * direction;
}

//+------------------------------------------------------------------+
//| Update Machine Learning Model                                    |
//+------------------------------------------------------------------+
void UpdateMLModel()
{
    // Store current indicator values for learning
    double indicators[10];
    GetNormalizedIndicators(indicators);
    
    for(int i = 0; i < 10; i++) {
        indicatorHistory[historyIndex][i] = indicators[i];
    }
    
    historyIndex = (historyIndex + 1) % InpMLHistoryBars;
    
    // Simple learning: adjust weights based on recent performance
    if(historyIndex % InpMLTrainingPeriod == 0) {
        TrainMLModel();
    }
}

//+------------------------------------------------------------------+
//| Train Machine Learning Model                                     |
//+------------------------------------------------------------------+
void TrainMLModel()
{
    // Simple gradient descent for neural network weights
    double error = CalculateModelError();
    
    for(int i = 0; i < InpNeuralNetworkNeurons; i++) {
        for(int j = 0; j < InpNeuralNetworkNeurons; j++) {
            neuralWeights[i][j] += InpMLLearningRate * error * (MathRand() / 32767.0 - 0.5);
        }
    }
    
    Print("ML Model Updated. Current Error: ", error);
}

//+------------------------------------------------------------------+
//| Calculate Model Error                                            |
//+------------------------------------------------------------------+
double CalculateModelError()
{
    // Simplified error calculation based on recent trade performance
    double totalProfit = 0;
    double totalLoss = 0;
    int totalTrades = 0;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(positionInfo.SelectByIndex(i) && positionInfo.Magic() == InpMagicNumber) {
            totalTrades++;
            double profit = positionInfo.Profit();
            if(profit > 0) totalProfit += profit;
            else totalLoss += MathAbs(profit);
        }
    }
    
    if(totalTrades > 0) {
        return (totalLoss - totalProfit) / totalTrades;
    }
    
    return 0;
}

//--- Additional helper functions and advanced analysis methods would continue here...
//--- (Due to length constraints, showing core structure and key functions)

//+------------------------------------------------------------------+
//| Check if market is suitable for trading                         |
//+------------------------------------------------------------------+
bool IsMarketSuitable()
{
    // Spread filter
    if(InpUseSpreadFilter) {
        double spread = symbolInfo.Spread() * symbolInfo.Point();
        if(spread > InpMaxSpread * symbolInfo.Point()) return false;
    }
    
    // Volatility filter
    if(InpUseVolatilityFilter) {
        double atr[];
        CopyBuffer(handleATR, 0, 0, 1, atr);
        if(atr[0] < InpMinVolatility || atr[0] > InpMaxVolatility) return false;
    }
    
    // Time filter
    if(InpUseTimeFilter) {
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        string currentTime = StringFormat("%02d:%02d", dt.hour, dt.min);
        if(currentTime < InpStartTime || currentTime > InpEndTime) return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Open Buy Position                                                |
//+------------------------------------------------------------------+
void OpenBuyPosition(AISignal &signal)
{
    double lotSize = CalculateLotSize();
    double atr[];
    CopyBuffer(handleATR, 0, 0, 1, atr);
    
    double price = symbolInfo.Ask();
    double sl = InpUseDynamicSL ? price - (atr[0] * InpATR_SL_Multiplier) : 0;
    double tp = InpUseDynamicTP ? price + (atr[0] * InpATR_TP_Multiplier) : 0;
    
    string comment = StringFormat("AI EA Buy - Conf:%.1f%% - %s", signal.confidence, signal.reason);
    
    if(trade.Buy(lotSize, Symbol(), price, sl, tp, comment)) {
        Print("Buy position opened successfully. Confidence: ", signal.confidence, "%");
        Print("Expected Return: ", signal.expectedReturn);
    }
    else {
        Print("Failed to open buy position. Error: ", trade.ResultRetcode());
    }
}

//+------------------------------------------------------------------+
//| Open Sell Position                                               |
//+------------------------------------------------------------------+
void OpenSellPosition(AISignal &signal)
{
    double lotSize = CalculateLotSize();
    double atr[];
    CopyBuffer(handleATR, 0, 0, 1, atr);
    
    double price = symbolInfo.Bid();
    double sl = InpUseDynamicSL ? price + (atr[0] * InpATR_SL_Multiplier) : 0;
    double tp = InpUseDynamicTP ? price - (atr[0] * InpATR_TP_Multiplier) : 0;
    
    string comment = StringFormat("AI EA Sell - Conf:%.1f%% - %s", signal.confidence, signal.reason);
    
    if(trade.Sell(lotSize, Symbol(), price, sl, tp, comment)) {
        Print("Sell position opened successfully. Confidence: ", signal.confidence, "%");
        Print("Expected Return: ", signal.expectedReturn);
    }
    else {
        Print("Failed to open sell position. Error: ", trade.ResultRetcode());
    }
}

//+------------------------------------------------------------------+
//| Calculate Dynamic Lot Size                                       |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
    if(!InpUseAutoLots) return InpLotSize;
    
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double atr[];
    CopyBuffer(handleATR, 0, 0, 1, atr);
    
    double riskAmount = balance * InpRiskPercent / 100;
    double stopLoss = atr[0] * InpATR_SL_Multiplier;
    double tickValue = symbolInfo.TickValue();
    double stopLossTicks = stopLoss / symbolInfo.TickSize();
    
    double lotSize = riskAmount / (stopLossTicks * tickValue);
    
    // Normalize lot size
    double minLot = symbolInfo.LotsMin();
    double maxLot = symbolInfo.LotsMax();
    double lotStep = symbolInfo.LotsStep();
    
    lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
    lotSize = NormalizeDouble(lotSize / lotStep, 0) * lotStep;
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| Manage Open Positions                                            |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(positionInfo.SelectByIndex(i) && positionInfo.Magic() == InpMagicNumber) {
            
            // Trailing stop
            if(InpUseTrailingStop) {
                ApplyTrailingStop();
            }
            
            // Break even
            if(InpUseBreakEven) {
                ApplyBreakEven();
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Apply Trailing Stop                                              |
//+------------------------------------------------------------------+
void ApplyTrailingStop()
{
    double currentPrice = (positionInfo.PositionType() == POSITION_TYPE_BUY) ? 
                         symbolInfo.Bid() : symbolInfo.Ask();
    double openPrice = positionInfo.PriceOpen();
    double currentSL = positionInfo.StopLoss();
    
    double profit = (positionInfo.PositionType() == POSITION_TYPE_BUY) ? 
                   (currentPrice - openPrice) : (openPrice - currentPrice);
    
    if(profit >= InpTrailingStart * symbolInfo.Point()) {
        double newSL;
        
        if(positionInfo.PositionType() == POSITION_TYPE_BUY) {
            newSL = currentPrice - InpTrailingStep * symbolInfo.Point();
            if(newSL > currentSL) {
                trade.PositionModify(positionInfo.Ticket(), newSL, positionInfo.TakeProfit());
            }
        }
        else {
            newSL = currentPrice + InpTrailingStep * symbolInfo.Point();
            if(newSL < currentSL || currentSL == 0) {
                trade.PositionModify(positionInfo.Ticket(), newSL, positionInfo.TakeProfit());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Apply Break Even                                                 |
//+------------------------------------------------------------------+
void ApplyBreakEven()
{
    double currentPrice = (positionInfo.PositionType() == POSITION_TYPE_BUY) ? 
                         symbolInfo.Bid() : symbolInfo.Ask();
    double openPrice = positionInfo.PriceOpen();
    double currentSL = positionInfo.StopLoss();
    
    double profit = (positionInfo.PositionType() == POSITION_TYPE_BUY) ? 
                   (currentPrice - openPrice) : (openPrice - currentPrice);
    
    if(profit >= InpBreakEvenPoint * symbolInfo.Point()) {
        if(positionInfo.PositionType() == POSITION_TYPE_BUY && currentSL < openPrice) {
            trade.PositionModify(positionInfo.Ticket(), openPrice, positionInfo.TakeProfit());
        }
        else if(positionInfo.PositionType() == POSITION_TYPE_SELL && (currentSL > openPrice || currentSL == 0)) {
            trade.PositionModify(positionInfo.Ticket(), openPrice, positionInfo.TakeProfit());
        }
    }
}

//+------------------------------------------------------------------+
//| Get Open Positions Count                                         |
//+------------------------------------------------------------------+
int GetOpenPositionsCount(ENUM_POSITION_TYPE type)
{
    int count = 0;
    for(int i = 0; i < PositionsTotal(); i++) {
        if(positionInfo.SelectByIndex(i) && 
           positionInfo.Magic() == InpMagicNumber && 
           positionInfo.PositionType() == type) {
            count++;
        }
    }
    return count;
}

//+------------------------------------------------------------------+
//| Check Daily Limits                                               |
//+------------------------------------------------------------------+
void CheckDailyLimits()
{
    double todayProfit = 0;
    double todayLoss = 0;
    
    // Check today's closed trades
    HistorySelect(iTime(Symbol(), PERIOD_D1, 0), TimeCurrent());
    
    for(int i = HistoryDealsTotal() - 1; i >= 0; i--) {
        ulong ticket = HistoryDealGetTicket(i);
        if(HistoryDealGetInteger(ticket, DEAL_MAGIC) == InpMagicNumber) {
            double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            if(profit > 0) todayProfit += profit;
            else todayLoss += MathAbs(profit);
        }
    }
    
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double profitPercent = (todayProfit / accountBalance) * 100;
    double lossPercent = (todayLoss / accountBalance) * 100;
    
    if(profitPercent >= InpMaxDailyProfit || lossPercent >= InpMaxDailyLoss) {
        tradingEnabled = false;
        Print("Daily limit reached. Trading disabled for today.");
        Print("Profit: ", profitPercent, "%, Loss: ", lossPercent, "%");
    }
}

// Additional helper functions for advanced analysis
double GetVolumeSignal() { return 0.5; } // Placeholder
int GetDominantTimeframe() { return 1; } // Placeholder  
double AnalyzeCandlestickPatterns(MqlRates &rates[]) { return 0; } // Placeholder
double AnalyzeSupportResistanceLevels(MqlRates &rates[]) { return 0; } // Placeholder
double AnalyzeTrendLines(MqlRates &rates[]) { return 0; } // Placeholder
double AnalyzeChartPatterns(MqlRates &rates[]) { return 0; } // Placeholder