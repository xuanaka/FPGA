### 1. PWM 產生器 (`hw1_2cnters.v`)
這是一個用 **Verilog** 撰寫的底層模組，負責產生單一 PWM 訊號。

*   **功能**：接收兩個計數上限值 (`i_upperBound1`, `i_upperBound2`)，依序進行計數切換輸出狀態。
*   **輸入**：
    *   `i_clk`, `i_rst`: 時脈與重置訊號。
    *   `i_upperBound1`: 控制輸出為 **Low (0)** 的時間長度（計數器 1）。
    *   `i_upperBound2`: 控制輸出為 **High (1)** 的時間長度（計數器 2）。
*   **輸出**：`o_state` (PWM 波形)。
*   **邏輯**：使用兩個計數器與一個簡單的 FSM (Finite State Machine) 在 0 與 1 之間切換。

### 2. 上層控制模組 (`breath_dual.vhd`)
這是一個用 **VHDL** 撰寫的頂層模組 (Top Module)，負責控制整體邏輯與實例化 PWM 模組。

*   **功能**：
    1.  實例化兩個 `hw1_2cnters` 模組，分別控制 LED1 和 LED2。
    2.  管理呼吸燈的狀態機 (`gettingBright`, `gettingDark`)。
    3.  動態調整 `upbnd1` 與 `upbnd2` 的數值，改變 PWM 的佔空比。
    4.  控制呼吸速度（透過 `pwmCnt` 累計 P 個週期後才調整一次亮度）。
*   **互補邏輯**：
    *   **LED1**: 變亮階段 (`upbnd1` 增加, `upbnd2` 減少)。
    *   **LED2**: 變暗階段 (與 LED1 相反)。
    *   *註：此設計中 `upbnd1` 與 `upbnd2` 被同時用於兩個 PWM 模組，但輸入端口交換，達到互補效果。*

## 運作原理

1.  **PWM 產生**：
    底層 Verilog 模組根據輸入的兩個上限值產生方波。
    *   若 `i_upperBound1` 小、`i_upperBound2` 大，則 High 的時間較長 (LED 亮)。
    *   若 `i_upperBound1` 大、`i_upperBound2` 小，則 High 的時間較短 (LED 暗)。

2.  **亮度調整 (Breathing)**：
    VHDL 模組中的 `upbnd1p` 和 `upbnd2p` process 負責改變計數器的上限值。
    *   `upbnd1` 從 0 數到 255 再數回 0。
    *   `upbnd2` 從 255 數到 0 再數回 255。

3.  **速度控制**：
    為了讓人眼能感受到平滑的呼吸效果，亮度不能每個 Clock Cycle 都改變。
    *   設計中使用了一個計數器 `pwmCnt`，每偵測到 `P` (255) 個 PWM 週期後，觸發訊號 `alreadyP_PWM_cycles`。
    *   只有在 `alreadyP_PWM_cycles` 為 High 時，亮度的數值才會加 1 或減 1。
