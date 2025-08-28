from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, List
from oandapyV20 import API
import oandapyV20.endpoints.instruments as instruments
import oandapyV20.endpoints.orders as orders

from .config import BotConfig


@dataclass
class Candle:
    time: str
    open: float
    high: float
    low: float
    close: float
    volume: int


class OandaClient:
    def __init__(self, cfg: BotConfig) -> None:
        practice = cfg.env == "practice"
        self.api = API(access_token=cfg.api_token, environment="practice" if practice else "live")
        self.account_id = cfg.account_id

    def fetch_candles(self, instrument: str, granularity: str, count: int = 300) -> List[Candle]:
        params: Dict[str, str] = {
            "granularity": granularity,
            "count": str(count),
            "price": "M",
        }
        r = instruments.InstrumentsCandles(instrument=instrument, params=params)
        data = self.api.request(r)
        candles: List[Candle] = []
        for c in data.get("candles", []):
            if not c.get("complete", False):
                continue
            mid = c["mid"]
            candles.append(
                Candle(
                    time=c["time"],
                    open=float(mid["o"]),
                    high=float(mid["h"]),
                    low=float(mid["l"]),
                    close=float(mid["c"]),
                    volume=int(c.get("volume", 0)),
                )
            )
        return candles

    def place_market_order(self, instrument: str, units: int, stop_loss_price: float | None = None, take_profit_price: float | None = None, dry_run: bool = True) -> Dict:
        order: Dict = {
            "order": {
                "units": str(units),
                "instrument": instrument,
                "timeInForce": "FOK",
                "type": "MARKET",
                "positionFill": "DEFAULT",
            }
        }
        # Add stops
        if stop_loss_price is not None:
            order["order"]["stopLossOnFill"] = {"price": f"{stop_loss_price:.5f}"}
        if take_profit_price is not None:
            order["order"]["takeProfitOnFill"] = {"price": f"{take_profit_price:.5f}"}

        if dry_run:
            return {"dry_run": True, "order": order}

        req = orders.OrderCreate(self.account_id, data=order)
        resp = self.api.request(req)
        return resp

