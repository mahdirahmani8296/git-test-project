//+------------------------------------------------------------------+
//|                                          AI_Expert_Advisor.mq4 |
//|                                 Advanced AI-Based Trading System |
//|                               Designed for Professional Trading |
//+------------------------------------------------------------------+
#property copyright "Advanced AI Expert Advisor"
#property version   "2.0"
#property strict

//--- Input Parameters
input string    Settings_General = "=== General Settings ===";
input double    LotSize = 0.1;
input bool      UseAutoLots = true;
input double    RiskPercent = 2.0;
input int       MagicNumber = 12345;
input int       Slippage = 3;

input string    Settings_Strategy = "=== Strategy Settings ===";
input bool      UseAILogic = true;
input int       AIConfidenceThreshold = 75;
input bool      UsePriceAction = true;
input bool      UseVolumeAnalysis = true;
input bool      UseMultiTimeframe = true;

input string    Settings_Indicators = "=== Indicator Settings ===";
input int       FastMA = 12;
input int       SlowMA = 26;
input int       SignalMA = 9;
input int       RSI_Period = 14;
input int       BB_Period = 20;
input double    BB_Deviation = 2.0;
input int       ADX_Period = 14;
input int       ATR_Period = 14;
input int       Stoch_K = 5;
input int       Stoch_D = 3;
input int       Stoch_Slowing = 3;

input string    Settings_Risk = "=== Risk Management ===";
input bool      UseDynamicSL = true;
input bool      UseDynamicTP = true;
input double    ATR_SL_Multiplier = 2.0;
input double    ATR_TP_Multiplier = 3.0;
input double    MaxDailyLoss = 5.0;
input double    MaxDailyProfit = 10.0;
input bool      UseTrailingStop = true;
input double    TrailingStart = 20;
input double    TrailingStep = 5;

input string    Settings_Advanced = "=== Advanced Settings ===";
input bool      UseNewsFilter = true;
input bool      UseSpreadFilter = true;
input double    MaxSpread = 3.0;
input bool      UseVolatilityFilter = true;
input double    MinVolatility = 0.0001;
input double    MaxVolatility = 0.01;

//--- Global Variables
datetime LastBarTime;
double DailyProfit = 0;
double DailyLoss = 0;
datetime DayStart;
bool TradingEnabled = true;

//--- AI Decision Structure
struct AISignal {
    double confidence;
    int direction;  // 1 for buy, -1 for sell, 0 for hold
    double strength;
    string reason;
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("AI Expert Advisor Initialized - Advanced Trading System Ready");
    LastBarTime = Time[0];
    DayStart = TimeCurrent();
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("AI Expert Advisor Deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check if new bar formed
    if(Time[0] == LastBarTime) return;
    LastBarTime = Time[0];
    
    // Reset daily counters
    if(TimeDay(TimeCurrent()) != TimeDay(DayStart))
    {
        DailyProfit = 0;
        DailyLoss = 0;
        DayStart = TimeCurrent();
        TradingEnabled = true;
    }
    
    // Check daily limits
    CheckDailyLimits();
    
    // Market condition analysis
    if(!IsMarketSuitable()) return;
    
    // Get AI signal
    AISignal signal = GetAISignal();
    
    // Execute trades based on AI decision
    if(signal.confidence >= AIConfidenceThreshold && TradingEnabled)
    {
        if(signal.direction == 1 && GetOpenPositions(OP_BUY) == 0)
        {
            OpenBuyPosition(signal);
        }
        else if(signal.direction == -1 && GetOpenPositions(OP_SELL) == 0)
        {
            OpenSellPosition(signal);
        }
    }
    
    // Manage existing positions
    ManageOpenPositions();
}

//+------------------------------------------------------------------+
//| AI Signal Generation Function                                    |
//+------------------------------------------------------------------+
AISignal GetAISignal()
{
    AISignal signal;
    signal.confidence = 0;
    signal.direction = 0;
    signal.strength = 0;
    signal.reason = "";
    
    double totalWeight = 0;
    double bullishScore = 0;
    double bearishScore = 0;
    
    // 1. MACD Analysis (Weight: 20%)
    double macdWeight = 20;
    double macdMain = iMACD(Symbol(), 0, FastMA, SlowMA, SignalMA, PRICE_CLOSE, MODE_MAIN, 1);
    double macdSignal = iMACD(Symbol(), 0, FastMA, SlowMA, SignalMA, PRICE_CLOSE, MODE_SIGNAL, 1);
    double macdPrev = iMACD(Symbol(), 0, FastMA, SlowMA, SignalMA, PRICE_CLOSE, MODE_MAIN, 2);
    
    if(macdMain > macdSignal && macdPrev <= iMACD(Symbol(), 0, FastMA, SlowMA, SignalMA, PRICE_CLOSE, MODE_SIGNAL, 2))
        bullishScore += macdWeight;
    else if(macdMain < macdSignal && macdPrev >= iMACD(Symbol(), 0, FastMA, SlowMA, SignalMA, PRICE_CLOSE, MODE_SIGNAL, 2))
        bearishScore += macdWeight;
    
    // 2. RSI Analysis (Weight: 15%)
    double rsiWeight = 15;
    double rsi = iRSI(Symbol(), 0, RSI_Period, PRICE_CLOSE, 1);
    
    if(rsi < 30) bullishScore += rsiWeight;
    else if(rsi > 70) bearishScore += rsiWeight;
    else if(rsi > 50 && rsi < 70) bullishScore += rsiWeight * 0.5;
    else if(rsi < 50 && rsi > 30) bearishScore += rsiWeight * 0.5;
    
    // 3. Bollinger Bands Analysis (Weight: 15%)
    double bbWeight = 15;
    double bbUpper = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_UPPER, 1);
    double bbLower = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_LOWER, 1);
    double bbMiddle = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_MAIN, 1);
    
    if(Close[1] <= bbLower && Close[0] > bbLower) bullishScore += bbWeight;
    else if(Close[1] >= bbUpper && Close[0] < bbUpper) bearishScore += bbWeight;
    
    // 4. ADX Trend Strength (Weight: 10%)
    double adxWeight = 10;
    double adx = iADX(Symbol(), 0, ADX_Period, PRICE_CLOSE, MODE_MAIN, 1);
    double adxPlus = iADX(Symbol(), 0, ADX_Period, PRICE_CLOSE, MODE_PLUSDI, 1);
    double adxMinus = iADX(Symbol(), 0, ADX_Period, PRICE_CLOSE, MODE_MINUSDI, 1);
    
    if(adx > 25)
    {
        if(adxPlus > adxMinus) bullishScore += adxWeight;
        else bearishScore += adxWeight;
    }
    
    // 5. Stochastic Analysis (Weight: 10%)
    double stochWeight = 10;
    double stochMain = iStochastic(Symbol(), 0, Stoch_K, Stoch_D, Stoch_Slowing, MODE_SMA, 0, MODE_MAIN, 1);
    double stochSignal = iStochastic(Symbol(), 0, Stoch_K, Stoch_D, Stoch_Slowing, MODE_SMA, 0, MODE_SIGNAL, 1);
    
    if(stochMain < 20 && stochMain > stochSignal) bullishScore += stochWeight;
    else if(stochMain > 80 && stochMain < stochSignal) bearishScore += stochWeight;
    
    // 6. Price Action Analysis (Weight: 20%)
    if(UsePriceAction)
    {
        double paWeight = 20;
        double paScore = AnalyzePriceAction();
        
        if(paScore > 0) bullishScore += paWeight * (paScore / 100);
        else bearishScore += paWeight * (MathAbs(paScore) / 100);
    }
    
    // 7. Volume Analysis (Weight: 10%)
    if(UseVolumeAnalysis)
    {
        double volWeight = 10;
        double volScore = AnalyzeVolume();
        
        if(volScore > 0) bullishScore += volWeight * (volScore / 100);
        else bearishScore += volWeight * (MathAbs(volScore) / 100);
    }
    
    totalWeight = 100;
    
    // Calculate final signal
    double netScore = bullishScore - bearishScore;
    signal.confidence = MathAbs(netScore);
    signal.strength = signal.confidence / totalWeight * 100;
    
    if(netScore > 0)
    {
        signal.direction = 1;
        signal.reason = "Bullish consensus from multiple indicators";
    }
    else if(netScore < 0)
    {
        signal.direction = -1;
        signal.reason = "Bearish consensus from multiple indicators";
    }
    else
    {
        signal.direction = 0;
        signal.reason = "Neutral - conflicting signals";
    }
    
    return signal;
}

//+------------------------------------------------------------------+
//| Price Action Analysis                                            |
//+------------------------------------------------------------------+
double AnalyzePriceAction()
{
    double score = 0;
    
    // Candlestick patterns
    double open1 = Open[1], high1 = High[1], low1 = Low[1], close1 = Close[1];
    double open2 = Open[2], high2 = High[2], low2 = Low[2], close2 = Close[2];
    double open3 = Open[3], high3 = High[3], low3 = Low[3], close3 = Close[3];
    
    // Hammer pattern
    if(IsHammer(open1, high1, low1, close1))
        score += 30;
    
    // Doji pattern
    if(IsDoji(open1, high1, low1, close1))
        score += 15;
    
    // Engulfing patterns
    if(IsBullishEngulfing(open2, high2, low2, close2, open1, high1, low1, close1))
        score += 40;
    else if(IsBearishEngulfing(open2, high2, low2, close2, open1, high1, low1, close1))
        score -= 40;
    
    // Support/Resistance levels
    double sr_score = AnalyzeSupportResistance();
    score += sr_score;
    
    return score;
}

//+------------------------------------------------------------------+
//| Volume Analysis                                                  |
//+------------------------------------------------------------------+
double AnalyzeVolume()
{
    double score = 0;
    
    // Volume is not directly available in MT4, so we use tick volume
    double vol1 = Volume[1];
    double vol2 = Volume[2];
    double vol3 = Volume[3];
    double avgVol = (vol1 + vol2 + vol3) / 3;
    
    // Price movement vs volume
    double priceChange = MathAbs(Close[1] - Close[2]);
    double avgPrice = (High[1] + Low[1] + Close[1]) / 3;
    
    if(vol1 > avgVol * 1.5 && priceChange > avgPrice * 0.001)
    {
        if(Close[1] > Close[2]) score += 30;
        else score -= 30;
    }
    
    return score;
}

//+------------------------------------------------------------------+
//| Support/Resistance Analysis                                      |
//+------------------------------------------------------------------+
double AnalyzeSupportResistance()
{
    double score = 0;
    int period = 20;
    
    // Find recent highs and lows
    double recentHigh = High[iHighest(Symbol(), 0, MODE_HIGH, period, 1)];
    double recentLow = Low[iLowest(Symbol(), 0, MODE_LOW, period, 1)];
    
    double currentPrice = Close[0];
    double range = recentHigh - recentLow;
    
    // Distance from support/resistance
    double distFromHigh = (recentHigh - currentPrice) / Point;
    double distFromLow = (currentPrice - recentLow) / Point;
    
    // Scoring based on position relative to S/R
    if(distFromLow < range * 0.1) score += 25; // Near support
    else if(distFromHigh < range * 0.1) score -= 25; // Near resistance
    
    return score;
}

//+------------------------------------------------------------------+
//| Candlestick Pattern Recognition                                  |
//+------------------------------------------------------------------+
bool IsHammer(double open, double high, double low, double close)
{
    double body = MathAbs(close - open);
    double lowerShadow = MathMin(open, close) - low;
    double upperShadow = high - MathMax(open, close);
    
    return (lowerShadow > body * 2 && upperShadow < body * 0.5);
}

bool IsDoji(double open, double high, double low, double close)
{
    double body = MathAbs(close - open);
    double range = high - low;
    
    return (body < range * 0.1);
}

bool IsBullishEngulfing(double open1, double high1, double low1, double close1,
                       double open2, double high2, double low2, double close2)
{
    return (close1 < open1 && close2 > open2 && 
            open2 < close1 && close2 > open1);
}

bool IsBearishEngulfing(double open1, double high1, double low1, double close1,
                       double open2, double high2, double low2, double close2)
{
    return (close1 > open1 && close2 < open2 && 
            open2 > close1 && close2 < open1);
}

//+------------------------------------------------------------------+
//| Market Suitability Check                                         |
//+------------------------------------------------------------------+
bool IsMarketSuitable()
{
    // Spread filter
    if(UseSpreadFilter)
    {
        double spread = (Ask - Bid) / Point;
        if(spread > MaxSpread) return false;
    }
    
    // Volatility filter
    if(UseVolatilityFilter)
    {
        double atr = iATR(Symbol(), 0, ATR_Period, 1);
        if(atr < MinVolatility || atr > MaxVolatility) return false;
    }
    
    // News filter (basic time-based)
    if(UseNewsFilter)
    {
        int hour = TimeHour(TimeCurrent());
        // Avoid major news times (can be enhanced with news calendar)
        if(hour >= 8 && hour <= 10) return false; // European session major news
        if(hour >= 13 && hour <= 15) return false; // US session major news
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate Dynamic Lot Size                                       |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
    if(!UseAutoLots) return LotSize;
    
    double balance = AccountBalance();
    double atr = iATR(Symbol(), 0, ATR_Period, 1);
    double stopLoss = atr * ATR_SL_Multiplier;
    
    double riskAmount = balance * RiskPercent / 100;
    double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
    double stopLossPips = stopLoss / Point;
    
    double lotSize = riskAmount / (stopLossPips * tickValue);
    
    // Normalize lot size
    double minLot = MarketInfo(Symbol(), MODE_MINLOT);
    double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
    double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
    
    lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
    lotSize = NormalizeDouble(lotSize / lotStep, 0) * lotStep;
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| Open Buy Position                                                |
//+------------------------------------------------------------------+
void OpenBuyPosition(AISignal signal)
{
    double lotSize = CalculateLotSize();
    double atr = iATR(Symbol(), 0, ATR_Period, 1);
    
    double stopLoss = 0;
    double takeProfit = 0;
    
    if(UseDynamicSL)
        stopLoss = Bid - (atr * ATR_SL_Multiplier);
    
    if(UseDynamicTP)
        takeProfit = Ask + (atr * ATR_TP_Multiplier);
    
    int ticket = OrderSend(Symbol(), OP_BUY, lotSize, Ask, Slippage, 
                          stopLoss, takeProfit, 
                          "AI EA Buy - " + signal.reason, 
                          MagicNumber, 0, clrGreen);
    
    if(ticket > 0)
    {
        Print("Buy order opened successfully. Ticket: ", ticket, 
              ", Confidence: ", signal.confidence, "%");
    }
    else
    {
        Print("Failed to open buy order. Error: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Open Sell Position                                               |
//+------------------------------------------------------------------+
void OpenSellPosition(AISignal signal)
{
    double lotSize = CalculateLotSize();
    double atr = iATR(Symbol(), 0, ATR_Period, 1);
    
    double stopLoss = 0;
    double takeProfit = 0;
    
    if(UseDynamicSL)
        stopLoss = Ask + (atr * ATR_SL_Multiplier);
    
    if(UseDynamicTP)
        takeProfit = Bid - (atr * ATR_TP_Multiplier);
    
    int ticket = OrderSend(Symbol(), OP_SELL, lotSize, Bid, Slippage, 
                          stopLoss, takeProfit, 
                          "AI EA Sell - " + signal.reason, 
                          MagicNumber, 0, clrRed);
    
    if(ticket > 0)
    {
        Print("Sell order opened successfully. Ticket: ", ticket, 
              ", Confidence: ", signal.confidence, "%");
    }
    else
    {
        Print("Failed to open sell order. Error: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Manage Open Positions                                            |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS) && OrderMagicNumber() == MagicNumber)
        {
            if(UseTrailingStop)
                ApplyTrailingStop(OrderTicket(), OrderType(), OrderOpenPrice(), 
                                OrderStopLoss(), OrderTakeProfit());
        }
    }
}

//+------------------------------------------------------------------+
//| Apply Trailing Stop                                              |
//+------------------------------------------------------------------+
void ApplyTrailingStop(int ticket, int orderType, double openPrice, 
                      double currentSL, double currentTP)
{
    double newSL = currentSL;
    bool modifyOrder = false;
    
    if(orderType == OP_BUY)
    {
        double profit = Bid - openPrice;
        if(profit >= TrailingStart * Point)
        {
            newSL = Bid - TrailingStep * Point;
            if(newSL > currentSL)
                modifyOrder = true;
        }
    }
    else if(orderType == OP_SELL)
    {
        double profit = openPrice - Ask;
        if(profit >= TrailingStart * Point)
        {
            newSL = Ask + TrailingStep * Point;
            if(newSL < currentSL || currentSL == 0)
                modifyOrder = true;
        }
    }
    
    if(modifyOrder)
    {
        if(OrderModify(ticket, openPrice, newSL, currentTP, 0, clrBlue))
        {
            Print("Trailing stop applied to order ", ticket);
        }
    }
}

//+------------------------------------------------------------------+
//| Get Open Positions Count                                         |
//+------------------------------------------------------------------+
int GetOpenPositions(int orderType)
{
    int count = 0;
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS) && 
           OrderMagicNumber() == MagicNumber && 
           OrderType() == orderType)
        {
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
    
    for(int i = OrdersHistoryTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) && 
           OrderMagicNumber() == MagicNumber)
        {
            if(TimeDay(OrderCloseTime()) == TimeDay(TimeCurrent()))
            {
                if(OrderProfit() > 0)
                    todayProfit += OrderProfit();
                else
                    todayLoss += MathAbs(OrderProfit());
            }
        }
    }
    
    double accountBalance = AccountBalance();
    double profitPercent = (todayProfit / accountBalance) * 100;
    double lossPercent = (todayLoss / accountBalance) * 100;
    
    if(profitPercent >= MaxDailyProfit || lossPercent >= MaxDailyLoss)
    {
        TradingEnabled = false;
        Print("Daily limit reached. Trading disabled for today.");
        Print("Profit: ", profitPercent, "%, Loss: ", lossPercent, "%");
    }
}