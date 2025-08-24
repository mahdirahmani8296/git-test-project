//+------------------------------------------------------------------+
//|                                           AdvancedTradingBot.mq4 |
//|                                     Professional Trading Systems |
//|                                            https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Systems"
#property link      "https://www.mql5.com"
#property version   "2.50"
#property strict

//--- Input Parameters
input string GeneralSettings = "========== General Settings ==========";
input double LotSize = 0.01;                    // Fixed lot size
input bool UseAutoLot = true;                   // Use automatic lot sizing
input double RiskPercent = 2.0;                 // Risk percentage per trade
input int MagicNumber = 123456;                 // Magic number for trades
input int Slippage = 3;                         // Slippage in points

input string IndicatorSettings = "========== Indicator Settings ==========";
input int FastMA = 21;                          // Fast Moving Average
input int SlowMA = 50;                          // Slow Moving Average
input int SignalMA = 9;                         // Signal Moving Average
input int RSI_Period = 14;                      // RSI Period
input int RSI_Overbought = 70;                  // RSI Overbought Level
input int RSI_Oversold = 30;                    // RSI Oversold Level
input int MACD_Fast = 12;                       // MACD Fast EMA
input int MACD_Slow = 26;                       // MACD Slow EMA
input int MACD_Signal = 9;                      // MACD Signal
input int BB_Period = 20;                       // Bollinger Bands Period
input double BB_Deviation = 2.0;                // Bollinger Bands Deviation
input int ATR_Period = 14;                      // ATR Period for volatility

input string RiskSettings = "========== Risk Management ==========";
input bool UseStopLoss = true;                  // Use Stop Loss
input bool UseTakeProfit = true;                // Use Take Profit
input double StopLossMultiplier = 2.0;          // SL multiplier based on ATR
input double TakeProfitMultiplier = 3.0;        // TP multiplier based on ATR
input bool UseTrailingStop = true;              // Use trailing stop
input double TrailingStopDistance = 50;         // Trailing stop distance in points
input double TrailingStepSize = 10;             // Trailing step size

input string TimeSettings = "========== Time Filters ==========";
input bool UseTimeFilter = true;                // Use time filter
input int StartHour = 8;                        // Trading start hour
input int EndHour = 22;                         // Trading end hour
input bool TradeMondayToFriday = true;          // Trade only Mon-Fri

input string SymbolSettings = "========== Symbol Optimization ==========";
input bool TradeGold = true;                    // Trade Gold (XAUUSD)
input bool TradeMajorPairs = true;              // Trade major currency pairs
input string GoldSymbol = "XAUUSD";             // Gold symbol name
input double GoldSpreadFilter = 30;             // Max spread for Gold in points

//--- Global Variables
double Point_Value;
int Digits_Adjust;
bool NewBar = false;

//--- Strategy Variables
struct StrategySignals {
    bool BuySignal;
    bool SellSignal;
    double Confidence;
    string Reason;
};

struct RiskManagement {
    double StopLoss;
    double TakeProfit;
    double LotSize;
    double MaxRisk;
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    //--- Initialize point value and digits
    if(Digits == 5 || Digits == 3) {
        Point_Value = Point * 10;
        Digits_Adjust = 10;
    } else {
        Point_Value = Point;
        Digits_Adjust = 1;
    }
    
    //--- Check if trading is allowed
    if(!IsTradeAllowed()) {
        Alert("Trading is not allowed! Please enable AutoTrading.");
        return(INIT_FAILED);
    }
    
    //--- Validate inputs
    if(LotSize <= 0) {
        Alert("Invalid lot size!");
        return(INIT_PARAMETERS_INCORRECT);
    }
    
    if(RiskPercent <= 0 || RiskPercent > 10) {
        Alert("Risk percentage should be between 0.1 and 10!");
        return(INIT_PARAMETERS_INCORRECT);
    }
    
    Print("Advanced Trading Bot initialized successfully");
    Print("Symbol: ", Symbol(), " | Period: ", Period());
    Print("Point Value: ", Point_Value, " | Digits: ", Digits);
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("Advanced Trading Bot deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    //--- Check for new bar
    if(!IsNewBar()) return;
    
    //--- Check time filter
    if(UseTimeFilter && !IsTimeToTrade()) return;
    
    //--- Check symbol filter
    if(!IsSymbolAllowed()) return;
    
    //--- Check spread filter
    if(!IsSpreadAcceptable()) return;
    
    //--- Get market analysis
    StrategySignals signals = AnalyzeMarket();
    
    //--- Process signals
    if(signals.BuySignal && signals.Confidence > 0.7) {
        if(CountOpenPositions(OP_BUY) == 0) {
            OpenBuyOrder(signals);
        }
    }
    
    if(signals.SellSignal && signals.Confidence > 0.7) {
        if(CountOpenPositions(OP_SELL) == 0) {
            OpenSellOrder(signals);
        }
    }
    
    //--- Manage existing positions
    ManagePositions();
}

//+------------------------------------------------------------------+
//| Check for new bar                                               |
//+------------------------------------------------------------------+
bool IsNewBar()
{
    static datetime lastBarTime = 0;
    datetime currentBarTime = Time[0];
    
    if(currentBarTime != lastBarTime) {
        lastBarTime = currentBarTime;
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Check if it's time to trade                                     |
//+------------------------------------------------------------------+
bool IsTimeToTrade()
{
    int currentHour = Hour();
    int currentDay = DayOfWeek();
    
    //--- Check day filter
    if(TradeMondayToFriday && (currentDay == 0 || currentDay == 6)) {
        return false;
    }
    
    //--- Check hour filter
    if(currentHour < StartHour || currentHour >= EndHour) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if symbol is allowed for trading                          |
//+------------------------------------------------------------------+
bool IsSymbolAllowed()
{
    string symbol = Symbol();
    
    //--- Gold symbols
    if(TradeGold && (StringFind(symbol, "GOLD") >= 0 || 
                     StringFind(symbol, "XAU") >= 0 || 
                     symbol == GoldSymbol)) {
        return true;
    }
    
    //--- Major currency pairs
    if(TradeMajorPairs) {
        if(symbol == "EURUSD" || symbol == "GBPUSD" || symbol == "USDJPY" ||
           symbol == "USDCHF" || symbol == "AUDUSD" || symbol == "USDCAD" ||
           symbol == "NZDUSD") {
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if spread is acceptable                                   |
//+------------------------------------------------------------------+
bool IsSpreadAcceptable()
{
    double spread = MarketInfo(Symbol(), MODE_SPREAD);
    string symbol = Symbol();
    
    //--- Gold spread filter
    if(StringFind(symbol, "GOLD") >= 0 || StringFind(symbol, "XAU") >= 0) {
        if(spread > GoldSpreadFilter) {
            return false;
        }
    }
    
    //--- Major pairs spread filter (general)
    if(spread > 50) { // 5 pips for major pairs
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Advanced Market Analysis                                         |
//+------------------------------------------------------------------+
StrategySignals AnalyzeMarket()
{
    StrategySignals signals;
    signals.BuySignal = false;
    signals.SellSignal = false;
    signals.Confidence = 0.0;
    signals.Reason = "";
    
    double confidence = 0.0;
    string reasons = "";
    
    //--- Moving Average Analysis
    double ma_fast = iMA(NULL, 0, FastMA, 0, MODE_EMA, PRICE_CLOSE, 1);
    double ma_slow = iMA(NULL, 0, SlowMA, 0, MODE_EMA, PRICE_CLOSE, 1);
    double ma_fast_prev = iMA(NULL, 0, FastMA, 0, MODE_EMA, PRICE_CLOSE, 2);
    double ma_slow_prev = iMA(NULL, 0, SlowMA, 0, MODE_EMA, PRICE_CLOSE, 2);
    
    bool ma_bullish = (ma_fast > ma_slow) && (ma_fast_prev <= ma_slow_prev);
    bool ma_bearish = (ma_fast < ma_slow) && (ma_fast_prev >= ma_slow_prev);
    
    //--- RSI Analysis
    double rsi = iRSI(NULL, 0, RSI_Period, PRICE_CLOSE, 1);
    double rsi_prev = iRSI(NULL, 0, RSI_Period, PRICE_CLOSE, 2);
    
    bool rsi_bullish = (rsi > RSI_Oversold) && (rsi_prev <= RSI_Oversold);
    bool rsi_bearish = (rsi < RSI_Overbought) && (rsi_prev >= RSI_Overbought);
    bool rsi_neutral = (rsi > RSI_Oversold + 10) && (rsi < RSI_Overbought - 10);
    
    //--- MACD Analysis
    double macd_main = iMACD(NULL, 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 1);
    double macd_signal = iMACD(NULL, 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL, 1);
    double macd_main_prev = iMACD(NULL, 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 2);
    double macd_signal_prev = iMACD(NULL, 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL, 2);
    
    bool macd_bullish = (macd_main > macd_signal) && (macd_main_prev <= macd_signal_prev);
    bool macd_bearish = (macd_main < macd_signal) && (macd_main_prev >= macd_signal_prev);
    
    //--- Bollinger Bands Analysis
    double bb_upper = iBands(NULL, 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_UPPER, 1);
    double bb_lower = iBands(NULL, 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_LOWER, 1);
    double bb_middle = iBands(NULL, 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_MAIN, 1);
    
    double close_price = Close[1];
    bool bb_bullish = (close_price < bb_lower) && (Close[0] > bb_lower);
    bool bb_bearish = (close_price > bb_upper) && (Close[0] < bb_upper);
    
    //--- Price Action Analysis
    double body_size = MathAbs(Close[1] - Open[1]);
    double candle_range = High[1] - Low[1];
    bool strong_bullish_candle = (Close[1] > Open[1]) && (body_size > candle_range * 0.7);
    bool strong_bearish_candle = (Close[1] < Open[1]) && (body_size > candle_range * 0.7);
    
    //--- Volume Analysis (if available)
    double volume_current = Volume[1];
    double volume_avg = 0;
    for(int i = 2; i <= 11; i++) {
        volume_avg += Volume[i];
    }
    volume_avg = volume_avg / 10;
    bool high_volume = volume_current > volume_avg * 1.5;
    
    //--- Trend Strength Analysis
    double atr = iATR(NULL, 0, ATR_Period, 1);
    double price_change = MathAbs(Close[1] - Close[5]);
    bool strong_trend = price_change > atr * 2;
    
    //--- Calculate Buy Signal Confidence
    if(ma_bullish || rsi_bullish || macd_bullish || bb_bullish || strong_bullish_candle) {
        confidence = 0.0;
        
        if(ma_bullish) { confidence += 0.25; reasons += "MA_Bullish "; }
        if(rsi_bullish) { confidence += 0.20; reasons += "RSI_Bullish "; }
        if(macd_bullish) { confidence += 0.25; reasons += "MACD_Bullish "; }
        if(bb_bullish) { confidence += 0.15; reasons += "BB_Bullish "; }
        if(strong_bullish_candle) { confidence += 0.10; reasons += "Strong_Bull_Candle "; }
        if(high_volume) { confidence += 0.05; reasons += "High_Volume "; }
        if(strong_trend && ma_fast > ma_slow) { confidence += 0.10; reasons += "Strong_Bull_Trend "; }
        
        // Confirmation filters
        if(rsi_neutral) confidence += 0.05;
        if(Close[1] > bb_middle) confidence += 0.05;
        
        signals.BuySignal = true;
        signals.Confidence = MathMin(confidence, 1.0);
        signals.Reason = "BUY: " + reasons;
    }
    
    //--- Calculate Sell Signal Confidence
    if(ma_bearish || rsi_bearish || macd_bearish || bb_bearish || strong_bearish_candle) {
        confidence = 0.0;
        
        if(ma_bearish) { confidence += 0.25; reasons = "MA_Bearish "; }
        if(rsi_bearish) { confidence += 0.20; reasons += "RSI_Bearish "; }
        if(macd_bearish) { confidence += 0.25; reasons += "MACD_Bearish "; }
        if(bb_bearish) { confidence += 0.15; reasons += "BB_Bearish "; }
        if(strong_bearish_candle) { confidence += 0.10; reasons += "Strong_Bear_Candle "; }
        if(high_volume) { confidence += 0.05; reasons += "High_Volume "; }
        if(strong_trend && ma_fast < ma_slow) { confidence += 0.10; reasons += "Strong_Bear_Trend "; }
        
        // Confirmation filters
        if(rsi_neutral) confidence += 0.05;
        if(Close[1] < bb_middle) confidence += 0.05;
        
        signals.SellSignal = true;
        signals.Confidence = MathMin(confidence, 1.0);
        signals.Reason = "SELL: " + reasons;
    }
    
    return signals;
}

//+------------------------------------------------------------------+
//| Calculate Dynamic Risk Management                                |
//+------------------------------------------------------------------+
RiskManagement CalculateRiskManagement(int order_type)
{
    RiskManagement risk;
    
    //--- Calculate lot size
    if(UseAutoLot) {
        double account_balance = AccountBalance();
        double risk_amount = account_balance * RiskPercent / 100.0;
        double atr = iATR(NULL, 0, ATR_Period, 1);
        double stop_distance = atr * StopLossMultiplier * Digits_Adjust;
        
        double tick_value = MarketInfo(Symbol(), MODE_TICKVALUE);
        if(tick_value != 0) {
            risk.LotSize = risk_amount / (stop_distance * tick_value);
            risk.LotSize = NormalizeDouble(risk.LotSize, 2);
            risk.LotSize = MathMax(risk.LotSize, MarketInfo(Symbol(), MODE_MINLOT));
            risk.LotSize = MathMin(risk.LotSize, MarketInfo(Symbol(), MODE_MAXLOT));
        } else {
            risk.LotSize = LotSize;
        }
    } else {
        risk.LotSize = LotSize;
    }
    
    //--- Calculate stop loss and take profit
    double atr = iATR(NULL, 0, ATR_Period, 1);
    double current_price = (order_type == OP_BUY) ? Ask : Bid;
    
    if(UseStopLoss) {
        double sl_distance = atr * StopLossMultiplier;
        if(order_type == OP_BUY) {
            risk.StopLoss = current_price - sl_distance;
        } else {
            risk.StopLoss = current_price + sl_distance;
        }
    } else {
        risk.StopLoss = 0;
    }
    
    if(UseTakeProfit) {
        double tp_distance = atr * TakeProfitMultiplier;
        if(order_type == OP_BUY) {
            risk.TakeProfit = current_price + tp_distance;
        } else {
            risk.TakeProfit = current_price - tp_distance;
        }
    } else {
        risk.TakeProfit = 0;
    }
    
    //--- Calculate maximum risk
    if(risk.StopLoss != 0) {
        double stop_distance = MathAbs(current_price - risk.StopLoss);
        double tick_value = MarketInfo(Symbol(), MODE_TICKVALUE);
        risk.MaxRisk = stop_distance * tick_value * risk.LotSize;
    } else {
        risk.MaxRisk = 0;
    }
    
    return risk;
}

//+------------------------------------------------------------------+
//| Open Buy Order                                                   |
//+------------------------------------------------------------------+
void OpenBuyOrder(StrategySignals &signals)
{
    RiskManagement risk = CalculateRiskManagement(OP_BUY);
    
    string comment = "AdvBot_Buy_" + signals.Reason + "_Conf:" + DoubleToStr(signals.Confidence, 2);
    
    int ticket = OrderSend(Symbol(), OP_BUY, risk.LotSize, Ask, Slippage, 
                          risk.StopLoss, risk.TakeProfit, comment, MagicNumber, 0, clrGreen);
    
    if(ticket > 0) {
        Print("Buy order opened successfully. Ticket: ", ticket, 
              " | Lot: ", risk.LotSize, 
              " | SL: ", risk.StopLoss, 
              " | TP: ", risk.TakeProfit,
              " | Risk: $", DoubleToStr(risk.MaxRisk, 2));
    } else {
        Print("Failed to open buy order. Error: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Open Sell Order                                                  |
//+------------------------------------------------------------------+
void OpenSellOrder(StrategySignals &signals)
{
    RiskManagement risk = CalculateRiskManagement(OP_SELL);
    
    string comment = "AdvBot_Sell_" + signals.Reason + "_Conf:" + DoubleToStr(signals.Confidence, 2);
    
    int ticket = OrderSend(Symbol(), OP_SELL, risk.LotSize, Bid, Slippage, 
                          risk.StopLoss, risk.TakeProfit, comment, MagicNumber, 0, clrRed);
    
    if(ticket > 0) {
        Print("Sell order opened successfully. Ticket: ", ticket, 
              " | Lot: ", risk.LotSize, 
              " | SL: ", risk.StopLoss, 
              " | TP: ", risk.TakeProfit,
              " | Risk: $", DoubleToStr(risk.MaxRisk, 2));
    } else {
        Print("Failed to open sell order. Error: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Count Open Positions                                            |
//+------------------------------------------------------------------+
int CountOpenPositions(int order_type = -1)
{
    int count = 0;
    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) {
                if(order_type == -1 || OrderType() == order_type) {
                    count++;
                }
            }
        }
    }
    return count;
}

//+------------------------------------------------------------------+
//| Manage Existing Positions                                       |
//+------------------------------------------------------------------+
void ManagePositions()
{
    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) {
                
                //--- Apply trailing stop
                if(UseTrailingStop) {
                    ApplyTrailingStop(OrderTicket(), OrderType(), OrderOpenPrice(), 
                                    OrderStopLoss(), OrderTakeProfit());
                }
                
                //--- Check for early exit conditions
                CheckEarlyExit(OrderTicket(), OrderType());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Apply Trailing Stop                                             |
//+------------------------------------------------------------------+
void ApplyTrailingStop(int ticket, int order_type, double open_price, double current_sl, double current_tp)
{
    double trail_distance = TrailingStopDistance * Point_Value;
    double step_size = TrailingStepSize * Point_Value;
    double current_price = (order_type == OP_BUY) ? Bid : Ask;
    double new_sl = current_sl;
    
    if(order_type == OP_BUY) {
        double potential_sl = current_price - trail_distance;
        if(potential_sl > current_sl + step_size || current_sl == 0) {
            new_sl = potential_sl;
        }
    } else if(order_type == OP_SELL) {
        double potential_sl = current_price + trail_distance;
        if(potential_sl < current_sl - step_size || current_sl == 0) {
            new_sl = potential_sl;
        }
    }
    
    if(new_sl != current_sl) {
        bool result = OrderModify(ticket, open_price, new_sl, current_tp, 0, clrBlue);
        if(result) {
            Print("Trailing stop applied for ticket: ", ticket, " New SL: ", new_sl);
        }
    }
}

//+------------------------------------------------------------------+
//| Check Early Exit Conditions                                     |
//+------------------------------------------------------------------+
void CheckEarlyExit(int ticket, int order_type)
{
    //--- Get current market conditions
    StrategySignals current_signals = AnalyzeMarket();
    
    //--- Check for opposite strong signals
    bool should_exit = false;
    string exit_reason = "";
    
    if(order_type == OP_BUY && current_signals.SellSignal && current_signals.Confidence > 0.8) {
        should_exit = true;
        exit_reason = "Strong opposite signal detected";
    }
    
    if(order_type == OP_SELL && current_signals.BuySignal && current_signals.Confidence > 0.8) {
        should_exit = true;
        exit_reason = "Strong opposite signal detected";
    }
    
    //--- Check RSI extreme levels
    double rsi = iRSI(NULL, 0, RSI_Period, PRICE_CLOSE, 1);
    if(order_type == OP_BUY && rsi > 85) {
        should_exit = true;
        exit_reason = "RSI extremely overbought";
    }
    
    if(order_type == OP_SELL && rsi < 15) {
        should_exit = true;
        exit_reason = "RSI extremely oversold";
    }
    
    //--- Execute early exit if conditions are met
    if(should_exit) {
        if(OrderSelect(ticket, SELECT_BY_TICKET)) {
            double close_price = (order_type == OP_BUY) ? Bid : Ask;
            bool result = OrderClose(ticket, OrderLots(), close_price, Slippage, clrOrange);
            if(result) {
                Print("Early exit executed for ticket: ", ticket, " Reason: ", exit_reason);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Custom function to get symbol-specific parameters               |
//+------------------------------------------------------------------+
double GetSymbolMultiplier()
{
    string symbol = Symbol();
    
    //--- Gold symbols typically have different pip values
    if(StringFind(symbol, "GOLD") >= 0 || StringFind(symbol, "XAU") >= 0) {
        return 0.1; // Gold typically moves in 0.1 increments
    }
    
    //--- JPY pairs
    if(StringFind(symbol, "JPY") >= 0) {
        return 0.01; // JPY pairs have 2-3 decimal places
    }
    
    //--- Default for major pairs
    return 0.0001; // Standard 4-5 decimal places
}

//+------------------------------------------------------------------+
//| End of Expert Advisor                                           |
//+------------------------------------------------------------------+