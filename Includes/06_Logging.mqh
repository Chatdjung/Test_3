//+------------------------------------------------------------------+
//|                                                  06_Logging.mqh |
//|                                                       Chatchai.D |
//|                                   With-Trend Pullback Strategy  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Include necessary files                                          |
//+------------------------------------------------------------------+
#include "01_Parameters.mqh"
#include "02_Analysis.mqh"

//+------------------------------------------------------------------+
//| Configuration - Logging System                                   |
//+------------------------------------------------------------------+
// CSV Format Settings
#define USE_CSV_FORMAT true
#define CSV_SEPARATOR ","

// Mode Detection (Auto-detect or manual override)
#define AUTO_DETECT_MODE true      // true = auto-detect, false = manual
#define MANUAL_MODE_BACKTEST false // Only used if AUTO_DETECT_MODE = false

// Backtest Mode Settings
#define BACKTEST_USE_CSV true
#define BACKTEST_LIMIT_LOG_FREQUENCY false
#define BACKTEST_SINGLE_LOG_FILE true

// Live Trading Mode Settings  
#define LIVE_USE_CSV true
#define LIVE_LIMIT_LOG_FREQUENCY true
#define LIVE_SEPARATE_FILES_BY_DATE true
#define LIVE_MAX_LOG_FILES 30      // Keep last 30 days of log files

// Traditional Logging Settings
#define USE_COMPUTER_TIMESTAMP true
#define LOG_FILE_PREFIX "WithTrendPullback_"

//+------------------------------------------------------------------+
//| Logging Functions                                                |
//| Contains functions for comprehensive trade and system logging    |
//|                                                                  |
//| NEW FUNCTIONS ADDED:                                            |
//| 1. Log_Entry_Signal_Basic() - บันทึกสัญญาณเข้าเทรดเบื้องต้น      |
//| 2. Log_Trade_Execution_Basic() - บันทึกการเปิดออเดอร์           |
//| 3. Enhanced debugging in Log_Trade_Exit() for price/time issues |
//|                                                                  |
//| USAGE IN MAIN EA:                                               |
//| - เรียก Log_Entry_Signal_Basic() เมื่อตรวจพบสัญญาณ              |
//| - เรียก Log_Trade_Execution_Basic() หลังเปิดออเดอร์สำเร็จ        |
//| - Log_Trade_Exit() จะทำงานอัตโนมัติเมื่อปิดออเดอร์               |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Log Trade Exit with comprehensive details                       |
//| Parameters: ticket - trade ticket number                        |
//| Returns: true if logging successful, false otherwise            |
//+------------------------------------------------------------------+
bool Log_Trade_Exit(ulong ticket)
{
    if(ticket <= 0)
    {
        Print("ERROR: Invalid ticket provided to Log_Trade_Exit: ", ticket);
        return false;
    }
    
    // Select the deal/position for analysis
    if(!HistorySelectByPosition(ticket))
    {
        Print("ERROR: Failed to select position history for ticket: ", ticket);
        return false;
    }
    
    // Get deal information
    int deals_total = HistoryDealsTotal();
    if(deals_total < 2) // Need at least entry and exit deals
    {
        Print("WARNING: Insufficient deal history for ticket: ", ticket, " (deals: ", deals_total, ")");
        return false;
    }
    
    // Find entry and exit deals
    ulong entry_deal = 0;
    ulong exit_deal = 0;
    
    for(int i = 0; i < deals_total; i++)
    {
        ulong deal_ticket = HistoryDealGetTicket(i);
        if(deal_ticket > 0)
        {
            long deal_position_id = HistoryDealGetInteger(deal_ticket, DEAL_POSITION_ID);
            if(deal_position_id == (long)ticket)
            {
                ENUM_DEAL_TYPE deal_type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal_ticket, DEAL_TYPE);
                
                if(deal_type == DEAL_TYPE_BUY || deal_type == DEAL_TYPE_SELL)
                {
                    if(entry_deal == 0)
                        entry_deal = deal_ticket; // First deal is entry
                    else
                        exit_deal = deal_ticket;  // Subsequent deal is exit
                }
            }
        }
    }
    
    if(entry_deal == 0)
    {
        Print("ERROR: Could not find entry deal for ticket: ", ticket);
        return false;
    }
    
    if(exit_deal == 0)
    {
        Print("WARNING: Position may still be open for ticket: ", ticket);
        // For open positions, we'll log current status
        return Log_Open_Position_Status(ticket);
    }
    
    // Extract detailed trade information with enhanced debugging
    string symbol = HistoryDealGetString(entry_deal, DEAL_SYMBOL);
    ENUM_DEAL_TYPE entry_type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(entry_deal, DEAL_TYPE);
    ENUM_DEAL_TYPE exit_type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(exit_deal, DEAL_TYPE);
    
    double entry_price = HistoryDealGetDouble(entry_deal, DEAL_PRICE);
    double exit_price = HistoryDealGetDouble(exit_deal, DEAL_PRICE);
    double volume = HistoryDealGetDouble(entry_deal, DEAL_VOLUME);
    
    datetime entry_time = (datetime)HistoryDealGetInteger(entry_deal, DEAL_TIME);
    datetime exit_time = (datetime)HistoryDealGetInteger(exit_deal, DEAL_TIME);
    
    double profit = HistoryDealGetDouble(exit_deal, DEAL_PROFIT);
    double commission = HistoryDealGetDouble(entry_deal, DEAL_COMMISSION) + HistoryDealGetDouble(exit_deal, DEAL_COMMISSION);
    double swap = HistoryDealGetDouble(exit_deal, DEAL_SWAP);
    
    string entry_comment = HistoryDealGetString(entry_deal, DEAL_COMMENT);
    string exit_comment = HistoryDealGetString(exit_deal, DEAL_COMMENT);
    
    long magic = HistoryDealGetInteger(entry_deal, DEAL_MAGIC);
    
    // Debug information for troubleshooting
    Print("DEBUG: Entry Deal ID: ", entry_deal, " Exit Deal ID: ", exit_deal);
    Print("DEBUG: Entry Price: ", entry_price, " Exit Price: ", exit_price);
    Print("DEBUG: Entry Time: ", TimeToString(entry_time, TIME_DATE|TIME_SECONDS));
    Print("DEBUG: Exit Time: ", TimeToString(exit_time, TIME_DATE|TIME_SECONDS));
    Print("DEBUG: Volume: ", volume, " Symbol: ", symbol);
    
    // Data validation with fallback values
    if(entry_price <= 0.0)
    {
        Print("WARNING: Invalid entry price detected, attempting alternative retrieval...");
        // Try to get current market price as fallback
        entry_price = (entry_type == DEAL_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_ASK) : SymbolInfoDouble(symbol, SYMBOL_BID);
        Print("DEBUG: Using fallback entry price: ", entry_price);
    }
    
    if(exit_price <= 0.0)
    {
        Print("WARNING: Invalid exit price detected, attempting alternative retrieval...");
        // Try to get current market price as fallback
        exit_price = (exit_type == DEAL_TYPE_SELL) ? SymbolInfoDouble(symbol, SYMBOL_BID) : SymbolInfoDouble(symbol, SYMBOL_ASK);
        Print("DEBUG: Using fallback exit price: ", exit_price);
    }
    
    if(entry_time <= 0)
    {
        Print("WARNING: Invalid entry time detected, using current time...");
        entry_time = TimeCurrent();
        Print("DEBUG: Using fallback entry time: ", TimeToString(entry_time, TIME_DATE|TIME_SECONDS));
    }
    
    if(exit_time <= 0)
    {
        Print("WARNING: Invalid exit time detected, using current time...");
        exit_time = TimeCurrent();
        Print("DEBUG: Using fallback exit time: ", TimeToString(exit_time, TIME_DATE|TIME_SECONDS));
    }
    
    // Calculate trade metrics
    double pip_size = SymbolInfoDouble(symbol, SYMBOL_POINT);
    if(SymbolInfoInteger(symbol, SYMBOL_DIGITS) == 5 || SymbolInfoInteger(symbol, SYMBOL_DIGITS) == 3)
        pip_size *= 10;
    
    double price_difference = (entry_type == DEAL_TYPE_BUY) ? (exit_price - entry_price) : (entry_price - exit_price);
    double pips_gained = price_difference / pip_size;
    
    int trade_duration_seconds = (int)(exit_time - entry_time);
    int trade_duration_minutes = trade_duration_seconds / 60;
    int trade_duration_hours = trade_duration_minutes / 60;
    
    double net_profit = profit + commission + swap;
    
    // Determine exit reason
    string exit_reason = Determine_Exit_Reason(exit_comment);
    
    // Create comprehensive log entry
    string log_message = StringFormat(
        "\n=== TRADE EXIT LOG ===\n" +
        "Ticket: %I64u\n" +
        "Symbol: %s\n" +
        "Magic Number: %I64d\n" +
        "Direction: %s\n" +
        "Volume: %.2f\n" +
        "Entry Time: %s\n" +
        "Entry Price: %.5f\n" +
        "Entry Comment: %s\n" +
        "Exit Time: %s\n" +
        "Exit Price: %.5f\n" +
        "Exit Comment: %s\n" +
        "Exit Reason: %s\n" +
        "Price Movement: %.5f (%.1f pips)\n" +
        "Trade Duration: %d:%02d:%02d (%d seconds)\n" +
        "Gross Profit: %.2f\n" +
        "Commission: %.2f\n" +
        "Swap: %.2f\n" +
        "Net Profit: %.2f\n" +
        "======================",
        ticket,
        symbol,
        magic,
        (entry_type == DEAL_TYPE_BUY ? "BUY" : "SELL"),
        volume,
        TimeToString(entry_time, TIME_DATE|TIME_SECONDS),
        entry_price,
        entry_comment,
        TimeToString(exit_time, TIME_DATE|TIME_SECONDS),
        exit_price,
        exit_comment,
        exit_reason,
        price_difference,
        pips_gained,
        trade_duration_hours,
        (trade_duration_minutes % 60),
        (trade_duration_seconds % 60),
        trade_duration_seconds,
        profit,
        commission,
        swap,
        net_profit
    );
    
    // Print to Experts log
    Print(log_message);
    
    // Save to traditional log file
    bool file_saved = Save_Log_To_File(log_message, "TradeExit");
    
    // Save to CSV for Excel analysis
    bool csv_saved = Log_Trade_To_CSV(ticket, 
                                    (entry_type == DEAL_TYPE_BUY ? "BUY" : "SELL"),
                                    exit_reason, entry_price, exit_price, volume,
                                    entry_time, exit_time, net_profit, pips_gained,
                                    trade_duration_seconds, commission, swap);
    
    // Additional summary for quick reference
    Print("TRADE SUMMARY: ", (entry_type == DEAL_TYPE_BUY ? "BUY" : "SELL"), 
          " ", symbol, " | Volume: ", volume, 
          " | Pips: ", DoubleToString(pips_gained, 1),
          " | Net P/L: ", DoubleToString(net_profit, 2),
          " | Duration: ", trade_duration_hours, "h ", (trade_duration_minutes % 60), "m",
          " | Exit: ", exit_reason);
    
    return (file_saved && csv_saved);
}

//+------------------------------------------------------------------+
//| Log status of open position                                     |
//| Parameters: ticket - position ticket number                     |
//| Returns: true if logging successful, false otherwise            |
//+------------------------------------------------------------------+
bool Log_Open_Position_Status(ulong ticket)
{
    if(!PositionSelectByTicket(ticket))
    {
        Print("ERROR: Could not select position with ticket: ", ticket);
        return false;
    }
    
    string symbol = PositionGetString(POSITION_SYMBOL);
    ENUM_POSITION_TYPE position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    double volume = PositionGetDouble(POSITION_VOLUME);
    double price_open = PositionGetDouble(POSITION_PRICE_OPEN);
    double price_current = PositionGetDouble(POSITION_PRICE_CURRENT);
    double profit = PositionGetDouble(POSITION_PROFIT);
    double sl = PositionGetDouble(POSITION_SL);
    double tp = PositionGetDouble(POSITION_TP);
    datetime time_open = (datetime)PositionGetInteger(POSITION_TIME);
    long magic = PositionGetInteger(POSITION_MAGIC);
    string comment = PositionGetString(POSITION_COMMENT);
    
    // Calculate unrealized metrics
    double pip_size = SymbolInfoDouble(symbol, SYMBOL_POINT);
    if(SymbolInfoInteger(symbol, SYMBOL_DIGITS) == 5 || SymbolInfoInteger(symbol, SYMBOL_DIGITS) == 3)
        pip_size *= 10;
    
    double price_difference = (position_type == POSITION_TYPE_BUY) ? 
                             (price_current - price_open) : (price_open - price_current);
    double pips_unrealized = price_difference / pip_size;
    
    int position_duration = (int)(TimeCurrent() - time_open);
    
    string log_message = StringFormat(
        "\n=== OPEN POSITION STATUS ===\n" +
        "Ticket: %I64u\n" +
        "Symbol: %s\n" +
        "Magic Number: %I64d\n" +
        "Direction: %s\n" +
        "Volume: %.2f\n" +
        "Open Time: %s\n" +
        "Open Price: %.5f\n" +
        "Current Price: %.5f\n" +
        "Stop Loss: %.5f\n" +
        "Take Profit: %.5f\n" +
        "Comment: %s\n" +
        "Unrealized P/L: %.2f (%.1f pips)\n" +
        "Position Age: %d seconds\n" +
        "============================",
        ticket,
        symbol,
        magic,
        (position_type == POSITION_TYPE_BUY ? "BUY" : "SELL"),
        volume,
        TimeToString(time_open, TIME_DATE|TIME_SECONDS),
        price_open,
        price_current,
        sl,
        tp,
        comment,
        profit,
        pips_unrealized,
        position_duration
    );
    
    Print(log_message);
    return Save_Log_To_File(log_message, "PositionStatus");
}

//+------------------------------------------------------------------+
//| Determine exit reason from comment                              |
//| Parameters: comment - exit deal comment                         |
//| Returns: string describing exit reason                          |
//+------------------------------------------------------------------+
string Determine_Exit_Reason(string comment)
{
    // Convert to lowercase for case-insensitive comparison
    string lower_comment = comment;
    StringToLower(lower_comment);
    
    // Check for stop loss indicators
    int sl_pos = StringFind(lower_comment, "sl", 0);
    int stop_loss_pos = StringFind(lower_comment, "stop loss", 0);
    if(sl_pos != -1 || stop_loss_pos != -1)
        return "Stop Loss Hit";
    
    // Check for take profit indicators
    int tp_pos = StringFind(lower_comment, "tp", 0);
    int take_profit_pos = StringFind(lower_comment, "take profit", 0);
    if(tp_pos != -1 || take_profit_pos != -1)
        return "Take Profit Hit";
    
    // Check for trailing stop
    int trailing_pos = StringFind(lower_comment, "trailing", 0);
    if(trailing_pos != -1)
        return "Trailing Stop";
    
    // Check for manual close
    int manual_pos = StringFind(lower_comment, "manual", 0);
    if(manual_pos != -1)
        return "Manual Close";
    
    // Check for margin call
    int margin_pos = StringFind(lower_comment, "margin", 0);
    if(margin_pos != -1)
        return "Margin Call";
    
    // Check for expert advisor close
    int expert_pos = StringFind(lower_comment, "expert", 0);
    int ea_pos = StringFind(lower_comment, "ea", 0);
    if(expert_pos != -1 || ea_pos != -1)
        return "EA Close";
    
    // Default case - unknown reason
    return "Unknown (" + comment + ")";
}

//+------------------------------------------------------------------+
//| CSV LOGGING FUNCTIONS - Excel Ready Format                     |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Create CSV Trade Log (Excel Ready)                             |
//| Parameters: All trade details for CSV format                   |
//| Returns: true if CSV logging successful, false otherwise       |
//+------------------------------------------------------------------+
bool Log_Trade_To_CSV(ulong ticket, string trade_type, string exit_reason, 
                     double entry_price, double exit_price, double volume,
                     datetime entry_time, datetime exit_time, double net_profit,
                     double pips_gained, int duration_seconds, double commission, double swap)
{
    if(!USE_CSV_FORMAT)
        return true; // Skip CSV if not enabled
        
    string csv_filename = LOG_FILE_PREFIX + "TradeHistory.csv";
    
    // Check if file exists to decide whether to write header
    bool file_exists = false;
    int test_handle = FileOpen(csv_filename, FILE_READ|FILE_TXT);
    if(test_handle != INVALID_HANDLE)
    {
        file_exists = true;
        FileClose(test_handle);
    }
    
    // Open file for append
    int file_handle = FileOpen(csv_filename, FILE_WRITE|FILE_READ|FILE_TXT);
    if(file_handle == INVALID_HANDLE)
    {
        Print("ERROR: Cannot create CSV trade file: ", csv_filename);
        return false;
    }
    
    // Move to end for append
    FileSeek(file_handle, 0, SEEK_END);
    
    // Write header if new file
    if(!file_exists)
    {
        string header = "Ticket" + CSV_SEPARATOR + "TradeType" + CSV_SEPARATOR + "Symbol" + CSV_SEPARATOR + 
                       "EntryTime" + CSV_SEPARATOR + "ExitTime" + CSV_SEPARATOR + "Duration(Sec)" + CSV_SEPARATOR + 
                       "Duration(Min)" + CSV_SEPARATOR + "Duration(Hours)" + CSV_SEPARATOR +
                       "EntryPrice" + CSV_SEPARATOR + "ExitPrice" + CSV_SEPARATOR + "Volume" + CSV_SEPARATOR + 
                       "Pips" + CSV_SEPARATOR + "GrossProfit" + CSV_SEPARATOR + "Commission" + CSV_SEPARATOR + 
                       "Swap" + CSV_SEPARATOR + "NetProfit" + CSV_SEPARATOR + "ExitReason" + CSV_SEPARATOR + 
                       "MagicNumber" + CSV_SEPARATOR + "TestDate\n";
        FileWriteString(file_handle, header);
    }
    
    // Calculate additional metrics
    int duration_minutes = duration_seconds / 60;
    double duration_hours = (double)duration_seconds / 3600.0;
    double gross_profit = net_profit - commission - swap;
    
    // Write trade data with proper CSV formatting
    string csv_line = StringFormat("%I64u%s%s%s%s%s%s%s%s%s%d%s%d%s%.2f%s%.5f%s%.5f%s%.2f%s%.1f%s%.2f%s%.2f%s%.2f%s%.2f%s%s%s%d%s%s\n",
        ticket, CSV_SEPARATOR,
        trade_type, CSV_SEPARATOR,
        Symbol(), CSV_SEPARATOR,
        TimeToString(entry_time, TIME_DATE|TIME_SECONDS), CSV_SEPARATOR,
        TimeToString(exit_time, TIME_DATE|TIME_SECONDS), CSV_SEPARATOR,
        duration_seconds, CSV_SEPARATOR,
        duration_minutes, CSV_SEPARATOR,
        duration_hours, CSV_SEPARATOR,
        entry_price, CSV_SEPARATOR,
        exit_price, CSV_SEPARATOR,
        volume, CSV_SEPARATOR,
        pips_gained, CSV_SEPARATOR,
        gross_profit, CSV_SEPARATOR,
        commission, CSV_SEPARATOR,
        swap, CSV_SEPARATOR,
        net_profit, CSV_SEPARATOR,
        exit_reason, CSV_SEPARATOR,
        MAGIC_NUMBER, CSV_SEPARATOR,
        TimeToString(TimeCurrent(), TIME_DATE)
    );
    
    FileWriteString(file_handle, csv_line);
    FileClose(file_handle);
    
    Print("CSV TRADE LOG: Recorded to ", csv_filename, " | Ticket: ", ticket, " | Net P/L: ", DoubleToString(net_profit, 2));
    return true;
}

//+------------------------------------------------------------------+
//| Create CSV Signal Log (Excel Ready)                            |
//| Parameters: Signal analysis details for CSV format             |
//| Returns: true if CSV logging successful, false otherwise       |
//+------------------------------------------------------------------+
bool Log_Signal_To_CSV(string signal_type, bool signal_result, bool trend_status,
                      bool pullback_status, bool pattern_status, double spread_pips,
                      double current_bid, double current_ask)
{
    if(!USE_CSV_FORMAT)
        return true; // Skip CSV if not enabled
        
    string csv_filename = LOG_FILE_PREFIX + "SignalHistory.csv";
    
    // Check if file exists
    bool file_exists = false;
    int test_handle = FileOpen(csv_filename, FILE_READ|FILE_TXT);
    if(test_handle != INVALID_HANDLE)
    {
        file_exists = true;
        FileClose(test_handle);
    }
    
    int file_handle = FileOpen(csv_filename, FILE_WRITE|FILE_READ|FILE_TXT);
    if(file_handle == INVALID_HANDLE)
    {
        Print("ERROR: Cannot create CSV signal file: ", csv_filename);
        return false;
    }
    
    FileSeek(file_handle, 0, SEEK_END);
    
    // Write header if new file
    if(!file_exists)
    {
        string header = "DateTime" + CSV_SEPARATOR + "SignalType" + CSV_SEPARATOR + "SignalResult" + CSV_SEPARATOR + 
                       "TrendStatus" + CSV_SEPARATOR + "PullbackStatus" + CSV_SEPARATOR + "PatternStatus" + CSV_SEPARATOR + 
                       "Spread(Pips)" + CSV_SEPARATOR + "Bid" + CSV_SEPARATOR + "Ask" + CSV_SEPARATOR + 
                       "Symbol" + CSV_SEPARATOR + "Timeframe" + CSV_SEPARATOR + "TestDate\n";
        FileWriteString(file_handle, header);
    }
    
    // Write signal data
    string csv_line = StringFormat("%s%s%s%s%s%s%s%s%s%s%s%s%.1f%s%.5f%s%.5f%s%s%s%s%s%s\n",
        TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), CSV_SEPARATOR,
        signal_type, CSV_SEPARATOR,
        (signal_result ? "SIGNAL" : "NO_SIGNAL"), CSV_SEPARATOR,
        (trend_status ? "PASS" : "FAIL"), CSV_SEPARATOR,
        (pullback_status ? "PASS" : "FAIL"), CSV_SEPARATOR,
        (pattern_status ? "PASS" : "FAIL"), CSV_SEPARATOR,
        spread_pips, CSV_SEPARATOR,
        current_bid, CSV_SEPARATOR,
        current_ask, CSV_SEPARATOR,
        Symbol(), CSV_SEPARATOR,
        "H4", CSV_SEPARATOR,
        TimeToString(TimeCurrent(), TIME_DATE)
    );
    
    FileWriteString(file_handle, csv_line);
    FileClose(file_handle);
    
    return true;
}

//+------------------------------------------------------------------+
//| Create CSV Execution Log (Excel Ready)                         |
//| Parameters: Execution attempt details for CSV format           |
//| Returns: true if CSV logging successful, false otherwise       |
//+------------------------------------------------------------------+
bool Log_Execution_To_CSV(string order_type, bool execution_result, double calculated_sl, 
                         double calculated_tp, double calculated_lot, double execution_price, 
                         uint result_code, ulong ticket_number, double risk_percentage, 
                         double risk_reward_ratio, double rsi_m15 = 0.0, double rsi_m5 = 0.0, 
                         double rsi_m1 = 0.0, bool multi_tf_compliant = false)
{
    if(!USE_CSV_FORMAT)
        return true; // Skip CSV if not enabled
        
    string csv_filename = LOG_FILE_PREFIX + "ExecutionHistory.csv";
    
    // Check if file exists
    bool file_exists = false;
    int test_handle = FileOpen(csv_filename, FILE_READ|FILE_TXT);
    if(test_handle != INVALID_HANDLE)
    {
        file_exists = true;
        FileClose(test_handle);
    }
    
    int file_handle = FileOpen(csv_filename, FILE_WRITE|FILE_READ|FILE_TXT);
    if(file_handle == INVALID_HANDLE)
    {
        Print("ERROR: Cannot create CSV execution file: ", csv_filename);
        return false;
    }
    
    FileSeek(file_handle, 0, SEEK_END);
    
    // Write header if new file
    if(!file_exists)
    {
        string header = "DateTime" + CSV_SEPARATOR + "OrderType" + CSV_SEPARATOR + "ExecutionResult" + CSV_SEPARATOR + 
                       "Ticket" + CSV_SEPARATOR + "LotSize" + CSV_SEPARATOR + "ExecutionPrice" + CSV_SEPARATOR + 
                       "StopLoss" + CSV_SEPARATOR + "TakeProfit" + CSV_SEPARATOR + "RiskRewardRatio" + CSV_SEPARATOR + 
                       "RiskPercentage" + CSV_SEPARATOR + "RSI_M15" + CSV_SEPARATOR + "RSI_M5" + CSV_SEPARATOR + 
                       "RSI_M1" + CSV_SEPARATOR + "Multi_TF_Compliant" + CSV_SEPARATOR + "ResultCode" + CSV_SEPARATOR + 
                       "Symbol" + CSV_SEPARATOR + "TestDate\n";
        FileWriteString(file_handle, header);
    }
    
    // Write execution data with RSI values
    string csv_line = StringFormat("%s%s%s%s%s%s%I64u%s%.2f%s%.5f%s%.5f%s%.5f%s%.2f%s%.2f%s%.2f%s%.2f%s%.2f%s%s%s%u%s%s%s%s\n",
        TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), CSV_SEPARATOR,
        order_type, CSV_SEPARATOR,
        (execution_result ? "SUCCESS" : "FAILED"), CSV_SEPARATOR,
        ticket_number, CSV_SEPARATOR,
        calculated_lot, CSV_SEPARATOR,
        execution_price, CSV_SEPARATOR,
        calculated_sl, CSV_SEPARATOR,
        calculated_tp, CSV_SEPARATOR,
        risk_reward_ratio, CSV_SEPARATOR,
        risk_percentage, CSV_SEPARATOR,
        rsi_m15, CSV_SEPARATOR,
        rsi_m5, CSV_SEPARATOR,
        rsi_m1, CSV_SEPARATOR,
        (multi_tf_compliant ? "YES" : "NO"), CSV_SEPARATOR,
        result_code, CSV_SEPARATOR,
        Symbol(), CSV_SEPARATOR,
        TimeToString(TimeCurrent(), TIME_DATE)
    );
    
    FileWriteString(file_handle, csv_line);
    FileClose(file_handle);
    
    return true;
}

//+------------------------------------------------------------------+
//| Generate Comprehensive Backtest Summary Report (Excel Ready)   |
//| Returns: true if report generated successfully                  |
//+------------------------------------------------------------------+
bool Generate_Backtest_Summary_Report()
{
    if(!USE_CSV_FORMAT)
        return true; // Skip if CSV not enabled
        
    string summary_filename = LOG_FILE_PREFIX + "Summary_Report.csv";
    
    int file_handle = FileOpen(summary_filename, FILE_WRITE|FILE_TXT);
    if(file_handle == INVALID_HANDLE)
    {
        Print("ERROR: Cannot create summary report: ", summary_filename);
        return false;
    }
    
    // Initialize statistics
    int total_trades = 0;
    int winning_trades = 0;
    int losing_trades = 0;
    double total_profit = 0.0;
    double total_loss = 0.0;
    double max_profit = 0.0;
    double max_loss = 0.0;
    double total_commission = 0.0;
    double total_swap = 0.0;
    int total_pips = 0;
    
    // Analyze trading history
    datetime start_time = 0;
    datetime end_time = TimeCurrent();
    
    if(!HistorySelect(start_time, end_time))
    {
        Print("ERROR: Cannot access trading history for summary");
        FileClose(file_handle);
        return false;
    }
    
    int total_deals = HistoryDealsTotal();
    
    for(int i = 0; i < total_deals; i++)
    {
        ulong deal_ticket = HistoryDealGetTicket(i);
        if(deal_ticket > 0)
        {
            long magic = HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
            string symbol = HistoryDealGetString(deal_ticket, DEAL_SYMBOL);
            
            // Filter by our EA and symbol
            if(magic == MAGIC_NUMBER && symbol == Symbol())
            {
                ENUM_DEAL_TYPE deal_type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal_ticket, DEAL_TYPE);
                
                // Only count exit deals to avoid double counting
                if(deal_type == DEAL_TYPE_BUY || deal_type == DEAL_TYPE_SELL)
                {
                    double profit = HistoryDealGetDouble(deal_ticket, DEAL_PROFIT);
                    double commission = HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION);
                    double swap = HistoryDealGetDouble(deal_ticket, DEAL_SWAP);
                    
                    total_commission += commission;
                    total_swap += swap;
                    
                    if(profit > 0)
                    {
                        winning_trades++;
                        total_profit += profit;
                        if(profit > max_profit) max_profit = profit;
                    }
                    else if(profit < 0)
                    {
                        losing_trades++;
                        total_loss += profit;
                        if(profit < max_loss) max_loss = profit;
                    }
                    total_trades++;
                }
            }
        }
    }
    
    // Calculate metrics
    double win_rate = total_trades > 0 ? (double)winning_trades / total_trades * 100.0 : 0.0;
    double net_profit = total_profit + total_loss;
    double profit_factor = (total_loss != 0) ? total_profit / MathAbs(total_loss) : 0.0;
    double avg_win = winning_trades > 0 ? total_profit / winning_trades : 0.0;
    double avg_loss = losing_trades > 0 ? total_loss / losing_trades : 0.0;
    
    // Get account information
    double initial_balance = 10000.0; // Default, you may want to track this
    double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double return_percentage = (current_balance - initial_balance) / initial_balance * 100.0;
    
    // Create comprehensive summary
    string report = "";
    
    // CSV Header with metadata and performance metrics
    report += "Metric,Value\n";
    report += StringFormat("Report_Type,%s\n", "BACKTEST SUMMARY REPORT");
    report += StringFormat("Generated_Date,%s\n", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS));
    report += StringFormat("Symbol,%s\n", Symbol());
    report += StringFormat("Magic_Number,%d\n", MAGIC_NUMBER);
    report += StringFormat("Test_Period_Start,%s\n", TimeToString(start_time, TIME_DATE));
    report += StringFormat("Test_Period_End,%s\n", TimeToString(end_time, TIME_DATE));
    report += "Section,TRADING_PERFORMANCE\n";
    report += StringFormat("Total Trades,%d\n", total_trades);
    report += StringFormat("Winning Trades,%d\n", winning_trades);
    report += StringFormat("Losing Trades,%d\n", losing_trades);
    report += StringFormat("Win Rate,%.2f%%\n", win_rate);
    report += StringFormat("Gross Profit,%.2f\n", total_profit);
    report += StringFormat("Gross Loss,%.2f\n", total_loss);
    report += StringFormat("Net Profit,%.2f\n", net_profit);
    report += StringFormat("Profit Factor,%.2f\n", profit_factor);
    report += StringFormat("Average Win,%.2f\n", avg_win);
    report += StringFormat("Average Loss,%.2f\n", avg_loss);
    report += StringFormat("Max Single Win,%.2f\n", max_profit);
    report += StringFormat("Max Single Loss,%.2f\n", max_loss);
    report += StringFormat("Total Commission,%.2f\n", total_commission);
    report += StringFormat("Total Swap,%.2f\n", total_swap);
    report += "Section,ACCOUNT_INFORMATION\n";
    report += StringFormat("Initial Balance,%.2f\n", initial_balance);
    report += StringFormat("Final Balance,%.2f\n", current_balance);
    report += StringFormat("Current Equity,%.2f\n", current_equity);
    report += StringFormat("Return Percentage,%.2f%%\n", return_percentage);
    report += "Section,RISK_METRICS\n";
    double max_drawdown = 0.0; // You may want to calculate this properly
    report += StringFormat("Maximum Drawdown,%.2f\n", max_drawdown);
    report += StringFormat("Recovery Factor,%.2f\n", max_drawdown != 0 ? net_profit / max_drawdown : 0.0);
    report += "Section,FILES_GENERATED\n";
    report += StringFormat("Trade_History_File,%s\n", LOG_FILE_PREFIX + "TradeHistory.csv");
    report += StringFormat("Signal_History_File,%s\n", LOG_FILE_PREFIX + "SignalHistory.csv");
    report += StringFormat("Execution_History_File,%s\n", LOG_FILE_PREFIX + "ExecutionHistory.csv");
    report += StringFormat("Summary_Report_File,%s\n", summary_filename);
    
    // Write report to file
    FileWriteString(file_handle, report);
    FileClose(file_handle);
    
    Print("✅ BACKTEST SUMMARY REPORT CREATED: ", summary_filename);
    Print("📊 Total Trades: ", total_trades, " | Win Rate: ", DoubleToString(win_rate, 1), "% | Net P/L: ", DoubleToString(net_profit, 2));
    
    return true;
}

//+------------------------------------------------------------------+
//| Save log message to file (FIXED VERSION)                       |
//| Parameters: message - log message to save                       |
//|            log_type - type of log (TradeExit, PositionStatus)   |
//| Returns: true if file save successful, false otherwise          |
//+------------------------------------------------------------------+
bool Save_Log_To_File(string message, string log_type)
{
    // Skip traditional logging if CSV format is enabled and log frequency is limited
    if(USE_CSV_FORMAT && Is_Log_Frequency_Limited())
    {
        // Only save critical logs when frequency is limited
        if(log_type != "TradeExit" && log_type != "ExecutionSuccess" && log_type != "ExecutionFailure")
        {
            return true; // Skip non-critical logs
        }
    }
    
    string filename = "";
    
    if(Use_Single_Log_File() && USE_CSV_FORMAT)
    {
        // Single log file for backtest data
        filename = LOG_FILE_PREFIX + "BacktestLog.txt";
    }
    else
    {
        // Traditional naming scheme with mode-specific settings
        string date_str = "";
        
        if(Is_Backtest_Mode())
        {
            // Backtest: Use computer timestamp for unique files per test run
            datetime computer_time = TimeLocal();  // Computer's local time
            date_str = TimeToString(computer_time, TIME_DATE|TIME_SECONDS);
            StringReplace(date_str, ".", "_");  // Replace dots with underscores
            StringReplace(date_str, ":", "_");  // Replace colons with underscores  
            StringReplace(date_str, " ", "_");  // Replace spaces with underscores
        }
        else
        {
            // Live Trading: Use trading date for grouping by trading day
            string market_date = TimeToString(TimeCurrent(), TIME_DATE);
            StringReplace(market_date, ".", "_");  // Replace dots with underscores
            StringReplace(market_date, ":", "_");  // Replace colons with underscores
            StringReplace(market_date, " ", "_");  // Replace spaces with underscores
            date_str = market_date;
        }
        
        filename = LOG_FILE_PREFIX + log_type + "_" + date_str + ".log";
    }
    
    // Always use standard MQL5/Files directory for consistency
    int file_handle = FileOpen(filename, FILE_WRITE|FILE_READ|FILE_TXT|FILE_ANSI);
    
    if(file_handle == INVALID_HANDLE)
    {
        int error_code = GetLastError();
        Print("ERROR: Failed to open log file: ", filename);
        Print("Target location: MQL5/Files directory");
        Print("Error Code: ", error_code);
        Print("Error Description: ", Get_Error_Description(error_code));
        return false;
    }
    
    // Move to end of file for append
    FileSeek(file_handle, 0, SEEK_END);
    
    // Add timestamp and log type to message
    string timestamped_message = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + 
                                " | [" + log_type + "] | " + message + "\n\n";
    
    uint bytes_written = FileWriteString(file_handle, timestamped_message);
    FileClose(file_handle);
    
    if(bytes_written > 0)
    {
        if(!Is_Log_Frequency_Limited() || log_type == "TradeExit")
        {
            Print("LOG: Saved to ", filename, " (", bytes_written, " bytes)");
        }
        return true;
    }
    else
    {
        Print("ERROR: Failed to write to log file: ", filename);
        return false;
    }
}

//+------------------------------------------------------------------+
//| Log Signal Check Results for Buy/Sell Analysis                 |
//| Parameters: signal_type - "BUY" or "SELL"                      |
//|            signal_result - true if signal found, false if not   |
//|            trend_status - trend analysis result                 |
//|            pullback_status - pullback zone analysis result     |
//|            pattern_status - pattern confirmation result        |
//| Returns: true if logging successful, false otherwise            |
//+------------------------------------------------------------------+
bool Log_Signal_Check(string signal_type, bool signal_result, bool trend_status, bool pullback_status, bool pattern_status)
{
    if(signal_type != "BUY" && signal_type != "SELL")
    {
        Print("ERROR: Invalid signal type provided to Log_Signal_Check: ", signal_type);
        return false;
    }
    
    // Get current market data for context
    double current_bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double current_ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double current_spread = current_ask - current_bid;
    
    // Convert spread to pips
    double pip_size = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
    if(SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 5 || SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 3)
        pip_size *= 10;
    double spread_pips = current_spread / pip_size;
    
    // Get additional market context
    datetime current_time = TimeCurrent();
    string timeframe_str = "H4"; // Our analysis timeframe
    
    // Create detailed signal analysis log
    string log_message = StringFormat(
        "\n=== SIGNAL CHECK LOG ===\n" +
        "Signal Type: %s\n" +
        "Signal Result: %s\n" +
        "Check Time: %s\n" +
        "Symbol: %s\n" +
        "Timeframe: %s\n" +
        "Current Bid: %.5f\n" +
        "Current Ask: %.5f\n" +
        "Spread: %.1f pips\n" +
        "--- Analysis Breakdown ---\n" +
        "1. Trend Analysis (D1): %s\n" +
        "2. Pullback Zone (H4): %s\n" +
        "3. Pattern Confirmation (H4): %s\n" +
        "--- Signal Logic ---\n" +
        "Required: ALL conditions must be TRUE\n" +
        "Result: %s\n" +
        "========================",
        signal_type,
        (signal_result ? "SIGNAL FOUND" : "NO SIGNAL"),
        TimeToString(current_time, TIME_DATE|TIME_SECONDS),
        Symbol(),
        timeframe_str,
        current_bid,
        current_ask,
        spread_pips,
        (trend_status ? "PASS" : "FAIL"),
        (pullback_status ? "PASS" : "FAIL"),
        (pattern_status ? "PASS" : "FAIL"),
        (signal_result ? "SIGNAL CONFIRMED" : "SIGNAL REJECTED")
    );
    
    // Print to Experts log
    Print(log_message);
    
    // Create summary for quick reference
    string summary = StringFormat("SIGNAL CHECK: %s | Result: %s | Trend: %s | Pullback: %s | Pattern: %s | Spread: %.1f pips",
        signal_type,
        (signal_result ? "FOUND" : "NONE"),
        (trend_status ? "OK" : "NO"),
        (pullback_status ? "OK" : "NO"),
        (pattern_status ? "OK" : "NO"),
        spread_pips
    );
    
    Print(summary);
    
    // Save to traditional log file
    bool file_saved = Save_Log_To_File(log_message, "SignalCheck");
    
    // Save to CSV for Excel analysis
    bool csv_saved = Log_Signal_To_CSV(signal_type, signal_result, trend_status,
                                     pullback_status, pattern_status, spread_pips,
                                     current_bid, current_ask);
    
    return (file_saved && csv_saved);
}

//+------------------------------------------------------------------+
//| Log Signal Check with Detailed Market Analysis                 |
//| Parameters: signal_type - "BUY" or "SELL"                      |
//|            signal_result - true if signal found, false if not   |
//|            analysis_details - detailed breakdown of analysis    |
//| Returns: true if logging successful, false otherwise            |
//+------------------------------------------------------------------+
bool Log_Signal_Check_Detailed(string signal_type, bool signal_result, string analysis_details)
{
    if(signal_type != "BUY" && signal_type != "SELL")
    {
        Print("ERROR: Invalid signal type provided to Log_Signal_Check_Detailed: ", signal_type);
        return false;
    }
    
    // Get current market data
    double current_bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double current_ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    datetime current_time = TimeCurrent();
    
    // Create comprehensive log with custom analysis details
    string log_message = StringFormat(
        "\n=== DETAILED SIGNAL ANALYSIS ===\n" +
        "Signal Type: %s\n" +
        "Signal Result: %s\n" +
        "Analysis Time: %s\n" +
        "Symbol: %s\n" +
        "Current Bid: %.5f\n" +
        "Current Ask: %.5f\n" +
        "--- Detailed Analysis ---\n" +
        "%s\n" +
        "--- Final Decision ---\n" +
        "Signal Status: %s\n" +
        "===============================",
        signal_type,
        (signal_result ? "SIGNAL CONFIRMED" : "NO SIGNAL"),
        TimeToString(current_time, TIME_DATE|TIME_SECONDS),
        Symbol(),
        current_bid,
        current_ask,
        analysis_details,
        (signal_result ? "PROCEED TO EXECUTION" : "WAIT FOR BETTER SETUP")
    );
    
    // Print to Experts log
    Print(log_message);
    
    // Save to file
    bool file_saved = Save_Log_To_File(log_message, "DetailedSignal");
    
    return file_saved;
}

//+------------------------------------------------------------------+
//| Log Signal Check Failure with Reasons                          |
//| Parameters: signal_type - "BUY" or "SELL"                      |
//|            failed_conditions - array of failed condition names  |
//|            condition_count - number of failed conditions        |
//| Returns: true if logging successful, false otherwise            |
//+------------------------------------------------------------------+
bool Log_Signal_Check_Failure(string signal_type, string &failed_conditions[], int condition_count)
{
    if(signal_type != "BUY" && signal_type != "SELL")
    {
        Print("ERROR: Invalid signal type provided to Log_Signal_Check_Failure: ", signal_type);
        return false;
    }
    
    // Build failed conditions list
    string failed_list = "";
    for(int i = 0; i < condition_count; i++)
    {
        failed_list += "- " + failed_conditions[i] + "\n";
    }
    
    // Get current market data
    datetime current_time = TimeCurrent();
    
    // Create failure analysis log
    string log_message = StringFormat(
        "\n=== SIGNAL CHECK FAILURE ===\n" +
        "Signal Type: %s\n" +
        "Check Time: %s\n" +
        "Symbol: %s\n" +
        "Failed Conditions (%d):\n" +
        "%s" +
        "Action: Wait for better setup\n" +
        "============================",
        signal_type,
        TimeToString(current_time, TIME_DATE|TIME_SECONDS),
        Symbol(),
        condition_count,
        failed_list
    );
    
    // Print to Experts log
    Print(log_message);
    
    // Create quick summary
    Print("SIGNAL FAILURE: ", signal_type, " - ", condition_count, " conditions failed");
    
    // Save to file
    bool file_saved = Save_Log_To_File(log_message, "SignalFailure");
    
    return file_saved;
}

//+------------------------------------------------------------------+
//| Log Trade Execution Attempt with Full Details                  |
//| Parameters: order_type - ORDER_TYPE_BUY or ORDER_TYPE_SELL     |
//|            execution_result - true if successful, false if not  |
//|            calculated_sl - calculated stop loss price           |
//|            calculated_tp - calculated take profit price         |
//|            calculated_lot - calculated lot size                 |
//|            execution_price - price used for execution           |
//|            result_code - trade server return code               |
//|            ticket_number - resulting ticket (0 if failed)       |
//|            risk_percentage - risk as percentage of balance      |
//|            risk_reward_ratio - risk to reward ratio             |
//| Returns: true if logging successful, false otherwise            |
//+------------------------------------------------------------------+
bool Log_Execution_Attempt(int order_type, bool execution_result, double calculated_sl, double calculated_tp, 
                          double calculated_lot, double execution_price, uint result_code, ulong ticket_number,
                          double risk_percentage, double risk_reward_ratio, 
                          double rsi_m15 = 0.0, double rsi_m5 = 0.0, double rsi_m1 = 0.0, bool multi_tf_compliant = false)
{
    if(order_type != ORDER_TYPE_BUY && order_type != ORDER_TYPE_SELL)
    {
        Print("ERROR: Invalid order type provided to Log_Execution_Attempt: ", order_type);
        return false;
    }
    
    // Get current market data
    double current_bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double current_ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double current_spread = current_ask - current_bid;
    datetime execution_time = TimeCurrent();
    
    // Convert spread to pips
    double pip_size = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
    if(SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 5 || SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 3)
        pip_size *= 10;
    double spread_pips = current_spread / pip_size;
    
    // Calculate risk metrics
    double sl_distance = 0.0;
    double tp_distance = 0.0;
    
    if(order_type == ORDER_TYPE_BUY)
    {
        sl_distance = execution_price - calculated_sl;
        tp_distance = calculated_tp - execution_price;
    }
    else
    {
        sl_distance = calculated_sl - execution_price;
        tp_distance = execution_price - calculated_tp;
    }
    
    if(sl_distance > 0)
        risk_reward_ratio = tp_distance / sl_distance;
    
    double sl_pips = sl_distance / pip_size;
    double tp_pips = tp_distance / pip_size;
    
    // Get account information
    double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double account_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    // Calculate position value
    double position_value = calculated_lot * execution_price * SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE);
    double risk_amount = sl_distance * calculated_lot * SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE) / SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
    risk_percentage = (risk_amount / account_balance) * 100.0;
    
    // Get return code description
    string result_description = Get_Execution_Retcode_Description(result_code);
    
    // Create comprehensive execution log
    string log_message = StringFormat(
        "\n=== TRADE EXECUTION ATTEMPT ===\n" +
        "Execution Time: %s\n" +
        "Order Type: %s\n" +
        "Execution Result: %s\n" +
        "Symbol: %s\n" +
        "--- Market Conditions ---\n" +
        "Current Bid: %.5f\n" +
        "Current Ask: %.5f\n" +
        "Spread: %.1f pips\n" +
        "Execution Price: %.5f\n" +
        "--- Calculated Parameters ---\n" +
        "Lot Size: %.2f\n" +
        "Stop Loss: %.5f (%.1f pips)\n" +
        "Take Profit: %.5f (%.1f pips)\n" +
        "Risk:Reward Ratio: %.2f:1\n" +
        "--- Risk Management ---\n" +
        "Account Balance: %.2f\n" +
        "Account Equity: %.2f\n" +
        "Position Value: %.2f\n" +
        "Risk Amount: %.2f\n" +
        "Risk Percentage: %.2f%%\n" +
        "--- Multi-Timeframe RSI Analysis ---\n" +
        "RSI M15: %.2f\n" +
        "RSI M5: %.2f\n" +
        "RSI M1: %.2f\n" +
        "Multi-TF Compliant: %s\n" +
        "--- Execution Result ---\n" +
        "Return Code: %u\n" +
        "Result Description: %s\n" +
        "Ticket Number: %I64u\n" +
        "Status: %s\n" +
        "===============================",
        TimeToString(execution_time, TIME_DATE|TIME_SECONDS),
        (order_type == ORDER_TYPE_BUY ? "BUY" : "SELL"),
        (execution_result ? "SUCCESS" : "FAILED"),
        Symbol(),
        current_bid,
        current_ask,
        spread_pips,
        execution_price,
        calculated_lot,
        calculated_sl,
        sl_pips,
        calculated_tp,
        tp_pips,
        risk_reward_ratio,
        account_balance,
        account_equity,
        position_value,
        risk_amount,
        risk_percentage,
        rsi_m15,
        rsi_m5,
        rsi_m1,
        (multi_tf_compliant ? "YES" : "NO"),
        result_code,
        result_description,
        ticket_number,
        (execution_result ? "TRADE OPENED SUCCESSFULLY" : "TRADE EXECUTION FAILED")
    );
    
    // Print to Experts log
    Print(log_message);
    
    // Create execution summary for quick reference
    string summary = StringFormat("EXECUTION: %s | Result: %s | Ticket: %I64u | Lot: %.2f | SL: %.1f pips | TP: %.1f pips | Risk: %.2f%% | Code: %u",
        (order_type == ORDER_TYPE_BUY ? "BUY" : "SELL"),
        (execution_result ? "SUCCESS" : "FAILED"),
        ticket_number,
        calculated_lot,
        sl_pips,
        tp_pips,
        risk_percentage,
        result_code
    );
    
    Print(summary);
    
    // Save to traditional log file
    string log_type = execution_result ? "ExecutionSuccess" : "ExecutionFailure";
    bool file_saved = Save_Log_To_File(log_message, log_type);
    
    // Save to CSV for Excel analysis with RSI data
    bool csv_saved = Log_Execution_To_CSV((order_type == ORDER_TYPE_BUY ? "BUY" : "SELL"),
                                         execution_result, calculated_sl, calculated_tp,
                                         calculated_lot, execution_price, result_code,
                                         ticket_number, risk_percentage, risk_reward_ratio,
                                         rsi_m15, rsi_m5, rsi_m1, multi_tf_compliant);
    
    return (file_saved && csv_saved);
}

//+------------------------------------------------------------------+
//| Log Pre-Execution Validation Results                           |
//| Parameters: order_type - ORDER_TYPE_BUY or ORDER_TYPE_SELL     |
//|            validation_passed - true if all validations passed   |
//|            validation_details - detailed validation breakdown   |
//| Returns: true if logging successful, false otherwise            |
//+------------------------------------------------------------------+
bool Log_Pre_Execution_Validation(int order_type, bool validation_passed, string validation_details)
{
    if(order_type != ORDER_TYPE_BUY && order_type != ORDER_TYPE_SELL)
    {
        Print("ERROR: Invalid order type provided to Log_Pre_Execution_Validation: ", order_type);
        return false;
    }
    
    // Get current market data
    datetime validation_time = TimeCurrent();
    double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    // Create validation log
    string log_message = StringFormat(
        "\n=== PRE-EXECUTION VALIDATION ===\n" +
        "Validation Time: %s\n" +
        "Order Type: %s\n" +
        "Validation Result: %s\n" +
        "Symbol: %s\n" +
        "Account Balance: %.2f\n" +
        "Account Equity: %.2f\n" +
        "--- Validation Details ---\n" +
        "%s\n" +
        "--- Decision ---\n" +
        "Action: %s\n" +
        "===============================",
        TimeToString(validation_time, TIME_DATE|TIME_SECONDS),
        (order_type == ORDER_TYPE_BUY ? "BUY" : "SELL"),
        (validation_passed ? "PASSED" : "FAILED"),
        Symbol(),
        current_balance,
        current_equity,
        validation_details,
        (validation_passed ? "PROCEED TO EXECUTION" : "ABORT EXECUTION")
    );
    
    // Print to Experts log
    Print(log_message);
    
    // Save to file
    string log_type = validation_passed ? "ValidationPass" : "ValidationFail";
    bool file_saved = Save_Log_To_File(log_message, log_type);
    
    return file_saved;
}

//+------------------------------------------------------------------+
//| Get human readable description of execution return codes       |
//| Parameters: retcode - execution operation return code          |
//| Returns: string description of the return code                 |
//+------------------------------------------------------------------+
string Get_Execution_Retcode_Description(uint retcode)
{
    switch(retcode)
    {
        case TRADE_RETCODE_REQUOTE:         return "Requote - price has changed";
        case TRADE_RETCODE_REJECT:          return "Request rejected by server";
        case TRADE_RETCODE_CANCEL:          return "Request canceled by trader";
        case TRADE_RETCODE_PLACED:          return "Order placed successfully";
        case TRADE_RETCODE_DONE:            return "Request completed successfully";
        case TRADE_RETCODE_DONE_PARTIAL:    return "Request partially completed";
        case TRADE_RETCODE_ERROR:           return "Request processing error";
        case TRADE_RETCODE_TIMEOUT:         return "Request timeout";
        case TRADE_RETCODE_INVALID:         return "Invalid request parameters";
        case TRADE_RETCODE_INVALID_VOLUME:  return "Invalid volume specified";
        case TRADE_RETCODE_INVALID_PRICE:   return "Invalid price specified";
        case TRADE_RETCODE_INVALID_STOPS:   return "Invalid stop levels";
        case TRADE_RETCODE_TRADE_DISABLED:  return "Trading is disabled";
        case TRADE_RETCODE_MARKET_CLOSED:   return "Market is closed";
        case TRADE_RETCODE_NO_MONEY:        return "Insufficient funds";
        case TRADE_RETCODE_PRICE_CHANGED:   return "Price changed during execution";
        case TRADE_RETCODE_PRICE_OFF:       return "No quotes available";
        case TRADE_RETCODE_INVALID_EXPIRATION: return "Invalid expiration date";
        case TRADE_RETCODE_ORDER_CHANGED:   return "Order state changed";
        case TRADE_RETCODE_TOO_MANY_REQUESTS: return "Too many requests";
        case TRADE_RETCODE_NO_CHANGES:      return "No changes required";
        case TRADE_RETCODE_SERVER_DISABLES_AT: return "Autotrading disabled by server";
        case TRADE_RETCODE_CLIENT_DISABLES_AT: return "Autotrading disabled by client";
        case TRADE_RETCODE_LOCKED:          return "Request locked for processing";
        case TRADE_RETCODE_FROZEN:          return "Order/position frozen";
        case TRADE_RETCODE_INVALID_FILL:    return "Invalid fill type";
        case TRADE_RETCODE_CONNECTION:      return "No connection to trade server";
        case TRADE_RETCODE_ONLY_REAL:       return "Operation allowed only for live accounts";
        case TRADE_RETCODE_LIMIT_ORDERS:    return "Orders limit reached";
        case TRADE_RETCODE_LIMIT_VOLUME:    return "Volume limit reached";
        default:                           return "Unknown execution error: " + IntegerToString(retcode);
    }
}

//+------------------------------------------------------------------+
//| Get error description from error code                           |
//| Parameters: error_code - error code from GetLastError()        |
//| Returns: string description of the error                       |
//+------------------------------------------------------------------+
string Get_Error_Description(int error_code)
{
    switch(error_code)
    {
        case 0:    return "No error";
        case 1:    return "No error returned";
        case 2:    return "Common error";
        case 3:    return "Invalid trade parameters";
        case 4:    return "Trade server is busy";
        case 5:    return "Old version of the client terminal";
        case 6:    return "No connection with trade server";
        case 7:    return "Not enough rights";
        case 8:    return "Too frequent requests";
        case 9:    return "Malfunctional trade operation";
        case 64:   return "Account disabled";
        case 65:   return "Invalid account";
        case 128:  return "Trade timeout";
        case 129:  return "Invalid price";
        case 130:  return "Invalid stops";
        case 131:  return "Invalid trade volume";
        case 132:  return "Market is closed";
        case 133:  return "Trade is disabled";
        case 134:  return "Not enough money";
        case 135:  return "Price changed";
        case 136:  return "Off quotes";
        case 137:  return "Broker is busy";
        case 138:  return "Requote";
        case 139:  return "Order is locked";
        case 140:  return "Long positions only allowed";
        case 141:  return "Too many requests";
        case 145:  return "Modification denied because order too close to market";
        case 146:  return "Trade context is busy";
        case 5001: return "Too many opened files";
        case 5002: return "Wrong file name";
        case 5003: return "Too long file name";
        case 5004: return "Cannot open file";
        case 5005: return "Text file buffer allocation error";
        case 5006: return "Cannot delete file";
        case 5007: return "Invalid file handle";
        case 5008: return "Wrong file handle";
        case 5009: return "File must be opened with FILE_WRITE flag";
        case 5010: return "File must be opened with FILE_READ flag";
        case 5011: return "File must be opened with FILE_BIN flag";
        case 5012: return "File must be opened with FILE_TXT flag";
        case 5013: return "File must be opened with FILE_TXT or FILE_CSV flag";
        case 5014: return "File must be opened with FILE_CSV flag";
        case 5015: return "File read error";
        case 5016: return "File write error";
        case 5017: return "String size must be specified for binary file";
        case 5018: return "Incompatible file (for example CSV), for this file format";
        case 5019: return "File is directory not file";
        case 5020: return "File does not exist";
        case 5021: return "File cannot be rewritten";
        case 5022: return "Wrong directory name";
        case 5023: return "Directory does not exist";
        case 5024: return "Specified file is not directory";
        case 5025: return "Cannot delete directory";
        case 5026: return "Cannot clean directory";
        case 5027: return "Array resize error";
        case 5028: return "String resize error";
        default:   return "Unknown error: " + IntegerToString(error_code);
    }
}

//+------------------------------------------------------------------+
//| Test logging functionality                                       |
//| Returns: true if test successful, false otherwise               |
//+------------------------------------------------------------------+
bool Test_Logging_Function()
{
    Print("=== TESTING LOGGING FUNCTIONALITY ===");
    
    string test_message = "This is a test log entry to verify logging functionality.";
    bool result = Save_Log_To_File(test_message, "TestLog");
    
    if(result)
    {
        Print("✅ Logging test PASSED - File created successfully");
    }
    else
    {
        Print("❌ Logging test FAILED - Unable to create file");
        Print("Common causes:");
        Print("1. Insufficient permissions");
        Print("2. Invalid file path");
        Print("3. Disk space issues");
    }
    
    Print("=== LOGGING TEST COMPLETE ===");
    return result;
}

//+------------------------------------------------------------------+
//| Check file access permissions                                   |
//| Returns: true if file access available, false otherwise         |
//+------------------------------------------------------------------+
bool Check_File_Access()
{
    Print("=== CHECKING FILE ACCESS PERMISSIONS ===");
    
    string test_filename = "access_test.txt";
    
    // Use standard MQL5/Files directory for consistency
    int handle = FileOpen(test_filename, FILE_WRITE|FILE_TXT);
    
    if(handle == INVALID_HANDLE)
    {
        int error_code = GetLastError();
        Print("❌ No file access permission.");
        Print("Target location: MQL5/Files directory");
        Print("Error Code: ", error_code);
        Print("Error Description: ", Get_Error_Description(error_code));
        Print("File access test FAILED");
        return false;
    }
    
    // Write test data
    FileWriteString(handle, "Test file access");
    FileClose(handle);
    
    // Clean up test file
    bool deleted = FileDelete(test_filename);
    
    if(deleted)
    {
        Print("✅ File access test PASSED - Can create and delete files");
        Print("Target: MQL5/Files directory (main location)");
    }
    else
    {
        Print("⚠️  File access partially working - Can create but not delete files");
        Print("Target: MQL5/Files directory (main location)");
    }
    
    Print("=== FILE ACCESS CHECK COMPLETE ===");
    return true;
}

//+------------------------------------------------------------------+
//| Initialize logging system with comprehensive testing            |
//| Returns: true if logging system ready, false otherwise          |
//+------------------------------------------------------------------+
bool Initialize_Logging_System()
{
    Print("=== INITIALIZING LOGGING SYSTEM ===");
    
    // Test 1: Check file access permissions
    bool access_ok = Check_File_Access();
    
    // Test 2: Test logging functionality
    bool logging_ok = Test_Logging_Function();
    
    // Test 3: Test with different log types
    bool various_logs_ok = true;
    string test_types[] = {"SystemTest", "FunctionTest", "BacktestLog"};
    
    for(int i = 0; i < ArraySize(test_types); i++)
    {
        string test_msg = "Testing log type: " + test_types[i];
        bool result = Save_Log_To_File(test_msg, test_types[i]);
        if(!result)
        {
            various_logs_ok = false;
            Print("❌ Failed to create log type: ", test_types[i]);
        }
    }
    
    bool overall_result = access_ok && logging_ok && various_logs_ok;
    
    if(overall_result)
    {
        Print("✅ LOGGING SYSTEM INITIALIZED SUCCESSFULLY");
        
        if(USE_CSV_FORMAT)
        {
            Print("📊 CSV LOGGING MODE ENABLED (Excel Ready)");
            Print("Files generated:");
            Print("   → Trade History: WithTrendPullback_TradeHistory.csv");
            Print("   → Signal History: WithTrendPullback_SignalHistory.csv");
            Print("   → Execution History: WithTrendPullback_ExecutionHistory.csv");
            Print("   → Summary Report: WithTrendPullback_Summary_Report.csv");
            
            if(Is_Backtest_Mode())
            {
                Print("   → Backtest Log: WithTrendPullback_BacktestLog.txt (critical logs only)");
                Print("🚀 BACKTEST MODE: Optimized for performance and reduced file creation");
                Print("   → Mode: BACKTEST (Auto-detected)");
            }
            else
            {
                Print("   → Live Trading Logs: WithTrendPullback_[Type]_[Date].log");
                Print("📈 LIVE TRADING MODE: Optimized for real-time monitoring");
                Print("   → Mode: LIVE TRADING (Auto-detected)");
            }
        }
        else
        {
            Print("📄 TRADITIONAL LOGGING MODE");
            Print("Environment: All modes (Backtest & Live)");
            
            if(USE_COMPUTER_TIMESTAMP)
            {
                Print("File naming: WithTrendPullback_[LogType]_[Computer_DateTime].log");
                Print("Strategy: Unique file per test run (recommended for backtesting)");
            }
            else
            {
                Print("File naming: WithTrendPullback_[LogType]_[Market_Date].log");
                Print("Strategy: Grouped by trading date (good for live trading)");
            }
        }
        
        Print("📁 Storage Location: MQL5/Files/ folder (main location)");
        Print("🔍 Access via: File → Open Data Folder → MQL5 → Files");
    }
    else
    {
        Print("❌ LOGGING SYSTEM INITIALIZATION FAILED");
        Print("Some logging features may not work properly");
    }
    
    Print("=== LOGGING SYSTEM INITIALIZATION COMPLETE ===");
    return overall_result;
}

//+------------------------------------------------------------------+
//| Finalize Logging System and Generate Reports                   |
//| Call this function at the end of backtest to generate summary  |
//| Returns: true if finalization successful                       |
//+------------------------------------------------------------------+
bool Finalize_Logging_System()
{
    Print("=== FINALIZING LOGGING SYSTEM ===");
    
    bool result = true;
    
    if(USE_CSV_FORMAT)
    {
        Print("📊 Generating backtest summary report...");
        bool summary_generated = Generate_Backtest_Summary_Report();
        
        if(summary_generated)
        {
            Print("✅ Summary report generated successfully");
            Print("📈 Files ready for Excel analysis:");
            Print("   → WithTrendPullback_TradeHistory.csv - All trade details");
            Print("   → WithTrendPullback_SignalHistory.csv - Signal analysis data");
            Print("   → WithTrendPullback_ExecutionHistory.csv - Execution attempts");
            Print("   → WithTrendPullback_Summary_Report.csv - Performance summary");
        }
        else
        {
            Print("❌ Failed to generate summary report");
            result = false;
        }
    }
    
    Print("📁 All files saved to: MQL5/Files/ directory");
    Print("🔍 Access: File → Open Data Folder → MQL5 → Files");
    Print("=== LOGGING SYSTEM FINALIZED ===");
    
    return result;
}

//+------------------------------------------------------------------+
//| Helper Functions - Mode Detection and Settings                   |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Detect if we're in backtest mode                                |
//| Returns: true if backtest, false if live trading               |
//+------------------------------------------------------------------+
bool Is_Backtest_Mode()
{
    if(!AUTO_DETECT_MODE)
        return MANUAL_MODE_BACKTEST;
    
    // Auto-detect based on MQL5 environment
    return (MQLInfoInteger(MQL_TESTER) != 0);
}

//+------------------------------------------------------------------+
//| Get current CSV logging setting                                 |
//| Returns: true if CSV logging is enabled for current mode       |
//+------------------------------------------------------------------+
bool Is_CSV_Logging_Enabled()
{
    if(Is_Backtest_Mode())
        return BACKTEST_USE_CSV;
    else
        return LIVE_USE_CSV;
}

//+------------------------------------------------------------------+
//| Get current log frequency limit setting                         |
//| Returns: true if logging frequency should be limited           |
//+------------------------------------------------------------------+
bool Is_Log_Frequency_Limited()
{
    if(Is_Backtest_Mode())
        return BACKTEST_LIMIT_LOG_FREQUENCY;
    else
        return LIVE_LIMIT_LOG_FREQUENCY;
}

//+------------------------------------------------------------------+
//| Get current single log file setting                             |
//| Returns: true if should use single log file                    |
//+------------------------------------------------------------------+
bool Use_Single_Log_File()
{
    if(Is_Backtest_Mode())
        return BACKTEST_SINGLE_LOG_FILE;
    else
        return false; // Live trading always uses separate files
}

//+------------------------------------------------------------------+
//| Get current mode name for logging                               |
//| Returns: "BACKTEST" or "LIVE"                                  |
//+------------------------------------------------------------------+
string Get_Current_Mode_Name()
{
    return Is_Backtest_Mode() ? "BACKTEST" : "LIVE";
}

//+------------------------------------------------------------------+
//| Log Entry Signal with Basic Market Analysis                     |
//| Parameters: order_type - ORDER_TYPE_BUY or ORDER_TYPE_SELL     |
//|            symbol - trading symbol                              |
//| Returns: true if logging successful, false otherwise            |
//+------------------------------------------------------------------+
bool Log_Entry_Signal_Basic(int order_type, string symbol)
{
    string signal_type = (order_type == ORDER_TYPE_BUY) ? "BUY" : "SELL";
    datetime signal_time = TimeCurrent();
    
    // Get basic market data
    double current_bid = SymbolInfoDouble(symbol, SYMBOL_BID);
    double current_ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    double spread = current_ask - current_bid;
    
    // Calculate spread in pips
    double pip_size = SymbolInfoDouble(symbol, SYMBOL_POINT);
    if(SymbolInfoInteger(symbol, SYMBOL_DIGITS) == 5 || SymbolInfoInteger(symbol, SYMBOL_DIGITS) == 3)
        pip_size *= 10;
    double spread_pips = spread / pip_size;
    
    // Create signal analysis log
    string log_message = StringFormat(
        "\n=== ENTRY SIGNAL DETECTED ===\n" +
        "Signal Type: %s\n" +
        "Signal Time: %s\n" +
        "Symbol: %s\n" +
        "--- MARKET DATA ---\n" +
        "Current Bid: %.5f\n" +
        "Current Ask: %.5f\n" +
        "Spread: %.1f pips\n" +
        "--- SIGNAL CONDITIONS ---\n" +
        "D1 Trend: %s (Check EMA alignment manually)\n" +
        "H4 Pullback: %s (Check RSI and Bollinger Bands manually)\n" +
        "Candlestick Pattern: %s (Check manually)\n" +
        "--- ASSESSMENT ---\n" +
        "Signal Generated: YES\n" +
        "Next Action: EXECUTE TRADE\n" +
        "=============================",
        signal_type,
        TimeToString(signal_time, TIME_DATE|TIME_SECONDS),
        symbol,
        current_bid, current_ask, spread_pips,
        (signal_type == "BUY" ? "BULLISH EXPECTED" : "BEARISH EXPECTED"),
        (signal_type == "BUY" ? "BUY ZONE EXPECTED" : "SELL ZONE EXPECTED"),
        "TO BE CONFIRMED"
    );
    
    // Print to Experts log for immediate visibility
    Print(log_message);
    
    // Also create a summary for quick monitoring
    string summary = StringFormat("SIGNAL: %s %s | Spread: %.1f pips | Time: %s",
        signal_type, symbol, spread_pips, TimeToString(signal_time, TIME_SECONDS));
    Print(summary);
    
    // Save to log file
    bool file_saved = Save_Log_To_File(log_message, "EntrySignals");
    
    // Save to CSV for analysis
    string csv_data = StringFormat("%s,%s,%s,%.5f,%.5f,%.1f,%s",
        TimeToString(signal_time, TIME_DATE|TIME_SECONDS),
        symbol, signal_type, current_bid, current_ask, spread_pips,
        "GENERATED");
        
    bool csv_saved = Log_Signal_To_CSV_Basic(csv_data);
    
    return (file_saved && csv_saved);
}

//+------------------------------------------------------------------+
//| Log Trade Execution with Entry Signal Context                   |
//| Parameters: order_type, symbol, entry_price, volume, ticket     |
//| Returns: true if logging successful, false otherwise            |
//+------------------------------------------------------------------+
bool Log_Trade_Execution_Basic(int order_type, string symbol, double entry_price, double volume, ulong ticket,
                              double rsi_m15 = 0.0, double rsi_m5 = 0.0, double rsi_m1 = 0.0, bool multi_tf_compliant = false)
{
    string trade_type = (order_type == ORDER_TYPE_BUY) ? "BUY" : "SELL";
    datetime execution_time = TimeCurrent();
    
    // Get current market conditions
    double current_bid = SymbolInfoDouble(symbol, SYMBOL_BID);
    double current_ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    double spread = current_ask - current_bid;
    
    // Calculate spread in pips
    double pip_size = SymbolInfoDouble(symbol, SYMBOL_POINT);
    if(SymbolInfoInteger(symbol, SYMBOL_DIGITS) == 5 || SymbolInfoInteger(symbol, SYMBOL_DIGITS) == 3)
        pip_size *= 10;
    double spread_pips = spread / pip_size;
    
    // Calculate slippage (difference between intended and actual price)
    double intended_price = (order_type == ORDER_TYPE_BUY) ? current_ask : current_bid;
    double slippage_pips = MathAbs(entry_price - intended_price) / pip_size;
    
    // Create execution log
    string log_message = StringFormat(
        "\n=== TRADE EXECUTION ===\n" +
        "Ticket: %I64u\n" +
        "Type: %s\n" +
        "Symbol: %s\n" +
        "Execution Time: %s\n" +
        "--- EXECUTION DETAILS ---\n" +
        "Entry Price: %.5f\n" +
        "Volume: %.2f lots\n" +
        "Intended Price: %.5f\n" +
        "Slippage: %.1f pips\n" +
        "Spread at Execution: %.1f pips\n" +
        "--- Multi-TF RSI ANALYSIS ---\n" +
        "RSI M15: %.2f\n" +
        "RSI M5: %.2f\n" +
        "RSI M1: %.2f\n" +
        "Multi-TF Compliant: %s\n" +
        "--- STATUS ---\n" +
        "Execution: SUCCESSFUL\n" +
        "Position: OPEN\n" +
        "======================",
        ticket, trade_type, symbol,
        TimeToString(execution_time, TIME_DATE|TIME_SECONDS),
        entry_price, volume, intended_price, slippage_pips, spread_pips,
        rsi_m15, rsi_m5, rsi_m1, (multi_tf_compliant ? "YES" : "NO")
    );
    
    // Print to log
    Print(log_message);
    
    // Save to file
    bool file_saved = Save_Log_To_File(log_message, "TradeExecution");
    
    // Save execution data to CSV  
    string csv_data = StringFormat("%s,%I64u,%s,%s,%.5f,%.2f,%.1f,%.1f,%.2f,%.2f,%.2f,%s,%s",
        TimeToString(execution_time, TIME_DATE|TIME_SECONDS),
        ticket, symbol, trade_type, entry_price, volume, 
        slippage_pips, spread_pips, rsi_m15, rsi_m5, rsi_m1, 
        (multi_tf_compliant ? "YES" : "NO"), "EXECUTED");
        
    bool csv_saved = Log_Execution_To_CSV_Basic(csv_data);
    
    return (file_saved && csv_saved);
}

//+------------------------------------------------------------------+
//| Log Signal to CSV (Basic Version)                              |
//| Parameters: csv_data - formatted CSV string                     |
//| Returns: true if successful, false otherwise                    |
//+------------------------------------------------------------------+
bool Log_Signal_To_CSV_Basic(string csv_data)
{
    string filename = LOG_FILE_PREFIX + "Signals_" + Get_Current_Mode_Name() + ".csv";
    
    // Create header if file doesn't exist
    int file_handle = FileOpen(filename, FILE_READ|FILE_TXT);
    bool file_exists = (file_handle != INVALID_HANDLE);
    if(file_exists) FileClose(file_handle);
    
    // Open for append
    file_handle = FileOpen(filename, FILE_WRITE|FILE_TXT);
    if(file_handle == INVALID_HANDLE)
    {
        Print("ERROR: Cannot open signals CSV file: ", filename);
        return false;
    }
    
    // Write header if new file
    if(!file_exists)
    {
        string header = "SignalTime,Symbol,SignalType,Bid,Ask,SpreadPips,Status";
        FileWriteString(file_handle, header + "\n");
    }
    
    // Move to end of file and write data
    FileSeek(file_handle, 0, SEEK_END);
    FileWriteString(file_handle, csv_data + "\n");
    FileClose(file_handle);
    
    return true;
}

//+------------------------------------------------------------------+
//| Log Execution to CSV (Basic Version)                           |
//| Parameters: csv_data - formatted CSV string                     |
//| Returns: true if successful, false otherwise                    |
//+------------------------------------------------------------------+
bool Log_Execution_To_CSV_Basic(string csv_data)
{
    string filename = LOG_FILE_PREFIX + "Executions_" + Get_Current_Mode_Name() + ".csv";
    
    // Create header if file doesn't exist
    int file_handle = FileOpen(filename, FILE_READ|FILE_TXT);
    bool file_exists = (file_handle != INVALID_HANDLE);
    if(file_exists) FileClose(file_handle);
    
    // Open for append
    file_handle = FileOpen(filename, FILE_WRITE|FILE_TXT);
    if(file_handle == INVALID_HANDLE)
    {
        Print("ERROR: Cannot open executions CSV file: ", filename);
        return false;
    }
    
    // Write header if new file
    if(!file_exists)
    {
        string header = "ExecutionTime,Ticket,Symbol,Type,EntryPrice,Volume,SlippagePips,SpreadPips,RSI_M15,RSI_M5,RSI_M1,Multi_TF_Compliant,Status";
        FileWriteString(file_handle, header + "\n");
    }
    
    // Move to end of file and write data
    FileSeek(file_handle, 0, SEEK_END);
    FileWriteString(file_handle, csv_data + "\n");
    FileClose(file_handle);
    
    return true;
}

//+------------------------------------------------------------------+
//| Enhanced Log Signal Check with Multi-Timeframe RSI Data        |
//| This function extends the original logging with Multi-TF RSI    |
//+------------------------------------------------------------------+
bool Log_Signal_Check_Multi_TF(string signal_type, bool signal_result, bool trend_status, bool pullback_status, bool pattern_status)
{
    if(signal_type != "BUY" && signal_type != "SELL")
    {
        Print("ERROR: Invalid signal type provided to Log_Signal_Check_Multi_TF: ", signal_type);
        return false;
    }
    
    // Get Multi-TF RSI data
    double rsi_m15, rsi_m5, rsi_m1;
    bool multi_tf_rsi_available = Get_Multi_Timeframe_RSI(RSI_PERIOD, rsi_m15, rsi_m5, rsi_m1);
    
    // Get current market data for context
    double current_bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double current_ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double current_spread = current_ask - current_bid;
    
    // Convert spread to pips
    double pip_size = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
    if(SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 5 || SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 3)
        pip_size *= 10;
    double spread_pips = current_spread / pip_size;
    
    // Get additional market context
    datetime current_time = TimeCurrent();
    string timeframe_str = "H4";
    
    // Determine Multi-TF RSI status
    bool multi_tf_oversold = false;
    bool multi_tf_overbought = false;
    string multi_tf_status = "N/A";
    
    if(multi_tf_rsi_available)
    {
        if(signal_type == "BUY")
        {
            multi_tf_oversold = (rsi_m15 < 35.0 && rsi_m5 < 35.0 && rsi_m1 < 35.0);
            multi_tf_status = multi_tf_oversold ? "OVERSOLD (All < 35)" : "NOT OVERSOLD";
        }
        else if(signal_type == "SELL")
        {
            multi_tf_overbought = (rsi_m15 > 65.0 && rsi_m5 > 65.0 && rsi_m1 > 65.0);
            multi_tf_status = multi_tf_overbought ? "OVERBOUGHT (All > 65)" : "NOT OVERBOUGHT";
        }
    }
    
    // Create enhanced signal analysis log
    Print("=== ENHANCED SIGNAL CHECK LOG ===");
    Print("Signal Type: ", signal_type);
    Print("Signal Result: ", (signal_result ? "SIGNAL FOUND" : "NO SIGNAL"));
    Print("Check Time: ", TimeToString(current_time, TIME_DATE|TIME_SECONDS));
    Print("Symbol: ", Symbol());
    Print("Timeframe: ", timeframe_str);
    Print("Current Bid: ", DoubleToString(current_bid, 5));
    Print("Current Ask: ", DoubleToString(current_ask, 5));
    Print("Spread: ", DoubleToString(spread_pips, 1), " pips");
    Print("--- Analysis Breakdown ---");
    Print("1. Trend Analysis (D1): ", (trend_status ? "BULLISH/BEARISH" : "NO TREND"));
    Print("2. Pullback Zone (H4): ", (pullback_status ? "IN ZONE" : "NOT IN ZONE"));  
    Print("3. Pattern Confirmation (H4): ", (pattern_status ? "CONFIRMED" : "NO PATTERN"));
    
    if(multi_tf_rsi_available)
    {
        Print("--- Multi-Timeframe RSI Analysis ---");
        Print("RSI M15: ", DoubleToString(rsi_m15, 2));
        Print("RSI M5:  ", DoubleToString(rsi_m5, 2));
        Print("RSI M1:  ", DoubleToString(rsi_m1, 2));
        Print("Multi-TF Status: ", multi_tf_status);
    }
    else
    {
        Print("--- Multi-Timeframe RSI Analysis ---");
        Print("Multi-TF RSI: ERROR - Unable to retrieve RSI data");
    }
    
    Print("--- Signal Logic ---");
    Print("Required: ALL conditions must be TRUE");
    Print("Result: ", (signal_result ? "SIGNAL FOUND" : "NO SIGNAL"));
    Print("================================");
    
    return true;
}
