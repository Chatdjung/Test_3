EA Development Task List - Modular Refactoring
(อ้างอิงจาก PRD ฉบับปรับปรุง)

Task Breakdown Table
ID	Task Title	Module / File	Status	Priority	Dependencies
PHASE 0: PROJECT & FILE STRUCTURE SETUP
P0.1	สร้างโฟลเดอร์ /Includes ภายในโฟลเดอร์โปรเจกต์	N/A	✅ Done	High	-
P0.2	สร้างไฟล์ 01_Parameters.mqh	Includes/	✅ Done	High	P0.1
P0.3	สร้างไฟล์ 02_Analysis.mqh	Includes/	✅ Done	High	P0.1
P0.4	สร้างไฟล์ 03_Signal.mqh	Includes/	✅ Done	High	P0.1
P0.5	สร้างไฟล์ 04_Execution.mqh	Includes/	✅ Done	High	P0.1
P0.6	สร้างไฟล์ 05_Management.mqh	Includes/	✅ Done	High	P0.1
P0.7	สร้างไฟล์ 06_Logging.mqh	Includes/	✅ Done	High	P0.1
PHASE 1: PARAMETERS & CORE ANALYSIS FUNCTIONS
P1.1	ย้าย input Parameters ทั้งหมดไปไว้ในไฟล์	01_Parameters.mqh	✅ Done	High	P0.2
P1.2	สร้างฟังก์ชัน Is_Bullish_Trend() และ Is_Bearish_Trend()	02_Analysis.mqh	✅ Done	High	P0.3, P1.1
P1.3	สร้างฟังก์ชัน Is_Buy_Pullback_Zone()	02_Analysis.mqh	✅ Done	High	P0.3, P1.1
P1.4	สร้างฟังก์ชัน Is_Sell_Pullback_Zone()	02_Analysis.mqh	✅ Done	High	P0.3, P1.1
P1.5	สร้างฟังก์ชัน Is_Bullish_Engulfing()	02_Analysis.mqh	✅ Done	High	P0.3
P1.6	สร้างฟังก์ชัน Is_Bullish_PinBar()	02_Analysis.mqh	✅ Done	High	P0.3
P1.7	สร้างฟังก์ชัน Is_Bearish_Engulfing()	02_Analysis.mqh	✅ Done	High	P0.3
P1.8	สร้างฟังก์ชัน Is_Shooting_Star()	02_Analysis.mqh	✅ Done	High	P0.3
PHASE 2: SIGNAL GENERATION & EXECUTION LOGIC
P2.1	สร้างฟังก์ชัน Check_Buy_Signal() (เรียกใช้ฟังก์ชันจาก Analysis)	03_Signal.mqh	✅ Done	High	P0.4, P1.2, P1.3, P1.5, P1.6
P2.2	สร้างฟังก์ชัน Check_Sell_Signal() (เรียกใช้ฟังก์ชันจาก Analysis)	03_Signal.mqh	✅ Done	High	P0.4, P1.2, P1.4, P1.7, P1.8
P2.3	สร้างฟังก์ชัน Calculate_Stop_Loss()	04_Execution.mqh	✅ Done	High	P0.5, P1.1
P2.4	สร้างฟังก์ชัน Calculate_Take_Profit()	04_Execution.mqh	✅ Done	High	P0.5, P1.1
P2.5	สร้างฟังก์ชัน Calculate_Lot_Size()	04_Execution.mqh	✅ Done	High	P0.5, P1.1
P2.6	สร้างฟังก์ชัน Execute_Trade() (เรียกใช้ฟังก์ชันคำนวณและส่งออเดอร์)	04_Execution.mqh	✅ Done	High	P2.3, P2.4, P2.5
PHASE 3: TRADE MANAGEMENT & LOGGING
P3.1	สร้างฟังก์ชัน Count_Open_Trades()	05_Management.mqh	✅ Done	High	P0.6
P3.2	สร้างฟังก์ชัน Manage_Trailing_Stop() (ถ้า Enable_Trailing_Stop เป็น true)	05_Management.mqh	✅ Done	Medium	P0.6, P1.1, P3.1
P3.3	สร้างฟังก์ชัน Log_Trade_Exit()	06_Logging.mqh	✅ Done	High	P0.7
P3.4	สร้างฟังก์ชัน Log_Signal_Check() (สำหรับ Buy/Sell)	06_Logging.mqh	✅ Done	Medium	P0.7
P3.5	สร้างฟังก์ชัน Log_Execution_Attempt()	06_Logging.mqh	✅ Done	Medium	P0.7
PHASE 4: MAIN EA ASSEMBLY & FINALIZATION
P4.1	เพิ่ม #include ทั้งหมดในไฟล์หลัก	With-Trend Pullback Strategy for XAUUSD.mq5	✅ Done	High	P1.1, P1.2, P2.1, P2.6, P3.1
P4.2	สร้างฟังก์ชัน OnInit() (เรียกใช้ Validation และ Logging เริ่มต้น)	With-Trend Pullback Strategy for XAUUSD.mq5	✅ Done	High	P4.1
P4.3	สร้างฟังก์ชัน OnDeinit() (เรียกใช้ Logging ตอนปิด)	With-Trend Pullback Strategy for XAUUSD.mq5	✅ Done	High	P4.1
P4.4	สร้าง Logic OnTick(): ตรวจสอบ New H4 Candle	With-Trend Pullback Strategy for XAUUSD.mq5	✅ Done	High	P4.1
P4.5	สร้าง Logic OnTick(): ตรวจสอบ Count_Open_Trades()	With-Trend Pullback Strategy for XAUUSD.mq5	✅ Done	High	P4.4, P3.1
P4.6	สร้าง Logic OnTick(): เรียกใช้ Check_Buy_Signal()	With-Trend Pullback Strategy for XAUUSD.mq5	✅ Done	High	P4.5, P2.1
P4.7	สร้าง Logic OnTick(): เรียกใช้ Check_Sell_Signal()	With-Trend Pullback Strategy for XAUUSD.mq5	✅ Done	High	P4.5, P2.2
P4.8	สร้าง Logic OnTick(): เรียกใช้ Execute_Trade()	With-Trend Pullback Strategy for XAUUSD.mq5	✅ Done	High	P4.6, P4.7, P2.6
P4.9	สร้าง Logic OnTick(): เรียกใช้ Manage_Trailing_Stop()	With-Trend Pullback Strategy for XAUUSD.mq5	✅ Done	High	P4.5, P3.2
P4.10	คอมไพล์โปรเจกต์ทั้งหมดและแก้ไข Error ที่เกิดจากการเชื่อมต่อไฟล์	N/A	✅ Done	High	P4.2, P4.3, P4.9
PHASE 4.5: MULTI-TIMEFRAME RSI IMPLEMENTATION (STRATEGY COMPLIANCE FIX)
P4.11	สร้างฟังก์ชัน Get_Multi_Timeframe_RSI() ใน 02_Analysis.mqh	Includes/02_Analysis.mqh	✅ Done	Critical	P4.10
P4.12	สร้างฟังก์ชัน Is_Multi_TF_Oversold() ใน 02_Analysis.mqh	Includes/02_Analysis.mqh	✅ Done	Critical	P4.11
P4.13	สร้างฟังก์ชัน Is_Multi_TF_Overbought() ใน 02_Analysis.mqh	Includes/02_Analysis.mqh	✅ Done	Critical	P4.11
P4.14	แก้ไข Is_Buy_Pullback_Zone() ให้เรียกใช้ Multi-TF RSI	Includes/02_Analysis.mqh	✅ Done	Critical	P4.12
P4.15	แก้ไข Is_Sell_Pullback_Zone() ให้เรียกใช้ Multi-TF RSI	Includes/02_Analysis.mqh	✅ Done	Critical	P4.13
P4.16	ทดสอบคอมไพล์หลังแก้ไข Multi-TF RSI	N/A	✅ Done	Critical	P4.14, P4.15
P4.17	แก้ไข Logging System ให้รองรับ Multi-TF RSI data	Includes/06_Logging_Multi_TF.mqh	✅ Done	High	P4.16
P4.18	ทดสอบ Backtest แบบสั้นเพื่อตรวจสอบ Compliance Rate	N/A	To Do	Critical	P4.17
PHASE 5: TESTING (FROM ORIGINAL TASK LIST)
P5.1	ทดสอบ Backtesting ด้วย Strategy Tester	N/A	To Do	High	P4.18
P5.2	ปรับจูนพารามิเตอร์ด้วย Optimization Module	N/A	To Do	High	P5.1
P5.3	ทดสอบ Forward Testing บน Demo Account	N/A	To Do	High	P5.2
