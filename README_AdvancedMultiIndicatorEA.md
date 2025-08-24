## AdvancedMultiIndicatorEA (MT5)

This Expert Advisor implements a multi‑indicator, confluence‑based strategy with dynamic risk and ATR‑based trade management. It supports gold (XAUUSD) and major FX pairs.

Important: No strategy guarantees profit. Thoroughly backtest and forward test on demo before going live. Use responsibly at your own risk.

### Features
- Multi‑indicator confluence (EMA trend filter, RSI, MACD, ADX)
- Adaptive RR based on rolling win‑rate
- ATR‑based SL/TP, breakeven, and trailing stop
- Risk‑based position sizing (% of balance)
- Session, spread, and symbol filters
- Per‑symbol position cap and MagicNumber segregation

### Files
- `AdvancedMultiIndicatorEA.mq5`: Main EA source
- Persistent stats file: `Common Files/AdvancedEA_<SYMBOL>_<MAGIC>.csv` (rolling win/loss outcomes)

### Installation
1. Open MetaTrader 5 → File → Open Data Folder
2. Place `AdvancedMultiIndicatorEA.mq5` into `MQL5/Experts`
3. Compile in MetaEditor
4. Attach to chart(s) for allowed symbols (e.g., XAUUSD, EURUSD) and desired timeframe

### Inputs (key)
- Strategy
  - `Timeframe`: signal timeframe (default H1)
  - `OnlyNewBar`: signal on new bar only
  - `ConfluenceRequired`: number of filters that must align to enter
  - `UseTrendFilter/RSI/MACD/ADX` + periods/thresholds
- Risk
  - `RiskPerTradePercent`: percent of balance risked per trade
  - `MaxSpreadPoints`: skip trading when spread is wider than this
  - `ATRPeriod`, `ATRMulSL`: SL distance as multiple of ATR
  - `BaseRR`, `MinRR`, `MaxRR`, `RollingTrades`: TP distance adapts to rolling win‑rate
- Management
  - `UseBreakeven`, `BreakevenBufferPoints`
  - `UseTrailingStop`, `TrailingATRMul`
  - `MaxPositionsPerSymbol`
- Filters
  - `RestrictToMajorsAndGold`, `AllowedSymbolsCSV`
  - `StartHourUTC`, `EndHourUTC` (24 disables end)
- Execution
  - `MagicNumber`, `SlippagePoints`, `AllowShort`, `AllowLong`

### How it trades
- Builds a signal snapshot on the previous closed bar
- Requires `ConfluenceRequired` bullish/bearish confirmations
- Sets SL = ATR × `ATRMulSL`. TP = SL × adaptive RR
- Position size is computed from account balance and SL distance
- Manages trade with breakeven at 1R and ATR trailing if enabled
- Tracks rolling results in a small CSV to adapt RR range over time

### Recommended symbols/timeframes
- XAUUSD, EURUSD, GBPUSD, USDJPY, USDCHF, USDCAD, AUDUSD, NZDUSD
- Start with H1; consider M30/H4 depending on broker/latency

### Backtesting & Optimization Tips
- Use “Every tick based on real ticks” if possible
- Optimize:
  - `ConfluenceRequired` (2–4)
  - `ATRMulSL` (1.5–3.0), `TrailingATRMul` (1.0–2.5)
  - `BaseRR`/`MinRR`/`MaxRR` ranges and `RollingTrades` (20–60)
  - EMA periods (e.g., 34/200) and RSI thresholds (30/70)
  - Session hours and spread cap per broker
- Validate on out‑of‑sample data and forward demo before live

### Notes & Limitations
- No martingale/grid. One position per symbol by default
- File‑based win‑rate uses common files; clear it to reset adaptation
- Broker specifics (tick value/size, contract size) affect sizing; verify in Journal
- Slippage, gaps, and requotes may cause SL/TP placement deviations

### Disclaimer
This EA is provided for educational purposes. Trading is risky and can result in loss of capital. You are solely responsible for its use in live markets.