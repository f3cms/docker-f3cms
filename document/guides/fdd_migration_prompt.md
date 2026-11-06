# FDD Migration Rewrite Prompt

## Purpose
- Provide a single-file prompt that can be pasted directly into an LLM after `./bin/port_fdd.sh` copies the FDD bundle into a new repository.
- Help the receiving project rewrite only the project-bound rules from migration steps 1 to 3.
- Avoid expanding the first migration pass into real feature work, spec creation, or prompt-contract validation.

## When To Use
- Use this immediately after the FDD bundle has been copied into a new repository.
- Use this after reading [fdd_porting_guide.md](fdd_porting_guide.md) when you want an execution prompt instead of a narrative guide.
- Use this before creating the first real feature folder under `document/spec/<FeatureName>/`.

## Non-Scope
- creating the first real feature folder
- validating `FDD Focus` / `FDD Sprint` / `FDD Review` behavior in the new project
- implementing any feature work in the receiving repository

## Direct Prompt

```text
請執行 FDD 新專案 migration 的第一輪改寫，只做第 1 到第 3 步。

先讀：
1. document/guides/fdd_porting_guide.md
2. document/guides/fdd_migration_checklist.md

目標：
- 改寫 .github/copilot-instructions.md 的 project-bound rules
- 改寫 .github/prompts/fdd-focus.prompt.md
- 改寫 .github/prompts/fdd-sprint.prompt.md
- 改寫 .github/prompts/fdd-review.prompt.md
- 改寫 .github/prompts/fdd-retrospective.prompt.md
- 改寫 .github/prompts/fdd-flow-llm-align.prompt.md
- 明確列出哪些 FDD 核心檔案保留原樣

限制：
- 不要建立第一個真實 spec folder
- 不要執行 prompt contract 驗證
- 不要進入任何 feature implementation
- 保留 FDD 的 stage chain、history-first continuation、drift handling、artifact ownership
- 只替換 project-bound assumptions，例如驗證環境、資料庫 source of truth、docs root、專案術語、架構名詞

執行順序：
1. 先列出你讀了哪些 migration 文件
2. 列出準備改寫的 project-bound files
3. 說明哪些核心 FDD files 預計保留不改
4. 直接完成第 1 到第 3 步的檔案改寫
5. 最後回報已改寫檔案、保留檔案、以及仍待人工補充的專案資訊

改寫要求：
- 優先逐檔改 .github/copilot-instructions.md 與 .github/prompts/fdd-*.prompt.md
- 保留 FDD 的流程骨架，不要把 prompt structure 重寫成另一套 workflow
- 若新專案資訊不足，先列出缺少的環境/術語/文件根目錄資訊，再做最小安全改寫
- 若 copied bundle 仍殘留來源專案名詞、路徑或驗證方式，必須主動清掉，不可假設之後再補

最後輸出必須包含：
- 已改寫的 project-bound files
- 明確保留不改的核心 FDD files
- 仍待人工補充的專案資訊
```

## Related Documents
- [fdd_porting_guide.md](fdd_porting_guide.md)
- [fdd_migration_checklist.md](fdd_migration_checklist.md)
- [../spec/prompts.md](../spec/prompts.md)