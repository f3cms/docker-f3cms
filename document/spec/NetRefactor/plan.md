
# OntoCMS (.NET 版) 核心框架 - plan.md (v1 實踐計畫)

### Purpose
*   將 `idea.md` (v3) 中確認的「實體優先 (Entity-First)」與「FORK 架構 .NET 現代化」決策，拆解為可執行的階段 (Stages) 與子任務。
*   控制第一版重構範圍，確保系統從最小可運作骨架 (Walking Skeleton) 穩步生長，避免陷入「一次性重寫整個框架卻無法編譯」的風險。
*   為後續的 `(done)` 與 `check.md` 驗收提供明確依據。

### Plan Basis
本計畫嚴格遵守 `idea.md` (v3) 的以下決議：
*   **定位**：單一 CMS 核心框架，不處理多站共構 (PetiteCMS) 邏輯。
*   **架構**：ASP.NET Core 8/9 + MSSQL，採用 Server-Side Rendering (SSR) Razor Pages。
*   **資料存取**：使用 Dapper，嚴格實作主表、`_lang`、`_meta` 的分段寫入，禁用全自動 ORM Tracking 魔術。
*   **初始資料**：Schema 轉換 + `init.sql` 核心配置植入 (Seeding)，無歷史業務資料搬遷。
*   **認證授權**：沿用 `tbl_staff` 與 `tbl_role` 的 Claim-based Authorization。

### High-Risk Areas
*   **Feed 分段寫入的交易邊界 (Transaction)**：若主表寫入成功但 `_lang` 寫入失敗，會導致實體破碎。必須在 `BaseFeedRepository` 中嚴格控制 Dapper 的 `SqlTransaction`。
*   **DTO 與 Schema 欄位映射**：C# 為強型別，若 Request JSON 解析時未能與動態的 `_meta` 或 `_lang` 欄位乾淨脫鉤，容易造成 `Reaction` 層充滿髒 code。
*   **權限攔截的生命週期**：若 Authorization Middleware 讀取資料庫的頻率過高，將成為效能瓶頸，必須妥善設計 Claims 快取 (Cache) 策略。

---

### Stage Plan (實作階段拆解)

#### Stage 0: 基礎設施與 Walking Skeleton (環境建置)
**目標**：建立本機開發環境與空框架，打通「環境 ➔ DB ➔ 路由 ➔ Hello World 畫面」的最短路徑。
*   **Task 0.1: Docker 環境搭建**
    *   撰寫 `docker-compose.yml`，包含 `.NET 8/9 Web` 容器與 `MSSQL` 容器。
    *   設定本機 Port 映射與 Volume 掛載。
*   **Task 0.2: 專案結構初始化**
    *   建立 ASP.NET Core MVC 專案，依照 F3CMS 規範建立 `Libs/`、`Modules/`、`Theme/` 資料夾。
    *   安裝核心 NuGet 套件：`Dapper`、`Microsoft.Data.SqlClient`。
*   **Task 0.3: 資料庫 Schema 轉換與 Seeding**
    *   撰寫 `Schema.sql`，將舊有 MySQL 型別轉換為 MSSQL (如 `DATETIME2`, `NVARCHAR(MAX)`)。
    *   撰寫 `Seed.sql`，將舊有 `init.sql` 中的 `tbl_menu`、`tbl_option`、`tbl_role`、預設 `tbl_staff` 匯入。
    *   於 `Program.cs` 實作啟動時自動檢查並執行 Schema/Seed 的機制。
*   **Task 0.4: 第一個 Outfit 路由驗證**
    *   建立基礎 `HomeController` (Outfit 層) 與對應的 Razor View。
    *   從 MSSQL 讀取一筆 `tbl_option` 系統名稱並渲染於網頁上，驗證連線與 SSR 正常。
*   **[驗收點]**：執行 `docker-compose up` 後，瀏覽器能正確渲染帶有 DB 資料的 Hello World 頁面，無編譯或連線錯誤。

#### Stage 1: 實體資料生命週期 (Feed 層核心實作)
**目標**：封裝 Dapper，實作 OntoCMS 靈魂的 `BaseFeedRepository<T>`。
*   **Task 1.1: 介面與常數定義**
    *   定義 `IFeedRepository` 介面。
    *   實作 C# 版的 `MTB` (主表)、`MULTILANG` 屬性標記 (Attributes)。
*   **Task 1.2: _handleColumn 與主表 CRUD**
    *   實作 Dapper 對主表 (Main Table) 的動態 Insert/Update 語法生成。
    *   實作自動寫入 Audit Fields (`insert_ts`, `last_ts`, `insert_user`) 的邏輯。
*   **Task 1.3: 多語系與中繼資料關聯寫入 (_afterSave)**
    *   實作 `saveLang()`：利用 MSSQL 的 `MERGE INTO` 處理 `_lang` 表的 Upsert。
    *   實作 `saveMeta()`：處理 `_meta` 表的鍵值對寫入。
    *   確保 Task 1.2 與 1.3 包裝在同一個 `DbTransaction` 內。
*   **[驗收點]**：撰寫整合測試 (Integration Test)，傳入一份包含 title (`_lang`) 與 seo_desc (`_meta`) 的 Payload，驗證 Dapper 能正確分流並寫入三張表。

#### Stage 2: 互動與權限治理 (Reaction & Auth 層)
**目標**：基於舊表建立 C# 權限攔截網，並實作標準的 API 回應層。
*   **Task 2.1: Claim-based Auth 中介軟體**
    *   實作自訂的 `AuthenticationHandler`。
    *   讀取登入者的 `tbl_staff` 狀態與 `tbl_role` 權限代碼，轉化為 `.NET Claims`。
*   **Task 2.2: 權限常數與攔截器 (Action Filters)**
    *   實作 `[OntoAuthorize(PV_U)]` 等屬性標記，能在進入 Controller 前依據 Claims 拒絕越權存取 (回傳 403)。
*   **Task 2.3: Reaction API 控制器骨架**
    *   建立標準的 JSON 回應格式 (`{ status, data, error }`)。
    *   實作如 `rPost` 的 Controller，負責接收 Request、呼叫 Task 1 完成的 `Feed`，並回傳結果。
*   **[驗收點]**：未帶憑證或權限不足的請求呼叫 `Reaction` API 時，會被 Middleware 正確攔截；合法請求能正確觸發 `Feed` 寫入。

#### Stage 3: WorkflowEngine MVP (Kit 工具層)
**目標**：將狀態機與防禦邏輯移植為無狀態的 C# 領域服務 (Domain Service)。
*   **Task 3.1: JSON Definition 載入與驗證**
    *   於 `Libs/` 實作 `WorkflowEngine` 類別，能反序列化並驗證目標流程 JSON (如 `flow.json`)。
*   **Task 3.2: 狀態防護與權限判定 (Guard)**
    *   實作 `canTransit(actionCode, runtimeContext)`，檢查當前使用者 Role 是否符合，及狀態轉換是否合法。
*   **Task 3.3: 模組專屬 Log (Module-owned Log) 交易封裝**
    *   在 `Reaction` 層實作呼叫範例：先由 Engine 判定合法，接著開啟 Transaction 寫入業務主表 (`tbl_post`) 與狀態軌跡表 (`tbl_post_log`)，最後 Commit。
*   **[驗收點]**：當嘗試執行 JSON 規範外的狀態切換 (如 Draft ➔ Offlined) 時，Engine 會拋出錯誤並中止資料庫 Transaction。

#### Stage 4: 頁面渲染與後台選單 (Outfit 層)
**目標**：結合 Seed Data 產出動態生成的後台/前台框架。
*   **Task 4.1: 動態選單渲染**
    *   在 `Outfit` (Razor View Component 或 ViewComponent) 讀取 `tbl_menu` 的資料，遞迴渲染出後台左側導覽列。
*   **Task 4.2: 多語系與系統選項載入**
    *   讀取 `tbl_option` 載入全站共用變數 (如網站名稱、Logo 路徑)。
*   **[驗收點]**：啟動站臺後，Razor SSR 畫面能正確顯示 `init.sql` 中定義的選單與系統名稱。

---

### Entry / Exit Criteria for (done)
*   **Entry Criteria (開始實作前提)**：
    *   開發者已詳閱本 `plan.md` 與對應的 `idea.md` (v3)。
    *   Docker Desktop 與 .NET 8/9 SDK 已安裝就緒。
*   **Exit Criteria (宣告階段完成標準)**：
    *   該 Stage 的程式碼已提交 (Commit)，並通過上述的 **[驗收點]**。
    *   產生對應的 SQL 或架構變更時，必須維持 F3CMS 的小寫底線 (`tbl_`) 命名規範。
    *   若實作過程中發現架構或邊界漂移 (Drift)，已同步更新 `history.md`。

