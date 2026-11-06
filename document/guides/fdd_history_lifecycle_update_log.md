# FDD 更新日誌：History XML 與 Spec 永續化

## 更新目的
- 將 FDD 的承接檔由 `history.md` 統一為 `history.xml`，避免多輪承接時欄位漂移。
- 調整「封存」概念：spec 視為永續 artifact，只有刪除 spec 才算失去該 spec。
- 定義「階段性完工」行為：可在 `history.xml` 記錄「無下一步計畫」，而不是把 feature 視為封存結束。

## 問題背景
- 以 Markdown 自由格式記錄 history 時，常出現欄位遺漏、輪次格式不一致、承接資訊混雜。
- 「封存」語意容易被誤解為 feature 永久結束，造成後續恢復開發時承接判斷不一致。
- Sprint 在遇到「暫時沒有下一步」時缺少統一停/續規則，容易出現過度執行或錯誤停工。

## 本次調整

### 1) History 格式標準化（XML）
- 檔名統一為 `history.xml`。
- 結構統一為：
  - `<history>`
  - `<round index="...">`
  - 每輪最少欄位：`current_focus`、`ai_actions`、`next_steps`
- 不再使用 `history_round`，也不再使用 Markdown 小標題輪次格式。

### 2) Spec 生命週期規則調整
- spec 不採「封存即結束」模型。
- spec 在未刪除前，都可再次進入開發、驗收、優化。
- `(Optimization)` 保留為「穩定規則沉澱與共享文件同步」階段，不等於 spec 結束。

### 3) Sprint 對「無下一步計畫」的處置
- 若 `history.xml` 最新一輪標示「無下一步計畫」：
  1. 先重檢 `idea.md`、`plan.xml`、`check.xml`
  2. 若無需求漂移且無未完成需求/checklist：停止本輪 Sprint
  3. 若仍有未完成需求/checklist：在 `history.xml` 新增一輪，補上明確下一步後繼續 Sprint

## 優化方式與效益

### 一致性優化
- 透過固定 XML 欄位，降低輪次記錄自由發散造成的承接差異。
- 將 stage 判斷統一回到 `history.xml` 最新一輪，減少多檔互相覆蓋。

### 可驗證性優化
- XML 可用結構檢查快速驗證格式是否合法。
- 可為後續自動化（摘要、報表、提醒）提供穩定資料形狀。

### 流程控制優化
- Sprint 停止條件由「主觀感覺已完成」改為「無下一步計畫 + 三檔重檢」。
- 避免在需求仍有缺口時誤停，也避免在無漂移時無限續跑。

## 影響範圍（摘要）
- FDD 主規範：`document/flow.md`、`document/flow.llm.md`
- FDD skills：`fdd-focus`、`fdd-sprint`、`fdd-review`、`fdd-refactor`、`fdd-retrospective`、`fdd-commit`
- Prompt 與 guides：`document/spec/prompts.md` 與多份 guide 的 `history.md` 參照已改為 `history.xml`

## 後續建議
- 新增或更新 spec 時，先確認 `.current-spec.xml` 的 `history_path` 是否指向 `history.xml`。
- 每次 Sprint 結束前，檢查最新 round 是否有明確 `next_steps`，或明確標記「無下一步計畫」。
- 若需壓縮歷史，只新增新的摘要 round，不改寫既有 round。
