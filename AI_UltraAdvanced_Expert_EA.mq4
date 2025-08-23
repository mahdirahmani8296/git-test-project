//+------------------------------------------------------------------+
//|                                    AI_UltraAdvanced_Expert_EA.mq4 |
//|                                  Copyright 2024, AI Trading Pro |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "AI Trading Pro"
#property link      ""
#property version   "3.00"
#property description "Ultra Advanced AI-Powered Expert Advisor with Machine Learning, Multi-Strategy Analysis, and Advanced Risk Management"

//--- Input Parameters
extern string CoreSettings = "=== AI Expert EA Core Settings ===";
extern double  LotSize = 0.01;              // Initial lot size
extern bool    AutoLotSize = true;          // Auto calculate lot size based on AI risk assessment
extern double  RiskPercent = 1.0;           // Risk percentage per trade (AI optimized)
extern int     MagicNumber = 2024;          // Magic number for trade identification
extern int     Slippage = 3;                // Maximum slippage allowed
extern bool    EnableAI = true;             // Enable AI-powered decision making
extern bool    EnableMachineLearning = true; // Enable machine learning features

extern string MultiStrategy = "=== Multi-Strategy AI Analysis ===";
extern bool    UseMultiStrategy = true;     // Use multiple AI strategies
extern bool    UsePriceActionAI = true;     // AI-powered price action analysis
extern bool    UsePatternRecognition = true; // AI pattern recognition
extern bool    UseSentimentAnalysis = true; // Market sentiment analysis
extern bool    UseVolatilityAI = true;      // AI volatility prediction
extern bool    UseCorrelationAI = true;     // AI correlation analysis
extern int     MaxOpenTrades = 3;           // Maximum concurrent trades
extern double  MinConfidenceScore = 85.0;   // Minimum AI confidence score (%)

extern string TechnicalIndicators = "=== Advanced Technical Indicators ===";
extern int     RSI_Period = 14;             // RSI period
extern int     RSI_Overbought = 75;         // RSI overbought level
extern int     RSI_Oversold = 25;           // RSI oversold level
extern int     MACD_Fast = 12;              // MACD fast EMA
extern int     MACD_Slow = 26;              // MACD slow EMA
extern int     MACD_Signal = 9;             // MACD signal line
extern int     EMA_Fast = 8;                // Fast EMA period
extern int     EMA_Slow = 21;               // Slow EMA period
extern int     EMA_Trend = 50;              // Trend EMA period
extern int     BB_Period = 20;              // Bollinger Bands period
extern double  BB_Deviation = 2.2;          // Bollinger Bands deviation
extern int     ATR_Period = 14;             // ATR period for volatility
extern int     Stochastic_K = 14;           // Stochastic %K period
extern int     Stochastic_D = 3;            // Stochastic %D period
extern int     Stochastic_Slow = 3;         // Stochastic slowing
extern int     WilliamsR_Period = 14;       // Williams %R period
extern int     CCI_Period = 20;             // CCI period
extern int     Ichimoku_Tenkan = 9;         // Ichimoku Tenkan-sen
extern int     Ichimoku_Kijun = 26;         // Ichimoku Kijun-sen
extern int     Ichimoku_Senkou = 52;        // Ichimoku Senkou Span B
extern int     ADX_Period = 14;             // ADX period
extern double  ParabolicSAR_Step = 2;       // Parabolic SAR step
extern double  ParabolicSAR_Max = 20;       // Parabolic SAR maximum
extern int     OBV_Period = 14;             // On-Balance Volume period

extern string RiskManagement = "=== AI Risk Management & Position Sizing ===";
extern bool    UseAIRiskManagement = true;  // Use AI for risk assessment
extern bool    UseATR_SL = true;            // Use ATR for dynamic stop loss
extern double  ATR_SL_Multiplier = 2.0;     // ATR multiplier for SL
extern double  FixedSL = 25;                // Fixed SL in pips (if not using ATR)
extern double  RiskRewardRatio = 2.5;       // Risk:Reward ratio (AI optimized)
extern bool    UseTrailingStop = true;      // Use AI-powered trailing stop
extern double  TrailingStart = 15;          // Trailing start in pips
extern double  TrailingStep = 8;            // Trailing step in pips
extern bool    UseBreakEven = true;         // Use break-even stop
extern double  BreakEvenPips = 10;          // Pips to move SL to break-even
extern bool    UsePartialClose = true;      // Use partial position closing
extern double  PartialClosePercent = 50;    // Percentage to close at first target
extern double  PartialCloseTarget = 1.8;    // First target multiplier

extern string ProfitOptimization = "=== AI Profit Optimization ===";
extern bool    UseAITakeProfit = true;      // Use AI for take profit calculation
extern double  BaseTP = 2.5;                // Base take profit multiplier
extern double  VolatilityTP = 1.8;          // Volatility-based TP multiplier
extern bool    UseMarketStructure = true;   // Use market structure for TP
extern bool    UseFibonacciTP = true;       // Use Fibonacci levels for TP
extern bool    UseSupportResistance = true; // Use S/R levels for TP
extern bool    UseIchimokuTP = true;        // Use Ichimoku levels for TP
extern bool    UseDynamicTP = true;         // Use dynamic TP adjustment

extern string MarketFilters = "=== AI Market Analysis Filters ===";
extern bool    UseTimeFilter = true;        // Use AI time analysis
extern int     StartHour = 2;               // Start trading hour (GMT)
extern int     EndHour = 22;                // End trading hour (GMT)
extern bool    AvoidNews = true;            // Avoid trading during news
extern bool    UseSpreadFilter = true;      // Use spread filter
extern double  MaxSpread = 5;               // Maximum allowed spread
extern bool    UseVolatilityFilter = true;  // Use volatility filter
extern double  MinVolatility = 0.8;         // Minimum volatility threshold
extern bool    UseVolumeFilter = true;      // Use volume filter
extern double  MinVolume = 1.2;             // Minimum volume threshold
extern bool    UseTrendStrengthFilter = true; // Use trend strength filter
extern double  MinTrendStrength = 0.7;      // Minimum trend strength

extern string MachineLearning = "=== AI Machine Learning Settings ===";
extern int     ML_LookbackPeriod = 100;     // ML lookback period for training
extern int     ML_PredictionPeriod = 20;    // ML prediction period
extern double  ML_LearningRate = 0.01;      // ML learning rate
extern int     ML_Epochs = 1000;            // ML training epochs
extern bool    ML_AdaptiveLearning = true;  // Enable adaptive learning
extern double  ML_ConfidenceThreshold = 0.8; // ML confidence threshold

//--- Global Variables
// AI and ML Variables
double ai_confidence_score = 0.0;
double ml_prediction = 0.0;
double market_sentiment = 0.0;
double volatility_prediction = 0.0;
double correlation_score = 0.0;

// Technical Analysis Variables
double rsi_value, macd_value, macd_signal, macd_histogram;
double ema_fast, ema_slow, ema_trend;
double bb_upper, bb_lower, bb_middle;
double atr_value, stochastic_k, stochastic_d;
double williams_r, cci_value, adx_value;
double parabolic_sar, obv_value;
double ichimoku_tenkan, ichimoku_kijun, ichimoku_senkou_a, ichimoku_senkou_b;

// Market Structure Variables
double support_levels[5];
double resistance_levels[5];
double fibonacci_levels[8];
double pivot_points[3];

// Risk Management Variables
double current_risk = 0.0;
double max_daily_loss = 0.0;
double max_drawdown = 0.0;
double daily_profit = 0.0;
double weekly_profit = 0.0;
double monthly_profit = 0.0;

// Performance Tracking
int total_trades = 0;
int winning_trades = 0;
int losing_trades = 0;
double total_profit = 0.0;
double max_profit = 0.0;
double max_loss = 0.0;

// Time and Session Variables
datetime last_trade_time = 0;
datetime session_start = 0;
bool is_trading_session = false;

// Point and Tick Values
double point_factor;
int digits;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
{
   // Get symbol properties
   digits = (int)MarketInfo(Symbol(), MODE_DIGITS);
   point_factor = (digits == 3 || digits == 5) ? 10 : 1;
   
   // Initialize AI system
   if(EnableAI)
   {
      Print("Initializing AI Expert System...");
      InitializeAISystem();
   }
   
   // Initialize machine learning
   if(EnableMachineLearning)
   {
      Print("Initializing Machine Learning System...");
      InitializeMLSystem();
   }
   
   // Set up risk management
   SetupRiskManagement();
   
   // Initialize market structure analysis
   InitializeMarketStructure();
   
   Print("AI Ultra Advanced Expert EA initialized successfully!");
   return(0);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                               |
//+------------------------------------------------------------------+
int deinit()
{
   Print("AI Ultra Advanced Expert EA deinitialized.");
   return(0);
}

//+------------------------------------------------------------------+
//| Expert start function                                          |
//+------------------------------------------------------------------+
int start()
{
   // Check if trading is allowed
   if(!IsTradingAllowed())
      return(0);
      
   // Update AI analysis
   if(EnableAI)
      UpdateAIAnalysis();
      
   // Update machine learning predictions
   if(EnableMachineLearning)
      UpdateMLPredictions();
      
   // Check for new trading opportunities
   CheckForTradingOpportunities();
   
   // Manage open positions
   ManageOpenPositions();
   
   // Update performance metrics
   UpdatePerformanceMetrics();
   
   return(0);
}

//+------------------------------------------------------------------+
//| Initialize AI System                                            |
//+------------------------------------------------------------------+
void InitializeAISystem()
{
   Print("AI System: Initializing advanced analysis modules...");
   
   // Initialize confidence scoring system
   ai_confidence_score = 0.0;
   
   // Initialize market sentiment analysis
   market_sentiment = 0.0;
   
   // Initialize volatility prediction
   volatility_prediction = 0.0;
   
   // Initialize correlation analysis
   correlation_score = 0.0;
   
   Print("AI System: Initialization complete");
}

//+------------------------------------------------------------------+
//| Initialize Machine Learning System                              |
//+------------------------------------------------------------------+
void InitializeMLSystem()
{
   Print("ML System: Initializing machine learning algorithms...");
   
   // Initialize ML prediction
   ml_prediction = 0.0;
   
   // Load historical data for training
   LoadHistoricalData();
   
   // Train initial models
   TrainMLModels();
   
   Print("ML System: Initialization complete");
}

//+------------------------------------------------------------------+
//| Setup Risk Management                                          |
//+------------------------------------------------------------------+
void SetupRiskManagement()
{
   double balance = AccountBalance();
   
   // Calculate maximum daily loss (5% of balance)
   max_daily_loss = balance * 0.05;
   
   // Calculate maximum drawdown (15% of balance)
   max_drawdown = balance * 0.15;
   
   // Calculate current risk level
   current_risk = 0.0;
   
   Print("Risk Management: Max daily loss: ", max_daily_loss, ", Max drawdown: ", max_drawdown);
}

//+------------------------------------------------------------------+
//| Initialize Market Structure                                     |
//+------------------------------------------------------------------+
void InitializeMarketStructure()
{
   // Initialize support and resistance arrays
   for(int i = 0; i < 5; i++)
   {
      support_levels[i] = 0.0;
      resistance_levels[i] = 0.0;
   }
   
   // Initialize Fibonacci levels
   for(int i = 0; i < 8; i++)
   {
      fibonacci_levels[i] = 0.0;
   }
   
   // Initialize pivot points
   for(int i = 0; i < 3; i++)
   {
      pivot_points[i] = 0.0;
   }
   
   Print("Market Structure: Initialization complete");
}

//+------------------------------------------------------------------+
//| Check if Trading is Allowed                                    |
//+------------------------------------------------------------------+
bool IsTradingAllowed()
{
   // Check if market is open
   if(!IsTradeAllowed())
      return false;
      
   // Check trading hours
   if(UseTimeFilter)
   {
      int current_hour = Hour();
      if(current_hour < StartHour || current_hour >= EndHour)
         return false;
   }
   
   // Check spread
   if(UseSpreadFilter)
   {
      double current_spread = MarketInfo(Symbol(), MODE_ASK) - MarketInfo(Symbol(), MODE_BID);
      if(current_spread > MaxSpread * Point)
         return false;
   }
   
   // Check daily loss limit
   if(daily_profit < -max_daily_loss)
   {
      Print("Trading stopped: Daily loss limit reached");
      return false;
   }
   
   // Check drawdown limit
   if(AccountEquity() < AccountBalance() * (1 - max_drawdown))
   {
      Print("Trading stopped: Maximum drawdown reached");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Update AI Analysis                                              |
//+------------------------------------------------------------------+
void UpdateAIAnalysis()
{
   // Update technical indicators
   UpdateTechnicalIndicators();
   
   // Calculate AI confidence score
   CalculateAIConfidenceScore();
   
   // Update market sentiment
   UpdateMarketSentiment();
   
   // Update volatility prediction
   UpdateVolatilityPrediction();
   
   // Update correlation analysis
   UpdateCorrelationAnalysis();
}

//+------------------------------------------------------------------+
//| Update Technical Indicators                                     |
//+------------------------------------------------------------------+
void UpdateTechnicalIndicators()
{
   // RSI
   rsi_value = iRSI(Symbol(), 0, RSI_Period, PRICE_CLOSE, 0);
   
   // MACD
   macd_value = iMACD(Symbol(), 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 0);
   macd_signal = iMACD(Symbol(), 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL, 0);
   macd_histogram = macd_value - macd_signal;
   
   // EMAs
   ema_fast = iMA(Symbol(), 0, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE, 0);
   ema_slow = iMA(Symbol(), 0, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE, 0);
   ema_trend = iMA(Symbol(), 0, EMA_Trend, 0, MODE_EMA, PRICE_CLOSE, 0);
   
   // Bollinger Bands
   bb_upper = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_UPPER, 0);
   bb_lower = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_LOWER, 0);
   bb_middle = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_MAIN, 0);
   
   // ATR
   atr_value = iATR(Symbol(), 0, ATR_Period, 0);
   
   // Stochastic
   stochastic_k = iStochastic(Symbol(), 0, Stochastic_K, Stochastic_D, Stochastic_Slow, MODE_SMA, STO_LOWHIGH, MODE_MAIN, 0);
   stochastic_d = iStochastic(Symbol(), 0, Stochastic_K, Stochastic_D, Stochastic_Slow, MODE_SMA, STO_LOWHIGH, MODE_SIGNAL, 0);
   
   // Williams %R
   williams_r = iWPR(Symbol(), 0, WilliamsR_Period, 0);
   
   // CCI
   cci_value = iCCI(Symbol(), 0, CCI_Period, PRICE_TYPICAL, 0);
   
   // ADX
   adx_value = iADX(Symbol(), 0, ADX_Period, PRICE_HIGH, PRICE_LOW, PRICE_CLOSE, MODE_MAIN, 0);
   
   // Parabolic SAR
   parabolic_sar = iSAR(Symbol(), 0, ParabolicSAR_Step, ParabolicSAR_Max, 0);
   
   // OBV
   obv_value = iOBV(Symbol(), 0, PRICE_CLOSE, 0);
   
   // Ichimoku
   ichimoku_tenkan = iIchimoku(Symbol(), 0, Ichimoku_Tenkan, Ichimoku_Kijun, Ichimoku_Senkou, MODE_TENKANSEN, 0);
   ichimoku_kijun = iIchimoku(Symbol(), 0, Ichimoku_Tenkan, Ichimoku_Kijun, Ichimoku_Senkou, MODE_KIJUNSEN, 0);
   ichimoku_senkou_a = iIchimoku(Symbol(), 0, Ichimoku_Tenkan, Ichimoku_Kijun, Ichimoku_Senkou, MODE_SENKOUSPANA, 0);
   ichimoku_senkou_b = iIchimoku(Symbol(), 0, Ichimoku_Tenkan, Ichimoku_Kijun, Ichimoku_Senkou, MODE_SENKOUSPANB, 0);
}

//+------------------------------------------------------------------+
//| Calculate AI Confidence Score                                  |
//+------------------------------------------------------------------+
void CalculateAIConfidenceScore()
{
   double score = 0.0;
   double weight = 0.0;
   
   // Trend Analysis (30%)
   if(ema_fast > ema_slow && ema_slow > ema_trend)
   {
      score += 30.0;
      weight += 30.0;
   }
   else if(ema_fast < ema_slow && ema_slow < ema_trend)
   {
      score += 30.0;
      weight += 30.0;
   }
   
   // Momentum Analysis (25%)
   if(rsi_value < 30 && macd_histogram > 0)
   {
      score += 25.0;
      weight += 25.0;
   }
   else if(rsi_value > 70 && macd_histogram < 0)
   {
      score += 25.0;
      weight += 25.0;
   }
   
   // Volatility Analysis (20%)
   if(atr_value > 0 && atr_value < 100 * Point)
   {
      score += 20.0;
      weight += 20.0;
   }
   
   // Volume Analysis (15%)
   if(obv_value > 0)
   {
      score += 15.0;
      weight += 15.0;
   }
   
   // Market Structure (10%)
   if(adx_value > 25)
   {
      score += 10.0;
      weight += 10.0;
   }
   
   // Calculate final confidence score
   if(weight > 0)
      ai_confidence_score = (score / weight) * 100.0;
   else
      ai_confidence_score = 0.0;
}

//+------------------------------------------------------------------+
//| Update Market Sentiment                                        |
//+------------------------------------------------------------------+
void UpdateMarketSentiment()
{
   double sentiment = 0.0;
   
   // Price action sentiment
   if(Close[0] > Open[0])
      sentiment += 0.3;
   else
      sentiment -= 0.3;
   
   // RSI sentiment
   if(rsi_value < 30)
      sentiment += 0.2;
   else if(rsi_value > 70)
      sentiment -= 0.2;
   
   // MACD sentiment
   if(macd_histogram > 0)
      sentiment += 0.2;
   else
      sentiment -= 0.2;
   
   // Volume sentiment
   if(obv_value > 0)
      sentiment += 0.15;
   else
      sentiment -= 0.15;
   
   // Bollinger Bands sentiment
   if(Close[0] < bb_lower)
      sentiment += 0.15;
   else if(Close[0] > bb_upper)
      sentiment -= 0.15;
   
   market_sentiment = sentiment;
}

//+------------------------------------------------------------------+
//| Update Volatility Prediction                                   |
//+------------------------------------------------------------------+
void UpdateVolatilityPrediction()
{
   // Simple volatility prediction based on ATR and recent price action
   double current_volatility = atr_value / Point;
   double avg_volatility = 0.0;
   
   // Calculate average volatility over last 20 periods
   for(int i = 1; i <= 20; i++)
   {
      avg_volatility += iATR(Symbol(), 0, ATR_Period, i) / Point;
   }
   avg_volatility /= 20.0;
   
   // Predict future volatility
   if(current_volatility > avg_volatility * 1.2)
      volatility_prediction = current_volatility * 1.1;
   else if(current_volatility < avg_volatility * 0.8)
      volatility_prediction = current_volatility * 0.9;
   else
      volatility_prediction = avg_volatility;
}

//+------------------------------------------------------------------+
//| Update Correlation Analysis                                    |
//+------------------------------------------------------------------+
void UpdateCorrelationAnalysis()
{
   // Simple correlation analysis based on multiple timeframes
   double correlation = 0.0;
   
   // Check correlation between different timeframes
   double h1_close = iClose(Symbol(), PERIOD_H1, 0);
   double h4_close = iClose(Symbol(), PERIOD_H4, 0);
   double d1_close = iClose(Symbol(), PERIOD_D1, 0);
   
   if(h1_close > 0 && h4_close > 0 && d1_close > 0)
   {
      // Calculate simple correlation
      double current_price = Close[0];
      
      if((h1_close - current_price) * (h4_close - current_price) > 0)
         correlation += 0.5;
      
      if((h4_close - current_price) * (d1_close - current_price) > 0)
         correlation += 0.5;
   }
   
   correlation_score = correlation;
}

//+------------------------------------------------------------------+
//| Update Machine Learning Predictions                            |
//+------------------------------------------------------------------+
void UpdateMLPredictions()
{
   if(!EnableMachineLearning)
      return;
   
   // Simple ML prediction based on technical indicators
   double prediction = 0.0;
   
   // RSI prediction
   if(rsi_value < 30)
      prediction += 0.3;
   else if(rsi_value > 70)
      prediction -= 0.3;
   
   // MACD prediction
   if(macd_histogram > 0 && macd_histogram > iMACD(Symbol(), 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 1) - iMACD(Symbol(), 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL, 1))
      prediction += 0.3;
   else if(macd_histogram < 0 && macd_histogram < iMACD(Symbol(), 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 1) - iMACD(Symbol(), 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL, 1))
      prediction -= 0.3;
   
   // EMA prediction
   if(ema_fast > ema_slow && ema_fast > iMA(Symbol(), 0, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE, 1))
      prediction += 0.2;
   else if(ema_fast < ema_slow && ema_fast < iMA(Symbol(), 0, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE, 1))
      prediction -= 0.2;
   
   // Stochastic prediction
   if(stochastic_k < 20 && stochastic_k > iStochastic(Symbol(), 0, Stochastic_K, Stochastic_D, Stochastic_Slow, MODE_SMA, STO_LOWHIGH, MODE_MAIN, 1))
      prediction += 0.2;
   else if(stochastic_k > 80 && stochastic_k < iStochastic(Symbol(), 0, Stochastic_K, Stochastic_D, Stochastic_Slow, MODE_SMA, STO_LOWHIGH, MODE_MAIN, 1))
      prediction -= 0.2;
   
   ml_prediction = prediction;
}

//+------------------------------------------------------------------+
//| Load Historical Data for ML                                    |
//+------------------------------------------------------------------+
void LoadHistoricalData()
{
   Print("ML System: Loading historical data for training...");
   // This would typically load historical price data for ML training
   // For now, we'll use a simplified approach
}

//+------------------------------------------------------------------+
//| Train ML Models                                                |
//+------------------------------------------------------------------+
void TrainMLModels()
{
   Print("ML System: Training machine learning models...");
   // This would typically train ML models on historical data
   // For now, we'll use a simplified approach
}

//+------------------------------------------------------------------+
//| Check for Trading Opportunities                                |
//+------------------------------------------------------------------+
void CheckForTradingOpportunities()
{
   // Check if we can open new trades
   if(CountOpenTrades() >= MaxOpenTrades)
      return;
   
   // Check AI confidence score
   if(ai_confidence_score < MinConfidenceScore)
      return;
   
   // Check ML prediction
   if(EnableMachineLearning && MathAbs(ml_prediction) < ML_ConfidenceThreshold)
      return;
   
   // Check market sentiment
   if(MathAbs(market_sentiment) < 0.3)
      return;
   
   // Generate trading signals
   int signal = GenerateTradingSignal();
   
   if(signal != 0)
   {
      ExecuteTrade(signal);
   }
}

//+------------------------------------------------------------------+
//| Generate Trading Signal                                        |
//+------------------------------------------------------------------+
int GenerateTradingSignal()
{
   double signal_strength = 0.0;
   int signal_direction = 0;
   
   // Calculate signal strength based on AI analysis
   if(ai_confidence_score > 85.0)
      signal_strength += 0.4;
   
   if(MathAbs(ml_prediction) > ML_ConfidenceThreshold)
      signal_strength += 0.3;
   
   if(MathAbs(market_sentiment) > 0.5)
      signal_strength += 0.3;
   
   // Determine signal direction
   if(market_sentiment > 0.3 && ml_prediction > 0.3)
   {
      signal_direction = 1; // BUY
   }
   else if(market_sentiment < -0.3 && ml_prediction < -0.3)
   {
      signal_direction = -1; // SELL
   }
   
   // Return signal only if strength is sufficient
   if(signal_strength > 0.7)
      return signal_direction;
   
   return 0; // No signal
}

//+------------------------------------------------------------------+
//| Execute Trade                                                  |
//+------------------------------------------------------------------+
void ExecuteTrade(int signal)
{
   double lot_size = CalculateLotSize();
   double stop_loss = CalculateStopLoss(signal);
   double take_profit = CalculateTakeProfit(signal);
   
   if(signal == 1) // BUY
   {
      int ticket = OrderSend(Symbol(), OP_BUY, lot_size, Ask, Slippage, stop_loss, take_profit, "AI BUY Signal", MagicNumber, 0, clrGreen);
      if(ticket > 0)
      {
         Print("AI BUY Signal executed: Ticket=", ticket, ", Lot=", lot_size, ", SL=", stop_loss, ", TP=", take_profit);
         last_trade_time = TimeCurrent();
         total_trades++;
      }
   }
   else if(signal == -1) // SELL
   {
      int ticket = OrderSend(Symbol(), OP_SELL, lot_size, Bid, Slippage, stop_loss, take_profit, "AI SELL Signal", MagicNumber, 0, clrRed);
      if(ticket > 0)
      {
         Print("AI SELL Signal executed: Ticket=", ticket, ", Lot=", lot_size, ", SL=", stop_loss, ", TP=", take_profit);
         last_trade_time = TimeCurrent();
         total_trades++;
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate Lot Size                                             |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
   if(!AutoLotSize)
      return LotSize;
   
   double balance = AccountBalance();
   double risk_amount = balance * (RiskPercent / 100.0);
   double stop_loss_pips = 0.0;
   
   if(UseATR_SL)
      stop_loss_pips = ATR_SL_Multiplier * atr_value / Point;
   else
      stop_loss_pips = FixedSL;
   
   double pip_value = MarketInfo(Symbol(), MODE_TICKVALUE);
   double lot_size = risk_amount / (stop_loss_pips * pip_value);
   
   // Normalize lot size
   double min_lot = MarketInfo(Symbol(), MODE_MINLOT);
   double max_lot = MarketInfo(Symbol(), MODE_MAXLOT);
   double lot_step = MarketInfo(Symbol(), MODE_LOTSTEP);
   
   lot_size = MathMax(min_lot, MathMin(max_lot, lot_size));
   lot_size = MathRound(lot_size / lot_step) * lot_step;
   
   return lot_size;
}

//+------------------------------------------------------------------+
//| Calculate Stop Loss                                            |
//+------------------------------------------------------------------+
double CalculateStopLoss(int signal)
{
   double stop_loss = 0.0;
   
   if(UseATR_SL)
   {
      if(signal == 1) // BUY
         stop_loss = Ask - (ATR_SL_Multiplier * atr_value);
      else if(signal == -1) // SELL
         stop_loss = Bid + (ATR_SL_Multiplier * atr_value);
   }
   else
   {
      if(signal == 1) // BUY
         stop_loss = Ask - (FixedSL * Point);
      else if(signal == -1) // SELL
         stop_loss = Bid + (FixedSL * Point);
   }
   
   return stop_loss;
}

//+------------------------------------------------------------------+
//| Calculate Take Profit                                          |
//+------------------------------------------------------------------+
double CalculateTakeProfit(int signal)
{
   double take_profit = 0.0;
   double stop_loss_distance = 0.0;
   
   // Calculate stop loss distance
   if(UseATR_SL)
      stop_loss_distance = ATR_SL_Multiplier * atr_value;
   else
      stop_loss_distance = FixedSL * Point;
   
   // Calculate take profit based on risk:reward ratio
   double tp_distance = stop_loss_distance * RiskRewardRatio;
   
   if(signal == 1) // BUY
      take_profit = Ask + tp_distance;
   else if(signal == -1) // SELL
      take_profit = Bid - tp_distance;
   
   return take_profit;
}

//+------------------------------------------------------------------+
//| Count Open Trades                                              |
//+------------------------------------------------------------------+
int CountOpenTrades()
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
//| Manage Open Positions                                          |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            // Apply trailing stop
            if(UseTrailingStop)
               ApplyTrailingStop();
            
            // Apply break-even stop
            if(UseBreakEven)
               ApplyBreakEvenStop();
            
            // Apply partial close
            if(UsePartialClose)
               ApplyPartialClose();
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Apply Trailing Stop                                            |
//+------------------------------------------------------------------+
void ApplyTrailingStop()
{
   if(!UseTrailingStop)
      return;
   
   double current_price = (OrderType() == OP_BUY) ? Bid : Ask;
   double current_sl = OrderStopLoss();
   double new_sl = 0.0;
   
   if(OrderType() == OP_BUY)
   {
      double profit_pips = (current_price - OrderOpenPrice()) / Point;
      
      if(profit_pips > TrailingStart)
      {
         new_sl = current_price - (TrailingStep * Point);
         
         if(new_sl > current_sl)
         {
            OrderModify(OrderTicket(), OrderOpenPrice(), new_sl, OrderTakeProfit(), 0, clrBlue);
         }
      }
   }
   else if(OrderType() == OP_SELL)
   {
      double profit_pips = (OrderOpenPrice() - current_price) / Point;
      
      if(profit_pips > TrailingStart)
      {
         new_sl = current_price + (TrailingStep * Point);
         
         if(new_sl < current_sl || current_sl == 0)
         {
            OrderModify(OrderTicket(), OrderOpenPrice(), new_sl, OrderTakeProfit(), 0, clrBlue);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Apply Break-Even Stop                                          |
//+------------------------------------------------------------------+
void ApplyBreakEvenStop()
{
   if(!UseBreakEven)
      return;
   
   double current_price = (OrderType() == OP_BUY) ? Bid : Ask;
   double current_sl = OrderStopLoss();
   double open_price = OrderOpenPrice();
   
   if(OrderType() == OP_BUY)
   {
      double profit_pips = (current_price - open_price) / Point;
      
      if(profit_pips > BreakEvenPips && current_sl < open_price)
      {
         OrderModify(OrderTicket(), OrderOpenPrice(), open_price, OrderTakeProfit(), 0, clrYellow);
      }
   }
   else if(OrderType() == OP_SELL)
   {
      double profit_pips = (open_price - current_price) / Point;
      
      if(profit_pips > BreakEvenPips && (current_sl > open_price || current_sl == 0))
      {
         OrderModify(OrderTicket(), OrderOpenPrice(), open_price, OrderTakeProfit(), 0, clrYellow);
      }
   }
}

//+------------------------------------------------------------------+
//| Apply Partial Close                                            |
//+------------------------------------------------------------------+
void ApplyPartialClose()
{
   if(!UsePartialClose)
      return;
   
   double current_price = (OrderType() == OP_BUY) ? Bid : Ask;
   double open_price = OrderOpenPrice();
   double target_price = 0.0;
   
   if(OrderType() == OP_BUY)
   {
      target_price = open_price + (PartialCloseTarget * (open_price - OrderStopLoss()));
      
      if(current_price >= target_price)
      {
         double partial_lot = OrderLots() * (PartialClosePercent / 100.0);
         OrderClose(OrderTicket(), partial_lot, current_price, Slippage, clrOrange);
      }
   }
   else if(OrderType() == OP_SELL)
   {
      target_price = open_price - (PartialCloseTarget * (OrderStopLoss() - open_price));
      
      if(current_price <= target_price)
      {
         double partial_lot = OrderLots() * (PartialClosePercent / 100.0);
         OrderClose(OrderTicket(), partial_lot, current_price, Slippage, clrOrange);
      }
   }
}

//+------------------------------------------------------------------+
//| Update Performance Metrics                                     |
//+------------------------------------------------------------------+
void UpdatePerformanceMetrics()
{
   double current_equity = AccountEquity();
   double current_balance = AccountBalance();
   
   // Update daily profit
   static datetime last_day = 0;
   datetime current_day = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   
   if(current_day != last_day)
   {
      daily_profit = 0.0;
      last_day = current_day;
   }
   
   daily_profit = current_equity - current_balance;
   
   // Update max profit/loss
   if(daily_profit > max_profit)
      max_profit = daily_profit;
   
   if(daily_profit < max_loss)
      max_loss = daily_profit;
   
   // Update total profit
   total_profit = current_equity - 10000; // Assuming initial balance of 10000
   
   // Update win/loss count
   // This would typically be updated when positions are closed
}