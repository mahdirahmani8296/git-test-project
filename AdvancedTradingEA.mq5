//+------------------------------------------------------------------+
//|                                          AdvancedTradingEA.mq5 |
//|                                    Copyright 2024, Expert Trader |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Expert Trader"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "Advanced Multi-Indicator Trading Expert Advisor"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//--- Input Parameters
input group "=== Main Strategy Settings ==="
input bool InpUseStrategy = true;                    // Enable Trading
input int InpMagicNumber = 123456;                   // Magic Number
input string InpTradeComment = "AdvancedEA";         // Trade Comment

input group "=== Risk Management ==="
input double InpRiskPercent = 2.0;                   // Risk Percentage per Trade
input double InpMaxSpread = 30.0;                    // Maximum Spread (points)
input int InpMaxPositions = 3;                       // Maximum Open Positions
input double InpMaxDailyLoss = 5.0;                  // Maximum Daily Loss %

input group "=== Take Profit & Stop Loss ==="
input bool InpUseDynamicSL = true;                   // Use Dynamic Stop Loss
input bool InpUseDynamicTP = true;                   // Use Dynamic Take Profit
input double InpStaticSL = 100.0;                    // Static Stop Loss (points)
input double InpStaticTP = 200.0;                    // Static Take Profit (points)
input double InpTrailStart = 150.0;                  // Trailing Stop Start (points)
input double InpTrailStep = 50.0;                    // Trailing Stop Step (points)

input group "=== Indicator Settings ==="
input int InpRSIPeriod = 14;                         // RSI Period
input int InpRSILevel = 70;                          // RSI Overbought/Oversold Level
input int InpMACDFast = 12;                          // MACD Fast EMA
input int InpMACDSlow = 26;                          // MACD Slow EMA
input int InpMACDSignal = 9;                         // MACD Signal Period
input int InpBBPeriod = 20;                          // Bollinger Bands Period
input double InpBBDeviation = 2.0;                   // Bollinger Bands Deviation
input int InpADXPeriod = 14;                         // ADX Period
input double InpADXLevel = 25.0;                     // ADX Trend Strength Level
input int InpATRPeriod = 14;                         // ATR Period
input int InpEMA1Period = 21;                        // Fast EMA Period
input int InpEMA2Period = 50;                        // Slow EMA Period
input int InpEMA3Period = 200;                       // Trend EMA Period

input group "=== Time Filter ==="
input bool InpUseTimeFilter = true;                  // Use Time Filter
input int InpStartHour = 8;                          // Trading Start Hour
input int InpEndHour = 20;                           // Trading End Hour
input bool InpTradeMonday = true;                    // Trade on Monday
input bool InpTradeTuesday = true;                   // Trade on Tuesday
input bool InpTradeWednesday = true;                 // Trade on Wednesday
input bool InpTradeThursday = true;                  // Trade on Thursday
input bool InpTradeFriday = true;                    // Trade on Friday

//--- Global Variables
CTrade trade;
CPositionInfo position;
COrderInfo order;

int handleRSI, handleMACD, handleBB, handleADX, handleATR;
int handleEMA1, handleEMA2, handleEMA3;
double rsiBuffer[], macdMainBuffer[], macdSignalBuffer[];
double bbUpperBuffer[], bbMiddleBuffer[], bbLowerBuffer[];
double adxMainBuffer[], atrBuffer[];
double ema1Buffer[], ema2Buffer[], ema3Buffer[];

datetime lastTradeTime = 0;
double dailyStartBalance = 0;
bool dailyLossReached = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Set magic number
    trade.SetExpertMagicNumber(InpMagicNumber);
    
    // Initialize indicators
    handleRSI = iRSI(_Symbol, PERIOD_CURRENT, InpRSIPeriod, PRICE_CLOSE);
    handleMACD = iMACD(_Symbol, PERIOD_CURRENT, InpMACDFast, InpMACDSlow, InpMACDSignal, PRICE_CLOSE);
    handleBB = iBands(_Symbol, PERIOD_CURRENT, InpBBPeriod, 0, InpBBDeviation, PRICE_CLOSE);
    handleADX = iADX(_Symbol, PERIOD_CURRENT, InpADXPeriod);
    handleATR = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);
    handleEMA1 = iMA(_Symbol, PERIOD_CURRENT, InpEMA1Period, 0, MODE_EMA, PRICE_CLOSE);
    handleEMA2 = iMA(_Symbol, PERIOD_CURRENT, InpEMA2Period, 0, MODE_EMA, PRICE_CLOSE);
    handleEMA3 = iMA(_Symbol, PERIOD_CURRENT, InpEMA3Period, 0, MODE_EMA, PRICE_CLOSE);
    
    // Check indicator handles
    if(handleRSI == INVALID_HANDLE || handleMACD == INVALID_HANDLE || 
       handleBB == INVALID_HANDLE || handleADX == INVALID_HANDLE || 
       handleATR == INVALID_HANDLE || handleEMA1 == INVALID_HANDLE ||
       handleEMA2 == INVALID_HANDLE || handleEMA3 == INVALID_HANDLE)
    {
        Print("Error creating indicator handles");
        return INIT_FAILED;
    }
    
    // Initialize arrays
    ArraySetAsSeries(rsiBuffer, true);
    ArraySetAsSeries(macdMainBuffer, true);
    ArraySetAsSeries(macdSignalBuffer, true);
    ArraySetAsSeries(bbUpperBuffer, true);
    ArraySetAsSeries(bbMiddleBuffer, true);
    ArraySetAsSeries(bbLowerBuffer, true);
    ArraySetAsSeries(adxMainBuffer, true);
    ArraySetAsSeries(atrBuffer, true);
    ArraySetAsSeries(ema1Buffer, true);
    ArraySetAsSeries(ema2Buffer, true);
    ArraySetAsSeries(ema3Buffer, true);
    
    // Set daily start balance
    dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    Print("Advanced Trading EA initialized successfully");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    IndicatorRelease(handleRSI);
    IndicatorRelease(handleMACD);
    IndicatorRelease(handleBB);
    IndicatorRelease(handleADX);
    IndicatorRelease(handleATR);
    IndicatorRelease(handleEMA1);
    IndicatorRelease(handleEMA2);
    IndicatorRelease(handleEMA3);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if(!InpUseStrategy) return;
    
    // Check if new bar
    static datetime lastBarTime = 0;
    datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    if(currentBarTime == lastBarTime) return;
    lastBarTime = currentBarTime;
    
    // Check daily loss limit
    CheckDailyLossLimit();
    if(dailyLossReached) return;
    
    // Check time filter
    if(!IsTimeToTrade()) return;
    
    // Check spread
    if(!IsSpreadOK()) return;
    
    // Update indicator values
    if(!UpdateIndicators()) return;
    
    // Manage existing positions
    ManagePositions();
    
    // Check for new signals
    if(GetOpenPositionsCount() < InpMaxPositions)
    {
        CheckForSignals();
    }
}

//+------------------------------------------------------------------+
//| Update all indicator values                                      |
//+------------------------------------------------------------------+
bool UpdateIndicators()
{
    // Copy RSI values
    if(CopyBuffer(handleRSI, 0, 0, 3, rsiBuffer) <= 0) return false;
    
    // Copy MACD values
    if(CopyBuffer(handleMACD, 0, 0, 3, macdMainBuffer) <= 0) return false;
    if(CopyBuffer(handleMACD, 1, 0, 3, macdSignalBuffer) <= 0) return false;
    
    // Copy Bollinger Bands values
    if(CopyBuffer(handleBB, 0, 0, 3, bbUpperBuffer) <= 0) return false;
    if(CopyBuffer(handleBB, 1, 0, 3, bbMiddleBuffer) <= 0) return false;
    if(CopyBuffer(handleBB, 2, 0, 3, bbLowerBuffer) <= 0) return false;
    
    // Copy ADX values
    if(CopyBuffer(handleADX, 0, 0, 3, adxMainBuffer) <= 0) return false;
    
    // Copy ATR values
    if(CopyBuffer(handleATR, 0, 0, 3, atrBuffer) <= 0) return false;
    
    // Copy EMA values
    if(CopyBuffer(handleEMA1, 0, 0, 3, ema1Buffer) <= 0) return false;
    if(CopyBuffer(handleEMA2, 0, 0, 3, ema2Buffer) <= 0) return false;
    if(CopyBuffer(handleEMA3, 0, 0, 3, ema3Buffer) <= 0) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Check for trading signals                                        |
//+------------------------------------------------------------------+
void CheckForSignals()
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // Buy Signal Analysis
    bool buySignal = false;
    bool sellSignal = false;
    
    // Multi-timeframe trend analysis
    bool bullishTrend = IsBullishTrend();
    bool bearishTrend = IsBearishTrend();
    
    // Momentum confirmation
    bool bullishMomentum = IsBullishMomentum();
    bool bearishMomentum = IsBearishMomentum();
    
    // Volatility filter
    bool highVolatility = IsHighVolatility();
    
    // Buy conditions
    if(bullishTrend && bullishMomentum && highVolatility)
    {
        // Additional confirmation filters
        if(rsiBuffer[0] > 50 && rsiBuffer[0] < 70 &&  // RSI in bullish zone but not overbought
           macdMainBuffer[0] > macdSignalBuffer[0] &&  // MACD bullish
           macdMainBuffer[0] > macdMainBuffer[1] &&    // MACD rising
           ask > bbMiddleBuffer[0] &&                  // Price above BB middle
           adxMainBuffer[0] > InpADXLevel &&           // Strong trend
           ema1Buffer[0] > ema2Buffer[0] &&            // Fast EMA above slow EMA
           ema2Buffer[0] > ema3Buffer[0])              // Trend confirmation
        {
            buySignal = true;
        }
    }
    
    // Sell conditions
    if(bearishTrend && bearishMomentum && highVolatility)
    {
        // Additional confirmation filters
        if(rsiBuffer[0] < 50 && rsiBuffer[0] > 30 &&  // RSI in bearish zone but not oversold
           macdMainBuffer[0] < macdSignalBuffer[0] &&  // MACD bearish
           macdMainBuffer[0] < macdMainBuffer[1] &&    // MACD falling
           bid < bbMiddleBuffer[0] &&                  // Price below BB middle
           adxMainBuffer[0] > InpADXLevel &&           // Strong trend
           ema1Buffer[0] < ema2Buffer[0] &&            // Fast EMA below slow EMA
           ema2Buffer[0] < ema3Buffer[0])              // Trend confirmation
        {
            sellSignal = true;
        }
    }
    
    // Execute trades
    if(buySignal && TimeCurrent() - lastTradeTime > 300) // 5 minute delay between trades
    {
        OpenBuyPosition();
        lastTradeTime = TimeCurrent();
    }
    else if(sellSignal && TimeCurrent() - lastTradeTime > 300)
    {
        OpenSellPosition();
        lastTradeTime = TimeCurrent();
    }
}

//+------------------------------------------------------------------+
//| Check if bullish trend                                           |
//+------------------------------------------------------------------+
bool IsBullishTrend()
{
    // Multiple EMA alignment
    if(ema1Buffer[0] > ema2Buffer[0] && ema2Buffer[0] > ema3Buffer[0])
    {
        // Price above key moving averages
        double close = iClose(_Symbol, PERIOD_CURRENT, 0);
        if(close > ema1Buffer[0] && close > ema2Buffer[0])
        {
            // Bollinger Bands expansion (volatility)
            if(bbUpperBuffer[0] - bbLowerBuffer[0] > bbUpperBuffer[1] - bbLowerBuffer[1])
            {
                return true;
            }
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Check if bearish trend                                           |
//+------------------------------------------------------------------+
bool IsBearishTrend()
{
    // Multiple EMA alignment
    if(ema1Buffer[0] < ema2Buffer[0] && ema2Buffer[0] < ema3Buffer[0])
    {
        // Price below key moving averages
        double close = iClose(_Symbol, PERIOD_CURRENT, 0);
        if(close < ema1Buffer[0] && close < ema2Buffer[0])
        {
            // Bollinger Bands expansion (volatility)
            if(bbUpperBuffer[0] - bbLowerBuffer[0] > bbUpperBuffer[1] - bbLowerBuffer[1])
            {
                return true;
            }
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Check if bullish momentum                                        |
//+------------------------------------------------------------------+
bool IsBullishMomentum()
{
    // MACD bullish momentum
    bool macdBullish = macdMainBuffer[0] > macdSignalBuffer[0] && 
                       macdMainBuffer[0] > macdMainBuffer[1];
    
    // RSI momentum but not overbought
    bool rsiBullish = rsiBuffer[0] > 55 && rsiBuffer[0] < 75 && 
                      rsiBuffer[0] > rsiBuffer[1];
    
    return macdBullish && rsiBullish;
}

//+------------------------------------------------------------------+
//| Check if bearish momentum                                        |
//+------------------------------------------------------------------+
bool IsBearishMomentum()
{
    // MACD bearish momentum
    bool macdBearish = macdMainBuffer[0] < macdSignalBuffer[0] && 
                       macdMainBuffer[0] < macdMainBuffer[1];
    
    // RSI momentum but not oversold
    bool rsiBearish = rsiBuffer[0] < 45 && rsiBuffer[0] > 25 && 
                      rsiBuffer[0] < rsiBuffer[1];
    
    return macdBearish && rsiBearish;
}

//+------------------------------------------------------------------+
//| Check if high volatility environment                             |
//+------------------------------------------------------------------+
bool IsHighVolatility()
{
    // ATR above recent average
    double atrAvg = (atrBuffer[0] + atrBuffer[1] + atrBuffer[2]) / 3.0;
    return atrBuffer[0] > atrAvg * 1.2;
}

//+------------------------------------------------------------------+
//| Open buy position                                                |
//+------------------------------------------------------------------+
void OpenBuyPosition()
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double lotSize = CalculateLotSize(true);
    
    if(lotSize > 0)
    {
        double sl = CalculateStopLoss(true, ask);
        double tp = CalculateTakeProfit(true, ask);
        
        if(trade.Buy(lotSize, _Symbol, ask, sl, tp, InpTradeComment))
        {
            Print("Buy order opened: Lot=", lotSize, " SL=", sl, " TP=", tp);
        }
        else
        {
            Print("Failed to open buy order: ", trade.ResultRetcodeDescription());
        }
    }
}

//+------------------------------------------------------------------+
//| Open sell position                                               |
//+------------------------------------------------------------------+
void OpenSellPosition()
{
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double lotSize = CalculateLotSize(false);
    
    if(lotSize > 0)
    {
        double sl = CalculateStopLoss(false, bid);
        double tp = CalculateTakeProfit(false, bid);
        
        if(trade.Sell(lotSize, _Symbol, bid, sl, tp, InpTradeComment))
        {
            Print("Sell order opened: Lot=", lotSize, " SL=", sl, " TP=", tp);
        }
        else
        {
            Print("Failed to open sell order: ", trade.ResultRetcodeDescription());
        }
    }
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk management                      |
//+------------------------------------------------------------------+
double CalculateLotSize(bool isBuy)
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = balance * InpRiskPercent / 100.0;
    
    double price = isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double sl = InpUseDynamicSL ? CalculateStopLoss(isBuy, price) : 
                (isBuy ? price - InpStaticSL * _Point : price + InpStaticSL * _Point);
    
    double slDistance = MathAbs(price - sl);
    if(slDistance == 0) return 0;
    
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    
    double lotSize = riskAmount / (slDistance / tickSize * tickValue);
    
    // Normalize lot size
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    
    lotSize = MathFloor(lotSize / lotStep) * lotStep;
    lotSize = MathMax(lotSize, minLot);
    lotSize = MathMin(lotSize, maxLot);
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| Calculate dynamic stop loss                                      |
//+------------------------------------------------------------------+
double CalculateStopLoss(bool isBuy, double entryPrice)
{
    if(!InpUseDynamicSL)
    {
        return isBuy ? entryPrice - InpStaticSL * _Point : entryPrice + InpStaticSL * _Point;
    }
    
    // Use ATR-based stop loss
    double atrValue = atrBuffer[0];
    double slDistance = atrValue * 2.0; // 2 times ATR
    
    // Consider recent swing high/low
    double swingLevel = isBuy ? FindRecentLow() : FindRecentHigh();
    double swingDistance = MathAbs(entryPrice - swingLevel);
    
    // Use the wider of ATR or swing-based SL
    slDistance = MathMax(slDistance, swingDistance);
    
    // Minimum SL distance
    double minDistance = 50 * _Point;
    slDistance = MathMax(slDistance, minDistance);
    
    return isBuy ? entryPrice - slDistance : entryPrice + slDistance;
}

//+------------------------------------------------------------------+
//| Calculate dynamic take profit                                    |
//+------------------------------------------------------------------+
double CalculateTakeProfit(bool isBuy, double entryPrice)
{
    if(!InpUseDynamicTP)
    {
        return isBuy ? entryPrice + InpStaticTP * _Point : entryPrice - InpStaticTP * _Point;
    }
    
    // Use ATR-based take profit with risk-reward ratio
    double atrValue = atrBuffer[0];
    double sl = CalculateStopLoss(isBuy, entryPrice);
    double slDistance = MathAbs(entryPrice - sl);
    
    // Target 2:1 risk-reward ratio minimum
    double tpDistance = slDistance * 2.5;
    
    // Consider Bollinger Bands as target
    if(isBuy && bbUpperBuffer[0] > entryPrice + tpDistance)
    {
        return bbUpperBuffer[0];
    }
    else if(!isBuy && bbLowerBuffer[0] < entryPrice - tpDistance)
    {
        return bbLowerBuffer[0];
    }
    
    return isBuy ? entryPrice + tpDistance : entryPrice - tpDistance;
}

//+------------------------------------------------------------------+
//| Find recent swing low                                            |
//+------------------------------------------------------------------+
double FindRecentLow()
{
    double minLow = iLow(_Symbol, PERIOD_CURRENT, 1);
    for(int i = 2; i <= 10; i++)
    {
        double low = iLow(_Symbol, PERIOD_CURRENT, i);
        if(low < minLow) minLow = low;
    }
    return minLow;
}

//+------------------------------------------------------------------+
//| Find recent swing high                                           |
//+------------------------------------------------------------------+
double FindRecentHigh()
{
    double maxHigh = iHigh(_Symbol, PERIOD_CURRENT, 1);
    for(int i = 2; i <= 10; i++)
    {
        double high = iHigh(_Symbol, PERIOD_CURRENT, i);
        if(high > maxHigh) maxHigh = high;
    }
    return maxHigh;
}

//+------------------------------------------------------------------+
//| Manage existing positions                                        |
//+------------------------------------------------------------------+
void ManagePositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Magic() == InpMagicNumber && position.Symbol() == _Symbol)
            {
                // Trailing stop
                TrailingStop(position.Ticket());
                
                // Partial profit taking
                PartialProfitTaking(position.Ticket());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Trailing stop function                                           |
//+------------------------------------------------------------------+
void TrailingStop(ulong ticket)
{
    if(!position.SelectByTicket(ticket)) return;
    
    double currentPrice = position.TypeFill() == POSITION_TYPE_BUY ? 
                          SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                          SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    double openPrice = position.PriceOpen();
    double currentSL = position.StopLoss();
    
    if(position.TypeFill() == POSITION_TYPE_BUY)
    {
        // Buy position trailing
        if(currentPrice - openPrice >= InpTrailStart * _Point)
        {
            double newSL = currentPrice - InpTrailStep * _Point;
            if(newSL > currentSL + InpTrailStep * _Point)
            {
                trade.PositionModify(ticket, newSL, position.TakeProfit());
            }
        }
    }
    else
    {
        // Sell position trailing
        if(openPrice - currentPrice >= InpTrailStart * _Point)
        {
            double newSL = currentPrice + InpTrailStep * _Point;
            if(newSL < currentSL - InpTrailStep * _Point)
            {
                trade.PositionModify(ticket, newSL, position.TakeProfit());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Partial profit taking                                            |
//+------------------------------------------------------------------+
void PartialProfitTaking(ulong ticket)
{
    if(!position.SelectByTicket(ticket)) return;
    
    double currentPrice = position.TypeFill() == POSITION_TYPE_BUY ? 
                          SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                          SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    double openPrice = position.PriceOpen();
    double profit = position.Profit();
    double volume = position.Volume();
    
    // Take 50% profit when 2:1 RR is reached
    if(profit > 0 && volume > SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
    {
        double atrValue = atrBuffer[0];
        double targetProfit = atrValue * 2.0;
        
        bool takePartialProfit = false;
        
        if(position.TypeFill() == POSITION_TYPE_BUY)
        {
            takePartialProfit = (currentPrice - openPrice) >= targetProfit;
        }
        else
        {
            takePartialProfit = (openPrice - currentPrice) >= targetProfit;
        }
        
        if(takePartialProfit)
        {
            double partialVolume = volume * 0.5;
            partialVolume = MathMax(partialVolume, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN));
            
            if(position.TypeFill() == POSITION_TYPE_BUY)
            {
                trade.Sell(partialVolume, _Symbol, currentPrice, 0, 0, "Partial Profit");
            }
            else
            {
                trade.Buy(partialVolume, _Symbol, currentPrice, 0, 0, "Partial Profit");
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check if spread is acceptable                                    |
//+------------------------------------------------------------------+
bool IsSpreadOK()
{
    double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    return spread <= InpMaxSpread;
}

//+------------------------------------------------------------------+
//| Check if it's time to trade                                      |
//+------------------------------------------------------------------+
bool IsTimeToTrade()
{
    if(!InpUseTimeFilter) return true;
    
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    // Check day of week
    bool dayOK = false;
    switch(dt.day_of_week)
    {
        case 1: dayOK = InpTradeMonday; break;
        case 2: dayOK = InpTradeTuesday; break;
        case 3: dayOK = InpTradeWednesday; break;
        case 4: dayOK = InpTradeThursday; break;
        case 5: dayOK = InpTradeFriday; break;
        default: dayOK = false;
    }
    
    // Check hour
    bool hourOK = (dt.hour >= InpStartHour && dt.hour <= InpEndHour);
    
    return dayOK && hourOK;
}

//+------------------------------------------------------------------+
//| Get count of open positions                                      |
//+------------------------------------------------------------------+
int GetOpenPositionsCount()
{
    int count = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Magic() == InpMagicNumber && position.Symbol() == _Symbol)
            {
                count++;
            }
        }
    }
    return count;
}

//+------------------------------------------------------------------+
//| Check daily loss limit                                           |
//+------------------------------------------------------------------+
void CheckDailyLossLimit()
{
    static int lastDay = 0;
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    // Reset daily variables at start of new day
    if(dt.day != lastDay)
    {
        lastDay = dt.day;
        dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        dailyLossReached = false;
    }
    
    // Check if daily loss limit reached
    double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double dailyLoss = (dailyStartBalance - currentBalance) / dailyStartBalance * 100.0;
    
    if(dailyLoss >= InpMaxDailyLoss)
    {
        dailyLossReached = true;
        Print("Daily loss limit reached: ", dailyLoss, "%");
        
        // Close all positions
        CloseAllPositions();
    }
}

//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Magic() == InpMagicNumber && position.Symbol() == _Symbol)
            {
                trade.PositionClose(position.Ticket());
            }
        }
    }
}

//+------------------------------------------------------------------+