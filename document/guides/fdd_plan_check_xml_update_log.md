### FDD 更新日誌：plan 及 check 文件 XML 化

#### 更新目的
* 將 `check.md` 轉化為由 **Specification by Example (SBE)** 驅動的 `check.xml`，徹底解耦驗收狀態與確定性測試佐證，消弭 AI Agent 在驗收時的「虛假通過 (Verifier Theater)」。
* 將 `plan.md` 轉化為結構化 DAG (Directed Acyclic Graph) 執行的 `plan.xml`，明確階段任務、驗收點與 Fallback 策略，防止跳步執行。
* 將 `.current-spec.md` 指針檔升格為包含完整狀態與時間戳的 `.current-spec.xml`。
* 確立「**驗收分離與確定性佐證 (Evidence-Based Verification)**」原則，將原本散文式的 Markdown 驗收轉化為機器可精確執行的結構化驗收合約。

#### 問題背景
* **清單式驗收缺乏佐證 (Markdown Checklist Flaws)**：傳統 `check.md` 的勾選框 (`- [x]`) 缺乏強型別約束，LLM 易隨意勾選或寫入抽象文字（如「測試通過」），無法由靜態檢查器（Verifier）進行自動化驗證。
* **需求與驗收斷層**：`idea.md` 定義的主線/邊界情境無法被 `check.md` 強制繼承與比對，導致邊界情境與反例情境 (Boundary Scenarios) 在實作中常被默默漏測。
* **執行步驟缺乏架構約束**：`plan.md` 的自由文字難以被 Agent 狀態機解析為明確的依賴樹，容易引發跨階段跳步或過度重構。
* **全域指針資訊單一**：`.current-spec.md` 僅包含單一檔案路徑，缺少目前 Stage、Session ID 與更新時間，在 Session 重置或多會話切換時容易產生狀態判讀失真。

---

#### 本次調整

##### 1) `check.xml`：Specification by Example (SBE) 導向重構
* **核心標籤結構**：
  * 根節點改為 `<spec_acceptance_suite feature="..." current_stage="...">`。
  * 最小驗收單元由抽象 Task 升格為 `<scenario id="..." category="mainline|boundary" status="passed|failed|pending">`。
  * 每個情境強制寫明情境標題 `<title>` 與需求追溯鏈結 `<context_ref>`（如 `idea.md#boundary-scenario-1`）。
* **SBE 三段式與佐證標籤 (SBE & Evidence Spec)**：
  * **`<given>`**：前置條件與系統狀態。
  * **`<when>`**：觸發動作與 Input Payload。
  * **`<then>`**：預期結果與狀態轉移斷言。
  * **`<evidence>`**：確定性佐證節點，強制記錄 `<verification_command>` (Docker 執行指令)、`<exit_code>` (執行回傳值) 與 `<execution_hash>` (日誌/結果 Hash)。無合法佐證者嚴禁標註 `status="passed"`。
* **慣例評估與同步清單整合**：內嵌 `<refactor_assessment>`（框架慣例重構評估）與 `<document_sync_checklist>`（共用文件同步清單）。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<spec_acceptance_suite feature="UserAuth" current_stage="check">
    <metadata>
        <spec_pointer>document/spec/UserAuth</spec_pointer>
        <last_verified_at>2026-11-06T06:00:00Z</last_verified_at>
    </metadata>

    <scenarios>
        <scenario id="SCE-MAIN-001" category="mainline" status="passed">
            <title>使用者提供正確憑證成功登入並取得 JWT Token</title>
            <context_ref>idea.md#mainline-scenario-1</context_ref>
            <given><state>資料庫已有啟用使用者 alice@example.com</state></given>
            <when><action>POST /api/v1/auth/login</action></when>
            <then><expected_outcome>HTTP 200 並回傳 access_token</expected_outcome></then>
            <evidence>
                <verification_command>docker compose exec app php smoke_test.php --suite=AuthTest</verification_command>
                <exit_code>0</exit_code>
                <execution_hash>a7f8b9c0d1e2f3a4b5c6d7e8f9a0b1c2</execution_hash>
            </evidence>
        </scenario>
    </scenarios>

    <refactor_assessment>
        <convention_drift_detected>false</convention_drift_detected>
        <priority_tier>None</priority_tier>
        <action_required>none</action_required>
    </refactor_assessment>
</spec_acceptance_suite>
```

##### 2) `plan.xml`：DAG 導向結構化執行計劃
* **核心標籤結構**：
  * 以 `<spec_plan feature="...">` 為根節點。
  * 包含 `<stages>` 陣列，每個 Stage 標明 `<stage index="..." name="..." status="completed|in_progress|pending">`。
  * 每個子任務 `<task id="...">` 強制包含 `<acceptance>`（可執行驗收斷言）與 `<fallback>`（故障回退策略）。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<spec_plan feature="UserAuth">
    <stages>
        <stage index="1" name="Database Schema & Entity" status="completed">
            <task id="T-01">建立 User 實體與 Migration</task>
            <acceptance>docker compose exec app php artisan migrate:status 返回 0</acceptance>
            <fallback>回退至 Migration 執行前狀態</fallback>
        </stage>
    </stages>
</spec_plan>
```

##### 3) `.current-spec.xml`：全域動態指針
* 由單行文字路徑升格為結構化 XML 動態指標：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<current_spec_pointer>
    <target_spec_name>UserAuth</target_spec_name>
    <target_path>document/spec/UserAuth</target_path>
    <history_path>document/spec/UserAuth/history.xml</history_path>
    <last_updated_timestamp>2026-11-06T06:00:00Z</last_updated_timestamp>
</current_spec_pointer>
```

##### 4) `idea.md` 混合標籤與其他檔案權責劃分
* **`idea.md` (Hybrid)**：保持 Markdown 副檔名以確保 SA/SD/DBA 人類工程師的可讀性，但內部強制套用 `<scope>`, `<non_scope>`, `<mainline_scenario>`, `<boundary_scenario>` 等 XML 語意隔離標籤。
* **`optimization.md` (Markdown)**：維持純 Markdown 格式，僅在驗收完成後作為知識沉澱與對外文檔同步之載體。

---

#### 優化方式與效益

##### 一致性優化 (Specification Consistency)
* **SBE 端對端追溯 (Idea-to-Check Traceability)**：`check.xml` 的情境必須強制綁定 `idea.md` 錨點，搭配 **Boundary Non-Bypass Doctrine（邊界反例不漏測原則）**，確保主線與邊界情境 100% 被繼承與驗證。

##### 可驗證性優化 (Deterministic Verification Engineering)
* **確定性驗證機制 (Anti-Verifier Theater)**：外部驗證工具（如靜態檢查器 `fdd-cli doctor` 或 CI Script）可透過 XML Schema 與 Docker Log Hash 進行自動化比對，拒絕缺乏有效 `<evidence>` 的狀態變更寫入。

##### 流程控制優化 (Execution Machine & Stage Control)
* **狀態機導向執行**：Agent 透過 `.current-spec.xml` 與 `plan.xml` 準確讀取工作階段與依賴樹，消弭傳統 Markdown 中因模糊敘述導致的自由發散或跳步執行。

---

#### 影響範圍（摘要）
* **FDD 主規範檔**：`document/flow.md`、`document/flow.llm.md`（寫入 XML Schema 規範與 SBE 驗收合約）。
* **FDD Prompt 核心套件**：
  * `.github/prompts/fdd-sprint.prompt.md`
  * `.github/prompts/fdd-review.prompt.md`
  * `.github/prompts/fdd-focus.prompt.md`
  * `.github/prompts/fdd-retrospective.prompt.md`
* **工作區常駐規則**：`.github/copilot-instructions.md`（加入 XML 讀寫標籤約束與硬性佐證驗證規則）。
* **Spec 目錄契約**：`document/spec/<feature>/` 檔案目錄更迭為：`idea.md` (Hybrid)、`history.xml` (XML)、`plan.xml` (XML)、`check.xml` (SBE XML)、`optimization.md` (MD) 及全域 `.current-spec.xml`。

---

#### 後續建議
1. **更新 CLI 自動化驗證器 (`fdd-cli doctor`)**：新增 `check.xml` 與 `plan.xml` 的 Schema 語法檢查器，於落檔前驗證 `<evidence>` 與 `<exit_code>`。
2. **CI/CD 門禁整合**：在自動化管道中嵌入 Evidence Hash 比對，當 `<exit_code>` 非 0 或測試指令不符時，自動中斷 PR 合併。
3. **維持 `idea.md` 混合格式**：避免將 `idea.md` 完全 XML 化，保持人類工程師與 AI 在需求階段的溝通效率。
   
