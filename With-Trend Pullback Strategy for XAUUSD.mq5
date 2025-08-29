//+------------------------------------------------------------------+
//|                      With-Trend Pullback Strategy for XAUUSD.mq5 |
//|                                                       Chatchai.D |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Chatchai.D"
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Include Files                                                    |
//+------------------------------------------------------------------+
#include "Includes/01_Parameters.mqh"
#include "Includes/02_Analysis.mqh"
#include "Includes/03_Signal.mqh"
#include "Includes/04_Execution.mqh"
#include "Includes/05_Management.mqh"
#include "Includes/06_Logging.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
//=== STATIC PARAMETERS ===
input int EMA_Fast_Period = 13;        // Fast EMA Period
input int EMA_Slow_Period = 39;        // Slow EMA Period
input int RSI_Period = 14;             // RSI Period
input int BB_Period = 20;              // Bollinger Bands Period
input double BB_Deviations = 2.0;      // Bollinger Bands Deviations
input int ATR_Period = 14;             // ATR Period

//=== OPTIMIZABLE PARAMETERS ===
input int RSI_Buy_Min = 30;            // RSI Minimum for Buy Signal (Oversold zone)
input int RSI_Buy_Max = 60;            // RSI Maximum for Buy Signal (Before overbought)
input int RSI_Sell_Min = 40;           // RSI Minimum for Sell Signal (After oversold)
input int RSI_Sell_Max = 70;           // RSI Maximum for Sell Signal (Overbought zone)
input double ATR_SL_Multiplier = 2.0;  // ATR Multiplier for Stop Loss
input double Risk_Reward_Ratio = 2.0;  // Risk to Reward Ratio
input double Risk_Per_Trade_Percent = 1.0; // Risk per Trade (%)

//=== TRADE MANAGEMENT ===
input double Max_Lot_Size = 1.0;       // Maximum Lot Size
input double Min_Lot_Size = 0.01;      // Minimum Lot Size
input int Max_Open_Trades = 1;         // Maximum Open Trades
input bool Enable_Trailing_Stop = false; // Enable Trailing Stop
input double Trailing_Stop_Pips = 50;  // Trailing Stop in Pips

//=== MAGIC NUMBER ===
input int Magic_Number = 123456;       // EA Magic Number

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Initialization logging
   Print("=== WITH-TREND PULLBACK STRATEGY INITIALIZATION ===");
   Print("EA Name: With-Trend Pullback Strategy for XAUUSD");
   Print("Version: 1.00");
   Print("Symbol: ", Symbol());
   Print("Account: ", AccountInfoString(ACCOUNT_NAME), " (", AccountInfoInteger(ACCOUNT_LOGIN), ")");
   Print("Account Balance: ", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
   Print("Account Currency: ", AccountInfoString(ACCOUNT_CURRENCY));
   Print("Initialization Time: ", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS));
   
//--- Parameter validation and logging
   Print("\n--- PARAMETER VALIDATION ---");
   bool validation_passed = true;
   
   // Validate EMA periods
   if(EMA_Fast_Period <= 0 || EMA_Slow_Period <= 0 || EMA_Fast_Period >= EMA_Slow_Period)
   {
      Print("ERROR: Invalid EMA periods - Fast: ", EMA_Fast_Period, ", Slow: ", EMA_Slow_Period);
      validation_passed = false;
   }
   else
   {
      Print("✓ EMA Periods - Fast: ", EMA_Fast_Period, ", Slow: ", EMA_Slow_Period);
   }
   
   // Validate RSI parameters
   if(RSI_Period <= 0 || RSI_Period > 100)
   {
      Print("ERROR: Invalid RSI period: ", RSI_Period);
      validation_passed = false;
   }
   else
   {
      Print("✓ RSI Period: ", RSI_Period);
   }
   
   // Validate RSI ranges
   if(RSI_Buy_Min < 0 || RSI_Buy_Max > 100 || RSI_Buy_Min >= RSI_Buy_Max ||
      RSI_Sell_Min < 0 || RSI_Sell_Max > 100 || RSI_Sell_Min >= RSI_Sell_Max)
   {
      Print("ERROR: Invalid RSI ranges - Buy: ", RSI_Buy_Min, "-", RSI_Buy_Max, 
            ", Sell: ", RSI_Sell_Min, "-", RSI_Sell_Max);
      validation_passed = false;
   }
   else
   {
      Print("✓ RSI Ranges - Buy: ", RSI_Buy_Min, "-", RSI_Buy_Max, 
            ", Sell: ", RSI_Sell_Min, "-", RSI_Sell_Max);
   }
   
   // Validate Bollinger Bands
   if(BB_Period <= 0 || BB_Deviations <= 0)
   {
      Print("ERROR: Invalid Bollinger Bands - Period: ", BB_Period, ", Deviations: ", BB_Deviations);
      validation_passed = false;
   }
   else
   {
      Print("✓ Bollinger Bands - Period: ", BB_Period, ", Deviations: ", BB_Deviations);
   }
   
   // Validate ATR parameters
   if(ATR_Period <= 0 || ATR_SL_Multiplier <= 0)
   {
      Print("ERROR: Invalid ATR parameters - Period: ", ATR_Period, ", Multiplier: ", ATR_SL_Multiplier);
      validation_passed = false;
   }
   else
   {
      Print("✓ ATR Parameters - Period: ", ATR_Period, ", Multiplier: ", ATR_SL_Multiplier);
   }
   
   // Validate risk management
   if(Risk_Reward_Ratio <= 0 || Risk_Per_Trade_Percent <= 0 || Risk_Per_Trade_Percent > 10)
   {
      Print("ERROR: Invalid risk parameters - R:R: ", Risk_Reward_Ratio, 
            ", Risk%: ", Risk_Per_Trade_Percent);
      validation_passed = false;
   }
   else
   {
      Print("✓ Risk Management - R:R: ", Risk_Reward_Ratio, ", Risk%: ", Risk_Per_Trade_Percent);
   }
   
   // Validate lot sizes
   double min_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   double lot_step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
   
   if(Min_Lot_Size < min_lot || Max_Lot_Size > max_lot || Min_Lot_Size >= Max_Lot_Size)
   {
      Print("ERROR: Invalid lot sizes - Min: ", Min_Lot_Size, ", Max: ", Max_Lot_Size);
      Print("Broker limits - Min: ", min_lot, ", Max: ", max_lot, ", Step: ", lot_step);
      validation_passed = false;
   }
   else
   {
      Print("✓ Lot Sizes - Min: ", Min_Lot_Size, ", Max: ", Max_Lot_Size);
      Print("  Broker limits - Min: ", min_lot, ", Max: ", max_lot, ", Step: ", lot_step);
   }
   
   // Validate trade management
   if(Max_Open_Trades <= 0)
   {
      Print("ERROR: Invalid max open trades: ", Max_Open_Trades);
      validation_passed = false;
   }
   else
   {
      Print("✓ Max Open Trades: ", Max_Open_Trades);
   }
   
   if(Enable_Trailing_Stop && Trailing_Stop_Pips <= 0)
   {
      Print("ERROR: Invalid trailing stop pips: ", Trailing_Stop_Pips);
      validation_passed = false;
   }
   else if(Enable_Trailing_Stop)
   {
      Print("✓ Trailing Stop: Enabled (", Trailing_Stop_Pips, " pips)");
   }
   else
   {
      Print("✓ Trailing Stop: Disabled");
   }
   
   // Validate Magic Number
   if(Magic_Number <= 0)
   {
      Print("ERROR: Invalid Magic Number: ", Magic_Number);
      validation_passed = false;
   }
   else
   {
      Print("✓ Magic Number: ", Magic_Number);
   }
   
//--- Symbol and market validation
   Print("\n--- SYMBOL VALIDATION ---");
   
   // Check if symbol exists and is available
   if(!SymbolSelect(Symbol(), true))
   {
      Print("ERROR: Symbol not available: ", Symbol());
      validation_passed = false;
   }
   else
   {
      Print("✓ Symbol: ", Symbol(), " - Available");
   }
   
   // Get symbol specifications
   double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
   double tick_size = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
   double tick_value = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
   double contract_size = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE);
   
   Print("✓ Symbol Specs - Point: ", point, ", Digits: ", digits);
   Print("  Tick Size: ", tick_size, ", Tick Value: ", tick_value);
   Print("  Contract Size: ", contract_size);
   
   // Check trading permissions
   bool trade_allowed = (bool)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_MODE);
   if(!trade_allowed)
   {
      Print("ERROR: Trading not allowed for symbol: ", Symbol());
      validation_passed = false;
   }
   else
   {
      Print("✓ Trading: Allowed");
   }
   
//--- Trading environment validation
   Print("\n--- TRADING ENVIRONMENT ---");
   
   // Check if automated trading is enabled
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
   {
      Print("ERROR: Automated trading is disabled in terminal");
      validation_passed = false;
   }
   else
   {
      Print("✓ Terminal: Automated trading enabled");
   }
   
   // Check if EA trading is allowed
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
   {
      Print("ERROR: EA trading is not allowed");
      validation_passed = false;
   }
   else
   {
      Print("✓ EA Trading: Allowed");
   }
   
   // Check account trade permissions
   if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
   {
      Print("ERROR: Trading is not allowed for this account");
      validation_passed = false;
   }
   else
   {
      Print("✓ Account: Trading allowed");
   }
   
   // Check account trade mode
   ENUM_ACCOUNT_TRADE_MODE trade_mode = (ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE);
   string trade_mode_str = "";
   switch(trade_mode)
   {
      case ACCOUNT_TRADE_MODE_DEMO: trade_mode_str = "Demo"; break;
      case ACCOUNT_TRADE_MODE_CONTEST: trade_mode_str = "Contest"; break;
      case ACCOUNT_TRADE_MODE_REAL: trade_mode_str = "Real"; break;
      default: trade_mode_str = "Unknown"; break;
   }
   Print("✓ Account Mode: ", trade_mode_str);
   
//--- Initialize and test logging system
   Print("=== LOGGING SYSTEM INITIALIZATION ===");
   bool logging_ready = Initialize_Logging_System();
   if(logging_ready)
   {
      Print("✓ Logging System: Ready");
   }
   else
   {
      Print("⚠️  Logging System: Partially functional or failed");
   }
   
//--- Create initialization log entry
   string init_log = StringFormat(
      "\n=== EA INITIALIZATION LOG ===\n" +
      "EA: With-Trend Pullback Strategy for XAUUSD v1.00\n" +
      "Symbol: %s\n" +
      "Account: %s (%I64d)\n" +
      "Account Mode: %s\n" +
      "Balance: %.2f %s\n" +
      "Magic Number: %d\n" +
      "Parameters Validation: %s\n" +
      "Initialization Time: %s\n" +
      "Status: %s\n" +
      "=============================",
      Symbol(),
      AccountInfoString(ACCOUNT_NAME),
      AccountInfoInteger(ACCOUNT_LOGIN),
      trade_mode_str,
      AccountInfoDouble(ACCOUNT_BALANCE),
      AccountInfoString(ACCOUNT_CURRENCY),
      Magic_Number,
      (validation_passed ? "PASSED" : "FAILED"),
      TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS),
      (validation_passed ? "READY FOR TRADING" : "INITIALIZATION FAILED")
   );
   
   // Print initialization log
   Print(init_log);
   
   // Save to log file
   Save_Log_To_File(init_log, "Initialization");
   
//--- Final validation result
   if(!validation_passed)
   {
      Print("=== INITIALIZATION FAILED ===");
      Print("Please check the parameters and try again.");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   Print("=== INITIALIZATION SUCCESSFUL ===");
   Print("EA is ready for trading on ", Symbol());
   
   Print("Log files location: MQL5/Files/ folder (main location)");
   Print("Access: MetaTrader → File → Open Data Folder → MQL5 → Files");
   Print("Note: All log files will be saved to the main MQL5/Files directory");
   
   #ifdef USE_COMPUTER_TIMESTAMP
   if(USE_COMPUTER_TIMESTAMP)
   {
      Print("Logging strategy: Computer timestamp (unique files per test)");
   }
   else
   {
      Print("Logging strategy: Market date (grouped by trading day)");
   }
   #endif
   
   Print("Waiting for trading signals...");
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- Deinitialization logging
   Print("=== WITH-TREND PULLBACK STRATEGY DEINITIALIZATION ===");
   Print("EA Name: With-Trend Pullback Strategy for XAUUSD");
   Print("Version: 1.00");
   Print("Symbol: ", Symbol());
   Print("Deinitialization Time: ", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS));
   
//--- Determine deinitialization reason
   string reason_text = "";
   switch(reason)
   {
      case REASON_PROGRAM:
         reason_text = "EA stopped by user";
         break;
      case REASON_REMOVE:
         reason_text = "EA removed from chart";
         break;
      case REASON_RECOMPILE:
         reason_text = "EA recompiled";
         break;
      case REASON_CHARTCHANGE:
         reason_text = "Chart symbol or period changed";
         break;
      case REASON_CHARTCLOSE:
         reason_text = "Chart closed";
         break;
      case REASON_PARAMETERS:
         reason_text = "EA parameters changed";
         break;
      case REASON_ACCOUNT:
         reason_text = "Account changed";
         break;
      case REASON_TEMPLATE:
         reason_text = "Template changed";
         break;
      case REASON_INITFAILED:
         reason_text = "Initialization failed";
         break;
      case REASON_CLOSE:
         reason_text = "Terminal closed";
         break;
      default:
         reason_text = StringFormat("Unknown reason (%d)", reason);
         break;
   }
   
   Print("Deinitialization Reason: ", reason_text);
   
//--- Count current open trades for this EA
   int open_trades = 0;
   double total_profit = 0.0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC) == Magic_Number && 
            PositionGetString(POSITION_SYMBOL) == Symbol())
         {
            open_trades++;
            total_profit += PositionGetDouble(POSITION_PROFIT) + 
                           PositionGetDouble(POSITION_SWAP);
         }
      }
   }
   
   Print("Open Trades at Shutdown: ", open_trades);
   if(open_trades > 0)
   {
      Print("Total Unrealized P/L: ", DoubleToString(total_profit, 2));
      Print("WARNING: EA is shutting down with open positions!");
   }
   
//--- Account information at shutdown
   double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double current_margin = AccountInfoDouble(ACCOUNT_MARGIN);
   double current_free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   string account_currency = AccountInfoString(ACCOUNT_CURRENCY);
   
   Print("\n--- ACCOUNT STATUS AT SHUTDOWN ---");
   Print("Account Balance: ", DoubleToString(current_balance, 2), " ", account_currency);
   Print("Account Equity: ", DoubleToString(current_equity, 2), " ", account_currency);
   Print("Used Margin: ", DoubleToString(current_margin, 2), " ", account_currency);
   Print("Free Margin: ", DoubleToString(current_free_margin, 2), " ", account_currency);
   
   // Calculate margin level if there's used margin
   if(current_margin > 0)
   {
      double margin_level = (current_equity / current_margin) * 100;
      Print("Margin Level: ", DoubleToString(margin_level, 2), "%");
   }
   
//--- Trading session summary (if available)
   Print("\n--- SESSION SUMMARY ---");
   
   // Count total deals for this session (today)
   datetime today_start = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   HistorySelect(today_start, TimeCurrent());
   
   int total_deals = 0;
   int buy_deals = 0;
   int sell_deals = 0;
   double session_profit = 0.0;
   double session_commission = 0.0;
   double session_swap = 0.0;
   
   for(int i = 0; i < HistoryDealsTotal(); i++)
   {
      ulong deal_ticket = HistoryDealGetTicket(i);
      if(deal_ticket > 0)
      {
         long deal_magic = HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
         string deal_symbol = HistoryDealGetString(deal_ticket, DEAL_SYMBOL);
         
         if(deal_magic == Magic_Number && deal_symbol == Symbol())
         {
            ENUM_DEAL_TYPE deal_type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal_ticket, DEAL_TYPE);
            
            if(deal_type == DEAL_TYPE_BUY || deal_type == DEAL_TYPE_SELL)
            {
               total_deals++;
               if(deal_type == DEAL_TYPE_BUY) buy_deals++;
               else sell_deals++;
               
               session_profit += HistoryDealGetDouble(deal_ticket, DEAL_PROFIT);
               session_commission += HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION);
               session_swap += HistoryDealGetDouble(deal_ticket, DEAL_SWAP);
            }
         }
      }
   }
   
   Print("Total Deals Today: ", total_deals, " (", buy_deals, " BUY, ", sell_deals, " SELL)");
   if(total_deals > 0)
   {
      double net_session_profit = session_profit + session_commission + session_swap;
      Print("Session Gross Profit: ", DoubleToString(session_profit, 2), " ", account_currency);
      Print("Session Commission: ", DoubleToString(session_commission, 2), " ", account_currency);
      Print("Session Swap: ", DoubleToString(session_swap, 2), " ", account_currency);
      Print("Session Net Profit: ", DoubleToString(net_session_profit, 2), " ", account_currency);
   }
   else
   {
      Print("No trades executed today");
   }
   
//--- Resource cleanup information
   Print("\n--- RESOURCE CLEANUP ---");
   Print("Indicator handles: Released automatically by terminal");
   Print("File handles: Closed automatically");
   Print("Memory: Freed automatically");
   Print("Timers: Stopped automatically");
   
//--- Final status message
   if(open_trades > 0)
   {
      Print("\n⚠️  WARNING: EA shutdown with ", open_trades, " open position(s)");
      Print("   Monitor these positions manually or restart EA");
   }
   else
   {
      Print("\n✅ Clean shutdown - No open positions");
   }
   
//--- Create comprehensive deinitialization log
   string deinit_log = StringFormat(
      "\n=== EA DEINITIALIZATION LOG ===\n" +
      "EA: With-Trend Pullback Strategy for XAUUSD v1.00\n" +
      "Symbol: %s\n" +
      "Account: %s (%I64d)\n" +
      "Deinitialization Time: %s\n" +
      "Reason: %s\n" +
      "--- Account Status ---\n" +
      "Balance: %.2f %s\n" +
      "Equity: %.2f %s\n" +
      "Used Margin: %.2f %s\n" +
      "Free Margin: %.2f %s\n" +
      "--- Open Positions ---\n" +
      "Open Trades: %d\n" +
      "Unrealized P/L: %.2f %s\n" +
      "--- Session Summary ---\n" +
      "Total Deals Today: %d (%d BUY, %d SELL)\n" +
      "Session Net Profit: %.2f %s\n" +
      "--- Status ---\n" +
      "Shutdown Status: %s\n" +
      "===============================",
      Symbol(),
      AccountInfoString(ACCOUNT_NAME),
      AccountInfoInteger(ACCOUNT_LOGIN),
      TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS),
      reason_text,
      current_balance,
      account_currency,
      current_equity,
      account_currency,
      current_margin,
      account_currency,
      current_free_margin,
      account_currency,
      open_trades,
      total_profit,
      account_currency,
      total_deals,
      buy_deals,
      sell_deals,
      (session_profit + session_commission + session_swap),
      account_currency,
      (open_trades > 0 ? "WARNING - Open positions remain" : "Clean shutdown")
   );
   
   // Print deinitialization log
   Print(deinit_log);
   
   // Save to log file
   Save_Log_To_File(deinit_log, "Deinitialization");
   
   // Finalize logging system and generate reports
   bool logging_finalized = Finalize_Logging_System();
   if(logging_finalized)
   {
      Print("✅ Logging system finalized successfully");
   }
   else
   {
      Print("⚠️ Warning: Logging system finalization had issues");
   }
   
//--- Final farewell message
   Print("=== EA DEINITIALIZATION COMPLETE ===");
   Print("Thank you for using With-Trend Pullback Strategy!");
   Print("EA stopped successfully on ", Symbol());
   
  }
//+------------------------------------------------------------------+
//| Global Variables for New Candle Detection & Trade Monitoring    |
//+------------------------------------------------------------------+
datetime last_h4_candle_time = 0;      // Track last H4 candle time
int tick_counter = 0;                   // Count ticks for performance monitoring
int last_open_trades_count = -1;        // Track changes in open trades count
datetime last_trade_count_check = 0;    // Track last time we checked trade count
datetime last_execution_attempt = 0;    // Track last trade execution attempt
int execution_attempts_today = 0;       // Count execution attempts per day
bool execution_cooldown_active = false; // Prevent rapid execution attempts

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- One-time logging test on first tick (especially important for backtest)
   static bool first_tick_logging_tested = false;
   if(!first_tick_logging_tested)
   {
      Print("=== FIRST TICK LOGGING TEST ===");
      string first_tick_msg = StringFormat("First tick received at %s - Logging system operational test", 
                                          TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS));
      bool test_result = Save_Log_To_File(first_tick_msg, "FirstTick");
      
      if(test_result)
      {
         Print("✅ First tick logging test PASSED");
      }
      else
      {
         Print("❌ First tick logging test FAILED - Check file permissions");
      }
      first_tick_logging_tested = true;
   }

//--- Increment tick counter for performance monitoring
   tick_counter++;
   
//--- Performance logging (every 100 ticks)
   if(tick_counter % 100 == 0)
   {
      Print("LOG: Tick #", tick_counter, " - Time: ", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS));
   }
   
//--- Check for new H4 candle formation
   datetime current_h4_time = iTime(Symbol(), PERIOD_H4, 0);
   
   if(current_h4_time == 0)
   {
      Print("ERROR: Failed to get H4 candle time");
      return;
   }
   
   // Initialize last_h4_candle_time on first run
   if(last_h4_candle_time == 0)
   {
      last_h4_candle_time = current_h4_time;
      Print("LOG: OnTick initialized - Current H4 candle time: ", TimeToString(current_h4_time, TIME_DATE|TIME_MINUTES));
      return;
   }
   
   // Check if new H4 candle has formed
   bool new_h4_candle = (current_h4_time > last_h4_candle_time);
   
   if(new_h4_candle)
   {
      // Update last candle time
      last_h4_candle_time = current_h4_time;
      
      // Log new candle formation
      Print("=== NEW H4 CANDLE DETECTED ===");
      Print("New H4 Candle Time: ", TimeToString(current_h4_time, TIME_DATE|TIME_MINUTES));
      Print("Previous H4 Candle Time: ", TimeToString(current_h4_time - 14400, TIME_DATE|TIME_MINUTES)); // 14400 = 4 hours in seconds
      
      // Get current market information
      double current_bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      double current_ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      double current_spread = current_ask - current_bid;
      
      // Convert spread to pips
      double pip_size = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
      if(SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 5 || SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 3)
         pip_size *= 10;
      double spread_pips = current_spread / pip_size;
      
      Print("Current Market - Bid: ", current_bid, ", Ask: ", current_ask, ", Spread: ", DoubleToString(spread_pips, 1), " pips");
      
      // Get H4 OHLC data for the completed candle (index 1)
      double h4_open = iOpen(Symbol(), PERIOD_H4, 1);
      double h4_high = iHigh(Symbol(), PERIOD_H4, 1);
      double h4_low = iLow(Symbol(), PERIOD_H4, 1);
      double h4_close = iClose(Symbol(), PERIOD_H4, 1);
      
      if(h4_open > 0 && h4_high > 0 && h4_low > 0 && h4_close > 0)
      {
         Print("Completed H4 Candle - Open: ", h4_open, ", High: ", h4_high, ", Low: ", h4_low, ", Close: ", h4_close);
         
         // Calculate candle size and direction
         double candle_size = h4_high - h4_low;
         double candle_body = MathAbs(h4_close - h4_open);
         double candle_body_percent = (candle_body / candle_size) * 100;
         string candle_direction = (h4_close > h4_open) ? "BULLISH" : "BEARISH";
         
         Print("Candle Analysis - Size: ", DoubleToString(candle_size, 5), 
               ", Body: ", DoubleToString(candle_body, 5),
               ", Body %: ", DoubleToString(candle_body_percent, 1), "%",
               ", Direction: ", candle_direction);
      }
      else
      {
         Print("ERROR: Failed to get H4 OHLC data for completed candle");
      }
      
      // Check trading conditions on new H4 candle
      Check_Trading_Conditions_On_New_Candle();
      
      Print("=== NEW H4 CANDLE PROCESSING COMPLETE ===");
   }
   
//--- Check open trades count and monitor changes (every 5 ticks for responsiveness)
   if(tick_counter % 5 == 0)
   {
      Monitor_Open_Trades_Changes();
   }
   
//--- Monitor closed trades and log them (every 10 ticks for efficiency)
   if(tick_counter % 10 == 0)
   {
      Monitor_Closed_Trades();
   }

//--- Check Buy Signal independently (every 20 ticks for efficiency)
   if(tick_counter % 20 == 0)
   {
      Check_Buy_Signal_OnTick();
   }

//--- Check Sell Signal independently (every 25 ticks for efficiency and offset)
   if(tick_counter % 25 == 0)
   {
      Check_Sell_Signal_OnTick();
   }

//--- Enhanced Trailing Stop Management (every 10 ticks for responsiveness)
   if(tick_counter % 10 == 0)
   {
      Enhanced_Trailing_Stop_Manager();
   }
   
//--- Market hours and trading session validation (every 50 ticks)
   if(tick_counter % 50 == 0)
   {
      // Check if market is open
      if(!SymbolInfoInteger(Symbol(), SYMBOL_SELECT))
      {
         Print("WARNING: Symbol not selected or market closed");
         return;
      }
      
      // Check trading permissions
      if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED))
      {
         Print("WARNING: Trading not allowed - Terminal: ", TerminalInfoInteger(TERMINAL_TRADE_ALLOWED), 
               ", EA: ", MQLInfoInteger(MQL_TRADE_ALLOWED));
         return;
      }
   }
   
//--- Comprehensive Signal Analysis Summary (every 500 ticks for overview)
   if(tick_counter % 500 == 0)
   {
      Signal_Analysis_Summary();
   }

//--- Trailing Stop Performance Monitor (every 200 ticks for detailed analysis)
   if(tick_counter % 200 == 0 && Enable_Trailing_Stop)
   {
      Trailing_Stop_Performance_Monitor();
   }

//--- Performance monitoring and cleanup (every 1000 ticks)
   if(tick_counter % 1000 == 0)
   {
      Print("PERFORMANCE: Processed ", tick_counter, " ticks since EA start");
      Print("Current Time: ", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS));
      Print("Last H4 Candle: ", TimeToString(last_h4_candle_time, TIME_DATE|TIME_MINUTES));
      
      // Reset tick counter to prevent overflow
      if(tick_counter >= 100000)
      {
         tick_counter = 0;
         Print("LOG: Tick counter reset to prevent overflow");
      }
   }
  }

//+------------------------------------------------------------------+
//| Check Trading Conditions on New H4 Candle Formation             |
//| This function runs only when a new H4 candle is detected        |
//+------------------------------------------------------------------+
void Check_Trading_Conditions_On_New_Candle()
{
   Print("\n=== CHECKING TRADING CONDITIONS ===");
   
   // First check if we can open new trades
   bool can_trade = Can_Open_New_Trade(Magic_Number, Max_Open_Trades);
   
   if(!can_trade)
   {
      Print("LOG: Cannot open new trades - Maximum limit reached or other restrictions");
      return;
   }
   
   Print("LOG: Trade limit check passed - Can proceed with signal analysis");
   
   // Check current account status
   double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double account_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double account_margin_free = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   
   Print("Account Status - Balance: ", DoubleToString(account_balance, 2),
         ", Equity: ", DoubleToString(account_equity, 2),
         ", Free Margin: ", DoubleToString(account_margin_free, 2));
   
   // Validate minimum account requirements
   if(account_balance < 100 || account_equity < 100)
   {
      Print("ERROR: Insufficient account balance/equity for trading");
      return;
   }
   
   if(account_margin_free < 50)
   {
      Print("ERROR: Insufficient free margin for trading");
      return;
   }
   
   // Check spread conditions
   double current_spread = SymbolInfoDouble(Symbol(), SYMBOL_ASK) - SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double pip_size = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   if(SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 5 || SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 3)
      pip_size *= 10;
   double spread_pips = current_spread / pip_size;
   
   // Skip trading if spread is too high (more than 50 pips for XAUUSD)
   if(spread_pips > 50.0)
   {
      Print("WARNING: Spread too high (", DoubleToString(spread_pips, 1), " pips) - Skipping trading");
      return;
   }
   
   Print("LOG: Spread check passed - ", DoubleToString(spread_pips, 1), " pips");
   
   // Now check for trading signals
   Print("\n--- SIGNAL ANALYSIS ---");
   
   // Check for BUY signal
   bool buy_signal = Check_Buy_Signal(EMA_Fast_Period, EMA_Slow_Period, BB_Period, BB_Deviations, 
                                     RSI_Period, RSI_Buy_Min, RSI_Buy_Max);
   
   if(buy_signal)
   {
      Print("🟢 BUY SIGNAL CONFIRMED - Proceeding to execution");
      
      // Execute BUY trade using enhanced manager
      bool buy_executed = Enhanced_Execute_Trade_Manager("BUY", "New_H4_Candle");
      
      if(buy_executed)
      {
         Print("✅ BUY trade executed successfully");
      }
      else
      {
         Print("❌ BUY trade execution failed");
      }
   }
   else
   {
      Print("LOG: No BUY signal detected");
   }
   
   // Check for SELL signal (only if no BUY signal to avoid conflicting trades)
   if(!buy_signal)
   {
      bool sell_signal = Check_Sell_Signal(EMA_Fast_Period, EMA_Slow_Period, BB_Period, BB_Deviations, 
                                          RSI_Period, RSI_Sell_Min, RSI_Sell_Max);
      
      if(sell_signal)
      {
         Print("🔴 SELL SIGNAL CONFIRMED - Proceeding to execution");
         
         // Execute SELL trade using enhanced manager
         bool sell_executed = Enhanced_Execute_Trade_Manager("SELL", "New_H4_Candle");
         
         if(sell_executed)
         {
            Print("✅ SELL trade executed successfully");
         }
         else
         {
            Print("❌ SELL trade execution failed");
         }
      }
      else
      {
         Print("LOG: No SELL signal detected");
      }
   }
   
   Print("=== TRADING CONDITIONS CHECK COMPLETE ===\n");
}





//+------------------------------------------------------------------+
//| Monitor Open Trades Changes and Count                           |
//| This function tracks changes in open trades count               |
//+------------------------------------------------------------------+
void Monitor_Open_Trades_Changes()
{
   // Get current open trades count
   int current_open_trades = Count_Open_Trades(Magic_Number);
   
   // Check if this is the first time checking
   if(last_open_trades_count == -1)
   {
      last_open_trades_count = current_open_trades;
      last_trade_count_check = TimeCurrent();
      
      if(current_open_trades > 0)
      {
         Print("LOG: Initial trade count check - Found ", current_open_trades, " open trade(s)");
         Detailed_Trade_Status_Report();
      }
      else
      {
         Print("LOG: Initial trade count check - No open trades");
      }
      return;
   }
   
   // Check for changes in open trades count
   if(current_open_trades != last_open_trades_count)
   {
      datetime current_time = TimeCurrent();
      
      Print("\n=== OPEN TRADES COUNT CHANGED ===");
      Print("Previous Count: ", last_open_trades_count);
      Print("Current Count: ", current_open_trades);
      Print("Change: ", (current_open_trades - last_open_trades_count));
      Print("Time: ", TimeToString(current_time, TIME_DATE|TIME_SECONDS));
      
      // Analyze the type of change
      if(current_open_trades > last_open_trades_count)
      {
         int new_trades = current_open_trades - last_open_trades_count;
         Print("🟢 NEW TRADE(S) OPENED: +", new_trades);
         
         // Log new trade opening
         string change_log = StringFormat(
            "NEW TRADE OPENED - Count changed from %d to %d (+%d) at %s",
            last_open_trades_count,
            current_open_trades,
            new_trades,
            TimeToString(current_time, TIME_DATE|TIME_SECONDS)
         );
         Save_Log_To_File(change_log, "TradeCountChange");
      }
      else if(current_open_trades < last_open_trades_count)
      {
         int closed_trades = last_open_trades_count - current_open_trades;
         Print("🔴 TRADE(S) CLOSED: -", closed_trades);
         
         // Log trade closing
         string change_log = StringFormat(
            "TRADE CLOSED - Count changed from %d to %d (-%d) at %s",
            last_open_trades_count,
            current_open_trades,
            closed_trades,
            TimeToString(current_time, TIME_DATE|TIME_SECONDS)
         );
         Save_Log_To_File(change_log, "TradeCountChange");
      }
      
      // Update tracking variables
      last_open_trades_count = current_open_trades;
      last_trade_count_check = current_time;
      
      // Show detailed status after any change
      if(current_open_trades > 0)
      {
         Detailed_Trade_Status_Report();
      }
      else
      {
         Print("✅ NO OPEN TRADES - Ready for new signals");
      }
      
      Print("=== TRADE COUNT MONITORING COMPLETE ===\n");
   }
   
   // Periodic detailed reporting (every 5 minutes) if we have open trades
   if(current_open_trades > 0 && (TimeCurrent() - last_trade_count_check) >= 300)
   {
      Print("\n--- PERIODIC TRADE STATUS CHECK (5 min) ---");
      Detailed_Trade_Status_Report();
      last_trade_count_check = TimeCurrent();
      Print("--- PERIODIC CHECK COMPLETE ---\n");
   }
}

//+------------------------------------------------------------------+
//| Detailed Trade Status Report                                    |
//| Shows comprehensive information about all open trades           |
//+------------------------------------------------------------------+
void Detailed_Trade_Status_Report()
{
   int total_positions = PositionsTotal();
   int ea_positions = 0;
   double total_profit = 0.0;
   double total_volume = 0.0;
   string positions_summary = "";
   
   Print("\n--- DETAILED TRADE STATUS REPORT ---");
   Print("Total Positions in Account: ", total_positions);
   
   // Loop through all positions to find EA trades
   for(int i = 0; i < total_positions; i++)
   {
      if(PositionGetTicket(i) > 0)
      {
         string position_symbol = PositionGetString(POSITION_SYMBOL);
         long position_magic = PositionGetInteger(POSITION_MAGIC);
         
         // Check if position belongs to this EA
         if(position_symbol == Symbol() && position_magic == Magic_Number)
         {
            ea_positions++;
            
            // Get detailed position information
            ulong ticket = PositionGetInteger(POSITION_TICKET);
            ENUM_POSITION_TYPE position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double volume = PositionGetDouble(POSITION_VOLUME);
            double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
            double current_price = (position_type == POSITION_TYPE_BUY) ? 
                                 SymbolInfoDouble(Symbol(), SYMBOL_BID) : 
                                 SymbolInfoDouble(Symbol(), SYMBOL_ASK);
            double stop_loss = PositionGetDouble(POSITION_SL);
            double take_profit = PositionGetDouble(POSITION_TP);
            double profit = PositionGetDouble(POSITION_PROFIT);
            double swap = PositionGetDouble(POSITION_SWAP);
            datetime open_time = (datetime)PositionGetInteger(POSITION_TIME);
            
            // Calculate additional metrics
            double price_change = current_price - open_price;
            if(position_type == POSITION_TYPE_SELL) price_change = -price_change;
            
            double pip_size = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
            if(SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 5 || SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 3)
               pip_size *= 10;
            double pips_profit = price_change / pip_size;
            
            // Calculate time in trade
            int seconds_in_trade = (int)(TimeCurrent() - open_time);
            int hours_in_trade = seconds_in_trade / 3600;
            int minutes_in_trade = (seconds_in_trade % 3600) / 60;
            
            // Update totals
            total_profit += profit;
            total_volume += volume;
            
            // Print individual position details
            Print("Position #", ea_positions, ":");
            Print("  Ticket: ", ticket);
            Print("  Type: ", (position_type == POSITION_TYPE_BUY ? "BUY" : "SELL"));
            Print("  Volume: ", volume);
            Print("  Open Price: ", open_price);
            Print("  Current Price: ", current_price);
            Print("  Stop Loss: ", (stop_loss > 0 ? DoubleToString(stop_loss, 5) : "None"));
            Print("  Take Profit: ", (take_profit > 0 ? DoubleToString(take_profit, 5) : "None"));
            Print("  Profit: ", DoubleToString(profit, 2));
            Print("  Swap: ", DoubleToString(swap, 2));
            Print("  Pips P/L: ", DoubleToString(pips_profit, 1));
            Print("  Time in Trade: ", hours_in_trade, "h ", minutes_in_trade, "m");
            Print("  Open Time: ", TimeToString(open_time, TIME_DATE|TIME_MINUTES));
            
            // Add to summary
            positions_summary += StringFormat(
               "T%I64d:%s:%.2f:%.1f ",
               ticket,
               (position_type == POSITION_TYPE_BUY ? "B" : "S"),
               profit,
               pips_profit
            );
         }
      }
   }
   
   // Print summary
   Print("--- SUMMARY ---");
   Print("EA Positions: ", ea_positions, " / ", Max_Open_Trades, " (max)");
   Print("Total Volume: ", DoubleToString(total_volume, 2));
   Print("Total Profit: ", DoubleToString(total_profit, 2));
   Print("Account Balance: ", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
   Print("Account Equity: ", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
   
   // Check if we can open new trades
   bool can_open_new = Can_Open_New_Trade(Magic_Number, Max_Open_Trades);
   Print("Can Open New Trade: ", (can_open_new ? "YES" : "NO"));
   
   // Log to file
   if(ea_positions > 0)
   {
      string status_log = StringFormat(
         "TRADE STATUS REPORT - Positions: %d, Total Profit: %.2f, Summary: %s",
         ea_positions,
         total_profit,
         positions_summary
      );
      Save_Log_To_File(status_log, "TradeStatus");
   }
   
   Print("--- TRADE STATUS REPORT COMPLETE ---");
}

//+------------------------------------------------------------------+
//| Check Buy Signal on Every Tick (Independent Function)           |
//| This function runs independently from New H4 Candle detection   |
//+------------------------------------------------------------------+
void Check_Buy_Signal_OnTick()
{
   // Only check signals if we can open new trades
   bool can_trade = Can_Open_New_Trade(Magic_Number, Max_Open_Trades);
   if(!can_trade)
   {
      // Silent return - don't spam logs when at max trades
      return;
   }
   
   // Quick pre-checks before running expensive signal analysis
   if(!Pre_Signal_Validation())
   {
      return;
   }
   
   Print("\n=== BUY SIGNAL CHECK (OnTick) ===");
   Print("Time: ", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS));
   Print("Tick Counter: ", tick_counter);
   
   // Get current market information
   double current_bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double current_ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double current_spread = current_ask - current_bid;
   
   // Convert spread to pips
   double pip_size = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   if(SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 5 || SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 3)
      pip_size *= 10;
   double spread_pips = current_spread / pip_size;
   
   Print("Market Data - Bid: ", current_bid, ", Ask: ", current_ask, ", Spread: ", DoubleToString(spread_pips, 1), " pips");
   
   // Check spread condition
   if(spread_pips > 50.0)
   {
      Print("WARNING: Spread too high (", DoubleToString(spread_pips, 1), " pips) - Skipping BUY signal check");
      return;
   }
   
   // Run comprehensive BUY signal analysis
   bool buy_signal = Check_Buy_Signal(EMA_Fast_Period, EMA_Slow_Period, BB_Period, BB_Deviations, 
                                     RSI_Period, RSI_Buy_Min, RSI_Buy_Max);
   
   if(buy_signal)
   {
      Print("🟢 BUY SIGNAL DETECTED ON TICK!");
      Print("Signal Components Check:");
      
             // Detailed signal breakdown for logging
       bool trend_bullish = Is_Bullish_Trend(EMA_Fast_Period, EMA_Slow_Period);
       bool pullback_zone = Is_Buy_Pullback_Zone(BB_Period, BB_Deviations, RSI_Period, RSI_Buy_Min, RSI_Buy_Max);
       bool bullish_pattern = (Is_Bullish_Engulfing(1) || Is_Bullish_PinBar(1));
      
      Print("  ✓ D1 Bullish Trend: ", (trend_bullish ? "YES" : "NO"));
      Print("  ✓ H4 Buy Pullback Zone: ", (pullback_zone ? "YES" : "NO"));
      Print("  ✓ H4 Bullish Pattern: ", (bullish_pattern ? "YES" : "NO"));
      
      // Log signal check to CSV
      Log_Signal_Check_Multi_TF("BUY", true, trend_bullish, pullback_zone, bullish_pattern);
      
      // Additional market timing validation
      if(Is_Good_Trading_Time())
      {
         Print("  ✓ Good Trading Time: YES");
         
         // Log the signal detection
         string signal_log = StringFormat(
            "BUY SIGNAL DETECTED - Trend: %s, Pullback: %s, Pattern: %s, Spread: %.1f pips at %s",
            (trend_bullish ? "Bullish" : "Bearish"),
            (pullback_zone ? "Valid" : "Invalid"),
            (bullish_pattern ? "Confirmed" : "None"),
            spread_pips,
            TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS)
         );
         Save_Log_To_File(signal_log, "BuySignalDetected");
         
         Print("🚀 PROCEEDING TO BUY TRADE EXECUTION");
         
         // Execute BUY trade using enhanced manager
         bool buy_executed = Enhanced_Execute_Trade_Manager("BUY", "OnTick_Signal");
         
         if(buy_executed)
         {
            Print("✅ BUY TRADE EXECUTED SUCCESSFULLY FROM TICK SIGNAL");
         }
         else
         {
            Print("❌ BUY TRADE EXECUTION FAILED FROM TICK SIGNAL");
         }
      }
      else
      {
         Print("  ❌ Good Trading Time: NO - Signal ignored");
         Print("INFO: BUY signal detected but outside good trading hours");
      }
   }
   else
   {
      // Only log detailed analysis every 100 ticks to avoid spam
      if(tick_counter % 100 == 0)
      {
                   Print("LOG: No BUY signal - Detailed analysis:");
          
          bool trend_bullish = Is_Bullish_Trend(EMA_Fast_Period, EMA_Slow_Period);
          bool pullback_zone = Is_Buy_Pullback_Zone(BB_Period, BB_Deviations, RSI_Period, RSI_Buy_Min, RSI_Buy_Max);
          bool bullish_pattern = (Is_Bullish_Engulfing(1) || Is_Bullish_PinBar(1));
         
         Print("  D1 Bullish Trend: ", (trend_bullish ? "✓" : "✗"));
         Print("  H4 Buy Pullback Zone: ", (pullback_zone ? "✓" : "✗"));
         Print("  H4 Bullish Pattern: ", (bullish_pattern ? "✓" : "✗"));
         
         // Log failed signal check to CSV
         Log_Signal_Check_Multi_TF("BUY", false, trend_bullish, pullback_zone, bullish_pattern);
      }
   }
   
   Print("=== BUY SIGNAL CHECK COMPLETE ===\n");
}

//+------------------------------------------------------------------+
//| Pre-Signal Validation for Quick Filtering                       |
//| Returns true if basic conditions are met for signal checking    |
//+------------------------------------------------------------------+
bool Pre_Signal_Validation()
{
   // Check if trading is allowed
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED))
   {
      return false;
   }
   
   // Check account trading permission
   if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
   {
      return false;
   }
   
   // Check symbol trading permission
   if(!SymbolInfoInteger(Symbol(), SYMBOL_TRADE_MODE))
   {
      return false;
   }
   
   // Check minimum account balance
   double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double account_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(account_balance < 100 || account_equity < 100)
   {
      return false;
   }
   
   // Check free margin
   double account_margin_free = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(account_margin_free < 50)
   {
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if Current Time is Good for Trading                       |
//| Returns true if within good trading hours                       |
//+------------------------------------------------------------------+
bool Is_Good_Trading_Time()
{
   // Get current server time
   datetime current_time = TimeCurrent();
   MqlDateTime time_struct;
   TimeToStruct(current_time, time_struct);
   
   // Check day of week (Monday = 1, Sunday = 0)
   // Avoid trading on Sunday (market opening) and Friday late (market closing)
   if(time_struct.day_of_week == 0) // Sunday
   {
      return false;
   }
   
   if(time_struct.day_of_week == 5 && time_struct.hour >= 20) // Friday after 8 PM
   {
      return false;
   }
   
   // Check hour of day (avoid low liquidity hours)
   // Good trading hours: 6 AM to 10 PM server time
   if(time_struct.hour < 6 || time_struct.hour >= 22)
   {
      return false;
   }
   
   // Additional check for major news times (simplified)
   // Avoid trading 30 minutes before and after major news (example: top of the hour)
   if(time_struct.min >= 0 && time_struct.min <= 30 && 
      (time_struct.hour == 8 || time_struct.hour == 13 || time_struct.hour == 15)) // Major news hours
   {
      // This is a simplified news filter - in real trading, use economic calendar
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check Sell Signal on Every Tick (Independent Function)          |
//| This function runs independently from New H4 Candle detection   |
//+------------------------------------------------------------------+
void Check_Sell_Signal_OnTick()
{
   // Only check signals if we can open new trades
   bool can_trade = Can_Open_New_Trade(Magic_Number, Max_Open_Trades);
   if(!can_trade)
   {
      // Silent return - don't spam logs when at max trades
      return;
   }
   
   // Quick pre-checks before running expensive signal analysis
   if(!Pre_Signal_Validation())
   {
      return;
   }
   
   Print("\n=== SELL SIGNAL CHECK (OnTick) ===");
   Print("Time: ", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS));
   Print("Tick Counter: ", tick_counter);
   
   // Get current market information
   double current_bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double current_ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double current_spread = current_ask - current_bid;
   
   // Convert spread to pips
   double pip_size = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   if(SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 5 || SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 3)
      pip_size *= 10;
   double spread_pips = current_spread / pip_size;
   
   Print("Market Data - Bid: ", current_bid, ", Ask: ", current_ask, ", Spread: ", DoubleToString(spread_pips, 1), " pips");
   
   // Check spread condition
   if(spread_pips > 50.0)
   {
      Print("WARNING: Spread too high (", DoubleToString(spread_pips, 1), " pips) - Skipping SELL signal check");
      return;
   }
   
   // Run comprehensive SELL signal analysis
   bool sell_signal = Check_Sell_Signal(EMA_Fast_Period, EMA_Slow_Period, BB_Period, BB_Deviations, 
                                       RSI_Period, RSI_Sell_Min, RSI_Sell_Max);
   
   if(sell_signal)
   {
      Print("🔴 SELL SIGNAL DETECTED ON TICK!");
      Print("Signal Components Check:");
      
      // Detailed signal breakdown for logging
      bool trend_bearish = Is_Bearish_Trend(EMA_Fast_Period, EMA_Slow_Period);
      bool pullback_zone = Is_Sell_Pullback_Zone(BB_Period, BB_Deviations, RSI_Period, RSI_Sell_Min, RSI_Sell_Max);
      bool bearish_pattern = (Is_Bearish_Engulfing(1) || Is_Shooting_Star(1));
      
      Print("  ✓ D1 Bearish Trend: ", (trend_bearish ? "YES" : "NO"));
      Print("  ✓ H4 Sell Pullback Zone: ", (pullback_zone ? "YES" : "NO"));
      Print("  ✓ H4 Bearish Pattern: ", (bearish_pattern ? "YES" : "NO"));
      
      // Log signal check to CSV
      Log_Signal_Check_Multi_TF("SELL", true, trend_bearish, pullback_zone, bearish_pattern);
      
      // Additional market timing validation
      if(Is_Good_Trading_Time())
      {
         Print("  ✓ Good Trading Time: YES");
         
         // Log the signal detection
         string signal_log = StringFormat(
            "SELL SIGNAL DETECTED - Trend: %s, Pullback: %s, Pattern: %s, Spread: %.1f pips at %s",
            (trend_bearish ? "Bearish" : "Bullish"),
            (pullback_zone ? "Valid" : "Invalid"),
            (bearish_pattern ? "Confirmed" : "None"),
            spread_pips,
            TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS)
         );
         Save_Log_To_File(signal_log, "SellSignalDetected");
         
         Print("🚀 PROCEEDING TO SELL TRADE EXECUTION");
         
         // Execute SELL trade using enhanced manager
         bool sell_executed = Enhanced_Execute_Trade_Manager("SELL", "OnTick_Signal");
         
         if(sell_executed)
         {
            Print("✅ SELL TRADE EXECUTED SUCCESSFULLY FROM TICK SIGNAL");
         }
         else
         {
            Print("❌ SELL TRADE EXECUTION FAILED FROM TICK SIGNAL");
         }
      }
      else
      {
         Print("  ❌ Good Trading Time: NO - Signal ignored");
         Print("INFO: SELL signal detected but outside good trading hours");
      }
   }
   else
   {
      // Only log detailed analysis every 125 ticks to avoid spam (different from buy to offset logging)
      if(tick_counter % 125 == 0)
      {
         Print("LOG: No SELL signal - Detailed analysis:");
         
         bool trend_bearish = Is_Bearish_Trend(EMA_Fast_Period, EMA_Slow_Period);
         bool pullback_zone = Is_Sell_Pullback_Zone(BB_Period, BB_Deviations, RSI_Period, RSI_Sell_Min, RSI_Sell_Max);
         bool bearish_pattern = (Is_Bearish_Engulfing(1) || Is_Shooting_Star(1));
         
         Print("  D1 Bearish Trend: ", (trend_bearish ? "✓" : "✗"));
         Print("  H4 Sell Pullback Zone: ", (pullback_zone ? "✓" : "✗"));
         Print("  H4 Bearish Pattern: ", (bearish_pattern ? "✓" : "✗"));
         
         // Log failed signal check to CSV
         Log_Signal_Check_Multi_TF("SELL", false, trend_bearish, pullback_zone, bearish_pattern);
      }
   }
   
   Print("=== SELL SIGNAL CHECK COMPLETE ===\n");
}

//+------------------------------------------------------------------+
//| Comprehensive Signal Analysis Summary                            |
//| Shows overall signal status for both BUY and SELL               |
//+------------------------------------------------------------------+
void Signal_Analysis_Summary()
{
   // This function can be called periodically to show overall signal status
   Print("\n=== COMPREHENSIVE SIGNAL ANALYSIS SUMMARY ===");
   Print("Time: ", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS));
   
   // Market conditions
   double current_bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double current_ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double current_spread = current_ask - current_bid;
   double pip_size = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   if(SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 5 || SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 3)
      pip_size *= 10;
   double spread_pips = current_spread / pip_size;
   
   Print("Market Conditions:");
   Print("  Current Bid: ", current_bid);
   Print("  Current Ask: ", current_ask);
   Print("  Spread: ", DoubleToString(spread_pips, 1), " pips");
   Print("  Good Trading Time: ", (Is_Good_Trading_Time() ? "YES" : "NO"));
   
   // Trading capacity
   int current_trades = Count_Open_Trades(Magic_Number);
   bool can_trade = Can_Open_New_Trade(Magic_Number, Max_Open_Trades);
   
   Print("Trading Capacity:");
   Print("  Current Trades: ", current_trades, " / ", Max_Open_Trades);
   Print("  Can Open New Trade: ", (can_trade ? "YES" : "NO"));
   
   // Trend Analysis
   bool bullish_trend = Is_Bullish_Trend(EMA_Fast_Period, EMA_Slow_Period);
   bool bearish_trend = Is_Bearish_Trend(EMA_Fast_Period, EMA_Slow_Period);
   
   Print("Trend Analysis (D1):");
   Print("  Bullish Trend: ", (bullish_trend ? "✓" : "✗"));
   Print("  Bearish Trend: ", (bearish_trend ? "✓" : "✗"));
   
   // Pullback Analysis
   bool buy_pullback = Is_Buy_Pullback_Zone(BB_Period, BB_Deviations, RSI_Period, RSI_Buy_Min, RSI_Buy_Max);
   bool sell_pullback = Is_Sell_Pullback_Zone(BB_Period, BB_Deviations, RSI_Period, RSI_Sell_Min, RSI_Sell_Max);
   
   Print("Pullback Analysis (H4):");
   Print("  Buy Pullback Zone: ", (buy_pullback ? "✓" : "✗"));
   Print("  Sell Pullback Zone: ", (sell_pullback ? "✓" : "✗"));
   
   // Pattern Analysis
   bool bullish_pattern = (Is_Bullish_Engulfing(1) || Is_Bullish_PinBar(1));
   bool bearish_pattern = (Is_Bearish_Engulfing(1) || Is_Shooting_Star(1));
   
   Print("Pattern Analysis (H4):");
   Print("  Bullish Pattern: ", (bullish_pattern ? "✓" : "✗"));
   Print("  Bearish Pattern: ", (bearish_pattern ? "✓" : "✗"));
   
   // Signal Summary
   bool buy_signal = Check_Buy_Signal(EMA_Fast_Period, EMA_Slow_Period, BB_Period, BB_Deviations, 
                                     RSI_Period, RSI_Buy_Min, RSI_Buy_Max);
   bool sell_signal = Check_Sell_Signal(EMA_Fast_Period, EMA_Slow_Period, BB_Period, BB_Deviations, 
                                       RSI_Period, RSI_Sell_Min, RSI_Sell_Max);
   
   Print("Signal Summary:");
   Print("  🟢 BUY Signal: ", (buy_signal ? "ACTIVE" : "INACTIVE"));
   Print("  🔴 SELL Signal: ", (sell_signal ? "ACTIVE" : "INACTIVE"));
   
   // Overall Status
   string overall_status = "WAITING";
   if(buy_signal && can_trade && Is_Good_Trading_Time() && spread_pips <= 50.0)
      overall_status = "🟢 READY TO BUY";
   else if(sell_signal && can_trade && Is_Good_Trading_Time() && spread_pips <= 50.0)
      overall_status = "🔴 READY TO SELL";
   else if(!can_trade)
      overall_status = "⚠️ MAX TRADES REACHED";
   else if(!Is_Good_Trading_Time())
      overall_status = "⏰ OUTSIDE TRADING HOURS";
   else if(spread_pips > 50.0)
      overall_status = "📊 SPREAD TOO HIGH";
   
   Print("Overall Status: ", overall_status);
   
   // Log summary to file
   string summary_log = StringFormat(
      "SIGNAL SUMMARY - BUY: %s, SELL: %s, Trades: %d/%d, Status: %s, Spread: %.1f at %s",
      (buy_signal ? "Active" : "Inactive"),
      (sell_signal ? "Active" : "Inactive"),
      current_trades,
      Max_Open_Trades,
      overall_status,
      spread_pips,
      TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS)
   );
   Save_Log_To_File(summary_log, "SignalSummary");
   
   Print("=== SIGNAL ANALYSIS SUMMARY COMPLETE ===\n");
}

//+------------------------------------------------------------------+
//| Enhanced Execute Trade Manager                                   |
//| Manages all trade execution with safety checks and monitoring   |
//+------------------------------------------------------------------+
bool Enhanced_Execute_Trade_Manager(string signal_type, string signal_source)
{
   Print("\n=== ENHANCED TRADE EXECUTION MANAGER ===");
   Print("Signal Type: ", signal_type);
   Print("Signal Source: ", signal_source);
   Print("Time: ", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS));
   
   // Execution cooldown DISABLED FOR BACKTEST
   // if(execution_cooldown_active)
   // {
   //    datetime current_time = TimeCurrent();
   //    if((current_time - last_execution_attempt) < 60) // 60 seconds cooldown
   //    {
   //       Print("WARNING: Execution cooldown active - Last attempt ", (current_time - last_execution_attempt), " seconds ago");
   //       return false;
   //    }
   //    else
   //    {
   //       execution_cooldown_active = false;
   //       Print("LOG: Execution cooldown expired - Ready for new execution");
   //    }
   // }
   Print("✅ Execution cooldown check DISABLED for backtest compatibility");
   
   // Daily execution limits DISABLED FOR BACKTEST
   // datetime today_start = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   // if(last_execution_attempt < today_start)
   // {
   //    execution_attempts_today = 0; // Reset daily counter
   //    Print("LOG: Daily execution counter reset");
   // }
   // 
   // if(execution_attempts_today >= 10) // Maximum 10 execution attempts per day
   // {
   //    Print("ERROR: Daily execution limit reached (", execution_attempts_today, "/10)");
   //    return false;
   // }
   Print("✅ Daily execution limit check COMPLETELY DISABLED for backtest compatibility");
   
   // Pre-execution validation
   if(!Pre_Execution_Validation(signal_type))
   {
      Print("ERROR: Pre-execution validation failed");
      return false;
   }
   
   // Record execution attempt
   last_execution_attempt = TimeCurrent();
   // execution_cooldown_active = true; // DISABLED FOR BACKTEST
   
   Print("LOG: Execution attempt for today");
   
   // Execute based on signal type
   bool execution_result = false;
   
   if(signal_type == "BUY")
   {
      execution_result = Execute_Enhanced_Buy_Trade(signal_source);
   }
   else if(signal_type == "SELL")
   {
      execution_result = Execute_Enhanced_Sell_Trade(signal_source);
   }
   else
   {
      Print("ERROR: Invalid signal type: ", signal_type);
      return false;
   }
   
   // Log execution result
   string execution_log = StringFormat(
      "EXECUTION ATTEMPT - Type: %s, Source: %s, Result: %s at %s",
      signal_type,
      signal_source,
      (execution_result ? "SUCCESS" : "FAILED"),
      TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS)
   );
   Save_Log_To_File(execution_log, "ExecutionManager");
   
   Print("=== TRADE EXECUTION MANAGER COMPLETE ===\n");
   return execution_result;
}

//+------------------------------------------------------------------+
//| Pre-Execution Validation                                        |
//| Comprehensive checks before executing any trade                 |
//+------------------------------------------------------------------+
bool Pre_Execution_Validation(string signal_type)
{
   Print("--- PRE-EXECUTION VALIDATION ---");
   
   // 1. Trading permissions
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
   {
      Print("❌ Terminal trading not allowed");
      return false;
   }
   
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
   {
      Print("❌ EA trading not allowed");
      return false;
   }
   
   if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
   {
      Print("❌ Account trading not allowed");
      return false;
   }
   
   // 2. Symbol validation
   if(!SymbolInfoInteger(Symbol(), SYMBOL_SELECT))
   {
      Print("❌ Symbol not selected");
      return false;
   }
   
   if(!SymbolInfoInteger(Symbol(), SYMBOL_TRADE_MODE))
   {
      Print("❌ Symbol trading not allowed");
      return false;
   }
   
   // 3. Market status (TEMPORARILY DISABLED FOR BACKTEST)
   // if(!SymbolInfoInteger(Symbol(), SYMBOL_SESSION_DEALS))
   // {
   //    Print("❌ Market closed for trading");
   //    return false;
   // }
   Print("✅ Market status check DISABLED for backtest compatibility");
   
   // 4. Account status
   double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double account_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double account_margin_free = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   
   if(account_balance < 100)
   {
      Print("❌ Insufficient account balance: ", account_balance);
      return false;
   }
   
   if(account_equity < 100)
   {
      Print("❌ Insufficient account equity: ", account_equity);
      return false;
   }
   
   if(account_margin_free < 50)
   {
      Print("❌ Insufficient free margin: ", account_margin_free);
      return false;
   }
   
   // 5. Spread check
   double current_spread = SymbolInfoDouble(Symbol(), SYMBOL_ASK) - SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double pip_size = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   if(SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 5 || SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 3)
      pip_size *= 10;
   double spread_pips = current_spread / pip_size;
   
   if(spread_pips > 50.0)
   {
      Print("❌ Spread too high: ", DoubleToString(spread_pips, 1), " pips");
      return false;
   }
   
   // 6. Position limits
   if(!Can_Open_New_Trade(Magic_Number, Max_Open_Trades))
   {
      Print("❌ Maximum trades limit reached");
      return false;
   }
   
   // 7. Trading time
   if(!Is_Good_Trading_Time())
   {
      Print("❌ Outside good trading hours");
      return false;
   }
   
   Print("✅ All pre-execution validations passed");
   return true;
}

//+------------------------------------------------------------------+
//| Enhanced Execute BUY Trade                                      |
//| Execute BUY trade with enhanced monitoring and logging          |
//+------------------------------------------------------------------+
bool Execute_Enhanced_Buy_Trade(string signal_source)
{
   Print("--- ENHANCED BUY TRADE EXECUTION ---");
   Print("Signal Source: ", signal_source);
   
   // Get market prices before execution
   double current_ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double current_bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   
   Print("Pre-execution Market Data:");
   Print("  Ask Price: ", current_ask);
   Print("  Bid Price: ", current_bid);
   
   // Execute the trade using existing function
   bool result = Execute_Trade(ORDER_TYPE_BUY);
   
   if(result)
   {
      Print("✅ BUY TRADE EXECUTED SUCCESSFULLY");
      
      // Get post-execution data
      double post_ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      double post_bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      
      Print("Post-execution Market Data:");
      Print("  Ask Price: ", post_ask);
      Print("  Bid Price: ", post_bid);
      Print("  Price Change: ", DoubleToString(post_ask - current_ask, 5));
      
      // Enhanced logging
      string enhanced_log = StringFormat(
         "BUY TRADE SUCCESS - Source: %s, Pre-Ask: %.5f, Post-Ask: %.5f, Change: %.5f at %s",
         signal_source,
         current_ask,
         post_ask,
         (post_ask - current_ask),
         TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS)
      );
      Save_Log_To_File(enhanced_log, "EnhancedExecution");
      
      // Reset cooldown on successful execution (DISABLED FOR BACKTEST)
      // execution_cooldown_active = false;
   }
   else
   {
      Print("❌ BUY TRADE EXECUTION FAILED");
      
      // Keep cooldown active on failed execution
      string failure_log = StringFormat(
         "BUY TRADE FAILED - Source: %s, Ask: %.5f, Bid: %.5f at %s",
         signal_source,
         current_ask,
         current_bid,
         TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS)
      );
      Save_Log_To_File(failure_log, "EnhancedExecution");
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| Enhanced Execute SELL Trade                                     |
//| Execute SELL trade with enhanced monitoring and logging         |
//+------------------------------------------------------------------+
bool Execute_Enhanced_Sell_Trade(string signal_source)
{
   Print("--- ENHANCED SELL TRADE EXECUTION ---");
   Print("Signal Source: ", signal_source);
   
   // Get market prices before execution
   double current_ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double current_bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   
   Print("Pre-execution Market Data:");
   Print("  Ask Price: ", current_ask);
   Print("  Bid Price: ", current_bid);
   
   // Execute the trade using existing function
   bool result = Execute_Trade(ORDER_TYPE_SELL);
   
   if(result)
   {
      Print("✅ SELL TRADE EXECUTED SUCCESSFULLY");
      
      // Get post-execution data
      double post_ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      double post_bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      
      Print("Post-execution Market Data:");
      Print("  Ask Price: ", post_ask);
      Print("  Bid Price: ", post_bid);
      Print("  Price Change: ", DoubleToString(post_bid - current_bid, 5));
      
      // Enhanced logging
      string enhanced_log = StringFormat(
         "SELL TRADE SUCCESS - Source: %s, Pre-Bid: %.5f, Post-Bid: %.5f, Change: %.5f at %s",
         signal_source,
         current_bid,
         post_bid,
         (post_bid - current_bid),
         TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS)
      );
      Save_Log_To_File(enhanced_log, "EnhancedExecution");
      
      // Reset cooldown on successful execution (DISABLED FOR BACKTEST)
      // execution_cooldown_active = false;
   }
   else
   {
      Print("❌ SELL TRADE EXECUTION FAILED");
      
      // Keep cooldown active on failed execution
      string failure_log = StringFormat(
         "SELL TRADE FAILED - Source: %s, Ask: %.5f, Bid: %.5f at %s",
         signal_source,
         current_ask,
         current_bid,
         TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS)
      );
      Save_Log_To_File(failure_log, "EnhancedExecution");
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| Enhanced Trailing Stop Manager                                  |
//| Comprehensive trailing stop management with advanced features   |
//+------------------------------------------------------------------+
void Enhanced_Trailing_Stop_Manager()
{
   // Quick check if we have any positions
   int total_positions = PositionsTotal();
   if(total_positions == 0)
   {
      return; // Silent return - no positions to manage
   }
   
   // Check if trailing stop is enabled
   if(!Enable_Trailing_Stop)
   {
      return; // Silent return - trailing stop disabled
   }
   
   Print("\n=== ENHANCED TRAILING STOP MANAGER ===");
   Print("Time: ", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS));
   Print("Total Positions in Account: ", total_positions);
   
   int ea_positions = 0;
   int positions_updated = 0;
   int positions_analyzed = 0;
   double total_unrealized_profit = 0.0;
   
   // Loop through all positions to find EA trades
   for(int i = 0; i < total_positions; i++)
   {
      if(PositionGetTicket(i) > 0)
      {
         string position_symbol = PositionGetString(POSITION_SYMBOL);
         long position_magic = PositionGetInteger(POSITION_MAGIC);
         
         // Check if position belongs to this EA
         if(position_symbol == Symbol() && position_magic == Magic_Number)
         {
            ea_positions++;
            positions_analyzed++;
            
            // Get position details
            ulong ticket = PositionGetInteger(POSITION_TICKET);
            ENUM_POSITION_TYPE position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double current_profit = PositionGetDouble(POSITION_PROFIT);
            total_unrealized_profit += current_profit;
            
            Print("Analyzing Position #", ea_positions, " - Ticket: ", ticket, 
                  ", Type: ", (position_type == POSITION_TYPE_BUY ? "BUY" : "SELL"),
                  ", Profit: ", DoubleToString(current_profit, 2));
            
            // Apply advanced trailing stop logic
            bool updated = Apply_Advanced_Trailing_Stop(ticket, position_type);
            if(updated)
            {
               positions_updated++;
               Print("✅ Trailing stop updated for position ", ticket);
            }
         }
      }
   }
   
   // Summary report
   Print("--- TRAILING STOP SUMMARY ---");
   Print("EA Positions Found: ", ea_positions);
   Print("Positions Analyzed: ", positions_analyzed);
   Print("Positions Updated: ", positions_updated);
   Print("Total Unrealized P/L: ", DoubleToString(total_unrealized_profit, 2));
   
   // Log to file if any updates were made
   if(positions_updated > 0)
   {
      string trailing_log = StringFormat(
         "TRAILING STOP UPDATE - Positions: %d, Updated: %d, Total P/L: %.2f at %s",
         ea_positions,
         positions_updated,
         total_unrealized_profit,
         TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS)
      );
      Save_Log_To_File(trailing_log, "TrailingStopManager");
   }
   
   Print("=== TRAILING STOP MANAGER COMPLETE ===\n");
}

//+------------------------------------------------------------------+
//| Apply Advanced Trailing Stop Logic                              |
//| Advanced trailing stop with profit protection and optimization  |
//+------------------------------------------------------------------+
bool Apply_Advanced_Trailing_Stop(ulong ticket, ENUM_POSITION_TYPE position_type)
{
   // Select the position
   if(!PositionSelectByTicket(ticket))
   {
      Print("ERROR: Failed to select position ", ticket);
      return false;
   }
   
   // Get position details
   double position_volume = PositionGetDouble(POSITION_VOLUME);
   double position_price_open = PositionGetDouble(POSITION_PRICE_OPEN);
   double current_sl = PositionGetDouble(POSITION_SL);
   double current_tp = PositionGetDouble(POSITION_TP);
   double current_profit = PositionGetDouble(POSITION_PROFIT);
   datetime position_time = (datetime)PositionGetInteger(POSITION_TIME);
   
   // Get current market prices
   double current_bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double current_ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   
   // Calculate position age
   int position_age_seconds = (int)(TimeCurrent() - position_time);
   int position_age_hours = position_age_seconds / 3600;
   
   Print("Position Details - Open: ", position_price_open, 
         ", Current SL: ", (current_sl > 0 ? DoubleToString(current_sl, 5) : "None"),
         ", Profit: ", DoubleToString(current_profit, 2),
         ", Age: ", position_age_hours, "h");
   
   // Calculate pip values
   double pip_size = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   if(SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 5 || SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) == 3)
      pip_size *= 10;
   
   // Advanced trailing stop logic based on position type
   double new_sl = 0.0;
   bool should_update = false;
   string update_reason = "";
   
   if(position_type == POSITION_TYPE_BUY)
   {
      // BUY position trailing logic
      double trailing_distance = Trailing_Stop_Pips * pip_size;
      new_sl = current_bid - trailing_distance;
      
      // Advanced logic: Tighten trailing stop if position is very profitable
      if(current_profit > 100) // If profit > $100
      {
         trailing_distance = (Trailing_Stop_Pips * 0.7) * pip_size; // Reduce trailing distance by 30%
         new_sl = current_bid - trailing_distance;
         update_reason = "Profit Protection (Tight Trail)";
      }
      else if(current_profit > 50) // If profit > $50
      {
         trailing_distance = (Trailing_Stop_Pips * 0.85) * pip_size; // Reduce trailing distance by 15%
         new_sl = current_bid - trailing_distance;
         update_reason = "Profit Protection (Medium Trail)";
      }
      else
      {
         update_reason = "Standard Trailing";
      }
      
      // Only update if new SL is higher than current SL (or if no SL is set)
      if(current_sl == 0.0 || new_sl > current_sl)
      {
         // Additional safety: Don't set SL too close to current price
         double min_distance = 20 * pip_size; // Minimum 20 pips distance
         if((current_bid - new_sl) >= min_distance)
         {
            should_update = true;
         }
         else
         {
            Print("WARNING: New SL too close to current price - skipping update");
         }
      }
   }
   else // SELL position
   {
      // SELL position trailing logic
      double trailing_distance = Trailing_Stop_Pips * pip_size;
      new_sl = current_ask + trailing_distance;
      
      // Advanced logic: Tighten trailing stop if position is very profitable
      if(current_profit > 100) // If profit > $100
      {
         trailing_distance = (Trailing_Stop_Pips * 0.7) * pip_size; // Reduce trailing distance by 30%
         new_sl = current_ask + trailing_distance;
         update_reason = "Profit Protection (Tight Trail)";
      }
      else if(current_profit > 50) // If profit > $50
      {
         trailing_distance = (Trailing_Stop_Pips * 0.85) * pip_size; // Reduce trailing distance by 15%
         new_sl = current_ask + trailing_distance;
         update_reason = "Profit Protection (Medium Trail)";
      }
      else
      {
         update_reason = "Standard Trailing";
      }
      
      // Only update if new SL is lower than current SL (or if no SL is set)
      if(current_sl == 0.0 || new_sl < current_sl)
      {
         // Additional safety: Don't set SL too close to current price
         double min_distance = 20 * pip_size; // Minimum 20 pips distance
         if((new_sl - current_ask) >= min_distance)
         {
            should_update = true;
         }
         else
         {
            Print("WARNING: New SL too close to current price - skipping update");
         }
      }
   }
   
   // Execute the trailing stop update
   if(should_update)
   {
      // Normalize the new stop loss price
      int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
      new_sl = NormalizeDouble(new_sl, digits);
      
      Print("Updating Trailing Stop:");
      Print("  Position Type: ", (position_type == POSITION_TYPE_BUY ? "BUY" : "SELL"));
      Print("  Current SL: ", (current_sl > 0 ? DoubleToString(current_sl, 5) : "None"));
      Print("  New SL: ", DoubleToString(new_sl, 5));
      Print("  Reason: ", update_reason);
      Print("  Current Price: ", (position_type == POSITION_TYPE_BUY ? current_bid : current_ask));
      
      // Prepare modification request
      MqlTradeRequest request = {};
      MqlTradeResult result = {};
      
      request.action = TRADE_ACTION_SLTP;
      request.position = ticket;
      request.sl = new_sl;
      request.tp = current_tp; // Keep existing TP
      
      // Send the modification request
      bool modify_result = OrderSend(request, result);
      
      if(modify_result && result.retcode == TRADE_RETCODE_DONE)
      {
         Print("✅ Trailing stop updated successfully");
         
         // Enhanced logging
         string modification_log = StringFormat(
            "TRAILING STOP SUCCESS - Ticket: %I64d, Type: %s, Old SL: %.5f, New SL: %.5f, Reason: %s at %s",
            ticket,
            (position_type == POSITION_TYPE_BUY ? "BUY" : "SELL"),
            current_sl,
            new_sl,
            update_reason,
            TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS)
         );
         Save_Log_To_File(modification_log, "TrailingStopSuccess");
         
         return true;
      }
      else
      {
         Print("❌ Failed to update trailing stop - Return code: ", result.retcode);
         
         // Log the failure
         string failure_log = StringFormat(
            "TRAILING STOP FAILED - Ticket: %I64d, Return Code: %d, Description: %s at %s",
            ticket,
            result.retcode,
            GetTradeRetcodeDescription(result.retcode),
            TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS)
         );
         Save_Log_To_File(failure_log, "TrailingStopFailed");
         
         return false;
      }
   }
   else
   {
      // Log why update was skipped (only every 50 ticks to avoid spam)
      if(tick_counter % 50 == 0)
      {
         Print("LOG: Trailing stop not updated - Current SL is optimal or conditions not met");
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Trailing Stop Performance Monitor                               |
//| Monitor and report trailing stop performance                    |
//+------------------------------------------------------------------+
void Trailing_Stop_Performance_Monitor()
{
   Print("\n=== TRAILING STOP PERFORMANCE MONITOR ===");
   
   // Get current positions with trailing stops
   int total_positions = PositionsTotal();
   int ea_positions_with_sl = 0;
   int ea_positions_without_sl = 0;
   double total_protected_profit = 0.0;
   
   for(int i = 0; i < total_positions; i++)
   {
      if(PositionGetTicket(i) > 0)
      {
         string position_symbol = PositionGetString(POSITION_SYMBOL);
         long position_magic = PositionGetInteger(POSITION_MAGIC);
         
         if(position_symbol == Symbol() && position_magic == Magic_Number)
         {
            double current_sl = PositionGetDouble(POSITION_SL);
            double current_profit = PositionGetDouble(POSITION_PROFIT);
            ENUM_POSITION_TYPE position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double position_price_open = PositionGetDouble(POSITION_PRICE_OPEN);
            
            if(current_sl > 0)
            {
               ea_positions_with_sl++;
               
               // Calculate protected profit
               double protected_profit = 0.0;
               if(position_type == POSITION_TYPE_BUY)
               {
                  protected_profit = (current_sl - position_price_open) * PositionGetDouble(POSITION_VOLUME) * 
                                   SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE) * 
                                   SymbolInfoDouble(Symbol(), SYMBOL_POINT);
               }
               else
               {
                  protected_profit = (position_price_open - current_sl) * PositionGetDouble(POSITION_VOLUME) * 
                                   SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE) * 
                                   SymbolInfoDouble(Symbol(), SYMBOL_POINT);
               }
               
               total_protected_profit += protected_profit;
            }
            else
            {
               ea_positions_without_sl++;
            }
         }
      }
   }
   
   Print("Performance Summary:");
   Print("  Positions with Trailing SL: ", ea_positions_with_sl);
   Print("  Positions without SL: ", ea_positions_without_sl);
   Print("  Total Protected Profit: ", DoubleToString(total_protected_profit, 2));
   Print("  Trailing Stop Status: ", (Enable_Trailing_Stop ? "ENABLED" : "DISABLED"));
   Print("  Trailing Distance: ", Trailing_Stop_Pips, " pips");
   
   // Performance recommendations
   if(ea_positions_without_sl > 0 && Enable_Trailing_Stop)
   {
      Print("⚠️  RECOMMENDATION: Some positions lack stop loss protection");
   }
   
   if(total_protected_profit > 0)
   {
      Print("✅ GOOD: Trailing stops are protecting profits");
   }
   
   Print("=== TRAILING STOP PERFORMANCE MONITOR COMPLETE ===\n");
}



//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
