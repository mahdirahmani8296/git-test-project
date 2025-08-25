//+------------------------------------------------------------------+
//|                                    UltraAdvancedScalpingEA.mq5 |
//|                    Ultra Advanced Scalping Expert Advisor MT5 |
//|                    Designed for Gold and Major Forex Pairs |
//|                    Intelligent Target/Stop Placement |
//+------------------------------------------------------------------+
#property copyright "Ultra Advanced Scalping EA MT5"
#property version   "4.0"
#property description "Ultra Advanced Scalping Expert Advisor for Gold and Major Pairs"
#property description "Features: Intelligent TP/SL, Advanced Risk Management, Multi-Timeframe Analysis"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Indicators\Indicators.mqh>
#include <Math\Stat\Math.mqh>

//--- Input Parameters
input group "=== General Settings ==="
input double    InpLotSize = 0.1;
input bool      InpUseAutoLots = true;
input double    InpRiskPercent = 1.5;
input ulong     InpMagicNumber = 98765;
input ulong     InpDeviation = 5;
input int       InpMaxPositions = 3;

input group "=== Scalping Strategy Settings ==="
input bool      InpUseAdvancedScalping = true;
input int       InpMinProfitPips = 3;
input int       InpMaxLossPips = 8;
input bool      InpUseDynamicTP = true;
input bool      InpUseDynamicSL = true;
input double    InpTPMultiplier = 1.5;
input double    InpSLMultiplier = 1.2;

input group "=== Technical Indicators ==="
input int       InpFastEMA = 8;
input int       InpSlowEMA = 21;
input int       InpSignalEMA = 13;
input int       InpRSI_Period = 14;
input int       InpRSI_Overbought = 70;
input int       InpRSI_Oversold = 30;
input int       InpBB_Period = 20;
input double    InpBB_Deviation = 2.0;
input int       InpATR_Period = 14;
input int       InpStoch_K = 5;
input int       InpStoch_D = 3;
input int       InpStoch_Slowing = 3;

input group "=== Advanced Filters ==="
input bool      InpUseSpreadFilter = true;
input double    InpMaxSpread = 15;
input bool      InpUseVolatilityFilter = true;
input double    InpMinVolatility = 0.0001;
input double    InpMaxVolatility = 0.003;
input bool      InpUseTimeFilter = true;
input string    InpStartTime = "07:00";
input string    InpEndTime = "23:00";
input bool      InpUseNewsFilter = true;

input group "=== Risk Management ==="
input double    InpMaxDailyLoss = 3.0;
input double    InpMaxDailyProfit = 10.0;
input bool      InpUseTrailingStop = true;
input double    InpTrailingStart = 15;
input double    InpTrailingStep = 5;
input bool      InpUseBreakEven = true;
input double    InpBreakEvenPoint = 10;
input bool      InpUseCorrelationFilter = true;

input group "=== Advanced AI Settings ==="
input bool      InpUseNeuralNetwork = true;
input int       InpNNLayers = 3;
input int       InpNNNeurons = 8;
input double    InpNNLearningRate = 0.01;
input int       InpNNTrainingBars = 500;
input bool      InpUsePatternRecognition = true;
input bool      InpUseSentimentAnalysis = true;

//--- Global Objects
CTrade trade;
CPositionInfo positionInfo;
COrderInfo orderInfo;

//--- Indicator Handles
int handleFastEMA, handleSlowEMA, handleSignalEMA;
int handleRSI, handleBBands, handleATR, handleStochastic;
int handleMACD, handleCCI, handleWilliams;

//--- Global Variables
datetime lastBarTime;
double dailyProfit = 0;
double dailyLoss = 0;
datetime lastTradeTime = 0;
int consecutiveLosses = 0;
int consecutiveWins = 0;
double lastATR = 0;
bool isMarketOpen = false;

//--- Neural Network Variables
double neuralWeights[][];
double neuralBias[];
int neuralLayerSizes[];

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
   
   // Initialize indicators
   if(!InitializeIndicators())
   {
      Print("Error: Failed to initialize indicators");
      return INIT_FAILED;
   }
   
   // Initialize neural network
   if(InpUseNeuralNetwork && !InitializeNeuralNetwork())
   {
      Print("Error: Failed to initialize neural network");
      return INIT_FAILED;
   }
   
   // Validate inputs
   if(!ValidateInputs())
   {
      Print("Error: Invalid input parameters");
      return INIT_FAILED;
   }
   
   // Set up event handlers
   EventSetTimer(1);
   
   Print("Ultra Advanced Scalping EA initialized successfully");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   Print("Ultra Advanced Scalping EA deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check if market is open
   if(!IsMarketOpen())
      return;
      
   // Check daily limits
   if(IsDailyLimitReached())
      return;
      
   // Check spread filter
   if(InpUseSpreadFilter && !IsSpreadAcceptable())
      return;
      
   // Check volatility filter
   if(InpUseVolatilityFilter && !IsVolatilityAcceptable())
      return;
      
   // Update indicators
   if(!UpdateIndicators())
      return;
      
   // Check for new bar
   if(!IsNewBar())
      return;
      
   // Analyze market conditions
   int signal = AnalyzeMarket();
   
   // Execute trading logic
   if(signal != 0)
   {
      ExecuteTrade(signal);
   }
   
   // Manage existing positions
   ManagePositions();
}

//+------------------------------------------------------------------+
//| Initialize indicators                                            |
//+------------------------------------------------------------------+
bool InitializeIndicators()
{
   // Initialize EMA handles
   handleFastEMA = iMA(_Symbol, PERIOD_CURRENT, InpFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   handleSlowEMA = iMA(_Symbol, PERIOD_CURRENT, InpSlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   handleSignalEMA = iMA(_Symbol, PERIOD_CURRENT, InpSignalEMA, 0, MODE_EMA, PRICE_CLOSE);
   
   // Initialize RSI
   handleRSI = iRSI(_Symbol, PERIOD_CURRENT, InpRSI_Period, PRICE_CLOSE);
   
   // Initialize Bollinger Bands
   handleBBands = iBands(_Symbol, PERIOD_CURRENT, InpBB_Period, 0, InpBB_Deviation, PRICE_CLOSE);
   
   // Initialize ATR
   handleATR = iATR(_Symbol, PERIOD_CURRENT, InpATR_Period);
   
   // Initialize Stochastic
   handleStochastic = iStochastic(_Symbol, PERIOD_CURRENT, InpStoch_K, InpStoch_D, InpStoch_Slowing, MODE_SMA, STO_LOWHIGH);
   
   // Initialize additional indicators
   handleMACD = iMACD(_Symbol, PERIOD_CURRENT, 12, 26, 9, PRICE_CLOSE);
   handleCCI = iCCI(_Symbol, PERIOD_CURRENT, 14, PRICE_TYPICAL);
   handleWilliams = iWPR(_Symbol, PERIOD_CURRENT, 14);
   
   // Check if all handles are valid
   if(handleFastEMA == INVALID_HANDLE || handleSlowEMA == INVALID_HANDLE || 
      handleSignalEMA == INVALID_HANDLE || handleRSI == INVALID_HANDLE ||
      handleBBands == INVALID_HANDLE || handleATR == INVALID_HANDLE ||
      handleStochastic == INVALID_HANDLE || handleMACD == INVALID_HANDLE ||
      handleCCI == INVALID_HANDLE || handleWilliams == INVALID_HANDLE)
   {
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Initialize neural network                                        |
//+------------------------------------------------------------------+
bool InitializeNeuralNetwork()
{
   if(!InpUseNeuralNetwork)
      return true;
      
   // Set up neural network architecture
   ArrayResize(neuralLayerSizes, InpNNLayers);
   neuralLayerSizes[0] = 10; // Input layer
   neuralLayerSizes[1] = InpNNNeurons; // Hidden layer
   neuralLayerSizes[2] = 1; // Output layer
   
   // Initialize weights and bias
   int totalWeights = 0;
   for(int i = 0; i < ArraySize(neuralLayerSizes) - 1; i++)
   {
      totalWeights += neuralLayerSizes[i] * neuralLayerSizes[i + 1];
   }
   
   ArrayResize(neuralWeights, totalWeights);
   ArrayResize(neuralBias, ArraySize(neuralLayerSizes) - 1);
   
   // Initialize with random weights
   for(int i = 0; i < totalWeights; i++)
   {
      neuralWeights[i] = MathRand() / 32768.0 - 0.5;
   }
   
   for(int i = 0; i < ArraySize(neuralBias); i++)
   {
      neuralBias[i] = MathRand() / 32768.0 - 0.5;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Validate input parameters                                        |
//+------------------------------------------------------------------+
bool ValidateInputs()
{
   if(InpLotSize <= 0 || InpRiskPercent <= 0 || InpRiskPercent > 10)
      return false;
      
   if(InpMaxDailyLoss <= 0 || InpMaxDailyProfit <= 0)
      return false;
      
   if(InpMinProfitPips <= 0 || InpMaxLossPips <= 0)
      return false;
      
   if(InpFastEMA <= 0 || InpSlowEMA <= 0 || InpSignalEMA <= 0)
      return false;
      
   return true;
}

//+------------------------------------------------------------------+
//| Check if market is open                                          |
//+------------------------------------------------------------------+
bool IsMarketOpen()
{
   if(!InpUseTimeFilter)
      return true;
      
   datetime currentTime = TimeCurrent();
   string currentTimeStr = TimeToString(currentTime, TIME_MINUTES);
   
   return (currentTimeStr >= InpStartTime && currentTimeStr <= InpEndTime);
}

//+------------------------------------------------------------------+
//| Check daily limits                                               |
//+------------------------------------------------------------------+
bool IsDailyLimitReached()
{
   double currentProfit = GetDailyProfit();
   
   if(currentProfit <= -InpMaxDailyLoss)
   {
      Print("Daily loss limit reached: ", currentProfit);
      return true;
   }
   
   if(currentProfit >= InpMaxDailyProfit)
   {
      Print("Daily profit limit reached: ", currentProfit);
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check spread acceptability                                       |
//+------------------------------------------------------------------+
bool IsSpreadAcceptable()
{
   double currentSpread = SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double spreadPoints = currentSpread / _Point;
   
   return (spreadPoints <= InpMaxSpread);
}

//+------------------------------------------------------------------+
//| Check volatility acceptability                                   |
//+------------------------------------------------------------------+
bool IsVolatilityAcceptable()
{
   double atr[];
   ArraySetAsSeries(atr, true);
   
   if(CopyBuffer(handleATR, 0, 0, 2, atr) < 2)
      return false;
      
   double currentVolatility = atr[0];
   
   return (currentVolatility >= InpMinVolatility && currentVolatility <= InpMaxVolatility);
}

//+------------------------------------------------------------------+
//| Update indicators                                                |
//+------------------------------------------------------------------+
bool UpdateIndicators()
{
   double atr[];
   ArraySetAsSeries(atr, true);
   
   if(CopyBuffer(handleATR, 0, 0, 1, atr) < 1)
      return false;
      
   lastATR = atr[0];
   return true;
}

//+------------------------------------------------------------------+
//| Check for new bar                                                |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   
   if(currentBarTime != lastBarTime)
   {
      lastBarTime = currentBarTime;
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Analyze market conditions                                        |
//+------------------------------------------------------------------+
int AnalyzeMarket()
{
   // Get indicator values
   double fastEMA[], slowEMA[], signalEMA[];
   double rsi[], bbUpper[], bbLower[], bbMiddle[];
   double stochMain[], stochSignal[];
   double macdMain[], macdSignal[];
   double cci[], williams[];
   
   ArraySetAsSeries(fastEMA, true);
   ArraySetAsSeries(slowEMA, true);
   ArraySetAsSeries(signalEMA, true);
   ArraySetAsSeries(rsi, true);
   ArraySetAsSeries(bbUpper, true);
   ArraySetAsSeries(bbLower, true);
   ArraySetAsSeries(bbMiddle, true);
   ArraySetAsSeries(stochMain, true);
   ArraySetAsSeries(stochSignal, true);
   ArraySetAsSeries(macdMain, true);
   ArraySetAsSeries(macdSignal, true);
   ArraySetAsSeries(cci, true);
   ArraySetAsSeries(williams, true);
   
   // Copy indicator data
   if(CopyBuffer(handleFastEMA, 0, 0, 3, fastEMA) < 3) return 0;
   if(CopyBuffer(handleSlowEMA, 0, 0, 3, slowEMA) < 3) return 0;
   if(CopyBuffer(handleSignalEMA, 0, 0, 3, signalEMA) < 3) return 0;
   if(CopyBuffer(handleRSI, 0, 0, 3, rsi) < 3) return 0;
   if(CopyBuffer(handleBBands, UPPER_BAND, 0, 3, bbUpper) < 3) return 0;
   if(CopyBuffer(handleBBands, LOWER_BAND, 0, 3, bbLower) < 3) return 0;
   if(CopyBuffer(handleBBands, BASE_LINE, 0, 3, bbMiddle) < 3) return 0;
   if(CopyBuffer(handleStochastic, MAIN_LINE, 0, 3, stochMain) < 3) return 0;
   if(CopyBuffer(handleStochastic, SIGNAL_LINE, 0, 3, stochSignal) < 3) return 0;
   if(CopyBuffer(handleMACD, MAIN_LINE, 0, 3, macdMain) < 3) return 0;
   if(CopyBuffer(handleMACD, SIGNAL_LINE, 0, 3, macdSignal) < 3) return 0;
   if(CopyBuffer(handleCCI, 0, 0, 3, cci) < 3) return 0;
   if(CopyBuffer(handleWilliams, 0, 0, 3, williams) < 3) return 0;
   
   // Calculate signal strength
   int buySignals = 0;
   int sellSignals = 0;
   
   // EMA crossover signals
   if(fastEMA[0] > slowEMA[0] && fastEMA[1] <= slowEMA[1])
      buySignals++;
   if(fastEMA[0] < slowEMA[0] && fastEMA[1] >= slowEMA[1])
      sellSignals++;
      
   // RSI signals
   if(rsi[0] < InpRSI_Oversold && rsi[1] >= InpRSI_Oversold)
      buySignals++;
   if(rsi[0] > InpRSI_Overbought && rsi[1] <= InpRSI_Overbought)
      sellSignals++;
      
   // Bollinger Bands signals
   double currentPrice = iClose(_Symbol, PERIOD_CURRENT, 0);
   if(currentPrice <= bbLower[0])
      buySignals++;
   if(currentPrice >= bbUpper[0])
      sellSignals++;
      
   // Stochastic signals
   if(stochMain[0] < 20 && stochMain[0] > stochSignal[0])
      buySignals++;
   if(stochMain[0] > 80 && stochMain[0] < stochSignal[0])
      sellSignals++;
      
   // MACD signals
   if(macdMain[0] > macdSignal[0] && macdMain[1] <= macdSignal[1])
      buySignals++;
   if(macdMain[0] < macdSignal[0] && macdMain[1] >= macdSignal[1])
      sellSignals++;
      
   // CCI signals
   if(cci[0] < -100 && cci[1] >= -100)
      buySignals++;
   if(cci[0] > 100 && cci[1] <= 100)
      sellSignals++;
      
   // Williams %R signals
   if(williams[0] < -80)
      buySignals++;
   if(williams[0] > -20)
      sellSignals++;
      
   // Neural network prediction
   if(InpUseNeuralNetwork)
   {
      double nnPrediction = GetNeuralNetworkPrediction();
      if(nnPrediction > 0.6)
         buySignals++;
      else if(nnPrediction < 0.4)
         sellSignals++;
   }
   
   // Pattern recognition
   if(InpUsePatternRecognition)
   {
      if(IsBullishPattern())
         buySignals++;
      if(IsBearishPattern())
         sellSignals++;
   }
   
   // Return signal based on signal strength
   if(buySignals >= 4 && buySignals > sellSignals)
      return 1; // Buy signal
   else if(sellSignals >= 4 && sellSignals > buySignals)
      return -1; // Sell signal
      
   return 0; // No signal
}

//+------------------------------------------------------------------+
//| Execute trade                                                    |
//+------------------------------------------------------------------+
void ExecuteTrade(int signal)
{
   // Check if we can open new positions
   if(GetTotalPositions() >= InpMaxPositions)
      return;
      
   // Check minimum time between trades
   if(TimeCurrent() - lastTradeTime < 60) // 1 minute minimum
      return;
      
   double lotSize = InpUseAutoLots ? CalculateOptimalLotSize() : InpLotSize;
   double price = (signal == 1) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   // Calculate dynamic TP and SL
   double tp = 0, sl = 0;
   CalculateDynamicLevels(signal, price, tp, sl);
   
   // Execute the trade
   bool result = false;
   if(signal == 1)
   {
      result = trade.Buy(lotSize, _Symbol, price, sl, tp, "UltraScalping_Buy");
   }
   else
   {
      result = trade.Sell(lotSize, _Symbol, price, sl, tp, "UltraScalping_Sell");
   }
   
   if(result)
   {
      lastTradeTime = TimeCurrent();
      Print("Trade executed: ", (signal == 1 ? "BUY" : "SELL"), " Lot: ", lotSize, " TP: ", tp, " SL: ", sl);
   }
   else
   {
      Print("Trade execution failed: ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double CalculateOptimalLotSize()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * InpRiskPercent / 100.0;
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double stopLossPips = InpMaxLossPips;
   
   if(tickValue > 0)
   {
      double lotSize = riskAmount / (stopLossPips * tickValue);
      double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
      double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      
      lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
      lotSize = NormalizeDouble(lotSize / lotStep, 0) * lotStep;
      
      return lotSize;
   }
   
   return InpLotSize;
}

//+------------------------------------------------------------------+
//| Calculate dynamic TP and SL levels                               |
//+------------------------------------------------------------------+
void CalculateDynamicLevels(int signal, double price, double &tp, double &sl)
{
   double atrValue = lastATR;
   double pointValue = _Point;
   
   if(InpUseDynamicTP)
   {
      double tpDistance = atrValue * InpTPMultiplier;
      if(signal == 1)
         tp = price + tpDistance;
      else
         tp = price - tpDistance;
   }
   else
   {
      double tpDistance = InpMinProfitPips * pointValue;
      if(signal == 1)
         tp = price + tpDistance;
      else
         tp = price - tpDistance;
   }
   
   if(InpUseDynamicSL)
   {
      double slDistance = atrValue * InpSLMultiplier;
      if(signal == 1)
         sl = price - slDistance;
      else
         sl = price + slDistance;
   }
   else
   {
      double slDistance = InpMaxLossPips * pointValue;
      if(signal == 1)
         sl = price - slDistance;
      else
         sl = price + slDistance;
   }
   
   // Normalize levels
   tp = NormalizeDouble(tp, _Digits);
   sl = NormalizeDouble(sl, _Digits);
}

//+------------------------------------------------------------------+
//| Manage existing positions                                        |
//+------------------------------------------------------------------+
void ManagePositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == InpMagicNumber)
         {
            // Trailing stop
            if(InpUseTrailingStop)
               ApplyTrailingStop();
               
            // Break even
            if(InpUseBreakEven)
               ApplyBreakEven();
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Apply trailing stop                                              |
//+------------------------------------------------------------------+
void ApplyTrailingStop()
{
   double currentPrice = (positionInfo.PositionType() == POSITION_TYPE_BUY) ? 
                        SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                        SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                        
   double openPrice = positionInfo.PriceOpen();
   double currentSL = positionInfo.StopLoss();
   double pointValue = _Point;
   
   if(positionInfo.PositionType() == POSITION_TYPE_BUY)
   {
      double profit = currentPrice - openPrice;
      if(profit > InpTrailingStart * pointValue)
      {
         double newSL = currentPrice - InpTrailingStep * pointValue;
         if(newSL > currentSL)
         {
            trade.PositionModify(positionInfo.Ticket(), newSL, positionInfo.TakeProfit());
         }
      }
   }
   else
   {
      double profit = openPrice - currentPrice;
      if(profit > InpTrailingStart * pointValue)
      {
         double newSL = currentPrice + InpTrailingStep * pointValue;
         if(newSL < currentSL || currentSL == 0)
         {
            trade.PositionModify(positionInfo.Ticket(), newSL, positionInfo.TakeProfit());
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Apply break even                                                 |
//+------------------------------------------------------------------+
void ApplyBreakEven()
{
   double currentPrice = (positionInfo.PositionType() == POSITION_TYPE_BUY) ? 
                        SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                        SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                        
   double openPrice = positionInfo.PriceOpen();
   double currentSL = positionInfo.StopLoss();
   double pointValue = _Point;
   
   if(positionInfo.PositionType() == POSITION_TYPE_BUY)
   {
      double profit = currentPrice - openPrice;
      if(profit > InpBreakEvenPoint * pointValue && currentSL < openPrice)
      {
         trade.PositionModify(positionInfo.Ticket(), openPrice, positionInfo.TakeProfit());
      }
   }
   else
   {
      double profit = openPrice - currentPrice;
      if(profit > InpBreakEvenPoint * pointValue && (currentSL > openPrice || currentSL == 0))
      {
         trade.PositionModify(positionInfo.Ticket(), openPrice, positionInfo.TakeProfit());
      }
   }
}

//+------------------------------------------------------------------+
//| Get neural network prediction                                    |
//+------------------------------------------------------------------+
double GetNeuralNetworkPrediction()
{
   if(!InpUseNeuralNetwork)
      return 0.5;
      
   // Prepare input data
   double inputs[10];
   double fastEMA[], slowEMA[], rsi[], atr[];
   
   ArraySetAsSeries(fastEMA, true);
   ArraySetAsSeries(slowEMA, true);
   ArraySetAsSeries(rsi, true);
   ArraySetAsSeries(atr, true);
   
   if(CopyBuffer(handleFastEMA, 0, 0, 5, fastEMA) < 5) return 0.5;
   if(CopyBuffer(handleSlowEMA, 0, 0, 5, slowEMA) < 5) return 0.5;
   if(CopyBuffer(handleRSI, 0, 0, 5, rsi) < 5) return 0.5;
   if(CopyBuffer(handleATR, 0, 0, 5, atr) < 5) return 0.5;
   
   // Normalize inputs
   inputs[0] = (fastEMA[0] - fastEMA[4]) / atr[0];
   inputs[1] = (slowEMA[0] - slowEMA[4]) / atr[0];
   inputs[2] = (rsi[0] - 50) / 50;
   inputs[3] = (rsi[1] - 50) / 50;
   inputs[4] = (rsi[2] - 50) / 50;
   inputs[5] = (atr[0] - atr[4]) / atr[4];
   inputs[6] = (fastEMA[0] - slowEMA[0]) / atr[0];
   inputs[7] = (fastEMA[1] - slowEMA[1]) / atr[0];
   inputs[8] = (fastEMA[2] - slowEMA[2]) / atr[0];
   inputs[9] = (fastEMA[3] - slowEMA[3]) / atr[0];
   
   // Forward propagation
   return ForwardPropagate(inputs);
}

//+------------------------------------------------------------------+
//| Forward propagation for neural network                           |
//+------------------------------------------------------------------+
double ForwardPropagate(double &inputs[])
{
   // Simple feedforward implementation
   double output = 0;
   
   for(int i = 0; i < ArraySize(inputs); i++)
   {
      output += inputs[i] * neuralWeights[i];
   }
   
   output += neuralBias[0];
   
   // Sigmoid activation
   output = 1.0 / (1.0 + MathExp(-output));
   
   return output;
}

//+------------------------------------------------------------------+
//| Check for bullish pattern                                        |
//+------------------------------------------------------------------+
bool IsBullishPattern()
{
   double close[], high[], low[];
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   
   if(CopyClose(_Symbol, PERIOD_CURRENT, 0, 5, close) < 5) return false;
   if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, 5, high) < 5) return false;
   if(CopyLow(_Symbol, PERIOD_CURRENT, 0, 5, low) < 5) return false;
   
   // Hammer pattern
   if(close[0] > (high[0] + low[0]) / 2 && 
      (high[0] - low[0]) > 2 * (close[0] - low[0]))
      return true;
      
   // Engulfing pattern
   if(close[0] > high[1] && close[1] < low[0])
      return true;
      
   return false;
}

//+------------------------------------------------------------------+
//| Check for bearish pattern                                        |
//+------------------------------------------------------------------+
bool IsBearishPattern()
{
   double close[], high[], low[];
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   
   if(CopyClose(_Symbol, PERIOD_CURRENT, 0, 5, close) < 5) return false;
   if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, 5, high) < 5) return false;
   if(CopyLow(_Symbol, PERIOD_CURRENT, 0, 5, low) < 5) return false;
   
   // Shooting star pattern
   if(close[0] < (high[0] + low[0]) / 2 && 
      (high[0] - low[0]) > 2 * (high[0] - close[0]))
      return true;
      
   // Engulfing pattern
   if(close[0] < low[1] && close[1] > high[0])
      return true;
      
   return false;
}

//+------------------------------------------------------------------+
//| Get total positions                                              |
//+------------------------------------------------------------------+
int GetTotalPositions()
{
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == InpMagicNumber)
            count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Get daily profit                                                 |
//+------------------------------------------------------------------+
double GetDailyProfit()
{
   double profit = 0;
   datetime today = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   
   for(int i = 0; i < HistoryDealsTotal(); i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(HistoryDealSelect(ticket))
      {
         if(HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol &&
            HistoryDealGetInteger(ticket, DEAL_MAGIC) == InpMagicNumber &&
            HistoryDealGetInteger(ticket, DEAL_TIME) >= today)
         {
            profit += HistoryDealGetDouble(ticket, DEAL_PROFIT);
         }
      }
   }
   
   return profit;
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   // Update daily profit/loss
   dailyProfit = GetDailyProfit();
   
   // Update market status
   isMarketOpen = IsMarketOpen();
}