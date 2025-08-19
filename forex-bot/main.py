import time
from typing import Optional

import click

from bot.config import load_config
from bot.trader import Trader


@click.group()
def cli() -> None:
    """Forex trading bot CLI (OANDA)."""


@cli.command()
@click.option("--instrument", default=None, help="Instrument, e.g., EUR_USD")
@click.option("--granularity", default=None, help="Candle granularity, e.g., M5, M15, H1")
@click.option("--interval", default=None, type=int, help="Loop interval seconds")
@click.option("--dry-run/--live", default=True, help="Dry-run does not send real orders")
@click.option("--once/--loop", "mode_once", flag_value=True, default=False, help="Run once and exit")
def live(instrument: Optional[str], granularity: Optional[str], interval: Optional[int], dry_run: bool, mode_once: bool) -> None:
    cfg = load_config()
    if instrument:
        cfg.instrument = instrument
    if granularity:
        cfg.granularity = granularity
    if interval is not None:
        cfg.loop_interval_seconds = interval

    trader = Trader(cfg)

    if mode_once:
        trader.run_once(dry_run=dry_run)
        return

    while True:
        trader.run_once(dry_run=dry_run)
        time.sleep(cfg.loop_interval_seconds)


if __name__ == "__main__":
    cli()

