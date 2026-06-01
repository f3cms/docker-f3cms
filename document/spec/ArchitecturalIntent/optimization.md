# ArchitecturalIntent Optimization

## Purpose
- 收斂 ArchitecturalIntent 已穩定的共享規則、術語與封存前整理結果。
- 讓後續 handoff 不必再從各輪 `history.md` 逆向整理哪些規則已足夠穩定，可以回寫到 `document/`。
- 記錄目前仍保留的已知風險，避免封存時把「註解 rollout 已完成」誤讀成「所有 editor-level 檢查完全零殘留」。

## Optimization Entry Check
- `history.md`、`plan.md`、`check.md` 已表明主要註解 rollout 與承接同步完成。
- `check.md` 已確認 Stage 1 到 Stage 4 的主線完成，且目前下一步不再是 implementation，而是 closeout/封存前整理。
- 本輪沒有重開新的 module target implementation scope。

## Shared Rules Backfilled

### Updated Shared Documents
- [document/guides/sd_conventions.md](../guides/sd_conventions.md)
  - 回寫 module-owned boundary summaries，將 module `Feed`、`Reaction`、`Outfit`、`Kit` 在註解中應保護的 owner boundary 與 red line 固化到共享 guide。
- [document/glossary.md](../glossary.md)
  - 新增 `Architectural Intent Comment`、`Owner-side Business Bridge`、`Page-shaping Boundary` 三個穩定詞彙，降低後續文件與 PR review 的用字漂移。

### Stable Distilled Rules
- 架構性註解的共享 comment contract 以四段式 class comment 為主：`Architecture Purpose`、`Design Intent`、`Strict Constraints`、`Porting Guidelines`。
- 納入範圍的函式必須有函式層級註解覆蓋，不能只留 class-level 註解或舊式 `@param` / `@return`。
- `Feed` 註解應保護 entity lifecycle、publish/status、workflow trace、relation writeback、tree/rule ownership 等 module-owned persistence boundary。
- `Reaction` 註解應保護 request/orchestration boundary，不可回收 persistence ownership。
- `Outfit` 註解應保護 page-shaping / render / cache / SEO boundary，不可變成主要寫入路徑。
- `Kit` 註解應保護 owner-side rule、validation、OAuth/session bridge、AI intent shaping、ad-slot shaping 等 module-owned reusable helper boundary，不可膨脹成 generic shared service。

## Completed Scope Summary
- shared `libs` base 與高風險 shared runtime surface 已完成架構註解 rollout
- selected module feed targets 已完成架構註解 rollout
- selected module reaction targets 已完成架構註解 rollout
- selected module outfit targets 已完成架構註解 rollout
- selected module kit targets 已完成架構註解 rollout

## Residual Risks
- [www/f3cms/modules/Press/outfit.php](../../www/f3cms/modules/Press/outfit.php) 仍有既有 editor-level 符號解析問題，包含 `safeCount()`、`kPress::fartherData()`、`kHistory`。這些不是本 spec 的註解變更引入，但在封存前應持續視為已知殘留風險。
- 若未來再追加新的 module target，必須先更新 `plan.md` / `check.md` 承接點，再重新進入 `(done)` 或 `check`，不可直接在已 closeout 的狀態下偷渡 scope 擴張。

## Archive Readiness
- 以目前完成範圍來看，這個 spec 已具備 archive-ready 的文件條件。
- 若團隊後續不再擴張新的 target scope，可將本 spec 視為已完成當前一輪 closeout。
- 若未來要續做新的 target，沿用本 spec 亦可，但應在 `history.md` 明確記錄 reopen 的 target scope 與原因。