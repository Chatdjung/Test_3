//+------------------------------------------------------------------+
//|                                                02_Analysis.mqh |
//|                                                       Chatchai.D |
//|                                   With-Trend Pullback Strategy  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Market Analysis Functions                                        |
//| Contains trend analysis and pullback zone detection functions   |
//| Parameters are declared in main .mq5 file                       |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Trend Analysis Functions (D1 Timeframe)                         |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Determine if market is in bullish trend on D1                   |
//| Parameters: ema_fast_period, ema_slow_period                    |
//| Returns: true if bullish trend detected, false otherwise        |
//+------------------------------------------------------------------+
bool Is_Bullish_Trend(int ema_fast_period = 13, int ema_slow_period = 39)
{
    // Create MA indicators for D1 timeframe
    int handle_ema13 = iMA(Symbol(), PERIOD_D1, ema_fast_period, 0, MODE_EMA, PRICE_CLOSE);
    int handle_ema39 = iMA(Symbol(), PERIOD_D1, ema_slow_period, 0, MODE_EMA, PRICE_CLOSE);
    
    if(handle_ema13 == INVALID_HANDLE || handle_ema39 == INVALID_HANDLE)
        return false;
    
    // Get indicator values
    double ema13_buffer[2];
    double ema39_buffer[2];
    
    if(CopyBuffer(handle_ema13, 0, 1, 1, ema13_buffer) <= 0 ||
       CopyBuffer(handle_ema39, 0, 1, 1, ema39_buffer) <= 0)
        return false;
    
    double d1_ema13 = ema13_buffer[0];
    double d1_ema39 = ema39_buffer[0];
    double d1_close = iClose(Symbol(), PERIOD_D1, 1);
    
    // Bullish trend conditions:
    // 1. Fast EMA > Slow EMA (EMA13 > EMA39)
    // 2. Price closed above Slow EMA (Close > EMA39)
    return (d1_ema13 > d1_ema39) && (d1_close > d1_ema39);
}

//+------------------------------------------------------------------+
//| Determine if market is in bearish trend on D1                   |
//| Parameters: ema_fast_period, ema_slow_period                    |
//| Returns: true if bearish trend detected, false otherwise        |
//+------------------------------------------------------------------+
bool Is_Bearish_Trend(int ema_fast_period = 13, int ema_slow_period = 39)
{
    // Create MA indicators for D1 timeframe
    int handle_ema13 = iMA(Symbol(), PERIOD_D1, ema_fast_period, 0, MODE_EMA, PRICE_CLOSE);
    int handle_ema39 = iMA(Symbol(), PERIOD_D1, ema_slow_period, 0, MODE_EMA, PRICE_CLOSE);
    
    if(handle_ema13 == INVALID_HANDLE || handle_ema39 == INVALID_HANDLE)
        return false;
    
    // Get indicator values
    double ema13_buffer[2];
    double ema39_buffer[2];
    
    if(CopyBuffer(handle_ema13, 0, 1, 1, ema13_buffer) <= 0 ||
       CopyBuffer(handle_ema39, 0, 1, 1, ema39_buffer) <= 0)
        return false;
    
    double d1_ema13 = ema13_buffer[0];
    double d1_ema39 = ema39_buffer[0];
    double d1_close = iClose(Symbol(), PERIOD_D1, 1);
    
    // Bearish trend conditions:
    // 1. Fast EMA < Slow EMA (EMA13 < EMA39)
    // 2. Price closed below Slow EMA (Close < EMA39)
    return (d1_ema13 < d1_ema39) && (d1_close < d1_ema39);
}

//+------------------------------------------------------------------+
//| Pullback Zone Analysis Functions (H4 Timeframe)                 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Check if current market is in buy pullback zone                 |
//| Parameters: bb_period, bb_deviations, rsi_period, rsi_buy_min, rsi_buy_max |
//| Returns: true if buy pullback conditions met, false otherwise   |
//| UPDATED: Now includes Multi-Timeframe RSI check as per PRD.md   |
//+------------------------------------------------------------------+
bool Is_Buy_Pullback_Zone(int bb_period = 20, double bb_deviations = 2.0, int rsi_period = 14, int rsi_buy_min = 40, int rsi_buy_max = 55)
{
    Print("=== BUY PULLBACK ZONE CHECK ===");
    
    // Create indicators for H4 timeframe
    int handle_bb = iBands(Symbol(), PERIOD_H4, bb_period, 0, bb_deviations, PRICE_CLOSE);
    int handle_rsi = iRSI(Symbol(), PERIOD_H4, rsi_period, PRICE_CLOSE);
    
    if(handle_bb == INVALID_HANDLE || handle_rsi == INVALID_HANDLE)
    {
        Print("ERROR: Failed to create H4 indicators");
        return false;
    }
    
    // Get indicator values (Added Upper BB for tolerance calculation)
    double bb_upper_buffer[2];
    double bb_lower_buffer[2];
    double rsi_buffer[2];
    
    if(CopyBuffer(handle_bb, 1, 1, 1, bb_upper_buffer) <= 0 ||  // Buffer 1 = Upper Band
       CopyBuffer(handle_bb, 2, 1, 1, bb_lower_buffer) <= 0 ||  // Buffer 2 = Lower Band
       CopyBuffer(handle_rsi, 0, 1, 1, rsi_buffer) <= 0)
    {
        Print("ERROR: Failed to copy H4 indicator buffers");
        return false;
    }
    
    double h4_low = iLow(Symbol(), PERIOD_H4, 1);
    double h4_upper_bb = bb_upper_buffer[0];
    double h4_lower_bb = bb_lower_buffer[0];
    double h4_rsi = rsi_buffer[0];
    
    // 1. Check Bollinger Band pullback condition
    double bb_range = h4_upper_bb - h4_lower_bb;
    double bb_tolerance = bb_range * 0.3; // 30% tolerance
    bool near_lower_bb = (h4_low <= (h4_lower_bb + bb_tolerance));
    
    Print("H4 Bollinger Band Check:");
    Print("  H4 Low: ", h4_low);
    Print("  Lower BB: ", h4_lower_bb);
    Print("  BB Tolerance: ", bb_tolerance);
    Print("  Near Lower BB: ", (near_lower_bb ? "✓ YES" : "✗ NO"));
    
    // 2. Check H4 RSI condition (original logic)
    bool h4_rsi_ok = (h4_rsi >= rsi_buy_min && h4_rsi <= rsi_buy_max);
    Print("H4 RSI Check:");
    Print("  H4 RSI: ", DoubleToString(h4_rsi, 2));
    Print("  Range: ", rsi_buy_min, "-", rsi_buy_max);
    Print("  H4 RSI OK: ", (h4_rsi_ok ? "✓ YES" : "✗ NO"));
    
    // 3. NEW: Check Multi-Timeframe RSI condition (as per PRD.md)
    // RSI M15, M5, M1 must all be < 35 (oversold) for BUY signal
    bool multi_tf_oversold = Is_Multi_TF_Oversold(rsi_period, 35.0);
    Print("Multi-TF RSI Check: ", (multi_tf_oversold ? "✅ ALL OVERSOLD" : "❌ NOT ALL OVERSOLD"));
    
    // All conditions must be met
    bool all_conditions = near_lower_bb && h4_rsi_ok && multi_tf_oversold;
    
    Print("=== BUY PULLBACK ZONE RESULT ===");
    Print("  BB Pullback: ", (near_lower_bb ? "✓" : "✗"));
    Print("  H4 RSI Range: ", (h4_rsi_ok ? "✓" : "✗"));
    Print("  Multi-TF Oversold: ", (multi_tf_oversold ? "✓" : "✗"));
    Print("  FINAL RESULT: ", (all_conditions ? "✅ PASS" : "❌ FAIL"));
    Print("=== BUY PULLBACK ZONE CHECK COMPLETE ===");
    
    return all_conditions;
}

//+------------------------------------------------------------------+
//| Check if current market is in sell pullback zone               |
//| Parameters: bb_period, bb_deviations, rsi_period, rsi_sell_min, rsi_sell_max |
//| Returns: true if sell pullback conditions met, false otherwise  |
//| UPDATED: Now includes Multi-Timeframe RSI check as per PRD.md   |
//+------------------------------------------------------------------+
bool Is_Sell_Pullback_Zone(int bb_period = 20, double bb_deviations = 2.0, int rsi_period = 14, int rsi_sell_min = 45, int rsi_sell_max = 60)
{
    Print("=== SELL PULLBACK ZONE CHECK ===");
    
    // Create indicators for H4 timeframe
    int handle_bb = iBands(Symbol(), PERIOD_H4, bb_period, 0, bb_deviations, PRICE_CLOSE);
    int handle_rsi = iRSI(Symbol(), PERIOD_H4, rsi_period, PRICE_CLOSE);
    
    if(handle_bb == INVALID_HANDLE || handle_rsi == INVALID_HANDLE)
    {
        Print("ERROR: Failed to create H4 indicators");
        return false;
    }
    
    // Get indicator values (Added Lower BB for tolerance calculation)
    double bb_upper_buffer[2];
    double bb_lower_buffer[2];
    double rsi_buffer[2];
    
    if(CopyBuffer(handle_bb, 1, 1, 1, bb_upper_buffer) <= 0 ||  // Buffer 1 = Upper Band
       CopyBuffer(handle_bb, 2, 1, 1, bb_lower_buffer) <= 0 ||  // Buffer 2 = Lower Band
       CopyBuffer(handle_rsi, 0, 1, 1, rsi_buffer) <= 0)
    {
        Print("ERROR: Failed to copy H4 indicator buffers");
        return false;
    }
    
    double h4_high = iHigh(Symbol(), PERIOD_H4, 1);
    double h4_upper_bb = bb_upper_buffer[0];
    double h4_lower_bb = bb_lower_buffer[0];
    double h4_rsi = rsi_buffer[0];
    
    // 1. Check Bollinger Band pullback condition
    double bb_range = h4_upper_bb - h4_lower_bb;
    double bb_tolerance = bb_range * 0.3; // 30% tolerance
    bool near_upper_bb = (h4_high >= (h4_upper_bb - bb_tolerance));
    
    Print("H4 Bollinger Band Check:");
    Print("  H4 High: ", h4_high);
    Print("  Upper BB: ", h4_upper_bb);
    Print("  BB Tolerance: ", bb_tolerance);
    Print("  Near Upper BB: ", (near_upper_bb ? "✓ YES" : "✗ NO"));
    
    // 2. Check H4 RSI condition (original logic)
    bool h4_rsi_ok = (h4_rsi >= rsi_sell_min && h4_rsi <= rsi_sell_max);
    Print("H4 RSI Check:");
    Print("  H4 RSI: ", DoubleToString(h4_rsi, 2));
    Print("  Range: ", rsi_sell_min, "-", rsi_sell_max);
    Print("  H4 RSI OK: ", (h4_rsi_ok ? "✓ YES" : "✗ NO"));
    
    // 3. NEW: Check Multi-Timeframe RSI condition (as per PRD.md)
    // RSI M15, M5, M1 must all be > 65 (overbought) for SELL signal
    bool multi_tf_overbought = Is_Multi_TF_Overbought(rsi_period, 65.0);
    Print("Multi-TF RSI Check: ", (multi_tf_overbought ? "✅ ALL OVERBOUGHT" : "❌ NOT ALL OVERBOUGHT"));
    
    // All conditions must be met
    bool all_conditions = near_upper_bb && h4_rsi_ok && multi_tf_overbought;
    
    Print("=== SELL PULLBACK ZONE RESULT ===");
    Print("  BB Pullback: ", (near_upper_bb ? "✓" : "✗"));
    Print("  H4 RSI Range: ", (h4_rsi_ok ? "✓" : "✗"));
    Print("  Multi-TF Overbought: ", (multi_tf_overbought ? "✓" : "✗"));
    Print("  FINAL RESULT: ", (all_conditions ? "✅ PASS" : "❌ FAIL"));
    Print("=== SELL PULLBACK ZONE CHECK COMPLETE ===");
    
    return all_conditions;
}

//+------------------------------------------------------------------+
//| Candlestick Pattern Recognition Functions (H4 Timeframe)        |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Check for Bullish Engulfing pattern                             |
//| Parameters: shift - candle position (1 = previous candle)       |
//| Returns: true if bullish engulfing pattern detected             |
//+------------------------------------------------------------------+
bool Is_Bullish_Engulfing(int shift)
{
    // Get OHLC data for current and previous candles
    double prev_open = iOpen(Symbol(), PERIOD_H4, shift + 1);
    double prev_close = iClose(Symbol(), PERIOD_H4, shift + 1);
    double curr_open = iOpen(Symbol(), PERIOD_H4, shift);
    double curr_close = iClose(Symbol(), PERIOD_H4, shift);
    
    // Bullish Engulfing pattern conditions:
    // 1. Previous candle is bearish (red candle)
    // 2. Current candle is bullish (green candle)
    // 3. Current candle's body completely engulfs previous candle's body
    return (prev_close < prev_open) && // Previous candle is bearish
           (curr_close > curr_open) && // Current candle is bullish
           (curr_open < prev_close) && // Current open below previous close
           (curr_close > prev_open);   // Current close above previous open
}

//+------------------------------------------------------------------+
//| Check for Bullish Pin Bar pattern                               |
//| Parameters: shift - candle position (1 = previous candle)       |
//| Returns: true if bullish pin bar pattern detected               |
//+------------------------------------------------------------------+
bool Is_Bullish_PinBar(int shift)
{
    // Get OHLC data for the candle
    double open = iOpen(Symbol(), PERIOD_H4, shift);
    double high = iHigh(Symbol(), PERIOD_H4, shift);
    double low = iLow(Symbol(), PERIOD_H4, shift);
    double close = iClose(Symbol(), PERIOD_H4, shift);
    
    // Calculate candle components
    double body = MathAbs(close - open);
    double upper_shadow = high - MathMax(open, close);
    double lower_shadow = MathMin(open, close) - low;
    
    // Bullish Pin Bar pattern conditions:
    // 1. Lower shadow is at least 2 times larger than body (long tail below)
    // 2. Upper shadow is less than half of body (small tail above)
    // This indicates rejection at lower levels and potential bullish reversal
    return (lower_shadow > body * 2) && (upper_shadow < body * 0.5);
}

//+------------------------------------------------------------------+
//| Check for Bearish Engulfing pattern                             |
//| Parameters: shift - candle position (1 = previous candle)       |
//| Returns: true if bearish engulfing pattern detected             |
//+------------------------------------------------------------------+
bool Is_Bearish_Engulfing(int shift)
{
    // Get OHLC data for current and previous candles
    double prev_open = iOpen(Symbol(), PERIOD_H4, shift + 1);
    double prev_close = iClose(Symbol(), PERIOD_H4, shift + 1);
    double curr_open = iOpen(Symbol(), PERIOD_H4, shift);
    double curr_close = iClose(Symbol(), PERIOD_H4, shift);
    
    // Bearish Engulfing pattern conditions:
    // 1. Previous candle is bullish (green candle)
    // 2. Current candle is bearish (red candle)
    // 3. Current candle's body completely engulfs previous candle's body
    return (prev_close > prev_open) && // Previous candle is bullish
           (curr_close < curr_open) && // Current candle is bearish
           (curr_open > prev_close) && // Current open above previous close
           (curr_close < prev_open);   // Current close below previous open
}

//+------------------------------------------------------------------+
//| Check for Shooting Star pattern                                 |
//| Parameters: shift - candle position (1 = previous candle)       |
//| Returns: true if shooting star pattern detected                 |
//+------------------------------------------------------------------+
bool Is_Shooting_Star(int shift)
{
    // Get OHLC data for the candle
    double open = iOpen(Symbol(), PERIOD_H4, shift);
    double high = iHigh(Symbol(), PERIOD_H4, shift);
    double low = iLow(Symbol(), PERIOD_H4, shift);
    double close = iClose(Symbol(), PERIOD_H4, shift);
    
    // Calculate candle components
    double body = MathAbs(close - open);
    double upper_shadow = high - MathMax(open, close);
    double lower_shadow = MathMin(open, close) - low;
    
    // Shooting Star pattern conditions:
    // 1. Upper shadow is at least 2 times larger than body (long tail above)
    // 2. Lower shadow is less than half of body (small tail below)
    // This indicates rejection at higher levels and potential bearish reversal
    return (upper_shadow > body * 2) && (lower_shadow < body * 0.5);
}

//+------------------------------------------------------------------+
//| Multi-Timeframe RSI Analysis Functions                          |
//| Added to implement PRD.md strategy requirements                 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Get Multi-Timeframe RSI Values                                 |
//| Parameters: rsi_period - RSI calculation period                 |
//| Returns: true if all RSI values successfully retrieved          |
//| Output: Sets rsi_m15, rsi_m5, rsi_m1 by reference             |
//+------------------------------------------------------------------+
bool Get_Multi_Timeframe_RSI(int rsi_period, double &rsi_m15, double &rsi_m5, double &rsi_m1)
{
    // Initialize output values
    rsi_m15 = 0.0;
    rsi_m5 = 0.0;
    rsi_m1 = 0.0;
    
    // Create RSI indicators for each timeframe
    int handle_rsi_m15 = iRSI(Symbol(), PERIOD_M15, rsi_period, PRICE_CLOSE);
    int handle_rsi_m5 = iRSI(Symbol(), PERIOD_M5, rsi_period, PRICE_CLOSE);
    int handle_rsi_m1 = iRSI(Symbol(), PERIOD_M1, rsi_period, PRICE_CLOSE);
    
    // Check if handles are valid
    if(handle_rsi_m15 == INVALID_HANDLE || handle_rsi_m5 == INVALID_HANDLE || handle_rsi_m1 == INVALID_HANDLE)
    {
        Print("ERROR: Failed to create RSI handles for multi-timeframe analysis");
        return false;
    }
    
    // Buffers for RSI values
    double rsi_m15_buffer[2];
    double rsi_m5_buffer[2];
    double rsi_m1_buffer[2];
    
    // Get RSI values from completed bars (shift=1) to prevent repainting
    if(CopyBuffer(handle_rsi_m15, 0, 1, 1, rsi_m15_buffer) <= 0 ||
       CopyBuffer(handle_rsi_m5, 0, 1, 1, rsi_m5_buffer) <= 0 ||
       CopyBuffer(handle_rsi_m1, 0, 1, 1, rsi_m1_buffer) <= 0)
    {
        Print("ERROR: Failed to copy RSI buffers for multi-timeframe analysis");
        return false;
    }
    
    // Set output values
    rsi_m15 = rsi_m15_buffer[0];
    rsi_m5 = rsi_m5_buffer[0];
    rsi_m1 = rsi_m1_buffer[0];
    
    // Debug logging
    Print("DEBUG: Multi-TF RSI Values - M15: ", DoubleToString(rsi_m15, 2), 
          ", M5: ", DoubleToString(rsi_m5, 2), 
          ", M1: ", DoubleToString(rsi_m1, 2));
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if Multi-Timeframe RSI is in Oversold Zone (for BUY)     |
//| Parameters: rsi_period, oversold_level                         |
//| Returns: true if RSI < oversold_level in M15, M5, M1           |
//+------------------------------------------------------------------+
bool Is_Multi_TF_Oversold(int rsi_period = 14, double oversold_level = 35.0)
{
    Print("=== MULTI-TIMEFRAME RSI OVERSOLD CHECK ===");
    
    double rsi_m15, rsi_m5, rsi_m1;
    
    // Get RSI values from all timeframes
    if(!Get_Multi_Timeframe_RSI(rsi_period, rsi_m15, rsi_m5, rsi_m1))
    {
        Print("ERROR: Failed to get multi-timeframe RSI values");
        return false;
    }
    
    // Check oversold condition for each timeframe
    bool m15_oversold = (rsi_m15 < oversold_level);
    bool m5_oversold = (rsi_m5 < oversold_level);
    bool m1_oversold = (rsi_m1 < oversold_level);
    
    // Detailed logging for each timeframe
    Print("RSI Oversold Check (< ", oversold_level, "):");
    Print("  M15 RSI: ", DoubleToString(rsi_m15, 2), " - ", (m15_oversold ? "✓ OVERSOLD" : "✗ Not Oversold"));
    Print("  M5 RSI:  ", DoubleToString(rsi_m5, 2), " - ", (m5_oversold ? "✓ OVERSOLD" : "✗ Not Oversold"));
    Print("  M1 RSI:  ", DoubleToString(rsi_m1, 2), " - ", (m1_oversold ? "✓ OVERSOLD" : "✗ Not Oversold"));
    
    // All timeframes must be oversold
    bool all_oversold = (m15_oversold && m5_oversold && m1_oversold);
    
    Print("Multi-TF Oversold Result: ", (all_oversold ? "✅ ALL OVERSOLD" : "❌ CONDITIONS NOT MET"));
    Print("=== MULTI-TIMEFRAME OVERSOLD CHECK COMPLETE ===");
    
    return all_oversold;
}

//+------------------------------------------------------------------+
//| Check if Multi-Timeframe RSI is in Overbought Zone (for SELL)  |
//| Parameters: rsi_period, overbought_level                       |
//| Returns: true if RSI > overbought_level in M15, M5, M1         |
//+------------------------------------------------------------------+
bool Is_Multi_TF_Overbought(int rsi_period = 14, double overbought_level = 65.0)
{
    Print("=== MULTI-TIMEFRAME RSI OVERBOUGHT CHECK ===");
    
    double rsi_m15, rsi_m5, rsi_m1;
    
    // Get RSI values from all timeframes
    if(!Get_Multi_Timeframe_RSI(rsi_period, rsi_m15, rsi_m5, rsi_m1))
    {
        Print("ERROR: Failed to get multi-timeframe RSI values");
        return false;
    }
    
    // Check overbought condition for each timeframe
    bool m15_overbought = (rsi_m15 > overbought_level);
    bool m5_overbought = (rsi_m5 > overbought_level);
    bool m1_overbought = (rsi_m1 > overbought_level);
    
    // Detailed logging for each timeframe
    Print("RSI Overbought Check (> ", overbought_level, "):");
    Print("  M15 RSI: ", DoubleToString(rsi_m15, 2), " - ", (m15_overbought ? "✓ OVERBOUGHT" : "✗ Not Overbought"));
    Print("  M5 RSI:  ", DoubleToString(rsi_m5, 2), " - ", (m5_overbought ? "✓ OVERBOUGHT" : "✗ Not Overbought"));
    Print("  M1 RSI:  ", DoubleToString(rsi_m1, 2), " - ", (m1_overbought ? "✓ OVERBOUGHT" : "✗ Not Overbought"));
    
    // All timeframes must be overbought
    bool all_overbought = (m15_overbought && m5_overbought && m1_overbought);
    
    Print("Multi-TF Overbought Result: ", (all_overbought ? "✅ ALL OVERBOUGHT" : "❌ CONDITIONS NOT MET"));
    Print("=== MULTI-TIMEFRAME OVERBOUGHT CHECK COMPLETE ===");
    
    return all_overbought;
}

//+------------------------------------------------------------------+
