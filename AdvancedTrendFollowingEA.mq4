//+------------------------------------------------------------------+
//|                                    AdvancedTrendFollowingEA.mq4 |
//|                                      Professional Trading System |
//|                                            Advanced Trend Expert |
//+------------------------------------------------------------------+
#property copyright "Advanced Trading System"
#property link      ""
#property version   "2.10"
#property strict

//--- Input Parameters
extern string  ===== = "========== GENERAL SETTINGS ==========";
extern int     MagicNumber = 12345;
extern bool    AutoLotSize = true;
extern double  FixedLotSize = 0.01;
extern double  RiskPercent = 2.0;
extern int     MaxSpread = 30;
extern bool    UseNews = true;

extern string  ===== = "========== TREND INDICATORS ==========";
extern int     EMA_Fast = 12;
extern int     EMA_Slow = 26;
extern int     EMA_Filter = 50;
extern int     RSI_Period = 14;
extern double  RSI_Overbought = 70;
extern double  RSI_Oversold = 30;

extern string  ===== = "========== MACD SETTINGS ==========";
extern int     MACD_Fast = 12;
extern int     MACD_Slow = 26;
extern int     MACD_Signal = 9;

extern string  ===== = "========== BOLLINGER BANDS ==========";
extern int     BB_Period = 20;
extern double  BB_Deviation = 2.0;

extern string  ===== = "========== ATR SETTINGS ==========";
extern int     ATR_Period = 14;
extern double  ATR_Multiplier = 2.0;

extern string  ===== = "========== RISK MANAGEMENT ==========";
extern bool    UseDynamicSL = true;
extern bool    UseDynamicTP = true;
extern double  SL_ATR_Multiplier = 2.5;
extern double  TP_ATR_Multiplier = 4.0;
extern double  MinSL_Pips = 15;
extern double  MaxSL_Pips = 100;
extern bool    UseTrailingStop = true;
extern double  TrailingStart = 20;
extern double  TrailingStep = 10;

extern string  ===== = "========== ADVANCED FILTERS ==========";
extern bool    UseVolatilityFilter = true;
extern double  MinVolatility = 0.0001;
extern double  MaxVolatility = 0.005;
extern bool    UseTimeFilter = true;
extern string  TradingStartTime = "08:00";
extern string  TradingEndTime = "20:00";
extern bool    AvoidNews = true;

//--- Global Variables
double Point_Factor;
int Slippage = 3;
bool NewBar = false;
datetime LastBarTime = 0;

//--- Indicator Handles
double EMA_Fast_Current, EMA_Fast_Previous;
double EMA_Slow_Current, EMA_Slow_Previous;
double EMA_Filter_Current;
double RSI_Current, RSI_Previous;
double MACD_Main_Current, MACD_Main_Previous;
double MACD_Signal_Current, MACD_Signal_Previous;
double BB_Upper, BB_Lower, BB_Middle;
double ATR_Current;

//--- Trading Variables
int TotalOrders = 0;
double CurrentProfit = 0;
double MaxDrawdown = 0;
double AccountBalance = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize point factor for different brokers
    if(Digits == 5 || Digits == 3)
        Point_Factor = 10;
    else
        Point_Factor = 1;
        
    Slippage = Slippage * Point_Factor;
    
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
    
    Print("Advanced Trend Following EA initialized successfully");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("Advanced Trend Following EA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check for new bar
    if(Time[0] != LastBarTime)
    {
        NewBar = true;
        LastBarTime = Time[0];
    }
    else
        NewBar = false;
    
    // Update indicators on new bar
    if(NewBar)
    {
        UpdateIndicators();
        
        // Check trading conditions
        if(IsNewOrderAllowed())
        {
            CheckForTrade();
        }
        
        // Manage existing positions
        ManagePositions();
    }
    
    // Always check trailing stop
    if(UseTrailingStop)
        TrailingStop();
}

//+------------------------------------------------------------------+
//| Update all indicators                                            |
//+------------------------------------------------------------------+
void UpdateIndicators()
{
    // EMA values
    EMA_Fast_Current = iMA(NULL, 0, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE, 0);
    EMA_Fast_Previous = iMA(NULL, 0, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE, 1);
    EMA_Slow_Current = iMA(NULL, 0, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE, 0);
    EMA_Slow_Previous = iMA(NULL, 0, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE, 1);
    EMA_Filter_Current = iMA(NULL, 0, EMA_Filter, 0, MODE_EMA, PRICE_CLOSE, 0);
    
    // RSI values
    RSI_Current = iRSI(NULL, 0, RSI_Period, PRICE_CLOSE, 0);
    RSI_Previous = iRSI(NULL, 0, RSI_Period, PRICE_CLOSE, 1);
    
    // MACD values
    MACD_Main_Current = iMACD(NULL, 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 0);
    MACD_Main_Previous = iMACD(NULL, 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 1);
    MACD_Signal_Current = iMACD(NULL, 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL, 0);
    MACD_Signal_Previous = iMACD(NULL, 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL, 1);
    
    // Bollinger Bands
    BB_Upper = iBands(NULL, 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_UPPER, 0);
    BB_Lower = iBands(NULL, 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_LOWER, 0);
    BB_Middle = iBands(NULL, 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_MAIN, 0);
    
    // ATR
    ATR_Current = iATR(NULL, 0, ATR_Period, 0);
}

//+------------------------------------------------------------------+
//| Check if new order is allowed                                   |
//+------------------------------------------------------------------+
bool IsNewOrderAllowed()
{
    // Check spread
    if(MarketInfo(Symbol(), MODE_SPREAD) > MaxSpread)
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
    TotalOrders = CountOrders();
    if(TotalOrders >= 1) // Only one position at a time
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
    if(EMA_Fast_Current > EMA_Slow_Current && EMA_Fast_Previous <= EMA_Slow_Previous)
        trend_signals += 2; // Strong bullish signal
    else if(EMA_Fast_Current > EMA_Slow_Current)
        trend_signals += 1; // Bullish
    
    if(EMA_Fast_Current < EMA_Slow_Current && EMA_Fast_Previous >= EMA_Slow_Previous)
        trend_signals -= 2; // Strong bearish signal
    else if(EMA_Fast_Current < EMA_Slow_Current)
        trend_signals -= 1; // Bearish
    
    // Price vs EMA Filter
    if(Close[0] > EMA_Filter_Current)
        trend_signals += 1;
    else if(Close[0] < EMA_Filter_Current)
        trend_signals -= 1;
    
    // MACD Trend Confirmation
    if(MACD_Main_Current > MACD_Signal_Current && MACD_Main_Previous <= MACD_Signal_Previous)
        trend_signals += 1;
    else if(MACD_Main_Current < MACD_Signal_Current && MACD_Main_Previous >= MACD_Signal_Previous)
        trend_signals -= 1;
    
    return trend_signals;
}

//+------------------------------------------------------------------+
//| Check for trade opportunities                                   |
//+------------------------------------------------------------------+
void CheckForTrade()
{
    int trend_strength = AnalyzeTrend();
    
    // Buy conditions
    if(trend_strength >= 3)
    {
        if(RSI_Current > 30 && RSI_Current < 70) // RSI not in extreme zones
        {
            if(Close[0] > BB_Lower && Close[0] < BB_Upper) // Price within BB
            {
                OpenBuyOrder();
            }
        }
    }
    
    // Sell conditions
    if(trend_strength <= -3)
    {
        if(RSI_Current > 30 && RSI_Current < 70) // RSI not in extreme zones
        {
            if(Close[0] > BB_Lower && Close[0] < BB_Upper) // Price within BB
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
    double stop_loss = CalculateStopLoss(OP_BUY);
    double take_profit = CalculateTakeProfit(OP_BUY);
    
    int ticket = OrderSend(Symbol(), OP_BUY, lot_size, Ask, Slippage, stop_loss, take_profit, 
                          "Advanced Trend EA - Buy", MagicNumber, 0, clrGreen);
    
    if(ticket > 0)
    {
        Print("Buy order opened successfully. Ticket: ", ticket);
    }
    else
    {
        Print("Error opening buy order: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Open Sell Order                                                  |
//+------------------------------------------------------------------+
void OpenSellOrder()
{
    double lot_size = CalculateLotSize();
    double stop_loss = CalculateStopLoss(OP_SELL);
    double take_profit = CalculateTakeProfit(OP_SELL);
    
    int ticket = OrderSend(Symbol(), OP_SELL, lot_size, Bid, Slippage, stop_loss, take_profit, 
                          "Advanced Trend EA - Sell", MagicNumber, 0, clrRed);
    
    if(ticket > 0)
    {
        Print("Sell order opened successfully. Ticket: ", ticket);
    }
    else
    {
        Print("Error opening sell order: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Calculate dynamic lot size                                       |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
    if(!AutoLotSize)
        return FixedLotSize;
    
    double risk_amount = AccountBalance() * RiskPercent / 100;
    double stop_loss_pips = ATR_Current * SL_ATR_Multiplier / Point;
    
    if(stop_loss_pips < MinSL_Pips)
        stop_loss_pips = MinSL_Pips;
    if(stop_loss_pips > MaxSL_Pips)
        stop_loss_pips = MaxSL_Pips;
    
    double tick_value = MarketInfo(Symbol(), MODE_TICKVALUE);
    double lot_size = risk_amount / (stop_loss_pips * tick_value);
    
    // Normalize lot size
    double min_lot = MarketInfo(Symbol(), MODE_MINLOT);
    double max_lot = MarketInfo(Symbol(), MODE_MAXLOT);
    double lot_step = MarketInfo(Symbol(), MODE_LOTSTEP);
    
    lot_size = MathMax(min_lot, MathMin(max_lot, lot_size));
    lot_size = NormalizeDouble(lot_size / lot_step, 0) * lot_step;
    
    return lot_size;
}

//+------------------------------------------------------------------+
//| Calculate dynamic stop loss                                     |
//+------------------------------------------------------------------+
double CalculateStopLoss(int order_type)
{
    if(!UseDynamicSL)
        return 0;
    
    double sl_distance = ATR_Current * SL_ATR_Multiplier;
    
    if(sl_distance / Point < MinSL_Pips)
        sl_distance = MinSL_Pips * Point;
    if(sl_distance / Point > MaxSL_Pips)
        sl_distance = MaxSL_Pips * Point;
    
    if(order_type == OP_BUY)
        return Ask - sl_distance;
    else
        return Bid + sl_distance;
}

//+------------------------------------------------------------------+
//| Calculate dynamic take profit                                   |
//+------------------------------------------------------------------+
double CalculateTakeProfit(int order_type)
{
    if(!UseDynamicTP)
        return 0;
    
    double tp_distance = ATR_Current * TP_ATR_Multiplier;
    
    if(order_type == OP_BUY)
        return Ask + tp_distance;
    else
        return Bid - tp_distance;
}

//+------------------------------------------------------------------+
//| Manage existing positions                                        |
//+------------------------------------------------------------------+
void ManagePositions()
{
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
                // Check for exit conditions
                if(ShouldClosePosition(OrderType()))
                {
                    ClosePosition(OrderTicket());
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check if position should be closed                              |
//+------------------------------------------------------------------+
bool ShouldClosePosition(int order_type)
{
    int trend_strength = AnalyzeTrend();
    
    // Close buy position if trend becomes bearish
    if(order_type == OP_BUY && trend_strength <= -2)
        return true;
    
    // Close sell position if trend becomes bullish
    if(order_type == OP_SELL && trend_strength >= 2)
        return true;
    
    // RSI extreme conditions
    if(order_type == OP_BUY && RSI_Current > RSI_Overbought)
        return true;
    
    if(order_type == OP_SELL && RSI_Current < RSI_Oversold)
        return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Close position                                                   |
//+------------------------------------------------------------------+
void ClosePosition(int ticket)
{
    if(OrderSelect(ticket, SELECT_BY_TICKET))
    {
        bool result = false;
        
        if(OrderType() == OP_BUY)
            result = OrderClose(ticket, OrderLots(), Bid, Slippage, clrRed);
        else if(OrderType() == OP_SELL)
            result = OrderClose(ticket, OrderLots(), Ask, Slippage, clrGreen);
        
        if(result)
            Print("Position closed successfully. Ticket: ", ticket);
        else
            Print("Error closing position: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Trailing stop function                                           |
//+------------------------------------------------------------------+
void TrailingStop()
{
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
                if(OrderType() == OP_BUY)
                {
                    if(Bid - OrderOpenPrice() > TrailingStart * Point_Factor * Point)
                    {
                        double new_sl = Bid - TrailingStep * Point_Factor * Point;
                        if(new_sl > OrderStopLoss())
                        {
                            OrderModify(OrderTicket(), OrderOpenPrice(), new_sl, OrderTakeProfit(), 0, clrBlue);
                        }
                    }
                }
                else if(OrderType() == OP_SELL)
                {
                    if(OrderOpenPrice() - Ask > TrailingStart * Point_Factor * Point)
                    {
                        double new_sl = Ask + TrailingStep * Point_Factor * Point;
                        if(new_sl < OrderStopLoss() || OrderStopLoss() == 0)
                        {
                            OrderModify(OrderTicket(), OrderOpenPrice(), new_sl, OrderTakeProfit(), 0, clrBlue);
                        }
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Count orders                                                     |
//+------------------------------------------------------------------+
int CountOrders()
{
    int count = 0;
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
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
    datetime start_time = StrToTime(TradingStartTime);
    datetime end_time = StrToTime(TradingEndTime);
    datetime current_time = TimeHour(TimeCurrent()) * 3600 + TimeMinute(TimeCurrent()) * 60;
    
    if(start_time <= end_time)
        return (current_time >= start_time && current_time <= end_time);
    else
        return (current_time >= start_time || current_time <= end_time);
}

//+------------------------------------------------------------------+
//| Volatility filter function                                      |
//+------------------------------------------------------------------+
bool IsVolatilityOK()
{
    return (ATR_Current >= MinVolatility && ATR_Current <= MaxVolatility);
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