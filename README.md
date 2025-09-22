# RSI KDE Enhanced Trading System

## Overview

The RSI KDE Enhanced Trading System consists of two complementary components:

1. **ELIJAH RSI POPE Indicator**: A sophisticated technical analysis indicator that combines RSI (Relative Strength Index) with Kernel Density Estimation (KDE) to generate high-probability trading signals.

2. **RSI_KDE_Enhanced_EA**: An Expert Advisor that automates trading based on signals from the ELIJAH RSI POPE indicator, with advanced risk management, position sizing, and filtering capabilities.

This system is designed for MetaTrader 5 and provides traders with a powerful tool for identifying potential market turning points with statistical confidence.

## Features

### ELIJAH RSI POPE Indicator

- **Advanced RSI Analysis**: Uses customizable RSI periods with multiple price types
- **Kernel Density Estimation**: Implements 8 different kernel types (Gaussian, Uniform, Sigmoid, Epanechnikov, Triangular, Quartic, Triweight, Cosine)
- **Signal Filtering**: Multiple advanced filters including:
  - Savitzky-Golay smoothing
  - T3 Tillson filtering
  - Jurik adaptive smoothing
  - ATR-guided adaptive filtering
  - LAD Kalman-Wiener hybrid filtering
- **Fibonacci Integration**: Automatically identifies swing points and applies Fibonacci retracement levels to filter signals
- **Visual Interface**: Customizable buy/sell arrows with optional Fibonacci level display
- **Alert System**: Comprehensive alert options including popup, sound, email, and push notifications

### RSI_KDE_Enhanced_EA

- **Automated Trading**: Fully automated execution of trades based on indicator signals
- **Advanced Risk Management**:
  - Multiple stop loss methods (ATR-based, fixed pips, percentage)
  - Configurable risk-reward ratios
  - Position sizing based on fixed lots, risk percentage, or balance percentage
- **Position Stacking**: Allows multiple positions in the same direction with configurable size multipliers
- **Time Filtering**: Trade only during specific hours and days
- **News Filtering**: Avoid trading around major news events
- **Trailing Stop**: Dynamic stop loss adjustment to protect profits
- **Comprehensive Dashboard**: Real-time display of trading statistics and system status
- **Backtesting Capabilities**: Built-in backtesting mode with performance metrics

## Installation

1. Download both files:
   - `ELIJAH RSI POPE.mq5`
   - `RSI_KDE_Enhanced_EA.mq5`

2. Place the files in the appropriate MetaTrader 5 directories:
   - Indicator: `MQL5/Indicators/`
   - Expert Advisor: `MQL5/Experts/`

3. Compile both files in the MetaEditor:
   - Open each file in MetaEditor
   - Click the "Compile" button or press F7

4. Restart MetaTrader 5

## Configuration

### ELIJAH RSI POPE Indicator

1. Attach the indicator to a chart by dragging it from the Navigator window
2. Configure the input parameters:
   - **RSI Settings**: Period, Price type
   - **Pivot Detection**: High/Low pivot lengths
   - **KDE Settings**: Kernel type, bandwidth, steps, limit
   - **Activation Threshold**: Signal sensitivity (Low/Medium/High)
   - **Filter Settings**: Choose and configure your preferred filter type
   - **Fibonacci Settings**: Enable/disable Fibonacci filtering and configure parameters
   - **Alert Settings**: Configure alert types and preferences

### RSI_KDE_Enhanced_EA

1. Attach the EA to a chart with the ELIJAH RSI POPE indicator
2. Configure the input parameters:
   - **Indicator Settings**: Ensure they match the indicator settings
   - **Trading Settings**: Enable/disable trading, position sizing method
   - **Risk Management**: Stop loss type, risk-reward ratio
   - **Position Stacking**: Enable/disable and configure stacking parameters
   - **Time Filter**: Set trading hours and days
   - **News Filter**: Enable/disable and configure minutes around news
   - **Alert Settings**: Configure alert preferences

## Usage

### Manual Trading with the Indicator

1. Apply the ELIJAH RSI POPE indicator to your chart
2. Configure the settings according to your trading style
3. Look for buy/sell signals (arrows) on the chart
4. Use the Fibonacci levels as additional confirmation
5. Set appropriate stop loss and take profit levels based on the indicator's risk management calculations

### Automated Trading with the EA

1. Apply both the indicator and the EA to your chart
2. Ensure all settings are properly configured
3. Enable automated trading in MetaTrader 5
4. Monitor the EA's performance through the dashboard
5. Regularly check the trading results and adjust parameters as needed

## Parameters

### Key Indicator Parameters

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| RSI_Period | RSI calculation period | 14 |
| RSI_Price | Price type for RSI calculation | PRICE_CLOSE |
| HighPivotLength | Length for detecting pivot highs | 21 |
| LowPivotLength | Length for detecting pivot lows | 21 |
| ActivationThreshold | Signal sensitivity threshold | THRESHOLD_MEDIUM |
| KDEKernel | Kernel type for density estimation | KERNEL_GAUSSIAN |
| KDEBandwidth | Bandwidth parameter for KDE | 2.71828 |
| EnableFibonacciFilter | Enable Fibonacci filtering | true |
| RSIFilterType | RSI filter type | FILTER_NONE |

### Key EA Parameters

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| EnableTrading | Enable automated trading | true |
| LotSizingMethod | Position sizing method | LOT_FIXED |
| FixedLotSize | Fixed lot size for trading | 0.01 |
| StopLossType | Stop loss calculation method | SL_ATR |
| RiskRewardRatio | Risk to reward ratio | 2.0 |
| EnablePositionStacking | Allow multiple positions in same direction | false |
| MaxStackedPositions | Maximum number of stacked positions | 3 |
| EnableTimeFilter | Enable time-based trading restrictions | false |
| EnableNewsFilter | Enable news event filtering | false |

## Backtesting

To backtest the system:

1. Open the MetaTrader 5 Strategy Tester
2. Select the RSI_KDE_Enhanced_EA
3. Select your preferred symbol and timeframe
4. Set the testing date range
5. Configure the EA parameters
6. Ensure "EnableBacktesting" is set to true
7. Click "Start" to run the backtest

## Troubleshooting

### Common Issues

1. **Indicator not loading**:
   - Verify the indicator file is in the correct directory
   - Recompile the indicator in MetaEditor
   - Check for error messages in the Experts tab

2. **EA not taking trades**:
   - Ensure automated trading is enabled in MetaTrader 5
   - Verify the indicator name matches exactly in the EA settings
   - Check that trading is enabled in the EA parameters
   - Verify your account allows automated trading

3. **Incorrect signals**:
   - Ensure the indicator and EA parameters match
   - Check that all filters are configured correctly
   - Verify the indicator is generating signals as expected

### Optimization

For best results, consider optimizing the following parameters:

1. RSI_Period: Test values between 5-21
2. HighPivotLength/LowPivotLength: Test values between 10-30
3. ActivationThreshold: Test all three settings
4. KDEBandwidth: Test values between 1.0-5.0
5. StopLossType and associated parameters
6. RiskRewardRatio: Test values between 1.5-3.0

## Risk Warning

Trading foreign exchange on margin carries a high level of risk and may not be suitable for all investors. The high degree of leverage can work against you as well as for you. Before deciding to trade foreign exchange, you should carefully consider your investment objectives, level of experience, and risk appetite. The possibility exists that you could sustain a loss of some or all of your initial investment and therefore you should not invest money that you cannot afford to lose. You should be aware of all the risks associated with foreign exchange trading and seek advice from an independent financial advisor if you have any doubts.

## Support

For support, questions, or feature requests:
- Visit the MQL5 community: https://www.mql5.com
- Contact the developer: ELIJAH EKPEN MENSAH®

## Version History

### ELIJAH RSI POPE Indicator
- Version 2.10: Current release with advanced filtering and Fibonacci integration

### RSI_KDE_Enhanced_EA
- Version 3.00: Current release with enhanced position stacking and risk management

## License

This software is copyrighted by ELIJAH EKPEN MENSAH® and is protected by international copyright laws. Unauthorized reproduction or distribution of this software is strictly prohibited.