Process Requirement Document (PRD) - (Revised Edition)
เอกสารข้อกำหนดกระบวนการ - (ฉบับปรับปรุง)
Expert Advisor: With-Trend Pullback Strategy for XAUUSD
EA: กลยุทธ์เทรดตามเทรนด์พร้อมการกลับตัวสำหรับทองคำ
1. Executive Summary / สรุปผู้บริหาร
1.1 Project Objective / เป้าหมายโครงการ

สร้าง Expert Advisor (EA) สำหรับเทรดทองคำ (XAUUSD) บนแพลตฟอร์ม MetaTrader 5 โดยใช้กลยุทธ์ "With-Trend Pullback Strategy" ที่รวมการวิเคราะห์เทรนด์ระดับ D1 และสัญญาณการกลับตัวระดับ H4

1.2 Tech Stack / เทคโนโลยีที่ใช้

Platform: MetaTrader 5 (MT5)
Language: MQL5
Symbol: XAUUSD (Gold)
Timeframes: D1 (Trend Analysis), H4 (Entry Signals)
Testing: Strategy Tester with Optimization Module
2. Architectural Principles & Design Philosophy / สถาปัตยกรรมและปรัชญาการออกแบบ
เพื่อให้แน่ใจว่า EA สามารถดูแลรักษา, ทดสอบ, และต่อยอดได้ง่ายในระยะยาว โครงการนี้จะถูกพัฒนาภายใต้สถาปัตยกรรมแบบ Modular Design อย่างเคร่งครัด

2.1 Modular Structure (.mqh Include Files) / โครงสร้างแบบโมดูล

ซอร์สโค้ดทั้งหมดจะถูกแบ่งตามหน้าที่การทำงานออกเป็นไฟล์ย่อยๆ (Include Files นามสกุล .mqh) อย่างชัดเจน โดยไฟล์ .mq5 หลักจะทำหน้าที่เป็นเพียงจุดเริ่มต้น (Entry Point) และตัวควบคุมระดับสูง (High-level Controller) เท่านั้น

2.2 Proposed File Structure / โครงสร้างไฟล์ที่เสนอ

โปรเจกต์จะถูกจัดระเบียบตามโครงสร้างดังนี้:

/MyEaProject
|-- GoldTraderEA.mq5      <-- ไฟล์หลัก
|-- /Includes             <-- โฟลเดอร์สำหรับเก็บโมดูล
|   |-- 01_Parameters.mqh   (เก็บ Input Parameters ทั้งหมด)
|   |-- 02_Analysis.mqh       (เก็บฟังก์ชันวิเคราะห์ตลาด: Trend, Pullback, Candle Patterns)
|   |-- 03_Signal.mqh         (เก็บฟังก์ชันสร้างสัญญาณเข้าเทรด: Check_Buy/Sell_Signal)
|   |-- 04_Execution.mqh      (เก็บฟังก์ชันส่งคำสั่งเทรดและคำนวณขนาด Lot, SL, TP)
|   |-- 05_Management.mqh     (เก็บฟังก์ชันจัดการออเดอร์ที่เปิดอยู่ เช่น Trailing Stop)
|   |-- 06_Logging.mqh        (เก็บฟังก์ชันสำหรับบันทึกข้อมูลและจัดการ Error)
2.3 Single Responsibility Principle (SRP) / หลักการรับผิดชอบเพียงสิ่งเดียว

แต่ละฟังก์ชันและแต่ละไฟล์ .mqh จะต้องยึดตามหลักการ SRP อย่างเคร่งครัด กล่าวคือ หนึ่งฟังก์ชันหรือหนึ่งไฟล์จะรับผิดชอบหน้าที่หลักเพียงอย่างเดียวเท่านั้น ตัวอย่างเช่น 04_Execution.mqh จะรับผิดชอบเฉพาะการส่งคำสั่งเทรด จะไม่มีตรรกะการวิเคราะห์ตลาดปะปนอยู่

2.4 Role of the Main .mq5 File / บทบาทของไฟล์หลัก

ไฟล์ GoldTraderEA.mq5 ควรมีโค้ดตรรกะน้อยที่สุด หน้าที่หลักของมันคือ:

เรียกใช้โมดูลต่างๆ ด้วยคำสั่ง #include
เป็นที่อยู่ของฟังก์ชัน Event Handler หลัก (OnInit, OnDeinit, OnTick)
ส่งต่องาน (Delegate) จาก Event Handler ไปยังฟังก์ชันที่เหมาะสมในโมดูลต่างๆ
3. EA Inputs & Parameters / พารามิเตอร์และตัวแปรของ EA
3.1 Static Parameters / พารามิเตอร์คงที่

ข้อมูลโค้ด
// === STATIC PARAMETERS ===
input int EMA_Fast_Period = 13;        // Fast EMA Period
input int EMA_Slow_Period = 39;        // Slow EMA Period
input int RSI_Period = 14;             // RSI Period
input int BB_Period = 20;              // Bollinger Bands Period
input double BB_Deviations = 2.0;      // Bollinger Bands Deviations
input int ATR_Period = 14;             // ATR Period
3.2 Optimizable Parameters / พารามิเตอร์ที่ปรับจูนได้

ข้อมูลโค้ด
// === OPTIMIZABLE PARAMETERS ===
input int RSI_Buy_Min = 40;            // RSI Minimum for Buy Signal
input int RSI_Buy_Max = 55;            // RSI Maximum for Buy Signal
input int RSI_Sell_Min = 45;           // RSI Minimum for Sell Signal
input int RSI_Sell_Max = 60;           // RSI Maximum for Sell Signal
input double ATR_SL_Multiplier = 2.0;  // ATR Multiplier for Stop Loss
input double Risk_Reward_Ratio = 2.0;  // Risk to Reward Ratio
input double Risk_Per_Trade_Percent = 1.0; // Risk per Trade (%)
3.3 Trade Management Parameters / พารามิเตอร์การจัดการออเดอร์

ข้อมูลโค้ด
// === TRADE MANAGEMENT ===
input double Max_Lot_Size = 1.0;       // Maximum Lot Size
input double Min_Lot_Size = 0.01;      // Minimum Lot Size
input int Max_Open_Trades = 1;         // Maximum Open Trades
input bool Enable_Trailing_Stop = false; // Enable Trailing Stop
input double Trailing_Stop_Pips = 50;  // Trailing Stop in Pips
4. Core Trading Logic / ตรรกะการเทรดหลัก
4.1 Market Analysis Functions / ฟังก์ชันการวิเคราะห์ตลาด

4.1.1 Trend Analysis (D1 Timeframe)

ข้อมูลโค้ด
// === TREND FILTER (D1) ===
bool Is_Bullish_Trend()
{
    double d1_ema13 = iMA(Symbol(), PERIOD_D1, EMA_Fast_Period, 0, MODE_EMA, PRICE_CLOSE, 1);
    double d1_ema39 = iMA(Symbol(), PERIOD_D1, EMA_Slow_Period, 0, MODE_EMA, PRICE_CLOSE, 1);
    double d1_close = iClose(Symbol(), PERIOD_D1, 1);
    
    return (d1_ema13 > d1_ema39) && (d1_close > d1_ema39);
}

bool Is_Bearish_Trend()
{
    double d1_ema13 = iMA(Symbol(), PERIOD_D1, EMA_Fast_Period, 0, MODE_EMA, PRICE_CLOSE, 1);
    double d1_ema39 = iMA(Symbol(), PERIOD_D1, EMA_Slow_Period, 0, MODE_EMA, PRICE_CLOSE, 1);
    double d1_close = iClose(Symbol(), PERIOD_D1, 1);
    
    return (d1_ema13 < d1_ema39) && (d1_close < d1_ema39);
}
4.1.2 Pullback Zone Analysis (H4 Timeframe)

ข้อมูลโค้ด
// === PULLBACK ZONE (H4) ===
bool Is_Buy_Pullback_Zone()
{
    double h4_low = iLow(Symbol(), PERIOD_H4, 1);
    double h4_lower_bb = iBands(Symbol(), PERIOD_H4, BB_Period, BB_Deviations, 0, PRICE_CLOSE, MODE_LOWER, 1);
    double h4_rsi = iRSI(Symbol(), PERIOD_H4, RSI_Period, PRICE_CLOSE, 1);
    
    return (h4_low <= h4_lower_bb) && (h4_rsi >= RSI_Buy_Min && h4_rsi <= RSI_Buy_Max);
}

bool Is_Sell_Pullback_Zone()
{
    double h4_high = iHigh(Symbol(), PERIOD_H4, 1);
    double h4_upper_bb = iBands(Symbol(), PERIOD_H4, BB_Period, BB_Deviations, 0, PRICE_CLOSE, MODE_UPPER, 1);
    double h4_rsi = iRSI(Symbol(), PERIOD_H4, RSI_Period, PRICE_CLOSE, 1);
    
    return (h4_high >= h4_upper_bb) && (h4_rsi <= RSI_Sell_Max && h4_rsi >= RSI_Sell_Min);
}
4.1.3 Candlestick Pattern Recognition

ข้อมูลโค้ด
// === CANDLESTICK PATTERNS ===
bool Is_Bullish_Engulfing(int shift)
{
    double prev_open = iOpen(Symbol(), PERIOD_H4, shift + 1);
    double prev_close = iClose(Symbol(), PERIOD_H4, shift + 1);
    double curr_open = iOpen(Symbol(), PERIOD_H4, shift);
    double curr_close = iClose(Symbol(), PERIOD_H4, shift);
    
    return (prev_close < prev_open) && // Previous candle is bearish
           (curr_close > curr_open) && // Current candle is bullish
           (curr_open < prev_close) && // Current open below previous close
           (curr_close > prev_open);   // Current close above previous open
}

bool Is_Bullish_PinBar(int shift)
{
    double open = iOpen(Symbol(), PERIOD_H4, shift);
    double high = iHigh(Symbol(), PERIOD_H4, shift);
    double low = iLow(Symbol(), PERIOD_H4, shift);
    double close = iClose(Symbol(), PERIOD_H4, shift);
    
    double body = MathAbs(close - open);
    double upper_shadow = high - MathMax(open, close);
    double lower_shadow = MathMin(open, close) - low;
    
    return (lower_shadow > body * 2) && (upper_shadow < body * 0.5);
}

bool Is_Bearish_Engulfing(int shift)
{
    double prev_open = iOpen(Symbol(), PERIOD_H4, shift + 1);
    double prev_close = iClose(Symbol(), PERIOD_H4, shift + 1);
    double curr_open = iOpen(Symbol(), PERIOD_H4, shift);
    double curr_close = iClose(Symbol(), PERIOD_H4, shift);
    
    return (prev_close > prev_open) && // Previous candle is bullish
           (curr_close < curr_open) && // Current candle is bearish
           (curr_open > prev_close) && // Current open above previous close
           (curr_close < prev_open);   // Current close below previous open
}

bool Is_Shooting_Star(int shift)
{
    double open = iOpen(Symbol(), PERIOD_H4, shift);
    double high = iHigh(Symbol(), PERIOD_H4, shift);
    double low = iLow(Symbol(), PERIOD_H4, shift);
    double close = iClose(Symbol(), PERIOD_H4, shift);
    
    double body = MathAbs(close - open);
    double upper_shadow = high - MathMax(open, close);
    double lower_shadow = MathMin(open, close) - low;
    
    return (upper_shadow > body * 2) && (lower_shadow < body * 0.5);
}
4.2 Entry Signal Logic / ตรรกะสัญญาณเข้าเทรด

4.2.1 BUY Signal Conditions

ข้อมูลโค้ด
// === BUY SIGNAL LOGIC ===
bool Check_Buy_Signal()
{
    // LOG: Checking Buy Signal Conditions
    Print("=== BUY SIGNAL CHECK ===");
    
    // Trend Filter (D1)
    if (!Is_Bullish_Trend())
    {
        Print("LOG: Trend filter failed - D1 not bullish");
        return false;
    }
    Print("LOG: Trend filter passed - D1 is bullish");
    
    // Pullback Zone (H4)
    if (!Is_Buy_Pullback_Zone())
    {
        Print("LOG: Pullback zone check failed");
        return false;
    }
    Print("LOG: Pullback zone check passed");
    
    // Confirmation (H4 Previous Candle)
    bool has_confirmation = Is_Bullish_Engulfing(1) || Is_Bullish_PinBar(1);
    if (!has_confirmation)
    {
        Print("LOG: Confirmation pattern not found");
        return false;
    }
    Print("LOG: Confirmation pattern found - Bullish Engulfing or PinBar");
    
    // LOG: Save trade context
    double h4_rsi = iRSI(Symbol(), PERIOD_H4, RSI_Period, PRICE_CLOSE, 1);
    Print("LOG: Entry_Signal=Engulfing/PinBar, RSI_Value=", h4_rsi);
    
    return true;
}
4.2.2 SELL Signal Conditions

ข้อมูลโค้ด
// === SELL SIGNAL LOGIC ===
bool Check_Sell_Signal()
{
    // LOG: Checking Sell Signal Conditions
    Print("=== SELL SIGNAL CHECK ===");
    
    // Trend Filter (D1)
    if (!Is_Bearish_Trend())
    {
        Print("LOG: Trend filter failed - D1 not bearish");
        return false;
    }
    Print("LOG: Trend filter passed - D1 is bearish");
    
    // Pullback Zone (H4)
    if (!Is_Sell_Pullback_Zone())
    {
        Print("LOG: Pullback zone check failed");
        return false;
    }
    Print("LOG: Pullback zone check passed");
    
    // Confirmation (H4 Previous Candle)
    bool has_confirmation = Is_Bearish_Engulfing(1) || Is_Shooting_Star(1);
    if (!has_confirmation)
    {
        Print("LOG: Confirmation pattern not found");
        return false;
    }
    Print("LOG: Confirmation pattern found - Bearish Engulfing or Shooting Star");
    
    // LOG: Save trade context
    double h4_rsi = iRSI(Symbol(), PERIOD_H4, RSI_Period, PRICE_CLOSE, 1);
    Print("LOG: Entry_Signal=Engulfing/ShootingStar, RSI_Value=", h4_rsi);
    
    return true;
}
5. Trade Management Logic / ตรรกะการจัดการออเดอร์
5.1 Position Sizing / การคำนวณขนาดออเดอร์

ข้อมูลโค้ด
// === POSITION SIZING ===
double Calculate_Lot_Size(double stop_loss_pips)
{
    double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amount = account_balance * (Risk_Per_Trade_Percent / 100.0);
    
    double tick_value = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
    double tick_size = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
    double point_value = tick_value * (Point() / tick_size);
    
    double lot_size = risk_amount / (stop_loss_pips * point_value);
    
    // Apply lot size constraints
    double min_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
    double lot_step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
    
    lot_size = MathMax(lot_size, Min_Lot_Size);
    lot_size = MathMin(lot_size, Max_Lot_Size);
    lot_size = MathMin(lot_size, max_lot);
    lot_size = MathMax(lot_size, min_lot);
    
    // Round to lot step
    lot_size = NormalizeDouble(lot_size / lot_step, 0) * lot_step;
    
    return lot_size;
}
5.2 Stop Loss Calculation / การคำนวณ Stop Loss

ข้อมูลโค้ด
// === STOP LOSS CALCULATION ===
double Calculate_Stop_Loss(int order_type, double entry_price)
{
    double atr_value = iATR(Symbol(), PERIOD_H4, ATR_Period, 1);
    double atr_distance = atr_value * ATR_SL_Multiplier;
    
    double stop_loss_price;
    
    if (order_type == ORDER_TYPE_BUY)
    {
        // For BUY orders: SL below entry
        double confirmation_low = iLow(Symbol(), PERIOD_H4, 1);
        stop_loss_price = confirmation_low - atr_distance;
    }
    else if (order_type == ORDER_TYPE_SELL)
    {
        // For SELL orders: SL above entry
        double confirmation_high = iHigh(Symbol(), PERIOD_H4, 1);
        stop_loss_price = confirmation_high + atr_distance;
    }
    
    return NormalizeDouble(stop_loss_price, Digits());
}
5.3 Take Profit Calculation / การคำนวณ Take Profit

ข้อมูลโค้ด
// === TAKE PROFIT CALCULATION ===
double Calculate_Take_Profit(int order_type, double entry_price, double stop_loss_price)
{
    double sl_distance = MathAbs(entry_price - stop_loss_price);
    double tp_distance = sl_distance * Risk_Reward_Ratio;
    
    double take_profit_price;
    
    if (order_type == ORDER_TYPE_BUY)
    {
        take_profit_price = entry_price + tp_distance;
    }
    else if (order_type == ORDER_TYPE_SELL)
    {
        take_profit_price = entry_price - tp_distance;
    }
    
    return NormalizeDouble(take_profit_price, Digits());
}
5.4 Order Execution / การส่งออเดอร์

ข้อมูลโค้ด
// === ORDER EXECUTION ===
bool Execute_Trade(int order_type)
{
    double entry_price = (order_type == ORDER_TYPE_BUY) ? SymbolInfoDouble(Symbol(), SYMBOL_ASK) : SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double stop_loss = Calculate_Stop_Loss(order_type, entry_price);
    double take_profit = Calculate_Take_Profit(order_type, entry_price, stop_loss);
    
    double sl_distance_pips = MathAbs(entry_price - stop_loss) / Point();
    double lot_size = Calculate_Lot_Size(sl_distance_pips);
    
    // LOG: Trade execution details
    Print("LOG: Executing ", (order_type == ORDER_TYPE_BUY ? "BUY" : "SELL"), " order");
    Print("LOG: Entry Price: ", entry_price);
    Print("LOG: Stop Loss: ", stop_loss, " (Distance: ", sl_distance_pips, " pips)");
    Print("LOG: Take Profit: ", take_profit);
    Print("LOG: Lot Size: ", lot_size);
    
    ulong ticket = OrderSend(Symbol(), order_type, lot_size, entry_price, 3, stop_loss, take_profit, "XAUUSD_EA", 0, 0, clrNONE);
    
    if (ticket > 0)
    {
        Print("LOG: Order executed successfully. Ticket: ", ticket);
        return true;
    }
    else
    {
        Print("LOG: Order execution failed. Error: ", GetLastError());
        return false;
    }
}
6. Trade Exit Logging / การบันทึกข้อมูลการปิดออเดอร์
6.1 Exit Logging Function / ฟังก์ชันบันทึกการปิดออเดอร์

ข้อมูลโค้ด
// === TRADE EXIT LOGGING ===
void Log_Trade_Exit(ulong ticket, string exit_reason)
{
    if (!OrderSelect(ticket))
        return;
    
    double open_price = OrderGetDouble(ORDER_PRICE_OPEN);
    double close_price = OrderGetDouble(ORDER_PRICE_CURRENT);
    double stop_loss = OrderGetDouble(ORDER_SL);
    double take_profit = OrderGetDouble(ORDER_TP);
    double lot_size = OrderGetDouble(ORDER_VOLUME_INITIAL);
    datetime open_time = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
    datetime close_time = TimeCurrent();
    
    // Calculate profit/loss
    double profit_loss_pips = 0;
    double profit_loss_currency = 0;
    double profit_loss_percent = 0;
    
    if (OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY)
    {
        profit_loss_pips = (close_price - open_price) / Point();
        profit_loss_currency = (close_price - open_price) * lot_size * 100000; // For XAUUSD
    }
    else
    {
        profit_loss_pips = (open_price - close_price) / Point();
        profit_loss_currency = (open_price - close_price) * lot_size * 100000;
    }
    
    double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    profit_loss_percent = (profit_loss_currency / account_balance) * 100;
    
    // LOG: Exit information
    Print("=== TRADE EXIT LOG ===");
    Print("LOG: Exit_Reason: ", exit_reason);
    Print("LOG: Ticket: ", ticket);
    Print("LOG: Open_Time: ", TimeToString(open_time));
    Print("LOG: Close_Time: ", TimeToString(close_time));
    Print("LOG: Open_Price: ", open_price);
    Print("LOG: Close_Price: ", close_price);
    Print("LOG: Stop_Loss: ", stop_loss);
    Print("LOG: Take_Profit: ", take_profit);
    Print("LOG: Lot_Size: ", lot_size);
    Print("LOG: Profit_Loss_Pips: ", profit_loss_pips);
    Print("LOG: Profit_Loss_Currency: ", profit_loss_currency);
    Print("LOG: Profit_Loss_Percent: ", profit_loss_percent);
    
    // Calculate MAE and MFE (would need historical data tracking)
    // LOG: MAE and MFE calculations would be implemented here
}
7. Optimization Module / โมดูลการปรับจูน
7.1 Optimization Parameters Structure / โครงสร้างพารามิเตอร์การปรับจูน

ข้อมูลโค้ด
// === OPTIMIZATION MODULE ===
// These parameters will be used in Strategy Tester optimization
// The EA must support all combinations of these parameters

// Example optimization ranges for Strategy Tester:
// RSI_Buy_Min: Start=35, Step=5, Stop=45
// RSI_Buy_Max: Start=50, Step=5, Stop=60
// RSI_Sell_Min: Start=40, Step=5, Stop=50
// RSI_Sell_Max: Start=55, Step=5, Stop=65
// ATR_SL_Multiplier: Start=1.5, Step=0.1, Stop=3.0
// Risk_Reward_Ratio: Start=1.5, Step=0.1, Stop=2.5
// Risk_Per_Trade_Percent: Start=0.5, Step=0.5, Stop=2.0
7.2 Optimization Results Tracking / การติดตามผลการปรับจูน

ข้อมูลโค้ด
// === OPTIMIZATION RESULTS ===
// The EA must track and report these metrics for each optimization run:
// - Total Trades
// - Win Rate %
// - Profit Factor
// - Max Drawdown %
// - Net Profit
// - Sharpe Ratio (if possible)
// - Average Trade Duration
// - Largest Win/Loss
8. Main EA Structure / โครงสร้างหลักของ EA
8.1 OnInit() Function / ฟังก์ชันเริ่มต้น

ข้อมูลโค้ด
// === EA INITIALIZATION ===
int OnInit()
{
    // Validate input parameters
    if (EMA_Fast_Period <= 0 || EMA_Slow_Period <= 0 || EMA_Fast_Period >= EMA_Slow_Period)
    {
        Print("ERROR: Invalid EMA parameters");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    if (RSI_Period <= 0 || BB_Period <= 0 || ATR_Period <= 0)
    {
        Print("ERROR: Invalid indicator parameters");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    if (RSI_Buy_Min >= RSI_Buy_Max || RSI_Sell_Min >= RSI_Sell_Max)
    {
        Print("ERROR: Invalid RSI range parameters");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    if (ATR_SL_Multiplier <= 0 || Risk_Reward_Ratio <= 0 || Risk_Per_Trade_Percent <= 0)
    {
        Print("ERROR: Invalid risk management parameters");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    Print("=== EA INITIALIZATION ===");
    Print("LOG: EA started successfully");
    Print("LOG: Symbol: ", Symbol());
    Print("LOG: Timeframe: H4");
    Print("LOG: Strategy: With-Trend Pullback Strategy");
    
    return INIT_SUCCEEDED;
}
8.2 OnTick() Function / ฟังก์ชันหลัก

ข้อมูลโค้ด
// === MAIN EA LOGIC ===
void OnTick()
{
    // Check if new H4 candle has formed
    static datetime last_candle_time = 0;
    datetime current_candle_time = iTime(Symbol(), PERIOD_H4, 0);
    
    if (current_candle_time == last_candle_time)
        return; // No new candle
    
    last_candle_time = current_candle_time;
    
    // LOG: New H4 candle detected
    Print("LOG: New H4 candle detected at ", TimeToString(current_candle_time));
    
    // Check if we already have open trades
    if (Count_Open_Trades() >= Max_Open_Trades)
    {
        Print("LOG: Maximum open trades reached");
        return;
    }
    
    // Check for entry signals
    if (Check_Buy_Signal())
    {
        Execute_Trade(ORDER_TYPE_BUY);
    }
    else if (Check_Sell_Signal())
    {
        Execute_Trade(ORDER_TYPE_SELL);
    }
    
    // Check for trailing stop (if enabled)
    if (Enable_Trailing_Stop)
    {
        Manage_Trailing_Stop();
    }
}
8.3 OnDeinit() Function / ฟังก์ชันปิด EA

ข้อมูลโค้ด
// === EA CLEANUP ===
void OnDeinit(const int reason)
{
    Print("=== EA DEINITIALIZATION ===");
    Print("LOG: EA stopped. Reason: ", reason);
    Print("LOG: Final account balance: ", AccountInfoDouble(ACCOUNT_BALANCE));
    Print("LOG: Final account equity: ", AccountInfoDouble(ACCOUNT_EQUITY));
}
9. Testing & Validation / การทดสอบและตรวจสอบ
9.1 Backtesting Requirements / ข้อกำหนดการทดสอบย้อนหลัง

Time Period: Minimum 2 years of historical data
Spread: Realistic spread simulation (2-5 pips for XAUUSD)
Slippage: 1-2 pips average slippage
Commission: $5-10 per lot (typical for XAUUSD)
9.2 Forward Testing Requirements / ข้อกำหนดการทดสอบไปข้างหน้า

Duration: Minimum 3 months on demo account
Market Conditions: Test during different market volatility periods
Performance Metrics: Track all optimization metrics
9.3 Live Trading Requirements / ข้อกำหนดการเทรดจริง

Risk Management: Strict adherence to position sizing
Monitoring: Daily performance review
Adjustment: Monthly parameter review and adjustment
10. Risk Management / การจัดการความเสี่ยง
10.1 Position Sizing Rules / กฎการกำหนดขนาดออเดอร์

Maximum 1% risk per trade
Maximum 1 open trade at a time
Lot size calculated based on ATR-based stop loss
10.2 Stop Loss Rules / กฎ Stop Loss

ATR-based stop loss calculation
No manual stop loss modification
Trailing stop optional feature
10.3 Take Profit Rules / กฎ Take Profit

Risk:Reward ratio minimum 1:2
Fixed take profit levels
No manual take profit modification
11. Performance Expectations / ความคาดหวังด้านผลการดำเนินงาน
11.1 Target Performance Metrics / เป้าหมายตัวชี้วัดผลการดำเนินงาน

Win Rate: 45-55%
Profit Factor: 1.5-2.5
Max Drawdown: &lt;20%
Monthly Return: 5-15%
Sharpe Ratio: >1.0
11.2 Risk-Adjusted Returns / ผลตอบแทนที่ปรับความเสี่ยงแล้ว

Focus on consistent performance over high returns
Prioritize low drawdown over high profit factor
Balance between win rate and risk:reward ratio
12. Implementation Timeline / ระยะเวลาการพัฒนา
12.1 Development Phases / ระยะการพัฒนา

Phase 1: Core logic implementation (2 weeks)
Phase 2: Testing and optimization (2 weeks)
Phase 3: Forward testing (1 month)
Phase 4: Live trading deployment (ongoing)
12.2 Quality Assurance / การประกันคุณภาพ

Code review and testing
Backtesting validation
Demo account testing
Gradual live deployment
13. Conclusion / สรุป
EA นี้จะถูกพัฒนาตามกลยุทธ์ "With-Trend Pullback Strategy" ที่รวมการวิเคราะห์เทรนด์ระดับ D1 และสัญญาณการกลับตัวระดับ H4 โดยมีระบบการบันทึกข้อมูลที่ครบถ้วนและโมดูลการปรับจูนที่รองรับการทดสอบใน Strategy Tester ของ MT5

การพัฒนา EA นี้จะเน้นที่ความปลอดภัย ความเสถียร และความสามารถในการปรับตัวให้เข้ากับสภาวะตลาดที่เปลี่ยนแปลงไป โดยใช้หลักการจัดการความเสี่ยงที่เข้มงวดและการบันทึกข้อมูลที่ละเอียดเพื่อการวิเคราะห์และปรับปรุงอย่างต่อเนื่อง