# OntoCMS (Go 版) 核心框架 - plan.md

### Purpose
*   將 `idea.md` 中確認的「實體優先 (Entity-First)」與「FORK 架構 Go 化」決策拆解為可執行階段。
*   先建立最小可運作骨架，避免一次性重寫整個框架卻無法啟動。
*   為後續 `check.md` 與 implementation 驗收提供明確依據。

### Plan Basis
本計畫目前遵守以下基礎決議：
*   **定位**：單一 CMS 核心框架，不處理多站共構。
*   **架構方向**：Go HTTP host + `chi` router + server-rendered HTML / JSON reaction 雙入口。
*   **資料存取**：保留主表、`_lang`、`_meta` 的分段寫入與 module-owned 邊界。
*   **初始資料**：Schema 轉換 + `init.sql` 核心配置植入，無歷史業務資料搬遷。
*   **資料庫**：預設 PostgreSQL，使用 `pgx` / `pgxpool`。
*   **認證授權**：沿用 `tbl_staff` 與 `tbl_role` 的既有權限模型。

### High-Risk Areas
*   **Feed 分段寫入的交易邊界**：若主表成功而 `_lang` / `_meta` 失敗，實體會破碎，因此必須先確立 PostgreSQL + `pgx` 的 transaction 封裝方式。
*   **動態欄位映射責任**：若 request DTO、domain model 與 `_meta` / `_lang` 切分不清，controller 很容易承擔過多資料拆解責任。
*   **權限生命週期與快取**：若每次請求都直接讀 DB 解析 role，權限 guard 會成為效能瓶頸。
*   **MySQL 到 PostgreSQL 的 bootstrap 差異**：既有 `document/sql/init.sql` 與日常 SQL 交付內容偏向 MySQL 語法，需明確區分 baseline 移植與 PostgreSQL 實際執行版本。

---

### Stage Plan (實作階段拆解)

#### Stage 0: 基礎設施與 Walking Skeleton
**目標**：建立開發環境與最小可運作骨架，打通「環境 ➔ DB ➔ 路由 ➔ HTML 輸出」最短路徑。
*   **Task 0.1: Docker 與本機啟動方式定案**
    *   建立 `docker-compose.yml` 與 Go service / PostgreSQL 容器定義。
    *   定義本機開發時的 build / run / reload 方式。
*   **Task 0.2: 專案結構初始化**
    *   建立 Go module 與最小目錄骨架，對齊 `src/public`、`src/app`、`src/conventions`、`src/infra`、`src/theme` 的責任邊界。
    *   固定第一版依賴集合為 `chi`、`html/template`、`scs`、`pgx`、`log/slog`。
*   **Task 0.3: Schema / Seed 執行流程**
    *   決定 Go 專案如何消費 `document/sql` 中的 schema 與 seed 素材，並轉為 PostgreSQL 可執行版本。
    *   建立第一版 DB 初始化入口，確保 `tbl_menu`、`tbl_option` 等基礎資料可被導入。
*   **Task 0.4: 第一個 outfit 路由驗證**
    *   建立首頁 handler 與對應 template。
    *   從 DB 讀取一筆 system option 並輸出到頁面，驗證 DB 與 SSR 路徑打通。
*   **[驗收點]**：啟動後可在瀏覽器看到帶 DB 資料的首頁，無 build 或連線錯誤。

#### Stage 1: Feed 層核心實作
**目標**：建立 Go 版 feed base，承接實體生命週期。
*   **Task 1.1: feed interface 與 metadata 定義**
    *   定義 feed 的最小介面與欄位分類方式。
    *   建立主表、`_lang`、`_meta` 的 mapping 規則。
*   **Task 1.2: 主表 CRUD 與 audit 欄位**
    *   實作主表 insert / update。
    *   善用 PostgreSQL `RETURNING` 取回主鍵與必要欄位，避免額外 round trip。
    *   統一處理 `insert_ts`、`last_ts`、`insert_user` 等欄位。
*   **Task 1.3: `_lang` / `_meta` 關聯寫入**
    *   實作語系與 meta 的保存流程。
    *   以 PostgreSQL `INSERT ... ON CONFLICT DO UPDATE` 處理 upsert。
    *   確保主表與關聯表寫入在同一 transaction 中完成。
*   **[驗收點]**：以整合測試驗證單一 payload 能正確分流並寫入三張表。

#### Stage 2: Reaction 與 Auth 層
**目標**：建立標準 reaction 入口與舊權限模型對應的 Go guard。
*   **Task 2.1: session / auth middleware**
    *   建立登入者身分解析與 permission 載入流程，session 預設以 `scs` 實作。
    *   規範未授權請求的回應格式。
*   **Task 2.2: 權限 guard**
    *   讓特定 reaction route 可宣告需要的 permission code。
    *   在進入 module-owned feed 前完成阻擋。
*   **Task 2.3: reaction handler 骨架**
    *   建立標準 JSON 回應格式。
    *   以 `chi` route / middleware 組裝 reaction 入口，串接 feed save 流程與錯誤處理。
*   **[驗收點]**：未授權請求會被正確拒絕，合法請求可完成 feed 寫入。

#### Stage 3: WorkflowEngine MVP
**目標**：移植 flow 定義與狀態 guard 為 Go 版工具層。
*   **Task 3.1: flow definition 載入**
    *   讀取並驗證 JSON flow 定義。
*   **Task 3.2: 狀態切換 guard**
    *   實作 `canTransit` 類型的狀態判定入口。
*   **Task 3.3: 模組自有 log 交易封裝**
    *   在合法 transition 下，將主表與 log 表寫入納入同一交易。
*   **[驗收點]**：非法狀態切換會中止流程且不留下半套資料。

#### Stage 4: Outfit / Theme 與後台選單
**目標**：以 seed data 建立可用的基本畫面框架。
*   **Task 4.1: 動態選單輸出**
    *   讀取 `tbl_menu` 並輸出後台導覽。
*   **Task 4.2: 系統選項載入**
    *   載入 `tbl_option` 並供 template 使用。
*   **[驗收點]**：畫面可正確顯示 `init.sql` 定義的選單與系統名稱。

---

### Entry / Exit Criteria for (done)
*   **Entry Criteria**：
    *   開發者已詳閱本 `plan.md` 與對應 `idea.md`。
    *   Docker、Go toolchain 與 PostgreSQL 開發環境已安裝就緒。
*   **Exit Criteria**：
    *   該 Stage 的程式碼已能通過對應驗收點。
    *   任何 SQL 或架構變更仍需維持 F3CMS 的小寫底線命名規範。
    *   若實作過程發現邊界漂移，必須同步更新 `history.md`。