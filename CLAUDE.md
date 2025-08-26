# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a MetaTrader 5 Expert Advisor (EA) project implementing a **With-Trend Pullback Strategy** for XAUUSD (Gold) trading. The project uses a modular architecture with comprehensive logging and follows a systematic development approach based on accumulated knowledge from multiple EA development cycles.

## Development Commands

### MQL5 Compilation
```bash
# Compile in MetaEditor (MetaTrader 5's IDE)
# File → Compile (F7) or use the compile button
# The main file to compile is: "With-Trend Pullback Strategy for XAUUSD.mq5"
```

### Testing Commands
```bash
# Backtesting via Strategy Tester
# 1. Open MetaTrader 5
# 2. View → Strategy Tester (Ctrl+R)
# 3. Select the compiled EA (.ex5 file)
# 4. Configure period, symbol (XAUUSD), and parameters
# 5. Run backtest with "Every tick based on real ticks" model

# Optimization
# In Strategy Tester: Settings tab → Optimization
# Configure parameter ranges as specified in PRD.md section 7.1
```

### File Structure Requirements
- Main EA file: `.mq5` extension
- Include files: `.mqh` extension in `/Includes` folder  
- Compiled output: `.ex5` files (auto-generated)
- Results: CSV files in `/Result_BackTest` folder

## Architecture Overview

### Modular Design Pattern
The EA follows strict **Single Responsibility Principle** with 6 specialized modules:

```
With-Trend Pullback Strategy for XAUUSD.mq5  (Main controller)
├── Includes/01_Parameters.mqh    (Input parameters & constants)
├── Includes/02_Analysis.mqh      (Market analysis functions)
├── Includes/03_Signal.mqh        (Entry signal logic)
├── Includes/04_Execution.mqh     (Trade execution & risk management)
├── Includes/05_Management.mqh    (Position management & trailing stops)
└── Includes/06_Logging.mqh       (Comprehensive logging system)
```

### Trading Strategy Implementation
- **Primary Trend Analysis**: D1 timeframe using EMA crossover (13/39 periods)
- **Pullback Detection**: H4 timeframe using Bollinger Bands + RSI
- **Entry Confirmation**: Candlestick patterns (Bullish Engulfing, Pin Bar, etc.)
- **Risk Management**: ATR-based stop loss, fixed risk-reward ratio (1:2)
- **Position Sizing**: Dynamic lot calculation based on account risk percentage

### Advanced Logging System
- **Auto-Detection**: Automatically switches between backtest and live trading modes
- **CSV Output**: Generates multiple CSV files for comprehensive analysis
  - `*_TradeHistory.csv`: Complete trade records with P&L analysis
  - `*_SignalHistory.csv`: All detected signals (executed and missed)  
  - `*_ExecutionHistory.csv`: Detailed execution metrics and slippage
  - `*_Summary_Report.csv`: Performance summary with key metrics

## Key Development Workflows

### EA Development Process
Follow this systematic approach based on `TASK.md`:

1. **Phase 0**: Set up modular file structure
2. **Phase 1**: Implement parameters and analysis functions  
3. **Phase 2**: Build signal generation and execution logic
4. **Phase 3**: Add trade management and logging
5. **Phase 4**: Integrate main EA assembly and testing

### Parameter Optimization Workflow
```mql5
// Key parameters for optimization (from PRD.md):
RSI_Buy_Min: 30-45 (step: 5)
RSI_Buy_Max: 50-70 (step: 5)  
RSI_Sell_Min: 30-50 (step: 5)
RSI_Sell_Max: 55-70 (step: 5)
ATR_SL_Multiplier: 1.5-3.0 (step: 0.1)
Risk_Reward_Ratio: 1.5-2.5 (step: 0.1)
```

### Testing Procedures
1. **Backtest Phase**: Minimum 2 years historical data with realistic spread/slippage
2. **Demo Phase**: 3+ months forward testing across different market conditions  
3. **Live Phase**: Gradual deployment with strict risk controls

## Common Issues & Solutions

### Compilation Errors
- `'function_name' - wrong parameters count` → Check function declarations match usage
- `'variable_name' - undeclared identifier` → Verify all include files are properly referenced
- `cannot open source file` → Check relative paths to include files

### Runtime Issues
- **High Spread**: XAUUSD spread can be 25-55 pips (normal), adjust `MAX_SPREAD_PIPS` to 50.0
- **RSI Range Too Narrow**: Expand ranges from 40-55 to 30-70 for more signals
- **BB Tolerance**: Add 30% tolerance zone around Bollinger Bands for pullback detection

### Order Execution Issues  
```mql5
// Use 2-step order execution for complex brokers:
// Step 1: Market order without SL/TP
// Step 2: Modify position to add SL/TP
```

### Logging Data Quality Issues
- Entry/Exit prices = 0 → Use fallback price retrieval methods
- Entry/Exit times = 1970.01.01 → Use TimeCurrent() fallback
- Missing CSV files → Ensure proper function calls to logging system

## Critical Configuration

### XAUUSD-Specific Settings
```mql5
#define MAX_SPREAD_PIPS 50.0        // Gold-optimized spread limit
#define RISK_PER_TRADE_PERCENT 1.0  // Conservative risk per trade
#define MAX_OPEN_TRADES 1           // Single position strategy
```

### Performance Targets
- Win Rate: >45%
- Profit Factor: >1.5  
- Max Drawdown: <20%
- Average Slippage: <1.0 pips

## File Dependencies

### Core Dependencies
- Main EA depends on all 6 include files
- Include files have minimal cross-dependencies
- 01_Parameters.mqh provides constants used by other modules

### Documentation Hierarchy
- `PRD.md`: Complete technical specification (reference for implementation)
- `EA_Development_Knowledge_Base.md`: Master troubleshooting guide and best practices
- `TASK.md`: Development task breakdown and completion tracking
- `Documentation_Archive/`: Historical documentation for reference

### Result Analysis Files
- `Result_BackTest/`: Contains CSV outputs and test results
- Use Excel formulas provided in knowledge base for data quality validation
- Monitor key ratios: Signal-to-Execution (≈100%), Average Slippage (<1.0 pips)

## Important Notes

### Code Style
- Follow existing MQL5 naming conventions
- Use comprehensive error handling and validation
- Include detailed logging for debugging
- Maintain modular separation of concerns

### Risk Management
- Never modify risk parameters without thorough testing
- Always validate input parameters in OnInit()
- Use fallback values for critical calculations
- Implement maximum daily loss limits

### When Making Changes
1. Read the EA_Development_Knowledge_Base.md first
2. Follow the established modular pattern  
3. Test changes in backtest before live deployment
4. Update documentation with lessons learned
5. Use the comprehensive logging system to track performance

This EA represents sophisticated algorithmic trading implementation with professional-grade logging, risk management, and systematic development approach. Treat it as production-level code requiring careful testing and validation of any modifications.