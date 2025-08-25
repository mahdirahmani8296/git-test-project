//+------------------------------------------------------------------+
//|                                                 ScalpingPro_EA.mq5 |
//|                                 Professional Scalping Expert Advisor |
//|                                              Designed for Gold & Majors |
//+------------------------------------------------------------------+
#property copyright "ScalpingPro EA"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

//--- Input parameters
input group "=== Trading Settings ==="
input double InpLotSize = 0.01;                    // Lot Size
input int InpMagicNumber = 123456;                 // Magic Number
input double InpRiskPercent = 1.0;                 // Risk per trade (%)
input int InpMaxSpread = 30;                       // Maximum spread (points)
input bool InpUseAutoLot = true;                   // Use automatic lot sizing

input group "=== Scalping Parameters ==="
input int InpScalpingPeriod = 5;                   // Scalping timeframe (minutes)
input double InpMinProfit = 5.0;                   // Minimum profit (points)
input double InpMaxProfit = 15.0;                  // Maximum profit (points)
input int InpMaxPositions = 3;                     // Maximum positions per symbol
input int InpCooldownMinutes = 2;                  // Cooldown between trades (minutes)

input group "=== Risk Management ==="
input double InpInitialStopLoss = 20.0;           // Initial Stop Loss (points)
input double InpInitialTakeProfit = 10.0;         // Initial Take Profit (points)
input bool InpUseTrailingStop = true;             // Use trailing stop
input double InpTrailingDistance = 8.0;           // Trailing distance (points)
input double InpBreakevenTrigger = 8.0;           // Breakeven trigger (points)

input group "=== Time Filter ==="
input bool InpUseTimeFilter = true;               // Use time filter
input int InpStartHour = 8;                       // Trading start hour
input int InpEndHour = 22;                        // Trading end hour

input group "=== Symbol Settings ==="
input bool InpTradeGold = true;                   // Trade Gold (XAUUSD)
input bool InpTradeEURUSD = true;                 // Trade EURUSD
input bool InpTradeGBPUSD = true;                 // Trade GBPUSD
input bool InpTradeUSDJPY = true;                 // Trade USDJPY
input bool InpTradeUSDCHF = true;                 // Trade USDCHF
input bool InpTradeAUDUSD = true;                 // Trade AUDUSD
input bool InpTradeUSDCAD = true;                 // Trade USDCAD
input bool InpTradeNZDUSD = true;                 // Trade NZDUSD

//--- Global variables
CTrade trade;
CSymbolInfo symbolInfo;
CPositionInfo positionInfo;
CAccountInfo accountInfo;

string tradingSymbols[];
datetime lastTradeTime[];
int totalTrades = 0;
int profitableTrades = 0;
double currentSuccessRate = 0.0;
double adaptiveStopLoss = 0.0;
double adaptiveTakeProfit = 0.0;

//--- Indicator handles
int maHandle[];
int rsiHandle[];
int atrHandle[];
int bollingerHandle[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("ScalpingPro EA - Initializing...");
    
    // Set trade parameters
    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetMarginMode();
    trade.SetTypeFillingBySymbol(Symbol());
    
    // Initialize trading symbols
    InitializeTradingSymbols();
    
    // Initialize indicators
    InitializeIndicators();
    
    // Initialize adaptive parameters
    adaptiveStopLoss = InpInitialStopLoss;
    adaptiveTakeProfit = InpInitialTakeProfit;
    
    Print("ScalpingPro EA - Initialization completed successfully!");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release indicator handles
    for(int i = 0; i < ArraySize(maHandle); i++)
    {
        if(maHandle[i] != INVALID_HANDLE)
            IndicatorRelease(maHandle[i]);
        if(rsiHandle[i] != INVALID_HANDLE)
            IndicatorRelease(rsiHandle[i]);
        if(atrHandle[i] != INVALID_HANDLE)
            IndicatorRelease(atrHandle[i]);
        if(bollingerHandle[i] != INVALID_HANDLE)
            IndicatorRelease(bollingerHandle[i]);
    }
    
    Print("ScalpingPro EA - Deinitialization completed");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Update success rate and adaptive parameters
    UpdateAdaptiveParameters();
    
    // Check each symbol for trading opportunities
    for(int i = 0; i < ArraySize(tradingSymbols); i++)
    {
        string symbol = tradingSymbols[i];
        
        if(!IsValidSymbol(symbol))
            continue;
            
        if(!symbolInfo.Name(symbol))
            continue;
            
        // Check time filter
        if(!IsTimeToTrade())
            continue;
            
        // Check spread
        if(!IsSpreadAcceptable(symbol))
            continue;
            
        // Check cooldown
        if(!IsCooldownPassed(symbol, i))
            continue;
            
        // Check maximum positions
        if(CountPositions(symbol) >= InpMaxPositions)
            continue;
            
        // Analyze market and execute trades
        AnalyzeAndTrade(symbol, i);
    }
    
    // Manage existing positions
    ManagePositions();
}

//+------------------------------------------------------------------+
//| Initialize trading symbols array                                 |
//+------------------------------------------------------------------+
void InitializeTradingSymbols()
{
    ArrayResize(tradingSymbols, 0);
    
    if(InpTradeGold) AddSymbol("XAUUSD");
    if(InpTradeEURUSD) AddSymbol("EURUSD");
    if(InpTradeGBPUSD) AddSymbol("GBPUSD");
    if(InpTradeUSDJPY) AddSymbol("USDJPY");
    if(InpTradeUSDCHF) AddSymbol("USDCHF");
    if(InpTradeAUDUSD) AddSymbol("AUDUSD");
    if(InpTradeUSDCAD) AddSymbol("USDCAD");
    if(InpTradeNZDUSD) AddSymbol("NZDUSD");
    
    ArrayResize(lastTradeTime, ArraySize(tradingSymbols));
    ArrayInitialize(lastTradeTime, 0);
    
    Print("Initialized ", ArraySize(tradingSymbols), " trading symbols");
}

//+------------------------------------------------------------------+
//| Add symbol to trading array                                      |
//+------------------------------------------------------------------+
void AddSymbol(string symbol)
{
    int size = ArraySize(tradingSymbols);
    ArrayResize(tradingSymbols, size + 1);
    tradingSymbols[size] = symbol;
}

//+------------------------------------------------------------------+
//| Initialize indicators for all symbols                            |
//+------------------------------------------------------------------+
void InitializeIndicators()
{
    int symbolCount = ArraySize(tradingSymbols);
    
    ArrayResize(maHandle, symbolCount);
    ArrayResize(rsiHandle, symbolCount);
    ArrayResize(atrHandle, symbolCount);
    ArrayResize(bollingerHandle, symbolCount);
    
    for(int i = 0; i < symbolCount; i++)
    {
        string symbol = tradingSymbols[i];
        
        maHandle[i] = iMA(symbol, PERIOD_M1, 20, 0, MODE_EMA, PRICE_CLOSE);
        rsiHandle[i] = iRSI(symbol, PERIOD_M1, 14, PRICE_CLOSE);
        atrHandle[i] = iATR(symbol, PERIOD_M1, 14);
        bollingerHandle[i] = iBands(symbol, PERIOD_M1, 20, 0, 2.0, PRICE_CLOSE);
        
        if(maHandle[i] == INVALID_HANDLE || rsiHandle[i] == INVALID_HANDLE || 
           atrHandle[i] == INVALID_HANDLE || bollingerHandle[i] == INVALID_HANDLE)
        {
            Print("Error initializing indicators for ", symbol);
        }
    }
}

//+------------------------------------------------------------------+
//| Check if symbol is valid for trading                            |
//+------------------------------------------------------------------+
bool IsValidSymbol(string symbol)
{
    if(!SymbolSelect(symbol, true))
    {
        Print("Symbol ", symbol, " not available");
        return false;
    }
    
    if(!symbolInfo.Name(symbol))
        return false;
        
    if(!symbolInfo.RefreshRates())
        return false;
        
    return true;
}

//+------------------------------------------------------------------+
//| Check if it's time to trade                                     |
//+------------------------------------------------------------------+
bool IsTimeToTrade()
{
    if(!InpUseTimeFilter)
        return true;
        
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    if(dt.hour >= InpStartHour && dt.hour <= InpEndHour)
        return true;
        
    return false;
}

//+------------------------------------------------------------------+
//| Check if spread is acceptable                                   |
//+------------------------------------------------------------------+
bool IsSpreadAcceptable(string symbol)
{
    if(!symbolInfo.Name(symbol))
        return false;
        
    double spread = symbolInfo.Spread();
    
    return (spread <= InpMaxSpread);
}

//+------------------------------------------------------------------+
//| Check if cooldown period has passed                             |
//+------------------------------------------------------------------+
bool IsCooldownPassed(string symbol, int index)
{
    datetime currentTime = TimeCurrent();
    
    if(currentTime - lastTradeTime[index] >= InpCooldownMinutes * 60)
        return true;
        
    return false;
}

//+------------------------------------------------------------------+
//| Count positions for specific symbol                             |
//+------------------------------------------------------------------+
int CountPositions(string symbol)
{
    int count = 0;
    
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(positionInfo.SelectByIndex(i))
        {
            if(positionInfo.Symbol() == symbol && positionInfo.Magic() == InpMagicNumber)
                count++;
        }
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| Analyze market and execute trades                               |
//+------------------------------------------------------------------+
void AnalyzeAndTrade(string symbol, int index)
{
    if(!symbolInfo.Name(symbol))
        return;
        
    // Get indicator values
    double ma[], rsi[], atr[], bbUpper[], bbLower[], bbMiddle[];
    
    if(CopyBuffer(maHandle[index], 0, 0, 3, ma) != 3 ||
       CopyBuffer(rsiHandle[index], 0, 0, 3, rsi) != 3 ||
       CopyBuffer(atrHandle[index], 0, 0, 3, atr) != 3 ||
       CopyBuffer(bollingerHandle[index], 0, 0, 3, bbUpper) != 3 ||
       CopyBuffer(bollingerHandle[index], 1, 0, 3, bbMiddle) != 3 ||
       CopyBuffer(bollingerHandle[index], 2, 0, 3, bbLower) != 3)
    {
        return;
    }
    
    double ask = symbolInfo.Ask();
    double bid = symbolInfo.Bid();
    double currentPrice = (ask + bid) / 2;
    
    // Scalping signals
    bool buySignal = false;
    bool sellSignal = false;
    
    // Multi-timeframe scalping strategy
    if(currentPrice > ma[0] && rsi[0] > 30 && rsi[0] < 70 && 
       ask < bbUpper[0] && ask > bbMiddle[0])
    {
        buySignal = true;
    }
    
    if(currentPrice < ma[0] && rsi[0] > 30 && rsi[0] < 70 && 
       bid > bbLower[0] && bid < bbMiddle[0])
    {
        sellSignal = true;
    }
    
    // Execute trades
    if(buySignal)
    {
        OpenPosition(symbol, ORDER_TYPE_BUY, index);
    }
    else if(sellSignal)
    {
        OpenPosition(symbol, ORDER_TYPE_SELL, index);
    }
}

//+------------------------------------------------------------------+
//| Open position                                                    |
//+------------------------------------------------------------------+
void OpenPosition(string symbol, ENUM_ORDER_TYPE orderType, int index)
{
    if(!symbolInfo.Name(symbol))
        return;
        
    double lotSize = CalculateLotSize(symbol);
    if(lotSize <= 0)
        return;
        
    double price = (orderType == ORDER_TYPE_BUY) ? symbolInfo.Ask() : symbolInfo.Bid();
    double sl = 0, tp = 0;
    
    // Calculate stop loss and take profit
    if(orderType == ORDER_TYPE_BUY)
    {
        sl = price - adaptiveStopLoss * symbolInfo.Point();
        tp = price + adaptiveTakeProfit * symbolInfo.Point();
    }
    else
    {
        sl = price + adaptiveStopLoss * symbolInfo.Point();
        tp = price - adaptiveTakeProfit * symbolInfo.Point();
    }
    
    // Normalize prices
    sl = NormalizeDouble(sl, symbolInfo.Digits());
    tp = NormalizeDouble(tp, symbolInfo.Digits());
    
    // Execute trade
    if(trade.PositionOpen(symbol, orderType, lotSize, price, sl, tp, "ScalpingPro"))
    {
        lastTradeTime[index] = TimeCurrent();
        totalTrades++;
        Print("Position opened: ", symbol, " ", EnumToString(orderType), " Lot: ", lotSize);
    }
    else
    {
        Print("Error opening position: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
    }
}

//+------------------------------------------------------------------+
//| Calculate lot size                                               |
//+------------------------------------------------------------------+
double CalculateLotSize(string symbol)
{
    if(!InpUseAutoLot)
        return InpLotSize;
        
    if(!symbolInfo.Name(symbol))
        return 0;
        
    double balance = accountInfo.Balance();
    double riskAmount = balance * InpRiskPercent / 100.0;
    double tickValue = symbolInfo.TickValue();
    double stopLossPoints = adaptiveStopLoss;
    
    if(tickValue == 0 || stopLossPoints == 0)
        return InpLotSize;
        
    double lotSize = riskAmount / (stopLossPoints * tickValue);
    
    // Normalize lot size
    double minLot = symbolInfo.LotsMin();
    double maxLot = symbolInfo.LotsMax();
    double lotStep = symbolInfo.LotsStep();
    
    lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
    lotSize = NormalizeDouble(lotSize / lotStep, 0) * lotStep;
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| Manage existing positions                                        |
//+------------------------------------------------------------------+
void ManagePositions()
{
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(!positionInfo.SelectByIndex(i))
            continue;
            
        if(positionInfo.Magic() != InpMagicNumber)
            continue;
            
        string symbol = positionInfo.Symbol();
        
        if(!symbolInfo.Name(symbol))
            continue;
            
        // Trailing stop
        if(InpUseTrailingStop)
        {
            ApplyTrailingStop(symbol);
        }
        
        // Breakeven
        ApplyBreakeven(symbol);
    }
}

//+------------------------------------------------------------------+
//| Apply trailing stop                                             |
//+------------------------------------------------------------------+
void ApplyTrailingStop(string symbol)
{
    double currentPrice = (positionInfo.Type() == POSITION_TYPE_BUY) ? 
                         symbolInfo.Bid() : symbolInfo.Ask();
    double openPrice = positionInfo.PriceOpen();
    double currentSL = positionInfo.StopLoss();
    double trailingDistance = InpTrailingDistance * symbolInfo.Point();
    
    double newSL = 0;
    bool modifyNeeded = false;
    
    if(positionInfo.Type() == POSITION_TYPE_BUY)
    {
        newSL = currentPrice - trailingDistance;
        if(newSL > currentSL && newSL > openPrice)
            modifyNeeded = true;
    }
    else
    {
        newSL = currentPrice + trailingDistance;
        if(newSL < currentSL && newSL < openPrice)
            modifyNeeded = true;
    }
    
    if(modifyNeeded)
    {
        newSL = NormalizeDouble(newSL, symbolInfo.Digits());
        trade.PositionModify(positionInfo.Ticket(), newSL, positionInfo.TakeProfit());
    }
}

//+------------------------------------------------------------------+
//| Apply breakeven                                                  |
//+------------------------------------------------------------------+
void ApplyBreakeven(string symbol)
{
    double currentPrice = (positionInfo.Type() == POSITION_TYPE_BUY) ? 
                         symbolInfo.Bid() : symbolInfo.Ask();
    double openPrice = positionInfo.PriceOpen();
    double currentSL = positionInfo.StopLoss();
    double breakevenTrigger = InpBreakevenTrigger * symbolInfo.Point();
    
    bool breakevenNeeded = false;
    
    if(positionInfo.Type() == POSITION_TYPE_BUY)
    {
        if(currentPrice >= openPrice + breakevenTrigger && currentSL < openPrice)
            breakevenNeeded = true;
    }
    else
    {
        if(currentPrice <= openPrice - breakevenTrigger && currentSL > openPrice)
            breakevenNeeded = true;
    }
    
    if(breakevenNeeded)
    {
        double newSL = NormalizeDouble(openPrice, symbolInfo.Digits());
        trade.PositionModify(positionInfo.Ticket(), newSL, positionInfo.TakeProfit());
    }
}

//+------------------------------------------------------------------+
//| Update adaptive parameters based on success rate                |
//+------------------------------------------------------------------+
void UpdateAdaptiveParameters()
{
    if(totalTrades < 10)
        return;
        
    currentSuccessRate = (double)profitableTrades / totalTrades * 100.0;
    
    // Adapt stop loss and take profit based on success rate
    if(currentSuccessRate > 70)
    {
        // High success rate - tighten stops, increase targets
        adaptiveStopLoss = InpInitialStopLoss * 0.8;
        adaptiveTakeProfit = InpInitialTakeProfit * 1.2;
    }
    else if(currentSuccessRate < 50)
    {
        // Low success rate - widen stops, decrease targets
        adaptiveStopLoss = InpInitialStopLoss * 1.2;
        adaptiveTakeProfit = InpInitialTakeProfit * 0.8;
    }
    else
    {
        // Medium success rate - use default values
        adaptiveStopLoss = InpInitialStopLoss;
        adaptiveTakeProfit = InpInitialTakeProfit;
    }
}

//+------------------------------------------------------------------+
//| Trade transaction function                                       |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                       const MqlTradeRequest& request,
                       const MqlTradeResult& result)
{
    if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
    {
        if(trans.deal_type == DEAL_TYPE_BUY || trans.deal_type == DEAL_TYPE_SELL)
        {
            // Check if it's a closing deal
            if(trans.position != 0)
            {
                // Position closed - update statistics
                CDealInfo dealInfo;
                if(dealInfo.SelectByIndex(HistoryDealsTotal() - 1))
                {
                    if(dealInfo.Profit() > 0)
                        profitableTrades++;
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Get current statistics                                           |
//+------------------------------------------------------------------+
void PrintStatistics()
{
    if(totalTrades > 0)
    {
        Print("=== ScalpingPro EA Statistics ===");
        Print("Total Trades: ", totalTrades);
        Print("Profitable Trades: ", profitableTrades);
        Print("Success Rate: ", DoubleToString(currentSuccessRate, 2), "%");
        Print("Adaptive Stop Loss: ", DoubleToString(adaptiveStopLoss, 1), " points");
        Print("Adaptive Take Profit: ", DoubleToString(adaptiveTakeProfit, 1), " points");
        Print("================================");
    }
}