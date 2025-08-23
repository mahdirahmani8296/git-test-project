//+------------------------------------------------------------------+
//|                                            AdvancedScalpingEA.mq4 |
//|                                  Copyright 2024, Advanced Trader |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Advanced Trader"
#property link      ""
#property version   "1.00"
#property strict

//--- Input Parameters
input string  EA_Settings = "=== EA Settings ===";
input double  LotSize = 0.01;              // Lot size
input bool    AutoLotSize = true;          // Auto calculate lot size
input double  RiskPercent = 2.0;           // Risk percentage per trade
input int     MagicNumber = 12345;         // Magic number
input int     Slippage = 3;                // Maximum slippage

input string  Scalping_Settings = "=== Scalping Settings ===";
input int     ScalpingTimeframe = 1;       // Scalping timeframe (1=M1, 5=M5)
input double  MinProfitPips = 5;           // Minimum profit in pips
input double  MaxSpread = 3;               // Maximum allowed spread
input bool    UseFastExit = true;          // Use fast exit on profit
input int     MaxOpenTrades = 3;           // Maximum open trades

input string  Indicator_Settings = "=== Indicator Settings ===";
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

input string  Risk_Settings = "=== Risk Management ===";
input bool    UseATR_SL = true;            // Use ATR for stop loss
input double  ATR_SL_Multiplier = 2.0;     // ATR multiplier for SL
input double  FixedSL = 20;                // Fixed SL in pips (if not using ATR)
input double  RiskRewardRatio = 1.5;       // Risk:Reward ratio
input bool    UseTrailingStop = true;      // Use trailing stop
input double  TrailingStart = 10;          // Trailing start in pips
input double  TrailingStep = 5;            // Trailing step in pips

input string  Time_Settings = "=== Trading Time ===";
input bool    UseTimeFilter = true;        // Use time filter
input int     StartHour = 8;               // Start trading hour
input int     EndHour = 18;                // End trading hour
input bool    AvoidNews = true;            // Avoid trading during news

//--- Global Variables
double point_factor;
int total_orders = 0;
datetime last_trade_time = 0;
double daily_profit = 0;
double max_daily_loss = -100;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize point factor for 4/5 digit brokers
    if(Digits == 5 || Digits == 3)
        point_factor = 10;
    else
        point_factor = 1;
    
    Print("Advanced Scalping EA initialized successfully");
    Print("Point factor: ", point_factor);
    Print("Current spread: ", MarketInfo(Symbol(), MODE_SPREAD));
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("Advanced Scalping EA stopped. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check if trading is allowed
    if(!IsTradeAllowed()) return;
    
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
    total_orders = CountOpenOrders();
    
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
    double spread = MarketInfo(Symbol(), MODE_SPREAD);
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
    double rsi = iRSI(Symbol(), ScalpingTimeframe, RSI_Period, PRICE_CLOSE, 0);
    double macd_main = iMACD(Symbol(), ScalpingTimeframe, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 0);
    double macd_signal = iMACD(Symbol(), ScalpingTimeframe, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL, 0);
    double ema_fast = iMA(Symbol(), ScalpingTimeframe, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE, 0);
    double ema_slow = iMA(Symbol(), ScalpingTimeframe, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE, 0);
    double bb_upper = iBands(Symbol(), ScalpingTimeframe, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_UPPER, 0);
    double bb_lower = iBands(Symbol(), ScalpingTimeframe, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_LOWER, 0);
    double bb_middle = iBands(Symbol(), ScalpingTimeframe, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_MAIN, 0);
    
    double current_price = (Ask + Bid) / 2;
    
    // Buy signal conditions
    bool buy_signal = false;
    if(rsi < RSI_Oversold && 
       macd_main > macd_signal && 
       ema_fast > ema_slow && 
       current_price < bb_lower &&
       Ask > ema_fast)
    {
        buy_signal = true;
    }
    
    // Sell signal conditions
    bool sell_signal = false;
    if(rsi > RSI_Overbought && 
       macd_main < macd_signal && 
       ema_fast < ema_slow && 
       current_price > bb_upper &&
       Bid < ema_fast)
    {
        sell_signal = true;
    }
    
    // Additional momentum confirmation
    double momentum = iMomentum(Symbol(), ScalpingTimeframe, 10, PRICE_CLOSE, 0);
    double momentum_prev = iMomentum(Symbol(), ScalpingTimeframe, 10, PRICE_CLOSE, 1);
    
    // Execute trades
    if(buy_signal && momentum > momentum_prev)
    {
        OpenBuyOrder();
    }
    else if(sell_signal && momentum < momentum_prev)
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
    double sl = CalculateStopLoss(OP_BUY);
    double tp = CalculateTakeProfit(OP_BUY, sl);
    
    int ticket = OrderSend(Symbol(), OP_BUY, lot_size, Ask, Slippage, sl, tp, 
                          "Advanced Scalping EA - Buy", MagicNumber, 0, Blue);
    
    if(ticket > 0)
    {
        last_trade_time = TimeCurrent();
        Print("Buy order opened: Ticket=", ticket, " Lot=", lot_size, " SL=", sl, " TP=", tp);
    }
    else
    {
        Print("Error opening buy order: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Open sell order                                                  |
//+------------------------------------------------------------------+
void OpenSellOrder()
{
    double lot_size = CalculateLotSize();
    double sl = CalculateStopLoss(OP_SELL);
    double tp = CalculateTakeProfit(OP_SELL, sl);
    
    int ticket = OrderSend(Symbol(), OP_SELL, lot_size, Bid, Slippage, sl, tp, 
                          "Advanced Scalping EA - Sell", MagicNumber, 0, Red);
    
    if(ticket > 0)
    {
        last_trade_time = TimeCurrent();
        Print("Sell order opened: Ticket=", ticket, " Lot=", lot_size, " SL=", sl, " TP=", tp);
    }
    else
    {
        Print("Error opening sell order: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Calculate lot size                                               |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
    if(!AutoLotSize)
        return LotSize;
    
    double account_balance = AccountBalance();
    double risk_amount = account_balance * RiskPercent / 100.0;
    
    double sl_pips;
    if(UseATR_SL)
    {
        double atr = iATR(Symbol(), ScalpingTimeframe, ATR_Period, 0);
        sl_pips = atr * ATR_SL_Multiplier / Point / point_factor;
    }
    else
    {
        sl_pips = FixedSL;
    }
    
    double pip_value = MarketInfo(Symbol(), MODE_TICKVALUE);
    if(point_factor == 10) pip_value *= 10;
    
    double lot_size = risk_amount / (sl_pips * pip_value);
    
    // Normalize lot size
    double min_lot = MarketInfo(Symbol(), MODE_MINLOT);
    double max_lot = MarketInfo(Symbol(), MODE_MAXLOT);
    double lot_step = MarketInfo(Symbol(), MODE_LOTSTEP);
    
    lot_size = MathMax(min_lot, MathMin(max_lot, MathRound(lot_size / lot_step) * lot_step));
    
    return lot_size;
}

//+------------------------------------------------------------------+
//| Calculate stop loss                                              |
//+------------------------------------------------------------------+
double CalculateStopLoss(int order_type)
{
    double sl = 0;
    
    if(UseATR_SL)
    {
        double atr = iATR(Symbol(), ScalpingTimeframe, ATR_Period, 0);
        double sl_distance = atr * ATR_SL_Multiplier;
        
        if(order_type == OP_BUY)
            sl = Ask - sl_distance;
        else if(order_type == OP_SELL)
            sl = Bid + sl_distance;
    }
    else
    {
        double sl_distance = FixedSL * Point * point_factor;
        
        if(order_type == OP_BUY)
            sl = Ask - sl_distance;
        else if(order_type == OP_SELL)
            sl = Bid + sl_distance;
    }
    
    return NormalizeDouble(sl, Digits);
}

//+------------------------------------------------------------------+
//| Calculate take profit                                            |
//+------------------------------------------------------------------+
double CalculateTakeProfit(int order_type, double stop_loss)
{
    double tp = 0;
    double sl_distance;
    
    if(order_type == OP_BUY)
    {
        sl_distance = Ask - stop_loss;
        tp = Ask + (sl_distance * RiskRewardRatio);
    }
    else if(order_type == OP_SELL)
    {
        sl_distance = stop_loss - Bid;
        tp = Bid - (sl_distance * RiskRewardRatio);
    }
    
    return NormalizeDouble(tp, Digits);
}

//+------------------------------------------------------------------+
//| Manage open positions                                            |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
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
    
    if(OrderType() == OP_BUY)
        profit_pips = (Bid - OrderOpenPrice()) / Point / point_factor;
    else if(OrderType() == OP_SELL)
        profit_pips = (OrderOpenPrice() - Ask) / Point / point_factor;
    
    // Fast exit if minimum profit reached and RSI shows reversal
    if(profit_pips >= MinProfitPips)
    {
        double rsi = iRSI(Symbol(), ScalpingTimeframe, RSI_Period, PRICE_CLOSE, 0);
        
        bool should_exit = false;
        if(OrderType() == OP_BUY && rsi > RSI_Overbought)
            should_exit = true;
        else if(OrderType() == OP_SELL && rsi < RSI_Oversold)
            should_exit = true;
        
        if(should_exit)
        {
            if(OrderType() == OP_BUY)
                OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, Green);
            else
                OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, Red);
            
            Print("Fast exit executed for ticket: ", OrderTicket());
        }
    }
}

//+------------------------------------------------------------------+
//| Apply trailing stop                                             |
//+------------------------------------------------------------------+
void ApplyTrailingStop()
{
    double new_sl = 0;
    double current_sl = OrderStopLoss();
    
    if(OrderType() == OP_BUY)
    {
        double trail_level = Bid - TrailingStart * Point * point_factor;
        
        if(Bid - OrderOpenPrice() >= TrailingStart * Point * point_factor)
        {
            new_sl = Bid - TrailingStep * Point * point_factor;
            
            if(new_sl > current_sl || current_sl == 0)
            {
                OrderModify(OrderTicket(), OrderOpenPrice(), new_sl, OrderTakeProfit(), 0, Blue);
                Print("Trailing stop updated for buy order: ", OrderTicket());
            }
        }
    }
    else if(OrderType() == OP_SELL)
    {
        double trail_level = Ask + TrailingStart * Point * point_factor;
        
        if(OrderOpenPrice() - Ask >= TrailingStart * Point * point_factor)
        {
            new_sl = Ask + TrailingStep * Point * point_factor;
            
            if(new_sl < current_sl || current_sl == 0)
            {
                OrderModify(OrderTicket(), OrderOpenPrice(), new_sl, OrderTakeProfit(), 0, Red);
                Print("Trailing stop updated for sell order: ", OrderTicket());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Count open orders                                               |
//+------------------------------------------------------------------+
int CountOpenOrders()
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
//| Calculate daily profit                                           |
//+------------------------------------------------------------------+
double CalculateDailyProfit()
{
    double profit = 0;
    datetime today_start = StrToTime(TimeToStr(TimeCurrent(), TIME_DATE));
    
    // Check open orders
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
                profit += OrderProfit() + OrderSwap() + OrderCommission();
        }
    }
    
    // Check closed orders from today
    for(int i = 0; i < OrdersHistoryTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber && OrderCloseTime() >= today_start)
                profit += OrderProfit() + OrderSwap() + OrderCommission();
        }
    }
    
    return profit;
}

//+------------------------------------------------------------------+
//| Check if current time is valid for trading                      |
//+------------------------------------------------------------------+
bool IsValidTradingTime()
{
    int current_hour = TimeHour(TimeCurrent());
    
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
    // This is a simplified news filter
    // In practice, you would integrate with a news calendar API
    int current_minute = TimeMinute(TimeCurrent());
    int current_hour = TimeHour(TimeCurrent());
    
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
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
                if(OrderType() == OP_BUY)
                    OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, Green);
                else if(OrderType() == OP_SELL)
                    OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, Red);
            }
        }
    }
}