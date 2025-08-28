from __future__ import annotations

from dataclasses import dataclass
from typing import Optional, List

from .config import BotConfig
from .oanda_client import OandaClient, Candle
from .strategy import compute_sma_cross_with_atr, StrategyResult


@dataclass
class PositionSizing:
    units: int
    stop_loss_price: Optional[float]


class Trader:
    def __init__(self, cfg: BotConfig) -> None:
        self.cfg = cfg
        self.client = OandaClient(cfg)

    def _compute_position_size(self, candles: List[Candle], signal: str, stop_loss: Optional[float]) -> PositionSizing:
        # Simplified: assume account in USD and quote currency is USD
        # Risk per trade = cfg.risk_per_trade * 1000 USD (we do not fetch balance here for simplicity)
        # For demo purposes, risk capitalized to 1000 USD notionally. Adjust per actual balance via Accounts API for production use.
        notional_balance_usd = 1000.0
        risk_amount_usd = self.cfg.risk_per_trade * notional_balance_usd

        last_price = float(candles[-1].close) if candles else 0.0
        if stop_loss is None or last_price <= 0.0:
            return PositionSizing(units=0, stop_loss_price=None)

        # Pip value approximation for pairs with USD as quote: 0.0001 per unit
        distance = abs(last_price - stop_loss)
        if distance <= 0:
            return PositionSizing(units=0, stop_loss_price=None)

        # Value per unit move approx equals distance (in price) per 1 unit
        position_units = int(risk_amount_usd / distance)
        # Cap to a reasonable max for demo
        position_units = max(0, min(position_units, 10000))

        if signal == "sell":
            position_units = -position_units

        return PositionSizing(units=position_units, stop_loss_price=stop_loss)

    def run_once(self, dry_run: bool = True) -> None:
        candles = self.client.fetch_candles(self.cfg.instrument, self.cfg.granularity, count=300)
        if not candles:
            print("No candle data fetched.")
            return

        strat: StrategyResult = compute_sma_cross_with_atr(candles)
        print(f"Signal: {strat.signal}, SL: {strat.stop_loss}")

        if strat.signal == "hold":
            return

        sizing = self._compute_position_size(candles, strat.signal, strat.stop_loss)
        if sizing.units == 0:
            print("Position size is 0; skipping order.")
            return

        resp = self.client.place_market_order(
            instrument=self.cfg.instrument,
            units=sizing.units,
            stop_loss_price=sizing.stop_loss_price,
            take_profit_price=None,
            dry_run=dry_run,
        )
        print(resp)

