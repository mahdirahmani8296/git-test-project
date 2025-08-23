//+------------------------------------------------------------------+
//|                                    AdvancedTrendFollowingEA.mq5 |
//|                                      Professional Trading System |
//|                                            Advanced Trend Expert |
//+------------------------------------------------------------------+
#property copyright "Advanced Trading System"
#property link      ""
#property version   "3.10"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//--- Input Parameters
input group "========== GENERAL SETTINGS =========="
input int     MagicNumber = 12345;
input bool    AutoLotSize = true;
input double  FixedLotSize = 0.01;
input double  RiskPercent = 2.0;
input int     MaxSpread = 30;
input bool    UseNews = true;

input group "========== TREND INDICATORS =========="
input int     EMA_Fast = 12;
input int     EMA_Slow = 26;
input int     EMA_Filter = 50;
input int     RSI_Period = 14;
input double  RSI_Overbought = 70;
input double  RSI_Oversold = 30;

input group "========== MACD SETTINGS =========="
input int     MACD_Fast = 12;
input int     MACD_Slow = 26;
input int     MACD_Signal = 9;

input group "========== BOLLINGER BANDS =========="
input int     BB_Period = 20;
input double  BB_Deviation = 2.0;

input group "========== ATR SETTINGS =========="
input int     ATR_Period = 14;
input double  ATR_Multiplier = 2.0;

input group "========== RISK MANAGEMENT =========="
input bool    UseDynamicSL = true;
input bool    UseDynamicTP = true;
input double  SL_ATR_Multiplier = 2.5;
input double  TP_ATR_Multiplier = 4.0;
input double  MinSL_Pips = 15;
input double  MaxSL_Pips = 100;
input bool    UseTrailingStop = true;
input double  TrailingStart = 20;
input double  TrailingStep = 10;

input group "========== ADVANCED FILTERS =========="
input bool    UseVolatilityFilter = true;
input double  MinVolatility = 0.0001;
input double  MaxVolatility = 0.005;
input bool    UseTimeFilter = true;
input string  TradingStartTime = "08:00";
input string  TradingEndTime = "20:00";
input bool    AvoidNews = true;

//--- Global Variables
CTrade trade;
CPositionInfo position;
COrderInfo order;

double Point_Factor;
int Slippage = 3;
bool NewBar = false;
datetime LastBarTime = 0;

//--- Indicator Handles
int handle_EMA_Fast;
int handle_EMA_Slow;
int handle_EMA_Filter;
int handle_RSI;
int handle_MACD;
int handle_BB;
int handle_ATR;

//--- Indicator Buffers
double EMA_Fast_Buffer[];
double EMA_Slow_Buffer[];
double EMA_Filter_Buffer[];
double RSI_Buffer[];
double MACD_Main_Buffer[];
double MACD_Signal_Buffer[];
double BB_Upper_Buffer[];
double BB_Lower_Buffer[];
double BB_Middle_Buffer[];
double ATR_Buffer[];

//--- Trading Variables
int TotalPositions = 0;
double CurrentProfit = 0;
double MaxDrawdown = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize point factor for different brokers
    if(_Digits == 5 || _Digits == 3)
        Point_Factor = 10;
    else
        Point_Factor = 1;
        
    // Set trade parameters
    trade.SetExpertMagicNumber(MagicNumber);
    trade.SetDeviationInPoints(Slippage * Point_Factor);
    trade.SetTypeFilling(ORDER_FILLING_FOK);
    trade.SetTypeExpiration(ORDER_TIME_GTC);
    
    // Initialize indicators
    handle_EMA_Fast = iMA(_Symbol, PERIOD_CURRENT, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
    handle_EMA_Slow = iMA(_Symbol, PERIOD_CURRENT, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
    handle_EMA_Filter = iMA(_Symbol, PERIOD_CURRENT, EMA_Filter, 0, MODE_EMA, PRICE_CLOSE);
    handle_RSI = iRSI(_Symbol, PERIOD_CURRENT, RSI_Period, PRICE_CLOSE);
    handle_MACD = iMACD(_Symbol, PERIOD_CURRENT, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE);
    handle_BB = iBands(_Symbol, PERIOD_CURRENT, BB_Period, 0, BB_Deviation, PRICE_CLOSE);
    handle_ATR = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);
    
    // Validate indicators
    if(handle_EMA_Fast == INVALID_HANDLE || handle_EMA_Slow == INVALID_HANDLE ||
       handle_EMA_Filter == INVALID_HANDLE || handle_RSI == INVALID_HANDLE ||
       handle_MACD == INVALID_HANDLE || handle_BB == INVALID_HANDLE ||
       handle_ATR == INVALID_HANDLE)
    {
        Alert("Failed to initialize indicators!");
        return(INIT_FAILED);
    }
    
    // Validate inputs
    if(EMA_Fast >= EMA_Slow)
    {
        Alert("EMA Fast period must be less than EMA Slow period!");
        return(INIT_FAILED);
    }
    
    if(RiskPercent <= 0 || RiskPercent > 10)
    {
        Alert("Risk percent must be between 0.1 and 10!");
        return(INIT_FAILED);
    }
    
    // Set array properties
    ArraySetAsSeries(EMA_Fast_Buffer, true);
    ArraySetAsSeries(EMA_Slow_Buffer, true);
    ArraySetAsSeries(EMA_Filter_Buffer, true);
    ArraySetAsSeries(RSI_Buffer, true);
    ArraySetAsSeries(MACD_Main_Buffer, true);
    ArraySetAsSeries(MACD_Signal_Buffer, true);
    ArraySetAsSeries(BB_Upper_Buffer, true);
    ArraySetAsSeries(BB_Lower_Buffer, true);
    ArraySetAsSeries(BB_Middle_Buffer, true);
    ArraySetAsSeries(ATR_Buffer, true);
    
    Print("Advanced Trend Following EA MT5 initialized successfully");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release indicator handles
    IndicatorRelease(handle_EMA_Fast);
    IndicatorRelease(handle_EMA_Slow);
    IndicatorRelease(handle_EMA_Filter);
    IndicatorRelease(handle_RSI);
    IndicatorRelease(handle_MACD);
    IndicatorRelease(handle_BB);
    IndicatorRelease(handle_ATR);
    
    Print("Advanced Trend Following EA MT5 deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check for new bar
    if(iTime(_Symbol, PERIOD_CURRENT, 0) != LastBarTime)
    {
        NewBar = true;
        LastBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    }
    else
        NewBar = false;
    
    // Update indicators on new bar
    if(NewBar)
    {
        if(UpdateIndicators())
        {
            // Check trading conditions
            if(IsNewOrderAllowed())
            {
                CheckForTrade();
            }
            
            // Manage existing positions
            ManagePositions();
        }
    }
    
    // Always check trailing stop
    if(UseTrailingStop)
        TrailingStop();
}

//+------------------------------------------------------------------+
//| Update all indicators                                            |
//+------------------------------------------------------------------+
bool UpdateIndicators()
{
    // Copy indicator data
    if(CopyBuffer(handle_EMA_Fast, 0, 0, 2, EMA_Fast_Buffer) < 2) return false;
    if(CopyBuffer(handle_EMA_Slow, 0, 0, 2, EMA_Slow_Buffer) < 2) return false;
    if(CopyBuffer(handle_EMA_Filter, 0, 0, 1, EMA_Filter_Buffer) < 1) return false;
    if(CopyBuffer(handle_RSI, 0, 0, 2, RSI_Buffer) < 2) return false;
    if(CopyBuffer(handle_MACD, MAIN_LINE, 0, 2, MACD_Main_Buffer) < 2) return false;
    if(CopyBuffer(handle_MACD, SIGNAL_LINE, 0, 2, MACD_Signal_Buffer) < 2) return false;
    if(CopyBuffer(handle_BB, UPPER_BAND, 0, 1, BB_Upper_Buffer) < 1) return false;
    if(CopyBuffer(handle_BB, LOWER_BAND, 0, 1, BB_Lower_Buffer) < 1) return false;
    if(CopyBuffer(handle_BB, BASE_LINE, 0, 1, BB_Middle_Buffer) < 1) return false;
    if(CopyBuffer(handle_ATR, 0, 0, 1, ATR_Buffer) < 1) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if new order is allowed                                   |
//+------------------------------------------------------------------+
bool IsNewOrderAllowed()
{
    // Check spread
    if(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > MaxSpread)
        return false;
    
    // Check time filter
    if(UseTimeFilter && !IsTimeToTrade())
        return false;
    
    // Check volatility filter
    if(UseVolatilityFilter && !IsVolatilityOK())
        return false;
    
    // Check news filter
    if(AvoidNews && IsNewsTime())
        return false;
    
    // Check maximum positions
    TotalPositions = CountPositions();
    if(TotalPositions >= 1) // Only one position at a time
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Advanced trend analysis                                          |
//+------------------------------------------------------------------+
int AnalyzeTrend()
{
    int trend_signals = 0;
    
    // EMA Trend Analysis
    if(EMA_Fast_Buffer[0] > EMA_Slow_Buffer[0] && EMA_Fast_Buffer[1] <= EMA_Slow_Buffer[1])
        trend_signals += 2; // Strong bullish signal
    else if(EMA_Fast_Buffer[0] > EMA_Slow_Buffer[0])
        trend_signals += 1; // Bullish
    
    if(EMA_Fast_Buffer[0] < EMA_Slow_Buffer[0] && EMA_Fast_Buffer[1] >= EMA_Slow_Buffer[1])
        trend_signals -= 2; // Strong bearish signal
    else if(EMA_Fast_Buffer[0] < EMA_Slow_Buffer[0])
        trend_signals -= 1; // Bearish
    
    // Price vs EMA Filter
    double current_close = iClose(_Symbol, PERIOD_CURRENT, 0);
    if(current_close > EMA_Filter_Buffer[0])
        trend_signals += 1;
    else if(current_close < EMA_Filter_Buffer[0])
        trend_signals -= 1;
    
    // MACD Trend Confirmation
    if(MACD_Main_Buffer[0] > MACD_Signal_Buffer[0] && MACD_Main_Buffer[1] <= MACD_Signal_Buffer[1])
        trend_signals += 1;
    else if(MACD_Main_Buffer[0] < MACD_Signal_Buffer[0] && MACD_Main_Buffer[1] >= MACD_Signal_Buffer[1])
        trend_signals -= 1;
    
    return trend_signals;
}

//+------------------------------------------------------------------+
//| Check for trade opportunities                                   |
//+------------------------------------------------------------------+
void CheckForTrade()
{
    int trend_strength = AnalyzeTrend();
    double current_close = iClose(_Symbol, PERIOD_CURRENT, 0);
    
    // Buy conditions
    if(trend_strength >= 3)
    {
        if(RSI_Buffer[0] > 30 && RSI_Buffer[0] < 70) // RSI not in extreme zones
        {
            if(current_close > BB_Lower_Buffer[0] && current_close < BB_Upper_Buffer[0]) // Price within BB
            {
                OpenBuyOrder();
            }
        }
    }
    
    // Sell conditions
    if(trend_strength <= -3)
    {
        if(RSI_Buffer[0] > 30 && RSI_Buffer[0] < 70) // RSI not in extreme zones
        {
            if(current_close > BB_Lower_Buffer[0] && current_close < BB_Upper_Buffer[0]) // Price within BB
            {
                OpenSellOrder();
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Open Buy Order                                                   |
//+------------------------------------------------------------------+
void OpenBuyOrder()
{
    double lot_size = CalculateLotSize();
    double stop_loss = CalculateStopLoss(ORDER_TYPE_BUY);
    double take_profit = CalculateTakeProfit(ORDER_TYPE_BUY);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    if(trade.Buy(lot_size, _Symbol, ask, stop_loss, take_profit, "Advanced Trend EA - Buy"))
    {
        Print("Buy order opened successfully. Ticket: ", trade.ResultOrder());
    }
    else
    {
        Print("Error opening buy order: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
    }
}

//+------------------------------------------------------------------+
//| Open Sell Order                                                  |
//+------------------------------------------------------------------+
void OpenSellOrder()
{
    double lot_size = CalculateLotSize();
    double stop_loss = CalculateStopLoss(ORDER_TYPE_SELL);
    double take_profit = CalculateTakeProfit(ORDER_TYPE_SELL);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    if(trade.Sell(lot_size, _Symbol, bid, stop_loss, take_profit, "Advanced Trend EA - Sell"))
    {
        Print("Sell order opened successfully. Ticket: ", trade.ResultOrder());
    }
    else
    {
        Print("Error opening sell order: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
    }
}

//+------------------------------------------------------------------+
//| Calculate dynamic lot size                                       |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
    if(!AutoLotSize)
        return FixedLotSize;
    
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amount = balance * RiskPercent / 100;
    double stop_loss_pips = ATR_Buffer[0] * SL_ATR_Multiplier / _Point;
    
    if(stop_loss_pips < MinSL_Pips)
        stop_loss_pips = MinSL_Pips;
    if(stop_loss_pips > MaxSL_Pips)
        stop_loss_pips = MaxSL_Pips;
    
    double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double lot_size = risk_amount / (stop_loss_pips * tick_value);
    
    // Normalize lot size
    double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    lot_size = MathMax(min_lot, MathMin(max_lot, lot_size));
    lot_size = NormalizeDouble(lot_size / lot_step, 0) * lot_step;
    
    return lot_size;
}

//+------------------------------------------------------------------+
//| Calculate dynamic stop loss                                     |
//+------------------------------------------------------------------+
double CalculateStopLoss(ENUM_ORDER_TYPE order_type)
{
    if(!UseDynamicSL)
        return 0;
    
    double sl_distance = ATR_Buffer[0] * SL_ATR_Multiplier;
    
    if(sl_distance / _Point < MinSL_Pips)
        sl_distance = MinSL_Pips * _Point;
    if(sl_distance / _Point > MaxSL_Pips)
        sl_distance = MaxSL_Pips * _Point;
    
    if(order_type == ORDER_TYPE_BUY)
        return SymbolInfoDouble(_Symbol, SYMBOL_ASK) - sl_distance;
    else
        return SymbolInfoDouble(_Symbol, SYMBOL_BID) + sl_distance;
}

//+------------------------------------------------------------------+
//| Calculate dynamic take profit                                   |
//+------------------------------------------------------------------+
double CalculateTakeProfit(ENUM_ORDER_TYPE order_type)
{
    if(!UseDynamicTP)
        return 0;
    
    double tp_distance = ATR_Buffer[0] * TP_ATR_Multiplier;
    
    if(order_type == ORDER_TYPE_BUY)
        return SymbolInfoDouble(_Symbol, SYMBOL_ASK) + tp_distance;
    else
        return SymbolInfoDouble(_Symbol, SYMBOL_BID) - tp_distance;
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
            if(position.Symbol() == _Symbol && position.Magic() == MagicNumber)
            {
                // Check for exit conditions
                if(ShouldClosePosition(position.PositionType()))
                {
                    ClosePosition(position.Ticket());
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check if position should be closed                              |
//+------------------------------------------------------------------+
bool ShouldClosePosition(ENUM_POSITION_TYPE position_type)
{
    int trend_strength = AnalyzeTrend();
    
    // Close buy position if trend becomes bearish
    if(position_type == POSITION_TYPE_BUY && trend_strength <= -2)
        return true;
    
    // Close sell position if trend becomes bullish
    if(position_type == POSITION_TYPE_SELL && trend_strength >= 2)
        return true;
    
    // RSI extreme conditions
    if(position_type == POSITION_TYPE_BUY && RSI_Buffer[0] > RSI_Overbought)
        return true;
    
    if(position_type == POSITION_TYPE_SELL && RSI_Buffer[0] < RSI_Oversold)
        return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Close position                                                   |
//+------------------------------------------------------------------+
void ClosePosition(ulong ticket)
{
    if(trade.PositionClose(ticket))
    {
        Print("Position closed successfully. Ticket: ", ticket);
    }
    else
    {
        Print("Error closing position: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
    }
}

//+------------------------------------------------------------------+
//| Trailing stop function                                           |
//+------------------------------------------------------------------+
void TrailingStop()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Symbol() == _Symbol && position.Magic() == MagicNumber)
            {
                double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                
                if(position.PositionType() == POSITION_TYPE_BUY)
                {
                    if(bid - position.PriceOpen() > TrailingStart * Point_Factor * _Point)
                    {
                        double new_sl = bid - TrailingStep * Point_Factor * _Point;
                        if(new_sl > position.StopLoss())
                        {
                            trade.PositionModify(position.Ticket(), new_sl, position.TakeProfit());
                        }
                    }
                }
                else if(position.PositionType() == POSITION_TYPE_SELL)
                {
                    if(position.PriceOpen() - ask > TrailingStart * Point_Factor * _Point)
                    {
                        double new_sl = ask + TrailingStep * Point_Factor * _Point;
                        if(new_sl < position.StopLoss() || position.StopLoss() == 0)
                        {
                            trade.PositionModify(position.Ticket(), new_sl, position.TakeProfit());
                        }
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Count positions                                                  |
//+------------------------------------------------------------------+
int CountPositions()
{
    int count = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Symbol() == _Symbol && position.Magic() == MagicNumber)
                count++;
        }
    }
    return count;
}

//+------------------------------------------------------------------+
//| Time filter function                                             |
//+------------------------------------------------------------------+
bool IsTimeToTrade()
{
    MqlDateTime time_struct;
    TimeToStruct(TimeCurrent(), time_struct);
    
    string start_time_str = TradingStartTime;
    string end_time_str = TradingEndTime;
    
    int start_hour = (int)StringSubstr(start_time_str, 0, 2);
    int start_minute = (int)StringSubstr(start_time_str, 3, 2);
    int end_hour = (int)StringSubstr(end_time_str, 0, 2);
    int end_minute = (int)StringSubstr(end_time_str, 3, 2);
    
    int current_minutes = time_struct.hour * 60 + time_struct.min;
    int start_minutes = start_hour * 60 + start_minute;
    int end_minutes = end_hour * 60 + end_minute;
    
    if(start_minutes <= end_minutes)
        return (current_minutes >= start_minutes && current_minutes <= end_minutes);
    else
        return (current_minutes >= start_minutes || current_minutes <= end_minutes);
}

//+------------------------------------------------------------------+
//| Volatility filter function                                      |
//+------------------------------------------------------------------+
bool IsVolatilityOK()
{
    return (ATR_Buffer[0] >= MinVolatility && ATR_Buffer[0] <= MaxVolatility);
}

//+------------------------------------------------------------------+
//| News filter function                                             |
//+------------------------------------------------------------------+
bool IsNewsTime()
{
    // This is a placeholder - in real implementation you would
    // check against an economic calendar or news feed
    return false;
}

//+------------------------------------------------------------------+