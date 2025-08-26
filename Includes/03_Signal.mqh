//+------------------------------------------------------------------+
//|                                                    03_Signal.mqh |
//|                                                       Chatchai.D |
//|                                   With-Trend Pullback Strategy  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Include necessary files                                          |
//+------------------------------------------------------------------+
#include "02_Analysis.mqh"

//+------------------------------------------------------------------+
//| Signal Generation Functions                                      |
//| Contains buy and sell signal logic combining all analysis       |
//| Parameters are declared in main .mq5 file                       |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Check for Buy Signal conditions                                 |
//| Parameters: All analysis parameters                             |
//| Returns: true if all buy conditions are met, false otherwise    |
//+------------------------------------------------------------------+
bool Check_Buy_Signal(int ema_fast_period = 13, int ema_slow_period = 39, int bb_period = 20, double bb_deviations = 2.0, int rsi_period = 14, int rsi_buy_min = 40, int rsi_buy_max = 55)
{
    // LOG: Checking Buy Signal Conditions
    Print("=== BUY SIGNAL CHECK ===");
    
    // 1. Trend Filter (D1) - Must be in bullish trend
    if (!Is_Bullish_Trend(ema_fast_period, ema_slow_period))
    {
        Print("LOG: Trend filter failed - D1 not bullish");
        return false;
    }
    Print("LOG: Trend filter passed - D1 is bullish");
    
    // 2. Pullback Zone (H4) - Must be in buy pullback zone
    if (!Is_Buy_Pullback_Zone(bb_period, bb_deviations, rsi_period, rsi_buy_min, rsi_buy_max))
    {
        Print("LOG: Pullback zone check failed");
        return false;
    }
    Print("LOG: Pullback zone check passed");
    
    // 3. Confirmation (H4 Previous Candle) - TEMPORARILY DISABLED FOR TESTING
    bool has_confirmation = true; // Is_Bullish_Engulfing(1) || Is_Bullish_PinBar(1);
    if (!has_confirmation)
    {
        Print("LOG: Confirmation pattern not found");
        return false;
    }
    Print("LOG: Confirmation pattern check DISABLED for testing - All patterns accepted");
    
    // LOG: Save trade context for debugging
    double h4_rsi = 0; // Will get from RSI calculation in pullback function
    Print("LOG: Entry_Signal=Engulfing/PinBar, All_Conditions_Met=TRUE");
    
    // All conditions met - Generate Buy Signal
    Print("=== BUY SIGNAL CONFIRMED ===");
    return true;
}

//+------------------------------------------------------------------+
//| Check for Sell Signal conditions                                |
//| Parameters: All analysis parameters                             |
//| Returns: true if all sell conditions are met, false otherwise   |
//+------------------------------------------------------------------+
bool Check_Sell_Signal(int ema_fast_period = 13, int ema_slow_period = 39, int bb_period = 20, double bb_deviations = 2.0, int rsi_period = 14, int rsi_sell_min = 45, int rsi_sell_max = 60)
{
    // LOG: Checking Sell Signal Conditions
    Print("=== SELL SIGNAL CHECK ===");
    
    // 1. Trend Filter (D1) - Must be in bearish trend
    if (!Is_Bearish_Trend(ema_fast_period, ema_slow_period))
    {
        Print("LOG: Trend filter failed - D1 not bearish");
        return false;
    }
    Print("LOG: Trend filter passed - D1 is bearish");
    
    // 2. Pullback Zone (H4) - Must be in sell pullback zone
    if (!Is_Sell_Pullback_Zone(bb_period, bb_deviations, rsi_period, rsi_sell_min, rsi_sell_max))
    {
        Print("LOG: Pullback zone check failed");
        return false;
    }
    Print("LOG: Pullback zone check passed");
    
    // 3. Confirmation (H4 Previous Candle) - TEMPORARILY DISABLED FOR TESTING
    bool has_confirmation = true; // Is_Bearish_Engulfing(1) || Is_Shooting_Star(1);
    if (!has_confirmation)
    {
        Print("LOG: Confirmation pattern not found");
        return false;
    }
    Print("LOG: Confirmation pattern check DISABLED for testing - All patterns accepted");
    
    // LOG: Save trade context for debugging
    double h4_rsi = 0; // Will get from RSI calculation in pullback function
    Print("LOG: Entry_Signal=Engulfing/ShootingStar, All_Conditions_Met=TRUE");
    
    // All conditions met - Generate Sell Signal
    Print("=== SELL SIGNAL CONFIRMED ===");
    return true;
}

//+------------------------------------------------------------------+
