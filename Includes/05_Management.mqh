//+------------------------------------------------------------------+
//|                                               05_Management.mqh |
//|                                                       Chatchai.D |
//|                                   With-Trend Pullback Strategy  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Include necessary files                                          |
//+------------------------------------------------------------------+
#include "01_Parameters.mqh"
#include "06_Logging.mqh"

//+------------------------------------------------------------------+
//| Trade Management Functions                                       |
//| Contains functions for managing open trades and positions       |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Count Open Trades for this EA                                   |
//| Parameters: None                                                 |
//| Returns: number of open trades managed by this EA               |
//+------------------------------------------------------------------+
int Count_Open_Trades(int magic_number = 123456)
{
    int open_trades_count = 0;
    
    // Get total number of open positions
    int total_positions = PositionsTotal();
    
    Print("LOG: Checking open trades - Total positions in account: ", total_positions);
    
    // Loop through all open positions
    for(int i = 0; i < total_positions; i++)
    {
        // Select position by index
        if(PositionGetTicket(i) > 0)
        {
            // Get position symbol
            string position_symbol = PositionGetString(POSITION_SYMBOL);
            
            // Get position magic number
            long position_magic = PositionGetInteger(POSITION_MAGIC);
            
            // Check if position belongs to this EA and symbol
            if(position_symbol == Symbol() && position_magic == magic_number)
            {
                // Get additional position information for logging
                ENUM_POSITION_TYPE position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                double position_volume = PositionGetDouble(POSITION_VOLUME);
                double position_price_open = PositionGetDouble(POSITION_PRICE_OPEN);
                double position_profit = PositionGetDouble(POSITION_PROFIT);
                ulong position_ticket = PositionGetInteger(POSITION_TICKET);
                
                open_trades_count++;
                
                Print("LOG: Found EA trade #", open_trades_count, 
                      " - Ticket: ", position_ticket,
                      ", Symbol: ", position_symbol,
                      ", Type: ", (position_type == POSITION_TYPE_BUY ? "BUY" : "SELL"),
                      ", Volume: ", position_volume,
                      ", Open Price: ", position_price_open,
                      ", Current Profit: ", position_profit,
                      ", Magic: ", position_magic);
            }
        }
        else
        {
            Print("ERROR: Failed to select position at index: ", i);
        }
    }
    
    Print("LOG: Count_Open_Trades() result - EA has ", open_trades_count, " open trades");
    
    return open_trades_count;
}

//+------------------------------------------------------------------+
//| Check if maximum trades limit is reached                        |
//| Parameters: None                                                 |
//| Returns: true if can open new trade, false if limit reached     |
//+------------------------------------------------------------------+
bool Can_Open_New_Trade(int magic_number = 123456, int max_open_trades = 1)
{
    int current_trades = Count_Open_Trades(magic_number);
    
    if(current_trades >= max_open_trades)
    {
        Print("WARNING: Maximum trades limit reached - Current: ", current_trades, 
              ", Maximum: ", max_open_trades);
        return false;
    }
    
    Print("LOG: Can open new trade - Current: ", current_trades, 
          ", Maximum: ", max_open_trades);
    return true;
}

//+------------------------------------------------------------------+
//| Get list of open trade tickets for this EA                      |
//| Parameters: tickets[] - array to store ticket numbers           |
//| Returns: number of tickets found                                 |
//+------------------------------------------------------------------+
int Get_Open_Trade_Tickets(ulong &tickets[], int magic_number = 123456)
{
    int found_tickets = 0;
    int total_positions = PositionsTotal();
    
    // Resize array to maximum possible size
    ArrayResize(tickets, total_positions);
    
    // Loop through all positions
    for(int i = 0; i < total_positions; i++)
    {
        if(PositionGetTicket(i) > 0)
        {
            string position_symbol = PositionGetString(POSITION_SYMBOL);
            long position_magic = PositionGetInteger(POSITION_MAGIC);
            
            // Check if position belongs to this EA
            if(position_symbol == Symbol() && position_magic == magic_number)
            {
                ulong ticket = PositionGetInteger(POSITION_TICKET);
                tickets[found_tickets] = ticket;
                found_tickets++;
                
                Print("LOG: Added ticket to list: ", ticket);
            }
        }
    }
    
    // Resize array to actual found tickets
    ArrayResize(tickets, found_tickets);
    
    Print("LOG: Get_Open_Trade_Tickets() found ", found_tickets, " tickets");
    
    return found_tickets;
}

//+------------------------------------------------------------------+
//| Manage Trailing Stop for all open trades                        |
//| Parameters: None                                                 |
//| Returns: number of positions updated with trailing stop         |
//+------------------------------------------------------------------+
int Manage_Trailing_Stop(bool enable_trailing_stop = false, double trailing_stop_pips = 50, int magic_number = 123456)
{
    // Check if trailing stop is enabled
    if(!enable_trailing_stop)
    {
        return 0; // Exit silently if trailing stop is disabled
    }
    
    int positions_updated = 0;
    int total_positions = PositionsTotal();
    
    Print("LOG: Starting trailing stop management - Total positions: ", total_positions);
    
    // Convert pips to points for current symbol
    double pip_size = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
    if(SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 5 || SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 3)
    {
        pip_size *= 10; // For 5-digit and 3-digit brokers
    }
    double trailing_distance = trailing_stop_pips * pip_size;
    
    Print("LOG: Trailing stop settings - Pips: ", trailing_stop_pips, 
          ", Point size: ", SymbolInfoDouble(Symbol(), SYMBOL_POINT),
          ", Pip size: ", pip_size,
          ", Trailing distance: ", trailing_distance);
    
    // Loop through all positions
    for(int i = 0; i < total_positions; i++)
    {
        if(PositionGetTicket(i) > 0)
        {
            string position_symbol = PositionGetString(POSITION_SYMBOL);
            long position_magic = PositionGetInteger(POSITION_MAGIC);
            
            // Check if position belongs to this EA
            if(position_symbol == Symbol() && position_magic == magic_number)
            {
                ulong ticket = PositionGetInteger(POSITION_TICKET);
                ENUM_POSITION_TYPE position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                double position_volume = PositionGetDouble(POSITION_VOLUME);
                double position_price_open = PositionGetDouble(POSITION_PRICE_OPEN);
                double current_sl = PositionGetDouble(POSITION_SL);
                double current_tp = PositionGetDouble(POSITION_TP);
                
                // Get current market prices
                double current_bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
                double current_ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
                
                double new_sl = 0.0;
                bool should_update = false;
                
                // Calculate new trailing stop based on position type
                if(position_type == POSITION_TYPE_BUY)
                {
                    // For BUY positions: trail stop loss upward
                    new_sl = current_bid - trailing_distance;
                    
                    // Only update if new SL is higher than current SL (or if no SL is set)
                    if(current_sl == 0.0 || new_sl > current_sl)
                    {
                        should_update = true;
                        Print("LOG: BUY position trailing - Ticket: ", ticket,
                              ", Current Bid: ", current_bid,
                              ", Current SL: ", current_sl,
                              ", New SL: ", new_sl,
                              ", Trailing Distance: ", trailing_distance);
                    }
                }
                else if(position_type == POSITION_TYPE_SELL)
                {
                    // For SELL positions: trail stop loss downward
                    new_sl = current_ask + trailing_distance;
                    
                    // Only update if new SL is lower than current SL (or if no SL is set)
                    if(current_sl == 0.0 || new_sl < current_sl)
                    {
                        should_update = true;
                        Print("LOG: SELL position trailing - Ticket: ", ticket,
                              ", Current Ask: ", current_ask,
                              ", Current SL: ", current_sl,
                              ", New SL: ", new_sl,
                              ", Trailing Distance: ", trailing_distance);
                    }
                }
                
                // Update stop loss if needed
                if(should_update)
                {
                    // Normalize the new stop loss price
                    int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
                    new_sl = NormalizeDouble(new_sl, digits);
                    
                    // Prepare modification request
                    MqlTradeRequest request = {};
                    MqlTradeResult result = {};
                    
                    request.action = TRADE_ACTION_SLTP;
                    request.symbol = Symbol();
                    request.position = ticket;
                    request.sl = new_sl;
                    request.tp = current_tp; // Keep existing TP
                    request.magic = magic_number;
                    request.comment = "Trailing Stop Update";
                    
                    // Send the modification request
                    bool success = OrderSend(request, result);
                    
                    if(success && result.retcode == TRADE_RETCODE_DONE)
                    {
                        positions_updated++;
                        Print("SUCCESS: Trailing stop updated - Ticket: ", ticket,
                              ", New SL: ", new_sl,
                              ", Position type: ", (position_type == POSITION_TYPE_BUY ? "BUY" : "SELL"));
                    }
                    else
                    {
                        Print("ERROR: Failed to update trailing stop - Ticket: ", ticket,
                              ", Return code: ", result.retcode,
                              ", Description: ", GetTrailingStopRetcodeDescription(result.retcode));
                    }
                }
                else
                {
                    Print("LOG: No trailing stop update needed - Ticket: ", ticket,
                          ", Position type: ", (position_type == POSITION_TYPE_BUY ? "BUY" : "SELL"),
                          ", Current SL: ", current_sl,
                          ", Calculated new SL: ", new_sl);
                }
            }
        }
    }
    
    Print("LOG: Trailing stop management completed - Positions updated: ", positions_updated);
    return positions_updated;
}

//+------------------------------------------------------------------+
//| Get description for trailing stop modification return codes     |
//| Parameters: retcode - modification operation return code        |
//| Returns: string description of the return code                  |
//+------------------------------------------------------------------+
string GetTrailingStopRetcodeDescription(uint retcode)
{
    switch(retcode)
    {
        case TRADE_RETCODE_REQUOTE:         return "Requote - price changed";
        case TRADE_RETCODE_REJECT:          return "Request rejected";
        case TRADE_RETCODE_CANCEL:          return "Request canceled";
        case TRADE_RETCODE_PLACED:          return "Order placed successfully";
        case TRADE_RETCODE_DONE:            return "Request completed successfully";
        case TRADE_RETCODE_DONE_PARTIAL:    return "Request partially completed";
        case TRADE_RETCODE_ERROR:           return "Request processing error";
        case TRADE_RETCODE_TIMEOUT:         return "Request timeout";
        case TRADE_RETCODE_INVALID:         return "Invalid request";
        case TRADE_RETCODE_INVALID_VOLUME:  return "Invalid volume";
        case TRADE_RETCODE_INVALID_PRICE:   return "Invalid price";
        case TRADE_RETCODE_INVALID_STOPS:   return "Invalid stop levels";
        case TRADE_RETCODE_TRADE_DISABLED:  return "Trading disabled";
        case TRADE_RETCODE_MARKET_CLOSED:   return "Market closed";
        case TRADE_RETCODE_NO_MONEY:        return "Insufficient funds";
        case TRADE_RETCODE_PRICE_CHANGED:   return "Price changed";
        case TRADE_RETCODE_PRICE_OFF:       return "No quotes";
        case TRADE_RETCODE_INVALID_EXPIRATION: return "Invalid expiration";
        case TRADE_RETCODE_ORDER_CHANGED:   return "Order state changed";
        case TRADE_RETCODE_TOO_MANY_REQUESTS: return "Too many requests";
        case TRADE_RETCODE_NO_CHANGES:      return "No changes required";
        case TRADE_RETCODE_SERVER_DISABLES_AT: return "Autotrading disabled by server";
        case TRADE_RETCODE_CLIENT_DISABLES_AT: return "Autotrading disabled by client";
        case TRADE_RETCODE_LOCKED:          return "Request locked";
        case TRADE_RETCODE_FROZEN:          return "Position frozen";
        case TRADE_RETCODE_INVALID_FILL:    return "Invalid fill type";
        case TRADE_RETCODE_CONNECTION:      return "No connection";
        case TRADE_RETCODE_ONLY_REAL:       return "Live accounts only";
        case TRADE_RETCODE_LIMIT_ORDERS:    return "Orders limit reached";
        case TRADE_RETCODE_LIMIT_VOLUME:    return "Volume limit reached";
        default:                           return "Unknown error: " + IntegerToString(retcode);
    }
}

//+------------------------------------------------------------------+
//| Monitor and Log Closed Trades                                   |
//| Check for closed trades since last check and log them          |
//| Returns: number of closed trades found and logged              |
//+------------------------------------------------------------------+
int Monitor_Closed_Trades()
{
    static datetime last_check_time = 0;
    datetime current_time = TimeCurrent();
    
    // If first run, set last check time to start of today
    if(last_check_time == 0)
    {
        last_check_time = StringToTime(TimeToString(current_time, TIME_DATE) + " 00:00:00");
    }
    
    // Select history from last check time to now
    if(!HistorySelect(last_check_time, current_time))
    {
        Print("ERROR: Failed to select history for closed trades monitoring");
        return 0;
    }
    
    int total_deals = HistoryDealsTotal();
    int closed_trades_logged = 0;
    
    // Track positions that have been closed
    static ulong logged_positions[];
    static int logged_count = 0;
    
    Print("LOG: Checking for closed trades - Total deals in period: ", total_deals);
    
    for(int i = 0; i < total_deals; i++)
    {
        ulong deal_ticket = HistoryDealGetTicket(i);
        if(deal_ticket > 0)
        {
            // Get deal properties
            long deal_magic = HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
            string deal_symbol = HistoryDealGetString(deal_ticket, DEAL_SYMBOL);
            ENUM_DEAL_TYPE deal_type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal_ticket, DEAL_TYPE);
            datetime deal_time = (datetime)HistoryDealGetInteger(deal_ticket, DEAL_TIME);
            long position_id = HistoryDealGetInteger(deal_ticket, DEAL_POSITION_ID);
            
            // Check if this is our EA's trade and it's an exit deal
            if(deal_magic == MAGIC_NUMBER && 
               deal_symbol == Symbol() && 
               deal_time > last_check_time &&
               (deal_type == DEAL_TYPE_BUY || deal_type == DEAL_TYPE_SELL))
            {
                // Check if this position has already been logged
                bool already_logged = false;
                for(int j = 0; j < logged_count; j++)
                {
                    if(logged_positions[j] == position_id)
                    {
                        already_logged = true;
                        break;
                    }
                }
                
                if(!already_logged)
                {
                    // Check if this position is actually closed (has both entry and exit)
                    if(!HistorySelectByPosition(position_id))
                        continue;
                        
                    int pos_deals = HistoryDealsTotal();
                    if(pos_deals >= 2) // Entry + Exit = closed trade
                    {
                        Print("LOG: Found closed trade - Position ID: ", position_id,
                              " | Magic: ", deal_magic,
                              " | Symbol: ", deal_symbol,
                              " | Close Time: ", TimeToString(deal_time));
                        
                        // Log the closed trade
                        bool logged = Log_Trade_Exit(position_id);
                        if(logged)
                        {
                            // Add to logged positions list
                            ArrayResize(logged_positions, logged_count + 1);
                            logged_positions[logged_count] = position_id;
                            logged_count++;
                            closed_trades_logged++;
                            
                            Print("✅ Successfully logged closed trade: ", position_id);
                        }
                        else
                        {
                            Print("❌ Failed to log closed trade: ", position_id);
                        }
                    }
                }
            }
        }
    }
    
    // Update last check time
    last_check_time = current_time;
    
    if(closed_trades_logged > 0)
    {
        Print("📊 CLOSED TRADES MONITORING: Found and logged ", closed_trades_logged, " new closed trades");
    }
    
    return closed_trades_logged;
}

//+------------------------------------------------------------------+
