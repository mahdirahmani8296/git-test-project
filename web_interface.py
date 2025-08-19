#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Forex Trading Bot Web Interface
==============================
Simple web interface for monitoring the forex trading bot.
"""

from flask import Flask, render_template, jsonify, request, redirect, url_for
import json
import os
from datetime import datetime
import threading
from forex_bot import ForexTradingBot

app = Flask(__name__)
bot = ForexTradingBot()
bot_thread = None
bot_running = False

@app.route('/')
def dashboard():
    """Main dashboard page."""
    return render_template('dashboard.html')

@app.route('/api/status')
def get_status():
    """Get bot status and performance data."""
    try:
        if bot.mt5_connected or bot.connect_mt5():
            report = bot.get_performance_report()
            bot.disconnect_mt5()
            
            status = {
                'bot_running': bot_running,
                'connected': True,
                'timestamp': datetime.now().isoformat(),
                'balance': report.get('balance', 0),
                'equity': report.get('equity', 0),
                'open_positions': report.get('open_positions', 0),
                'total_profit': report.get('total_floating_profit', 0),
                'positions': report.get('positions', [])
            }
        else:
            status = {
                'bot_running': bot_running,
                'connected': False,
                'error': 'Unable to connect to MetaTrader 5'
            }
    except Exception as e:
        status = {
            'bot_running': bot_running,
            'connected': False,
            'error': str(e)
        }
    
    return jsonify(status)

@app.route('/api/analysis/<symbol>')
def get_analysis(symbol):
    """Get technical analysis for a symbol."""
    try:
        if bot.connect_mt5():
            analysis = bot.analyze_market(symbol)
            signal = bot.generate_trading_signal(analysis)
            analysis['signal'] = signal
            bot.disconnect_mt5()
            return jsonify(analysis)
        else:
            return jsonify({'error': 'Unable to connect to MetaTrader 5'})
    except Exception as e:
        return jsonify({'error': str(e)})

@app.route('/api/config')
def get_config():
    """Get current configuration."""
    return jsonify(bot.config)

@app.route('/api/config', methods=['POST'])
def update_config():
    """Update configuration."""
    try:
        new_config = request.json
        bot.config.update(new_config)
        
        # Save to file
        with open('config.json', 'w', encoding='utf-8') as f:
            json.dump(bot.config, f, indent=4, ensure_ascii=False)
        
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)})

@app.route('/api/start', methods=['POST'])
def start_bot():
    """Start the trading bot."""
    global bot_thread, bot_running
    
    if not bot_running:
        bot_running = True
        bot_thread = threading.Thread(target=run_bot_thread)
        bot_thread.daemon = True
        bot_thread.start()
        return jsonify({'success': True, 'message': 'Bot started'})
    else:
        return jsonify({'error': 'Bot is already running'})

@app.route('/api/stop', methods=['POST'])
def stop_bot():
    """Stop the trading bot."""
    global bot_running
    
    if bot_running:
        bot_running = False
        bot.stop_trading()
        return jsonify({'success': True, 'message': 'Bot stopped'})
    else:
        return jsonify({'error': 'Bot is not running'})

def run_bot_thread():
    """Run bot in separate thread."""
    global bot_running
    
    try:
        if bot.connect_mt5():
            bot.trading_active = True
            
            while bot_running and bot.trading_active:
                bot.run_trading_cycle()
                # Check every 30 seconds instead of 60 for more responsive web interface
                for _ in range(30):
                    if not bot_running:
                        break
                    threading.Event().wait(1)
        
    except Exception as e:
        print(f"Bot thread error: {e}")
    finally:
        bot_running = False
        bot.stop_trading()

if __name__ == '__main__':
    # Create templates directory and HTML files
    os.makedirs('templates', exist_ok=True)
    
    # Create dashboard template
    dashboard_html = '''<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ربات معاملاتی فارکس</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: #333;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .header {
            text-align: center;
            color: white;
            margin-bottom: 30px;
        }
        
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        
        .status-card {
            background: white;
            border-radius: 15px;
            padding: 25px;
            margin-bottom: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }
        
        .status-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .status-item {
            text-align: center;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 10px;
        }
        
        .status-value {
            font-size: 1.8em;
            font-weight: bold;
            color: #2c3e50;
            margin-bottom: 5px;
        }
        
        .status-label {
            color: #7f8c8d;
            font-size: 0.9em;
        }
        
        .controls {
            display: flex;
            justify-content: center;
            gap: 15px;
            margin-bottom: 20px;
        }
        
        .btn {
            padding: 12px 25px;
            border: none;
            border-radius: 25px;
            font-size: 16px;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        
        .btn-start {
            background: #27ae60;
            color: white;
        }
        
        .btn-start:hover {
            background: #2ecc71;
        }
        
        .btn-stop {
            background: #e74c3c;
            color: white;
        }
        
        .btn-stop:hover {
            background: #c0392b;
        }
        
        .positions-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        
        .positions-table th,
        .positions-table td {
            padding: 12px;
            text-align: center;
            border-bottom: 1px solid #eee;
        }
        
        .positions-table th {
            background: #34495e;
            color: white;
        }
        
        .profit-positive {
            color: #27ae60;
            font-weight: bold;
        }
        
        .profit-negative {
            color: #e74c3c;
            font-weight: bold;
        }
        
        .analysis-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
        }
        
        .analysis-card {
            background: white;
            border-radius: 15px;
            padding: 20px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        
        .symbol-header {
            font-size: 1.3em;
            font-weight: bold;
            margin-bottom: 15px;
            color: #2c3e50;
        }
        
        .signal-badge {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9em;
            font-weight: bold;
            margin-bottom: 15px;
        }
        
        .signal-buy {
            background: #d4edda;
            color: #155724;
        }
        
        .signal-sell {
            background: #f8d7da;
            color: #721c24;
        }
        
        .signal-none {
            background: #d1ecf1;
            color: #0c5460;
        }
        
        .indicator-item {
            display: flex;
            justify-content: space-between;
            margin-bottom: 8px;
            padding: 8px;
            background: #f8f9fa;
            border-radius: 5px;
        }
        
        .loading {
            text-align: center;
            padding: 40px;
            color: #7f8c8d;
        }
        
        .error {
            background: #f8d7da;
            color: #721c24;
            padding: 15px;
            border-radius: 10px;
            margin: 20px 0;
        }
        
        @media (max-width: 768px) {
            .controls {
                flex-direction: column;
                align-items: center;
            }
            
            .btn {
                width: 200px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🤖 ربات معاملاتی فارکس</h1>
            <p>سیستم معاملات خودکار با تحلیل تکنیکال</p>
        </div>
        
        <div class="status-card">
            <div class="controls">
                <button class="btn btn-start" onclick="startBot()">▶️ شروع ربات</button>
                <button class="btn btn-stop" onclick="stopBot()">⏹️ توقف ربات</button>
            </div>
            
            <div id="status-content" class="loading">
                در حال بارگذاری...
            </div>
        </div>
        
        <div id="analysis-section" class="analysis-grid">
        </div>
    </div>

    <script>
        let updateInterval;
        
        function updateStatus() {
            fetch('/api/status')
                .then(response => response.json())
                .then(data => {
                    const statusContent = document.getElementById('status-content');
                    
                    if (data.error) {
                        statusContent.innerHTML = `<div class="error">خطا: ${data.error}</div>`;
                        return;
                    }
                    
                    const statusHtml = `
                        <div class="status-grid">
                            <div class="status-item">
                                <div class="status-value">${data.bot_running ? '🟢 فعال' : '🔴 غیرفعال'}</div>
                                <div class="status-label">وضعیت ربات</div>
                            </div>
                            <div class="status-item">
                                <div class="status-value">$${data.balance ? data.balance.toFixed(2) : '0.00'}</div>
                                <div class="status-label">موجودی حساب</div>
                            </div>
                            <div class="status-item">
                                <div class="status-value">$${data.equity ? data.equity.toFixed(2) : '0.00'}</div>
                                <div class="status-label">حقوق صاحبان سهام</div>
                            </div>
                            <div class="status-item">
                                <div class="status-value">${data.open_positions || 0}</div>
                                <div class="status-label">موقعیت‌های باز</div>
                            </div>
                            <div class="status-item">
                                <div class="status-value ${data.total_profit >= 0 ? 'profit-positive' : 'profit-negative'}">
                                    $${data.total_profit ? data.total_profit.toFixed(2) : '0.00'}
                                </div>
                                <div class="status-label">سود شناور</div>
                            </div>
                        </div>
                    `;
                    
                    if (data.positions && data.positions.length > 0) {
                        const positionsHtml = `
                            <table class="positions-table">
                                <thead>
                                    <tr>
                                        <th>نماد</th>
                                        <th>نوع</th>
                                        <th>حجم</th>
                                        <th>قیمت ورود</th>
                                        <th>قیمت فعلی</th>
                                        <th>سود/زیان</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ${data.positions.map(pos => `
                                        <tr>
                                            <td>${pos.symbol}</td>
                                            <td>${pos.type}</td>
                                            <td>${pos.volume}</td>
                                            <td>${pos.price_open.toFixed(5)}</td>
                                            <td>${pos.price_current.toFixed(5)}</td>
                                            <td class="${pos.profit >= 0 ? 'profit-positive' : 'profit-negative'}">
                                                $${pos.profit.toFixed(2)}
                                            </td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                        `;
                        statusContent.innerHTML = statusHtml + positionsHtml;
                    } else {
                        statusContent.innerHTML = statusHtml;
                    }
                })
                .catch(error => {
                    console.error('Error updating status:', error);
                    document.getElementById('status-content').innerHTML = 
                        `<div class="error">خطا در دریافت وضعیت: ${error.message}</div>`;
                });
        }
        
        function updateAnalysis() {
            const symbols = ['EURUSD', 'GBPUSD', 'USDJPY', 'AUDUSD'];
            const analysisSection = document.getElementById('analysis-section');
            
            Promise.all(symbols.map(symbol => 
                fetch(`/api/analysis/${symbol}`)
                    .then(response => response.json())
                    .then(data => ({symbol, data}))
                    .catch(error => ({symbol, error: error.message}))
            )).then(results => {
                const analysisHtml = results.map(result => {
                    if (result.error) {
                        return `
                            <div class="analysis-card">
                                <div class="symbol-header">${result.symbol}</div>
                                <div class="error">خطا: ${result.error}</div>
                            </div>
                        `;
                    }
                    
                    const data = result.data;
                    const signalClass = data.signal === 'BUY' ? 'signal-buy' : 
                                       data.signal === 'SELL' ? 'signal-sell' : 'signal-none';
                    const signalText = data.signal === 'BUY' ? '📈 خرید' :
                                      data.signal === 'SELL' ? '📉 فروش' : '⚪ بدون سیگنال';
                    
                    return `
                        <div class="analysis-card">
                            <div class="symbol-header">${data.symbol}</div>
                            <div class="signal-badge ${signalClass}">${signalText}</div>
                            
                            <div class="indicator-item">
                                <span>قیمت فعلی:</span>
                                <span>${data.current_price ? data.current_price.toFixed(5) : 'N/A'}</span>
                            </div>
                            <div class="indicator-item">
                                <span>RSI:</span>
                                <span>${data.rsi ? data.rsi.toFixed(2) : 'N/A'}</span>
                            </div>
                            <div class="indicator-item">
                                <span>روند:</span>
                                <span>${data.trend === 'BULLISH' ? '📈 صعودی' : '📉 نزولی'}</span>
                            </div>
                            <div class="indicator-item">
                                <span>MACD:</span>
                                <span>${data.macd ? data.macd.toFixed(5) : 'N/A'}</span>
                            </div>
                            <div class="indicator-item">
                                <span>MA سریع:</span>
                                <span>${data.ma_fast ? data.ma_fast.toFixed(5) : 'N/A'}</span>
                            </div>
                            <div class="indicator-item">
                                <span>MA کند:</span>
                                <span>${data.ma_slow ? data.ma_slow.toFixed(5) : 'N/A'}</span>
                            </div>
                        </div>
                    `;
                }).join('');
                
                analysisSection.innerHTML = analysisHtml;
            });
        }
        
        function startBot() {
            fetch('/api/start', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                }
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('ربات با موفقیت شروع شد');
                } else {
                    alert('خطا: ' + data.error);
                }
            })
            .catch(error => {
                alert('خطا در شروع ربات: ' + error.message);
            });
        }
        
        function stopBot() {
            fetch('/api/stop', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                }
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('ربات متوقف شد');
                } else {
                    alert('خطا: ' + data.error);
                }
            })
            .catch(error => {
                alert('خطا در توقف ربات: ' + error.message);
            });
        }
        
        // Initialize
        updateStatus();
        updateAnalysis();
        
        // Update every 30 seconds
        updateInterval = setInterval(() => {
            updateStatus();
            updateAnalysis();
        }, 30000);
    </script>
</body>
</html>'''
    
    with open('templates/dashboard.html', 'w', encoding='utf-8') as f:
        f.write(dashboard_html)
    
    print("🚀 وب اینترفیس در حال اجرا...")
    print("🌐 آدرس: http://localhost:5000")
    app.run(host='0.0.0.0', port=5000, debug=False)