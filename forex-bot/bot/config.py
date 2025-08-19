from __future__ import annotations

import os
from dataclasses import dataclass
from typing import Literal

from dotenv import load_dotenv


@dataclass
class BotConfig:
    api_token: str
    account_id: str
    env: Literal["practice", "live"]
    instrument: str
    granularity: str
    risk_per_trade: float
    loop_interval_seconds: int


def load_config() -> BotConfig:
    load_dotenv()

    api_token = os.getenv("OANDA_API_TOKEN", "").strip()
    account_id = os.getenv("OANDA_ACCOUNT_ID", "").strip()
    env = os.getenv("OANDA_ENV", "practice").strip()
    instrument = os.getenv("INSTRUMENT", "EUR_USD").strip()
    granularity = os.getenv("GRANULARITY", "M5").strip()
    risk_per_trade = float(os.getenv("RISK_PER_TRADE", "0.01").strip())
    loop_interval_seconds = int(os.getenv("LOOP_INTERVAL_SECONDS", "60").strip())

    if not api_token or not account_id:
        raise RuntimeError("Missing OANDA_API_TOKEN or OANDA_ACCOUNT_ID in environment")

    if env not in {"practice", "live"}:
        raise RuntimeError("OANDA_ENV must be 'practice' or 'live'")

    return BotConfig(
        api_token=api_token,
        account_id=account_id,
        env=env, 
        instrument=instrument,
        granularity=granularity,
        risk_per_trade=risk_per_trade,
        loop_interval_seconds=loop_interval_seconds,
    )

