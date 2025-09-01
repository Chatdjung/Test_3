//+------------------------------------------------------------------+
//|                                                04_Execution.mqh |
//|                                                       Chatchai.D |
//|                                   With-Trend Pullback Strategy  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Include necessary files                                          |
//+------------------------------------------------------------------+
#include "01_Parameters.mqh"

//+------------------------------------------------------------------+
//| Forward declarations for position tracking                      |
//+------------------------------------------------------------------+
void AddTrackedPosition(ulong ticket, ENUM_POSITION_TYPE type, double volume, double open_price, 
                       double sl, double tp, datetime open_time, double atr_value, 
                       double sl_multiplier, double rr_ratio);

#include "06_Logging.mqh"

//+------------------------------------------------------------------+
//| Trade Execution Functions                                        |
//| Contains functions for calculating SL, TP, lot size and trades  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Get current spread in pips                                      |
//| Parameters: None                                                 |
//| Returns: current spread in pips                                  |
//+------------------------------------------------------------------+
double Get_Current_Spread_Pips()
{
    // Get current bid and ask prices
    double current_bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double current_ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    
    if(current_bid <= 0 || current_ask <= 0)
    {
        Print("ERROR: Invalid bid/ask prices - Bid: ", current_bid, ", Ask: ", current_ask);
        return 999.0; // Return high spread to prevent trading
    }
    
    // Calculate spread
    double spread_points = current_ask - current_bid;
    
    // Convert to pips
    double pip_size = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
    if(SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 5 || SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 3)
    {
        pip_size *= 10; // For 5-digit and 3-digit brokers
    }
    
    double spread_pips = spread_points / pip_size;
    
    return spread_pips;
}

//+------------------------------------------------------------------+
//| Check if current spread is acceptable for trading               |
//| Parameters: max_spread_pips - maximum allowed spread            |
//| Returns: true if spread is acceptable, false otherwise          |
//+------------------------------------------------------------------+
bool Is_Spread_Acceptable(double max_spread_pips = MAX_SPREAD_PIPS)
{
    if(!SPREAD_CHECK_ENABLED)
    {
        return true; // Skip spread check if disabled
    }
    
    double current_spread = Get_Current_Spread_Pips();
    
    // Log spread information
    Print("LOG: Current spread: ", DoubleToString(current_spread, 1), " pips, Max allowed: ", 
          DoubleToString(max_spread_pips, 1), " pips");
    
    // Check if spread is within acceptable range
    if(current_spread > max_spread_pips)
    {
        Print("WARNING: Spread too high (", DoubleToString(current_spread, 1), 
              " pips) - Maximum allowed: ", DoubleToString(max_spread_pips, 1), " pips");
        return false;
    }
    
    if(current_spread < MIN_SPREAD_PIPS)
    {
        Print("WARNING: Spread suspiciously low (", DoubleToString(current_spread, 1), 
              " pips) - Minimum expected: ", DoubleToString(MIN_SPREAD_PIPS, 1), " pips");
        // Don't return false for low spread, just log warning
    }
    
    Print("LOG: Spread acceptable for trading: ", DoubleToString(current_spread, 1), " pips");
    return true;
}

//+------------------------------------------------------------------+
//| Check if trading execution is allowed                           |
//| Parameters: order_type - ORDER_TYPE_BUY or ORDER_TYPE_SELL      |
//| Returns: true if all conditions met, false otherwise            |
//+------------------------------------------------------------------+
bool Can_Execute_Trade(int order_type)
{
    Print("=== TRADE EXECUTION VALIDATION ===");
    
    // 1. Check if spread is acceptable
    if(!Is_Spread_Acceptable())
    {
        Print("VALIDATION FAILED: Spread too high");
        return false;
    }
    
    // 2. Check trading permissions
    if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
    {
        Print("VALIDATION FAILED: Automated trading disabled in terminal");
        return false;
    }
    
    if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
    {
        Print("VALIDATION FAILED: EA trading not allowed");
        return false;
    }
    
    if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
    {
        Print("VALIDATION FAILED: Account trading not allowed");
        return false;
    }
    
    // 3. Check symbol trading status
    if(!SymbolInfoInteger(Symbol(), SYMBOL_SELECT))
    {
        Print("VALIDATION FAILED: Symbol not selected or market closed");
        return false;
    }
    
    // 4. Check account equity and margin
    double account_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    
    if(account_equity < 100)
    {
        Print("VALIDATION FAILED: Insufficient account equity: ", DoubleToString(account_equity, 2));
        return false;
    }
    
    if(free_margin < 50)
    {
        Print("VALIDATION FAILED: Insufficient free margin: ", DoubleToString(free_margin, 2));
        return false;
    }
    
    // 5. Validate order type
    if(order_type != ORDER_TYPE_BUY && order_type != ORDER_TYPE_SELL)
    {
        Print("VALIDATION FAILED: Invalid order type: ", order_type);
        return false;
    }
    
    // 6. Check market hours (optional - can be extended later)
    datetime current_time = TimeCurrent();
    MqlDateTime time_struct;
    TimeToStruct(current_time, time_struct);
    int current_hour = time_struct.hour;
    
    if(current_hour < GOOD_TRADING_HOURS_START || current_hour > GOOD_TRADING_HOURS_END)
    {
        Print("LOG: Trading outside optimal hours (", current_hour, ":xx) - Consider review");
        // Don't block trading, just log warning
    }
    
    Print("VALIDATION PASSED: All conditions met for ", 
          (order_type == ORDER_TYPE_BUY ? "BUY" : "SELL"), " trade");
    Print("Current spread: ", DoubleToString(Get_Current_Spread_Pips(), 1), " pips");
    Print("Account equity: ", DoubleToString(account_equity, 2));
    Print("Free margin: ", DoubleToString(free_margin, 2));
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate Stop Loss distance using ATR                          |
//| Parameters: order_type - ORDER_TYPE_BUY or ORDER_TYPE_SELL      |
//| Returns: stop loss distance in points                           |
//+------------------------------------------------------------------+
double Calculate_Stop_Loss(int order_type, int atr_period = 14, double atr_sl_multiplier = 2.0)
{
    // Get ATR indicator handle for current symbol
    int handle_atr = iATR(Symbol(), PERIOD_H4, atr_period);
    
    if(handle_atr == INVALID_HANDLE)
    {
        Print("ERROR: Failed to create ATR indicator handle");
        return 0.0;
    }
    
    // Get ATR value from previous completed candle
    double atr_buffer[2];
    if(CopyBuffer(handle_atr, 0, 1, 1, atr_buffer) <= 0)
    {
        Print("ERROR: Failed to get ATR values");
        return 0.0;
    }
    
    double atr_value = atr_buffer[0];
    double current_price = 0.0;
    double stop_loss_price = 0.0;
    
    // Calculate stop loss based on order type
    if(order_type == ORDER_TYPE_BUY)
    {
        current_price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
        stop_loss_price = current_price - (atr_value * atr_sl_multiplier);
        
        Print("LOG: BUY - Current Price: ", current_price, 
              ", ATR: ", atr_value, 
              ", SL Distance: ", (atr_value * atr_sl_multiplier),
              ", SL Price: ", stop_loss_price);
    }
    else if(order_type == ORDER_TYPE_SELL)
    {
        current_price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
        stop_loss_price = current_price + (atr_value * atr_sl_multiplier);
        
        Print("LOG: SELL - Current Price: ", current_price, 
              ", ATR: ", atr_value, 
              ", SL Distance: ", (atr_value * atr_sl_multiplier),
              ", SL Price: ", stop_loss_price);
    }
    else
    {
        Print("ERROR: Invalid order type for Stop Loss calculation");
        return 0.0;
    }
    
    // Validate stop loss price
    if(stop_loss_price <= 0)
    {
        Print("ERROR: Invalid stop loss price calculated: ", stop_loss_price);
        return 0.0;
    }
    
    return stop_loss_price;
}

//+------------------------------------------------------------------+
//| Calculate Take Profit using Risk:Reward ratio                   |
//| Parameters: order_type - ORDER_TYPE_BUY or ORDER_TYPE_SELL      |
//|            stop_loss_price - calculated stop loss price         |
//| Returns: take profit price                                       |
//+------------------------------------------------------------------+
double Calculate_Take_Profit(int order_type, double stop_loss_price, double risk_reward_ratio = 2.0)
{
    if(stop_loss_price <= 0)
    {
        Print("ERROR: Invalid stop loss price provided: ", stop_loss_price);
        return 0.0;
    }
    
    double current_price = 0.0;
    double stop_loss_distance = 0.0;
    double take_profit_distance = 0.0;
    double take_profit_price = 0.0;
    
    // Calculate take profit based on order type
    if(order_type == ORDER_TYPE_BUY)
    {
        current_price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
        stop_loss_distance = current_price - stop_loss_price;
        take_profit_distance = stop_loss_distance * risk_reward_ratio;
        take_profit_price = current_price + take_profit_distance;
        
        Print("LOG: BUY TP - Current Price: ", current_price, 
              ", SL Price: ", stop_loss_price,
              ", SL Distance: ", stop_loss_distance,
              ", RR Ratio: ", risk_reward_ratio,
              ", TP Distance: ", take_profit_distance,
              ", TP Price: ", take_profit_price);
    }
    else if(order_type == ORDER_TYPE_SELL)
    {
        current_price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
        stop_loss_distance = stop_loss_price - current_price;
        take_profit_distance = stop_loss_distance * risk_reward_ratio;
        take_profit_price = current_price - take_profit_distance;
        
        Print("LOG: SELL TP - Current Price: ", current_price, 
              ", SL Price: ", stop_loss_price,
              ", SL Distance: ", stop_loss_distance,
              ", RR Ratio: ", risk_reward_ratio,
              ", TP Distance: ", take_profit_distance,
              ", TP Price: ", take_profit_price);
    }
    else
    {
        Print("ERROR: Invalid order type for Take Profit calculation");
        return 0.0;
    }
    
    // Validate take profit price
    if(take_profit_price <= 0)
    {
        Print("ERROR: Invalid take profit price calculated: ", take_profit_price);
        return 0.0;
    }
    
    // Additional validation for reasonable TP distance
    if(stop_loss_distance <= 0)
    {
        Print("ERROR: Invalid stop loss distance for TP calculation: ", stop_loss_distance);
        return 0.0;
    }
    
    return take_profit_price;
}

//+------------------------------------------------------------------+
//| Calculate Lot Size based on Risk Management                     |
//| Parameters: order_type - ORDER_TYPE_BUY or ORDER_TYPE_SELL      |
//|            stop_loss_price - calculated stop loss price         |
//| Returns: lot size for the trade                                  |
//+------------------------------------------------------------------+
double Calculate_Lot_Size(int order_type, double stop_loss_price, double risk_per_trade_percent = 1.0, double min_lot_size = 0.01, double max_lot_size = 1.0)
{
    if(stop_loss_price <= 0)
    {
        Print("ERROR: Invalid stop loss price provided for lot calculation: ", stop_loss_price);
        return 0.0;
    }
    
    // Get account information
    double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double account_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    if(account_balance <= 0)
    {
        Print("ERROR: Invalid account balance: ", account_balance);
        return 0.0;
    }
    
    // Use equity if it's lower than balance (for safety)
    double account_value = MathMin(account_balance, account_equity);
    
    // Calculate risk amount in account currency
    double risk_amount = account_value * (risk_per_trade_percent / 100.0);
    
    // Get current price and calculate stop loss distance
    double current_price = 0.0;
    double stop_loss_distance = 0.0;
    
    if(order_type == ORDER_TYPE_BUY)
    {
        current_price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
        stop_loss_distance = current_price - stop_loss_price;
    }
    else if(order_type == ORDER_TYPE_SELL)
    {
        current_price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
        stop_loss_distance = stop_loss_price - current_price;
    }
    else
    {
        Print("ERROR: Invalid order type for lot size calculation");
        return 0.0;
    }
    
    // Validate stop loss distance
    if(stop_loss_distance <= 0)
    {
        Print("ERROR: Invalid stop loss distance: ", stop_loss_distance);
        return 0.0;
    }
    
    // Get symbol information for calculations
    double tick_size = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
    double tick_value = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
    double lot_step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
    
    if(tick_size <= 0 || tick_value <= 0)
    {
        Print("ERROR: Invalid symbol tick information - Tick Size: ", tick_size, ", Tick Value: ", tick_value);
        return 0.0;
    }
    
    // Calculate pip value per lot
    double pip_value_per_lot = tick_value / tick_size;
    
    // Calculate lot size based on risk
    double calculated_lot_size = risk_amount / (stop_loss_distance * pip_value_per_lot);
    
    // Round to lot step
    calculated_lot_size = MathFloor(calculated_lot_size / lot_step) * lot_step;
    
    // Apply min/max lot size limits
    if(calculated_lot_size < min_lot_size)
    {
        calculated_lot_size = min_lot_size;
        Print("WARNING: Calculated lot size below minimum, using minimum lot size: ", min_lot_size);
    }
    else if(calculated_lot_size > max_lot_size)
    {
        calculated_lot_size = max_lot_size;
        Print("WARNING: Calculated lot size above maximum, using maximum lot size: ", max_lot_size);
    }
    
    // Validate against broker limits
    double min_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
    
    if(calculated_lot_size < min_lot)
    {
        calculated_lot_size = min_lot;
        Print("WARNING: Lot size below broker minimum, adjusted to: ", min_lot);
    }
    else if(calculated_lot_size > max_lot)
    {
        calculated_lot_size = max_lot;
        Print("WARNING: Lot size above broker maximum, adjusted to: ", max_lot);
    }
    
    // Final validation
    if(calculated_lot_size <= 0)
    {
        Print("ERROR: Final lot size calculation resulted in zero or negative value");
        return 0.0;
    }
    
    // Comprehensive logging
    Print("LOG: Lot Size Calculation - Account Balance: ", account_balance,
          ", Account Equity: ", account_equity,
          ", Risk Amount: ", risk_amount,
          ", Current Price: ", current_price,
          ", SL Price: ", stop_loss_price,
          ", SL Distance: ", stop_loss_distance,
          ", Pip Value/Lot: ", pip_value_per_lot,
          ", Calculated Lot: ", calculated_lot_size);
    
    return calculated_lot_size;
}

//+------------------------------------------------------------------+
//| Execute Trade - Main function that combines all calculations    |
//| Parameters: order_type - ORDER_TYPE_BUY or ORDER_TYPE_SELL      |
//| Returns: true if trade executed successfully, false otherwise    |
//+------------------------------------------------------------------+
bool Execute_Trade(int order_type)
{
    Print("LOG: Starting trade execution for order type: ", 
          (order_type == ORDER_TYPE_BUY ? "BUY" : "SELL"));
    
    // Comprehensive pre-trade validation (includes spread check)
    if(!Can_Execute_Trade(order_type))
    {
        Print("ERROR: Trade execution validation failed");
        return false;
    }
    
    // Get Multi-Timeframe RSI data for logging
    double rsi_m15, rsi_m5, rsi_m1;
    bool multi_tf_rsi_available = Get_Multi_Timeframe_RSI(RSI_PERIOD, rsi_m15, rsi_m5, rsi_m1);
    bool multi_tf_compliant = false;
    
    if(multi_tf_rsi_available)
    {
        if(order_type == ORDER_TYPE_BUY)
        {
            // BUY signals require all RSI < 35 (oversold condition)
            multi_tf_compliant = (rsi_m15 < 35.0 && rsi_m5 < 35.0 && rsi_m1 < 35.0);
        }
        else if(order_type == ORDER_TYPE_SELL)
        {
            // SELL signals require all RSI > 65 (overbought condition)
            multi_tf_compliant = (rsi_m15 > 65.0 && rsi_m5 > 65.0 && rsi_m1 > 65.0);
        }
        
        Print("Multi-TF RSI Analysis: M15=", DoubleToString(rsi_m15, 2), 
              ", M5=", DoubleToString(rsi_m5, 2), 
              ", M1=", DoubleToString(rsi_m1, 2), 
              ", Compliant=", (multi_tf_compliant ? "YES" : "NO"));
    }
    else
    {
        Print("WARNING: Unable to retrieve Multi-TF RSI data");
        rsi_m15 = rsi_m5 = rsi_m1 = 0.0;
    }
    
    // Step 1: Calculate Stop Loss
    double stop_loss_price = Calculate_Stop_Loss(order_type);
    if(stop_loss_price <= 0)
    {
        Print("ERROR: Failed to calculate stop loss");
        return false;
    }
    
    // Step 2: Calculate Take Profit
    double take_profit_price = Calculate_Take_Profit(order_type, stop_loss_price);
    if(take_profit_price <= 0)
    {
        Print("ERROR: Failed to calculate take profit");
        return false;
    }
    
    // Step 3: Calculate Lot Size
    double lot_size = Calculate_Lot_Size(order_type, stop_loss_price);
    if(lot_size <= 0)
    {
        Print("ERROR: Failed to calculate lot size");
        return false;
    }
    
    // Get current price for order
    double price = 0.0;
    if(order_type == ORDER_TYPE_BUY)
    {
        price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    }
    else
    {
        price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    }
    
    if(price <= 0)
    {
        Print("ERROR: Invalid price for order: ", price);
        return false;
    }
    
    // Prepare trade request (STEP 1: Market Order WITHOUT SL/TP)
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;        // Market order
    request.symbol = Symbol();                 // Current symbol
    request.volume = lot_size;                 // Calculated lot size
    request.type = (ENUM_ORDER_TYPE)order_type; // Order type (BUY/SELL)
    request.price = price;                     // Current market price
    request.sl = 0;                           // NO Stop loss in initial order
    request.tp = 0;                           // NO Take profit in initial order
    request.deviation = 3;                     // Maximum price deviation
    request.magic = MAGIC_NUMBER;              // Magic number for EA identification
    request.comment = "With-Trend Pullback Strategy";
    request.type_filling = ORDER_FILLING_IOC;  // Immediate or Cancel (most compatible)
    
    // Normalize prices to symbol digits
    int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
    request.price = NormalizeDouble(request.price, digits);
    
    // Log trade details before execution
    Print("LOG: Trade Request Details (Step 1 - Market Order):");
    Print("  Symbol: ", request.symbol);
    Print("  Order Type: ", (order_type == ORDER_TYPE_BUY ? "BUY" : "SELL"));
    Print("  Volume: ", request.volume);
    Print("  Price: ", request.price);
    Print("  SL/TP: Will be set in Step 2");
    Print("  Magic: ", request.magic);
    Print("  Filling Mode: IOC");
    
    // Calculate risk metrics for logging
    double risk_amount = (MathAbs(price - stop_loss_price) * lot_size * SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE)) / SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
    double risk_percentage = (risk_amount / AccountInfoDouble(ACCOUNT_BALANCE)) * 100.0;
    double risk_reward_ratio = MathAbs(take_profit_price - price) / MathAbs(price - stop_loss_price);
    
    // Calculate ATR for logging
    int atr_handle = iATR(Symbol(), PERIOD_H4, ATR_PERIOD);
    double atr_array[];
    ArraySetAsSeries(atr_array, true);
    CopyBuffer(atr_handle, 0, 1, 1, atr_array);
    double current_atr = (ArraySize(atr_array) > 0) ? atr_array[0] : 0.001; // fallback
    
    // Send the market order (STEP 1)
    bool order_sent = OrderSend(request, result);
    
    // Calculate additional parameters for logging
    double atr_h4_value = current_atr;
    double sl_atr_multiplier = ATR_SL_MULTIPLIER;
    double rr_applied = risk_reward_ratio;
    double sl_distance = MathAbs(price - stop_loss_price);
    double tp_distance = MathAbs(take_profit_price - price);
    string config_tag = StringFormat("ATR_%.1f_RR_%.1f", sl_atr_multiplier, rr_applied);
    
    // Log execution attempt with enhanced parameters
    bool execution_success = (order_sent && result.retcode == TRADE_RETCODE_DONE);
    Log_Execution_Attempt(order_type, execution_success, 
                         stop_loss_price, take_profit_price, lot_size, price, 
                         result.retcode, result.order, risk_percentage, risk_reward_ratio,
                         atr_h4_value, sl_atr_multiplier, rr_applied, sl_distance, tp_distance, config_tag,
                         rsi_m15, rsi_m5, rsi_m1, multi_tf_compliant);
    
    // Check result
    if(order_sent && result.retcode == TRADE_RETCODE_DONE)
    {
        Print("✅ STEP 1 SUCCESS: Market order executed successfully!");
        Print("  Order Ticket: ", result.order);
        Print("  Deal Ticket: ", result.deal);
        Print("  Position Ticket: ", result.order);
        Print("  Executed Volume: ", result.volume);
        Print("  Executed Price: ", result.price);
        
        // STEP 2: Set Stop Loss and Take Profit
        Print("LOG: Proceeding to Step 2 - Setting SL/TP...");
        
        MqlTradeRequest modify_request = {};
        MqlTradeResult modify_result = {};
        
        modify_request.action = TRADE_ACTION_SLTP;    // Modify SL/TP
        modify_request.position = result.order;       // Position ticket
        modify_request.symbol = Symbol();             // Symbol
        modify_request.sl = NormalizeDouble(stop_loss_price, digits);     // Stop Loss
        modify_request.tp = NormalizeDouble(take_profit_price, digits);   // Take Profit
        modify_request.magic = MAGIC_NUMBER;          // Magic number
        
        Print("LOG: SL/TP Modification Details:");
        Print("  Position Ticket: ", modify_request.position);
        Print("  Stop Loss: ", modify_request.sl);
        Print("  Take Profit: ", modify_request.tp);
        
        bool modify_sent = OrderSend(modify_request, modify_result);
        
        if(modify_sent && modify_result.retcode == TRADE_RETCODE_DONE)
        {
            Print("✅ STEP 2 SUCCESS: SL/TP set successfully!");
            Print("  SL set to: ", modify_request.sl);
            Print("  TP set to: ", modify_request.tp);
            Print("🎯 COMPLETE SUCCESS: Trade executed with full risk management!");
            
            // Log successful trade execution to CSV with RSI data
            Log_Trade_Execution_Basic(order_type, Symbol(), result.price, lot_size, result.order,
                                    rsi_m15, rsi_m5, rsi_m1, multi_tf_compliant);
            
            // Add position to tracking system for proper exit logging
            ENUM_POSITION_TYPE pos_type = (order_type == ORDER_TYPE_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
            int atr_handle = iATR(Symbol(), PERIOD_H4, ATR_PERIOD);
            double atr_array[];
            ArraySetAsSeries(atr_array, true);
            CopyBuffer(atr_handle, 0, 1, 1, atr_array);
            double atr_value = (ArraySize(atr_array) > 0) ? atr_array[0] : 0.001; // fallback
            AddTrackedPosition(result.order, pos_type, lot_size, result.price, 
                             modify_request.sl, modify_request.tp, TimeCurrent(), 
                             atr_value, ATR_SL_MULTIPLIER, RISK_REWARD_RATIO);
            
            return true;
        }
        else
        {
            Print("⚠️ STEP 2 WARNING: Failed to set SL/TP but position is still ACTIVE!");
            Print("  Position Ticket: ", result.order, " (Monitor manually)");
            Print("  Modify Return Code: ", modify_result.retcode);
            Print("  Modify Description: ", GetTradeRetcodeDescription(modify_result.retcode));
            Print("  Intended SL: ", stop_loss_price);
            Print("  Intended TP: ", take_profit_price);
            
            // Log successful trade execution to CSV with RSI data (even without SL/TP)
            Log_Trade_Execution_Basic(order_type, Symbol(), result.price, lot_size, result.order,
                                    rsi_m15, rsi_m5, rsi_m1, multi_tf_compliant);
            
            // Add position to tracking system (even without SL/TP set)
            ENUM_POSITION_TYPE pos_type = (order_type == ORDER_TYPE_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
            int atr_handle = iATR(Symbol(), PERIOD_H4, ATR_PERIOD);
            double atr_array[];
            ArraySetAsSeries(atr_array, true);
            CopyBuffer(atr_handle, 0, 1, 1, atr_array);
            double atr_value = (ArraySize(atr_array) > 0) ? atr_array[0] : 0.001; // fallback
            AddTrackedPosition(result.order, pos_type, lot_size, result.price, 
                             stop_loss_price, take_profit_price, TimeCurrent(), 
                             atr_value, ATR_SL_MULTIPLIER, RISK_REWARD_RATIO);
            
            // Position is still open and profitable, just without automatic SL/TP
            return true; // Consider success with warning
        }
    }
    else
    {
        Print("❌ STEP 1 FAILED: Failed to execute market order!");
        Print("  Return Code: ", result.retcode);
        Print("  Return Description: ", GetTradeRetcodeDescription(result.retcode));
        Print("  Deal: ", result.deal);
        Print("  Order: ", result.order);
        Print("  Volume: ", result.volume);
        Print("  Price: ", result.price);
        Print("  Bid: ", result.bid);
        Print("  Ask: ", result.ask);
        Print("  Comment: ", result.comment);
        return false;
    }
}

//+------------------------------------------------------------------+
//| Get human readable description of trade return codes            |
//| Parameters: retcode - trade operation return code               |
//| Returns: string description of the return code                  |
//+------------------------------------------------------------------+
string GetTradeRetcodeDescription(uint retcode)
{
    switch(retcode)
    {
        case TRADE_RETCODE_REQUOTE:         return "Requote";
        case TRADE_RETCODE_REJECT:          return "Request rejected";
        case TRADE_RETCODE_CANCEL:          return "Request canceled by trader";
        case TRADE_RETCODE_PLACED:          return "Order placed";
        case TRADE_RETCODE_DONE:            return "Request completed";
        case TRADE_RETCODE_DONE_PARTIAL:    return "Only part of the request was completed";
        case TRADE_RETCODE_ERROR:           return "Request processing error";
        case TRADE_RETCODE_TIMEOUT:         return "Request canceled by timeout";
        case TRADE_RETCODE_INVALID:         return "Invalid request";
        case TRADE_RETCODE_INVALID_VOLUME:  return "Invalid volume in the request";
        case TRADE_RETCODE_INVALID_PRICE:   return "Invalid price in the request";
        case TRADE_RETCODE_INVALID_STOPS:   return "Invalid stops in the request";
        case TRADE_RETCODE_TRADE_DISABLED:  return "Trade is disabled";
        case TRADE_RETCODE_MARKET_CLOSED:   return "Market is closed";
        case TRADE_RETCODE_NO_MONEY:        return "There is not enough money to complete the request";
        case TRADE_RETCODE_PRICE_CHANGED:   return "Prices changed";
        case TRADE_RETCODE_PRICE_OFF:       return "There are no quotes to process the request";
        case TRADE_RETCODE_INVALID_EXPIRATION: return "Invalid order expiration date in the request";
        case TRADE_RETCODE_ORDER_CHANGED:   return "Order state changed";
        case TRADE_RETCODE_TOO_MANY_REQUESTS: return "Too frequent requests";
        case TRADE_RETCODE_NO_CHANGES:      return "No changes in request";
        case TRADE_RETCODE_SERVER_DISABLES_AT: return "Autotrading disabled by server";
        case TRADE_RETCODE_CLIENT_DISABLES_AT: return "Autotrading disabled by client terminal";
        case TRADE_RETCODE_LOCKED:          return "Request locked for processing";
        case TRADE_RETCODE_FROZEN:          return "Order or position frozen";
        case TRADE_RETCODE_INVALID_FILL:    return "Invalid order filling type";
        case TRADE_RETCODE_CONNECTION:      return "No connection with the trade server";
        case TRADE_RETCODE_ONLY_REAL:       return "Operation is allowed only for live accounts";
        case TRADE_RETCODE_LIMIT_ORDERS:    return "The number of pending orders has reached the limit";
        case TRADE_RETCODE_LIMIT_VOLUME:    return "The volume of orders and positions for the symbol has reached the limit";
        default:                           return "Unknown error code: " + IntegerToString(retcode);
    }
}

//+------------------------------------------------------------------+
//| Execute Buy Trade - Wrapper function for buying                 |
//| Parameters: None                                                 |
//| Returns: true if buy trade executed successfully                 |
//+------------------------------------------------------------------+
bool Execute_Buy_Trade()
{
    Print("=== EXECUTING BUY TRADE ===");
    return Execute_Trade(ORDER_TYPE_BUY);
}

//+------------------------------------------------------------------+
//| Execute Sell Trade - Wrapper function for selling               |
//| Parameters: None                                                 |
//| Returns: true if sell trade executed successfully               |
//+------------------------------------------------------------------+
bool Execute_Sell_Trade()
{
    Print("=== EXECUTING SELL TRADE ===");
    return Execute_Trade(ORDER_TYPE_SELL);
}

//+------------------------------------------------------------------+
//| Check if spread allows trading and log status                   |
//| Parameters: None                                                 |
//| Returns: true if spread is acceptable, false otherwise          |
//+------------------------------------------------------------------+
bool Check_Spread_And_Log()
{
    double current_spread = Get_Current_Spread_Pips();
    bool spread_ok = Is_Spread_Acceptable();
    
    if(spread_ok)
    {
        Print("SPREAD CHECK: ✓ ACCEPTABLE (", DoubleToString(current_spread, 1), " pips)");
    }
    else
    {
        Print("SPREAD CHECK: ✗ TOO HIGH (", DoubleToString(current_spread, 1), " pips > ", 
              DoubleToString(MAX_SPREAD_PIPS, 1), " pips)");
    }
    
    return spread_ok;
}

//+------------------------------------------------------------------+
