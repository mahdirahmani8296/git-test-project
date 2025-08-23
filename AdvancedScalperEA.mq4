//+------------------------------------------------------------------+
//|                                              AdvancedScalperEA.mq4 |
//|                                  Copyright 2024, Advanced Trading |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Advanced Trading"
#property link      "https://www.mql5.com"
#property version   "2.00"
#property strict

//--- Input Parameters
input double   LotSize = 0.1;           // Lot Size
input int      MagicNumber = 12345;     // Magic Number
input int      Slippage = 3;            // Slippage
input bool     UseTrailingStop = true;  // Use Trailing Stop
input double   TrailingStop = 20;       // Trailing Stop (points)
input double   TrailingStep = 5;        // Trailing Step (points)

// Risk Management
input double   MaxRiskPercent = 2.0;    // Maximum Risk per Trade (%)
input double   MaxDailyLoss = 5.0;      // Maximum Daily Loss (%)
input double   MinProfitRatio = 1.5;    // Minimum Profit/Loss Ratio

// Indicator Parameters
input int      RSI_Period = 14;         // RSI Period
input int      RSI_Overbought = 70;     // RSI Overbought Level
input int      RSI_Oversold = 30;       // RSI Oversold Level

input int      MACD_Fast = 12;          // MACD Fast EMA
input int      MACD_Slow = 26;          // MACD Slow EMA
input int      MACD_Signal = 9;         // MACD Signal Line

input int      BB_Period = 20;          // Bollinger Bands Period
input double   BB_Deviation = 2.0;      // Bollinger Bands Deviation

input int      Stoch_K = 14;            // Stochastic %K Period
input int      Stoch_D = 3;             // Stochastic %D Period
input int      Stoch_Slowing = 3;       // Stochastic Slowing

// Time Filters
input int      StartHour = 8;           // Trading Start Hour
input int      EndHour = 20;            // Trading End Hour
input bool     AvoidNews = true;        // Avoid News Time

// Global Variables
double g_prevBalance = 0;
datetime g_lastTradeTime = 0;
int g_dailyTrades = 0;
double g_dailyProfit = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   g_prevBalance = AccountBalance();
   g_lastTradeTime = 0;
   g_dailyTrades = 0;
   g_dailyProfit = 0;
   
   Print("Advanced Scalper EA Initialized Successfully");
   Print("Account Balance: ", AccountBalance());
   Print("Account Currency: ", AccountCurrency());
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("Advanced Scalper EA Deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                           |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check if we can trade
   if(!CanTrade()) return;
   
   // Check daily loss limit
   if(CheckDailyLoss()) return;
   
   // Check for open positions
   if(CountOpenPositions() > 0)
   {
      ManageOpenPositions();
      return;
   }
   
   // Look for new trading opportunities
   AnalyzeMarket();
}

//+------------------------------------------------------------------+
//| Check if trading is allowed                                    |
//+------------------------------------------------------------------+
bool CanTrade()
{
   // Check if market is closed
   if(!IsTradeAllowed()) return false;
   
   // Check trading hours
   int currentHour = TimeHour(TimeCurrent());
   if(currentHour < StartHour || currentHour >= EndHour) return false;
   
   // Check if we have enough free margin
   if(AccountFreeMargin() < 1000) return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Check daily loss limit                                         |
//+------------------------------------------------------------------+
bool CheckDailyLoss()
{
   static datetime lastCheck = 0;
   datetime currentTime = TimeCurrent();
   
   // Check once per day
   if(TimeDay(currentTime) != TimeDay(lastCheck))
   {
      g_dailyTrades = 0;
      g_dailyProfit = 0;
      lastCheck = currentTime;
   }
   
   double dailyLossPercent = (g_dailyProfit / g_prevBalance) * 100;
   if(dailyLossPercent <= -MaxDailyLoss)
   {
      Print("Daily loss limit reached: ", dailyLossPercent, "%");
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Count open positions                                           |
//+------------------------------------------------------------------+
int CountOpenPositions()
{
   int count = 0;
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            count++;
         }
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Manage open positions                                          |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            // Update trailing stop
            if(UseTrailingStop)
            {
               UpdateTrailingStop(OrderTicket());
            }
            
            // Check if position should be closed based on indicators
            if(ShouldClosePosition(OrderType()))
            {
               ClosePosition(OrderTicket());
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Update trailing stop                                            |
//+------------------------------------------------------------------+
void UpdateTrailingStop(int ticket)
{
   if(!OrderSelect(ticket, SELECT_BY_TICKET)) return;
   
   double currentSL = OrderStopLoss();
   double newSL = 0;
   
   if(OrderType() == OP_BUY)
   {
      newSL = Bid - TrailingStop * Point;
      if(newSL > currentSL + TrailingStep * Point)
      {
         if(OrderModify(ticket, OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrBlue))
         {
            Print("Trailing stop updated for BUY order: ", newSL);
         }
      }
   }
   else if(OrderType() == OP_SELL)
   {
      newSL = Ask + TrailingStop * Point;
      if(newSL < currentSL - TrailingStep * Point || currentSL == 0)
      {
         if(OrderModify(ticket, OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrRed))
         {
            Print("Trailing stop updated for SELL order: ", newSL);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check if position should be closed                             |
//+------------------------------------------------------------------+
bool ShouldClosePosition(int orderType)
{
   double rsi = iRSI(Symbol(), 0, RSI_Period, PRICE_CLOSE, 0);
   double macd = iMACD(Symbol(), 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 0);
   double macd_signal = iMACD(Symbol(), 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL, 0);
   
   if(orderType == OP_BUY)
   {
      // Close BUY if RSI overbought or MACD bearish crossover
      if(rsi > RSI_Overbought || (macd < macd_signal && macd < 0))
         return true;
   }
   else if(orderType == OP_SELL)
   {
      // Close SELL if RSI oversold or MACD bullish crossover
      if(rsi < RSI_Oversold || (macd > macd_signal && macd > 0))
         return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Close position                                                 |
//+------------------------------------------------------------------+
void ClosePosition(int ticket)
{
   if(!OrderSelect(ticket, SELECT_BY_TICKET)) return;
   
   bool result = false;
   if(OrderType() == OP_BUY)
   {
      result = OrderClose(ticket, OrderLots(), Bid, Slippage, clrRed);
   }
   else if(OrderType() == OP_SELL)
   {
      result = OrderClose(ticket, OrderLots(), Ask, Slippage, clrBlue);
   }
   
   if(result)
   {
      double profit = OrderProfit() + OrderSwap() + OrderCommission();
      g_dailyProfit += profit;
      g_dailyTrades++;
      Print("Position closed. Profit: ", profit);
   }
}

//+------------------------------------------------------------------+
//| Analyze market for opportunities                               |
//+------------------------------------------------------------------+
void AnalyzeMarket()
{
   // Get indicator values
   double rsi = iRSI(Symbol(), 0, RSI_Period, PRICE_CLOSE, 0);
   double rsi_prev = iRSI(Symbol(), 0, RSI_Period, PRICE_CLOSE, 1);
   
   double macd = iMACD(Symbol(), 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 0);
   double macd_prev = iMACD(Symbol(), 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 1);
   double macd_signal = iMACD(Symbol(), 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL, 0);
   double macd_signal_prev = iMACD(Symbol(), 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL, 1);
   
   double bb_upper = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_UPPER, 0);
   double bb_lower = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_LOWER, 0);
   double bb_middle = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_MAIN, 0);
   
   double stoch_k = iStochastic(Symbol(), 0, Stoch_K, Stoch_D, Stoch_Slowing, MODE_SMA, 0, MODE_MAIN, 0);
   double stoch_d = iStochastic(Symbol(), 0, Stoch_K, Stoch_D, Stoch_Slowing, MODE_SMA, 0, MODE_SIGNAL, 0);
   
   // Calculate volatility
   double atr = iATR(Symbol(), 0, 14, 0);
   double volatility = atr / Point;
   
   // Check for BUY signal
   if(IsBuySignal(rsi, rsi_prev, macd, macd_prev, macd_signal, macd_signal_prev, bb_lower, stoch_k, stoch_d))
   {
      double confidence = CalculateBuyConfidence(rsi, macd, bb_lower, stoch_k, volatility);
      if(confidence > 0.7) // 70% confidence threshold
      {
         ExecuteBuyOrder(confidence, volatility);
      }
   }
   
   // Check for SELL signal
   if(IsSellSignal(rsi, rsi_prev, macd, macd_prev, macd_signal, macd_signal_prev, bb_upper, stoch_k, stoch_d))
   {
      double confidence = CalculateSellConfidence(rsi, macd, bb_upper, stoch_k, volatility);
      if(confidence > 0.7) // 70% confidence threshold
      {
         ExecuteSellOrder(confidence, volatility);
      }
   }
}

//+------------------------------------------------------------------+
//| Check for BUY signal                                          |
//+------------------------------------------------------------------+
bool IsBuySignal(double rsi, double rsi_prev, double macd, double macd_prev, 
                 double macd_signal, double macd_signal_prev, double bb_lower, 
                 double stoch_k, double stoch_d)
{
   // RSI oversold and turning up
   bool rsi_signal = rsi < RSI_Oversold && rsi > rsi_prev;
   
   // MACD bullish crossover
   bool macd_signal = macd > macd_signal && macd_prev <= macd_signal_prev;
   
   // Price near lower Bollinger Band
   bool bb_signal = Close[0] <= bb_lower * 1.001;
   
   // Stochastic oversold and turning up
   bool stoch_signal = stoch_k < 20 && stoch_k > stoch_d;
   
   // At least 3 out of 4 signals must be true
   int signalCount = 0;
   if(rsi_signal) signalCount++;
   if(macd_signal) signalCount++;
   if(bb_signal) signalCount++;
   if(stoch_signal) signalCount++;
   
   return signalCount >= 3;
}

//+------------------------------------------------------------------+
//| Check for SELL signal                                         |
//+------------------------------------------------------------------+
bool IsSellSignal(double rsi, double rsi_prev, double macd, double macd_prev, 
                  double macd_signal, double macd_signal_prev, double bb_upper, 
                  double stoch_k, double stoch_d)
{
   // RSI overbought and turning down
   bool rsi_signal = rsi > RSI_Overbought && rsi < rsi_prev;
   
   // MACD bearish crossover
   bool macd_signal = macd < macd_signal && macd_prev >= macd_signal_prev;
   
   // Price near upper Bollinger Band
   bool bb_signal = Close[0] >= bb_upper * 0.999;
   
   // Stochastic overbought and turning down
   bool stoch_signal = stoch_k > 80 && stoch_k < stoch_d;
   
   // At least 3 out of 4 signals must be true
   int signalCount = 0;
   if(rsi_signal) signalCount++;
   if(macd_signal) signalCount++;
   if(bb_signal) signalCount++;
   if(stoch_signal) signalCount++;
   
   return signalCount >= 3;
}

//+------------------------------------------------------------------+
//| Calculate BUY confidence                                       |
//+------------------------------------------------------------------+
double CalculateBuyConfidence(double rsi, double macd, double bb_lower, double stoch_k, double volatility)
{
   double confidence = 0.5; // Base confidence
   
   // RSI contribution (0-0.2)
   if(rsi < 25) confidence += 0.2;
   else if(rsi < 30) confidence += 0.15;
   else if(rsi < 35) confidence += 0.1;
   
   // MACD contribution (0-0.2)
   if(macd > 0) confidence += 0.2;
   else if(macd > macd * 0.5) confidence += 0.1;
   
   // Bollinger Bands contribution (0-0.2)
   double bb_distance = (Close[0] - bb_lower) / (bb_lower * 0.01);
   if(bb_distance < 0.1) confidence += 0.2;
   else if(bb_distance < 0.5) confidence += 0.1;
   
   // Stochastic contribution (0-0.2)
   if(stoch_k < 15) confidence += 0.2;
   else if(stoch_k < 25) confidence += 0.1;
   
   // Volatility adjustment (0-0.1)
   if(volatility > 50 && volatility < 200) confidence += 0.1;
   
   return MathMin(confidence, 1.0);
}

//+------------------------------------------------------------------+
//| Calculate SELL confidence                                      |
//+------------------------------------------------------------------+
double CalculateSellConfidence(double rsi, double macd, double bb_upper, double stoch_k, double volatility)
{
   double confidence = 0.5; // Base confidence
   
   // RSI contribution (0-0.2)
   if(rsi > 75) confidence += 0.2;
   else if(rsi > 70) confidence += 0.15;
   else if(rsi > 65) confidence += 0.1;
   
   // MACD contribution (0-0.2)
   if(macd < 0) confidence += 0.2;
   else if(macd < macd * 0.5) confidence += 0.1;
   
   // Bollinger Bands contribution (0-0.2)
   double bb_distance = (bb_upper - Close[0]) / (bb_upper * 0.01);
   if(bb_distance < 0.1) confidence += 0.2;
   else if(bb_distance < 0.5) confidence += 0.1;
   
   // Stochastic contribution (0-0.2)
   if(stoch_k > 85) confidence += 0.2;
   else if(stoch_k > 75) confidence += 0.1;
   
   // Volatility adjustment (0-0.1)
   if(volatility > 50 && volatility < 200) confidence += 0.1;
   
   return MathMin(confidence, 1.0);
}

//+------------------------------------------------------------------+
//| Execute BUY order                                             |
//+------------------------------------------------------------------+
void ExecuteBuyOrder(double confidence, double volatility)
{
   // Calculate position size based on risk
   double riskAmount = AccountBalance() * MaxRiskPercent / 100;
   double stopLoss = CalculateStopLoss(true, volatility);
   double takeProfit = CalculateTakeProfit(true, confidence, volatility);
   
   double pointValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   double lotSize = riskAmount / (stopLoss * pointValue);
   lotSize = MathMin(lotSize, LotSize);
   lotSize = NormalizeDouble(lotSize, 2);
   
   if(lotSize < MarketInfo(Symbol(), MODE_MINLOT)) return;
   
   int ticket = OrderSend(Symbol(), OP_BUY, lotSize, Ask, Slippage, stopLoss, takeProfit, 
                         "Advanced Scalper BUY", MagicNumber, 0, clrBlue);
   
   if(ticket > 0)
   {
      Print("BUY order executed. Ticket: ", ticket, " Lot: ", lotSize, " SL: ", stopLoss, " TP: ", takeProfit);
      g_lastTradeTime = TimeCurrent();
   }
   else
   {
      Print("BUY order failed. Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Execute SELL order                                            |
//+------------------------------------------------------------------+
void ExecuteSellOrder(double confidence, double volatility)
{
   // Calculate position size based on risk
   double riskAmount = AccountBalance() * MaxRiskPercent / 100;
   double stopLoss = CalculateStopLoss(false, volatility);
   double takeProfit = CalculateTakeProfit(false, confidence, volatility);
   
   double pointValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   double lotSize = riskAmount / (stopLoss * pointValue);
   lotSize = MathMin(lotSize, LotSize);
   lotSize = NormalizeDouble(lotSize, 2);
   
   if(lotSize < MarketInfo(Symbol(), MODE_MINLOT)) return;
   
   int ticket = OrderSend(Symbol(), OP_SELL, lotSize, Bid, Slippage, stopLoss, takeProfit, 
                         "Advanced Scalper SELL", MagicNumber, 0, clrRed);
   
   if(ticket > 0)
   {
      Print("SELL order executed. Ticket: ", ticket, " Lot: ", lotSize, " SL: ", stopLoss, " TP: ", takeProfit);
      g_lastTradeTime = TimeCurrent();
   }
   else
   {
      Print("SELL order failed. Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Calculate stop loss                                            |
//+------------------------------------------------------------------+
double CalculateStopLoss(bool isBuy, double volatility)
{
   double atr = iATR(Symbol(), 0, 14, 0);
   double baseStop = atr * 1.5; // 1.5 times ATR
   
   // Adjust based on volatility
   if(volatility > 100) baseStop *= 0.8; // Tighter stop for high volatility
   if(volatility < 50) baseStop *= 1.2;  // Wider stop for low volatility
   
   // Ensure minimum stop loss
   double minStop = 20 * Point;
   if(baseStop < minStop) baseStop = minStop;
   
   if(isBuy)
      return NormalizeDouble(Ask - baseStop, Digits);
   else
      return NormalizeDouble(Bid + baseStop, Digits);
}

//+------------------------------------------------------------------+
//| Calculate take profit                                          |
//+------------------------------------------------------------------+
double CalculateTakeProfit(bool isBuy, double confidence, double volatility)
{
   double stopLoss = CalculateStopLoss(isBuy, volatility);
   double stopLossPoints = 0;
   
   if(isBuy)
      stopLossPoints = (Ask - stopLoss) / Point;
   else
      stopLossPoints = (stopLoss - Bid) / Point;
   
   // Calculate take profit based on confidence and risk ratio
   double profitRatio = MinProfitRatio + (confidence - 0.7) * 2; // 1.5 to 2.5
   double takeProfitPoints = stopLossPoints * profitRatio;
   
   // Adjust based on volatility
   if(volatility > 100) takeProfitPoints *= 0.8; // Tighter TP for high volatility
   if(volatility < 50) takeProfitPoints *= 1.2;  // Wider TP for low volatility
   
   if(isBuy)
      return NormalizeDouble(Ask + takeProfitPoints * Point, Digits);
   else
      return NormalizeDouble(Bid - takeProfitPoints * Point, Digits);
}

//+------------------------------------------------------------------+
//| Custom functions                                               |
//+------------------------------------------------------------------+
double Min(double a, double b) { return (a < b) ? a : b; }
double Max(double a, double b) { return (a > b) ? a : b; }