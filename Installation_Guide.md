# Advanced Trading Bot - Installation & Setup Guide

## 📋 Prerequisites

### System Requirements
- MetaTrader 4 platform
- Windows 7/8/10/11 or Windows Server
- Minimum 4GB RAM
- Stable internet connection
- VPS recommended for 24/7 trading

### Account Requirements
- MetaTrader 4 broker account
- Minimum balance: $500 (recommended $1000+)
- Spreads: Maximum 3-5 pips for major pairs
- Execution: Market execution preferred
- Allow Expert Advisors and Automated Trading enabled

## 🚀 Installation Steps

### Step 1: Download Files
Ensure you have the following files:
```
✅ AdvancedTradingBot.mq4      (Main Expert Advisor)
✅ AdvancedTradingBot_Config.set  (Configuration Template)
✅ README_Persian.md           (Persian Documentation)
✅ Installation_Guide.md       (This File)
```

### Step 2: Copy Files to MetaTrader

#### Method 1: Using File Explorer
1. Open MetaTrader 4
2. Go to `File → Open Data Folder`
3. Navigate to `MQL4\Experts\`
4. Copy `AdvancedTradingBot.mq4` here
5. Navigate to `MQL4\Presets\`
6. Copy `AdvancedTradingBot_Config.set` here
7. Restart MetaTrader 4

#### Method 2: Using MetaEditor
1. Open MetaEditor (F4 in MT4)
2. Go to `File → Open`
3. Select `AdvancedTradingBot.mq4`
4. Press `F7` or click Compile
5. Check for compilation errors
6. Close MetaEditor

### Step 3: Verify Installation
1. In MetaTrader Navigator panel
2. Expand "Expert Advisors"
3. Look for "AdvancedTradingBot"
4. If not visible, refresh Navigator (F5)

## ⚙️ Configuration

### Step 1: Chart Setup
1. Open desired chart (XAUUSD, EURUSD, etc.)
2. Set timeframe (M15, H1, H4 recommended)
3. Drag AdvancedTradingBot from Navigator to chart
4. Configuration dialog will appear

### Step 2: Essential Settings

#### General Settings
```
✓ UseAutoLot = true
✓ RiskPercent = 2.0 (start conservative)
✓ MagicNumber = 123456 (unique for each chart)
✓ Slippage = 3
```

#### Risk Management
```
✓ UseStopLoss = true
✓ UseTakeProfit = true
✓ StopLossMultiplier = 2.0
✓ TakeProfitMultiplier = 3.0
✓ UseTrailingStop = true
```

#### Symbol Optimization
```
✓ TradeGold = true (for XAUUSD)
✓ TradeMajorPairs = true (for forex)
✓ GoldSpreadFilter = 30 (max spread for gold)
```

### Step 3: Enable Trading
1. Check "Allow live trading" ✅
2. Check "Allow DLL imports" (if required) ✅
3. Click "OK"
4. Verify smiley face appears in top-right corner

## 🧪 Testing Protocol

### Phase 1: Demo Testing (1-2 weeks)
1. **Demo Account Setup**
   - Same broker as live account
   - Similar balance to intended live trading
   - Same server conditions

2. **Initial Parameters**
   ```
   RiskPercent = 1.0 (conservative start)
   FastMA = 21
   SlowMA = 50
   StopLossMultiplier = 2.0
   ```

3. **Monitoring Checklist**
   - [ ] EA starts correctly
   - [ ] Signals are generated
   - [ ] Orders open and close properly
   - [ ] Risk management works
   - [ ] Logs show no errors

### Phase 2: Optimization (1 week)
1. **Strategy Tester Setup**
   ```
   Period: 3-6 months
   Model: Every tick
   Optimization: Genetic Algorithm
   ```

2. **Parameters to Optimize**
   - RiskPercent: 1.0 to 3.0 (step 0.5)
   - FastMA: 10 to 30 (step 2)
   - SlowMA: 40 to 80 (step 5)
   - StopLossMultiplier: 1.5 to 3.0 (step 0.5)

3. **Target Metrics**
   - Profit Factor > 1.5
   - Win Rate > 55%
   - Max Drawdown < 15%
   - Total Trades > 50

### Phase 3: Live Testing (small size)
1. **Start Small**
   - RiskPercent = 0.5-1.0%
   - Monitor for 1-2 weeks
   - Verify demo results translate

2. **Scale Up Gradually**
   - Increase risk by 0.5% weekly
   - Maximum 3% per trade
   - Monitor performance closely

## 📊 Performance Monitoring

### Daily Checks
- [ ] EA is running (smiley face visible)
- [ ] No error messages in logs
- [ ] Trades are within risk parameters
- [ ] Account balance trending positively

### Weekly Reviews
- [ ] Win rate analysis
- [ ] Profit factor calculation
- [ ] Drawdown assessment
- [ ] Compare to demo results

### Monthly Optimization
- [ ] Parameter adjustment if needed
- [ ] Market condition adaptation
- [ ] Strategy performance review
- [ ] Risk parameter update

## 🔧 Troubleshooting

### Common Issues and Solutions

#### 1. EA Not Trading
**Symptoms**: No trades opening despite signals
**Solutions**:
- Check AutoTrading is enabled (Ctrl+E)
- Verify account has sufficient margin
- Check spread filter settings
- Ensure time filter allows trading
- Verify symbol is in allowed list

#### 2. Compilation Errors
**Symptoms**: Red errors in MetaEditor
**Solutions**:
- Update MetaTrader to latest version
- Check MQL4 syntax compatibility
- Verify all required functions exist
- Check for missing semicolons/brackets

#### 3. Poor Performance
**Symptoms**: Low win rate or profit factor
**Solutions**:
- Return to demo testing
- Reduce risk percentage
- Optimize parameters for current market
- Check spread costs impact
- Consider different timeframe

#### 4. Unexpected Behavior
**Symptoms**: Large losses or strange orders
**Solutions**:
- Immediately disable EA
- Close all positions manually
- Review logs for errors
- Reset to default parameters
- Test on demo again

## 📈 Performance Expectations

### Realistic Targets
```
Win Rate: 55-70%
Profit Factor: 1.3-2.5
Monthly Return: 3-12%
Maximum Drawdown: 5-15%
Average Trade Duration: 4-24 hours
```

### Market-Specific Performance

#### Gold (XAUUSD)
- Higher volatility = Higher profit potential
- Wider spreads = Higher costs
- News sensitivity = More false signals
- Recommended: H1-H4 timeframes

#### Major Forex Pairs
- Lower volatility = More consistent results
- Tighter spreads = Lower costs
- More predictable patterns
- Recommended: M15-H1 timeframes

## 🛡️ Risk Management Rules

### Position Sizing
- Never risk more than 2-3% per trade
- Maximum 5% total account exposure
- Scale position size with account growth
- Reduce size after significant losses

### Diversification
- Trade multiple symbols simultaneously
- Use different parameter sets for different markets
- Don't put all trades in correlated pairs
- Consider time diversification

### Stop Loss Management
- Always use stop losses
- Never move SL against position
- Allow trailing stops to work
- Don't interfere with EA decisions

## 📞 Support Information

### Before Contacting Support
1. Check this guide thoroughly
2. Review error logs in MetaTrader
3. Test on demo account
4. Document specific issues with screenshots

### Technical Support Checklist
- MetaTrader version
- Broker name and account type
- EA version and parameters used
- Error messages or unexpected behavior
- Chart timeframe and symbol
- Operating system details

---

## ⚠️ Important Disclaimers

1. **Past performance does not guarantee future results**
2. **Trading carries significant risk of loss**
3. **Only trade with money you can afford to lose**
4. **Always test thoroughly on demo before live trading**
5. **Market conditions can change rapidly**
6. **This EA is a tool, not a guarantee of profit**

## 🎯 Success Tips

1. **Be Patient**: Allow time for results to develop
2. **Stay Disciplined**: Don't override EA decisions
3. **Monitor Regularly**: Check performance weekly
4. **Keep Learning**: Understand market conditions
5. **Risk Management**: Never risk more than planned
6. **Backup Everything**: Save configurations and logs

---

**Version**: 2.50  
**Last Updated**: 2024  
**Compatibility**: MetaTrader 4 Build 1090+

*Good luck with your automated trading journey!* 🚀