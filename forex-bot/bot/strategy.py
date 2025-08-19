from __future__ import annotations

from dataclasses import dataclass
from typing import Literal, Optional, List


Signal = Literal["buy", "sell", "hold"]


@dataclass
class StrategyResult:
    signal: Signal
    stop_loss: Optional[float]
    take_profit: Optional[float]

from .oanda_client import Candle


def _sma(values: List[float], window: int) -> List[Optional[float]]:
    sma: List[Optional[float]] = [None] * len(values)
    if window <= 0 or len(values) < window:
        return sma
    running_sum = sum(values[:window])
    sma[window - 1] = running_sum / window
    for i in range(window, len(values)):
        running_sum += values[i] - values[i - 1 - (window - 1)]
        sma[i] = running_sum / window
    return sma


def compute_sma_cross_with_atr(candles: List[Candle], fast: int = 10, slow: int = 20, atr_period: int = 14, atr_multiplier: float = 2.0) -> StrategyResult:
    n = len(candles)
    if n < max(slow, atr_period) + 2:
        return StrategyResult(signal="hold", stop_loss=None, take_profit=None)

    closes = [c.close for c in candles]
    highs = [c.high for c in candles]
    lows = [c.low for c in candles]

    sma_fast = _sma(closes, fast)
    sma_slow = _sma(closes, slow)

    true_ranges: List[float] = []
    for i in range(n):
        if i == 0:
            tr = highs[i] - lows[i]
        else:
            tr = max(
                highs[i] - lows[i],
                abs(highs[i] - closes[i - 1]),
                abs(lows[i] - closes[i - 1]),
            )
        true_ranges.append(tr)

    atr_series = _sma(true_ranges, atr_period)

    prev_fast = sma_fast[-2]
    prev_slow = sma_slow[-2]
    last_fast = sma_fast[-1]
    last_slow = sma_slow[-1]
    last_close = closes[-1]
    last_atr = atr_series[-1]

    signal: Signal = "hold"
    stop_loss: Optional[float] = None
    take_profit: Optional[float] = None

    if prev_fast is not None and prev_slow is not None and last_fast is not None and last_slow is not None and last_atr is not None:
        if prev_fast <= prev_slow and last_fast > last_slow:
            signal = "buy"
            stop_loss = float(last_close - atr_multiplier * last_atr)
        elif prev_fast >= prev_slow and last_fast < last_slow:
            signal = "sell"
            stop_loss = float(last_close + atr_multiplier * last_atr)

    return StrategyResult(signal=signal, stop_loss=stop_loss, take_profit=take_profit)

