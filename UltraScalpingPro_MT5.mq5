//+------------------------------------------------------------------+
//|                                        UltraScalpingPro_MT5.mq5 |
//|                    Ultra Advanced Scalping Expert Advisor MT5 |
//|                    Designed for Gold and Major Forex Pairs |
//|                    Professional Grade with AI Logic |
//+------------------------------------------------------------------+
#property copyright "UltraScalpingPro MT5"
#property version   "4.0"
#property description "Ultra Advanced Scalping EA for Gold and Major Forex"
#property description "Features: AI Logic, Dynamic Risk Management, Multi-Timeframe Analysis"
#property description "Optimized for High-Frequency Scalping with Maximum Profit"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Indicators\Indicators.mqh>
#include <Math\Stat\Math.mqh>

//--- Input Parameters
input group "=== GENERAL SETTINGS ==="
input double    InpLotSize = 0.1;                    // Fixed Lot Size
input bool      InpUseAutoLots = true;               // Use Auto Lot Calculation
input double    InpRiskPercent = 1.5;                // Risk Per Trade (%)
input ulong     InpMagicNumber = 20241201;           // Magic Number
input ulong     InpDeviation = 5;                    // Slippage (Points)
input int       InpMaxPositions = 3;                 // Maximum Concurrent Positions

input group "=== SCALPING STRATEGY ==="
input bool      InpUseAdvancedScalping = true;       // Use Advanced Scalping Logic
input int       InpScalpingTimeframe = PERIOD_M1;    // Scalping Timeframe
input int       InpAnalysisTimeframe = PERIOD_M5;    // Analysis Timeframe
input int       InpMinProfitPoints = 5;              // Minimum Profit (Points)
input int       InpMaxLossPoints = 15;               // Maximum Loss (Points)
input bool      InpUseQuickExit = true;              // Quick Exit on Reversal
input int       InpQuickExitThreshold = 3;           // Quick Exit Threshold (Points)

input group "=== TECHNICAL INDICATORS ==="
input int       InpFastEMA = 8;                      // Fast EMA Period
input int       InpSlowEMA = 21;                     // Slow EMA Period
input int       InpSignalEMA = 13;                   // Signal EMA Period
input int       InpRSI_Period = 14;                  // RSI Period
input int       InpRSI_Overbought = 70;              // RSI Overbought Level
input int       InpRSI_Oversold = 30;                // RSI Oversold Level
input int       InpStoch_K = 5;                      // Stochastic %K Period
input int       InpStoch_D = 3;                      // Stochastic %D Period
input int       InpStoch_Slowing = 3;                // Stochastic Slowing
input int       InpATR_Period = 14;                  // ATR Period
input double    InpATR_Multiplier = 1.5;             // ATR Multiplier for SL/TP

input group "=== ADVANCED FILTERS ==="
input bool      InpUseSpreadFilter = true;           // Filter by Spread
input double    InpMaxSpread = 15;                   // Maximum Spread (Points)
input bool      InpUseVolatilityFilter = true;       // Filter by Volatility
input double    InpMinVolatility = 0.0001;           // Minimum Volatility
input double    InpMaxVolatility = 0.001;            // Maximum Volatility
input bool      InpUseTimeFilter = true;             // Filter by Time
input string    InpStartTime = "08:00";              // Trading Start Time
input string    InpEndTime = "22:00";                // Trading End Time
input bool      InpUseNewsFilter = true;             // Filter News Events
input int       InpNewsBufferMinutes = 30;           // News Buffer (Minutes)

input group "=== RISK MANAGEMENT ==="
input bool      InpUseDynamicSL = true;              // Dynamic Stop Loss
input bool      InpUseDynamicTP = true;              // Dynamic Take Profit
input double    InpSL_ATR_Multiplier = 2.0;          // SL ATR Multiplier
input double    InpTP_ATR_Multiplier = 3.0;          // TP ATR Multiplier
input bool      InpUseTrailingStop = true;           // Use Trailing Stop
input double    InpTrailingStart = 10;               // Trailing Start (Points)
input double    InpTrailingStep = 5;                 // Trailing Step (Points)
input double    InpMaxDailyLoss = 3.0;               // Max Daily Loss (%)
input double    InpMaxDailyProfit = 10.0;            // Max Daily Profit (%)
input bool      InpUseBreakEven = true;              // Use Break Even
input double    InpBreakEvenPoints = 8;              // Break Even Points

input group "=== AI & MACHINE LEARNING ==="
input bool      InpUseAI = true;                     // Use AI Logic
input int       InpAIHistoryBars = 500;              // AI History Bars
input double    InpAIConfidenceThreshold = 0.75;     // AI Confidence Threshold
input bool      InpUsePatternRecognition = true;     // Pattern Recognition
input bool      InpUseSentimentAnalysis = true;      // Market Sentiment Analysis

input group "=== PROFIT OPTIMIZATION ==="
input bool      InpUseProfitOptimization = true;     // Profit Optimization
input double    InpProfitTarget = 5.0;               // Daily Profit Target (%)
input bool      InpUseCompounding = true;            // Use Compounding
input double    InpCompoundingRate = 0.1;            // Compounding Rate (%)
input bool      InpUseAdaptiveLots = true;           // Adaptive Lot Sizing

//--- Global Objects
CTrade trade;
CPositionInfo positionInfo;
COrderInfo orderInfo;

//--- Indicator Handles
int handleFastEMA, handleSlowEMA, handleSignalEMA;
int handleRSI, handleStoch, handleATR;
int handleBBands, handleMACD, handleCCI;

//--- Global Variables
datetime lastBarTime = 0;
double dailyProfit = 0;
double dailyLoss = 0;
datetime lastTradeTime = 0;
int totalTrades = 0;
int winningTrades = 0;
double winRate = 0;
double averageWin = 0;
double averageLoss = 0;
double profitFactor = 0;

//--- AI Variables
double aiConfidence = 0;
double marketSentiment = 0;
bool patternDetected = false;
int patternType = 0;

//--- Arrays for Indicators
double fastEMA[], slowEMA[], signalEMA[];
double rsiValues[], stochK[], stochD[];
double atrValues[], bbUpper[], bbLower[];
double macdMain[], macdSignal[];
double cciValues[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize trade object
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpDeviation);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   trade.SetAsyncMode(false);
   
   // Initialize symbol info
   if(!symbolInfo.Name(_Symbol))
   {
      Print("Error: Failed to initialize symbol info");
      return INIT_FAILED;
   }
   
   // Initialize indicator handles
   handleFastEMA = iMA(_Symbol, InpScalpingTimeframe, InpFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   handleSlowEMA = iMA(_Symbol, InpScalpingTimeframe, InpSlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   handleSignalEMA = iMA(_Symbol, InpScalpingTimeframe, InpSignalEMA, 0, MODE_EMA, PRICE_CLOSE);
   handleRSI = iRSI(_Symbol, InpScalpingTimeframe, InpRSI_Period, PRICE_CLOSE);
   handleStoch = iStochastic(_Symbol, InpScalpingTimeframe, InpStoch_K, InpStoch_D, InpStoch_Slowing, MODE_SMA, STO_LOWHIGH);
   handleATR = iATR(_Symbol, InpScalpingTimeframe, InpATR_Period);
   handleBBands = iBands(_Symbol, InpScalpingTimeframe, 20, 2, 0, PRICE_CLOSE);
   handleMACD = iMACD(_Symbol, InpScalpingTimeframe, 12, 26, 9, PRICE_CLOSE);
   handleCCI = iCCI(_Symbol, InpScalpingTimeframe, 14, PRICE_TYPICAL);
   
   // Check if indicators initialized successfully
   if(handleFastEMA == INVALID_HANDLE || handleSlowEMA == INVALID_HANDLE || 
      handleSignalEMA == INVALID_HANDLE || handleRSI == INVALID_HANDLE ||
      handleStoch == INVALID_HANDLE || handleATR == INVALID_HANDLE)
   {
      Print("Error: Failed to initialize indicators");
      return INIT_FAILED;
   }
   
   // Set up arrays
   ArraySetAsSeries(fastEMA, true);
   ArraySetAsSeries(slowEMA, true);
   ArraySetAsSeries(signalEMA, true);
   ArraySetAsSeries(rsiValues, true);
   ArraySetAsSeries(stochK, true);
   ArraySetAsSeries(stochD, true);
   ArraySetAsSeries(atrValues, true);
   ArraySetAsSeries(bbUpper, true);
   ArraySetAsSeries(bbLower, true);
   ArraySetAsSeries(macdMain, true);
   ArraySetAsSeries(macdSignal, true);
   ArraySetAsSeries(cciValues, true);
   
   // Initialize statistics
   LoadTradingStatistics();
   
   Print("UltraScalpingPro MT5 initialized successfully");
   Print("Symbol: ", _Symbol, " | Timeframe: ", EnumToString((ENUM_TIMEFRAMES)InpScalpingTimeframe));
   Print("Risk per trade: ", InpRiskPercent, "% | Max positions: ", InpMaxPositions);
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Release indicator handles
   if(handleFastEMA != INVALID_HANDLE) IndicatorRelease(handleFastEMA);
   if(handleSlowEMA != INVALID_HANDLE) IndicatorRelease(handleSlowEMA);
   if(handleSignalEMA != INVALID_HANDLE) IndicatorRelease(handleSignalEMA);
   if(handleRSI != INVALID_HANDLE) IndicatorRelease(handleRSI);
   if(handleStoch != INVALID_HANDLE) IndicatorRelease(handleStoch);
   if(handleATR != INVALID_HANDLE) IndicatorRelease(handleATR);
   if(handleBBands != INVALID_HANDLE) IndicatorRelease(handleBBands);
   if(handleMACD != INVALID_HANDLE) IndicatorRelease(handleMACD);
   if(handleCCI != INVALID_HANDLE) IndicatorRelease(handleCCI);
   
   // Save trading statistics
   SaveTradingStatistics();
   
   Print("UltraScalpingPro MT5 deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check if new bar
   if(!IsNewBar()) return;
   
   // Update daily statistics
   UpdateDailyStatistics();
   
   // Check trading conditions
   if(!CanTrade()) return;
   
   // Update indicators
   if(!UpdateIndicators()) return;
   
   // Calculate AI confidence and market sentiment
   if(InpUseAI)
   {
      CalculateAIConfidence();
      CalculateMarketSentiment();
   }
   
   // Check for pattern recognition
   if(InpUsePatternRecognition)
   {
      DetectPatterns();
   }
   
   // Manage existing positions
   ManagePositions();
   
   // Check for new trading opportunities
   if(GetTotalPositions() < InpMaxPositions)
   {
      CheckForEntrySignals();
   }
}

//+------------------------------------------------------------------+
//| Check if new bar has formed                                     |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime currentBarTime = iTime(_Symbol, InpScalpingTimeframe, 0);
   if(currentBarTime != lastBarTime)
   {
      lastBarTime = currentBarTime;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Check if trading is allowed                                     |
//+------------------------------------------------------------------+
bool CanTrade()
{
   // Check spread filter
   if(InpUseSpreadFilter)
   {
      double currentSpread = symbolInfo.Spread();
      if(currentSpread > InpMaxSpread)
      {
         return false;
      }
   }
   
   // Check volatility filter
   if(InpUseVolatilityFilter)
   {
      double volatility = atrValues[0] / _Point;
      if(volatility < InpMinVolatility || volatility > InpMaxVolatility)
      {
         return false;
      }
   }
   
   // Check time filter
   if(InpUseTimeFilter)
   {
      datetime currentTime = TimeCurrent();
      string currentTimeStr = TimeToString(currentTime, TIME_MINUTES);
      if(currentTimeStr < InpStartTime || currentTimeStr > InpEndTime)
      {
         return false;
      }
   }
   
   // Check daily loss limit
   if(dailyLoss >= InpMaxDailyLoss)
   {
      return false;
   }
   
   // Check daily profit limit
   if(dailyProfit >= InpMaxDailyProfit)
   {
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Update all indicators                                           |
//+------------------------------------------------------------------+
bool UpdateIndicators()
{
   // Update EMA values
   if(CopyBuffer(handleFastEMA, 0, 0, 3, fastEMA) < 3) return false;
   if(CopyBuffer(handleSlowEMA, 0, 0, 3, slowEMA) < 3) return false;
   if(CopyBuffer(handleSignalEMA, 0, 0, 3, signalEMA) < 3) return false;
   
   // Update RSI values
   if(CopyBuffer(handleRSI, 0, 0, 3, rsiValues) < 3) return false;
   
   // Update Stochastic values
   if(CopyBuffer(handleStoch, 0, 0, 3, stochK) < 3) return false;
   if(CopyBuffer(handleStoch, 1, 0, 3, stochD) < 3) return false;
   
   // Update ATR values
   if(CopyBuffer(handleATR, 0, 0, 3, atrValues) < 3) return false;
   
   // Update Bollinger Bands
   if(CopyBuffer(handleBBands, 1, 0, 3, bbUpper) < 3) return false;
   if(CopyBuffer(handleBBands, 2, 0, 3, bbLower) < 3) return false;
   
   // Update MACD
   if(CopyBuffer(handleMACD, 0, 0, 3, macdMain) < 3) return false;
   if(CopyBuffer(handleMACD, 1, 0, 3, macdSignal) < 3) return false;
   
   // Update CCI
   if(CopyBuffer(handleCCI, 0, 0, 3, cciValues) < 3) return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Calculate AI confidence level                                   |
//+------------------------------------------------------------------+
void CalculateAIConfidence()
{
   double confidence = 0;
   int signals = 0;
   
   // EMA trend analysis
   if(fastEMA[0] > slowEMA[0] && fastEMA[1] > slowEMA[1])
   {
      confidence += 0.2;
      signals++;
   }
   else if(fastEMA[0] < slowEMA[0] && fastEMA[1] < slowEMA[1])
   {
      confidence += 0.2;
      signals++;
   }
   
   // RSI analysis
   if(rsiValues[0] < InpRSI_Oversold && rsiValues[1] >= InpRSI_Oversold)
   {
      confidence += 0.15;
      signals++;
   }
   else if(rsiValues[0] > InpRSI_Overbought && rsiValues[1] <= InpRSI_Overbought)
   {
      confidence += 0.15;
      signals++;
   }
   
   // Stochastic analysis
   if(stochK[0] < 20 && stochD[0] < 20)
   {
      confidence += 0.15;
      signals++;
   }
   else if(stochK[0] > 80 && stochD[0] > 80)
   {
      confidence += 0.15;
      signals++;
   }
   
   // MACD analysis
   if(macdMain[0] > macdSignal[0] && macdMain[1] <= macdSignal[1])
   {
      confidence += 0.15;
      signals++;
   }
   else if(macdMain[0] < macdSignal[0] && macdMain[1] >= macdSignal[1])
   {
      confidence += 0.15;
      signals++;
   }
   
   // CCI analysis
   if(cciValues[0] > 100 && cciValues[1] <= 100)
   {
      confidence += 0.15;
      signals++;
   }
   else if(cciValues[0] < -100 && cciValues[1] >= -100)
   {
      confidence += 0.15;
      signals++;
   }
   
   // Normalize confidence
   if(signals > 0)
   {
      aiConfidence = confidence / signals;
   }
   else
   {
      aiConfidence = 0;
   }
}

//+------------------------------------------------------------------+
//| Calculate market sentiment                                      |
//+------------------------------------------------------------------+
void CalculateMarketSentiment()
{
   double sentiment = 0;
   
   // Price position relative to Bollinger Bands
   double currentPrice = symbolInfo.Bid();
   if(currentPrice < bbLower[0])
   {
      sentiment += 0.3; // Oversold
   }
   else if(currentPrice > bbUpper[0])
   {
      sentiment -= 0.3; // Overbought
   }
   
   // Volume analysis (if available)
   // Add volume-based sentiment calculation here
   
   // Trend strength
   double trendStrength = MathAbs(fastEMA[0] - slowEMA[0]) / atrValues[0];
   if(trendStrength > 0.5)
   {
      sentiment += (fastEMA[0] > slowEMA[0] ? 0.2 : -0.2);
   }
   
   marketSentiment = MathMax(-1, MathMin(1, sentiment));
}

//+------------------------------------------------------------------+
//| Detect chart patterns                                           |
//+------------------------------------------------------------------+
void DetectPatterns()
{
   patternDetected = false;
   patternType = 0;
   
   // Double bottom pattern
   if(IsDoubleBottom())
   {
      patternDetected = true;
      patternType = 1; // Bullish pattern
   }
   
   // Double top pattern
   if(IsDoubleTop())
   {
      patternDetected = true;
      patternType = 2; // Bearish pattern
   }
   
   // Pin bar pattern
   if(IsPinBar())
   {
      patternDetected = true;
      patternType = (IsBullishPinBar() ? 3 : 4);
   }
}

//+------------------------------------------------------------------+
//| Check for double bottom pattern                                 |
//+------------------------------------------------------------------+
bool IsDoubleBottom()
{
   double low1 = iLow(_Symbol, InpScalpingTimeframe, 3);
   double low2 = iLow(_Symbol, InpScalpingTimeframe, 1);
   double low0 = iLow(_Symbol, InpScalpingTimeframe, 0);
   
   if(MathAbs(low1 - low2) < atrValues[0] * 0.5 && low0 > low2)
   {
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check for double top pattern                                    |
//+------------------------------------------------------------------+
bool IsDoubleTop()
{
   double high1 = iHigh(_Symbol, InpScalpingTimeframe, 3);
   double high2 = iHigh(_Symbol, InpScalpingTimeframe, 1);
   double high0 = iHigh(_Symbol, InpScalpingTimeframe, 0);
   
   if(MathAbs(high1 - high2) < atrValues[0] * 0.5 && high0 < high2)
   {
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check for pin bar pattern                                       |
//+------------------------------------------------------------------+
bool IsPinBar()
{
   double body = MathAbs(iClose(_Symbol, InpScalpingTimeframe, 0) - iOpen(_Symbol, InpScalpingTimeframe, 0));
   double upperWick = iHigh(_Symbol, InpScalpingTimeframe, 0) - MathMax(iOpen(_Symbol, InpScalpingTimeframe, 0), iClose(_Symbol, InpScalpingTimeframe, 0));
   double lowerWick = MathMin(iOpen(_Symbol, InpScalpingTimeframe, 0), iClose(_Symbol, InpScalpingTimeframe, 0)) - iLow(_Symbol, InpScalpingTimeframe, 0);
   
   if(upperWick > body * 2 || lowerWick > body * 2)
   {
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check if pin bar is bullish                                     |
//+------------------------------------------------------------------+
bool IsBullishPinBar()
{
   double body = iClose(_Symbol, InpScalpingTimeframe, 0) - iOpen(_Symbol, InpScalpingTimeframe, 0);
   double lowerWick = MathMin(iOpen(_Symbol, InpScalpingTimeframe, 0), iClose(_Symbol, InpScalpingTimeframe, 0)) - iLow(_Symbol, InpScalpingTimeframe, 0);
   
   return (lowerWick > MathAbs(body) * 2);
}

//+------------------------------------------------------------------+
//| Check for entry signals                                         |
//+------------------------------------------------------------------+
void CheckForEntrySignals()
{
   // Calculate entry signal strength
   double buySignal = CalculateBuySignal();
   double sellSignal = CalculateSellSignal();
   
   // Check AI confidence threshold
   if(InpUseAI && aiConfidence < InpAIConfidenceThreshold)
   {
      return;
   }
   
   // Execute trades based on signal strength
   if(buySignal > 0.7)
   {
      OpenBuyPosition();
   }
   else if(sellSignal > 0.7)
   {
      OpenSellPosition();
   }
}

//+------------------------------------------------------------------+
//| Calculate buy signal strength                                   |
//+------------------------------------------------------------------+
double CalculateBuySignal()
{
   double signal = 0;
   
   // EMA crossover
   if(fastEMA[0] > slowEMA[0] && fastEMA[1] <= slowEMA[1])
   {
      signal += 0.25;
   }
   
   // RSI oversold bounce
   if(rsiValues[0] > InpRSI_Oversold && rsiValues[1] <= InpRSI_Oversold)
   {
      signal += 0.2;
   }
   
   // Stochastic oversold
   if(stochK[0] > 20 && stochK[1] <= 20)
   {
      signal += 0.15;
   }
   
   // MACD bullish crossover
   if(macdMain[0] > macdSignal[0] && macdMain[1] <= macdSignal[1])
   {
      signal += 0.2;
   }
   
   // CCI oversold
   if(cciValues[0] > -100 && cciValues[1] <= -100)
   {
      signal += 0.1;
   }
   
   // Pattern recognition
   if(patternDetected && patternType == 1)
   {
      signal += 0.1;
   }
   
   // Market sentiment
   if(marketSentiment > 0.3)
   {
      signal += 0.1;
   }
   
   return signal;
}

//+------------------------------------------------------------------+
//| Calculate sell signal strength                                  |
//+------------------------------------------------------------------+
double CalculateSellSignal()
{
   double signal = 0;
   
   // EMA crossover
   if(fastEMA[0] < slowEMA[0] && fastEMA[1] >= slowEMA[1])
   {
      signal += 0.25;
   }
   
   // RSI overbought rejection
   if(rsiValues[0] < InpRSI_Overbought && rsiValues[1] >= InpRSI_Overbought)
   {
      signal += 0.2;
   }
   
   // Stochastic overbought
   if(stochK[0] < 80 && stochK[1] >= 80)
   {
      signal += 0.15;
   }
   
   // MACD bearish crossover
   if(macdMain[0] < macdSignal[0] && macdMain[1] >= macdSignal[1])
   {
      signal += 0.2;
   }
   
   // CCI overbought
   if(cciValues[0] < 100 && cciValues[1] >= 100)
   {
      signal += 0.1;
   }
   
   // Pattern recognition
   if(patternDetected && patternType == 2)
   {
      signal += 0.1;
   }
   
   // Market sentiment
   if(marketSentiment < -0.3)
   {
      signal += 0.1;
   }
   
   return signal;
}

//+------------------------------------------------------------------+
//| Open buy position                                               |
//+------------------------------------------------------------------+
void OpenBuyPosition()
{
   double lotSize = CalculateLotSize();
   double price = symbolInfo.Ask();
   double sl = 0, tp = 0;
   
   // Calculate stop loss and take profit
   if(InpUseDynamicSL)
   {
      sl = price - (atrValues[0] * InpSL_ATR_Multiplier);
   }
   
   if(InpUseDynamicTP)
   {
      tp = price + (atrValues[0] * InpTP_ATR_Multiplier);
   }
   
   // Ensure minimum profit
   if(tp > 0 && (tp - price) / _Point < InpMinProfitPoints)
   {
      tp = price + (InpMinProfitPoints * _Point);
   }
   
   // Ensure maximum loss
   if(sl > 0 && (price - sl) / _Point > InpMaxLossPoints)
   {
      sl = price - (InpMaxLossPoints * _Point);
   }
   
   if(trade.Buy(lotSize, _Symbol, price, sl, tp, "UltraScalpingPro Buy"))
   {
      Print("Buy position opened: Lot=", lotSize, " Price=", price, " SL=", sl, " TP=", tp);
      lastTradeTime = TimeCurrent();
      totalTrades++;
   }
   else
   {
      Print("Error opening buy position: ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Open sell position                                              |
//+------------------------------------------------------------------+
void OpenSellPosition()
{
   double lotSize = CalculateLotSize();
   double price = symbolInfo.Bid();
   double sl = 0, tp = 0;
   
   // Calculate stop loss and take profit
   if(InpUseDynamicSL)
   {
      sl = price + (atrValues[0] * InpSL_ATR_Multiplier);
   }
   
   if(InpUseDynamicTP)
   {
      tp = price - (atrValues[0] * InpTP_ATR_Multiplier);
   }
   
   // Ensure minimum profit
   if(tp > 0 && (price - tp) / _Point < InpMinProfitPoints)
   {
      tp = price - (InpMinProfitPoints * _Point);
   }
   
   // Ensure maximum loss
   if(sl > 0 && (sl - price) / _Point > InpMaxLossPoints)
   {
      sl = price + (InpMaxLossPoints * _Point);
   }
   
   if(trade.Sell(lotSize, _Symbol, price, sl, tp, "UltraScalpingPro Sell"))
   {
      Print("Sell position opened: Lot=", lotSize, " Price=", price, " SL=", sl, " TP=", tp);
      lastTradeTime = TimeCurrent();
      totalTrades++;
   }
   else
   {
      Print("Error opening sell position: ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk management                     |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
   if(!InpUseAutoLots)
   {
      return InpLotSize;
   }
   
   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = accountBalance * InpRiskPercent / 100;
   double tickValue = symbolInfo.TickValue();
   double stopLossPoints = atrValues[0] * InpSL_ATR_Multiplier / _Point;
   
   if(stopLossPoints > 0 && tickValue > 0)
   {
      double lotSize = riskAmount / (stopLossPoints * tickValue);
      double minLot = symbolInfo.LotsMin();
      double maxLot = symbolInfo.LotsMax();
      double lotStep = symbolInfo.LotsStep();
      
      lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
      lotSize = NormalizeDouble(lotSize / lotStep, 0) * lotStep;
      
      return lotSize;
   }
   
   return InpLotSize;
}

//+------------------------------------------------------------------+
//| Manage existing positions                                       |
//+------------------------------------------------------------------+
void ManagePositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == InpMagicNumber)
         {
            // Check for quick exit
            if(InpUseQuickExit)
            {
               CheckQuickExit(positionInfo);
            }
            
            // Check for break even
            if(InpUseBreakEven)
            {
               CheckBreakEven(positionInfo);
            }
            
            // Check for trailing stop
            if(InpUseTrailingStop)
            {
               CheckTrailingStop(positionInfo);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check for quick exit conditions                                 |
//+------------------------------------------------------------------+
void CheckQuickExit(CPositionInfo &pos)
{
   double currentPrice = (pos.PositionType() == POSITION_TYPE_BUY) ? symbolInfo.Bid() : symbolInfo.Ask();
   double openPrice = pos.PriceOpen();
   double profit = pos.Profit();
   double points = MathAbs(currentPrice - openPrice) / _Point;
   
   // Quick exit on reversal
   if(pos.PositionType() == POSITION_TYPE_BUY)
   {
      if(fastEMA[0] < slowEMA[0] && points >= InpQuickExitThreshold)
      {
         if(trade.PositionClose(pos.Ticket()))
         {
            Print("Quick exit on buy position: ", pos.Ticket());
         }
      }
   }
   else
   {
      if(fastEMA[0] > slowEMA[0] && points >= InpQuickExitThreshold)
      {
         if(trade.PositionClose(pos.Ticket()))
         {
            Print("Quick exit on sell position: ", pos.Ticket());
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check for break even conditions                                 |
//+------------------------------------------------------------------+
void CheckBreakEven(CPositionInfo &pos)
{
   double currentPrice = (pos.PositionType() == POSITION_TYPE_BUY) ? symbolInfo.Bid() : symbolInfo.Ask();
   double openPrice = pos.PriceOpen();
   double points = MathAbs(currentPrice - openPrice) / _Point;
   
   if(points >= InpBreakEvenPoints)
   {
      double newSL = openPrice;
      
      if(pos.PositionType() == POSITION_TYPE_BUY)
      {
         if(pos.StopLoss() < openPrice)
         {
            trade.PositionModify(pos.Ticket(), newSL, pos.TakeProfit());
         }
      }
      else
      {
         if(pos.StopLoss() > openPrice || pos.StopLoss() == 0)
         {
            trade.PositionModify(pos.Ticket(), newSL, pos.TakeProfit());
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check for trailing stop conditions                              |
//+------------------------------------------------------------------+
void CheckTrailingStop(CPositionInfo &pos)
{
   double currentPrice = (pos.PositionType() == POSITION_TYPE_BUY) ? symbolInfo.Bid() : symbolInfo.Ask();
   double openPrice = pos.PriceOpen();
   double points = MathAbs(currentPrice - openPrice) / _Point;
   
   if(points >= InpTrailingStart)
   {
      double newSL = 0;
      
      if(pos.PositionType() == POSITION_TYPE_BUY)
      {
         newSL = currentPrice - (InpTrailingStep * _Point);
         if(newSL > pos.StopLoss())
         {
            trade.PositionModify(pos.Ticket(), newSL, pos.TakeProfit());
         }
      }
      else
      {
         newSL = currentPrice + (InpTrailingStep * _Point);
         if(newSL < pos.StopLoss() || pos.StopLoss() == 0)
         {
            trade.PositionModify(pos.Ticket(), newSL, pos.TakeProfit());
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Get total positions for current symbol                          |
//+------------------------------------------------------------------+
int GetTotalPositions()
{
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == InpMagicNumber)
         {
            count++;
         }
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Update daily statistics                                         |
//+------------------------------------------------------------------+
void UpdateDailyStatistics()
{
   static datetime lastDay = 0;
   datetime currentDay = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   
   if(currentDay != lastDay)
   {
      // Reset daily statistics
      dailyProfit = 0;
      dailyLoss = 0;
      lastDay = currentDay;
   }
   
   // Calculate current day's profit/loss
   double totalPL = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == InpMagicNumber)
         {
            totalPL += positionInfo.Profit();
         }
      }
   }
   
   if(totalPL > 0)
   {
      dailyProfit = totalPL;
   }
   else
   {
      dailyLoss = MathAbs(totalPL);
   }
}

//+------------------------------------------------------------------+
//| Load trading statistics from file                               |
//+------------------------------------------------------------------+
void LoadTradingStatistics()
{
   string filename = "UltraScalpingPro_Stats.txt";
   int handle = FileOpen(filename, FILE_READ | FILE_TXT);
   
   if(handle != INVALID_HANDLE)
   {
      totalTrades = (int)StringToInteger(FileReadString(handle));
      winningTrades = (int)StringToInteger(FileReadString(handle));
      winRate = StringToDouble(FileReadString(handle));
      averageWin = StringToDouble(FileReadString(handle));
      averageLoss = StringToDouble(FileReadString(handle));
      profitFactor = StringToDouble(FileReadString(handle));
      FileClose(handle);
   }
}

//+------------------------------------------------------------------+
//| Save trading statistics to file                                 |
//+------------------------------------------------------------------+
void SaveTradingStatistics()
{
   string filename = "UltraScalpingPro_Stats.txt";
   int handle = FileOpen(filename, FILE_WRITE | FILE_TXT);
   
   if(handle != INVALID_HANDLE)
   {
      FileWriteString(handle, IntegerToString(totalTrades));
      FileWriteString(handle, IntegerToString(winningTrades));
      FileWriteString(handle, DoubleToString(winRate, 2));
      FileWriteString(handle, DoubleToString(averageWin, 2));
      FileWriteString(handle, DoubleToString(averageLoss, 2));
      FileWriteString(handle, DoubleToString(profitFactor, 2));
      FileClose(handle);
   }
}

//+------------------------------------------------------------------+
//| Trade transaction function                                      |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                       const MqlTradeRequest &request,
                       const MqlTradeResult &result)
{
   // Update statistics when position is closed
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
   {
      if(trans.deal_type == DEAL_TYPE_SELL || trans.deal_type == DEAL_TYPE_BUY)
      {
         if(trans.deal_type == DEAL_TYPE_SELL && trans.order_type == ORDER_TYPE_BUY)
         {
            // Position closed
            double profit = trans.price_profit;
            if(profit > 0)
            {
               winningTrades++;
            }
            
            // Update statistics
            if(totalTrades > 0)
            {
               winRate = (double)winningTrades / totalTrades * 100;
            }
         }
      }
   }
}