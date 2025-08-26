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
//+------------------------------------------------------------------+
bool Is_Buy_Pullback_Zone(int bb_period = 20, double bb_deviations = 2.0, int rsi_period = 14, int rsi_buy_min = 40, int rsi_buy_max = 55)
{
    // Create indicators for H4 timeframe
    int handle_bb = iBands(Symbol(), PERIOD_H4, bb_period, 0, bb_deviations, PRICE_CLOSE);
    int handle_rsi = iRSI(Symbol(), PERIOD_H4, rsi_period, PRICE_CLOSE);
    
    if(handle_bb == INVALID_HANDLE || handle_rsi == INVALID_HANDLE)
        return false;
    
    // Get indicator values (Added Upper BB for tolerance calculation)
    double bb_upper_buffer[2];
    double bb_lower_buffer[2];
    double rsi_buffer[2];
    
    if(CopyBuffer(handle_bb, 1, 1, 1, bb_upper_buffer) <= 0 ||  // Buffer 1 = Upper Band
       CopyBuffer(handle_bb, 2, 1, 1, bb_lower_buffer) <= 0 ||  // Buffer 2 = Lower Band
       CopyBuffer(handle_rsi, 0, 1, 1, rsi_buffer) <= 0)
        return false;
    
    double h4_low = iLow(Symbol(), PERIOD_H4, 1);
    double h4_upper_bb = bb_upper_buffer[0];
    double h4_lower_bb = bb_lower_buffer[0];
    double h4_rsi = rsi_buffer[0];
    
    // Buy pullback zone conditions (RELAXED):
    // 1. H4 Low is within 30% of BB range above Lower Band (instead of touching exactly)
    // 2. RSI is within buy range (rsi_buy_min to rsi_buy_max)
    double bb_range = h4_upper_bb - h4_lower_bb;
    double bb_tolerance = bb_range * 0.3; // 30% tolerance
    bool near_lower_bb = (h4_low <= (h4_lower_bb + bb_tolerance));
    
    return near_lower_bb && (h4_rsi >= rsi_buy_min && h4_rsi <= rsi_buy_max);
}

//+------------------------------------------------------------------+
//| Check if current market is in sell pullback zone               |
//| Parameters: bb_period, bb_deviations, rsi_period, rsi_sell_min, rsi_sell_max |
//| Returns: true if sell pullback conditions met, false otherwise  |
//+------------------------------------------------------------------+
bool Is_Sell_Pullback_Zone(int bb_period = 20, double bb_deviations = 2.0, int rsi_period = 14, int rsi_sell_min = 45, int rsi_sell_max = 60)
{
    // Create indicators for H4 timeframe
    int handle_bb = iBands(Symbol(), PERIOD_H4, bb_period, 0, bb_deviations, PRICE_CLOSE);
    int handle_rsi = iRSI(Symbol(), PERIOD_H4, rsi_period, PRICE_CLOSE);
    
    if(handle_bb == INVALID_HANDLE || handle_rsi == INVALID_HANDLE)
        return false;
    
    // Get indicator values (Added Lower BB for tolerance calculation)
    double bb_upper_buffer[2];
    double bb_lower_buffer[2];
    double rsi_buffer[2];
    
    if(CopyBuffer(handle_bb, 1, 1, 1, bb_upper_buffer) <= 0 ||  // Buffer 1 = Upper Band
       CopyBuffer(handle_bb, 2, 1, 1, bb_lower_buffer) <= 0 ||  // Buffer 2 = Lower Band
       CopyBuffer(handle_rsi, 0, 1, 1, rsi_buffer) <= 0)
        return false;
    
    double h4_high = iHigh(Symbol(), PERIOD_H4, 1);
    double h4_upper_bb = bb_upper_buffer[0];
    double h4_lower_bb = bb_lower_buffer[0];
    double h4_rsi = rsi_buffer[0];
    
    // Sell pullback zone conditions (RELAXED):
    // 1. H4 High is within 30% of BB range below Upper Band (instead of touching exactly)
    // 2. RSI is within sell range (rsi_sell_min to rsi_sell_max)
    double bb_range = h4_upper_bb - h4_lower_bb;
    double bb_tolerance = bb_range * 0.3; // 30% tolerance
    bool near_upper_bb = (h4_high >= (h4_upper_bb - bb_tolerance));
    
    return near_upper_bb && (h4_rsi >= rsi_sell_min && h4_rsi <= rsi_sell_max);
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
