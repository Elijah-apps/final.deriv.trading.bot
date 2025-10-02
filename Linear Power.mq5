//+------------------------------------------------------------------+
//|                Linear Regression Intensity EA (MT5)             |
//|                        Enhanced Version with Trailing           |
//|                        © AlgoAlpha / EA Version                 |
//+------------------------------------------------------------------+
#property copyright "AlgoAlpha"
#property link      ""
#property version   "1.10"
#property strict

#include <Trade\Trade.mqh>

// Enums
enum ENUM_TRADE_DIRECTION
{
   TRADE_BOTH = 0,      // Trade Both Directions
   TRADE_BUY_ONLY = 1,  // Buy Only
   TRADE_SELL_ONLY = 2  // Sell Only
};

// Input Parameters
input group "==== Linear Regression Settings ===="
input int    n              = 12;     // Lookback Period
input int    p              = 90;     // Range Tolerance %
input int    linreg_length  = 90;     // Linear Regression Length

input group "==== Trade Direction ===="
input ENUM_TRADE_DIRECTION TradeDirection = TRADE_BOTH; // Trading Direction

input group "==== Money Management ===="
input double Lots           = 0.10;   // Fixed Lot Size
input int    ATR_Period     = 14;     // ATR Period
input double SL_ATR_Multi   = 1.5;    // Stop Loss ATR Multiplier
input double TP_ATR_Multi   = 3.0;    // Take Profit ATR Multiplier

input group "==== Trailing Stop ===="
input bool   UseTrailing    = true;   // Use Trailing Stop
input double Trail_ATR_Multi = 1.0;   // Trailing Stop ATR Multiplier
input double TrailingStep   = 10;     // Trailing Step (points)

input group "==== EA Settings ===="
input int    MagicNumber    = 123456; // Magic Number
input string Commentary     = "LinReg EA"; // Order Comment

// Global Variables
double linregBuffer[];
int lastState = 0;
int atrHandle;
CTrade trade;

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   // Set array as series
   ArraySetAsSeries(linregBuffer, true);
   
   // Set magic number and comment for trade object
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   
   // Create ATR indicator handle
   atrHandle = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);
   if(atrHandle == INVALID_HANDLE)
   {
      Print("Error creating ATR indicator");
      return(INIT_FAILED);
   }
   
   // Validate inputs
   if(n < 2)
   {
      Print("Error: Lookback Period must be >= 2");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   if(linreg_length < 2)
   {
      Print("Error: Linear Regression Length must be >= 2");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   if(Lots <= 0)
   {
      Print("Error: Lot Size must be positive");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   if(ATR_Period < 1)
   {
      Print("Error: ATR Period must be >= 1");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   Print("Linear Regression Intensity EA initialized successfully");
   Print("Trading Direction: ", EnumToString(TradeDirection));
   Print("Trailing Stop: ", UseTrailing ? "Enabled" : "Disabled");
   Print("SL ATR Multiplier: ", SL_ATR_Multi, " | TP ATR Multiplier: ", TP_ATR_Multi);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Release ATR indicator handle
   if(atrHandle != INVALID_HANDLE)
      IndicatorRelease(atrHandle);
   
   Print("EA removed. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Update trailing stops if enabled
   if(UseTrailing)
      ManageTrailingStops();
   
   // Check if new bar
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   
   if(currentBarTime == lastBarTime)
      return; // Wait for new bar
   
   lastBarTime = currentBarTime;
   
   // Calculate signal
   int state = CalculateSignal();
   
   // Execute trading logic
   ExecuteTradingLogic(state);
   
   // Update last state
   lastState = state;
}

//+------------------------------------------------------------------+
//| Calculate Linear Regression Signal                               |
//+------------------------------------------------------------------+
int CalculateSignal()
{
   int totalcombos = (n * (n - 1)) / 2;
   double thresh = totalcombos * (p / 100.0);
   int trend = 0;
   
   // Resize buffer
   ArrayResize(linregBuffer, n);
   
   // Calculate linear regression values for lookback period
   for(int i = 0; i < n; i++)
   {
      double sum_x = 0, sum_y = 0, sum_xy = 0, sum_x2 = 0;
      
      // Calculate linear regression manually
      for(int j = 0; j < linreg_length; j++)
      {
         double price = iClose(_Symbol, PERIOD_CURRENT, i + j);
         sum_x += j;
         sum_y += price;
         sum_xy += j * price;
         sum_x2 += j * j;
      }
      
      double slope = (linreg_length * sum_xy - sum_x * sum_y) / (linreg_length * sum_x2 - sum_x * sum_x);
      double intercept = (sum_y - slope * sum_x) / linreg_length;
      
      // Linear regression value at current point (offset 0)
      linregBuffer[i] = intercept;
   }
   
   // Trend calculation (pairwise comparison)
   for(int i = 0; i < n - 1; i++)
   {
      for(int j = i + 1; j < n; j++)
      {
         if(linregBuffer[i] != linregBuffer[j])
            trend += (linregBuffer[i] > linregBuffer[j]) ? 1 : -1;
      }
   }
   
   // State determination
   int state = 0;
   if(trend > thresh)
      state = 1;      // Bullish
   else if(trend < -thresh)
      state = -1;     // Bearish
   else
      state = 0;      // Neutral
   
   return state;
}

//+------------------------------------------------------------------+
//| Execute Trading Logic                                            |
//+------------------------------------------------------------------+
void ExecuteTradingLogic(int state)
{
   // Only act on state change
   if(state == lastState)
      return;
   
   if(state == 1) // Bullish trend
   {
      if(TradeDirection == TRADE_BOTH || TradeDirection == TRADE_BUY_ONLY)
      {
         CloseAllPositions(POSITION_TYPE_SELL);
         if(!HasPosition(POSITION_TYPE_BUY))
            OpenTrade(ORDER_TYPE_BUY);
      }
   }
   else if(state == -1) // Bearish trend
   {
      if(TradeDirection == TRADE_BOTH || TradeDirection == TRADE_SELL_ONLY)
      {
         CloseAllPositions(POSITION_TYPE_BUY);
         if(!HasPosition(POSITION_TYPE_SELL))
            OpenTrade(ORDER_TYPE_SELL);
      }
   }
   else if(state == 0) // Neutral: Close all
   {
      CloseAllPositions(POSITION_TYPE_BUY);
      CloseAllPositions(POSITION_TYPE_SELL);
   }
}

//+------------------------------------------------------------------+
//| Get Current ATR Value                                            |
//+------------------------------------------------------------------+
double GetATR()
{
   double atrArray[];
   ArraySetAsSeries(atrArray, true);
   
   if(CopyBuffer(atrHandle, 0, 0, 1, atrArray) <= 0)
   {
      Print("Error copying ATR data: ", GetLastError());
      return 0;
   }
   
   return atrArray[0];
}

//+------------------------------------------------------------------+
//| Open Trade                                                       |
//+------------------------------------------------------------------+
void OpenTrade(ENUM_ORDER_TYPE type)
{
   double atr = GetATR();
   if(atr == 0)
   {
      Print("Error: ATR value is zero, cannot open trade");
      return;
   }
   
   double price = (type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl = 0, tp = 0;
   
   // Calculate SL and TP based on ATR multiplier
   if(SL_ATR_Multi > 0)
   {
      if(type == ORDER_TYPE_BUY)
         sl = price - (atr * SL_ATR_Multi);
      else
         sl = price + (atr * SL_ATR_Multi);
   }
   
   if(TP_ATR_Multi > 0)
   {
      if(type == ORDER_TYPE_BUY)
         tp = price + (atr * TP_ATR_Multi);
      else
         tp = price - (atr * TP_ATR_Multi);
   }
   
   // Normalize prices
   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);
   
   // Send order
   if(trade.PositionOpen(_Symbol, type, Lots, price, sl, tp, Commentary))
   {
      Print("Position opened: ", EnumToString(type), " at ", price, " | SL: ", sl, " | TP: ", tp, " | ATR: ", atr);
   }
   else
   {
      Print("Error opening position: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Close All Positions of Type                                      |
//+------------------------------------------------------------------+
void CloseAllPositions(ENUM_POSITION_TYPE type)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
            PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
            PositionGetInteger(POSITION_TYPE) == type)
         {
            if(trade.PositionClose(ticket))
            {
               Print("Position closed: ", ticket);
            }
            else
            {
               Print("Error closing position: ", trade.ResultRetcode());
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check if position exists                                         |
//+------------------------------------------------------------------+
bool HasPosition(ENUM_POSITION_TYPE type)
{
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
            PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
            PositionGetInteger(POSITION_TYPE) == type)
         {
            return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Manage Trailing Stops                                           |
//+------------------------------------------------------------------+
void ManageTrailingStops()
{
   double atr = GetATR();
   if(atr == 0)
      return;
   
   double trailingDistance = atr * Trail_ATR_Multi;
   
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
            PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         {
            ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double posOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double posSL = PositionGetDouble(POSITION_SL);
            double currentPrice = (posType == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            
            double profit = 0;
            if(posType == POSITION_TYPE_BUY)
               profit = currentPrice - posOpenPrice;
            else
               profit = posOpenPrice - currentPrice;
            
            // Check if position is in profit (at least 1 ATR)
            if(profit >= atr)
            {
               double newSL = 0;
               
               if(posType == POSITION_TYPE_BUY)
               {
                  newSL = currentPrice - trailingDistance;
                  newSL = NormalizeDouble(newSL, _Digits);
                  
                  // Only modify if new SL is better (higher than current SL)
                  if(newSL > posSL + TrailingStep * _Point || posSL == 0)
                  {
                     if(trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP)))
                     {
                        Print("Trailing stop updated for BUY position: ", ticket, " New SL: ", newSL, " (ATR: ", atr, ")");
                     }
                  }
               }
               else // SELL
               {
                  newSL = currentPrice + trailingDistance;
                  newSL = NormalizeDouble(newSL, _Digits);
                  
                  // Only modify if new SL is better (lower than current SL)
                  if(newSL < posSL - TrailingStep * _Point || posSL == 0)
                  {
                     if(trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP)))
                     {
                        Print("Trailing stop updated for SELL position: ", ticket, " New SL: ", newSL, " (ATR: ", atr, ")");
                     }
                  }
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+