//+------------------------------------------------------------------+
//|                                   OrderBlock_Trading_EA.mq5     |
//|                        Copyright 2024, ELIJAH EKPEN MENSAH®     |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "ELIJAH EKPEN MENSAH®"
#property link      "https://www.mql5.com"
#property version   "1.01"
#property description "Order Block Trading Expert Advisor - Uses Order Block Indicator Buffers with Customizable Risk-Reward"

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

//--- Order Block Filter Types
enum ENUM_OB_FILTER_TYPE
{
   FILTER_NONE = 0,     // No Filter
   FILTER_EMA = 1,      // EMA Filter
   FILTER_VWAP = 2      // VWAP Filter
};

//--- Risk-Reward Calculation Methods
enum ENUM_RR_CALC_METHOD
{
   RR_FIXED_RATIO = 0,      // Fixed Risk-Reward Ratio
   RR_OB_LEVELS = 1,        // Based on Order Block Levels
   RR_ATR_MULTIPLE = 2      // ATR Multiple Based
};

//--- Magic number
#define EA_MAGIC_BASE 54321

//=== Indicator Import Settings ===
input group "=== Order Block Indicator Settings ==="
input string IndicatorName = "OrderBlockIndicator";        // Indicator Name (without .ex5)
input int InpPeriods = 5;                                 // Relevant Periods to identify OB
input double InpThreshold = 0.0;                          // Min. Percent move to identify OB
input bool InpUseWicks = false;                           // Use whole range [High/Low] for OB marking
input bool InpShowBullish = true;                         // Show Bullish Order Blocks
input bool InpShowBearish = true;                         // Show Bearish Order Blocks
input bool InpShowArrows = false;                         // Show Buy/Sell Arrows (Set to false for EA)

//=== Filter Settings ===
input group "=== Order Block Filter Settings ==="
input ENUM_OB_FILTER_TYPE InpFilterType = FILTER_EMA;     // Filter Type
input int InpEMA_Period = 50;                             // EMA Period (if EMA filter selected)

//=== Color Settings ===
input group "=== Color Settings ==="
input color InpBullishColor = clrLime;                    // Bullish Order Block Color
input color InpBearishColor = clrRed;                     // Bearish Order Block Color

//=== Arrow Settings ===
input group "=== Arrow Settings ==="
input int InpBuyArrowCode = 233;                          // Buy Arrow Symbol Code
input int InpSellArrowCode = 234;                         // Sell Arrow Symbol Code
input double InpArrowOffset = 0.2;                        // Arrow Offset (% of candle range)

//=== Trading Parameters ===
input group "=== Trading Settings ==="
input bool EnableTrading = true;                          // Enable Automated Trading
input ENUM_LOT_SIZING LotSizingMethod = LOT_FIXED;        // Position Sizing Method
input double FixedLotSize = 0.01;                        // Fixed Lot Size
input double RiskPercent = 2.0;                          // Risk Percentage of Balance
input double BalancePercent = 1.0;                       // Balance Percentage per Trade

//=== Risk-Reward Settings ===
input group "=== Risk-Reward Management ==="
input ENUM_RR_CALC_METHOD RiskRewardMethod = RR_FIXED_RATIO; // Risk-Reward Calculation Method
input double RiskRewardRatio = 2.0;                      // Risk-Reward Ratio (1:X)
input double MinRiskRewardRatio = 1.5;                   // Minimum Acceptable Risk-Reward Ratio
input double MaxRiskRewardRatio = 5.0;                   // Maximum Risk-Reward Ratio
input int StopLossPips = 100;                            // Stop Loss (Pips) - Used when not using OB levels
input int TakeProfitPips = 200;                          // Take Profit (Pips) - Used when not using OB levels
input int ATR_Period = 14;                               // ATR Period for RR calculation
input double ATR_SL_Multiplier = 1.5;                    // ATR Multiplier for Stop Loss
input double ATR_TP_Multiplier = 3.0;                    // ATR Multiplier for Take Profit
input double OB_Buffer_Pips = 5.0;                       // Buffer (Pips) above/below OB levels
input bool UseBreakevenStop = false;                     // Move SL to breakeven when TP is 50% hit
input bool UsePartialTakeProfit = false;                 // Close partial position at intermediate levels
input double PartialTPPercent = 50.0;                    // Percentage of position to close at first TP
input double PartialTPRatio = 1.0;                       // Risk-Reward ratio for partial TP

//=== Advanced SL/TP Settings ===
input group "=== Advanced Stop Loss & Take Profit ==="
input bool UseTrailingStop = false;                      // Use Trailing Stop
input int TrailingStopPips = 50;                         // Trailing Stop Distance (Pips)
input int TrailingStepPips = 10;                         // Trailing Step (Pips)
input bool TrailOnlyInProfit = true;                     // Trail only when position is in profit
input bool UseOrderBlockSLTP = true;                     // Use Order Block Levels for SL/TP
input bool UseDynamicSLTP = true;                        // Dynamically adjust SL/TP based on market conditions

//=== Position Management ===
input group "=== Position Management Settings ==="
input bool EnablePositionStacking = false;               // Enable Position Stacking
input int MaxStackedPositions = 3;                       // Maximum Stacked Positions
input double StackingSizeMultiplier = 1.0;               // Size Multiplier for Stacked Positions
input int MinPipsBetweenStacks = 50;                     // Minimum Pips Between Stacked Positions
input bool CloseAllOnOppositeSignal = true;              // Close All Positions on Opposite Signal

//=== Time Filter ===
input group "=== Time Filter Settings ==="
input bool EnableTimeFilter = false;                     // Enable Time Filter
input int StartHour = 8;                                 // Trading Start Hour
input int EndHour = 18;                                  // Trading End Hour
input bool MondayTrading = true;                         // Trade on Monday
input bool TuesdayTrading = true;                        // Trade on Tuesday
input bool WednesdayTrading = true;                      // Trade on Wednesday
input bool ThursdayTrading = true;                       // Trade on Thursday
input bool FridayTrading = true;                         // Trade on Friday

//=== Alert Settings ===
input group "=== Alert Settings ==="
input bool EnableAlerts = true;                          // Enable Alerts
input bool EnablePopupAlerts = true;                     // Enable Popup Alerts
input bool EnableSoundAlerts = true;                     // Enable Sound Alerts
input bool EnableEmailAlerts = false;                    // Enable Email Alerts
input bool EnablePushAlerts = false;                     // Enable Push Notifications
input string BuyAlertSound = "alert.wav";                // Buy Alert Sound File
input string SellAlertSound = "alert2.wav";              // Sell Alert Sound File
input string AlertPrefix = "OrderBlock_EA";              // Alert Message Prefix

//=== Dashboard Settings ===
input group "=== Dashboard Settings ==="
input bool ShowDashboard = true;                         // Show Trading Dashboard
input int DashboardCorner = 1;                           // Dashboard Corner (0-3)
input int DashboardXOffset = 20;                         // Dashboard X Offset
input int DashboardYOffset = 50;                         // Dashboard Y Offset
input bool ShowDebugInfo = false;                        // Show Debug Information

//--- Global variables
int indicator_handle = INVALID_HANDLE;
int atr_handle = INVALID_HANDLE;

//--- Indicator buffers - mapping to the 6 buffers from OrderBlockIndicator
double bullish_ob_high[];    // Buffer 0: Bullish OB High
double bullish_ob_low[];     // Buffer 1: Bullish OB Low  
double bearish_ob_high[];    // Buffer 2: Bearish OB High
double bearish_ob_low[];     // Buffer 3: Bearish OB Low
double buy_arrow[];          // Buffer 4: Buy Arrow
double sell_arrow[];         // Buffer 5: Sell Arrow

//--- ATR buffer
double atr_buffer[];

//--- Trading variables
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
datetime last_bar_time = 0;

//--- Order Block levels for dynamic SL/TP
double current_bullish_ob_high = 0;
double current_bullish_ob_low = 0;
double current_bearish_ob_high = 0;
double current_bearish_ob_low = 0;

//--- Risk-Reward tracking
double average_rr_ratio = 0;
int rr_trade_count = 0;

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
    
    if(RiskRewardRatio <= 0)
    {
        Print("Error: Risk-Reward ratio must be positive");
        return(INIT_PARAMETERS_INCORRECT);
    }
    
    if(MinRiskRewardRatio <= 0 || MinRiskRewardRatio > MaxRiskRewardRatio)
    {
        Print("Error: Invalid Risk-Reward ratio range");
        return(INIT_PARAMETERS_INCORRECT);
    }
    
    if(MaxStackedPositions < 1 || MaxStackedPositions > 10)
    {
        Print("Error: Max stacked positions must be between 1 and 10");
        return(INIT_PARAMETERS_INCORRECT);
    }
    
    if(PartialTPPercent <= 0 || PartialTPPercent >= 100)
    {
        Print("Error: Partial TP percentage must be between 0 and 100");
        return(INIT_PARAMETERS_INCORRECT);
    }
    
    //--- Create indicator handle with parameters
    indicator_handle = iCustom(_Symbol, _Period, IndicatorName,
                              InpPeriods,           // Relevant Periods to identify OB
                              InpThreshold,         // Min. Percent move to identify OB
                              InpUseWicks,          // Use whole range for OB marking
                              InpShowBullish,       // Show Bullish Order Blocks
                              InpShowBearish,       // Show Bearish Order Blocks
                              InpShowArrows,        // Show Buy/Sell Arrows (false for EA)
                              InpFilterType,        // Filter Type
                              InpEMA_Period,        // EMA Period
                              InpBullishColor,      // Bullish Order Block Color
                              InpBearishColor,      // Bearish Order Block Color
                              InpBuyArrowCode,      // Buy Arrow Symbol Code
                              InpSellArrowCode,     // Sell Arrow Symbol Code
                              InpArrowOffset        // Arrow Offset
                              );
    
    if(indicator_handle == INVALID_HANDLE)
    {
        Print("Error: Failed to create indicator handle. Make sure '", IndicatorName, "' indicator is compiled and available.");
        return(INIT_FAILED);
    }
    
    //--- Create ATR handle for risk-reward calculations
    atr_handle = iATR(_Symbol, _Period, ATR_Period);
    if(atr_handle == INVALID_HANDLE)
    {
        Print("Error: Failed to create ATR indicator handle");
        return(INIT_FAILED);
    }
    
    //--- Setup trading
    trade.SetExpertMagicNumber(EA_MAGIC_BASE);
    trade.SetMarginMode();
    trade.SetTypeFillingBySymbol(_Symbol);
    
    //--- Initialize arrays
    ArrayResize(bullish_ob_high, 100);
    ArrayResize(bullish_ob_low, 100);
    ArrayResize(bearish_ob_high, 100);
    ArrayResize(bearish_ob_low, 100);
    ArrayResize(buy_arrow, 100);
    ArrayResize(sell_arrow, 100);
    ArrayResize(atr_buffer, 100);
    
    ArraySetAsSeries(bullish_ob_high, true);
    ArraySetAsSeries(bullish_ob_low, true);
    ArraySetAsSeries(bearish_ob_high, true);
    ArraySetAsSeries(bearish_ob_low, true);
    ArraySetAsSeries(buy_arrow, true);
    ArraySetAsSeries(sell_arrow, true);
    ArraySetAsSeries(atr_buffer, true);
    
    //--- Initialize trading variables
    current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    peak_balance = current_balance;
    last_bar_time = 0;
    
    //--- Wait for indicators to initialize
    Sleep(1000);
    
    //--- Print initialization info
    Print("=== Order Block Trading EA v1.01 Initialized Successfully ===");
    Print("Indicator: ", IndicatorName);
    Print("Symbol: ", _Symbol, ", Timeframe: ", EnumToString(_Period));
    Print("Trading Enabled: ", EnableTrading ? "YES" : "NO");
    Print("Risk-Reward Method: ", RiskRewardMethod == RR_FIXED_RATIO ? "Fixed Ratio" : 
                                   RiskRewardMethod == RR_OB_LEVELS ? "OB Levels" : "ATR Multiple");
    Print("Risk-Reward Ratio: 1:", DoubleToString(RiskRewardRatio, 2));
    Print("Min/Max RR Ratio: ", DoubleToString(MinRiskRewardRatio, 2), "/", DoubleToString(MaxRiskRewardRatio, 2));
    Print("Use OB Levels for SL/TP: ", UseOrderBlockSLTP ? "YES" : "NO");
    Print("Use Partial TP: ", UsePartialTakeProfit ? "YES (" + DoubleToString(PartialTPPercent, 1) + "%)" : "NO");
    Print("Use Breakeven: ", UseBreakevenStop ? "YES" : "NO");
    Print("============================================================");
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    //--- Release indicator handles
    if(indicator_handle != INVALID_HANDLE)
        IndicatorRelease(indicator_handle);
    if(atr_handle != INVALID_HANDLE)
        IndicatorRelease(atr_handle);
    
    //--- Clean up dashboard objects
    if(ShowDashboard)
    {
        ObjectDelete(0, "OrderBlock_EA_Dashboard");
    }
    
    //--- Print final statistics
    Print("=== Order Block EA Performance Summary ===");
    Print("Total Trades: ", total_trades);
    Print("Win Rate: ", total_trades > 0 ? DoubleToString((double)winning_trades/total_trades*100, 2) : "0", "%");
    Print("Average R:R Ratio: ", rr_trade_count > 0 ? DoubleToString(average_rr_ratio/rr_trade_count, 2) : "N/A");
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
//| Calculate dynamic risk-reward based Stop Loss and Take Profit   |
//+------------------------------------------------------------------+
bool CalculateAdvancedStopLossAndTakeProfit(double entry_price, bool is_buy, double &sl, double &tp, double &actual_rr_ratio)
{
    sl = 0;
    tp = 0;
    actual_rr_ratio = RiskRewardRatio;
    
    double atr_value = 0;
    if(RiskRewardMethod == RR_ATR_MULTIPLE)
    {
        if(CopyBuffer(atr_handle, 0, 1, 1, atr_buffer) <= 0)
        {
            Print("Error: Cannot get ATR value");
            return false;
        }
        atr_value = atr_buffer[0];
        if(atr_value <= 0)
        {
            Print("Error: Invalid ATR value");
            return false;
        }
    }
    
    switch(RiskRewardMethod)
    {
        case RR_FIXED_RATIO:
        {
            if(UseOrderBlockSLTP && ((is_buy && current_bullish_ob_low > 0) || (!is_buy && current_bearish_ob_high > 0)))
            {
                //--- Use Order Block levels with fixed ratio
                double buffer = OB_Buffer_Pips * _Point * 10;
                
                if(is_buy)
                {
                    sl = current_bullish_ob_low - buffer;
                    double sl_distance = entry_price - sl;
                    tp = entry_price + (sl_distance * RiskRewardRatio);
                }
                else
                {
                    sl = current_bearish_ob_high + buffer;
                    double sl_distance = sl - entry_price;
                    tp = entry_price - (sl_distance * RiskRewardRatio);
                }
            }
            else
            {
                //--- Use pip-based SL/TP with fixed ratio
                double sl_distance = StopLossPips * _Point * 10;
                
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
            break;
        }
        
        case RR_OB_LEVELS:
        {
            if((is_buy && current_bullish_ob_low > 0) || (!is_buy && current_bearish_ob_high > 0))
            {
                double buffer = OB_Buffer_Pips * _Point * 10;
                
                if(is_buy)
                {
                    sl = current_bullish_ob_low - buffer;
                    double sl_distance = entry_price - sl;
                    
                    //--- Calculate TP based on available OB levels or use dynamic ratio
                    if(current_bearish_ob_low > entry_price)
                    {
                        tp = current_bearish_ob_low - buffer;
                        actual_rr_ratio = (tp - entry_price) / sl_distance;
                    }
                    else
                    {
                        tp = entry_price + (sl_distance * RiskRewardRatio);
                        actual_rr_ratio = RiskRewardRatio;
                    }
                }
                else
                {
                    sl = current_bearish_ob_high + buffer;
                    double sl_distance = sl - entry_price;
                    
                    //--- Calculate TP based on available OB levels or use dynamic ratio
                    if(current_bullish_ob_high < entry_price)
                    {
                        tp = current_bullish_ob_high + buffer;
                        actual_rr_ratio = (entry_price - tp) / sl_distance;
                    }
                    else
                    {
                        tp = entry_price - (sl_distance * RiskRewardRatio);
                        actual_rr_ratio = RiskRewardRatio;
                    }
                }
            }
            else
            {
                //--- Fallback to fixed ratio method
                return CalculateAdvancedStopLossAndTakeProfit(entry_price, is_buy, sl, tp, actual_rr_ratio);
            }
            break;
        }
        
        case RR_ATR_MULTIPLE:
        {
            if(is_buy)
            {
                sl = entry_price - (atr_value * ATR_SL_Multiplier);
                tp = entry_price + (atr_value * ATR_TP_Multiplier);
                actual_rr_ratio = ATR_TP_Multiplier / ATR_SL_Multiplier;
            }
            else
            {
                sl = entry_price + (atr_value * ATR_SL_Multiplier);
                tp = entry_price - (atr_value * ATR_TP_Multiplier);
                actual_rr_ratio = ATR_TP_Multiplier / ATR_SL_Multiplier;
            }
            break;
        }
    }
    
    //--- Validate risk-reward ratio
    if(actual_rr_ratio < MinRiskRewardRatio)
    {
        Print("Risk-reward ratio too low: ", DoubleToString(actual_rr_ratio, 2), " (min: ", DoubleToString(MinRiskRewardRatio, 2), ")");
        return false;
    }
    
    if(actual_rr_ratio > MaxRiskRewardRatio)
    {
        //--- Cap the TP if RR is too high
        double sl_distance = is_buy ? (entry_price - sl) : (sl - entry_price);
        if(is_buy)
            tp = entry_price + (sl_distance * MaxRiskRewardRatio);
        else
            tp = entry_price - (sl_distance * MaxRiskRewardRatio);
        actual_rr_ratio = MaxRiskRewardRatio;
        
        Print("Risk-reward ratio capped to maximum: ", DoubleToString(MaxRiskRewardRatio, 2));
    }
    
    //--- Normalize prices
    sl = NormalizeDouble(sl, _Digits);
    tp = NormalizeDouble(tp, _Digits);
    
    return true;
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
//| Execute buy trade with advanced risk management                  |
//+------------------------------------------------------------------+
void ExecuteBuyTrade(double current_price)
{
    if(!EnableTrading) return;
    
    //--- Check filters
    if(!IsTimeFilterOK())
        return;
    
    //--- Check stacking rules
    if(!IsStackingAllowed(true, current_price))
        return;
    
    //--- Calculate advanced stop loss and take profit
    double sl, tp, actual_rr_ratio;
    if(!CalculateAdvancedStopLossAndTakeProfit(current_price, true, sl, tp, actual_rr_ratio))
    {
        Print("Skipping BUY trade - Risk-reward ratio not acceptable");
        return;
    }
    
    //--- Close opposite positions if enabled
    if(CloseAllOnOppositeSignal)
    {
        CloseAllPositions(POSITION_TYPE_SELL);
    }
    
    //--- Calculate position size
    double sl_distance = MathAbs(current_price - sl);
    double lot_size = CalculatePositionSize(sl_distance);
    
    //--- Execute main trade
    double main_lot_size = UsePartialTakeProfit ? lot_size * (100 - PartialTPPercent) / 100.0 : lot_size;
    
    if(trade.Buy(main_lot_size, _Symbol, current_price, sl, tp, "OrderBlock_BUY"))
    {
        ulong main_ticket = trade.ResultOrder();
        
        //--- Execute partial position if enabled
        if(UsePartialTakeProfit)
        {
            double partial_lot_size = lot_size * PartialTPPercent / 100.0;
            double partial_tp = current_price + ((current_price - sl) * PartialTPRatio);
            partial_tp = NormalizeDouble(partial_tp, _Digits);
            
            if(trade.Buy(partial_lot_size, _Symbol, current_price, sl, partial_tp, "OrderBlock_BUY_Partial"))
            {
                ulong partial_ticket = trade.ResultOrder();
                Print("Partial BUY position opened: Ticket=", partial_ticket, ", Lot=", DoubleToString(partial_lot_size, 2), ", TP=", DoubleToString(partial_tp, _Digits));
            }
        }
        
        //--- Update tracking variables
        last_buy_price = current_price;
        last_buy_signal_time = TimeCurrent();
        total_buy_positions++;
        total_trades++;
        
        //--- Update risk-reward statistics
        average_rr_ratio += actual_rr_ratio;
        rr_trade_count++;
        
        //--- Send alerts
        if(EnableAlerts)
        {
            SendAdvancedTradeAlert("BUY", current_price, sl, tp, lot_size, main_ticket, actual_rr_ratio);
        }
        
        Print("=== BULLISH ORDER BLOCK TRADE EXECUTED ===");
        Print("Ticket: ", main_ticket);
        Print("Price: ", DoubleToString(current_price, _Digits));
        Print("Stop Loss: ", DoubleToString(sl, _Digits));
        Print("Take Profit: ", DoubleToString(tp, _Digits));
        Print("Lot Size: ", DoubleToString(lot_size, 2));
        Print("Actual R:R Ratio: 1:", DoubleToString(actual_rr_ratio, 2));
        Print("RR Method: ", RiskRewardMethod == RR_FIXED_RATIO ? "Fixed" : 
                              RiskRewardMethod == RR_OB_LEVELS ? "OB Levels" : "ATR");
        if(UseOrderBlockSLTP && current_bullish_ob_low > 0)
            Print("Based on Bullish OB Low: ", DoubleToString(current_bullish_ob_low, _Digits));
        if(UsePartialTakeProfit)
            Print("Partial TP: ", DoubleToString(PartialTPPercent, 1), "% at R:R 1:", DoubleToString(PartialTPRatio, 2));
        Print("========================================");
    }
    else
    {
        Print("BUY order failed: ", trade.ResultRetcodeDescription());
        Print("Error code: ", trade.ResultRetcode());
    }
}

//+------------------------------------------------------------------+
//| Execute sell trade with advanced risk management                 |
//+------------------------------------------------------------------+
void ExecuteSellTrade(double current_price)
{
    if(!EnableTrading) return;
    
    //--- Check filters
    if(!IsTimeFilterOK())
        return;
    
    //--- Check stacking rules
    if(!IsStackingAllowed(false, current_price))
        return;
    
    //--- Calculate advanced stop loss and take profit
    double sl, tp, actual_rr_ratio;
    if(!CalculateAdvancedStopLossAndTakeProfit(current_price, false, sl, tp, actual_rr_ratio))
    {
        Print("Skipping SELL trade - Risk-reward ratio not acceptable");
        return;
    }
    
    //--- Close opposite positions if enabled
    if(CloseAllOnOppositeSignal)
    {
        CloseAllPositions(POSITION_TYPE_BUY);
    }
    
    //--- Calculate position size
    double sl_distance = MathAbs(current_price - sl);
    double lot_size = CalculatePositionSize(sl_distance);
    
    //--- Execute main trade
    double main_lot_size = UsePartialTakeProfit ? lot_size * (100 - PartialTPPercent) / 100.0 : lot_size;
    
    if(trade.Sell(main_lot_size, _Symbol, current_price, sl, tp, "OrderBlock_SELL"))
    {
        ulong main_ticket = trade.ResultOrder();
        
        //--- Execute partial position if enabled
        if(UsePartialTakeProfit)
        {
            double partial_lot_size = lot_size * PartialTPPercent / 100.0;
            double partial_tp = current_price - ((sl - current_price) * PartialTPRatio);
            partial_tp = NormalizeDouble(partial_tp, _Digits);
            
            if(trade.Sell(partial_lot_size, _Symbol, current_price, sl, partial_tp, "OrderBlock_SELL_Partial"))
            {
                ulong partial_ticket = trade.ResultOrder();
                Print("Partial SELL position opened: Ticket=", partial_ticket, ", Lot=", DoubleToString(partial_lot_size, 2), ", TP=", DoubleToString(partial_tp, _Digits));
            }
        }
        
        //--- Update tracking variables
        last_sell_price = current_price;
        last_sell_signal_time = TimeCurrent();
        total_sell_positions++;
        total_trades++;
        
        //--- Update risk-reward statistics
        average_rr_ratio += actual_rr_ratio;
        rr_trade_count++;
        
        //--- Send alerts
        if(EnableAlerts)
        {
            SendAdvancedTradeAlert("SELL", current_price, sl, tp, lot_size, main_ticket, actual_rr_ratio);
        }
        
        Print("=== BEARISH ORDER BLOCK TRADE EXECUTED ===");
        Print("Ticket: ", main_ticket);
        Print("Price: ", DoubleToString(current_price, _Digits));
        Print("Stop Loss: ", DoubleToString(sl, _Digits));
        Print("Take Profit: ", DoubleToString(tp, _Digits));
        Print("Lot Size: ", DoubleToString(lot_size, 2));
        Print("Actual R:R Ratio: 1:", DoubleToString(actual_rr_ratio, 2));
        Print("RR Method: ", RiskRewardMethod == RR_FIXED_RATIO ? "Fixed" : 
                              RiskRewardMethod == RR_OB_LEVELS ? "OB Levels" : "ATR");
        if(UseOrderBlockSLTP && current_bearish_ob_high > 0)
            Print("Based on Bearish OB High: ", DoubleToString(current_bearish_ob_high, _Digits));
        if(UsePartialTakeProfit)
            Print("Partial TP: ", DoubleToString(PartialTPPercent, 1), "% at R:R 1:", DoubleToString(PartialTPRatio, 2));
        Print("=========================================");
    }
    else
    {
        Print("SELL order failed: ", trade.ResultRetcodeDescription());
        Print("Error code: ", trade.ResultRetcode());
    }
}

//+------------------------------------------------------------------+
//| Send advanced trade alert with R:R information                  |
//+------------------------------------------------------------------+
void SendAdvancedTradeAlert(string signal_type, double price, double sl, double tp, double lot_size, ulong ticket, double rr_ratio)
{
    string ob_info = "";
    if(UseOrderBlockSLTP)
    {
        if(signal_type == "BUY" && current_bullish_ob_low > 0)
            ob_info = StringFormat(" [OB_Low: %s]", DoubleToString(current_bullish_ob_low, _Digits));
        else if(signal_type == "SELL" && current_bearish_ob_high > 0)
            ob_info = StringFormat(" [OB_High: %s]", DoubleToString(current_bearish_ob_high, _Digits));
    }
    
    string rr_method = RiskRewardMethod == RR_FIXED_RATIO ? "Fixed" : 
                       RiskRewardMethod == RR_OB_LEVELS ? "OB" : "ATR";
    
    string message = StringFormat("%s %s Order Block Trade: Ticket=%I64u, Price=%s, Lot=%s, SL=%s, TP=%s, R:R=1:%s (%s)%s",
                                 AlertPrefix, signal_type, ticket, 
                                 DoubleToString(price, _Digits),
                                 DoubleToString(lot_size, 2),
                                 DoubleToString(sl, _Digits),
                                 DoubleToString(tp, _Digits),
                                 DoubleToString(rr_ratio, 2),
                                 rr_method,
                                 ob_info);
    
    if(EnablePopupAlerts)
        Alert(message);
    
    if(EnableSoundAlerts)
    {
        string sound_file = (signal_type == "BUY") ? BuyAlertSound : SellAlertSound;
        if(sound_file != "")
            PlaySound(sound_file);
    }
    
    if(EnableEmailAlerts)
        SendMail(AlertPrefix + " Advanced Order Block Trade", message);
    
    if(EnablePushAlerts)
        SendNotification(message);
    
    Print("ALERT: ", message);
}

//+------------------------------------------------------------------+
//| Update trailing stop with breakeven functionality               |
//+------------------------------------------------------------------+
void UpdateAdvancedTrailingStop()
{
    if(!UseTrailingStop && !UseBreakevenStop) return;
    
    double trailing_distance = TrailingStopPips * _Point * 10;
    double trailing_step = TrailingStepPips * _Point * 10;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Symbol() == _Symbol && position.Magic() == EA_MAGIC_BASE)
            {
                double current_price;
                double new_sl = position.StopLoss();
                bool should_modify = false;
                double position_profit = position.Profit();
                bool is_in_profit = position_profit > 0;
                
                if(position.PositionType() == POSITION_TYPE_BUY)
                {
                    current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                    
                    //--- Breakeven stop logic
                    if(UseBreakevenStop && position.StopLoss() < position.PriceOpen() && is_in_profit)
                    {
                        double profit_distance = current_price - position.PriceOpen();
                        double sl_distance = position.PriceOpen() - position.StopLoss();
                        
                        if(profit_distance >= sl_distance * 0.5) // Move to breakeven when 50% of TP distance is reached
                        {
                            new_sl = position.PriceOpen() + (5 * _Point); // Small profit at breakeven
                            should_modify = true;
                            Print("Moving BUY position ", position.Ticket(), " to breakeven");
                        }
                    }
                    
                    //--- Trailing stop logic
                    if(UseTrailingStop && (!TrailOnlyInProfit || is_in_profit))
                    {
                        double trail_sl = current_price - trailing_distance;
                        if(trail_sl > new_sl + trailing_step || position.StopLoss() == 0)
                        {
                            new_sl = trail_sl;
                            should_modify = true;
                        }
                    }
                }
                else if(position.PositionType() == POSITION_TYPE_SELL)
                {
                    current_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                    
                    //--- Breakeven stop logic
                    if(UseBreakevenStop && position.StopLoss() > position.PriceOpen() && is_in_profit)
                    {
                        double profit_distance = position.PriceOpen() - current_price;
                        double sl_distance = position.StopLoss() - position.PriceOpen();
                        
                        if(profit_distance >= sl_distance * 0.5) // Move to breakeven when 50% of TP distance is reached
                        {
                            new_sl = position.PriceOpen() - (5 * _Point); // Small profit at breakeven
                            should_modify = true;
                            Print("Moving SELL position ", position.Ticket(), " to breakeven");
                        }
                    }
                    
                    //--- Trailing stop logic
                    if(UseTrailingStop && (!TrailOnlyInProfit || is_in_profit))
                    {
                        double trail_sl = current_price + trailing_distance;
                        if(trail_sl < new_sl - trailing_step || position.StopLoss() == 0)
                        {
                            new_sl = trail_sl;
                            should_modify = true;
                        }
                    }
                }
                
                if(should_modify && new_sl != position.StopLoss())
                {
                    new_sl = NormalizeDouble(new_sl, _Digits);
                    if(trade.PositionModify(position.Ticket(), new_sl, position.TakeProfit()))
                    {
                        Print("Advanced stop management updated: Ticket=", position.Ticket(), ", New SL=", DoubleToString(new_sl, _Digits));
                    }
                    else
                    {
                        Print("Failed to update stop management for ticket ", position.Ticket(), ": ", trade.ResultRetcodeDescription());
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Update trading statistics with R:R tracking                     |
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
    
    //--- Count positions
    total_buy_positions = GetCurrentStackLevel(ORDER_TYPE_BUY);
    total_sell_positions = GetCurrentStackLevel(ORDER_TYPE_SELL);
    
    //--- Update win rate from deal history
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
//| Update enhanced trading dashboard                                |
//+------------------------------------------------------------------+
void UpdateTradingDashboard()
{
    if(!ShowDashboard) return;
    
    string dashboard_text = "";
    dashboard_text += "\n=== Order Block Trading EA v1.01 Dashboard ===";
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
    
    if(rr_trade_count > 0)
    {
        dashboard_text += "\nAvg R:R: 1:" + DoubleToString(average_rr_ratio / rr_trade_count, 2);
    }
    else
    {
        dashboard_text += "\nAvg R:R: N/A";
    }
    
    dashboard_text += "\n\n=== Risk-Reward Settings ===";
    string rr_method = (RiskRewardMethod == RR_FIXED_RATIO) ? "Fixed Ratio" :
                      (RiskRewardMethod == RR_OB_LEVELS) ? "OB Levels" : "ATR Multiple";
    dashboard_text += "\nRR Method: " + rr_method;
    dashboard_text += "\nTarget R:R: 1:" + DoubleToString(RiskRewardRatio, 2);
    dashboard_text += "\nMin/Max R:R: " + DoubleToString(MinRiskRewardRatio, 2) + "/" + DoubleToString(MaxRiskRewardRatio, 2);
    
    if(RiskRewardMethod == RR_ATR_MULTIPLE)
    {
        dashboard_text += "\nATR Period: " + IntegerToString(ATR_Period);
        dashboard_text += "\nATR SL/TP: " + DoubleToString(ATR_SL_Multiplier, 1) + "/" + DoubleToString(ATR_TP_Multiplier, 1);
    }
    
    dashboard_text += "\n\n=== Advanced Features ===";
    dashboard_text += "\nPartial TP: " + (UsePartialTakeProfit ? "ON (" + DoubleToString(PartialTPPercent, 0) + "%)" : "OFF");
    dashboard_text += "\nBreakeven: " + (UseBreakevenStop ? "ON" : "OFF");
    dashboard_text += "\nTrailing: " + (UseTrailingStop ? "ON (" + IntegerToString(TrailingStopPips) + ")" : "OFF");
    dashboard_text += "\nDynamic SL/TP: " + (UseDynamicSLTP ? "ON" : "OFF");
    
    dashboard_text += "\n\n=== Order Block Settings ===";
    dashboard_text += "\nOB Periods: " + IntegerToString(InpPeriods);
    dashboard_text += "\nMin Threshold: " + DoubleToString(InpThreshold, 2) + "%";
    dashboard_text += "\nUse Wicks: " + (InpUseWicks ? "YES" : "NO");
    dashboard_text += "\nOB Buffer: " + DoubleToString(OB_Buffer_Pips, 1) + " pips";
    string filter_name = (InpFilterType == FILTER_EMA) ? "EMA(" + IntegerToString(InpEMA_Period) + ")" :
                        (InpFilterType == FILTER_VWAP) ? "VWAP" : "None";
    dashboard_text += "\nFilter: " + filter_name;
    
    dashboard_text += "\n\n=== Current OB Levels ===";
    if(current_bullish_ob_high > 0 || current_bullish_ob_low > 0)
    {
        dashboard_text += "\nBullish OB: " + DoubleToString(current_bullish_ob_high, _Digits) + " - " + DoubleToString(current_bullish_ob_low, _Digits);
    }
    else
    {
        dashboard_text += "\nBullish OB: None";
    }
    
    if(current_bearish_ob_high > 0 || current_bearish_ob_low > 0)
    {
        dashboard_text += "\nBearish OB: " + DoubleToString(current_bearish_ob_high, _Digits) + " - " + DoubleToString(current_bearish_ob_low, _Digits);
    }
    else
    {
        dashboard_text += "\nBearish OB: None";
    }
    
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
    string obj_name = "OrderBlock_EA_Dashboard";
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
//| Expert tick function                                            |
//+------------------------------------------------------------------+
void OnTick()
{
    //--- Update advanced trailing stops and breakeven
    UpdateAdvancedTrailingStop();
    
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
        Print("Error: Indicator handle is invalid. Cannot get Order Block signals.");
        return;
    }
    
    //--- Copy indicator buffers (6 buffers from OrderBlockIndicator)
    int copied_bullish_high = CopyBuffer(indicator_handle, 0, 0, 3, bullish_ob_high);
    int copied_bullish_low = CopyBuffer(indicator_handle, 1, 0, 3, bullish_ob_low);
    int copied_bearish_high = CopyBuffer(indicator_handle, 2, 0, 3, bearish_ob_high);
    int copied_bearish_low = CopyBuffer(indicator_handle, 3, 0, 3, bearish_ob_low);
    int copied_buy_arrow = CopyBuffer(indicator_handle, 4, 0, 3, buy_arrow);
    int copied_sell_arrow = CopyBuffer(indicator_handle, 5, 0, 3, sell_arrow);
    
    if(copied_bullish_high <= 0 || copied_bullish_low <= 0 || copied_bearish_high <= 0 || 
       copied_bearish_low <= 0 || copied_buy_arrow <= 0 || copied_sell_arrow <= 0)
    {
        int error_code = GetLastError();
        if(error_code != 0)
        {
            Print("Error copying Order Block indicator buffers. Error: ", error_code);
            if(error_code == 4806) // ERR_INDICATOR_DATA_NOT_FOUND
            {
                Print("Order Block indicator data not ready. Waiting for next tick...");
            }
        }
        return;
    }
    
    //--- Get current values (most recent bar is index 0 with ArraySetAsSeries)
    double curr_bullish_high = bullish_ob_high[0];
    double curr_bullish_low = bullish_ob_low[0];
    double curr_bearish_high = bearish_ob_high[0];
    double curr_bearish_low = bearish_ob_low[0];
    double curr_buy_arrow = buy_arrow[0];
    double curr_sell_arrow = sell_arrow[0];
    
    //--- Update current Order Block levels for SL/TP calculation
    if(curr_bullish_high != EMPTY_VALUE && curr_bullish_low != EMPTY_VALUE)
    {
        current_bullish_ob_high = curr_bullish_high;
        current_bullish_ob_low = curr_bullish_low;
    }
    
    if(curr_bearish_high != EMPTY_VALUE && curr_bearish_low != EMPTY_VALUE)
    {
        current_bearish_ob_high = curr_bearish_high;
        current_bearish_ob_low = curr_bearish_low;
    }
    
    //--- Get current prices
    double current_ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double current_bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    if(current_ask == 0 || current_bid == 0)
    {
        Print("Error: Cannot get current prices");
        return;
    }
    
    //--- Check for Order Block signals
    bool bullish_ob_signal = (curr_bullish_high != EMPTY_VALUE && curr_bullish_low != EMPTY_VALUE);
    bool bearish_ob_signal = (curr_bearish_high != EMPTY_VALUE && curr_bearish_low != EMPTY_VALUE);
    bool buy_arrow_signal = (curr_buy_arrow != EMPTY_VALUE && curr_buy_arrow > 0);
    bool sell_arrow_signal = (curr_sell_arrow != EMPTY_VALUE && curr_sell_arrow > 0);
    
    //--- Combine signals (Order Block formation OR arrow signals)
    bool buy_signal = bullish_ob_signal || buy_arrow_signal;
    bool sell_signal = bearish_ob_signal || sell_arrow_signal;
    
    //--- Avoid processing same signal multiple times
    static double last_processed_bullish_high = EMPTY_VALUE;
    static double last_processed_bearish_high = EMPTY_VALUE;
    static datetime last_signal_bar_time = 0;
    
    if(last_signal_bar_time != current_bar_time)
    {
        last_signal_bar_time = current_bar_time;
        last_processed_bullish_high = EMPTY_VALUE;
        last_processed_bearish_high = EMPTY_VALUE;
    }
    
    //--- Execute buy trade on bullish Order Block
    if(buy_signal && last_processed_bullish_high != curr_bullish_high)
    {
        if(ShowDebugInfo)
        {
            Print("BULLISH ORDER BLOCK DETECTED at ", TimeToString(current_bar_time, TIME_SECONDS));
            Print("Bullish OB High: ", curr_bullish_high != EMPTY_VALUE ? DoubleToString(curr_bullish_high, _Digits) : "N/A");
            Print("Bullish OB Low: ", curr_bullish_low != EMPTY_VALUE ? DoubleToString(curr_bullish_low, _Digits) : "N/A");
            Print("Buy Arrow: ", curr_buy_arrow != EMPTY_VALUE ? DoubleToString(curr_buy_arrow, _Digits) : "N/A");
        }
        
        ExecuteBuyTrade(current_ask);
        last_processed_bullish_high = curr_bullish_high;
    }
    
    //--- Execute sell trade on bearish Order Block
    if(sell_signal && last_processed_bearish_high != curr_bearish_high)
    {
        if(ShowDebugInfo)
        {
            Print("BEARISH ORDER BLOCK DETECTED at ", TimeToString(current_bar_time, TIME_SECONDS));
            Print("Bearish OB High: ", curr_bearish_high != EMPTY_VALUE ? DoubleToString(curr_bearish_high, _Digits) : "N/A");
            Print("Bearish OB Low: ", curr_bearish_low != EMPTY_VALUE ? DoubleToString(curr_bearish_low, _Digits) : "N/A");
            Print("Sell Arrow: ", curr_sell_arrow != EMPTY_VALUE ? DoubleToString(curr_sell_arrow, _Digits) : "N/A");
        }
        
        ExecuteSellTrade(current_bid);
        last_processed_bearish_high = curr_bearish_high;
    }
    
    //--- Debug information
    if(ShowDebugInfo)
    {
        static int debug_counter = 0;
        debug_counter++;
        
        if(debug_counter % 10 == 0) // Print every 10th tick to avoid spam
        {
            Print("=== ORDER BLOCK DEBUG INFO ===");
            Print("Current Bar: ", TimeToString(current_bar_time, TIME_SECONDS));
            Print("Bullish OB High[0]: ", curr_bullish_high == EMPTY_VALUE ? "EMPTY" : DoubleToString(curr_bullish_high, _Digits));
            Print("Bullish OB Low[0]: ", curr_bullish_low == EMPTY_VALUE ? "EMPTY" : DoubleToString(curr_bullish_low, _Digits));
            Print("Bearish OB High[0]: ", curr_bearish_high == EMPTY_VALUE ? "EMPTY" : DoubleToString(curr_bearish_high, _Digits));
            Print("Bearish OB Low[0]: ", curr_bearish_low == EMPTY_VALUE ? "EMPTY" : DoubleToString(curr_bearish_low, _Digits));
            Print("Buy Arrow[0]: ", curr_buy_arrow == EMPTY_VALUE ? "EMPTY" : DoubleToString(curr_buy_arrow, _Digits));
            Print("Sell Arrow[0]: ", curr_sell_arrow == EMPTY_VALUE ? "EMPTY" : DoubleToString(curr_sell_arrow, _Digits));
            Print("Buy Positions: ", total_buy_positions, ", Sell Positions: ", total_sell_positions);
            Print("Trading Enabled: ", EnableTrading ? "YES" : "NO");
            Print("Current R:R Method: ", RiskRewardMethod == RR_FIXED_RATIO ? "Fixed" : 
                                         RiskRewardMethod == RR_OB_LEVELS ? "OB Levels" : "ATR");
            Print("Target R:R Ratio: 1:", DoubleToString(RiskRewardRatio, 2));
            if(rr_trade_count > 0)
                Print("Average R:R Achieved: 1:", DoubleToString(average_rr_ratio / rr_trade_count, 2));
            Print("===============================");
        }
    }
}

//+------------------------------------------------------------------+
//| Expert trade transaction function with enhanced tracking        |
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
                double volume = HistoryDealGetDouble(trans.deal, DEAL_VOLUME);
                double entry_price = HistoryDealGetDouble(trans.deal, DEAL_PRICE);
                string comment = HistoryDealGetString(trans.deal, DEAL_COMMENT);
                
                if(symbol == _Symbol && profit != 0)
                {
                    //--- Calculate actual R:R ratio achieved
                    double actual_rr = 0;
                    if(StringFind(comment, "OrderBlock") >= 0)
                    {
                        // Try to calculate R:R from the trade result
                        // This is approximate since we don't store the original SL distance
                        if(profit > 0)
                        {
                            Print("Order Block trade closed with PROFIT: $", DoubleToString(profit, 2));
                            if(StringFind(comment, "Partial") >= 0)
                                Print("This was a partial take profit execution");
                        }
                        else
                        {
                            Print("Order Block trade closed with LOSS: $", DoubleToString(profit, 2));
                        }
                        
                        total_profit += (profit > 0 ? profit : 0);
                        total_loss += (profit < 0 ? MathAbs(profit) : 0);
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
                Print("Order Block EA - Order added: ", trans.order, ", Type: ", trans.order_type);
            break;
        }
        
        case TRADE_TRANSACTION_ORDER_DELETE:
        {
            if(ShowDebugInfo)
                Print("Order Block EA - Order deleted: ", trans.order);
            break;
        }
        
        case TRADE_TRANSACTION_POSITION:
        {
            if(ShowDebugInfo)
                Print("Order Block EA - Position modified: ", trans.position);
            break;
        }
    }
}

//+------------------------------------------------------------------+
//| Calculate lot size with enhanced risk management                 |
//+------------------------------------------------------------------+
double CalculateEnhancedPositionSize(double entry_price, double sl_price, bool is_buy)
{
    if(LotSizingMethod == LOT_FIXED)
        return CalculatePositionSize();
    
    double sl_distance = MathAbs(entry_price - sl_price);
    if(sl_distance <= 0)
        return FixedLotSize;
    
    double risk_amount = 0;
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    switch(LotSizingMethod)
    {
        case LOT_RISK_PERCENT:
            risk_amount = balance * RiskPercent / 100.0;
            break;
            
        case LOT_BALANCE_PERCENT:
            risk_amount = balance * BalancePercent / 100.0;
            break;
            
        default:
            return FixedLotSize;
    }
    
    //--- Calculate lot size based on risk amount and SL distance
    double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    
    if(tick_value <= 0 || tick_size <= 0)
        return FixedLotSize;
    
    double sl_amount = (sl_distance / tick_size) * tick_value;
    
    if(sl_amount <= 0)
        return FixedLotSize;
    
    double calculated_lot_size = risk_amount / sl_amount;
    
    //--- Apply position stacking multiplier
    if(EnablePositionStacking)
    {
        int stack_level = is_buy ? GetCurrentStackLevel(ORDER_TYPE_BUY) : GetCurrentStackLevel(ORDER_TYPE_SELL);
        calculated_lot_size *= MathPow(StackingSizeMultiplier, stack_level);
    }
    
    //--- Normalize lot size
    double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    calculated_lot_size = MathMax(calculated_lot_size, min_lot);
    calculated_lot_size = MathMin(calculated_lot_size, max_lot);
    calculated_lot_size = NormalizeDouble(MathRound(calculated_lot_size / lot_step) * lot_step, 2);
    
    return calculated_lot_size;
}

//+------------------------------------------------------------------+
//| Validate trade setup before execution                           |
//+------------------------------------------------------------------+
bool ValidateTradeSetup(double entry_price, double sl_price, double tp_price, bool is_buy)
{
    //--- Basic price validation
    if(entry_price <= 0 || sl_price <= 0 || tp_price <= 0)
    {
        Print("Invalid prices: Entry=", entry_price, ", SL=", sl_price, ", TP=", tp_price);
        return false;
    }
    
    //--- Validate SL/TP direction for buy trades
    if(is_buy)
    {
        if(sl_price >= entry_price)
        {
            Print("Invalid BUY setup: SL (", sl_price, ") must be below entry (", entry_price, ")");
            return false;
        }
        if(tp_price <= entry_price)
        {
            Print("Invalid BUY setup: TP (", tp_price, ") must be above entry (", entry_price, ")");
            return false;
        }
    }
    else
    {
        if(sl_price <= entry_price)
        {
            Print("Invalid SELL setup: SL (", sl_price, ") must be above entry (", entry_price, ")");
            return false;
        }
        if(tp_price >= entry_price)
        {
            Print("Invalid SELL setup: TP (", tp_price, ") must be below entry (", entry_price, ")");
            return false;
        }
    }
    
    //--- Calculate and validate risk-reward ratio
    double sl_distance = MathAbs(entry_price - sl_price);
    double tp_distance = MathAbs(tp_price - entry_price);
    double actual_rr = tp_distance / sl_distance;
    
    if(actual_rr < MinRiskRewardRatio)
    {
        Print("Risk-reward ratio (", DoubleToString(actual_rr, 2), ") below minimum (", DoubleToString(MinRiskRewardRatio, 2), ")");
        return false;
    }
    
    //--- Validate minimum distance from current price
    double current_price = is_buy ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double min_distance = 10 * _Point; // Minimum 10 points from current price
    
    if(MathAbs(entry_price - current_price) > min_distance)
    {
        Print("Entry price too far from current market price");
        return false;
    }
    
    //--- Check spread impact
    double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
    if(spread > sl_distance * 0.1) // Spread shouldn't be more than 10% of SL distance
    {
        Print("Spread too high relative to SL distance: ", spread, " vs ", sl_distance);
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Enhanced OnInit with additional validations                     |
//+------------------------------------------------------------------+
bool ValidateEASettings()
{
    //--- Validate risk-reward settings
    if(RiskRewardRatio <= 0 || MinRiskRewardRatio <= 0 || MaxRiskRewardRatio <= 0)
    {
        Print("Error: All risk-reward ratios must be positive");
        return false;
    }
    
    if(MinRiskRewardRatio >= MaxRiskRewardRatio)
    {
        Print("Error: Min R:R ratio must be less than Max R:R ratio");
        return false;
    }
    
    if(RiskRewardRatio < MinRiskRewardRatio || RiskRewardRatio > MaxRiskRewardRatio)
    {
        Print("Error: Target R:R ratio must be between Min and Max ratios");
        return false;
    }
    
    //--- Validate ATR settings
    if(RiskRewardMethod == RR_ATR_MULTIPLE)
    {
        if(ATR_Period <= 0 || ATR_SL_Multiplier <= 0 || ATR_TP_Multiplier <= 0)
        {
            Print("Error: ATR settings must be positive");
            return false;
        }
    }
    
    //--- Validate partial TP settings
    if(UsePartialTakeProfit)
    {
        if(PartialTPPercent <= 0 || PartialTPPercent >= 100)
        {
            Print("Error: Partial TP percentage must be between 0 and 100");
            return false;
        }
        if(PartialTPRatio <= 0 || PartialTPRatio >= RiskRewardRatio)
        {
            Print("Error: Partial TP ratio must be positive and less than main R:R ratio");
            return false;
        }
    }
    
    //--- Validate lot sizing
    if(LotSizingMethod == LOT_RISK_PERCENT && RiskPercent <= 0)
    {
        Print("Error: Risk percentage must be positive");
        return false;
    }
    
    if(LotSizingMethod == LOT_BALANCE_PERCENT && BalancePercent <= 0)
    {
        Print("Error: Balance percentage must be positive");
        return false;
    }
    
    //--- Validate trailing stop settings
    if(UseTrailingStop)
    {
        if(TrailingStopPips <= 0 || TrailingStepPips <= 0)
        {
            Print("Error: Trailing stop parameters must be positive");
            return false;
        }
        if(TrailingStepPips >= TrailingStopPips)
        {
            Print("Error: Trailing step must be smaller than trailing distance");
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Get current market conditions summary                           |
//+------------------------------------------------------------------+
string GetMarketConditionsSummary()
{
    double current_ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double current_bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double spread = current_ask - current_bid;
    
    string conditions = "";
    conditions += "Bid: " + DoubleToString(current_bid, _Digits);
    conditions += " | Ask: " + DoubleToString(current_ask, _Digits);
    conditions += " | Spread: " + DoubleToString(spread / _Point, 1) + " pts";
    
    if(RiskRewardMethod == RR_ATR_MULTIPLE && CopyBuffer(atr_handle, 0, 1, 1, atr_buffer) > 0)
    {
        conditions += " | ATR: " + DoubleToString(atr_buffer[0] / _Point, 1) + " pts";
    }
    
    return conditions;
}

//+------------------------------------------------------------------+