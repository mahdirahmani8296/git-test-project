import argparse
import math
import warnings
from typing import Tuple

import numpy as np
import pandas as pd
import yfinance as yf
from backtesting import Backtest, Strategy

warnings.filterwarnings("ignore")


class AdvancedForexStrategy(Strategy):
	# پارامترهای قابل‌تنظیم (مطابق الگوی backtesting.py)
	ema_fast = 20
	ema_slow = 50
	ema_trend = 200
	rsi_period = 14
	atr_period = 14
	atr_sl_mult = 2.0
	atr_tp_mult = 3.0
	risk_per_trade = 0.005
	min_atr_pct = 0.0005
	max_atr_pct = 0.01
	use_trailing = True
	trail_atr_mult = 1.5

	def init(self):
		# DataFrame منبع
		df = self.data.df

		# محاسبه اندیکاتورها بر اساس پارامترهای جاری (هر بار بازنویسی می‌شود)
		df['ema_fast'] = df['Close'].ewm(span=self.ema_fast, adjust=False).mean()
		df['ema_slow'] = df['Close'].ewm(span=self.ema_slow, adjust=False).mean()
		df['ema_trend'] = df['Close'].ewm(span=self.ema_trend, adjust=False).mean()

		change = df['Close'].diff()
		gain = change.clip(lower=0.0)
		loss = -change.clip(upper=0.0)
		avg_gain = gain.rolling(self.rsi_period).mean()
		avg_loss = loss.rolling(self.rsi_period).mean()
		rs = avg_gain / (avg_loss.replace(0, np.nan))
		df['rsi'] = (100 - (100 / (1 + rs))).fillna(50.0)

		high_low = (df['High'] - df['Low']).abs()
		high_close = (df['High'] - df['Close'].shift()).abs()
		low_close = (df['Low'] - df['Close'].shift()).abs()
		df['tr'] = pd.concat([high_low, high_close, low_close], axis=1).max(axis=1)
		df['atr'] = df['tr'].rolling(self.atr_period).mean()
		df['atr_pct'] = (df['atr'] / df['Close']).fillna(0.0)

		self.df = df

	def _position_size(self, stop_price: float) -> float:
		price = float(self.data.Close[-1])
		if math.isnan(price) or price <= 0:
			return 0
		stop_distance = abs(price - stop_price)
		if stop_distance <= 0 or math.isnan(stop_distance):
			return 0
		equity = float(self.equity)
		risk_dollars = equity * self.risk_per_trade
		size = risk_dollars / stop_distance
		return max(0.0, size)

	def next(self):
		idx = len(self.df) - 1
		row = self.df.iloc[idx]

		price = float(row['Close'])
		atr = float(row['atr']) if not math.isnan(row['atr']) else None
		atr_pct = float(row['atr_pct']) if not math.isnan(row['atr_pct']) else 0.0
		ema_fast = float(row['ema_fast'])
		ema_slow = float(row['ema_slow'])
		ema_trend = float(row['ema_trend'])
		rsi = float(row['rsi'])

		# فیلتر نوسان
		if not (self.min_atr_pct <= atr_pct <= self.max_atr_pct):
			return

		# فیلتر رژیم روند
		regime_long = price > ema_trend
		regime_short = price < ema_trend

		# کراس‌اور مومنتوم (به‌صورت ساده)
		prev_ema_fast = self.df['ema_fast'].iloc[idx-1] if idx > 0 else ema_fast
		prev_ema_slow = self.df['ema_slow'].iloc[idx-1] if idx > 0 else ema_slow
		bull_cross = ema_fast > ema_slow and prev_ema_fast <= prev_ema_slow
		bear_cross = ema_fast < ema_slow and prev_ema_fast >= prev_ema_slow

		# مدیریت تریلینگ استاپ
		if self.position.is_long and self.use_trailing and atr is not None and atr > 0:
			new_sl = max(self.position.sl or -np.inf, price - self.trail_atr_mult * atr)
			self.position.set_sl(new_sl)
		elif self.position.is_short and self.use_trailing and atr is not None and atr > 0:
			new_sl = min(self.position.sl or np.inf, price + self.trail_atr_mult * atr)
			self.position.set_sl(new_sl)

		# ورود خرید
		if not self.position and regime_long and bull_cross and rsi >= 50 and atr is not None and atr > 0:
			sl = price - self.atr_sl_mult * atr
			tp = price + self.atr_tp_mult * atr
			size = self._position_size(sl)
			if size > 0:
				self.buy(size=size, sl=sl, tp=tp)

		# ورود فروش
		elif not self.position and regime_short and bear_cross and rsi <= 50 and atr is not None and atr > 0:
			sl = price + self.atr_sl_mult * atr
			tp = price - self.atr_tp_mult * atr
			size = self._position_size(sl)
			if size > 0:
				self.sell(size=size, sl=sl, tp=tp)



def download_data(symbol: str, interval: str, period: str) -> pd.DataFrame:
	data = yf.download(symbol, interval=interval, period=period, auto_adjust=True, progress=False)
	if not isinstance(data, pd.DataFrame) or data.empty:
		raise RuntimeError("No data returned from yfinance. Try a different symbol/interval/period.")
	data = data.rename(columns={
		'Open': 'Open', 'High': 'High', 'Low': 'Low', 'Close': 'Close', 'Volume': 'Volume'
	})
	data.dropna(inplace=True)
	return data


def optimize_params(df: pd.DataFrame, commission: float, slippage: float) -> Tuple[dict, dict]:
	# جستجوی شبکه‌ای کوچک برای مثال
	ema_fast_opts = [10, 20, 30]
	ema_slow_opts = [40, 50, 80]
	atr_sl_opts = [1.5, 2.0, 2.5]
	atr_tp_opts = [2.0, 3.0, 4.0]

	best_sharpe = -np.inf
	best_params: dict = {}
	best_stats: dict = {}

	bt = Backtest(
		df,
		AdvancedForexStrategy,
		cash=100_000,
		commission=commission,
		slippage=slippage,
		exclusive_orders=True,
	)

	for ef in ema_fast_opts:
		for es in ema_slow_opts:
			if ef >= es:
				continue
			for slm in atr_sl_opts:
				for tpm in atr_tp_opts:
					params = dict(
						ema_fast=ef,
						ema_slow=es,
						atr_sl_mult=slm,
						atr_tp_mult=tpm,
					)
					stats = bt.run(**params)
					sharpe = stats.get('Sharpe Ratio', -np.inf)
					if np.isfinite(sharpe) and sharpe > best_sharpe:
						best_sharpe = sharpe
						best_params = params
						best_stats = stats

	if not best_params:
		best_params = {}
		best_stats = bt.run()

	return best_params, best_stats


def main():
	parser = argparse.ArgumentParser()
	parser.add_argument('--symbol', type=str, default='EURUSD=X')
	parser.add_argument('--interval', type=str, default='1h')
	parser.add_argument('--period', type=str, default='730d')
	parser.add_argument('--optimize', action='store_true', help='اجرای بهینه‌سازی پارامترها')
	parser.add_argument('--plot', action='store_true', help='نمایش نمودار نتایج')
	args = parser.parse_args()

	commission_pct = 0.0001
	slippage_pct = 0.00005

	print(f"Downloading {args.symbol} {args.interval} {args.period} ...")
	df = download_data(args.symbol, args.interval, args.period)

	if args.optimize:
		print("Optimizing parameters (small grid)...")
		best_params, best_stats = optimize_params(df, commission_pct, slippage_pct)
		print("Best params:", best_params)
		print(best_stats)
		if args.plot:
			bt = Backtest(
				df,
				AdvancedForexStrategy,
				cash=100_000,
				commission=commission_pct,
				slippage=slippage_pct,
				exclusive_orders=True,
			)
			bt.run(**best_params)
			bt.plot()
	else:
		bt = Backtest(
			df,
			AdvancedForexStrategy,
			cash=100_000,
			commission=commission_pct,
			slippage=slippage_pct,
			exclusive_orders=True,
		)
		stats = bt.run()
		print(stats)
		if args.plot:
			bt.plot()


if __name__ == '__main__':
	main()