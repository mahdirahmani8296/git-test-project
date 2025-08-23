//+------------------------------------------------------------------+
//|                                            AdvancedScalpingEA.mq5 |
//|                                  Copyright 2024, Advanced Trader |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Advanced Trader"
#property link      ""
#property version   "1.00"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

//--- Input Parameters
input group "=== EA Settings ==="
input double  LotSize = 0.01;              // Lot size
input bool    AutoLotSize = true;          // Auto calculate lot size
input double  RiskPercent = 2.0;           // Risk percentage per trade
input ulong   MagicNumber = 12345;         // Magic number
input uint    Slippage = 3;                // Maximum slippage

input group "=== Scalping Settings ==="
input ENUM_TIMEFRAMES ScalpingTimeframe = PERIOD_M1; // Scalping timeframe
input double  MinProfitPips = 5;           // Minimum profit in pips
input double  MaxSpread = 3;               // Maximum allowed spread
input bool    UseFastExit = true;          // Use fast exit on profit
input int     MaxOpenTrades = 3;           // Maximum open trades

input group "=== Indicator Settings ==="
input int     RSI_Period = 14;             // RSI period
input int     RSI_Overbought = 70;         // RSI overbought level
input int     RSI_Oversold = 30;           // RSI oversold level
input int     MACD_Fast = 12;              // MACD fast EMA
input int     MACD_Slow = 26;              // MACD slow EMA
input int     MACD_Signal = 9;             // MACD signal line
input int     EMA_Fast = 10;               // Fast EMA period
input int     EMA_Slow = 21;               // Slow EMA period
input int     BB_Period = 20;              // Bollinger Bands period
input double  BB_Deviation = 2.0;          // Bollinger Bands deviation
input int     ATR_Period = 14;             // ATR period for volatility

input group "=== Risk Management ==="
input bool    UseATR_SL = true;            // Use ATR for stop loss
input double  ATR_SL_Multiplier = 2.0;     // ATR multiplier for SL
input double  FixedSL = 20;                // Fixed SL in pips (if not using ATR)
input double  RiskRewardRatio = 1.5;       // Risk:Reward ratio
input bool    UseTrailingStop = true;      // Use trailing stop
input double  TrailingStart = 10;          // Trailing start in pips
input double  TrailingStep = 5;            // Trailing step in pips

input group "=== Trading Time ==="
input bool    UseTimeFilter = true;        // Use time filter
input int     StartHour = 8;               // Start trading hour
input int     EndHour = 18;                // End trading hour
input bool    AvoidNews = true;            // Avoid trading during news

//--- Global Variables
CTrade trade;
CPositionInfo position;
CAccountInfo account;

double point_factor;
int total_orders = 0;
datetime last_trade_time = 0;
double daily_profit = 0;
double max_daily_loss = -100;

// Indicator handles
int rsi_handle;
int macd_handle;
int ema_fast_handle;
int ema_slow_handle;
int bb_handle;
int atr_handle;
int momentum_handle;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize trading class
    trade.SetExpertMagicNumber(MagicNumber);
    trade.SetDeviationInPoints(Slippage);
    trade.SetTypeFilling(ORDER_FILLING_FOK);
    
    // Initialize point factor
    point_factor = (Digits() == 5 || Digits() == 3) ? 10 : 1;
    
    // Initialize indicators
    rsi_handle = iRSI(Symbol(), ScalpingTimeframe, RSI_Period, PRICE_CLOSE);
    macd_handle = iMACD(Symbol(), ScalpingTimeframe, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE);
    ema_fast_handle = iMA(Symbol(), ScalpingTimeframe, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
    ema_slow_handle = iMA(Symbol(), ScalpingTimeframe, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
    bb_handle = iBands(Symbol(), ScalpingTimeframe, BB_Period, 0, BB_Deviation, PRICE_CLOSE);
    atr_handle = iATR(Symbol(), ScalpingTimeframe, ATR_Period);
    momentum_handle = iMomentum(Symbol(), ScalpingTimeframe, 10, PRICE_CLOSE);
    
    // Check indicator handles
    if(rsi_handle == INVALID_HANDLE || macd_handle == INVALID_HANDLE || 
       ema_fast_handle == INVALID_HANDLE || ema_slow_handle == INVALID_HANDLE ||
       bb_handle == INVALID_HANDLE || atr_handle == INVALID_HANDLE ||
       momentum_handle == INVALID_HANDLE)
    {
        Print("Error initializing indicators");
        return INIT_FAILED;
    }
    
    Print("Advanced Scalping EA MT5 initialized successfully");
    Print("Point factor: ", point_factor);
    Print("Current spread: ", SymbolInfoInteger(Symbol(), SYMBOL_SPREAD));
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release indicator handles
    IndicatorRelease(rsi_handle);
    IndicatorRelease(macd_handle);
    IndicatorRelease(ema_fast_handle);
    IndicatorRelease(ema_slow_handle);
    IndicatorRelease(bb_handle);
    IndicatorRelease(atr_handle);
    IndicatorRelease(momentum_handle);
    
    Print("Advanced Scalping EA MT5 stopped. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check if trading is allowed
    if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || 
       !SymbolInfoInteger(Symbol(), SYMBOL_TRADE_MODE)) return;
    
    // Update global variables
    UpdateGlobalVariables();
    
    // Check trading conditions
    if(!CheckTradingConditions()) return;
    
    // Manage existing positions
    ManageOpenPositions();
    
    // Check for new trading signals
    CheckTradingSignals();
}

//+------------------------------------------------------------------+
//| Update global variables                                          |
//+------------------------------------------------------------------+
void UpdateGlobalVariables()
{
    total_orders = CountOpenPositions();
    
    // Calculate daily profit
    daily_profit = CalculateDailyProfit();
    
    // Check if maximum daily loss reached
    if(daily_profit <= max_daily_loss)
    {
        CloseAllPositions();
        Print("Maximum daily loss reached. Stopping trading for today.");
        return;
    }
}

//+------------------------------------------------------------------+
//| Check trading conditions                                         |
//+------------------------------------------------------------------+
bool CheckTradingConditions()
{
    // Check spread
    long spread = SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);
    if(spread > MaxSpread * point_factor)
    {
        return false;
    }
    
    // Check maximum open trades
    if(total_orders >= MaxOpenTrades)
    {
        return false;
    }
    
    // Check time filter
    if(UseTimeFilter && !IsValidTradingTime())
    {
        return false;
    }
    
    // Check news filter
    if(AvoidNews && IsNewsTime())
    {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check for trading signals                                        |
//+------------------------------------------------------------------+
void CheckTradingSignals()
{
    // Prevent too frequent trading
    if(TimeCurrent() - last_trade_time < 60) // At least 1 minute between trades
        return;
    
    // Get indicator values
    double rsi[1];
    double macd_main[1], macd_signal[1];
    double ema_fast[1], ema_slow[1];
    double bb_upper[1], bb_lower[1], bb_middle[1];
    double momentum[2];
    
    // Copy indicator data
    if(CopyBuffer(rsi_handle, 0, 0, 1, rsi) != 1 ||
       CopyBuffer(macd_handle, 0, 0, 1, macd_main) != 1 ||
       CopyBuffer(macd_handle, 1, 0, 1, macd_signal) != 1 ||
       CopyBuffer(ema_fast_handle, 0, 0, 1, ema_fast) != 1 ||
       CopyBuffer(ema_slow_handle, 0, 0, 1, ema_slow) != 1 ||
       CopyBuffer(bb_handle, 1, 0, 1, bb_upper) != 1 ||
       CopyBuffer(bb_handle, 2, 0, 1, bb_lower) != 1 ||
       CopyBuffer(bb_handle, 0, 0, 1, bb_middle) != 1 ||
       CopyBuffer(momentum_handle, 0, 0, 2, momentum) != 2)
    {
        Print("Error copying indicator data");
        return;
    }
    
    MqlTick latest_price;
    if(!SymbolInfoTick(Symbol(), latest_price))
    {
        Print("Error getting latest price");
        return;
    }
    
    double current_price = (latest_price.ask + latest_price.bid) / 2;
    
    // Buy signal conditions
    bool buy_signal = false;
    if(rsi[0] < RSI_Oversold && 
       macd_main[0] > macd_signal[0] && 
       ema_fast[0] > ema_slow[0] && 
       current_price < bb_lower[0] &&
       latest_price.ask > ema_fast[0])
    {
        buy_signal = true;
    }
    
    // Sell signal conditions
    bool sell_signal = false;
    if(rsi[0] > RSI_Overbought && 
       macd_main[0] < macd_signal[0] && 
       ema_fast[0] < ema_slow[0] && 
       current_price > bb_upper[0] &&
       latest_price.bid < ema_fast[0])
    {
        sell_signal = true;
    }
    
    // Additional momentum confirmation
    if(buy_signal && momentum[0] > momentum[1])
    {
        OpenBuyOrder();
    }
    else if(sell_signal && momentum[0] < momentum[1])
    {
        OpenSellOrder();
    }
}

//+------------------------------------------------------------------+
//| Open buy order                                                   |
//+------------------------------------------------------------------+
void OpenBuyOrder()
{
    double lot_size = CalculateLotSize();
    double sl = CalculateStopLoss(ORDER_TYPE_BUY);
    double tp = CalculateTakeProfit(ORDER_TYPE_BUY, sl);
    
    MqlTick latest_price;
    if(!SymbolInfoTick(Symbol(), latest_price))
        return;
    
    if(trade.Buy(lot_size, Symbol(), latest_price.ask, sl, tp, "Advanced Scalping EA - Buy"))
    {
        last_trade_time = TimeCurrent();
        Print("Buy order opened: Lot=", lot_size, " SL=", sl, " TP=", tp);
    }
    else
    {
        Print("Error opening buy order: ", trade.ResultRetcode());
    }
}

//+------------------------------------------------------------------+
//| Open sell order                                                  |
//+------------------------------------------------------------------+
void OpenSellOrder()
{
    double lot_size = CalculateLotSize();
    double sl = CalculateStopLoss(ORDER_TYPE_SELL);
    double tp = CalculateTakeProfit(ORDER_TYPE_SELL, sl);
    
    MqlTick latest_price;
    if(!SymbolInfoTick(Symbol(), latest_price))
        return;
    
    if(trade.Sell(lot_size, Symbol(), latest_price.bid, sl, tp, "Advanced Scalping EA - Sell"))
    {
        last_trade_time = TimeCurrent();
        Print("Sell order opened: Lot=", lot_size, " SL=", sl, " TP=", tp);
    }
    else
    {
        Print("Error opening sell order: ", trade.ResultRetcode());
    }
}

//+------------------------------------------------------------------+
//| Calculate lot size                                               |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
    if(!AutoLotSize)
        return LotSize;
    
    double account_balance = account.Balance();
    double risk_amount = account_balance * RiskPercent / 100.0;
    
    double sl_pips;
    if(UseATR_SL)
    {
        double atr[1];
        if(CopyBuffer(atr_handle, 0, 0, 1, atr) != 1)
            return LotSize;
        sl_pips = atr[0] * ATR_SL_Multiplier / Point() / point_factor;
    }
    else
    {
        sl_pips = FixedSL;
    }
    
    double pip_value = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
    if(point_factor == 10) pip_value *= 10;
    
    double lot_size = risk_amount / (sl_pips * pip_value);
    
    // Normalize lot size
    double min_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
    double lot_step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
    
    lot_size = MathMax(min_lot, MathMin(max_lot, MathRound(lot_size / lot_step) * lot_step));
    
    return lot_size;
}

//+------------------------------------------------------------------+
//| Calculate stop loss                                              |
//+------------------------------------------------------------------+
double CalculateStopLoss(ENUM_ORDER_TYPE order_type)
{
    double sl = 0;
    
    MqlTick latest_price;
    if(!SymbolInfoTick(Symbol(), latest_price))
        return 0;
    
    if(UseATR_SL)
    {
        double atr[1];
        if(CopyBuffer(atr_handle, 0, 0, 1, atr) != 1)
            return 0;
        
        double sl_distance = atr[0] * ATR_SL_Multiplier;
        
        if(order_type == ORDER_TYPE_BUY)
            sl = latest_price.ask - sl_distance;
        else if(order_type == ORDER_TYPE_SELL)
            sl = latest_price.bid + sl_distance;
    }
    else
    {
        double sl_distance = FixedSL * Point() * point_factor;
        
        if(order_type == ORDER_TYPE_BUY)
            sl = latest_price.ask - sl_distance;
        else if(order_type == ORDER_TYPE_SELL)
            sl = latest_price.bid + sl_distance;
    }
    
    return NormalizeDouble(sl, Digits());
}

//+------------------------------------------------------------------+
//| Calculate take profit                                            |
//+------------------------------------------------------------------+
double CalculateTakeProfit(ENUM_ORDER_TYPE order_type, double stop_loss)
{
    double tp = 0;
    double sl_distance;
    
    MqlTick latest_price;
    if(!SymbolInfoTick(Symbol(), latest_price))
        return 0;
    
    if(order_type == ORDER_TYPE_BUY)
    {
        sl_distance = latest_price.ask - stop_loss;
        tp = latest_price.ask + (sl_distance * RiskRewardRatio);
    }
    else if(order_type == ORDER_TYPE_SELL)
    {
        sl_distance = stop_loss - latest_price.bid;
        tp = latest_price.bid - (sl_distance * RiskRewardRatio);
    }
    
    return NormalizeDouble(tp, Digits());
}

//+------------------------------------------------------------------+
//| Manage open positions                                            |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0 && position.SelectByTicket(ticket))
        {
            if(position.Symbol() == Symbol() && position.Magic() == MagicNumber)
            {
                // Check for fast exit
                if(UseFastExit)
                {
                    CheckFastExit();
                }
                
                // Apply trailing stop
                if(UseTrailingStop)
                {
                    ApplyTrailingStop();
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check for fast exit conditions                                  |
//+------------------------------------------------------------------+
void CheckFastExit()
{
    double profit_pips = 0;
    
    MqlTick latest_price;
    if(!SymbolInfoTick(Symbol(), latest_price))
        return;
    
    if(position.PositionType() == POSITION_TYPE_BUY)
        profit_pips = (latest_price.bid - position.PriceOpen()) / Point() / point_factor;
    else if(position.PositionType() == POSITION_TYPE_SELL)
        profit_pips = (position.PriceOpen() - latest_price.ask) / Point() / point_factor;
    
    // Fast exit if minimum profit reached and RSI shows reversal
    if(profit_pips >= MinProfitPips)
    {
        double rsi[1];
        if(CopyBuffer(rsi_handle, 0, 0, 1, rsi) != 1)
            return;
        
        bool should_exit = false;
        if(position.PositionType() == POSITION_TYPE_BUY && rsi[0] > RSI_Overbought)
            should_exit = true;
        else if(position.PositionType() == POSITION_TYPE_SELL && rsi[0] < RSI_Oversold)
            should_exit = true;
        
        if(should_exit)
        {
            trade.PositionClose(position.Ticket());
            Print("Fast exit executed for ticket: ", position.Ticket());
        }
    }
}

//+------------------------------------------------------------------+
//| Apply trailing stop                                             |
//+------------------------------------------------------------------+
void ApplyTrailingStop()
{
    double new_sl = 0;
    double current_sl = position.StopLoss();
    
    MqlTick latest_price;
    if(!SymbolInfoTick(Symbol(), latest_price))
        return;
    
    if(position.PositionType() == POSITION_TYPE_BUY)
    {
        if(latest_price.bid - position.PriceOpen() >= TrailingStart * Point() * point_factor)
        {
            new_sl = latest_price.bid - TrailingStep * Point() * point_factor;
            
            if(new_sl > current_sl || current_sl == 0)
            {
                trade.PositionModify(position.Ticket(), new_sl, position.TakeProfit());
                Print("Trailing stop updated for buy position: ", position.Ticket());
            }
        }
    }
    else if(position.PositionType() == POSITION_TYPE_SELL)
    {
        if(position.PriceOpen() - latest_price.ask >= TrailingStart * Point() * point_factor)
        {
            new_sl = latest_price.ask + TrailingStep * Point() * point_factor;
            
            if(new_sl < current_sl || current_sl == 0)
            {
                trade.PositionModify(position.Ticket(), new_sl, position.TakeProfit());
                Print("Trailing stop updated for sell position: ", position.Ticket());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Count open positions                                             |
//+------------------------------------------------------------------+
int CountOpenPositions()
{
    int count = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0 && position.SelectByTicket(ticket))
        {
            if(position.Symbol() == Symbol() && position.Magic() == MagicNumber)
                count++;
        }
    }
    return count;
}

//+------------------------------------------------------------------+
//| Calculate daily profit                                           |
//+------------------------------------------------------------------+
double CalculateDailyProfit()
{
    double profit = 0;
    datetime today_start = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
    
    // Check open positions
    for(int i = 0; i < PositionsTotal(); i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0 && position.SelectByTicket(ticket))
        {
            if(position.Symbol() == Symbol() && position.Magic() == MagicNumber)
                profit += position.Profit() + position.Swap() + position.Commission();
        }
    }
    
    // Check history for today
    HistorySelect(today_start, TimeCurrent());
    for(int i = 0; i < HistoryDealsTotal(); i++)
    {
        ulong ticket = HistoryDealGetTicket(i);
        if(ticket > 0)
        {
            string symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
            ulong magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
            
            if(symbol == Symbol() && magic == MagicNumber)
            {
                profit += HistoryDealGetDouble(ticket, DEAL_PROFIT);
                profit += HistoryDealGetDouble(ticket, DEAL_SWAP);
                profit += HistoryDealGetDouble(ticket, DEAL_COMMISSION);
            }
        }
    }
    
    return profit;
}

//+------------------------------------------------------------------+
//| Check if current time is valid for trading                      |
//+------------------------------------------------------------------+
bool IsValidTradingTime()
{
    MqlDateTime dt;
    TimeCurrent(dt);
    int current_hour = dt.hour;
    
    if(StartHour <= EndHour)
        return (current_hour >= StartHour && current_hour < EndHour);
    else
        return (current_hour >= StartHour || current_hour < EndHour);
}

//+------------------------------------------------------------------+
//| Check if it's news time (simplified)                            |
//+------------------------------------------------------------------+
bool IsNewsTime()
{
    MqlDateTime dt;
    TimeCurrent(dt);
    int current_minute = dt.min;
    int current_hour = dt.hour;
    
    // Avoid trading at typical news release times
    if((current_hour == 8 || current_hour == 10 || current_hour == 14 || current_hour == 16) && 
       current_minute >= 28 && current_minute <= 32)
        return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Close all positions                                             |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0 && position.SelectByTicket(ticket))
        {
            if(position.Symbol() == Symbol() && position.Magic() == MagicNumber)
            {
                trade.PositionClose(ticket);
            }
        }
    }
}