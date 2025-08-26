//+------------------------------------------------------------------+
//|                                               01_Parameters.mqh |
//|                                                       Chatchai.D |
//|                                   With-Trend Pullback Strategy  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Parameters Constants - For Include File Usage                   |
//| Note: Input parameters must be defined in main .mq5 file        |
//+------------------------------------------------------------------+

//=== STATIC PARAMETERS ===
#define EMA_FAST_PERIOD 13             // Fast EMA Period
#define EMA_SLOW_PERIOD 39             // Slow EMA Period
#define RSI_PERIOD 14                  // RSI Period
#define BB_PERIOD 20                   // Bollinger Bands Period
#define BB_DEVIATIONS 2.0              // Bollinger Bands Deviations
#define ATR_PERIOD 14                  // ATR Period

//=== MARKET CONDITIONS ===
#define MAX_SPREAD_PIPS 50.0           // Maximum allowed spread in pips (optimized for GOLD)
#define MIN_SPREAD_PIPS 1.0            // Minimum expected spread in pips
#define SPREAD_CHECK_ENABLED true      // Enable spread checking before trading

//=== OPTIMIZABLE PARAMETERS ===
#define RSI_BUY_MIN 30                 // RSI Minimum for Buy Signal (expanded from 40)
#define RSI_BUY_MAX 60                 // RSI Maximum for Buy Signal (expanded from 55)
#define RSI_SELL_MIN 40                // RSI Minimum for Sell Signal (expanded from 45)
#define RSI_SELL_MAX 70                // RSI Maximum for Sell Signal (expanded from 60)
#define ATR_SL_MULTIPLIER 2.0          // ATR Multiplier for Stop Loss
#define RISK_REWARD_RATIO 2.0          // Risk to Reward Ratio
#define RISK_PER_TRADE_PERCENT 1.0     // Risk per Trade (%)

//=== TRADE MANAGEMENT ===
#define MAX_LOT_SIZE 1.0               // Maximum Lot Size
#define MIN_LOT_SIZE 0.01              // Minimum Lot Size
#define MAX_OPEN_TRADES 1              // Maximum Open Trades
#define ENABLE_TRAILING_STOP false     // Enable Trailing Stop
#define TRAILING_STOP_PIPS 50          // Trailing Stop in Pips

//=== MAGIC NUMBER ===
#define MAGIC_NUMBER 123456            // EA Magic Number

//=== TRADING TIME MANAGEMENT ===
#define GOOD_TRADING_HOURS_START 8     // Good trading hours start (London/NY overlap)
#define GOOD_TRADING_HOURS_END 17      // Good trading hours end
#define AVOID_NEWS_MINUTES 30          // Minutes to avoid trading around major news

//+------------------------------------------------------------------+
