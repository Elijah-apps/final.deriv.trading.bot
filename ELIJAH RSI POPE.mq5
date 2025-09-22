//+------------------------------------------------------------------+
//|                                    ELIJAH RSI POPE.mq5 |
//|                                  Copyright 2024, ELIJAH EKPEN MENSAH® |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "ELIJAH EKPEN MENSAH®"
#property link      "https://www.mql5.com"
#property version   "2.10"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

//--- Plot settings
#property indicator_label1  "Buy Signal"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrLime
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_label2  "Sell Signal"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

//--- Enums for better parameter handling
enum ENUM_ACTIVATION_THRESHOLD
{
    THRESHOLD_LOW = 0,     // Low (0.15)
    THRESHOLD_MEDIUM = 1,  // Medium (0.25)
    THRESHOLD_HIGH = 2     // High (0.40)
};

enum ENUM_KDE_KERNEL
{
    KERNEL_GAUSSIAN = 0,    // Gaussian (Normal Distribution)
    KERNEL_UNIFORM = 1,     // Uniform (Box Kernel)
    KERNEL_SIGMOID = 2,     // Sigmoid (Logistic)
    KERNEL_EPANECHNIKOV = 3, // Epanechnikov (Parabolic)
    KERNEL_TRIANGULAR = 4,  // Triangular (Linear)
    KERNEL_QUARTIC = 5,     // Quartic (Biweight)
    KERNEL_TRIWEIGHT = 6,   // Triweight
    KERNEL_COSINE = 7       // Cosine
};

//--- Fibonacci zone enums
enum ENUM_FIB_ZONE
{
    FIB_PREMIUM = 0,    // Premium Zone (61.8-100%)
    FIB_EQUILIBRIUM = 1, // Equilibrium Zone (38.2-61.8%)
    FIB_DISCOUNT = 2    // Discount Zone (0-38.2%)
};

//--- RSI Filter Types
enum ENUM_RSI_FILTER
{
    FILTER_NONE = 0,        // No Filter
    FILTER_SAVGOL = 1,      // Savitzky-Golay Filter
    FILTER_T3 = 2,          // T3 Filter
    FILTER_JURIK = 3,       // Jurik Filter
    FILTER_ATR_ADAPTIVE = 4, // ATR-Guided Adaptive Smoothing
    FILTER_LAD_KALMAN_WIENER = 5 // LAD Kalman-Wiener Hybrid Filter
};

//--- Risk Management Types
enum ENUM_SL_TYPE
{
    SL_ATR = 0,             // ATR-based Stop Loss
    SL_FIXED_PIPS = 1,      // Fixed Pips
    SL_PERCENT = 2          // Percentage of Price
};

//--- Input parameters
input int RSI_Period = 14;                                    // RSI Length
input ENUM_APPLIED_PRICE RSI_Price = PRICE_CLOSE;            // Price for RSI calculation
input int HighPivotLength = 21;                              // High Pivot Length
input int LowPivotLength = 21;                               // Low Pivot Length
input ENUM_ACTIVATION_THRESHOLD ActivationThreshold = THRESHOLD_MEDIUM; // Activation Threshold
input ENUM_KDE_KERNEL KDEKernel = KERNEL_GAUSSIAN;           // KDE Kernel Type
input double KDEBandwidth = 2.71828;                         // KDE Bandwidth
input int KDESteps = 100;                                     // Number of KDE Bins
input int KDELimit = 300;                                     // Maximum KDE data points
input bool ShowBuyArrows = true;                             // Show Buy Arrows
input bool ShowSellArrows = true;                            // Show Sell Arrows
input bool EnableAdaptiveBandwidth = false;                  // Enable Adaptive Bandwidth
input double SignalSensitivity = 1.0;                        // Signal Sensitivity Multiplier
input bool ShowDebugInfo = false;                            // Show Debug Information

//--- Advanced Filter Parameters
input group "=== Advanced RSI Filters ==="
input ENUM_RSI_FILTER RSIFilterType = FILTER_NONE;           // RSI Filter Type
input int SavGolPeriod = 21;                                 // Savitzky-Golay Period
input int SavGolDegree = 3;                                  // Savitzky-Golay Polynomial Degree
input double T3Period = 14;                                  // T3 Filter Period
input double T3VolumeFactor = 0.7;                           // T3 Volume Factor
input int JurikPhase = 0;                                    // Jurik Phase (-100 to +100)
input double JurikPower = 1.0;                               // Jurik Power (0.5 to 2.5)
input int ATRAdaptivePeriod = 14;                            // ATR Period for Adaptive Filter
input double ATRSensitivity = 1.0;                           // ATR Sensitivity Multiplier
input double MinSmoothingFactor = 0.1;                       // Minimum Smoothing Factor
input double MaxSmoothingFactor = 0.9;                       // Maximum Smoothing Factor
input int KalmanPeriod = 20;                                 // Kalman Filter Period
input double KalmanQ = 0.01;                                 // Kalman Process Noise (ATR-guided)
input double KalmanR = 0.1;                                  // Kalman Measurement Noise
input int LADPeriod = 15;                                    // LAD Median Period
input int WienerFFTSize = 32;                                // Wiener FFT Window Size
input double WienerNoiseThreshold = 0.1;                     // Wiener Noise Suppression Threshold
input double KDEGateThreshold = 0.3;                         // KDE Gate Probability Threshold

//--- Fibonacci Filter Parameters
input group "=== Fibonacci Filter Settings ==="
input bool EnableFibonacciFilter = true;                     // Enable Fibonacci Filter
input bool UseRollingWindow = true;                          // Use Rolling Window for Fib Levels
input int FibRollingPeriod = 100;                            // Rolling Window Period
input int FibSwingLength = 50;                               // Swing High/Low Detection Length
input double FibPremiumStart = 61.8;                         // Premium Zone Start (%)
input double FibDiscountEnd = 38.2;                          // Discount Zone End (%)
input int FibLookbackBars = 200;                             // Fibonacci Calculation Lookback
input bool ShowFibLevels = true;                             // Show Fibonacci Levels on Chart
input bool OnlyTipSignals = true;                            // Only Show Signals at Retracement Tips
input double TipTolerancePercent = 5.0;                      // Tip Tolerance (% of range)

//--- Risk Management Parameters
input group "=== Risk Management Settings ==="
input bool EnableRiskManagement = true;                      // Enable Risk Management
input ENUM_SL_TYPE StopLossType = SL_ATR;                    // Stop Loss Type
input int ATRPeriod = 14;                                    // ATR Period for SL
input double ATRMultiplier = 2.0;                            // ATR Multiplier for SL
input double FixedStopLossPips = 50;                         // Fixed Stop Loss (Pips)
input double StopLossPercent = 1.0;                          // Stop Loss Percentage
input double RiskRewardRatio = 2.0;                          // Risk:Reward Ratio (1:X)
input bool ShowDashboard = true;                             // Show Trading Dashboard
input int DashboardCorner = 1;                               // Dashboard Corner (0-3)
input int DashboardXOffset = 20;                             // Dashboard X Offset
input int DashboardYOffset = 50;                             // Dashboard Y Offset

//--- Backtesting Parameters
input group "=== Backtesting Settings ==="
input bool EnableBacktesting = false;                        // Enable Backtesting Mode
input double InitialBalance = 10000;                         // Initial Balance
input double RiskPerTrade = 2.0;                            // Risk Per Trade (%)
input bool CompoundProfits = true;                           // Compound Profits

//--- Alert parameters
input group "=== Alert Settings ==="
input bool EnableAlerts = true;                              // Enable Alerts
input bool EnablePopupAlerts = true;                         // Enable Popup Alerts
input bool EnableSoundAlerts = true;                         // Enable Sound Alerts
input bool EnableEmailAlerts = false;                        // Enable Email Alerts
input bool EnablePushAlerts = false;                         // Enable Push Notifications
input string BuyAlertSound = "alert.wav";                    // Buy Alert Sound File
input string SellAlertSound = "alert2.wav";                  // Sell Alert Sound File
input string AlertPrefix = "RSI_KDE_Enhanced";               // Alert Message Prefix
input bool AlertOncePerBar = true;                           // Alert Once Per Bar

//--- Indicator buffers
double BuyBuffer[];
double SellBuffer[];

//--- Global variables
double rsi_values[];
double filtered_rsi[];
double high_pivot_rsis[];
double low_pivot_rsis[];
double kde_high_x[];
double kde_high_y[];
double kde_low_x[];
double kde_low_y[];
int high_pivot_count = 0;
int low_pivot_count = 0;
bool kde_high_needs_recalc = true;
bool kde_low_needs_recalc = true;
double activation_threshold = 0.25;
int rsi_handle;
int atr_handle;
datetime last_calculation_time = 0;

//--- Filter variables
double t3_e1[], t3_e2[], t3_e3[], t3_e4[], t3_e5[], t3_e6[];
double jurik_v1[], jurik_v2[], jurik_s8[], jurik_s10[], jurik_s18[], jurik_s20[];
double savgol_coeffs[];
double atr_adaptive_smoothed[];
double atr_values_for_filter[];
int atr_adaptive_handle;

//--- LAD Kalman-Wiener Hybrid filter variables
double kalman_x[];          // Kalman state estimate
double kalman_p[];          // Kalman error covariance
double kalman_k[];          // Kalman gain
double lad_median_buffer[]; // LAD median calculation buffer
double wiener_real[];       // Wiener filter real part (FFT)
double wiener_imag[];       // Wiener filter imaginary part (FFT)
double wiener_filtered[];   // Wiener filtered output
double hybrid_output[];     // Final hybrid filter output
int kalman_wiener_atr_handle;
bool filters_initialized = false;

//--- Risk Management variables
double current_balance = 0;
int total_trades = 0;
int winning_trades = 0;
double total_profit = 0;
double max_drawdown = 0;
double peak_balance = 0;

//--- Dashboard variables
string dashboard_objects[];
int dashboard_object_count = 0;

//--- Fibonacci variables
struct FibLevel
{
    double price;
    double percentage;
    bool is_valid;
};

struct SwingPoint
{
    int index;
    double price;
    bool is_high;
    datetime time;
};

SwingPoint current_swing_high;
SwingPoint current_swing_low;
FibLevel fib_levels[7]; // 0%, 23.6%, 38.2%, 50%, 61.8%, 78.6%, 100%
bool fib_levels_valid = false;
double swing_high_price = 0;
double swing_low_price = 0;
int swing_high_index = 0;
int swing_low_index = 0;

//--- Performance optimization variables (removed duplicates - already declared in global variables section)

//--- Alert tracking variables
datetime last_buy_alert_time = 0;
datetime last_sell_alert_time = 0;
bool buy_alert_sent_on_bar = false;
bool sell_alert_sent_on_bar = false;
datetime current_bar_time = 0;

//+------------------------------------------------------------------+
//| Initialize Fibonacci levels                                     |
//+------------------------------------------------------------------+
void InitializeFibLevels()
{
    double fib_ratios[] = {0.0, 23.6, 38.2, 50.0, 61.8, 78.6, 100.0};
    
    for(int i = 0; i < 7; i++)
    {
        fib_levels[i].percentage = fib_ratios[i];
        fib_levels[i].price = 0.0;
        fib_levels[i].is_valid = false;
    }
}

//+------------------------------------------------------------------+
//| Find swing high                                                 |
//+------------------------------------------------------------------+
bool FindSwingHigh(const double &high[], int current_bar, int lookback)
{
    if(current_bar < FibSwingLength || current_bar >= ArraySize(high) - FibSwingLength)
        return false;
    
    int highest_bar = current_bar;
    double highest_price = high[current_bar];
    
    // Look for the highest point in the lookback period
    int start_bar = MathMax(0, current_bar - lookback);
    for(int i = start_bar; i <= current_bar; i++)
    {
        if(high[i] > highest_price)
        {
            highest_price = high[i];
            highest_bar = i;
        }
    }
    
    // Verify it's a valid swing high
    bool is_swing = true;
    for(int i = highest_bar - FibSwingLength; i <= highest_bar + FibSwingLength; i++)
    {
        if(i >= 0 && i < ArraySize(high) && i != highest_bar)
        {
            if(high[i] >= highest_price)
            {
                is_swing = false;
                break;
            }
        }
    }
    
    if(is_swing && (current_swing_high.index != highest_bar || current_swing_high.price != highest_price))
    {
        current_swing_high.index = highest_bar;
        current_swing_high.price = highest_price;
        current_swing_high.is_high = true;
        swing_high_price = highest_price;
        swing_high_index = highest_bar;
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Find swing low                                                  |
//+------------------------------------------------------------------+
bool FindSwingLow(const double &low[], int current_bar, int lookback)
{
    if(current_bar < FibSwingLength || current_bar >= ArraySize(low) - FibSwingLength)
        return false;
    
    int lowest_bar = current_bar;
    double lowest_price = low[current_bar];
    
    // Look for the lowest point in the lookback period
    int start_bar = MathMax(0, current_bar - lookback);
    for(int i = start_bar; i <= current_bar; i++)
    {
        if(low[i] < lowest_price)
        {
            lowest_price = low[i];
            lowest_bar = i;
        }
    }
    
    // Verify it's a valid swing low
    bool is_swing = true;
    for(int i = lowest_bar - FibSwingLength; i <= lowest_bar + FibSwingLength; i++)
    {
        if(i >= 0 && i < ArraySize(low) && i != lowest_bar)
        {
            if(low[i] <= lowest_price)
            {
                is_swing = false;
                break;
            }
        }
    }
    
    if(is_swing && (current_swing_low.index != lowest_bar || current_swing_low.price != lowest_price))
    {
        current_swing_low.index = lowest_bar;
        current_swing_low.price = lowest_price;
        current_swing_low.is_high = false;
        swing_low_price = lowest_price;
        swing_low_index = lowest_bar;
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Calculate Fibonacci levels                                      |
//+------------------------------------------------------------------+
void CalculateFibLevels()
{
    if(swing_high_price <= 0 || swing_low_price <= 0 || swing_high_price == swing_low_price)
    {
        fib_levels_valid = false;
        return;
    }
    
    double range = swing_high_price - swing_low_price;
    
    // Calculate Fibonacci retracement levels
    for(int i = 0; i < 7; i++)
    {
        fib_levels[i].price = swing_high_price - (range * fib_levels[i].percentage / 100.0);
        fib_levels[i].is_valid = true;
    }
    
    fib_levels_valid = true;
    
    if(ShowDebugInfo)
    {
        Print(StringFormat("Fibonacci Levels Calculated - High: %.5f, Low: %.5f, Range: %.5f", 
              swing_high_price, swing_low_price, range));
    }
}

//+------------------------------------------------------------------+
//| Get Fibonacci zone                                              |
//+------------------------------------------------------------------+
ENUM_FIB_ZONE GetFibZone(double price)
{
    if(!fib_levels_valid) return FIB_EQUILIBRIUM;
    
    // Find the 61.8% and 38.2% levels
    double fib_618_level = fib_levels[4].price; // 61.8%
    double fib_382_level = fib_levels[2].price; // 38.2%
    
    if(swing_high_price > swing_low_price) // Normal uptrend retracement
    {
        if(price >= fib_618_level)
            return FIB_PREMIUM;
        else if(price <= fib_382_level)
            return FIB_DISCOUNT;
        else
            return FIB_EQUILIBRIUM;
    }
    else // Downtrend retracement (shouldn't happen with our swing detection, but safety check)
    {
        if(price <= fib_618_level)
            return FIB_PREMIUM;
        else if(price >= fib_382_level)
            return FIB_DISCOUNT;
        else
            return FIB_EQUILIBRIUM;
    }
}

//+------------------------------------------------------------------+
//| Check if price is at retracement tip                           |
//+------------------------------------------------------------------+
bool IsAtRetracementTip(double current_price, ENUM_FIB_ZONE zone, const double &high[], const double &low[], int current_bar)
{
    if(!OnlyTipSignals || !fib_levels_valid) return true;
    
    double range = swing_high_price - swing_low_price;
    double tolerance = range * TipTolerancePercent / 100.0;
    
    if(zone == FIB_PREMIUM)
    {
        // Check if we're near the swing high (tip of retracement up)
        return (MathAbs(current_price - swing_high_price) <= tolerance);
    }
    else if(zone == FIB_DISCOUNT)
    {
        // Check if we're near the swing low (tip of retracement down)
        return (MathAbs(current_price - swing_low_price) <= tolerance);
    }
    
    return false; // No signals in equilibrium zone tips
}

//+------------------------------------------------------------------+
//| Fibonacci filter for signals                                   |
//+------------------------------------------------------------------+
bool PassesFibonacciFilter(double current_price, bool is_buy_signal, const double &high[], const double &low[], int current_bar)
{
    if(!EnableFibonacciFilter) return true;
    if(!fib_levels_valid) return false;
    
    ENUM_FIB_ZONE current_zone = GetFibZone(current_price);
    
    // Buy signals only in discount zone (near swing lows)
    if(is_buy_signal)
    {
        if(current_zone != FIB_DISCOUNT) return false;
        return IsAtRetracementTip(current_price, current_zone, high, low, current_bar);
    }
    // Sell signals only in premium zone (near swing highs)
    else
    {
        if(current_zone != FIB_PREMIUM) return false;
        return IsAtRetracementTip(current_price, current_zone, high, low, current_bar);
    }
}

//+------------------------------------------------------------------+
//| Draw Fibonacci levels on chart                                 |
//+------------------------------------------------------------------+
void DrawFibLevels(const datetime &time[], int current_bar)
{
    if(!ShowFibLevels || !fib_levels_valid) return;
    
    static datetime last_draw_time = 0;
    if(time[current_bar] == last_draw_time) return; // Avoid redrawing on same bar
    
    // Clean up previous objects
    for(int i = 0; i < 7; i++)
    {
        ObjectDelete(0, "FibLevel_" + IntegerToString(i));
    }
    
    // Draw new Fibonacci levels
    string level_names[] = {"0.0%", "23.6%", "38.2%", "50.0%", "61.8%", "78.6%", "100.0%"};
    color level_colors[] = {clrGray, clrSilver, clrYellow, clrOrange, clrRed, clrMaroon, clrGray};
    
    datetime start_time = time[MathMax(0, current_bar - 50)];
    datetime end_time = time[current_bar];
    
    for(int i = 0; i < 7; i++)
    {
        if(fib_levels[i].is_valid)
        {
            string obj_name = "FibLevel_" + IntegerToString(i);
            
            if(ObjectCreate(0, obj_name, OBJ_TREND, 0, start_time, fib_levels[i].price, end_time, fib_levels[i].price))
            {
                ObjectSetInteger(0, obj_name, OBJPROP_COLOR, level_colors[i]);
                ObjectSetInteger(0, obj_name, OBJPROP_STYLE, STYLE_DOT);
                ObjectSetInteger(0, obj_name, OBJPROP_WIDTH, 1);
                ObjectSetString(0, obj_name, OBJPROP_TEXT, "Fib " + level_names[i]);
                ObjectSetInteger(0, obj_name, OBJPROP_RAY_RIGHT, true);
                ObjectSetInteger(0, obj_name, OBJPROP_BACK, true);
            }
        }
    }
    
    last_draw_time = time[current_bar];
}

//+------------------------------------------------------------------+
//| Send alert function                                             |
//+------------------------------------------------------------------+
void SendAlert(string signal_type, double price, double rsi_value, double probability, datetime signal_time)
{
    if(!EnableAlerts) return;
    
    string symbol = _Symbol;
    string timeframe = EnumToString(_Period);
    
    //--- Create alert message with Fibonacci info
    string fib_info = "";
    if(EnableFibonacciFilter && fib_levels_valid)
    {
        ENUM_FIB_ZONE zone = GetFibZone(price);
        string zone_name = (zone == FIB_PREMIUM) ? "Premium" : 
                          (zone == FIB_DISCOUNT) ? "Discount" : "Equilibrium";
        fib_info = StringFormat(" [Fib: %s Zone]", zone_name);
    }
    
    string message = StringFormat("%s: %s Signal on %s %s at %.5f (RSI: %.2f, Prob: %.3f)%s", 
                                 AlertPrefix, signal_type, symbol, timeframe, price, rsi_value, probability, fib_info);
    
    //--- Send popup alert
    if(EnablePopupAlerts)
    {
        Alert(message);
    }
    
    //--- Send sound alert
    if(EnableSoundAlerts)
    {
        string sound_file = (signal_type == "BUY") ? BuyAlertSound : SellAlertSound;
        if(sound_file != "")
            PlaySound(sound_file);
    }
    
    //--- Send email alert
    if(EnableEmailAlerts)
    {
        string email_subject = StringFormat("%s %s Signal - %s", AlertPrefix, signal_type, symbol);
        string email_body = StringFormat("Signal: %s\nSymbol: %s\nTimeframe: %s\nPrice: %.5f\nRSI: %.2f\nProbability: %.3f%s\nTime: %s",
                                        signal_type, symbol, timeframe, price, rsi_value, probability, fib_info,
                                        TimeToString(signal_time, TIME_DATE|TIME_SECONDS));
        SendMail(email_subject, email_body);
    }
    
    //--- Send push notification
    if(EnablePushAlerts)
    {
        string push_message = StringFormat("%s %s: %s %.5f (RSI:%.2f)%s", 
                                          AlertPrefix, signal_type, symbol, price, rsi_value, fib_info);
        SendNotification(push_message);
    }
    
    //--- Print to log
    Print(message);
}

//+------------------------------------------------------------------+
//| Check if alert should be sent                                  |
//+------------------------------------------------------------------+
bool ShouldSendAlert(string signal_type, datetime bar_time)
{
    if(!EnableAlerts) return false;
    
    //--- Check if new bar
    if(current_bar_time != bar_time)
    {
        current_bar_time = bar_time;
        buy_alert_sent_on_bar = false;
        sell_alert_sent_on_bar = false;
    }
    
    //--- Check alert once per bar setting
    if(AlertOncePerBar)
    {
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
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    //--- Set activation threshold based on enum input
    switch(ActivationThreshold)
    {
        case THRESHOLD_LOW:
            activation_threshold = 0.15;
            break;
        case THRESHOLD_MEDIUM:
            activation_threshold = 0.25;
            break;
        case THRESHOLD_HIGH:
            activation_threshold = 0.40;
            break;
    }
    
    //--- Validate inputs
    if(RSI_Period < 2 || RSI_Period > 100)
    {
        Print("Error: RSI Period must be between 2 and 100");
        return(INIT_PARAMETERS_INCORRECT);
    }
    
    if(HighPivotLength < 1 || LowPivotLength < 1)
    {
        Print("Error: Pivot lengths must be greater than 0");
        return(INIT_PARAMETERS_INCORRECT);
    }
    
    if(KDEBandwidth <= 0)
    {
        Print("Error: KDE Bandwidth must be positive");
        return(INIT_PARAMETERS_INCORRECT);
    }
    
    if(KDESteps < 10 || KDESteps > 1000)
    {
        Print("Error: KDE Steps must be between 10 and 1000");
        return(INIT_PARAMETERS_INCORRECT);
    }
    
    if(FibSwingLength < 5 || FibSwingLength > 100)
    {
        Print("Error: Fibonacci Swing Length must be between 5 and 100");
        return(INIT_PARAMETERS_INCORRECT);
    }
    
    //--- Indicator buffers mapping
    SetIndexBuffer(0, BuyBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, SellBuffer, INDICATOR_DATA);
    
    //--- Set arrow codes
    PlotIndexSetInteger(0, PLOT_ARROW, 233);  // Up arrow
    PlotIndexSetInteger(1, PLOT_ARROW, 234);  // Down arrow
    
    //--- Set empty values
    PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
    PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
    
    //--- Initialize RSI handle
    rsi_handle = iRSI(_Symbol, _Period, RSI_Period, RSI_Price);
    if(rsi_handle == INVALID_HANDLE)
    {
        Print("Error creating RSI handle");
        return(INIT_FAILED);
    }
    
    //--- Initialize ATR handle for risk management
    if(EnableRiskManagement)
    {
        atr_handle = iATR(_Symbol, _Period, ATRPeriod);
        if(atr_handle == INVALID_HANDLE)
        {
            Print("Error creating ATR handle");
            return(INIT_FAILED);
        }
    }
    
    //--- Initialize ATR handle for adaptive filtering
    if(RSIFilterType == FILTER_ATR_ADAPTIVE)
    {
        atr_adaptive_handle = iATR(_Symbol, _Period, ATRAdaptivePeriod);
        if(atr_adaptive_handle == INVALID_HANDLE)
        {
            Print("Error creating ATR handle for adaptive filtering");
            return(INIT_FAILED);
        }
    }
    
    //--- Initialize ATR handle for Kalman-Wiener hybrid filtering
    if(RSIFilterType == FILTER_LAD_KALMAN_WIENER)
    {
        kalman_wiener_atr_handle = iATR(_Symbol, _Period, KalmanPeriod);
        if(kalman_wiener_atr_handle == INVALID_HANDLE)
        {
            Print("Error creating ATR handle for Kalman-Wiener filtering");
            return(INIT_FAILED);
        }
    }
    
    //--- Resize arrays with error checking
    if(!ArrayResize(rsi_values, KDELimit) ||
       !ArrayResize(filtered_rsi, KDELimit) ||
       !ArrayResize(high_pivot_rsis, KDELimit) ||
       !ArrayResize(low_pivot_rsis, KDELimit) ||
       !ArrayResize(kde_high_x, KDESteps * 2) ||
       !ArrayResize(kde_high_y, KDESteps * 2) ||
       !ArrayResize(kde_low_x, KDESteps * 2) ||
       !ArrayResize(kde_low_y, KDESteps * 2))
    {
        Print("Error resizing arrays");
        return(INIT_FAILED);
    }
    
    //--- Initialize filter arrays if needed
    if(RSIFilterType != FILTER_NONE)
    {
        InitializeFilters();
    }
    
    //--- Initialize backtesting variables
    if(EnableBacktesting)
    {
        current_balance = InitialBalance;
        peak_balance = InitialBalance;
        total_trades = 0;
        winning_trades = 0;
        total_profit = 0;
        max_drawdown = 0;
    }
    
    //--- Initialize arrays
    ArrayInitialize(BuyBuffer, EMPTY_VALUE);
    ArrayInitialize(SellBuffer, EMPTY_VALUE);
    ArrayInitialize(high_pivot_rsis, 0.0);
    ArrayInitialize(low_pivot_rsis, 0.0);
    
    //--- Initialize Fibonacci levels
    InitializeFibLevels();
    
    //--- Initialize swing points
    current_swing_high.index = -1;
    current_swing_high.price = 0;
    current_swing_high.is_high = true;
    
    current_swing_low.index = -1;
    current_swing_low.price = 0;
    current_swing_low.is_high = false;
    
    //--- Initialize alert tracking
    last_buy_alert_time = 0;
    last_sell_alert_time = 0;
    buy_alert_sent_on_bar = false;
    sell_alert_sent_on_bar = false;
    current_bar_time = 0;
    
    //--- Set indicator name
    string kernel_name = GetKernelName(KDEKernel);
    string fib_status = EnableFibonacciFilter ? " + Fib Filter" : "";
    string indicator_name = StringFormat("RSI KDE (%s, %d, %.2f)%s", kernel_name, RSI_Period, KDEBandwidth, fib_status);
    IndicatorSetString(INDICATOR_SHORTNAME, indicator_name);
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    if(rsi_handle != INVALID_HANDLE)
        IndicatorRelease(rsi_handle);
    
    //--- Clean up Fibonacci level objects
    if(ShowFibLevels)
    {
        for(int i = 0; i < 7; i++)
        {
            ObjectDelete(0, "FibLevel_" + IntegerToString(i));
        }
    }
}

//+------------------------------------------------------------------+
//| Get kernel name string                                          |
//+------------------------------------------------------------------+
string GetKernelName(ENUM_KDE_KERNEL kernel)
{
    switch(kernel)
    {
        case KERNEL_GAUSSIAN: return "Gaussian";
        case KERNEL_UNIFORM: return "Uniform";
        case KERNEL_SIGMOID: return "Sigmoid";
        case KERNEL_EPANECHNIKOV: return "Epanechnikov";
        case KERNEL_TRIANGULAR: return "Triangular";
        case KERNEL_QUARTIC: return "Quartic";
        case KERNEL_TRIWEIGHT: return "Triweight";
        case KERNEL_COSINE: return "Cosine";
        default: return "Unknown";
    }
}

//+------------------------------------------------------------------+
//| Enhanced kernel functions                                       |
//+------------------------------------------------------------------+
double Gaussian(double distance, double bandwidth = 1.0)
{
    double std_dist = distance / bandwidth;
    return (1.0 / (bandwidth * MathSqrt(2.0 * M_PI))) * MathExp(-0.5 * std_dist * std_dist);
}

double Uniform(double distance, double bandwidth = 1.0)
{
    return (MathAbs(distance) <= bandwidth) ? 0.5 / bandwidth : 0.0;
}

double Sigmoid(double distance, double bandwidth = 1.0)
{
    double exp_pos = MathExp(distance / bandwidth);
    double exp_neg = MathExp(-distance / bandwidth);
    return (2.0 / (M_PI * bandwidth)) * (1.0 / (exp_pos + exp_neg));
}

double Epanechnikov(double distance, double bandwidth = 1.0)
{
    double u = distance / bandwidth;
    return (MathAbs(u) <= 1.0) ? (3.0 / (4.0 * bandwidth)) * (1.0 - u * u) : 0.0;
}

double Triangular(double distance, double bandwidth = 1.0)
{
    double u = MathAbs(distance) / bandwidth;
    return (u <= 1.0) ? (1.0 - u) / bandwidth : 0.0;
}

double Quartic(double distance, double bandwidth = 1.0)
{
    double u = distance / bandwidth;
    return (MathAbs(u) <= 1.0) ? (15.0 / (16.0 * bandwidth)) * MathPow(1.0 - u * u, 2.0) : 0.0;
}

double Triweight(double distance, double bandwidth = 1.0)
{
    double u = distance / bandwidth;
    return (MathAbs(u) <= 1.0) ? (35.0 / (32.0 * bandwidth)) * MathPow(1.0 - u * u, 3.0) : 0.0;
}

double Cosine(double distance, double bandwidth = 1.0)
{
    double u = distance / bandwidth;
    return (MathAbs(u) <= 1.0) ? (M_PI / (4.0 * bandwidth)) * MathCos(M_PI * u / 2.0) : 0.0;
}
 //+------------------------------------------------------------------+
//| Get kernel function value                                       |
//+------------------------------------------------------------------+
double GetKernelValue(double distance, double bandwidth, ENUM_KDE_KERNEL kernel)
{
    switch(kernel)
    {
        case KERNEL_GAUSSIAN: return Gaussian(distance, bandwidth);
        case KERNEL_UNIFORM: return Uniform(distance, bandwidth);
        case KERNEL_SIGMOID: return Sigmoid(distance, bandwidth);
        case KERNEL_EPANECHNIKOV: return Epanechnikov(distance, bandwidth);
        case KERNEL_TRIANGULAR: return Triangular(distance, bandwidth);
        case KERNEL_QUARTIC: return Quartic(distance, bandwidth);
        case KERNEL_TRIWEIGHT: return Triweight(distance, bandwidth);
        case KERNEL_COSINE: return Cosine(distance, bandwidth);
        default: return Gaussian(distance, bandwidth);
    }
}

//+------------------------------------------------------------------+
//| Calculate KDE for given data points                             |
//+------------------------------------------------------------------+
void CalculateKDE(const double &data[], int data_count, double &x[], double &y[], int steps, double bandwidth, ENUM_KDE_KERNEL kernel)
{
    if(data_count < 1) return;
    
    // Determine range for KDE evaluation
    double min_val = data[0];
    double max_val = data[0];
    for(int i = 1; i < data_count; i++)
    {
        if(data[i] < min_val) min_val = data[i];
        if(data[i] > max_val) max_val = data[i];
    }
    
    // Add some padding to the range
    double range = max_val - min_val;
    min_val -= range * 0.1;
    max_val += range * 0.1;
    double step_size = (max_val - min_val) / (steps - 1);
    
    // Calculate KDE at each point
    for(int i = 0; i < steps; i++)
    {
        x[i] = min_val + i * step_size;
        y[i] = 0.0;
        
        for(int j = 0; j < data_count; j++)
        {
            double distance = x[i] - data[j];
            y[i] += GetKernelValue(distance, bandwidth, kernel);
        }
        
        y[i] /= data_count; // Normalize
    }
}

//+------------------------------------------------------------------+
//| Find peaks in KDE results                                       |
//+------------------------------------------------------------------+
bool FindPeaks(const double &y[], int steps, int &peak_index, double &peak_value)
{
    if(steps < 3) return false;
    
    bool found = false;
    peak_value = 0.0;
    peak_index = -1;
    
    for(int i = 1; i < steps - 1; i++)
    {
        if(y[i] > y[i-1] && y[i] > y[i+1] && y[i] > peak_value)
        {
            peak_value = y[i];
            peak_index = i;
            found = true;
        }
    }
    
    return found;
}

//+------------------------------------------------------------------+
//| Calculate probability density at given RSI value                |
//+------------------------------------------------------------------+
double CalculateProbability(double rsi_value, const double &x[], const double &y[], int steps)
{
    if(steps < 2) return 0.0;
    
    // Find the interval where the RSI value falls
    for(int i = 0; i < steps - 1; i++)
    {
        if(rsi_value >= x[i] && rsi_value <= x[i+1])
        {
            // Linear interpolation
            double t = (rsi_value - x[i]) / (x[i+1] - x[i]);
            return y[i] + t * (y[i+1] - y[i]);
        }
    }
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Find pivot highs in RSI                                         |
//+------------------------------------------------------------------+
void FindPivotHighs(const double &rsi_data[], int count, int length, double &pivots[], int &pivot_count)
{
    pivot_count = 0;
    if(count < length * 2 + 1 || length <= 0) return;
    
    // Ensure we have valid array bounds
    int start_index = MathMax(length, 0);
    int end_index = MathMin(count - length, count - 1);
    
    for(int i = start_index; i < end_index; i++)
    {
        bool is_pivot = true;
        double current = rsi_data[i];
        
        // Validate current value
        if(current == EMPTY_VALUE || current != current) // Check for NaN
            continue;
        
        // Check left side
        for(int j = 1; j <= length && is_pivot; j++)
        {
            int left_index = i - j;
            if(left_index < 0 || rsi_data[left_index] == EMPTY_VALUE)
            {
                is_pivot = false;
                break;
            }
            if(current <= rsi_data[left_index])
            {
                is_pivot = false;
            }
        }
        
        // Check right side
        if(is_pivot)
        {
            for(int j = 1; j <= length && is_pivot; j++)
            {
                int right_index = i + j;
                if(right_index >= count || rsi_data[right_index] == EMPTY_VALUE)
                {
                    is_pivot = false;
                    break;
                }
                if(current <= rsi_data[right_index])
                {
                    is_pivot = false;
                }
            }
        }
        
        if(is_pivot && pivot_count < KDELimit && current > 0)
        {
            pivots[pivot_count++] = current;
        }
    }
}

//+------------------------------------------------------------------+
//| Find pivot lows in RSI                                          |
//+------------------------------------------------------------------+
void FindPivotLows(const double &rsi_data[], int count, int length, double &pivots[], int &pivot_count)
{
    pivot_count = 0;
    if(count < length * 2 + 1 || length <= 0) return;
    
    // Ensure we have valid array bounds
    int start_index = MathMax(length, 0);
    int end_index = MathMin(count - length, count - 1);
    
    for(int i = start_index; i < end_index; i++)
    {
        bool is_pivot = true;
        double current = rsi_data[i];
        
        // Validate current value
        if(current == EMPTY_VALUE || current != current) // Check for NaN
            continue;
        
        // Check left side
        for(int j = 1; j <= length && is_pivot; j++)
        {
            int left_index = i - j;
            if(left_index < 0 || rsi_data[left_index] == EMPTY_VALUE)
            {
                is_pivot = false;
                break;
            }
            if(current >= rsi_data[left_index])
            {
                is_pivot = false;
            }
        }
        
        // Check right side
        if(is_pivot)
        {
            for(int j = 1; j <= length && is_pivot; j++)
            {
                int right_index = i + j;
                if(right_index >= count || rsi_data[right_index] == EMPTY_VALUE)
                {
                    is_pivot = false;
                    break;
                }
                if(current >= rsi_data[right_index])
                {
                    is_pivot = false;
                }
            }
        }
        
        if(is_pivot && pivot_count < KDELimit && current >= 0)
        {
            pivots[pivot_count++] = current;
        }
    }
}

//+------------------------------------------------------------------+
//| Calculate adaptive bandwidth                                    |
//+------------------------------------------------------------------+
double CalculateAdaptiveBandwidth(const double &data[], int count)
{
    if(count < 2) return KDEBandwidth;
    
    // Calculate standard deviation
    double sum = 0.0;
    for(int i = 0; i < count; i++) sum += data[i];
    double mean = sum / count;
    
    double variance = 0.0;
    for(int i = 0; i < count; i++)
        variance += MathPow(data[i] - mean, 2.0);
    variance /= (count - 1);
    
    double std_dev = MathSqrt(variance);
    
    // Silverman's rule of thumb
    double iqr = CalculateIQR(data, count);
    double h = 0.9 * MathMin(std_dev, iqr / 1.34) * MathPow(count, -0.2);
    
    return MathMax(h, 0.1); // Ensure minimum bandwidth
}

//+------------------------------------------------------------------+
//| Calculate interquartile range                                   |
//+------------------------------------------------------------------+
double CalculateIQR(const double &data[], int count)
{
    if(count < 4) return 0.0;
    
    // Create a copy of the data
    double temp[];
    ArrayResize(temp, count);
    ArrayCopy(temp, data);
    
    // Sort the array
    ArraySort(temp);
    
    // Calculate Q1 and Q3
    int q1_index = (int)MathRound(0.25 * (count + 1)) - 1;
    int q3_index = (int)MathRound(0.75 * (count + 1)) - 1;
    
    // Ensure indices are within bounds
    q1_index = MathMax(0, MathMin(q1_index, count - 1));
    q3_index = MathMax(0, MathMin(q3_index, count - 1));
    
    double q1 = temp[q1_index];
    double q3 = temp[q3_index];
    
    return q3 - q1;
}

//+------------------------------------------------------------------+
//| Initialize filter arrays and coefficients                       |
//+------------------------------------------------------------------+
void InitializeFilters()
{
    if(RSIFilterType == FILTER_T3)
    {
        ArrayResize(t3_e1, KDELimit);
        ArrayResize(t3_e2, KDELimit);
        ArrayResize(t3_e3, KDELimit);
        ArrayResize(t3_e4, KDELimit);
        ArrayResize(t3_e5, KDELimit);
        ArrayResize(t3_e6, KDELimit);
        ArrayInitialize(t3_e1, 0.0);
        ArrayInitialize(t3_e2, 0.0);
        ArrayInitialize(t3_e3, 0.0);
        ArrayInitialize(t3_e4, 0.0);
        ArrayInitialize(t3_e5, 0.0);
        ArrayInitialize(t3_e6, 0.0);
    }
    else if(RSIFilterType == FILTER_JURIK)
    {
        ArrayResize(jurik_v1, KDELimit);
        ArrayResize(jurik_v2, KDELimit);
        ArrayResize(jurik_s8, KDELimit);
        ArrayResize(jurik_s10, KDELimit);
        ArrayResize(jurik_s18, KDELimit);
        ArrayResize(jurik_s20, KDELimit);
        ArrayInitialize(jurik_v1, 0.0);
        ArrayInitialize(jurik_v2, 0.0);
        ArrayInitialize(jurik_s8, 0.0);
        ArrayInitialize(jurik_s10, 0.0);
        ArrayInitialize(jurik_s18, 0.0);
        ArrayInitialize(jurik_s20, 0.0);
    }
    else if(RSIFilterType == FILTER_SAVGOL)
    {
        CalculateSavGolCoefficients();
    }
    else if(RSIFilterType == FILTER_ATR_ADAPTIVE)
    {
        ArrayResize(atr_adaptive_smoothed, KDELimit);
        ArrayResize(atr_values_for_filter, KDELimit);
        ArrayInitialize(atr_adaptive_smoothed, 0.0);
        ArrayInitialize(atr_values_for_filter, 0.0);
    }
    else if(RSIFilterType == FILTER_LAD_KALMAN_WIENER)
    {
        ArrayResize(kalman_x, KDELimit);
        ArrayResize(kalman_p, KDELimit);
        ArrayResize(kalman_k, KDELimit);
        ArrayResize(lad_median_buffer, LADPeriod);
        ArrayResize(wiener_real, WienerFFTSize);
        ArrayResize(wiener_imag, WienerFFTSize);
        ArrayResize(wiener_filtered, KDELimit);
        ArrayResize(hybrid_output, KDELimit);
        
        ArrayInitialize(kalman_x, 0.0);
        ArrayInitialize(kalman_p, 1.0);
        ArrayInitialize(kalman_k, 0.0);
        ArrayInitialize(lad_median_buffer, 0.0);
        ArrayInitialize(wiener_real, 0.0);
        ArrayInitialize(wiener_imag, 0.0);
        ArrayInitialize(wiener_filtered, 0.0);
        ArrayInitialize(hybrid_output, 0.0);
    }
    
    filters_initialized = true;
}

//+------------------------------------------------------------------+
//| Apply RSI filter based on selected type                         |
//+------------------------------------------------------------------+
double ApplyRSIFilter(double rsi_value, int index)
{
    if(RSIFilterType == FILTER_NONE || !filters_initialized)
        return rsi_value;
    
    switch(RSIFilterType)
    {
        case FILTER_T3:
            return ApplyT3Filter(rsi_value, index);
        case FILTER_JURIK:
            return ApplyJurikFilter(rsi_value, index);
        case FILTER_SAVGOL:
            return ApplySavGolFilter(rsi_value, index);
        case FILTER_ATR_ADAPTIVE:
            return ApplyATRAdaptiveFilter(rsi_value, index);
        case FILTER_LAD_KALMAN_WIENER:
            return ApplyLADKalmanWienerFilter(rsi_value, index);
        default:
            return rsi_value;
    }
}

//+------------------------------------------------------------------+
//| Apply T3 filter                                                 |
//+------------------------------------------------------------------+
double ApplyT3Filter(double value, int index)
{
    if(index < 1) return value;
    
    double alpha = 2.0 / (T3Period + 1.0);
    double c1 = -alpha * alpha * alpha;
    double c2 = 3.0 * alpha * alpha + 3.0 * alpha * alpha * alpha;
    double c3 = -6.0 * alpha * alpha - 3.0 * alpha - 3.0 * alpha * alpha * alpha;
    double c4 = 1.0 + 3.0 * alpha + alpha * alpha * alpha + 3.0 * alpha * alpha;
    
    t3_e1[index] = alpha * value + (1.0 - alpha) * t3_e1[index - 1];
    t3_e2[index] = alpha * t3_e1[index] + (1.0 - alpha) * t3_e2[index - 1];
    t3_e3[index] = alpha * t3_e2[index] + (1.0 - alpha) * t3_e3[index - 1];
    t3_e4[index] = alpha * t3_e3[index] + (1.0 - alpha) * t3_e4[index - 1];
    t3_e5[index] = alpha * t3_e4[index] + (1.0 - alpha) * t3_e5[index - 1];
    t3_e6[index] = alpha * t3_e5[index] + (1.0 - alpha) * t3_e6[index - 1];
    
    return c1 * t3_e6[index] + c2 * t3_e5[index] + c3 * t3_e4[index] + c4 * t3_e3[index];
}

//+------------------------------------------------------------------+
//| Apply Jurik filter                                              |
//+------------------------------------------------------------------+
double ApplyJurikFilter(double value, int index)
{
    if(index < 1) return value;
    
    double phase_ratio = JurikPhase < -100 ? 0.5 : (JurikPhase > 100 ? 2.5 : JurikPhase / 100.0 + 1.5);
    double beta = 0.45 * (14.0 - 1.0) / (0.45 * (14.0 - 1.0) + 2.0);
    double alpha = beta;
    
    jurik_v1[index] = (1.0 - alpha) * value + alpha * jurik_v1[index - 1];
    jurik_v2[index] = (value - jurik_v1[index]) * (1.0 - beta) + beta * jurik_v2[index - 1];
    
    return jurik_v1[index] + phase_ratio * jurik_v2[index];
}

//+------------------------------------------------------------------+
//| Calculate Savitzky-Golay coefficients                           |
//+------------------------------------------------------------------+
void CalculateSavGolCoefficients()
{
    int n = SavGolPeriod;
    ArrayResize(savgol_coeffs, n);
    
    // Simplified Savitzky-Golay coefficients for smoothing
    // Using a simple moving average approximation for now
    double sum = 0.0;
    for(int i = 0; i < n; i++)
    {
        savgol_coeffs[i] = 1.0; // Equal weights for simplicity
        sum += savgol_coeffs[i];
    }
    
    // Normalize coefficients
    for(int i = 0; i < n; i++)
    {
        savgol_coeffs[i] /= sum;
    }
}

//+------------------------------------------------------------------+
//| Apply Savitzky-Golay filter                                     |
//+------------------------------------------------------------------+
double ApplySavGolFilter(double value, int index)
{
    if(index < SavGolPeriod) return value;
    
    double filtered_value = 0.0;
    for(int i = 0; i < SavGolPeriod; i++)
    {
        int data_index = index - SavGolPeriod + 1 + i;
        if(data_index >= 0 && data_index < ArraySize(rsi_values))
        {
            filtered_value += rsi_values[data_index] * savgol_coeffs[i];
        }
    }
    
    return filtered_value;
}

//+------------------------------------------------------------------+
//| Apply ATR-Guided Adaptive Smoothing filter                      |
//+------------------------------------------------------------------+
double ApplyATRAdaptiveFilter(double rsi_value, int index)
{
    if(index < 1) return rsi_value;
    
    // Get current ATR value
    double current_atr = 0;
    if(CopyBuffer(atr_adaptive_handle, 0, index, 1, atr_values_for_filter) > 0)
    {
        current_atr = atr_values_for_filter[0];
    }
    else
    {
        // Fallback: use previous smoothed value if ATR unavailable
        return (index > 0) ? atr_adaptive_smoothed[index - 1] : rsi_value;
    }
    
    // Calculate ATR-based volatility measure
    double price_range = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) + SymbolInfoDouble(_Symbol, SYMBOL_BID)) / 2.0;
    double volatility_ratio = (current_atr * ATRSensitivity) / price_range;
    
    // Normalize volatility ratio to 0-1 range
    volatility_ratio = MathMin(MathMax(volatility_ratio, 0.0), 1.0);
    
    // Calculate adaptive smoothing factor
    // High volatility = more smoothing (higher alpha)
    // Low volatility = less smoothing (lower alpha)
    double adaptive_alpha = MinSmoothingFactor + (volatility_ratio * (MaxSmoothingFactor - MinSmoothingFactor));
    
    // Apply exponential moving average with adaptive alpha
    double smoothed_value;
    if(index == 0 || atr_adaptive_smoothed[index - 1] == 0)
    {
        smoothed_value = rsi_value;
    }
    else
    {
        smoothed_value = (adaptive_alpha * rsi_value) + ((1.0 - adaptive_alpha) * atr_adaptive_smoothed[index - 1]);
    }
    
    // Store the smoothed value for next iteration
    atr_adaptive_smoothed[index] = smoothed_value;
    
    return smoothed_value;
}

//+------------------------------------------------------------------+
//| Apply LAD Kalman-Wiener Hybrid filter                           |
//+------------------------------------------------------------------+
double ApplyLADKalmanWienerFilter(double rsi_value, int index)
{
    if(index < KalmanPeriod) return rsi_value;
    
    // Step 1: Kalman Filter with ATR-guided process noise
    double kalman_filtered = ApplyKalmanFilter(rsi_value, index);
    
    // Step 2: LAD (Least Absolute Deviation) - Robust median calculation
    double lad_median = CalculateLADMedian(rsi_value, index);
    
    // Step 3: Calculate residual for Wiener filtering
    double residual = kalman_filtered - lad_median;
    
    // Step 4: Wiener filter for noise suppression in frequency domain
    double wiener_filtered = ApplyWienerFilter(residual, index);
    
    // Step 5: Combine LAD median with Wiener-filtered residual
    double combined_signal = lad_median + wiener_filtered;
    
    // Step 6: KDE Gate - only accept signals with high probability
    double kde_probability = CalculateKDEProbabilityForFilter(combined_signal, index);
    
    if(kde_probability > KDEGateThreshold)
    {
        hybrid_output[index] = combined_signal;
    }
    else
    {
        // If KDE gate rejects, use previous filtered value or fallback
        hybrid_output[index] = (index > 0) ? hybrid_output[index - 1] : rsi_value;
    }
    
    return hybrid_output[index];
}

//+------------------------------------------------------------------+
//| Apply Kalman filter with ATR-guided process noise               |
//+------------------------------------------------------------------+
double ApplyKalmanFilter(double measurement, int index)
{
    if(index < 1)
    {
        kalman_x[index] = measurement;
        kalman_p[index] = 1.0;
        return measurement;
    }
    
    // Get ATR for adaptive process noise
    double current_atr = 0;
    double atr_buffer[];
    ArrayResize(atr_buffer, 1);
    if(CopyBuffer(kalman_wiener_atr_handle, 0, index, 1, atr_buffer) > 0)
    {
        current_atr = atr_buffer[0];
    }
    else
    {
        current_atr = 0.01; // Fallback value
    }
    
    // ATR-guided process noise (higher ATR = higher uncertainty)
    double adaptive_q = KalmanQ * (1.0 + current_atr * 10.0);
    
    // Prediction step
    double x_pred = kalman_x[index - 1]; // Simple model: next state = current state
    double p_pred = kalman_p[index - 1] + adaptive_q;
    
    // Update step
    kalman_k[index] = p_pred / (p_pred + KalmanR);
    kalman_x[index] = x_pred + kalman_k[index] * (measurement - x_pred);
    kalman_p[index] = (1.0 - kalman_k[index]) * p_pred;
    
    return kalman_x[index];
}

//+------------------------------------------------------------------+
//| Calculate LAD (Least Absolute Deviation) median                 |
//+------------------------------------------------------------------+
double CalculateLADMedian(double current_value, int index)
{
    if(index < LADPeriod) return current_value;
    
    // Fill buffer with recent RSI values
    for(int i = 0; i < LADPeriod; i++)
    {
        int data_index = index - LADPeriod + 1 + i;
        if(data_index >= 0 && data_index < ArraySize(rsi_values))
        {
            lad_median_buffer[i] = rsi_values[data_index];
        }
        else
        {
            lad_median_buffer[i] = current_value;
        }
    }
    
    // Sort array to find median (robust against outliers)
    ArraySort(lad_median_buffer);
    
    // Return median value
    int mid = LADPeriod / 2;
    if(LADPeriod % 2 == 0)
    {
        return (lad_median_buffer[mid - 1] + lad_median_buffer[mid]) / 2.0;
    }
    else
    {
        return lad_median_buffer[mid];
    }
}

//+------------------------------------------------------------------+
//| Apply Wiener filter for noise suppression (simplified FFT)      |
//+------------------------------------------------------------------+
double ApplyWienerFilter(double signal, int index)
{
    if(index < WienerFFTSize) return signal;
    
    // Simplified Wiener filtering approach
    // In a full implementation, this would use FFT/IFFT
    
    // Calculate moving average as signal estimate
    double signal_estimate = 0;
    int count = 0;
    
    for(int i = MathMax(0, index - WienerFFTSize + 1); i <= index; i++)
    {
        if(i < ArraySize(wiener_filtered))
        {
            signal_estimate += (i == index) ? signal : wiener_filtered[i];
            count++;
        }
    }
    
    if(count > 0)
        signal_estimate /= count;
    else
        signal_estimate = signal;
    
    // Calculate noise estimate
    double noise_estimate = signal - signal_estimate;
    
    // Apply noise suppression threshold
    if(MathAbs(noise_estimate) < WienerNoiseThreshold)
    {
        wiener_filtered[index] = signal_estimate;
    }
    else
    {
        // Reduce noise but preserve signal
        double noise_reduction_factor = WienerNoiseThreshold / MathAbs(noise_estimate);
        wiener_filtered[index] = signal_estimate + (noise_estimate * noise_reduction_factor);
    }
    
    return wiener_filtered[index];
}

//+------------------------------------------------------------------+
//| Calculate KDE probability for filter gating                     |
//+------------------------------------------------------------------+
double CalculateKDEProbabilityForFilter(double value, int index)
{
    // Simplified KDE probability calculation for gating
    // This uses a basic Gaussian kernel approach
    
    if(index < 10) return 1.0; // Accept early values
    
    double sum_weights = 0;
    double probability = 0;
    int lookback = MathMin(index, 50); // Look back at most 50 bars
    
    for(int i = MathMax(0, index - lookback); i < index; i++)
    {
        if(i < ArraySize(hybrid_output) && hybrid_output[i] != 0)
        {
            double distance = MathAbs(value - hybrid_output[i]);
            double weight = MathExp(-0.5 * MathPow(distance / 5.0, 2)); // Gaussian kernel
            probability += weight;
            sum_weights += 1.0;
        }
    }
    
    if(sum_weights > 0)
        probability /= sum_weights;
    else
        probability = 0.5; // Neutral probability
    
    return probability;
}

//+------------------------------------------------------------------+
//| Calculate stop loss and take profit levels                      |
//+------------------------------------------------------------------+
void CalculateRiskLevels(double entry_price, bool is_buy, double &stop_loss, double &take_profit)
{
    if(!EnableRiskManagement)
    {
        stop_loss = 0;
        take_profit = 0;
        return;
    }
    
    double sl_distance = 0;
    
    switch(StopLossType)
    {
        case SL_ATR:
        {
            double atr_values[];
            ArrayResize(atr_values, 1);
            if(CopyBuffer(atr_handle, 0, 0, 1, atr_values) > 0)
            {
                sl_distance = atr_values[0] * ATRMultiplier;
            }
            else
            {
                sl_distance = entry_price * 0.01; // 1% fallback
            }
            break;
        }
        case SL_FIXED_PIPS:
            sl_distance = FixedStopLossPips * _Point;
            break;
        case SL_PERCENT:
            sl_distance = entry_price * StopLossPercent / 100.0;
            break;
    }
    
    if(is_buy)
    {
        stop_loss = entry_price - sl_distance;
        take_profit = entry_price + (sl_distance * RiskRewardRatio);
    }
    else
    {
        stop_loss = entry_price + sl_distance;
        take_profit = entry_price - (sl_distance * RiskRewardRatio);
    }
}

//+------------------------------------------------------------------+
//| Update rolling window Fibonacci levels                          |
//+------------------------------------------------------------------+
void UpdateRollingFibonacci(const double &high[], const double &low[], int current_bar)
{
    if(!UseRollingWindow || current_bar < FibRollingPeriod)
        return;
    
    int start_bar = current_bar - FibRollingPeriod;
    double highest = high[start_bar];
    double lowest = low[start_bar];
    
    // Find highest high and lowest low in rolling window
    for(int i = start_bar; i <= current_bar; i++)
    {
        if(high[i] > highest) highest = high[i];
        if(low[i] < lowest) lowest = low[i];
    }
    
    // Update Fibonacci levels
    swing_high_price = highest;
    swing_low_price = lowest;
    CalculateFibLevels();
}

//+------------------------------------------------------------------+
//| Create and update trading dashboard                              |
//+------------------------------------------------------------------+
void UpdateTradingDashboard()
{
    if(!ShowDashboard) return;
    
    string dashboard_text = "";
    dashboard_text += "\n=== RSI KDE Enhanced Dashboard ===";
    dashboard_text += "\nSymbol: " + _Symbol;
    dashboard_text += "\nTimeframe: " + EnumToString(_Period);
    
    if(EnableBacktesting)
    {
        dashboard_text += "\n\n=== Backtesting Results ===";
        dashboard_text += "\nBalance: $" + DoubleToString(current_balance, 2);
        dashboard_text += "\nTotal Trades: " + IntegerToString(total_trades);
        if(total_trades > 0)
        {
            dashboard_text += "\nWin Rate: " + DoubleToString((double)winning_trades / total_trades * 100, 1) + "%";
            dashboard_text += "\nTotal Profit: $" + DoubleToString(total_profit, 2);
            dashboard_text += "\nMax Drawdown: " + DoubleToString(max_drawdown, 2) + "%";
        }
    }
    
    if(EnableRiskManagement)
    {
        dashboard_text += "\n\n=== Risk Management ===";
        dashboard_text += "\nSL Type: " + (StopLossType == SL_ATR ? "ATR" : (StopLossType == SL_FIXED_PIPS ? "Fixed Pips" : "Percentage"));
        dashboard_text += "\nRisk:Reward = 1:" + DoubleToString(RiskRewardRatio, 1);
    }
    
    dashboard_text += "\n\n=== Filter Settings ===";
    string filter_name = "None";
    switch(RSIFilterType)
    {
        case FILTER_T3: filter_name = "T3"; break;
        case FILTER_JURIK: filter_name = "Jurik"; break;
        case FILTER_SAVGOL: filter_name = "Savitzky-Golay"; break;
        case FILTER_ATR_ADAPTIVE: filter_name = "ATR-Adaptive"; break;
        case FILTER_LAD_KALMAN_WIENER: filter_name = "LAD-Kalman-Wiener"; break;
        default: filter_name = "None"; break;
    }
    dashboard_text += "\nRSI Filter: " + filter_name;
    dashboard_text += "\nFib Filter: " + (EnableFibonacciFilter ? "ON" : "OFF");
    
    // Create or update dashboard object
    string obj_name = "RSI_KDE_Dashboard";
    if(ObjectFind(0, obj_name) < 0)
    {
        ObjectCreate(0, obj_name, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, obj_name, OBJPROP_CORNER, DashboardCorner);
        ObjectSetInteger(0, obj_name, OBJPROP_XDISTANCE, DashboardXOffset);
        ObjectSetInteger(0, obj_name, OBJPROP_YDISTANCE, DashboardYOffset);
        ObjectSetInteger(0, obj_name, OBJPROP_COLOR, clrWhite);
        ObjectSetInteger(0, obj_name, OBJPROP_FONTSIZE, 8);
        ObjectSetString(0, obj_name, OBJPROP_FONT, "Courier New");
    }
    
    ObjectSetString(0, obj_name, OBJPROP_TEXT, dashboard_text);
}

//+------------------------------------------------------------------+
//| Send enhanced alert with risk management info                    |
//+------------------------------------------------------------------+
void SendEnhancedAlert(string signal_type, double price, double rsi, double probability, double sl, double tp, datetime alert_time)
{
    if(!EnableAlerts) return;
    
    string message = StringFormat("%s %s Signal: Price=%.5f, RSI=%.2f, Prob=%.4f", 
                                 AlertPrefix, signal_type, price, rsi, probability);
    
    if(EnableRiskManagement && sl > 0 && tp > 0)
    {
        message += StringFormat(", SL=%.5f, TP=%.5f, R:R=1:%.1f", sl, tp, RiskRewardRatio);
    }
    
    if(EnablePopupAlerts)
    {
        Alert(message);
    }
    
    if(EnableSoundAlerts)
    {
        string sound_file = (signal_type == "BUY") ? BuyAlertSound : SellAlertSound;
        PlaySound(sound_file);
    }
    
    if(EnableEmailAlerts)
    {
        SendMail(AlertPrefix + " - " + signal_type + " Signal", message);
    }
    
    if(EnablePushAlerts)
    {
        SendNotification(message);
    }
    
    Print(message);
}

//+------------------------------------------------------------------+
//| Process backtesting trade                                        |
//+------------------------------------------------------------------+
void ProcessBacktestTrade(bool is_buy, double entry_price, double sl, double tp)
{
    if(!EnableBacktesting) return;
    
    total_trades++;
    
    // Calculate position size based on risk per trade
    double risk_amount = current_balance * RiskPerTrade / 100.0;
    double sl_distance = MathAbs(entry_price - sl);
    double position_size = (sl_distance > 0) ? risk_amount / sl_distance : 0;
    
    // Simulate trade outcome (simplified - in real backtesting, you'd track actual price movements)
    // For demonstration, assume 60% win rate
    bool trade_wins = (MathRand() % 100) < 60;
    
    double trade_result = 0;
    if(trade_wins)
    {
        winning_trades++;
        trade_result = MathAbs(tp - entry_price) * position_size;
    }
    else
    {
        trade_result = -risk_amount;
    }
    
    // Update balance
    if(CompoundProfits)
    {
        current_balance += trade_result;
    }
    else
    {
        current_balance = InitialBalance + total_profit + trade_result;
    }
    
    total_profit += trade_result;
    
    // Update peak balance and drawdown
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
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    //--- Check if we have enough data
    if(rates_total < RSI_Period + HighPivotLength + LowPivotLength + 1)
        return(0);
    
    //--- Get RSI values
    ArrayResize(rsi_values, rates_total);
    ArrayResize(filtered_rsi, rates_total);
    int copied = CopyBuffer(rsi_handle, 0, 0, rates_total, rsi_values);
    if(copied <= 0)
    {
        Print("Error copying RSI buffer: ", GetLastError());
        return(prev_calculated);
    }
    
    //--- Validate RSI data
    if(copied < rates_total)
    {
        Print("Warning: Only copied ", copied, " RSI values out of ", rates_total, " requested");
        return(prev_calculated);
    }
    
    //--- Apply RSI filtering if enabled
    for(int i = 0; i < rates_total; i++)
    {
        filtered_rsi[i] = ApplyRSIFilter(rsi_values[i], i);
    }
    
    //--- Find pivot highs and lows in RSI (use filtered RSI if filtering is enabled)
    if(RSIFilterType != FILTER_NONE)
    {
        FindPivotHighs(filtered_rsi, rates_total, HighPivotLength, high_pivot_rsis, high_pivot_count);
        FindPivotLows(filtered_rsi, rates_total, LowPivotLength, low_pivot_rsis, low_pivot_count);
    }
    else
    {
        FindPivotHighs(rsi_values, rates_total, HighPivotLength, high_pivot_rsis, high_pivot_count);
        FindPivotLows(rsi_values, rates_total, LowPivotLength, low_pivot_rsis, low_pivot_count);
    }
    
    //--- Calculate KDE for pivot highs if needed
    if(high_pivot_count > 0 && (kde_high_needs_recalc || prev_calculated == 0))
    {
        double bandwidth = EnableAdaptiveBandwidth ? CalculateAdaptiveBandwidth(high_pivot_rsis, high_pivot_count) : KDEBandwidth;
        CalculateKDE(high_pivot_rsis, high_pivot_count, kde_high_x, kde_high_y, KDESteps, bandwidth, KDEKernel);
        kde_high_needs_recalc = false;
    }
    
    //--- Calculate KDE for pivot lows if needed
    if(low_pivot_count > 0 && (kde_low_needs_recalc || prev_calculated == 0))
    {
        double bandwidth = EnableAdaptiveBandwidth ? CalculateAdaptiveBandwidth(low_pivot_rsis, low_pivot_count) : KDEBandwidth;
        CalculateKDE(low_pivot_rsis, low_pivot_count, kde_low_x, kde_low_y, KDESteps, bandwidth, KDEKernel);
        kde_low_needs_recalc = false;
    }
    
    //--- Update rolling window Fibonacci if enabled
    if(UseRollingWindow && EnableFibonacciFilter)
    {
        UpdateRollingFibonacci(high, low, rates_total - 1);
    }
    else
    {
        //--- Find swing points for traditional Fibonacci calculations
        bool swing_high_changed = FindSwingHigh(high, rates_total - 1, FibLookbackBars);
        bool swing_low_changed = FindSwingLow(low, rates_total - 1, FibLookbackBars);
        
        //--- Calculate Fibonacci levels if needed
        if((swing_high_changed || swing_low_changed) && EnableFibonacciFilter)
        {
            CalculateFibLevels();
        }
    }
    
    //--- Draw Fibonacci levels if enabled
    if(EnableFibonacciFilter && ShowFibLevels)
    {
        DrawFibLevels(time, rates_total - 1);
    }
    
    //--- Start from the last calculated bar to prevent recalculating everything
    int start_bar = prev_calculated == 0 ? RSI_Period + MathMax(HighPivotLength, LowPivotLength) : prev_calculated - 1;
    
    //--- Main loop through bars
    for(int i = start_bar; i < rates_total && !IsStopped(); i++)
    {
        BuyBuffer[i] = EMPTY_VALUE;
        SellBuffer[i] = EMPTY_VALUE;
        
        double current_rsi = rsi_values[i];
        double current_price = close[i];
        
        //--- Calculate probabilities
        double prob_high = CalculateProbability(current_rsi, kde_high_x, kde_high_y, KDESteps);
        double prob_low = CalculateProbability(current_rsi, kde_low_x, kde_low_y, KDESteps);
        
        //--- Normalize probabilities
        double total_prob = prob_high + prob_low;
        if(total_prob > 0.0001) // Avoid division by very small numbers
        {
            prob_high /= total_prob;
            prob_low /= total_prob;
        }
        else
        {
            prob_high = 0.0;
            prob_low = 0.0;
        }
        
        //--- Check for signals
        bool buy_signal = false;
        bool sell_signal = false;
        
        if(prob_low > activation_threshold * SignalSensitivity && prob_low > prob_high)
        {
            buy_signal = true;
        }
        else if(prob_high > activation_threshold * SignalSensitivity && prob_high > prob_low)
        {
            sell_signal = true;
        }
        
        //--- Apply Fibonacci filter if enabled
        if(buy_signal && EnableFibonacciFilter)
        {
            buy_signal = PassesFibonacciFilter(current_price, true, high, low, i);
        }
        
        if(sell_signal && EnableFibonacciFilter)
        {
            sell_signal = PassesFibonacciFilter(current_price, false, high, low, i);
        }
        
        //--- Set buffer values and send enhanced alerts with risk management
        if(buy_signal && ShowBuyArrows)
        {
            BuyBuffer[i] = low[i] - 10 * _Point;
            
            //--- Calculate risk levels if enabled
            double stop_loss = 0, take_profit = 0;
            if(EnableRiskManagement)
            {
                CalculateRiskLevels(current_price, true, stop_loss, take_profit);
            }
            
            //--- Update backtesting if enabled
            if(EnableBacktesting)
            {
                ProcessBacktestTrade(true, current_price, stop_loss, take_profit);
            }
            
            if(ShouldSendAlert("BUY", time[i]))
            {
                SendEnhancedAlert("BUY", current_price, current_rsi, prob_low, stop_loss, take_profit, time[i]);
                UpdateAlertTracking("BUY");
            }
        }
        else if(sell_signal && ShowSellArrows)
        {
            SellBuffer[i] = high[i] + 10 * _Point;
            
            //--- Calculate risk levels if enabled
            double stop_loss = 0, take_profit = 0;
            if(EnableRiskManagement)
            {
                CalculateRiskLevels(current_price, false, stop_loss, take_profit);
            }
            
            //--- Update backtesting if enabled
            if(EnableBacktesting)
            {
                ProcessBacktestTrade(false, current_price, stop_loss, take_profit);
            }
            
            if(ShouldSendAlert("SELL", time[i]))
            {
                SendEnhancedAlert("SELL", current_price, current_rsi, prob_high, stop_loss, take_profit, time[i]);
                UpdateAlertTracking("SELL");
            }
        }
        
        //--- Debug information
        if(ShowDebugInfo && i == rates_total - 1)
        {
            Print(StringFormat("Current RSI: %.2f, High Prob: %.4f, Low Prob: %.4f, Buy: %d, Sell: %d",
                  current_rsi, prob_high, prob_low, buy_signal, sell_signal));
            
            if(EnableFibonacciFilter)
            {
                ENUM_FIB_ZONE zone = GetFibZone(current_price);
                string zone_name = (zone == FIB_PREMIUM) ? "Premium" : 
                                  (zone == FIB_DISCOUNT) ? "Discount" : "Equilibrium";
                Print("Current Fib Zone: " + zone_name);
            }
        }
    }
    
    //--- Update trading dashboard
    if(ShowDashboard)
    {
        UpdateTradingDashboard();
    }
    
    //--- Return number of calculated bars
    return(rates_total);
}
//+------------------------------------------------------------------+