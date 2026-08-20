# OntoCMS (Go 版) 核心框架 - idea.md

### 1. 背景與問題定義 (Problem Statement)
舊有基於 PHP 開發的 F3CMS 系統具備優異的「以實體為優先 (Entity-First)」與「Hierarchical FORK」分層架構，但目前仍受限於弱型別、長期維運成本與 runtime 邊界不夠清晰等問題。
我們需要將系統升級為全新的 OntoCMS (Go 版)。新框架必須保留原有的實體優先、模組擁有邊界與表分解原則（主表、`_lang`、`_meta`），同時改以 Go 建立更直接、較低框架耦合、便於部署與維運的單一 CMS 基礎框架，並以 PostgreSQL 作為預設資料庫。

### 2. 目標結果 (Target Outcome)
建置一套基於 Go 的 OntoCMS 核心框架，保留 Feed、Outfit、Reaction、Kit 的責任分層與 module-owned 邊界。Web 層採用 `chi` 為薄路由核心，搭配標準庫 `html/template` 提供 SSR，資料層以 `pgx` 直連 PostgreSQL。系統上線時採 Zero Business Data 策略，不搬遷歷史業務資料，但需保留 Schema 轉換與 `init.sql` 的基礎系統資料植入能力，讓新系統可以在乾淨資料庫上完成初始化。

### 3. 範圍 (Scope)
*   **底層架構映射 (Architecture Mapping)**：實作以 Go 為核心的 HTTP host，使用 `chi` 維持薄的 public 入口與明確 middleware 鏈，提供 SSR/HTML 輸出能力，同時保留 JSON reaction 入口。
*   **實體資料生命週期 (Entity Feed Layer)**：實作 Go 版 feed base，承接主表、`_lang`、`_meta` 的分段讀寫與交易邊界。
*   **認證授權 (Identity & Auth)**：沿用舊有 `tbl_staff` 與 `tbl_role` 的資料模型，建立 Go 版的 session / claim / permission guard。
*   **工作流引擎 (WorkflowEngine MVP)**：保留讀取 JSON flow 定義與狀態切換 guard 的能力，並維持 log 由各模組自有資料表承接。
*   **Schema 轉換與基礎植入 (Migration & Seeding)**：沿用 `document/sql` 作為 schema 與 seed 的素材來源，將既有 MySQL 基底轉換為 PostgreSQL 版 schema / seed，並建立 Go 專案可執行的初始化與 migration 流程。

### 4. 非範圍 (Non-Scope)
*   **多站共構機制 (Multi-Site)**：本階段仍只處理單站 CMS 核心，不實作 PetiteCMS 類型的多站治理能力。
*   **重量級框架綁定**：不引入需要高度框架慣例綁定的巨大套件組合，避免把 module-owned 邏輯推進框架魔術。
*   **前端 SPA 重寫**：本階段不以 SPA 為主要目標，優先保留 server-rendered 與薄互動頁面能力。

### 5. 核心物件與模組邊界 (Core Objects & Module Boundaries)
系統嚴格遵守 OntoCMS 的核心規範「一個實體對應一個模組」：
*   **`Staff / Role` (治理模組)**：管理 CMS 後台帳號、授權與 session 狀態。
*   **`Feed` (資料生命週期核心類別)**：所有業務模組資料操作根基，負責主表、`_lang` 與 `_meta` 的切分與持久化。
*   **`Menu / Option` (配置模組)**：維持後台導覽與全域設定。
*   **`WorkflowEngine` (工具模組)**：作為無狀態規則引擎，讀取 flow 定義進行狀態判定，但不反向侵入模組資料邊界。

### 6. 角色與參與者 (Actors and Roles)
*   **系統管理員 (System Admin)**：具備 CMS 後台管理權限，可維護內容、選單與設定。
*   **一般使用者 (End User)**：透過瀏覽器存取網站前台，由 outfit/theme 層渲染對應頁面。

### 7. 資料與狀態影響 (Data and State Implications)
*   **Schema 命名不變性**：維持原有 `tbl_` 前綴與小寫底線命名慣例。
*   **稽核欄位一致性**：所有寫入仍需統一維護 `insert_ts`、`last_ts`、`insert_user` 等稽核欄位。
*   **啟動依賴 (Bootstrap Dependency)**：系統初始啟動仍依賴 `init.sql` 導入的 `tbl_menu` 與 `tbl_option` 等基礎資料。

### 8. 限制與依賴 (Constraints and Dependencies)
*   **基礎設施**：需運行於支援 Go toolchain 的容器或主機，並連線到 PostgreSQL。
*   **動態欄位與強邊界設計**：Go 層必須在 request DTO、domain model 與 `_lang` / `_meta` 動態欄位之間維持清楚分流，避免 controller 直接承擔資料拆解責任。

### 9. 風險與業務決策 (Risks and Key Decisions)
*   *(已決議)* **命名與精神**：定名為 OntoCMS，強調實體優先與模組擁有邊界。
*   *(已決議)* **目標定位**：單站 CMS 核心框架，不承擔多站共構。
*   *(已決議)* **Go web stack**：採用 `chi + html/template + scs` 的薄堆疊，不引入重量級全包式 framework。
*   *(已決議)* **資料庫選型**：Go 版預設採用 PostgreSQL，Go driver 使用 `pgx` 與 `pgxpool`。
*   *(待確認)* **migration 與 query 生成工具**：`goose` / `atlas` 與 `sqlc` 的組合需在第一輪實作前定案。

### 10. 實例化規格與架構流轉 (Specification by Example & Scenarios)

**【情境一】Go 版 OntoCMS 的實體分段寫入 (Entity-First Save Lifecycle)**
*說明：驗證 Go 版 feed base 是否能承接 F3CMS 時代 `_afterSave` 的關聯寫入邏輯，並維持交易一致性。*
*   **Given (假設)** reaction 層收到一筆包含主檔資料與多語系 title 的更新請求。
*   **When (當)** request 完成 DTO 驗證後，呼叫 post feed 的 save 流程。
*   **Then (那麼)** feed 應先寫入 `tbl_post` 主表。
*   **And (並且)** 同一交易內繼續寫入 `tbl_post_lang` 與 `tbl_post_meta`，避免實體破碎。

**【情境二】沿用舊有角色表的權限攔截**
*說明：驗證系統能否基於 `tbl_role` 的授權結構，在 Go HTTP handler 進入模組邏輯前先阻擋未授權操作。*
*   **Given (假設)** 某帳號不具備 `Post` 模組的更新權限。
*   **When (當)** 該帳號呼叫 post update 的 reaction 路由。
*   **Then (那麼)** 權限 guard 應在進入 feed 前直接拒絕請求。
*   **And (並且)** 系統回傳對應的 forbidden 結果，確保未授權操作無法觸及資料寫入。

### 11. 建議技術堆疊 (Recommended Stack)
*   **Router / Middleware**：`chi`
*   **SSR Template**：Go 標準庫 `html/template`
*   **Session**：`alexedwards/scs/v2`
*   **Database Driver / Pool**：`pgx/v5`、`pgxpool`
*   **Migration**：`goose` 或 `atlas`
*   **Logging**：Go 標準庫 `log/slog`
*   **Query Strategy**：以 raw SQL 為主，必要時搭配 `sqlc` 產生 strongly typed query bindings