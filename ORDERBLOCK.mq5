 //+------------------------------------------------------------------+
//|                                    OrderBlockIndicator.mq5       |
//|                        Copyright 2024, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.01"
#property description "Order Block Finder with EMA/VWAP Filter - Fixed Arrows"
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   6

// Plot definitions for Order Block lines
#property indicator_label1  "Bullish OB High"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGreen
#property indicator_style1  STYLE_DASH
#property indicator_width1  2

#property indicator_label2  "Bullish OB Low"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrGreen
#property indicator_style2  STYLE_DASH
#property indicator_width2  2

#property indicator_label3  "Bearish OB High"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrRed
#property indicator_style3  STYLE_DASH
#property indicator_width3  2

#property indicator_label4  "Bearish OB Low"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrRed
#property indicator_style4  STYLE_DASH
#property indicator_width4  2

// Plot definitions for arrows
#property indicator_label5  "Buy Arrow"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrLime
#property indicator_width5  4

#property indicator_label6  "Sell Arrow"
#property indicator_type6   DRAW_ARROW
#property indicator_color6  clrRed
#property indicator_width6  4

// Input parameters
input group "=== Order Block Settings ==="
input int InpPeriods = 5;                          // Relevant Periods to identify OB
input double InpThreshold = 0.0;                   // Min. Percent move to identify OB
input bool InpUseWicks = false;                    // Use whole range [High/Low] for OB marking
input bool InpShowBullish = true;                  // Show Bullish Order Blocks
input bool InpShowBearish = true;                  // Show Bearish Order Blocks
input bool InpShowArrows = true;                   // Show Buy/Sell Arrows

input group "=== Filter Settings ==="
enum ENUM_FILTER_TYPE
{
   FILTER_NONE = 0,     // No Filter
   FILTER_EMA = 1,      // EMA Filter
   FILTER_VWAP = 2      // VWAP Filter
};
input ENUM_FILTER_TYPE InpFilterType = FILTER_EMA; // Filter Type
input int InpEMA_Period = 50;                      // EMA Period (if EMA filter selected)

input group "=== Color Settings ==="
input color InpBullishColor = clrLime;             // Bullish Order Block Color
input color InpBearishColor = clrRed;              // Bearish Order Block Color

input group "=== Arrow Settings ==="
input int InpBuyArrowCode = 233;                   // Buy Arrow Symbol Code
input int InpSellArrowCode = 234;                  // Sell Arrow Symbol Code
input double InpArrowOffset = 0.2;                 // Arrow Offset (% of candle range)

// Indicator buffers
double BullishOB_High[];
double BullishOB_Low[];
double BearishOB_High[];
double BearishOB_Low[];
double BuyArrow[];
double SellArrow[];

// Global variables
int ema_handle = INVALID_HANDLE;
double ema_buffer[];
double vwap_buffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   // Set indicator buffers
   SetIndexBuffer(0, BullishOB_High, INDICATOR_DATA);
   SetIndexBuffer(1, BullishOB_Low, INDICATOR_DATA);
   SetIndexBuffer(2, BearishOB_High, INDICATOR_DATA);
   SetIndexBuffer(3, BearishOB_Low, INDICATOR_DATA);
   SetIndexBuffer(4, BuyArrow, INDICATOR_DATA);
   SetIndexBuffer(5, SellArrow, INDICATOR_DATA);
   
   // Set arrow codes and properties
   PlotIndexSetInteger(4, PLOT_ARROW, InpBuyArrowCode);
   PlotIndexSetInteger(5, PLOT_ARROW, InpSellArrowCode);
   
   // Set arrow shift for better visibility
   PlotIndexSetInteger(4, PLOT_ARROW_SHIFT, 0);
   PlotIndexSetInteger(5, PLOT_ARROW_SHIFT, 0);
   
   // Set colors
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, InpBullishColor);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, InpBullishColor);
   PlotIndexSetInteger(2, PLOT_LINE_COLOR, InpBearishColor);
   PlotIndexSetInteger(3, PLOT_LINE_COLOR, InpBearishColor);
   PlotIndexSetInteger(4, PLOT_LINE_COLOR, InpBullishColor);
   PlotIndexSetInteger(5, PLOT_LINE_COLOR, InpBearishColor);
   
   // Set empty values
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(4, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(5, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   
   // Initialize buffers as series
   ArraySetAsSeries(BullishOB_High, true);
   ArraySetAsSeries(BullishOB_Low, true);
   ArraySetAsSeries(BearishOB_High, true);
   ArraySetAsSeries(BearishOB_Low, true);
   ArraySetAsSeries(BuyArrow, true);
   ArraySetAsSeries(SellArrow, true);
   
   // Initialize all buffers with EMPTY_VALUE
   ArrayInitialize(BullishOB_High, EMPTY_VALUE);
   ArrayInitialize(BullishOB_Low, EMPTY_VALUE);
   ArrayInitialize(BearishOB_High, EMPTY_VALUE);
   ArrayInitialize(BearishOB_Low, EMPTY_VALUE);
   ArrayInitialize(BuyArrow, EMPTY_VALUE);
   ArrayInitialize(SellArrow, EMPTY_VALUE);
   
   // Initialize EMA handle if needed
   if(InpFilterType == FILTER_EMA)
   {
      ema_handle = iMA(Symbol(), Period(), InpEMA_Period, 0, MODE_EMA, PRICE_CLOSE);
      if(ema_handle == INVALID_HANDLE)
      {
         Print("Failed to create EMA handle");
         return INIT_FAILED;
      }
      ArraySetAsSeries(ema_buffer, true);
   }
   
   // Initialize VWAP buffer if needed
   if(InpFilterType == FILTER_VWAP)
   {
      ArraySetAsSeries(vwap_buffer, true);
   }
   
   // Set indicator name
   string filter_name = "";
   switch(InpFilterType)
   {
      case FILTER_EMA: filter_name = " (EMA " + IntegerToString(InpEMA_Period) + ")"; break;
      case FILTER_VWAP: filter_name = " (VWAP)"; break;
      default: filter_name = ""; break;
   }
   
   IndicatorSetString(INDICATOR_SHORTNAME, "Order Blocks" + filter_name);
   
   // Set drawing begin
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, InpPeriods + 1);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, InpPeriods + 1);
   PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, InpPeriods + 1);
   PlotIndexSetInteger(3, PLOT_DRAW_BEGIN, InpPeriods + 1);
   PlotIndexSetInteger(4, PLOT_DRAW_BEGIN, InpPeriods + 1);
   PlotIndexSetInteger(5, PLOT_DRAW_BEGIN, InpPeriods + 1);
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(ema_handle != INVALID_HANDLE)
      IndicatorRelease(ema_handle);
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
   if(rates_total < InpPeriods + 2)
      return 0;
   
   // Set arrays as series
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(time, true);
   ArraySetAsSeries(tick_volume, true);
   if(ArraySize(volume) > 0)
      ArraySetAsSeries(volume, true);
   
   int start = MathMax(prev_calculated - 1, InpPeriods + 1);
   if(prev_calculated == 0) 
   {
      start = InpPeriods + 1;
      // Clear all buffers when starting fresh
      ArrayInitialize(BullishOB_High, EMPTY_VALUE);
      ArrayInitialize(BullishOB_Low, EMPTY_VALUE);
      ArrayInitialize(BearishOB_High, EMPTY_VALUE);
      ArrayInitialize(BearishOB_Low, EMPTY_VALUE);
      ArrayInitialize(BuyArrow, EMPTY_VALUE);
      ArrayInitialize(SellArrow, EMPTY_VALUE);
   }
   
   // Get filter data if needed
   if(InpFilterType == FILTER_EMA && ema_handle != INVALID_HANDLE)
   {
      if(CopyBuffer(ema_handle, 0, 0, rates_total, ema_buffer) <= 0)
         return prev_calculated;
   }
   
   // Calculate VWAP if needed
   if(InpFilterType == FILTER_VWAP)
   {
      CalculateVWAP(rates_total, high, low, close, tick_volume, volume);
   }
   
   // Main calculation loop
   for(int i = start; i < rates_total; i++)
   {
      // Initialize current bar buffers
      BullishOB_High[i] = EMPTY_VALUE;
      BullishOB_Low[i] = EMPTY_VALUE;
      BearishOB_High[i] = EMPTY_VALUE;
      BearishOB_Low[i] = EMPTY_VALUE;
      BuyArrow[i] = EMPTY_VALUE;
      SellArrow[i] = EMPTY_VALUE;
      
      // Check if we have enough data for lookback
      if(i < InpPeriods + 1) continue;
      
      int ob_index = i - InpPeriods;
      
      // Calculate absolute move
      double move_start = close[ob_index];
      double move_end = close[i - 1];
      double absmove = (MathAbs(move_end - move_start) / move_start) * 100;
      bool relmove = absmove >= InpThreshold;
      
      // Check for Bullish Order Block
      if(InpShowBullish)
      {
         bool bullishOB = close[ob_index] < open[ob_index]; // Initial red candle
         
         // Count consecutive up candles after the red candle
         int upcandles = 0;
         for(int j = 1; j <= InpPeriods; j++)
         {
            if(ob_index + j < rates_total && close[ob_index + j] > open[ob_index + j])
               upcandles++;
         }
         
         bool OB_bull = bullishOB && (upcandles >= InpPeriods) && relmove;
         
         // Apply filter
         if(OB_bull && ApplyFilter(ob_index, close[ob_index], true))
         {
            double OB_bull_high = InpUseWicks ? high[ob_index] : MathMax(open[ob_index], close[ob_index]);
            double OB_bull_low = low[ob_index];
            
            BullishOB_High[i] = OB_bull_high;
            BullishOB_Low[i] = OB_bull_low;
            
            // Set buy arrow
            if(InpShowArrows)
            {
               double candle_range = high[i] - low[i];
               if(candle_range == 0) candle_range = Point() * 10; // Minimum range
               BuyArrow[i] = low[i] - (candle_range * InpArrowOffset);
            }
         }
      }
      
      // Check for Bearish Order Block
      if(InpShowBearish)
      {
         bool bearishOB = close[ob_index] > open[ob_index]; // Initial green candle
         
         // Count consecutive down candles after the green candle
         int downcandles = 0;
         for(int j = 1; j <= InpPeriods; j++)
         {
            if(ob_index + j < rates_total && close[ob_index + j] < open[ob_index + j])
               downcandles++;
         }
         
         bool OB_bear = bearishOB && (downcandles >= InpPeriods) && relmove;
         
         // Apply filter
         if(OB_bear && ApplyFilter(ob_index, close[ob_index], false))
         {
            double OB_bear_high = high[ob_index];
            double OB_bear_low = InpUseWicks ? low[ob_index] : MathMin(open[ob_index], close[ob_index]);
            
            BearishOB_High[i] = OB_bear_high;
            BearishOB_Low[i] = OB_bear_low;
            
            // Set sell arrow
            if(InpShowArrows)
            {
               double candle_range = high[i] - low[i];
               if(candle_range == 0) candle_range = Point() * 10; // Minimum range
               SellArrow[i] = high[i] + (candle_range * InpArrowOffset);
            }
         }
      }
   }
   
   return rates_total;
}

//+------------------------------------------------------------------+
//| Apply filter based on selected type                             |
//+------------------------------------------------------------------+
bool ApplyFilter(int index, double price, bool is_bullish)
{
   switch(InpFilterType)
   {
      case FILTER_NONE:
         return true;
         
      case FILTER_EMA:
         if(ArraySize(ema_buffer) > index && index >= 0)
         {
            if(is_bullish)
               return price > ema_buffer[index]; // Bullish OB above EMA
            else
               return price < ema_buffer[index]; // Bearish OB below EMA
         }
         return true;
         
      case FILTER_VWAP:
         if(ArraySize(vwap_buffer) > index && index >= 0)
         {
            if(is_bullish)
               return price > vwap_buffer[index]; // Bullish OB above VWAP
            else
               return price < vwap_buffer[index]; // Bearish OB below VWAP
         }
         return true;
         
      default:
         return true;
   }
}

//+------------------------------------------------------------------+
//| Calculate VWAP                                                   |
//+------------------------------------------------------------------+
void CalculateVWAP(int rates_total, const double &high[], const double &low[], 
                   const double &close[], const long &tick_volume[], const long &volume[])
{
   ArrayResize(vwap_buffer, rates_total);
   ArraySetAsSeries(vwap_buffer, true);
   
   // Use volume if available, otherwise use tick_volume  
   bool use_volume = (ArraySize(volume) > 0);
   
   double sum_pv = 0;
   double sum_v = 0;
   
   // Calculate VWAP from most recent to oldest (since arrays are series)
   for(int i = rates_total - 1; i >= 0; i--)
   {
      double typical_price = (high[i] + low[i] + close[i]) / 3.0;
      double vol = use_volume ? (double)volume[i] : (double)tick_volume[i];
      if(vol <= 0) vol = 1.0;
      
      sum_pv += typical_price * vol;
      sum_v += vol;
      
      vwap_buffer[i] = (sum_v > 0) ? sum_pv / sum_v : typical_price;
   }
}