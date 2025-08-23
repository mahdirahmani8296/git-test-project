#property copyright "TrendFollowPro"
#property link      "https://"
#property version   "1.00"
#property strict

#include <Trade/Trade.mqh>

// ============================= Inputs =============================
input group               "General"
input ENUM_TIMEFRAMES     InpTimeframe          = PERIOD_CURRENT; // Signal timeframe
input ulong               InpMagicNumber        = 76543210;       // Magic number
input int                 InpSlippagePoints     = 10;             // Max slippage (points)
input bool                InpUseNewBarLogic     = true;           // Evaluate on new bar only

input group               "Trend Filters"
input int                 InpFastMAPeriod       = 50;             // Fast EMA period
input int                 InpSlowMAPeriod       = 200;            // Slow EMA period
input ENUM_APPLIED_PRICE  InpMAPrice            = PRICE_CLOSE;    // MA applied price
input int                 InpADXPeriod          = 14;             // ADX period
input double              InpADXMin             = 18.0;           // Minimum ADX to trade

input group               "Entry Conditions"
input int                 InpRSIPeriod          = 14;             // RSI period
input double              InpRSIPullbackBuy     = 45.0;           // RSI pullback threshold buy
input double              InpRSIPullbackSell    = 55.0;           // RSI pullback threshold sell
input int                 InpBarsBetweenTrades  = 5;              // Minimum bars between entries
input bool                InpOnePositionOnly    = true;           // One position per symbol

input group               "Risk Management"
input double              InpRiskPercent        = 1.0;            // Risk per trade (% of equity)
input int                 InpATRPeriod          = 14;             // ATR period
input double              InpSL_ATR_Multiplier  = 2.0;            // StopLoss = ATR * multiplier
input double              InpTP_ATR_Multiplier  = 3.0;            // TakeProfit base = ATR * multiplier
input bool                InpAdaptiveTPByADX    = true;           // Adapt TP to ADX strength
input double              InpTP_ADX_BoostMax    = 2.0;            // Max TP boost factor when ADX strong

input group               "Trade Management"
input bool                InpUseBreakEven       = true;           // Move SL to BE
input double              InpBreakEven_ATR      = 1.0;            // Move to BE after price moves ATR*x
input bool                InpUseATRTrailing     = true;           // ATR trailing stop
input double              InpTrail_ATR_Mult     = 1.5;            // ATR multiplier for trailing

input group               "Filters"
input int                 InpMaxSpreadPoints    = 25;             // Max spread (points)
input bool                InpAllowLongs         = true;           // Allow buy orders
input bool                InpAllowShorts        = true;           // Allow sell orders

input group               "Session Control (Server Time)"
input bool                InpUseSessionFilter   = false;          // Restrict trading hours
input int                 InpSessionStartHour   = 7;              // Start hour (0-23)
input int                 InpSessionEndHour     = 22;             // End hour (0-23)

// ============================= Globals =============================
CTrade                Trade;

datetime              g_lastBarTime = 0;
long                  g_digits      = 0;
double                g_point       = 0.0;
double                g_tickSize    = 0.0;
double                g_tickValue   = 0.0;
double                g_minLot      = 0.0;
double                g_maxLot      = 0.0;
double                g_lotStep     = 0.0;
int                   g_stopLevel   = 0; // in points
int                   g_freezeLevel = 0; // in points

// For spacing entries
int                   g_barsSinceLastEntry = 99999;

// ============================= Utility =============================
bool RefreshSymbolInfo()
{
   if(!SymbolInfoInteger(_Symbol, SYMBOL_DIGITS, g_digits)) return false;
   if(!SymbolInfoDouble(_Symbol, SYMBOL_POINT, g_point)) return false;
   if(!SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE, g_tickSize)) return false;
   if(!SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE, g_tickValue)) return false;
   if(!SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN, g_minLot)) return false;
   if(!SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX, g_maxLot)) return false;
   if(!SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP, g_lotStep)) return false;
   if(!SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL, g_stopLevel)) return false; // points
   if(!SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL, g_freezeLevel)) return false; // points
   return true;
}

bool IsNewBar()
{
   if(!InpUseNewBarLogic) return true; // evaluate each tick

   MqlRates rates[];
   if(CopyRates(_Symbol, InpTimeframe, 0, 2, rates) != 2) return false;
   datetime currentBarTime = rates[0].time; // bar 0 (current forming bar)
   if(currentBarTime != g_lastBarTime)
   {
      g_lastBarTime = currentBarTime;
      g_barsSinceLastEntry++;
      return true;
   }
   return false;
}

bool IsSpreadOk()
{
   double bid = 0.0, ask = 0.0;
   if(!SymbolInfoDouble(_Symbol, SYMBOL_BID, bid)) return false;
   if(!SymbolInfoDouble(_Symbol, SYMBOL_ASK, ask)) return false;
   double spreadPoints = (ask - bid) / g_point;
   return (InpMaxSpreadPoints <= 0) || (spreadPoints <= InpMaxSpreadPoints);
}

bool IsSessionOpen()
{
   if(!InpUseSessionFilter) return true;
   datetime now = TimeCurrent();
   MqlDateTime dt; TimeToStruct(now, dt);
   int hour = dt.hour;
   if(InpSessionStartHour <= InpSessionEndHour)
      return (hour >= InpSessionStartHour && hour < InpSessionEndHour);
   // Overnight session (e.g., 22 -> 6)
   return (hour >= InpSessionStartHour || hour < InpSessionEndHour);
}

double GetATR(int period)
{
   double atr[];
   if(iATR(_Symbol, InpTimeframe, period, atr) < 2) return 0.0;
   return atr[1]; // use closed bar ATR
}

double GetEMA(int period)
{
   double ma[];
   if(iMA(_Symbol, InpTimeframe, period, 0, MODE_EMA, InpMAPrice, ma) < 2) return 0.0;
   return ma[1]; // closed bar
}

double GetADX(int period)
{
   double adx[];
   if(iADX(_Symbol, InpTimeframe, period, PRICE_CLOSE, MODE_MAIN, adx) < 2) return 0.0;
   return adx[1];
}

double GetRSI()
{
   double rsi[];
   if(iRSI(_Symbol, InpTimeframe, InpRSIPeriod, PRICE_CLOSE, rsi) < 2) return 50.0;
   return rsi[1];
}

bool IsUptrend()
{
   double fast = GetEMA(InpFastMAPeriod);
   double slow = GetEMA(InpSlowMAPeriod);
   double adx  = GetADX(InpADXPeriod);
   if(fast == 0.0 || slow == 0.0 || adx == 0.0) return false;
   return (fast > slow && adx >= InpADXMin);
}

bool IsDowntrend()
{
   double fast = GetEMA(InpFastMAPeriod);
   double slow = GetEMA(InpSlowMAPeriod);
   double adx  = GetADX(InpADXPeriod);
   if(fast == 0.0 || slow == 0.0 || adx == 0.0) return false;
   return (fast < slow && adx >= InpADXMin);
}

int CountOpenPositionsByMagic(const long magic)
{
   int count = 0;
   for(int i = 0; i < PositionsTotal(); ++i)
   {
      if(!PositionSelectByIndex(i)) continue;
      string sym = PositionGetString(POSITION_SYMBOL);
      long mg = (long)PositionGetInteger(POSITION_MAGIC);
      if(sym == _Symbol && mg == (long)magic) count++;
   }
   return count;
}

bool HasPositionByDirection(const long magic, const int direction)
{
   for(int i = 0; i < PositionsTotal(); ++i)
   {
      if(!PositionSelectByIndex(i)) continue;
      string sym = PositionGetString(POSITION_SYMBOL);
      long mg = (long)PositionGetInteger(POSITION_MAGIC);
      int type = (int)PositionGetInteger(POSITION_TYPE);
      if(sym == _Symbol && mg == (long)magic)
      {
         if(direction > 0 && type == POSITION_TYPE_BUY) return true;
         if(direction < 0 && type == POSITION_TYPE_SELL) return true;
      }
   }
   return false;
}

double NormalizeVolume(double volume)
{
   if(volume < g_minLot) volume = g_minLot;
   if(volume > g_maxLot) volume = g_maxLot;
   if(g_lotStep > 0)
   {
      double steps = MathFloor((volume - g_minLot) / g_lotStep + 0.5);
      volume = g_minLot + steps * g_lotStep;
   }
   return NormalizeDouble(volume, 2);
}

double CalculateLotsByRisk(double stopDistancePrice)
{
   // stopDistancePrice is absolute price distance (e.g., 0.00123)
   if(stopDistancePrice <= 0.0 || g_tickSize <= 0.0 || g_tickValue <= 0.0) return g_minLot;
   double equity = 0.0; AccountInfoDouble(ACCOUNT_EQUITY, equity);
   double riskMoney = equity * InpRiskPercent / 100.0;
   double stopTicks = stopDistancePrice / g_tickSize;
   double riskPerLot = stopTicks * g_tickValue;
   if(riskPerLot <= 0.0) return g_minLot;
   double lots = riskMoney / riskPerLot;
   return NormalizeVolume(lots);
}

bool GetBidAsk(double &bid, double &ask)
{
   if(!SymbolInfoDouble(_Symbol, SYMBOL_BID, bid)) return false;
   if(!SymbolInfoDouble(_Symbol, SYMBOL_ASK, ask)) return false;
   return true;
}

// ============================= Orders =============================
bool OpenPosition(const bool isBuy)
{
   double bid = 0.0, ask = 0.0;
   if(!GetBidAsk(bid, ask)) return false;

   const double atr = GetATR(InpATRPeriod);
   if(atr <= 0.0) return false;

   double sl = 0.0, tp = 0.0, entry = isBuy ? ask : bid;

   double slDistance = atr * InpSL_ATR_Multiplier;
   if(isBuy)
      sl = entry - slDistance;
   else
      sl = entry + slDistance;

   // Enforce minimum stop level
   double minStopDistance = (double)g_stopLevel * g_point;
   if(isBuy && (entry - sl) < minStopDistance) sl = entry - minStopDistance;
   if(!isBuy && (sl - entry) < minStopDistance) sl = entry + minStopDistance;

   double lotSize = CalculateLotsByRisk(MathAbs(entry - sl));
   if(lotSize < g_minLot - 1e-8) return false;

   // TP with optional ADX boost
   double tpDistance = atr * InpTP_ATR_Multiplier;
   if(InpAdaptiveTPByADX)
   {
      double adx = GetADX(InpADXPeriod);
      if(adx > 0.0 && InpADXMin > 0.0)
      {
         double boost = MathMin(InpTP_ADX_BoostMax, MathMax(1.0, adx / InpADXMin));
         tpDistance *= boost;
      }
   }
   if(isBuy)
      tp = entry + tpDistance;
   else
      tp = entry - tpDistance;

   Trade.SetExpertMagicNumber((long)InpMagicNumber);
   Trade.SetDeviationInPoints(InpSlippagePoints);

   bool result = false;
   if(isBuy)
      result = Trade.Buy(lotSize, _Symbol, entry, sl, tp, "TFP Buy");
   else
      result = Trade.Sell(lotSize, _Symbol, entry, sl, tp, "TFP Sell");

   if(result)
   {
      g_barsSinceLastEntry = 0;
   }
   else
   {
      PrintFormat("Order open failed. Error: %d", GetLastError());
   }
   return result;
}

void ManageOpenPositions()
{
   const double atr = GetATR(InpATRPeriod);
   if(atr <= 0.0) return;

   for(int i = 0; i < PositionsTotal(); ++i)
   {
      if(!PositionSelectByIndex(i)) continue;
      string sym = PositionGetString(POSITION_SYMBOL);
      long mg = (long)PositionGetInteger(POSITION_MAGIC);
      if(sym != _Symbol || mg != (long)InpMagicNumber) continue;

      int type = (int)PositionGetInteger(POSITION_TYPE);
      double vol = PositionGetDouble(POSITION_VOLUME);
      double priceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);

      double bid = 0.0, ask = 0.0; if(!GetBidAsk(bid, ask)) continue;
      double price = (type == POSITION_TYPE_BUY ? bid : ask);

      bool modifyNeeded = false;
      double newSL = sl;

      // Break-even logic
      if(InpUseBreakEven)
      {
         double beDistance = atr * InpBreakEven_ATR;
         if(type == POSITION_TYPE_BUY)
         {
            if(price - priceOpen >= beDistance)
            {
               double beSL = priceOpen;
               if(sl < beSL)
               {
                  newSL = beSL;
                  modifyNeeded = true;
               }
            }
         }
         else if(type == POSITION_TYPE_SELL)
         {
            if(priceOpen - price >= beDistance)
            {
               double beSL = priceOpen;
               if(sl > beSL || sl == 0.0)
               {
                  newSL = beSL;
                  modifyNeeded = true;
               }
            }
         }
      }

      // ATR trailing
      if(InpUseATRTrailing)
      {
         double trailDistance = atr * InpTrail_ATR_Mult;
         if(type == POSITION_TYPE_BUY)
         {
            double trailSL = price - trailDistance;
            if(trailSL > newSL && trailSL > sl)
            {
               newSL = trailSL;
               modifyNeeded = true;
            }
         }
         else if(type == POSITION_TYPE_SELL)
         {
            double trailSL = price + trailDistance;
            if((newSL == 0.0 || trailSL < newSL) && (sl == 0.0 || trailSL < sl))
            {
               newSL = trailSL;
               modifyNeeded = true;
            }
         }
      }

      // Respect stop levels
      double minStopDistance = (double)g_stopLevel * g_point;
      if(type == POSITION_TYPE_BUY && newSL > 0.0)
      {
         if((price - newSL) < minStopDistance)
            newSL = price - minStopDistance;
      }
      else if(type == POSITION_TYPE_SELL && newSL > 0.0)
      {
         if((newSL - price) < minStopDistance)
            newSL = price + minStopDistance;
      }

      if(modifyNeeded)
      {
         Trade.SetExpertMagicNumber((long)InpMagicNumber);
         Trade.SetDeviationInPoints(InpSlippagePoints);
         if(!Trade.PositionModify(_Symbol, newSL, tp))
         {
            PrintFormat("Position modify failed. Error: %d", GetLastError());
         }
      }
   }
}

// ============================= Signals =============================
bool PriceAboveEMAs()
{
   double emaFast = GetEMA(InpFastMAPeriod);
   double emaSlow = GetEMA(InpSlowMAPeriod);
   double close[]; if(CopyClose(_Symbol, InpTimeframe, 0, 2, close) < 2) return false;
   return (close[1] > emaFast && emaFast > emaSlow);
}

bool PriceBelowEMAs()
{
   double emaFast = GetEMA(InpFastMAPeriod);
   double emaSlow = GetEMA(InpSlowMAPeriod);
   double close[]; if(CopyClose(_Symbol, InpTimeframe, 0, 2, close) < 2) return false;
   return (close[1] < emaFast && emaFast < emaSlow);
}

bool SignalBuy()
{
   if(!InpAllowLongs) return false;
   if(!IsUptrend()) return false;
   if(!PriceAboveEMAs()) return false;
   double rsi[]; if(iRSI(_Symbol, InpTimeframe, InpRSIPeriod, PRICE_CLOSE, rsi) < 3) return false;
   double rsiPrev = rsi[2];
   double rsiCurr = rsi[1];
   // Pullback then momentum resumption: cross up through pullback threshold
   if(rsiPrev < InpRSIPullbackBuy && rsiCurr >= InpRSIPullbackBuy) return true;
   return false;
}

bool SignalSell()
{
   if(!InpAllowShorts) return false;
   if(!IsDowntrend()) return false;
   if(!PriceBelowEMAs()) return false;
   double rsi[]; if(iRSI(_Symbol, InpTimeframe, InpRSIPeriod, PRICE_CLOSE, rsi) < 3) return false;
   double rsiPrev = rsi[2];
   double rsiCurr = rsi[1];
   // Pullback then momentum resumption: cross down through pullback threshold
   if(rsiPrev > InpRSIPullbackSell && rsiCurr <= InpRSIPullbackSell) return true;
   return false;
}

// ============================= EA Events =============================
int OnInit()
{
   if(!RefreshSymbolInfo())
   {
      Print("Failed to get symbol info");
      return(INIT_FAILED);
   }
   Trade.SetExpertMagicNumber((long)InpMagicNumber);
   Trade.SetDeviationInPoints(InpSlippagePoints);
   g_lastBarTime = 0;
   g_barsSinceLastEntry = 99999;
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   // Nothing to clean
}

void OnTick()
{
   if(!IsSessionOpen()) return;
   if(!IsSpreadOk()) return;

   if(InpUseNewBarLogic)
   {
      if(!IsNewBar()) return; // process once per bar
   }

   ManageOpenPositions();

   // Entry spacing control
   if(g_barsSinceLastEntry < InpBarsBetweenTrades) return;

   if(InpOnePositionOnly && CountOpenPositionsByMagic((long)InpMagicNumber) > 0)
      return;

   // Entry signals
   if(SignalBuy() && !HasPositionByDirection((long)InpMagicNumber, +1))
   {
      OpenPosition(true);
      return;
   }
   if(SignalSell() && !HasPositionByDirection((long)InpMagicNumber, -1))
   {
      OpenPosition(false);
      return;
   }
}

// ============================= Notes =============================
// This Expert Advisor implements a trend-following strategy using EMA(50/200) cross with ADX filter,
// RSI pullback-based entries, ATR-based SL/TP, adaptive TP boost with ADX, break-even and ATR trailing.
// Always backtest and forward-test in demo before live trading. Use appropriate risk.

