#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
داشبورد معاملات فارکس
Forex Trading Dashboard

داشبورد تعاملی برای نظارت بر معاملات فارکس در زمان واقعی
Interactive dashboard for real-time forex trading monitoring
"""

import dash
from dash import dcc, html, Input, Output, callback
import dash_bootstrap_components as dbc
import plotly.graph_objs as go
import plotly.express as px
from plotly.subplots import make_subplots
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import yfinance as yf
import talib
import threading
import time
import warnings
warnings.filterwarnings('ignore')

# ایجاد اپلیکیشن Dash
app = dash.Dash(__name__, external_stylesheets=[dbc.themes.BOOTSTRAP])
app.title = "داشبورد معاملات فارکس"

class RealTimeTrader:
    def __init__(self, symbol="EURUSD=X"):
        self.symbol = symbol
        self.data = None
        self.signals = None
        self.current_position = None
        self.trade_history = []
        self.balance = 10000
        self.initial_balance = 10000
        
    def fetch_latest_data(self, period="1d", interval="5m"):
        """دریافت آخرین داده‌ها"""
        try:
            ticker = yf.Ticker(self.symbol)
            data = ticker.history(period=period, interval=interval)
            return data
        except Exception as e:
            print(f"خطا در دریافت داده‌ها: {e}")
            return None
    
    def calculate_indicators(self, data):
        """محاسبه اندیکاتورها"""
        df = data.copy()
        
        # RSI
        df['RSI'] = talib.RSI(df['Close'], timeperiod=14)
        
        # MACD
        df['MACD'], df['MACD_Signal'], df['MACD_Hist'] = talib.MACD(
            df['Close'], fastperiod=12, slowperiod=26, signalperiod=9
        )
        
        # EMA
        df['EMA_9'] = talib.EMA(df['Close'], timeperiod=9)
        df['EMA_21'] = talib.EMA(df['Close'], timeperiod=21)
        df['EMA_50'] = talib.EMA(df['Close'], timeperiod=50)
        
        # Bollinger Bands
        df['BB_Upper'], df['BB_Middle'], df['BB_Lower'] = talib.BBANDS(
            df['Close'], timeperiod=20, nbdevup=2, nbdevdn=2
        )
        
        # ATR
        df['ATR'] = talib.ATR(df['High'], df['Low'], df['Close'], timeperiod=14)
        
        # Stochastic
        df['Stoch_K'], df['Stoch_D'] = talib.STOCH(
            df['High'], df['Low'], df['Close'], fastk_period=14, slowk_period=3, slowd_period=3
        )
        
        return df
    
    def generate_signals(self, df):
        """تولید سیگنال‌ها"""
        signals = pd.DataFrame(index=df.index)
        signals['Signal'] = 0
        
        # شرایط خرید
        buy_conditions = (
            (df['EMA_9'] > df['EMA_21']) &
            (df['EMA_21'] > df['EMA_50']) &
            (df['RSI'] < 30) &
            (df['MACD'] > df['MACD_Signal']) &
            (df['Close'] <= df['BB_Lower'] * 1.01)
        )
        
        # شرایط فروش
        sell_conditions = (
            (df['EMA_9'] < df['EMA_21']) &
            (df['EMA_21'] < df['EMA_50']) &
            (df['RSI'] > 70) &
            (df['MACD'] < df['MACD_Signal']) &
            (df['Close'] >= df['BB_Upper'] * 0.99)
        )
        
        signals.loc[buy_conditions, 'Signal'] = 1
        signals.loc[sell_conditions, 'Signal'] = -1
        
        return signals
    
    def update_data(self):
        """به‌روزرسانی داده‌ها"""
        data = self.fetch_latest_data()
        if data is not None:
            self.data = self.calculate_indicators(data)
            self.signals = self.generate_signals(self.data)
            return True
        return False

# ایجاد نمونه از تریدر
trader = RealTimeTrader()

# طراحی داشبورد
app.layout = dbc.Container([
    dbc.Row([
        dbc.Col([
            html.H1("📊 داشبورد معاملات فارکس", className="text-center mb-4"),
            html.Hr()
        ])
    ]),
    
    # اطلاعات کلی
    dbc.Row([
        dbc.Col([
            dbc.Card([
                dbc.CardBody([
                    html.H4("💰 موجودی", className="card-title"),
                    html.H2(id="balance-display", children="$10,000.00", className="text-success")
                ])
            ])
        ], width=3),
        dbc.Col([
            dbc.Card([
                dbc.CardBody([
                    html.H4("📈 سود/زیان", className="card-title"),
                    html.H2(id="pnl-display", children="$0.00", className="text-info")
                ])
            ])
        ], width=3),
        dbc.Col([
            dbc.Card([
                dbc.CardBody([
                    html.H4("🔄 معاملات", className="card-title"),
                    html.H2(id="trades-display", children="0", className="text-warning")
                ])
            ])
        ], width=3),
        dbc.Col([
            dbc.Card([
                dbc.CardBody([
                    html.H4("✅ درصد موفقیت", className="card-title"),
                    html.H2(id="winrate-display", children="0%", className="text-primary")
                ])
            ])
        ], width=3)
    ], className="mb-4"),
    
    # نمودار اصلی
    dbc.Row([
        dbc.Col([
            dbc.Card([
                dbc.CardBody([
                    html.H4("📈 نمودار قیمت و سیگنال‌ها", className="card-title"),
                    dcc.Graph(id="price-chart", style={'height': '500px'}),
                    dcc.Interval(
                        id='interval-component',
                        interval=30*1000,  # به‌روزرسانی هر 30 ثانیه
                        n_intervals=0
                    )
                ])
            ])
        ])
    ], className="mb-4"),
    
    # نمودارهای اندیکاتور
    dbc.Row([
        dbc.Col([
            dbc.Card([
                dbc.CardBody([
                    html.H4("📊 اندیکاتورها", className="card-title"),
                    dcc.Graph(id="indicators-chart", style={'height': '400px'})
                ])
            ])
        ], width=6),
        dbc.Col([
            dbc.Card([
                dbc.CardBody([
                    html.H4("📋 آخرین معاملات", className="card-title"),
                    html.Div(id="trades-table")
                ])
            ])
        ], width=6)
    ], className="mb-4"),
    
    # کنترل‌ها
    dbc.Row([
        dbc.Col([
            dbc.Card([
                dbc.CardBody([
                    html.H4("⚙️ تنظیمات", className="card-title"),
                    dbc.Row([
                        dbc.Col([
                            html.Label("جفت ارز:"),
                            dcc.Dropdown(
                                id="symbol-dropdown",
                                options=[
                                    {"label": "EUR/USD", "value": "EURUSD=X"},
                                    {"label": "GBP/USD", "value": "GBPUSD=X"},
                                    {"label": "USD/JPY", "value": "USDJPY=X"},
                                    {"label": "USD/CHF", "value": "USDCHF=X"},
                                    {"label": "AUD/USD", "value": "AUDUSD=X"}
                                ],
                                value="EURUSD=X"
                            )
                        ], width=4),
                        dbc.Col([
                            html.Label("بازه زمانی:"),
                            dcc.Dropdown(
                                id="interval-dropdown",
                                options=[
                                    {"label": "1 دقیقه", "value": "1m"},
                                    {"label": "5 دقیقه", "value": "5m"},
                                    {"label": "15 دقیقه", "value": "15m"},
                                    {"label": "1 ساعت", "value": "1h"},
                                    {"label": "1 روز", "value": "1d"}
                                ],
                                value="5m"
                            )
                        ], width=4),
                        dbc.Col([
                            html.Label("دوره:"),
                            dcc.Dropdown(
                                id="period-dropdown",
                                options=[
                                    {"label": "1 روز", "value": "1d"},
                                    {"label": "5 روز", "value": "5d"},
                                    {"label": "1 ماه", "value": "1mo"},
                                    {"label": "3 ماه", "value": "3mo"}
                                ],
                                value="1d"
                            )
                        ], width=4)
                    ])
                ])
            ])
        ])
    ])
], fluid=True)

@app.callback(
    [Output('price-chart', 'figure'),
     Output('indicators-chart', 'figure'),
     Output('balance-display', 'children'),
     Output('pnl-display', 'children'),
     Output('trades-display', 'children'),
     Output('winrate-display', 'children')],
    [Input('interval-component', 'n_intervals'),
     Input('symbol-dropdown', 'value'),
     Input('interval-dropdown', 'value'),
     Input('period-dropdown', 'value')]
)
def update_charts(n, symbol, interval, period):
    """به‌روزرسانی نمودارها"""
    global trader
    
    # به‌روزرسانی نماد
    if trader.symbol != symbol:
        trader = RealTimeTrader(symbol)
    
    # دریافت داده‌ها
    try:
        ticker = yf.Ticker(symbol)
        data = ticker.history(period=period, interval=interval)
        
        if data.empty:
            return {}, {}, "$10,000.00", "$0.00", "0", "0%"
        
        # محاسبه اندیکاتورها
        df = trader.calculate_indicators(data)
        signals = trader.generate_signals(df)
        
        # نمودار قیمت
        price_fig = make_subplots(
            rows=2, cols=1,
            shared_xaxes=True,
            vertical_spacing=0.03,
            subplot_titles=('قیمت و سیگنال‌ها', 'حجم معاملات'),
            row_width=[0.7, 0.3]
        )
        
        # نمودار قیمت
        price_fig.add_trace(
            go.Candlestick(
                x=df.index,
                open=df['Open'],
                high=df['High'],
                low=df['Low'],
                close=df['Close'],
                name="قیمت"
            ),
            row=1, col=1
        )
        
        # EMA ها
        price_fig.add_trace(
            go.Scatter(x=df.index, y=df['EMA_9'], name='EMA 9', line=dict(color='orange')),
            row=1, col=1
        )
        price_fig.add_trace(
            go.Scatter(x=df.index, y=df['EMA_21'], name='EMA 21', line=dict(color='blue')),
            row=1, col=1
        )
        price_fig.add_trace(
            go.Scatter(x=df.index, y=df['EMA_50'], name='EMA 50', line=dict(color='red')),
            row=1, col=1
        )
        
        # Bollinger Bands
        price_fig.add_trace(
            go.Scatter(x=df.index, y=df['BB_Upper'], name='BB Upper', 
                      line=dict(color='gray', dash='dash'), opacity=0.7),
            row=1, col=1
        )
        price_fig.add_trace(
            go.Scatter(x=df.index, y=df['BB_Lower'], name='BB Lower', 
                      line=dict(color='gray', dash='dash'), opacity=0.7),
            row=1, col=1
        )
        
        # سیگنال‌ها
        buy_signals = signals[signals['Signal'] == 1]
        sell_signals = signals[signals['Signal'] == -1]
        
        if not buy_signals.empty:
            price_fig.add_trace(
                go.Scatter(
                    x=buy_signals.index,
                    y=df.loc[buy_signals.index, 'Low'] * 0.999,
                    mode='markers',
                    marker=dict(symbol='triangle-up', size=15, color='green'),
                    name='سیگنال خرید'
                ),
                row=1, col=1
            )
        
        if not sell_signals.empty:
            price_fig.add_trace(
                go.Scatter(
                    x=sell_signals.index,
                    y=df.loc[sell_signals.index, 'High'] * 1.001,
                    mode='markers',
                    marker=dict(symbol='triangle-down', size=15, color='red'),
                    name='سیگنال فروش'
                ),
                row=1, col=1
            )
        
        # نمودار حجم
        price_fig.add_trace(
            go.Bar(x=df.index, y=df['Volume'], name='حجم', opacity=0.7),
            row=2, col=1
        )
        
        price_fig.update_layout(
            title=f"نمودار {symbol}",
            xaxis_rangeslider_visible=False,
            height=500
        )
        
        # نمودار اندیکاتورها
        indicators_fig = make_subplots(
            rows=3, cols=1,
            shared_xaxes=True,
            vertical_spacing=0.05,
            subplot_titles=('RSI', 'MACD', 'Stochastic')
        )
        
        # RSI
        indicators_fig.add_trace(
            go.Scatter(x=df.index, y=df['RSI'], name='RSI', line=dict(color='purple')),
            row=1, col=1
        )
        indicators_fig.add_hline(y=70, line_dash="dash", line_color="red", row=1, col=1)
        indicators_fig.add_hline(y=30, line_dash="dash", line_color="green", row=1, col=1)
        
        # MACD
        indicators_fig.add_trace(
            go.Scatter(x=df.index, y=df['MACD'], name='MACD', line=dict(color='blue')),
            row=2, col=1
        )
        indicators_fig.add_trace(
            go.Scatter(x=df.index, y=df['MACD_Signal'], name='Signal', line=dict(color='red')),
            row=2, col=1
        )
        indicators_fig.add_trace(
            go.Bar(x=df.index, y=df['MACD_Hist'], name='Histogram', opacity=0.5),
            row=2, col=1
        )
        
        # Stochastic
        indicators_fig.add_trace(
            go.Scatter(x=df.index, y=df['Stoch_K'], name='%K', line=dict(color='blue')),
            row=3, col=1
        )
        indicators_fig.add_trace(
            go.Scatter(x=df.index, y=df['Stoch_D'], name='%D', line=dict(color='red')),
            row=3, col=1
        )
        indicators_fig.add_hline(y=80, line_dash="dash", line_color="red", row=3, col=1)
        indicators_fig.add_hline(y=20, line_dash="dash", line_color="green", row=3, col=1)
        
        indicators_fig.update_layout(height=400, showlegend=False)
        
        # محاسبه آمار
        current_price = df['Close'].iloc[-1]
        pnl = (current_price - df['Close'].iloc[0]) / df['Close'].iloc[0] * 100
        
        balance = f"${trader.balance:,.2f}"
        pnl_display = f"${pnl:.2f}%"
        trades_count = len(trader.trade_history)
        winrate = "0%"
        
        if trades_count > 0:
            winning_trades = len([t for t in trader.trade_history if t.get('profit', 0) > 0])
            winrate = f"{winning_trades/trades_count*100:.1f}%"
        
        return price_fig, indicators_fig, balance, pnl_display, str(trades_count), winrate
        
    except Exception as e:
        print(f"خطا در به‌روزرسانی: {e}")
        return {}, {}, "$10,000.00", "$0.00", "0", "0%"

@app.callback(
    Output('trades-table', 'children'),
    [Input('interval-component', 'n_intervals')]
)
def update_trades_table(n):
    """به‌روزرسانی جدول معاملات"""
    if not trader.trade_history:
        return html.P("هیچ معامله‌ای انجام نشده است.")
    
    # ایجاد جدول معاملات
    table_header = [
        html.Thead(html.Tr([
            html.Th("تاریخ"),
            html.Th("نوع"),
            html.Th("قیمت ورود"),
            html.Th("قیمت خروج"),
            html.Th("سود/زیان")
        ]))
    ]
    
    table_body = [html.Tbody([
        html.Tr([
            html.Td(trade.get('entry_time', 'N/A').strftime('%H:%M') if hasattr(trade.get('entry_time', 'N/A'), 'strftime') else 'N/A'),
            html.Td("خرید" if trade.get('type') == 'BUY' else "فروش"),
            html.Td(f"${trade.get('entry_price', 0):.5f}"),
            html.Td(f"${trade.get('exit_price', 0):.5f}"),
            html.Td(f"${trade.get('profit', 0):.2f}", 
                   style={'color': 'green' if trade.get('profit', 0) > 0 else 'red'})
        ]) for trade in trader.trade_history[-10:]  # آخرین 10 معامله
    ])]
    
    return dbc.Table(table_header + table_body, bordered=True, hover=True, responsive=True)

if __name__ == '__main__':
    print("🚀 راه‌اندازی داشبورد معاملات فارکس...")
    print("🌐 باز کردن در مرورگر: http://127.0.0.1:8050")
    app.run_server(debug=True, host='0.0.0.0', port=8050)