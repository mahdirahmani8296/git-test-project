#property copyright "OpenAI"
#property version   "1.0"
#property strict
#property description "EMA crossover + RSI filter with ATR-based SL/TP and optional trailing stop. Risk-based or fixed-volume position sizing."

#include <Trade/Trade.mqh>

CTrade trade;

input string InpSymbol = _Symbol;                          // Symbol to trade
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M15;           // Signal timeframe

input int InpEMAFast = 50;                                 // Fast EMA period
input int InpEMASlow = 200;                                // Slow EMA period
input int InpRSIPeriod = 14;                               // RSI period
input int InpATRPeriod = 14;                               // ATR period
input int InpRSIBuyLevel = 55;                             // RSI min for buy
input int InpRSISellLevel = 45;                            // RSI max for sell

input double InpATRMultiplierSL = 2.0;                     // SL = ATR * multiplier
input double InpATRMultiplierTP = 3.0;                     // TP = ATR * multiplier
input bool InpUseTrailingStop = true;                      // Use ATR trailing stop
input double InpTrailATRMultiplier = 1.0;                  // Trail = ATR * multiplier

input bool InpUseRisk = true;                              // Use risk % per trade
input double InpRiskPerTradePercent = 1.0;                 // Risk percent per trade
input double InpFixedVolume = 0.10;                        // Fixed lot if risk disabled

input int InpMaxSpreadPoints = 30;                         // Max allowed spread (points)
input int InpSlippagePoints = 5;                           // Slippage (points)
input int InpMaxOpenTrades = 1;                            // Max concurrent trades (this EA)
input bool InpCloseOnOppositeSignal = true;                // Close on opposite signal
input long InpMagic = 20250819;                            // Magic number

int g_emaFastHandle = INVALID_HANDLE;
int g_emaSlowHandle = INVALID_HANDLE;
int g_rsiHandle = INVALID_HANDLE;
int g_atrHandle = INVALID_HANDLE;

datetime g_lastProcessedBarTime = 0;

bool EnsureSymbolSelected(const string symbol)
{
	if(SymbolInfoInteger(symbol, SYMBOL_SELECT))
		return true;
	return SymbolSelect(symbol, true);
}

bool CreateIndicators()
{
	g_emaFastHandle = iMA(InpSymbol, InpTimeframe, InpEMAFast, 0, MODE_EMA, PRICE_CLOSE);
	g_emaSlowHandle = iMA(InpSymbol, InpTimeframe, InpEMASlow, 0, MODE_EMA, PRICE_CLOSE);
	g_rsiHandle = iRSI(InpSymbol, InpTimeframe, InpRSIPeriod, PRICE_CLOSE);
	g_atrHandle = iATR(InpSymbol, InpTimeframe, InpATRPeriod);

	if(g_emaFastHandle == INVALID_HANDLE || g_emaSlowHandle == INVALID_HANDLE || g_rsiHandle == INVALID_HANDLE || g_atrHandle == INVALID_HANDLE)
		return false;
	return true;
}

void ReleaseIndicators()
{
	if(g_emaFastHandle != INVALID_HANDLE) { IndicatorRelease(g_emaFastHandle); g_emaFastHandle = INVALID_HANDLE; }
	if(g_emaSlowHandle != INVALID_HANDLE) { IndicatorRelease(g_emaSlowHandle); g_emaSlowHandle = INVALID_HANDLE; }
	if(g_rsiHandle != INVALID_HANDLE) { IndicatorRelease(g_rsiHandle); g_rsiHandle = INVALID_HANDLE; }
	if(g_atrHandle != INVALID_HANDLE) { IndicatorRelease(g_atrHandle); g_atrHandle = INVALID_HANDLE; }
}

bool CopyLatestSeries(datetime &barTime, double &emaFast1, double &emaFast2, double &emaSlow1, double &emaSlow2, double &rsi1, double &rsi2, double &atr1)
{
	double emaFast[3];
	double emaSlow[3];
	double rsi[3];
	double atr[3];
	datetime times[3];

	int needBars = 3;
	int copiedTime = CopyTime(InpSymbol, InpTimeframe, 0, needBars, times);
	int copiedFast = CopyBuffer(g_emaFastHandle, 0, 0, needBars, emaFast);
	int copiedSlow = CopyBuffer(g_emaSlowHandle, 0, 0, needBars, emaSlow);
	int copiedRSI = CopyBuffer(g_rsiHandle, 0, 0, needBars, rsi);
	int copiedATR = CopyBuffer(g_atrHandle, 0, 0, needBars, atr);

	if(copiedTime < needBars || copiedFast < needBars || copiedSlow < needBars || copiedRSI < needBars || copiedATR < needBars)
		return false;

	barTime = times[1];
	emaFast1 = emaFast[1];
	emaFast2 = emaFast[2];
	emaSlow1 = emaSlow[1];
	emaSlow2 = emaSlow[2];
	rsi1 = rsi[1];
	rsi2 = rsi[2];
	atr1 = atr[1];
	return true;
}

int CountOpenPositionsForThisEA()
{
	int count = 0;
	for(int i = 0; i < PositionsTotal(); ++i)
	{
		ulong ticket = PositionGetTicket(i);
		if(ticket == 0)
			continue;
		if(!PositionSelectByTicket(ticket))
			continue;
		string posSymbol = PositionGetString(POSITION_SYMBOL);
		long posMagic = (long)PositionGetInteger(POSITION_MAGIC);
		if(posSymbol == InpSymbol && posMagic == InpMagic)
			++count;
	}
	return count;
}

bool GetExistingPosition(ENUM_POSITION_TYPE &typeOut, double &priceOpenOut, double &slOut, double &tpOut)
{
	for(int i = 0; i < PositionsTotal(); ++i)
	{
		ulong ticket = PositionGetTicket(i);
		if(ticket == 0)
			continue;
		if(!PositionSelectByTicket(ticket))
			continue;
		string posSymbol = PositionGetString(POSITION_SYMBOL);
		long posMagic = (long)PositionGetInteger(POSITION_MAGIC);
		if(posSymbol == InpSymbol && posMagic == InpMagic)
		{
			typeOut = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
			priceOpenOut = PositionGetDouble(POSITION_PRICE_OPEN);
			slOut = PositionGetDouble(POSITION_SL);
			tpOut = PositionGetDouble(POSITION_TP);
			return true;
		}
	}
	return false;
}

double NormalizeVolumeToStep(double volume)
{
	double volMin = SymbolInfoDouble(InpSymbol, SYMBOL_VOLUME_MIN);
	double volMax = SymbolInfoDouble(InpSymbol, SYMBOL_VOLUME_MAX);
	double volStep = SymbolInfoDouble(InpSymbol, SYMBOL_VOLUME_STEP);
	if(volume < volMin) volume = volMin;
	if(volume > volMax) volume = volMax;
	if(volStep > 0.0)
	{
		double steps = MathFloor((volume - volMin) / volStep + 0.5);
		volume = volMin + steps * volStep;
	}
	return volume;
}

double CalculateVolumeByRisk(const double entryPrice, const double stopLossPrice)
{
	double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
	double riskMoney = accountBalance * InpRiskPerTradePercent / 100.0;
	double tickValue = SymbolInfoDouble(InpSymbol, SYMBOL_TRADE_TICK_VALUE);
	double tickSize = SymbolInfoDouble(InpSymbol, SYMBOL_TRADE_TICK_SIZE);
	if(tickValue <= 0.0 || tickSize <= 0.0)
		return 0.0;
	double riskPriceDistance = MathAbs(entryPrice - stopLossPrice);
	if(riskPriceDistance <= 0.0)
		return 0.0;
	double riskTicks = riskPriceDistance / tickSize;
	if(riskTicks <= 0.0)
		return 0.0;
	double volume = riskMoney / (riskTicks * tickValue);
	return NormalizeVolumeToStep(volume);
}

bool PlaceOrder(const bool isBuy, const double atrValue)
{
	MqlTick tick;
	if(!SymbolInfoTick(InpSymbol, tick))
		return false;

	int stopLevelPts = (int)SymbolInfoInteger(InpSymbol, SYMBOL_TRADE_STOPS_LEVEL);
	double minStopDistance = stopLevelPts * _Point;
	double entry = isBuy ? tick.ask : tick.bid;
	if(atrValue <= 0.0)
		return false;

	double sl = isBuy ? (entry - atrValue * InpATRMultiplierSL) : (entry + atrValue * InpATRMultiplierSL);
	double tp = isBuy ? (entry + atrValue * InpATRMultiplierTP) : (entry - atrValue * InpATRMultiplierTP);

	if(minStopDistance > 0)
	{
		if(isBuy)
		{
			if((entry - sl) < minStopDistance) sl = entry - minStopDistance;
			if((tp - entry) < minStopDistance) tp = entry + minStopDistance;
		}
		else
		{
			if((sl - entry) < minStopDistance) sl = entry + minStopDistance;
			if((entry - tp) < minStopDistance) tp = entry - minStopDistance;
		}
	}

	double volume = InpUseRisk ? CalculateVolumeByRisk(entry, sl) : NormalizeVolumeToStep(InpFixedVolume);
	if(volume <= 0.0)
		return false;

	trade.SetExpertMagicNumber(InpMagic);
	trade.SetDeviationInPoints(InpSlippagePoints);
	bool sent = false;
	if(isBuy)
		sent = trade.Buy(volume, InpSymbol, entry, sl, tp);
	else
		sent = trade.Sell(volume, InpSymbol, entry, sl, tp);
	return sent;
}

void MaybeTrailPosition(const double atrValue)
{
	if(!InpUseTrailingStop || atrValue <= 0.0)
		return;

	ENUM_POSITION_TYPE type;
	double priceOpen, sl, tp;
	if(!GetExistingPosition(type, priceOpen, sl, tp))
		return;

	MqlTick tick;
	if(!SymbolInfoTick(InpSymbol, tick))
		return;

	int stopLevelPts = (int)SymbolInfoInteger(InpSymbol, SYMBOL_TRADE_STOPS_LEVEL);
	double minStopDistance = stopLevelPts * _Point;

	double desiredSL = 0.0;
	if(type == POSITION_TYPE_BUY)
	{
		desiredSL = tick.bid - atrValue * InpTrailATRMultiplier;
		if(sl <= 0.0 || desiredSL > sl)
		{
			if(minStopDistance > 0 && (tick.bid - desiredSL) < minStopDistance)
				desiredSL = tick.bid - minStopDistance;
			trade.PositionModify(InpSymbol, desiredSL, tp);
		}
	}
	else if(type == POSITION_TYPE_SELL)
	{
		desiredSL = tick.ask + atrValue * InpTrailATRMultiplier;
		if(sl <= 0.0 || desiredSL < sl)
		{
			if(minStopDistance > 0 && (desiredSL - tick.ask) < minStopDistance)
				desiredSL = tick.ask + minStopDistance;
			trade.PositionModify(InpSymbol, desiredSL, tp);
		}
	}
}

int OnInit()
{
	if(!EnsureSymbolSelected(InpSymbol))
		return INIT_FAILED;
	if(!CreateIndicators())
		return INIT_FAILED;
	g_lastProcessedBarTime = 0;
	return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
	ReleaseIndicators();
}

void OnTick()
{
	long spreadPoints = SymbolInfoInteger(InpSymbol, SYMBOL_SPREAD);
	if(InpMaxSpreadPoints > 0 && spreadPoints > InpMaxSpreadPoints)
		return;

	datetime barTime;
	double emaFast1, emaFast2, emaSlow1, emaSlow2, rsi1, rsi2, atr1;
	if(!CopyLatestSeries(barTime, emaFast1, emaFast2, emaSlow1, emaSlow2, rsi1, rsi2, atr1))
		return;

	if(barTime == 0 || barTime == g_lastProcessedBarTime)
	{
		MaybeTrailPosition(atr1);
		return;
	}

	g_lastProcessedBarTime = barTime;

	bool bullishCross = (emaFast1 > emaSlow1) && (emaFast2 <= emaSlow2) && (rsi1 >= InpRSIBuyLevel);
	bool bearishCross = (emaFast1 < emaSlow1) && (emaFast2 >= emaSlow2) && (rsi1 <= InpRSISellLevel);

	ENUM_POSITION_TYPE existingType;
	double priceOpen, sl, tp;
	bool hasPosition = GetExistingPosition(existingType, priceOpen, sl, tp);

	if(hasPosition && InpCloseOnOppositeSignal)
	{
		if(existingType == POSITION_TYPE_BUY && bearishCross)
		{
			trade.PositionClose(InpSymbol);
			hasPosition = false;
		}
		else if(existingType == POSITION_TYPE_SELL && bullishCross)
		{
			trade.PositionClose(InpSymbol);
			hasPosition = false;
		}
	}

	if(InpMaxOpenTrades > 0 && CountOpenPositionsForThisEA() >= InpMaxOpenTrades)
	{
		MaybeTrailPosition(atr1);
		return;
	}

	if(bullishCross)
		PlaceOrder(true, atr1);
	else if(bearishCross)
		PlaceOrder(false, atr1);

	MaybeTrailPosition(atr1);
}

