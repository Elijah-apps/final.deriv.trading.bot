//+------------------------------------------------------------------+
//|                                RSI_KDE_Enhanced_EA.mq5 |
//|                                  Copyright 2024, ELIJAH EKPEN MENSAH® |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "ELIJAH EKPEN MENSAH®"
#property link      "https://www.mql5.com"
#property version   "3.00"
#property description "Advanced RSI KDE Trading Expert Advisor - Uses Original Indicator Buffers"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//--- Trading objects
CTrade trade;
CPositionInfo position;
COrderInfo order;

//--- Position Sizing Methods
enum ENUM_LOT_SIZING
{
    LOT_FIXED = 0,          // Fixed Lot Size
    LOT_RISK_PERCENT = 1,   // Risk Percentage Based
    LOT_BALANCE_PERCENT = 2 // Balance Percentage Based
};

//--- Magic number calculation
#define EA_MAGIC_BASE 12345

//=== Indicator Import Settings ===
input group "=== RSI KDE Indicator Settings ==="
input string IndicatorName = "ELIJAH RSI POPE";              // Indicator Name (without .ex5)
input int RSI_Period = 14;                                   // RSI Length
input ENUM_APPLIED_PRICE RSI_Price = PRICE_CLOSE;           // Price for RSI calculation
input int HighPivotLength = 21;                             // High Pivot Length
input int LowPivotLength = 21;                              // Low Pivot Length
input int ActivationThreshold = 1;                          // Activation Threshold (0=Low, 1=Medium, 2=High)
input int KDEKernel = 0;                                     // KDE Kernel Type (0=Gaussian, 1=Uniform, etc.)
input double KDEBandwidth = 2.71828;                        // KDE Bandwidth
input int KDESteps = 100;                                    // Number of KDE Bins
input int KDELimit = 300;                                    // Maximum KDE data points
input bool ShowBuyArrows = false;                           // Show Buy Arrows (Set to false for EA)
input bool ShowSellArrows = false;                          // Show Sell Arrows (Set to false for EA)
input bool EnableAdaptiveBandwidth = false;                 // Enable Adaptive Bandwidth
input double SignalSensitivity = 1.0;                       // Signal Sensitivity Multiplier
input bool ShowDebugInfo = false;                           // Show Debug Information

//=== Advanced RSI Filters ===
input group "=== Advanced RSI Filters ==="
input int RSIFilterType = 0;                                // RSI Filter Type (0=None, 1=SavGol, 2=T3, 3=Jurik, 4=ATR, 5=Kalman)
input int SavGolPeriod = 21;                                // Savitzky-Golay Period
input int SavGolDegree = 3;                                 // Savitzky-Golay Polynomial Degree
input double T3Period = 14;                                 // T3 Filter Period
input double T3VolumeFactor = 0.7;                          // T3 Volume Factor
input int JurikPhase = 0;                                   // Jurik Phase (-100 to +100)
input double JurikPower = 1.0;                              // Jurik Power (0.5 to 2.5)
input int ATRAdaptivePeriod = 14;                           // ATR Period for Adaptive Filter
input double ATRSensitivity = 1.0;                          // ATR Sensitivity Multiplier
input double MinSmoothingFactor = 0.1;                      // Minimum Smoothing Factor
input double MaxSmoothingFactor = 0.9;                      // Maximum Smoothing Factor
input int KalmanPeriod = 20;                                // Kalman Filter Period
input double KalmanQ = 0.01;                                // Kalman Process Noise
input double KalmanR = 0.1;                                 // Kalman Measurement Noise
input int LADPeriod = 15;                                   // LAD Median Period
input int WienerFFTSize = 32;                               // Wiener FFT Window Size
input double WienerNoiseThreshold = 0.1;                    // Wiener Noise Suppression Threshold
input double KDEGateThreshold = 0.3;                        // KDE Gate Probability Threshold

//=== Fibonacci Filter Settings ===
input group "=== Fibonacci Filter Settings ==="
input bool EnableFibonacciFilter = true;                    // Enable Fibonacci Filter
input bool UseRollingWindow = true;                         // Use Rolling Window for Fib Levels
input int FibRollingPeriod = 100;                           // Rolling Window Period
input int FibSwingLength = 50;                              // Swing High/Low Detection Length
input double FibPremiumStart = 61.8;                        // Premium Zone Start (%)
input double FibDiscountEnd = 38.2;                         // Discount Zone End (%)
input int FibLookbackBars = 200;                            // Fibonacci Calculation Lookback
input bool ShowFibLevels = false;                           // Show Fibonacci Levels on Chart (Set to false for EA)
input bool OnlyTipSignals = true;                           // Only Show Signals at Retracement Tips
input double TipTolerancePercent = 5.0;                     // Tip Tolerance (% of range)

//=== Risk Management Settings ===
input group "=== Risk Management Settings ==="
input bool EnableRiskManagement = true;                     // Enable Risk Management
input int StopLossType = 0;                                 // Stop Loss Type (0=ATR, 1=Fixed Pips, 2=Percent)
input int ATRPeriod = 14;                                   // ATR Period for SL
input double ATRMultiplier = 2.0;                           // ATR Multiplier for SL
input double FixedStopLossPips = 50;                        // Fixed Stop Loss (Pips)
input double StopLossPercent = 1.0;                         // Stop Loss Percentage
input double RiskRewardRatio = 2.0;                         // Risk:Reward Ratio (1:X)
input bool ShowDashboard = true;                            // Show Trading Dashboard
input int DashboardCorner = 1;                              // Dashboard Corner (0-3)
input int DashboardXOffset = 20;                            // Dashboard X Offset
input int DashboardYOffset = 50;                            // Dashboard Y Offset

//=== Backtesting Settings ===
input group "=== Backtesting Settings ==="
input bool EnableBacktesting = false;                       // Enable Backtesting Mode
input double InitialBalance = 10000;                        // Initial Balance
input double RiskPerTrade = 2.0;                           // Risk Per Trade (%)
input bool CompoundProfits = true;                          // Compound Profits

//=== Alert Settings ===
input group "=== Alert Settings ==="
input bool EnableAlerts = true;                             // Enable Alerts
input bool EnablePopupAlerts = true;                        // Enable Popup Alerts
input bool EnableSoundAlerts = true;                        // Enable Sound Alerts
input bool EnableEmailAlerts = false;                       // Enable Email Alerts
input bool EnablePushAlerts = false;                        // Enable Push Notifications
input string BuyAlertSound = "alert.wav";                   // Buy Alert Sound File
input string SellAlertSound = "alert2.wav";                 // Sell Alert Sound File
input string AlertPrefix = "RSI_KDE_EA";                    // Alert Message Prefix
input bool AlertOncePerBar = true;                          // Alert Once Per Bar

//=== Trading Parameters ===
input group "=== Trading Settings ==="
input bool EnableTrading = true;                            // Enable Automated Trading
input ENUM_LOT_SIZING LotSizingMethod = LOT_FIXED;          // Position Sizing Method
input double FixedLotSize = 0.01;                          // Fixed Lot Size
input double RiskPercent = 2.0;                            // Risk Percentage of Balance
input double BalancePercent = 1.0;                         // Balance Percentage per Trade
input int StopLossPips = 100;                              // Stop Loss (Pips) - Override for manual SL
input int TakeProfitPips = 200;                            // Take Profit (Pips) - Override for manual TP
input bool UseTrailingStop = false;                        // Use Trailing Stop
input int TrailingStopPips = 50;                           // Trailing Stop Distance (Pips)
input int TrailingStepPips = 10;                           // Trailing Step (Pips)

//=== Position Stacking ===
input group "=== Position Stacking Settings ==="
input bool EnablePositionStacking = false;                 // Enable Position Stacking
input int MaxStackedPositions = 3;                         // Maximum Stacked Positions
input double StackingSizeMultiplier = 1.0;                 // Size Multiplier for Stacked Positions
input int MinPipsBetweenStacks = 50;                       // Minimum Pips Between Stacked Positions
input bool CloseAllOnOppositeSignal = true;                // Close All Positions on Opposite Signal

//=== Time Filter ===
input group "=== Time Filter Settings ==="
input bool EnableTimeFilter = false;                       // Enable Time Filter
input int StartHour = 8;                                   // Trading Start Hour
input int EndHour = 18;                                    // Trading End Hour
input bool MondayTrading = true;                           // Trade on Monday
input bool TuesdayTrading = true;                          // Trade on Tuesday
input bool WednesdayTrading = true;                        // Trade on Wednesday
input bool ThursdayTrading = true;                         // Trade on Thursday
input bool FridayTrading = true;                           // Trade on Friday

//=== News Filter ===
input group "=== News Filter Settings ==="
input bool EnableNewsFilter = false;                       // Enable News Filter
input int NewsFilterMinutes = 30;                         // Minutes Before/After News

//--- Global variables
int indicator_handle = INVALID_HANDLE;
double buy_buffer[];
double sell_buffer[];

//--- Trading variables
struct TradePosition
{
    ulong ticket;
    int type;
    double lot_size;
    double open_price;
    double stop_loss;
    double take_profit;
    datetime open_time;
    int stack_level;
};

TradePosition active_positions[];
int total_buy_positions = 0;
int total_sell_positions = 0;
double total_profit = 0;
double total_loss = 0;
int total_trades = 0;
int winning_trades = 0;
double max_drawdown = 0;
double peak_balance = 0;
double current_balance = 0;

//--- Signal tracking
datetime last_buy_signal_time = 0;
datetime last_sell_signal_time = 0;
double last_buy_price = 0;
double last_sell_price = 0;
bool buy_signal_processed = false;
bool sell_signal_processed = false;
datetime last_bar_time = 0;

//--- Alert tracking
datetime last_buy_alert_time = 0;
datetime last_sell_alert_time = 0;
bool buy_alert_sent_on_bar = false;
bool sell_alert_sent_on_bar = false;

//--- ATR handle for risk management
int atr_handle = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    //--- Validate inputs
    if(FixedLotSize <= 0)
    {
        Print("Error: Fixed lot size must be positive");
        return(INIT_PARAMETERS_INCORRECT);
    }
    
    if(MaxStackedPositions < 1 || MaxStackedPositions > 10)
    {
        Print("Error: Max stacked positions must be between 1 and 10");
        return(INIT_PARAMETERS_INCORRECT);
    }
    
    //--- Create indicator handle with core parameters only
    //--- Note: You may need to adjust the parameter count based on your actual indicator
    indicator_handle = iCustom(_Symbol, _Period, IndicatorName,
                              RSI_Period,           // RSI Length
                              RSI_Price,            // Price for RSI calculation  
                              HighPivotLength,      // High Pivot Length
                              LowPivotLength,       // Low Pivot Length
                              ActivationThreshold,  // Activation Threshold
                              KDEKernel,           // KDE Kernel Type
                              KDEBandwidth,        // KDE Bandwidth
                              KDESteps,            // Number of KDE Bins
                              KDELimit,            // Maximum KDE data points
                              ShowBuyArrows,       // Show Buy Arrows (set to false)
                              ShowSellArrows,      // Show Sell Arrows (set to false)  
                              EnableAdaptiveBandwidth,  // Enable Adaptive Bandwidth
                              SignalSensitivity,   // Signal Sensitivity Multiplier
                              ShowDebugInfo        // Show Debug Information
                              );
    
    if(indicator_handle == INVALID_HANDLE)
    {
        Print("Error: Failed to create indicator handle. Make sure '", IndicatorName, "' indicator is compiled and available.");
        Print("The indicator file should be named '", IndicatorName, ".ex5' and located in MQL5\\Indicators folder.");
        return(INIT_FAILED);
    }
    
    //--- Create ATR handle for risk management if needed
    if(EnableRiskManagement && (StopLossType == 0 || UseTrailingStop))
    {
        atr_handle = iATR(_Symbol, _Period, ATRPeriod);
        if(atr_handle == INVALID_HANDLE)
        {
            Print("Error creating ATR handle for risk management");
            return(INIT_FAILED);
        }
    }
    
    //--- Setup trading
    trade.SetExpertMagicNumber(EA_MAGIC_BASE);
    trade.SetMarginMode();
    trade.SetTypeFillingBySymbol(_Symbol);
    
    //--- Initialize arrays
    ArrayResize(buy_buffer, 100);
    ArrayResize(sell_buffer, 100);
    ArrayResize(active_positions, MaxStackedPositions * 2);
    ArraySetAsSeries(buy_buffer, true);
    ArraySetAsSeries(sell_buffer, true);
    
    //--- Initialize trading variables
    current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    peak_balance = current_balance;
    last_bar_time = 0;
    
    //--- Wait for indicator to initialize
    Sleep(1000);
    
    //--- Check if indicator buffers are available
    if(CopyBuffer(indicator_handle, 0, 0, 10, buy_buffer) <= 0)
    {
        Print("Warning: Cannot copy indicator buffers yet. Indicator may still be initializing...");
        Print("Error code: ", GetLastError());
    }
    
    //--- Print initialization info
    Print("=== RSI KDE Enhanced EA Initialized Successfully ===");
    Print("Indicator: ", IndicatorName);
    Print("Symbol: ", _Symbol, ", Timeframe: ", EnumToString(_Period));
    Print("Trading Enabled: ", EnableTrading ? "YES" : "NO");
    Print("Position Stacking: ", EnablePositionStacking ? "YES" : "NO");
    Print("Max Stacked Positions: ", MaxStackedPositions);
    Print("Lot Sizing Method: ", LotSizingMethod == LOT_FIXED ? "Fixed" : 
                                 LotSizingMethod == LOT_RISK_PERCENT ? "Risk %" : "Balance %");
    Print("Fixed Lot Size: ", FixedLotSize);
    Print("SL/TP Pips: ", StopLossPips, "/", TakeProfitPips);
    Print("Fibonacci Filter: ", EnableFibonacciFilter ? "ON" : "OFF");
    Print("Time Filter: ", EnableTimeFilter ? "ON" : "OFF");
    Print("=================================================");
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    //--- Release indicator handle
    if(indicator_handle != INVALID_HANDLE)
        IndicatorRelease(indicator_handle);
    
    //--- Release ATR handle
    if(atr_handle != INVALID_HANDLE)
        IndicatorRelease(atr_handle);
    
    //--- Clean up dashboard objects
    if(ShowDashboard)
    {
        ObjectDelete(0, "RSI_KDE_EA_Dashboard");
    }
    
    //--- Print final statistics
    Print("=== EA Performance Summary ===");
    Print("Total Trades: ", total_trades);
    Print("Win Rate: ", total_trades > 0 ? DoubleToString((double)winning_trades/total_trades*100, 2) : "0", "%");
    Print("Final Balance: $", DoubleToString(current_balance, 2));
    Print("Max Drawdown: ", DoubleToString(max_drawdown, 2), "%");
    Print("EA Deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Calculate position size based on method                         |
//+------------------------------------------------------------------+
double CalculatePositionSize(double sl_distance_price = 0)
{
    double lot_size = FixedLotSize;
    
    switch(LotSizingMethod)
    {
        case LOT_FIXED:
            lot_size = FixedLotSize;
            break;
            
        case LOT_RISK_PERCENT:
        {
            double balance = AccountInfoDouble(ACCOUNT_BALANCE);
            double risk_amount = balance * RiskPercent / 100.0;
            
            if(sl_distance_price > 0)
            {
                double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
                double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
                double sl_amount = (sl_distance_price / tick_size) * tick_value;
                
                if(sl_amount > 0)
                    lot_size = risk_amount / sl_amount;
                else
                    lot_size = FixedLotSize;
            }
            else
            {
                // Fallback to fixed lot if SL distance not available
                lot_size = FixedLotSize;
            }
            break;
        }
        
        case LOT_BALANCE_PERCENT:
        {
            double balance = AccountInfoDouble(ACCOUNT_BALANCE);
            double contract_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
            double current_price = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) + SymbolInfoDouble(_Symbol, SYMBOL_BID)) / 2.0;
            
            if(contract_size > 0 && current_price > 0)
                lot_size = (balance * BalancePercent / 100.0) / (contract_size * current_price);
            else
                lot_size = FixedLotSize;
            break;
        }
    }
    
    //--- Apply stacking multiplier if applicable
    if(EnablePositionStacking)
    {
        int current_stack_level = GetCurrentStackLevel(ORDER_TYPE_BUY) + GetCurrentStackLevel(ORDER_TYPE_SELL);
        lot_size *= MathPow(StackingSizeMultiplier, current_stack_level);
    }
    
    //--- Normalize lot size
    double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    lot_size = MathMax(lot_size, min_lot);
    lot_size = MathMin(lot_size, max_lot);
    lot_size = NormalizeDouble(MathRound(lot_size / lot_step) * lot_step, 2);
    
    return lot_size;
}

//+------------------------------------------------------------------+
//| Get current stack level for order type                          |
//+------------------------------------------------------------------+
int GetCurrentStackLevel(ENUM_ORDER_TYPE order_type)
{
    int count = 0;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Symbol() == _Symbol && position.Magic() == EA_MAGIC_BASE)
            {
                if((order_type == ORDER_TYPE_BUY && position.PositionType() == POSITION_TYPE_BUY) ||
                   (order_type == ORDER_TYPE_SELL && position.PositionType() == POSITION_TYPE_SELL))
                {
                    count++;
                }
            }
        }
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| Check if trading is allowed by time filter                      |
//+------------------------------------------------------------------+
bool IsTimeFilterOK()
{
    if(!EnableTimeFilter) return true;
    
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    //--- Check trading hours
    if(dt.hour < StartHour || dt.hour >= EndHour)
        return false;
    
    //--- Check trading days
    switch(dt.day_of_week)
    {
        case 1: return MondayTrading;    // Monday
        case 2: return TuesdayTrading;   // Tuesday
        case 3: return WednesdayTrading; // Wednesday
        case 4: return ThursdayTrading;  // Thursday
        case 5: return FridayTrading;    // Friday
        default: return false;           // Weekend
    }
}

//+------------------------------------------------------------------+
//| Check if news filter allows trading                             |
//+------------------------------------------------------------------+
bool IsNewsFilterOK()
{
    if(!EnableNewsFilter) return true;
    
    // Simplified news filter implementation
    // In a real implementation, you would check economic calendar events
    // For now, we'll assume trading is always allowed
    return true;
}

//+------------------------------------------------------------------+
//| Check if position stacking is allowed                           |
//+------------------------------------------------------------------+
bool IsStackingAllowed(bool is_buy_signal, double current_price)
{
    if(!EnablePositionStacking) return true;
    
    int current_positions = is_buy_signal ? GetCurrentStackLevel(ORDER_TYPE_BUY) : GetCurrentStackLevel(ORDER_TYPE_SELL);
    
    if(current_positions >= MaxStackedPositions)
        return false;
    
    //--- Check minimum distance between stacked positions
    double min_distance = MinPipsBetweenStacks * _Point * 10;
    double last_entry_price = is_buy_signal ? last_buy_price : last_sell_price;
    
    if(last_entry_price > 0 && MathAbs(current_price - last_entry_price) < min_distance)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Close all positions of specified type                           |
//+------------------------------------------------------------------+
void CloseAllPositions(ENUM_POSITION_TYPE position_type = -1)
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Symbol() == _Symbol && position.Magic() == EA_MAGIC_BASE)
            {
                if(position_type == -1 || position.PositionType() == position_type)
                {
                    if(trade.PositionClose(position.Ticket()))
                    {
                        Print("Closed position: ", position.Ticket(), " Type: ", 
                              position.PositionType() == POSITION_TYPE_BUY ? "BUY" : "SELL");
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Calculate stop loss and take profit using indicator's method    |
//+------------------------------------------------------------------+
void CalculateStopLossAndTakeProfit(double entry_price, bool is_buy, double &sl, double &tp)
{
    sl = 0;
    tp = 0;
    
    //--- Use indicator's risk management if enabled, otherwise use manual settings
    if(EnableRiskManagement)
    {
        double sl_distance = 0;
        
        if(StopLossType == 0) // ATR-based
        {
            double atr_values[];
            ArrayResize(atr_values, 1);
            ArraySetAsSeries(atr_values, true);
            
            if(atr_handle != INVALID_HANDLE && CopyBuffer(atr_handle, 0, 0, 1, atr_values) > 0)
            {
                sl_distance = atr_values[0] * ATRMultiplier;
            }
            else
            {
                sl_distance = entry_price * 0.01; // 1% fallback
            }
        }
        else if(StopLossType == 1) // Fixed pips
        {
            sl_distance = FixedStopLossPips * _Point * 10;
        }
        else // Percentage
        {
            sl_distance = entry_price * StopLossPercent / 100.0;
        }
        
        if(is_buy)
        {
            sl = entry_price - sl_distance;
            tp = entry_price + (sl_distance * RiskRewardRatio);
        }
        else
        {
            sl = entry_price + sl_distance;
            tp = entry_price - (sl_distance * RiskRewardRatio);
        }
    }
    else
    {
        // Use manual SL/TP settings
        double sl_distance = StopLossPips * _Point * 10;
        double tp_distance = TakeProfitPips * _Point * 10;
        
        if(is_buy)
        {
            sl = entry_price - sl_distance;
            tp = entry_price + tp_distance;
        }
        else
        {
            sl = entry_price + sl_distance;
            tp = entry_price - tp_distance;
        }
    }
    
    //--- Normalize prices
    sl = NormalizeDouble(sl, _Digits);
    tp = NormalizeDouble(tp, _Digits);
}

//+------------------------------------------------------------------+
//| Execute buy trade                                                |
//+------------------------------------------------------------------+
void ExecuteBuyTrade(double current_price)
{
    if(!EnableTrading) return;
    
    //--- Check filters
    if(!IsTimeFilterOK() || !IsNewsFilterOK())
        return;
    
    //--- Check stacking rules
    if(!IsStackingAllowed(true, current_price))
        return;
    
    //--- Close opposite positions if enabled
    if(CloseAllOnOppositeSignal)
    {
        CloseAllPositions(POSITION_TYPE_SELL);
    }
    
    //--- Calculate stop loss and take profit
    double sl, tp;
    CalculateStopLossAndTakeProfit(current_price, true, sl, tp);
    
    //--- Calculate position size (pass SL distance for risk-based sizing)
    double sl_distance = MathAbs(current_price - sl);
    double lot_size = CalculatePositionSize(sl_distance);
    
    //--- Execute trade
    if(trade.Buy(lot_size, _Symbol, current_price, sl, tp, "RSI_KDE_BUY"))
    {
        ulong ticket = trade.ResultOrder();
        last_buy_price = current_price;
        last_buy_signal_time = TimeCurrent();
        total_buy_positions++;
        total_trades++;
        
        //--- Send alerts
        if(EnableAlerts)
        {
            SendTradeAlert("BUY", current_price, sl, tp, lot_size, ticket);
        }
        
        Print("=== BUY TRADE EXECUTED ===");
        Print("Ticket: ", ticket);
        Print("Price: ", DoubleToString(current_price, _Digits));
        Print("Stop Loss: ", DoubleToString(sl, _Digits));
        Print("Take Profit: ", DoubleToString(tp, _Digits));
        Print("Lot Size: ", DoubleToString(lot_size, 2));
        Print("========================");
    }
    else
    {
        Print("BUY order failed: ", trade.ResultRetcodeDescription());
        Print("Error code: ", trade.ResultRetcode());
    }
}

//+------------------------------------------------------------------+
//| Execute sell trade                                               |
//+------------------------------------------------------------------+
void ExecuteSellTrade(double current_price)
{
    if(!EnableTrading) return;
    
    //--- Check filters
    if(!IsTimeFilterOK() || !IsNewsFilterOK())
        return;
    
    //--- Check stacking rules
    if(!IsStackingAllowed(false, current_price))
        return;
    
    //--- Close opposite positions if enabled
    if(CloseAllOnOppositeSignal)
    {
        CloseAllPositions(POSITION_TYPE_BUY);
    }
    
    //--- Calculate stop loss and take profit
    double sl, tp;
    CalculateStopLossAndTakeProfit(current_price, false, sl, tp);
    
    //--- Calculate position size (pass SL distance for risk-based sizing)
    double sl_distance = MathAbs(current_price - sl);
    double lot_size = CalculatePositionSize(sl_distance);
    
    //--- Execute trade
    if(trade.Sell(lot_size, _Symbol, current_price, sl, tp, "RSI_KDE_SELL"))
    {
        ulong ticket = trade.ResultOrder();
        last_sell_price = current_price;
        last_sell_signal_time = TimeCurrent();
        total_sell_positions++;
        total_trades++;
        
        //--- Send alerts
        if(EnableAlerts)
        {
            SendTradeAlert("SELL", current_price, sl, tp, lot_size, ticket);
        }
        
        Print("=== SELL TRADE EXECUTED ===");
        Print("Ticket: ", ticket);
        Print("Price: ", DoubleToString(current_price, _Digits));
        Print("Stop Loss: ", DoubleToString(sl, _Digits));
        Print("Take Profit: ", DoubleToString(tp, _Digits));
        Print("Lot Size: ", DoubleToString(lot_size, 2));
        Print("=========================");
    }
    else
    {
        Print("SELL order failed: ", trade.ResultRetcodeDescription());
        Print("Error code: ", trade.ResultRetcode());
    }
}

//+------------------------------------------------------------------+
//| Send trade alert                                                 |
//+------------------------------------------------------------------+
void SendTradeAlert(string signal_type, double price, double sl, double tp, double lot_size, ulong ticket)
{
    string message = StringFormat("%s %s Trade Executed: Ticket=%I64u, Price=%s, Lot=%s, SL=%s, TP=%s, Symbol=%s",
                                 AlertPrefix, signal_type, ticket, 
                                 DoubleToString(price, _Digits),
                                 DoubleToString(lot_size, 2),
                                 DoubleToString(sl, _Digits),
                                 DoubleToString(tp, _Digits),
                                 _Symbol);
    
    if(EnablePopupAlerts)
        Alert(message);
    
    if(EnableSoundAlerts)
    {
        string sound_file = (signal_type == "BUY") ? BuyAlertSound : SellAlertSound;
        if(sound_file != "")
            PlaySound(sound_file);
    }
    
    if(EnableEmailAlerts)
        SendMail(AlertPrefix + " Trade Executed", message);
    
    if(EnablePushAlerts)
        SendNotification(message);
    
    Print("ALERT: ", message);
}

//+------------------------------------------------------------------+
//| Update trailing stop                                             |
//+------------------------------------------------------------------+
void UpdateTrailingStop()
{
    if(!UseTrailingStop) return;
    
    double trailing_distance = TrailingStopPips * _Point * 10;
    double trailing_step = TrailingStepPips * _Point * 10;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Symbol() == _Symbol && position.Magic() == EA_MAGIC_BASE)
            {
                double current_price;
                double new_sl = 0;
                bool should_modify = false;
                
                if(position.PositionType() == POSITION_TYPE_BUY)
                {
                    current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                    new_sl = current_price - trailing_distance;
                    
                    if(new_sl > position.StopLoss() + trailing_step || position.StopLoss() == 0)
                    {
                        should_modify = true;
                    }
                }
                else if(position.PositionType() == POSITION_TYPE_SELL)
                {
                    current_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                    new_sl = current_price + trailing_distance;
                    
                    if(new_sl < position.StopLoss() - trailing_step || position.StopLoss() == 0)
                    {
                        should_modify = true;
                    }
                }
                
                if(should_modify)
                {
                    new_sl = NormalizeDouble(new_sl, _Digits);
                    if(trade.PositionModify(position.Ticket(), new_sl, position.TakeProfit()))
                    {
                        Print("Trailing stop updated: Ticket=", position.Ticket(), ", New SL=", DoubleToString(new_sl, _Digits));
                    }
                    else
                    {
                        Print("Failed to update trailing stop for ticket ", position.Ticket(), ": ", trade.ResultRetcodeDescription());
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Update trading statistics                                        |
//+------------------------------------------------------------------+
void UpdateTradingStatistics()
{
    current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    //--- Update peak balance and drawdown
    if(current_balance > peak_balance)
    {
        peak_balance = current_balance;
    }
    else
    {
        double current_drawdown = (peak_balance - current_balance) / peak_balance * 100.0;
        if(current_drawdown > max_drawdown)
        {
            max_drawdown = current_drawdown;
        }
    }
    
    //--- Count positions and calculate basic stats
    total_buy_positions = GetCurrentStackLevel(ORDER_TYPE_BUY);
    total_sell_positions = GetCurrentStackLevel(ORDER_TYPE_SELL);
    
    //--- Update win rate from deal history (simplified calculation)
    static datetime last_stats_update = 0;
    if(TimeCurrent() - last_stats_update > 60) // Update every minute
    {
        HistorySelect(0, TimeCurrent());
        int total_deals = HistoryDealsTotal();
        winning_trades = 0;
        int ea_trades = 0;
        
        for(int i = 0; i < total_deals; i++)
        {
            ulong ticket = HistoryDealGetTicket(i);
            if(ticket > 0 && HistoryDealGetInteger(ticket, DEAL_MAGIC) == EA_MAGIC_BASE)
            {
                if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
                {
                    double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
                    if(profit > 0)
                        winning_trades++;
                    ea_trades++;
                }
            }
        }
        
        total_trades = ea_trades;
        last_stats_update = TimeCurrent();
    }
}

//+------------------------------------------------------------------+
//| Update trading dashboard                                         |
//+------------------------------------------------------------------+
void UpdateTradingDashboard()
{
    if(!ShowDashboard) return;
    
    string dashboard_text = "";
    dashboard_text += "\n=== RSI KDE Enhanced EA Dashboard ===";
    dashboard_text += "\nSymbol: " + _Symbol + " | TF: " + EnumToString(_Period);
    dashboard_text += "\nStatus: " + (EnableTrading ? "TRADING" : "MONITORING");
    dashboard_text += "\nIndicator: " + IndicatorName + (indicator_handle != INVALID_HANDLE ? " [OK]" : " [ERROR]");
    
    dashboard_text += "\n\n=== Current Positions ===";
    dashboard_text += "\nBuy Positions: " + IntegerToString(total_buy_positions);
    dashboard_text += "\nSell Positions: " + IntegerToString(total_sell_positions);
    dashboard_text += "\nMax Stacks: " + IntegerToString(MaxStackedPositions);
    dashboard_text += "\nStacking: " + (EnablePositionStacking ? "ON" : "OFF");
    
    dashboard_text += "\n\n=== Trading Statistics ===";
    dashboard_text += "\nBalance: $" + DoubleToString(current_balance, 2);
    dashboard_text += "\nTotal Trades: " + IntegerToString(total_trades);
    if(total_trades > 0)
    {
        dashboard_text += "\nWin Rate: " + DoubleToString((double)winning_trades / total_trades * 100, 1) + "%";
        dashboard_text += "\nMax DD: " + DoubleToString(max_drawdown, 2) + "%";
    }
    else
    {
        dashboard_text += "\nWin Rate: N/A";
        dashboard_text += "\nMax DD: 0.00%";
    }
    
    dashboard_text += "\n\n=== Risk Management ===";
    string lot_method = (LotSizingMethod == LOT_FIXED) ? "Fixed" : 
                       (LotSizingMethod == LOT_RISK_PERCENT) ? "Risk %" : "Balance %";
    dashboard_text += "\nLot Method: " + lot_method;
    dashboard_text += "\nFixed Lot: " + DoubleToString(FixedLotSize, 2);
    dashboard_text += "\nTrailing: " + (UseTrailingStop ? "ON (" + IntegerToString(TrailingStopPips) + ")" : "OFF");
    
    dashboard_text += "\n\n=== Signal Settings ===";
    dashboard_text += "\nRSI Period: " + IntegerToString(RSI_Period);
    dashboard_text += "\nPivot H/L: " + IntegerToString(HighPivotLength) + "/" + IntegerToString(LowPivotLength);
    dashboard_text += "\nKDE Kernel: " + IntegerToString(KDEKernel);
    dashboard_text += "\nSignal Sens: " + DoubleToString(SignalSensitivity, 1);
    
    dashboard_text += "\n\n=== Active Filters ===";
    dashboard_text += "\nRSI Filter: " + (RSIFilterType == 0 ? "OFF" : "ON (" + IntegerToString(RSIFilterType) + ")");
    dashboard_text += "\nFib Filter: " + (EnableFibonacciFilter ? "ON" : "OFF");
    dashboard_text += "\nTime Filter: " + (EnableTimeFilter ? "ON" : "OFF");
    dashboard_text += "\nNews Filter: " + (EnableNewsFilter ? "ON" : "OFF");
    
    dashboard_text += "\n\n=== Last Signals ===";
    if(last_buy_signal_time > 0)
        dashboard_text += "\nLast BUY: " + TimeToString(last_buy_signal_time, TIME_MINUTES);
    else
        dashboard_text += "\nLast BUY: None";
        
    if(last_sell_signal_time > 0)
        dashboard_text += "\nLast SELL: " + TimeToString(last_sell_signal_time, TIME_MINUTES);
    else
        dashboard_text += "\nLast SELL: None";
    
    // Create or update dashboard object
    string obj_name = "RSI_KDE_EA_Dashboard";
    if(ObjectFind(0, obj_name) < 0)
    {
        ObjectCreate(0, obj_name, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, obj_name, OBJPROP_CORNER, DashboardCorner);
        ObjectSetInteger(0, obj_name, OBJPROP_XDISTANCE, DashboardXOffset);
        ObjectSetInteger(0, obj_name, OBJPROP_YDISTANCE, DashboardYOffset);
        ObjectSetInteger(0, obj_name, OBJPROP_COLOR, clrWhite);
        ObjectSetInteger(0, obj_name, OBJPROP_FONTSIZE, 8);
        ObjectSetString(0, obj_name, OBJPROP_FONT, "Courier New");
        ObjectSetInteger(0, obj_name, OBJPROP_BACK, false);
    }
    
    ObjectSetString(0, obj_name, OBJPROP_TEXT, dashboard_text);
}

//+------------------------------------------------------------------+
//| Check if alert should be sent                                   |
//+------------------------------------------------------------------+
bool ShouldSendAlert(string signal_type, datetime bar_time)
{
    if(!EnableAlerts) return false;
    
    //--- Check alert once per bar setting
    if(AlertOncePerBar)
    {
        static datetime current_bar_time = 0;
        if(current_bar_time != bar_time)
        {
            current_bar_time = bar_time;
            buy_alert_sent_on_bar = false;
            sell_alert_sent_on_bar = false;
        }
        
        if(signal_type == "BUY" && buy_alert_sent_on_bar)
            return false;
        if(signal_type == "SELL" && sell_alert_sent_on_bar)
            return false;
    }
    
    //--- Check time-based filtering (minimum 1 minute between same signal types)
    datetime current_time = TimeCurrent();
    if(signal_type == "BUY")
    {
        if(current_time - last_buy_alert_time < 60) // 1 minute minimum
            return false;
    }
    else if(signal_type == "SELL")
    {
        if(current_time - last_sell_alert_time < 60) // 1 minute minimum
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Update alert tracking                                           |
//+------------------------------------------------------------------+
void UpdateAlertTracking(string signal_type)
{
    datetime current_time = TimeCurrent();
    
    if(signal_type == "BUY")
    {
        last_buy_alert_time = current_time;
        buy_alert_sent_on_bar = true;
    }
    else if(signal_type == "SELL")
    {
        last_sell_alert_time = current_time;
        sell_alert_sent_on_bar = true;
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                            |
//+------------------------------------------------------------------+
void OnTick()
{
    //--- Update trailing stops first
    UpdateTrailingStop();
    
    //--- Update statistics
    UpdateTradingStatistics();
    
    //--- Update dashboard
    UpdateTradingDashboard();
    
    //--- Check for new bar
    datetime current_bar_time = iTime(_Symbol, _Period, 0);
    
    if(current_bar_time <= last_bar_time)
        return; // No new bar
    
    last_bar_time = current_bar_time;
    
    //--- Check if indicator handle is valid
    if(indicator_handle == INVALID_HANDLE)
    {
        Print("Error: Indicator handle is invalid. Cannot get signals.");
        return;
    }
    
    //--- Copy indicator buffers
    // Buffer 0 = Buy signals, Buffer 1 = Sell signals
    int copied_buy = CopyBuffer(indicator_handle, 0, 0, 3, buy_buffer);
    int copied_sell = CopyBuffer(indicator_handle, 1, 0, 3, sell_buffer);
    
    if(copied_buy <= 0 || copied_sell <= 0)
    {
        int error_code = GetLastError();
        if(error_code != 0)
        {
            Print("Error copying indicator buffers. Error: ", error_code);
            if(error_code == 4806) // ERR_INDICATOR_DATA_NOT_FOUND
            {
                Print("Indicator data not ready. Waiting for next tick...");
            }
        }
        return;
    }
    
    //--- Get current values (most recent bar is index 0 with ArraySetAsSeries)
    double current_buy_signal = buy_buffer[0];
    double current_sell_signal = sell_buffer[0];
    
    //--- Get current prices
    double current_ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double current_bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    if(current_ask == 0 || current_bid == 0)
    {
        Print("Error: Cannot get current prices");
        return;
    }
    
    //--- Check for buy signal
    bool buy_signal = (current_buy_signal != EMPTY_VALUE && current_buy_signal > 0);
    bool sell_signal = (current_sell_signal != EMPTY_VALUE && current_sell_signal > 0);
    
    //--- Avoid processing same signal multiple times
    static double last_processed_buy_signal = EMPTY_VALUE;
    static double last_processed_sell_signal = EMPTY_VALUE;
    static datetime last_signal_bar_time = 0;
    
    if(last_signal_bar_time != current_bar_time)
    {
        last_signal_bar_time = current_bar_time;
        last_processed_buy_signal = EMPTY_VALUE;
        last_processed_sell_signal = EMPTY_VALUE;
    }
    
    //--- Execute buy trade
    if(buy_signal && last_processed_buy_signal != current_buy_signal)
    {
        if(ShowDebugInfo)
        {
            Print("BUY SIGNAL DETECTED at ", TimeToString(current_bar_time, TIME_SECONDS));
            Print("Buy buffer value: ", DoubleToString(current_buy_signal, _Digits));
        }
        
        ExecuteBuyTrade(current_ask);
        last_processed_buy_signal = current_buy_signal;
        
        //--- Send signal alert (separate from trade alert)
        if(ShouldSendAlert("BUY", current_bar_time))
        {
            string alert_msg = StringFormat("%s BUY Signal Generated at %s on %s", 
                                           AlertPrefix, DoubleToString(current_ask, _Digits), _Symbol);
            if(EnablePopupAlerts) Alert(alert_msg);
            Print("SIGNAL ALERT: ", alert_msg);
            UpdateAlertTracking("BUY");
        }
    }
    
    //--- Execute sell trade
    if(sell_signal && last_processed_sell_signal != current_sell_signal)
    {
        if(ShowDebugInfo)
        {
            Print("SELL SIGNAL DETECTED at ", TimeToString(current_bar_time, TIME_SECONDS));
            Print("Sell buffer value: ", DoubleToString(current_sell_signal, _Digits));
        }
        
        ExecuteSellTrade(current_bid);
        last_processed_sell_signal = current_sell_signal;
        
        //--- Send signal alert (separate from trade alert)
        if(ShouldSendAlert("SELL", current_bar_time))
        {
            string alert_msg = StringFormat("%s SELL Signal Generated at %s on %s", 
                                           AlertPrefix, DoubleToString(current_bid, _Digits), _Symbol);
            if(EnablePopupAlerts) Alert(alert_msg);
            Print("SIGNAL ALERT: ", alert_msg);
            UpdateAlertTracking("SELL");
        }
    }
    
    //--- Debug information
    if(ShowDebugInfo)
    {
        static int debug_counter = 0;
        debug_counter++;
        
        if(debug_counter % 10 == 0) // Print every 10th tick to avoid spam
        {
            Print("=== DEBUG INFO ===");
            Print("Current Bar: ", TimeToString(current_bar_time, TIME_SECONDS));
            Print("Buy Buffer[0]: ", current_buy_signal == EMPTY_VALUE ? "EMPTY" : DoubleToString(current_buy_signal, _Digits));
            Print("Sell Buffer[0]: ", current_sell_signal == EMPTY_VALUE ? "EMPTY" : DoubleToString(current_sell_signal, _Digits));
            Print("Buy Positions: ", total_buy_positions, ", Sell Positions: ", total_sell_positions);
            Print("Trading Enabled: ", EnableTrading ? "YES" : "NO");
            Print("==================");
        }
    }
}

//+------------------------------------------------------------------+
//| Expert trade transaction function                                |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                       const MqlTradeRequest& request,
                       const MqlTradeResult& result)
{
    //--- Check if it's our EA's transaction
    if(request.magic != EA_MAGIC_BASE)
        return;
    
    //--- Handle different transaction types
    switch(trans.type)
    {
        case TRADE_TRANSACTION_DEAL_ADD:
        {
            if(trans.deal > 0)
            {
                HistoryDealSelect(trans.deal);
                double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
                string symbol = HistoryDealGetString(trans.deal, DEAL_SYMBOL);
                
                if(symbol == _Symbol && profit != 0)
                {
                    if(profit > 0)
                    {
                        total_profit += profit;
                        Print("Trade closed with PROFIT: $", DoubleToString(profit, 2));
                    }
                    else
                    {
                        total_loss += MathAbs(profit);
                        Print("Trade closed with LOSS: $", DoubleToString(profit, 2));
                    }
                    
                    //--- Update statistics
                    UpdateTradingStatistics();
                }
            }
            break;
        }
        
        case TRADE_TRANSACTION_ORDER_ADD:
        {
            if(ShowDebugInfo)
                Print("Order added: ", trans.order);
            break;
        }
        
        case TRADE_TRANSACTION_ORDER_DELETE:
        {
            if(ShowDebugInfo)
                Print("Order deleted: ", trans.order);
            break;
        }
    }
}

//+------------------------------------------------------------------+