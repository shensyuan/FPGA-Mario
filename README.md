# FinalProject — FPGA 馬利歐遊戲

以 Verilog 實作、運行於 **Terasic DE10-Lite (MAX 10 FPGA)** 的橫向捲軸馬利歐遊戲。畫面透過 VGA 輸出，並使用 7 段顯示器、點矩陣、按鍵/LED 作為周邊互動。

---

## 1. 硬體平台

| 項目 | 內容 |
| --- | --- |
| 開發板 | Terasic DE10-Lite |
| FPGA | MAX 10 `10M50DAF484C7G` (FBGA 484, speed grade 7) |
| 開發工具 | Quartus Prime Lite 18.1 |
| 系統時脈 | `MAX10_CLK1_50` / `MAX10_CLK2_50` (50 MHz)、`ADC_CLK_10` (10 MHz) |
| 顯示 | VGA 640×480、2× 8×8 點矩陣 |
| 輸入 | 4×4 矩陣鍵盤 或 Arduino IO |
| 時間約束 | `FinalProject.sdc` (3 個 clock，10/50/50 MHz) |

---

## 2. 系統架構

### 模組階層

```
FinalProject (top, FinalProject.v)
├── Game                       遊戲核心
│   ├── Render                 像素/貼圖繪製
│   ├── MapParser              關卡地圖解析
│   │   └── Collision          碰撞與邊界計算
│   └── PlayerController       玩家物理與操作
├── VGA_Output                 VGA 時序與掃描座標
├── KeyPadController           4x4 鍵盤掃描
├── DotMatrix_Output           點矩陣圖示顯示
└── SegDecoder ×6             7 段顯示器解碼 (HEX0~HEX5)
```

### 時脈與重置配置

- `MAX10_CLK1_50` → `Game`、`VGA_Output`（遊戲與繪圖主時脈）
- `MAX10_CLK2_50` → `KeyPadController`、`DotMatrix_Output`、`SegDecoder`（周邊時脈）
- `KEY[0]` → 全域非同步重置（低電位動作 `RST_N`）

### 頂層訊號流

```
                    ┌──────────────┐
 keyboard ────────► │              │ ── rgb_output ──► VGA_Output ──► VGA_R/G/B, HS, VS
                    │              │
 MAX10_CLK1_50 ────►│     Game     │ ── IS_JUMP ─────► (未使用)
 KEY[0] ───────────►│              │
                    │              │ ── COUNTER ─────► SegDecoder ×6 ──► HEX0..HEX5
                    └──────────────┘
 KeyPadController ──► keyboard
 DotMatrix_Output ─► ROW, COL_0, COL_1
```

`render_x` / `render_y` 由 `VGA_Output` 反向提供給 `Game`，代表目前掃描到的像素座標。

---

## 3. 操作方式

遊戲按鍵（`KEYBOARD[3:0]`）：

| Bit | 功能 |
| --- | --- |
| `[0]` | 跳躍 |
| `[2]` | 向左 |
| `[3]` | 向右 |
| `[1]` | 保留 (`1'b0`) |

輸入來源切換：

- `SW[0] = 0` → 使用 **Arduino IO**（`ARDUINO_IO[3:0]`）
- `SW[0] = 1` → 使用 **4×4 矩陣鍵盤**（`K_ROW` / `K_COL`）

顯示器模式（由鍵盤 `KeyPadController.COUNT_STATE` 決定，對應按鍵 `keys[15]/[11]/[7]/[3]`）：

| COUNT_STATE | 顯示內容 |
| --- | --- |
| `0` | 死亡次數 (`death_count`) |
| `1` | 金幣數量 (`coin_count`) |
| 其他 | 動畫 (`24'hffffff`，觸發 `SegDecoder` 跑馬燈動畫) |

點矩陣：`IS_WALK` 為走路時顯示動畫，`REVERSE` 控制方向反轉。

---

## 4. 檔案結構

```
FinalProject_u/
├── FinalProject.v              頂層模組：連接所有周邊與 Game
├── FinalProject.qpf            Quartus 專案檔
├── FinalProject.qsf            專案設定與腳位約束
├── FinalProject.sdc            時序約束
├── FinalProject.htm            Quartus 專案說明頁
│
├── modules/
│   ├── VGA_Output.v            VGA 時序產生器 (640×480)
│   ├── KeyPadController.v      4x4 矩陣鍵盤掃描與解碼
│   ├── DotMatrix_Output.v      點矩陣掃描顯示 (走路/停止圖示)
│   └── Game/
│       ├── variable.v          全域巨集：尺寸、速度、計時器、顏色
│       ├── Game.v              遊戲頂層：串接 Render/MapParser/Controller
│       ├── PlayerController.v  玩家物理、位移、跳躍、地圖切換、死亡
│       ├── Render.v            貼圖繪製與背景合成
│       └── MapParser/
│           ├── MapParser.v     地圖資料、金幣/磚塊狀態、輸出畫素區塊
│           └── Collision.v     玩家碰撞邊界 (上下左右極限) 計算
│
├── utils/
│   └── SegDecoder.v            16 進位/動畫的 7 段解碼器
│
├── data/                       精靈 (sprite) 貼圖，12-bit RGB hex
│   ├── Mario.hex / Mario_Jump.hex / Mario_Walk1.hex / Mario_Walk2.hex
│   ├── Ground.hex / Block.hex / Brick.hex
│   └── Gold.hex / Gold_Empty.hex
│
├── map/                        關卡資料
│   ├── Main.hex               關卡地形圖 (每欄 15-bit)
│   ├── Gold.hex               金幣方塊座標
│   └── Brick.hex              可破壞磚塊座標
│
├── dot_matrix_image/           點矩陣圖示 (8×8 binary)
│   ├── walk.hex / stop.hex
│   ├── heart.hex / 0.hex ~ 9.hex   (部分未使用)
│
├── output_files/               Quartus 輸出 (.sof 燒錄檔, .cdf)
├── db/                         Quartus 資料庫
└── .vscode/                    建置/燒錄 task 與編輯器設定
```

> 註：`FinalProject.qsf` 有引用 `utils/BothEdge.v`，但專案中無此檔案，編譯時會出現找不到檔案的訊息（不影響其餘模組）。

---

## 5. 各模組說明

### `FinalProject.v`（頂層）
連接所有子模組。設定 `HEX0..HEX5` 的最高位（小數點）恆為 1，並依 `SW[0]` 選擇鍵盤或 Arduino 作為輸入。將 `counter` 拆成 6 個 4-bit 片段送到 6 顆 `SegDecoder`。

### `VGA_Output.v`
以除 2 計數器從 50 MHz 產生 25 MHz 像素時脈。產生水平 (`h_pos` 0~799) 與垂直 (`v_pos` 0~524) 掃描位置，輸出 `VGA_HS`/`VGA_VS`。可見區域為 `H_START=144`、`V_START=35` 起算的 640×480，並將 `render_x/render_y` 提供給遊戲邏輯。

### `KeyPadController.v`
輪詢式掃描 4×4 鍵盤：依序將 `K_ROW` 拉低，讀取 `K_COL` 並鎖存成 `keys[15:0]`（含去彈跳用的回授保持）。最後映射為遊戲用的 4-bit `KEYBOARD`，並輸出 `COUNT_STATE`。

### `DotMatrix_Output.v`
以 `counter[15:13]` 做列掃描，`ROW` 為低電位有效列選擇；`COL[15:8]` 依 `IS_WALK`/`REVERSE` 顯示 `WALK` 或 `STOP` 圖示。圖示以 `$readmemb` 從 `dot_matrix_image/*.hex` 載入。

### `SegDecoder.v`
解碼 `VAL` (0~F) 為 7 段碼；當 `ANI` 致能時改顯示跑馬燈動畫（用於死亡/結束效果）。

### `Game.v`
遊戲核心整合：
- `Render`：依座標與 `BLOCK_TYPE` 產生 `RGB_OUTPUT`。
- `MapParser`：提供畫素對應的 `BLOCK_TYPE` 與碰撞極限 `limit_u/d/l/r`、`coin_count`。
- `PlayerController`：輸出玩家座標、方向、走路動畫、`map_index`、`death_count`。
- `COUNTER` 依 `COUNT_STATE` 選擇死亡數/金幣數/動畫值。
- `IS_JUMP = player_y < limit_d`（未落地）。

### `PlayerController.v`
玩家狀態機與物理模擬：
- 初始位置 `x=72`、`y = GROUND - 2*BLOCK_HEIGHT`。
- 左右移動依 `timer_x` 達 `KEYBOARD_TIMER` 觸發一格，並檢查 `LIMIT_L/R`。
- 走路動畫計時器 `walking_timer` 切換 `walking_animation`。
- 跳躍分兩段：短跳 (`JUMP_TIMER`) 與長按加力 (`JUMP_TIMER_2`)。
- 重力：`gforce_timer` 週期性遞減 `y_speed`（`GFORCE`）。
- 位置更新：`y_pos_timer` 觸發，處理天花板 (`LIMIT_U_POS`)、地板 (`LIMIT_D_POS`) 夾制。
- 掉出地圖 (`y_pos > GROUND + 2*BLOCK_HEIGHT`) 時 `death_count + 1` 並重生。
- 抵達畫面左右邊界時切換 `map_index`（`MAP_LENGTH=2` 個關卡循環）。

### `Render.v`
- 用 `$readmemh` 載入 Mario 各動作與場景貼圖（16×16，共 256 像素）。
- 依 `DIRECTION` 做水平翻轉、依 `PLAYER_Y < ON_GROUND` 判斷跳躍圖、`WALKING`/`WALKING_ANIMATION` 選擇走路圖。
- 方塊貼圖依 `BLOCK_TYPE` 選擇：`GROUND/BLOCK/GOLD/GOLD_EMPTY/BRICK`。
- 無貼圖時填入背景色 `` `BG_COLOR `` (`12'h33e`)。

### `MapParser.v`
- `MAP_DATA[20*MAP_LENGTH]`：每筆 15-bit 表示「某一欄各列是否有方塊」；`ORIGIN_MAP_DATA` 保存原始地圖供重置。
- `GOLD_MAP_DATA` / `GOLD_STATE_DATA`：金幣位置與是否已取得。
- `BRICK_MAP_DATA` / `BRICK_STATE_DATA`：磚塊位置與剩餘耐久（初始 2，每撞一次減 1，歸零消失）。
- 玩家頂到方塊 (`PLAYER_Y == LIMIT_U_POS`) 時判定金幣/磚塊並更新 `coin_count`。
- `BLOCK_TYPE`：地面回傳 `1`，金幣依狀態回傳 `3/4`，磚塊回傳 `5`，其餘查表。

### `Collision.v`
由玩家座標與鄰近 4 欄方塊位圖，計算：
- `LIMIT_U_POS` / `LIMIT_D_POS`：可移動的上下邊界。
- `LIMIT_L` / `LIMIT_R`：左右是否碰牆。
- `PLAYER_BLOCK_X/Y`、`PLAYER_X/Y_INBLOCK`：玩家所在方塊與是否對齊格線。

---

## 6. 資料格式

### 貼圖 `data/*.hex`
16×16 共 256 個 12-bit 顏色值（RGB444），以空白分隔。`$readmemh` 載入到 `reg [11:0] XXX[256]`。

### 點矩陣 `dot_matrix_image/*.hex`
8 行、每行 8-bit（binary），`$readmemb` 載入。

### 關卡 `map/Main.hex`
每欄一個 15-bit 值（16 進位），共 `20 × MAP_LENGTH = 40` 欄。
Bit `y` 表示第 `y` 列（`y=0` 最上方，`y=14` 最下方）是否為實心方塊。

### 座標 `map/Gold.hex`、`map/Brick.hex`
17-bit 座標 `{block_x[4:0], block_y[3:0], map_index[7:0]}`，例如 `07900` → 地圖 0、`(x=7, y=9)`。

### 方塊類型 `BLOCK_TYPE`
| 值 | 意義 |
| --- | --- |
| 0 | 空 |
| 1 | 地面 (Ground) |
| 2 | 一般方塊 (Block) |
| 3 | 金幣方塊 (Gold) |
| 4 | 已取得金幣方塊 (Gold_Empty) |
| 5 | 磚塊 (Brick) |

---

## 7. 遊戲參數 (`modules/Game/variable.v`)

| 巨集 | 值 | 說明 |
| --- | --- | --- |
| `BLOCK_UNIT_WIDTH/HEIGHT` | 16 | 單一貼圖像素尺寸 |
| `BLOCK_UNIT_SIZE` | 256 | 貼圖像素數 |
| `BLOCK_WIDTH/HEIGHT` | 32 | 遊戲中方塊顯示尺寸 |
| `BLOCK_MASK` | 31 | 取格內偏移 |
| `TO_BLOCK_SHIFT` | 5 | 座標 → 方塊索引位移 |
| `MAP_LENGTH` | 2 | 關卡數 |
| `GOLD_LENGTH` / `BRICK_LENGTH` | 2 / 3 | 金幣 / 磚塊數量 |
| `KEYBOARD_TIMER` | 400000 | 水平移動觸發週期 |
| `JUMP_TIMER` / `JUMP_TIMER_2` | 80000 / 6000000 | 短跳 / 長跳計時 |
| `WALKING_TIMER` | 6000000 | 走路動畫切換週期 |
| `GFORCE_TIMER` | 2000000 | 重力更新週期 |
| `Y_POS_TIMER` | 1250000 | Y 位置更新週期 |
| `GFORCE` | 1 | 重力加速度 |
| `JUMP_FORCE` / `JUMP_FORCE_2` | 6 / 6 | 跳躍初速 / 長跳加力 |
| `GROUND` | 384 | 地面 Y 基準 |
| `BG_COLOR` | `12'h33e` | 背景顏色 |

---

## 8. 建置與燒錄

### 使用 Quartus Prime
1. 開啟 `FinalProject.qpf`。
2. 執行 **Processing → Start Compilation**。
3. 以 **Programmer** 燒錄 `output_files/FinalProject.sof`。

### 使用 VS Code Tasks
`.vscode/tasks.json` 提供：

| Task | 指令 | 說明 |
| --- | --- | --- |
| `Build` | `quartus_cmd FinalProject -c FinalProject` | 編譯專案 |
| `Test` | `quartus_pgm -c USB-Blaster output_files/FinalProject.cdf` | 燒錄到板子 |
| `Build & Test` | 先 Build 後 Test | 一鍵建置並燒錄 |

> 需先將 Quartus 的 `bin` 目錄加入系統 `PATH`。
