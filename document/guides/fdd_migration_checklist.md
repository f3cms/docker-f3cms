# FDD New-Project Migration Checklist

## Purpose
- Provide a file-by-file checklist for the first migration pass after running `./bin/port_fdd.sh`.
- Help the receiving project's LLM or engineer rewrite only the project-bound rules before real feature work begins.
- Keep the migration focused on steps 1 to 3 only: rewrite workspace rules, rewrite prompts, and confirm what can stay unchanged.

## Primary Readers
- Engineers who just copied the FDD bundle into a new repository
- LLMs asked to adapt the copied bundle to the receiving project
- Tech leads reviewing whether the first migration pass is actually complete

## Scope
- `.github/copilot-instructions.md` rewrite pass
- `.github/prompts/fdd-*.prompt.md` rewrite pass
- confirmation of which FDD files can remain unchanged
- file-by-file replacement checklist for project-bound assumptions

## Non-Scope
- creating the first real feature folder under `document/spec/<FeatureName>/`
- validating the migrated prompt contract with `FDD Focus` / `FDD Sprint` / `FDD Review`
- pilot-feature execution after the migration

## When To Use
- Use this immediately after `./bin/port_fdd.sh <target-directory>` completes.
- Use this before creating the first real spec folder in the new project.
- Use this when the copied FDD bundle still contains source-project nouns, validation paths, or environment assumptions.

## Inputs
- [fdd_porting_guide.md](fdd_porting_guide.md)
- [../flow.md](../flow.md)
- [../flow.llm.md](../flow.llm.md)
- [../../.github/copilot-instructions.md](../../.github/copilot-instructions.md)

## How To Use This Checklist
- Work top to bottom.
- Do not rewrite `flow.md` or `flow.llm.md` during this pass unless the receiving project truly needs a different stage model.
- Mark each item only after the file wording matches the receiving project's actual runtime, terminology, and doc layout.

## Step 1: Rewrite Workspace Rules

### Target File
- [../../.github/copilot-instructions.md](../../.github/copilot-instructions.md)

### 1A. Validation Environment Rules
- [ ] Replace Docker-specific wording if the receiving project does not use Docker as the primary validation baseline.
- [ ] Replace source-project runtime wording such as PHP execution, container paths, or smoke-script assumptions with the receiving project's real build/test/verify commands.
- [ ] Replace host-vs-container precedence rules if the receiving project uses a different source of truth, such as CI, devcontainer, or host-only tooling.

### 1B. Database Verification Rules
- [ ] Confirm whether `.env` is still the canonical database source of truth.
- [ ] If not, replace every `.env`-specific rule with the receiving project's actual config source, such as `appsettings.*`, `config/*.yaml`, secret manager, or deployment config.
- [ ] Ensure the rewritten rule still preserves one canonical DB verification source rather than leaving the LLM to guess.

### 1C. Project Terminology Rules
- [ ] Replace source-project nouns such as `F3CMS`, `OntoCMS`, `module`, `feed`, `reaction`, `outfit`, and `kit` when those are not the receiving project's real architecture terms.
- [ ] Point the LLM to the receiving project's actual architecture vocabulary source.
- [ ] Remove any source-project examples that would cause the LLM to produce stale folder names or stale class names in the new repo.

### 1D. Document Source-of-Truth Rules
- [ ] Confirm whether architecture/process truth still lives under `document/`.
- [ ] If not, replace every path-level rule so the LLM reads from the receiving project's actual docs root, such as `docs/`, `architecture/`, or `spec/`.
- [ ] Confirm the instructions still tell the LLM where feature specs, operational guides, and shared architecture references live.

### Step 1 Exit Criteria
- [ ] `.github/copilot-instructions.md` no longer contains stale validation paths, runtime assumptions, or architecture nouns from the source project.
- [ ] The file still preserves the history-first FDD behavior and explicit artifact-update bias.

## Step 2: Rewrite FDD Prompt Entry Points

### Target Files
- [../../.github/prompts/fdd-focus.prompt.md](../../.github/prompts/fdd-focus.prompt.md)
- [../../.github/prompts/fdd-sprint.prompt.md](../../.github/prompts/fdd-sprint.prompt.md)
- [../../.github/prompts/fdd-review.prompt.md](../../.github/prompts/fdd-review.prompt.md)
- [../../.github/prompts/fdd-retrospective.prompt.md](../../.github/prompts/fdd-retrospective.prompt.md)
- [../../.github/prompts/fdd-flow-llm-align.prompt.md](../../.github/prompts/fdd-flow-llm-align.prompt.md)

### 2A. Doc Root and Spec Resolution Rules
- [ ] Replace any stale `document/` wording if the receiving project uses a different docs root.
- [ ] Keep `.current-spec.md` pointer resolution intact unless the receiving project intentionally changes the spec-pointer contract.
- [ ] Keep the rule that `history.md` is read before `plan.md` and `check.md`.

### 2B. Validation Environment Wording
- [ ] Replace source-project validation instructions such as Docker compose services, PHP commands, route checks, or smoke script paths.
- [ ] Ensure each prompt names the receiving project's actual preferred validation environment.
- [ ] Remove wording that would make the LLM choose the wrong runtime just because it was copied from the source repo.

### 2C. Database Verification Wording
- [ ] Replace `.env`-specific database wording when the receiving project uses a different canonical config source.
- [ ] Keep the higher-level rule shape: the LLM must use one declared source of truth and must not guess credentials.

### 2D. Architecture Vocabulary Wording
- [ ] Replace source-project nouns and examples in each prompt so they match the receiving project's actual architecture terms.
- [ ] Remove prompt wording that would make the LLM talk about `feed`, `reaction`, `outfit`, or `kit` when the target project uses different layers.
- [ ] Keep the FDD execution order and drift-handling logic unchanged unless the receiving project intentionally changes the workflow.

### Step 2 Exit Criteria
- [ ] All FDD prompts now reference the receiving project's real docs root, validation environment, and architecture vocabulary.
- [ ] None of the prompts still rely on source-project-only assumptions to decide stage, validation, or artifact updates.

## Step 3: Confirm What Can Stay Unchanged

### Files That Usually Stay As-Is
- [ ] [../flow.md](../flow.md) is still acceptable as the full process definition.
- [ ] [../flow.llm.md](../flow.llm.md) is still acceptable as the low-token execution contract.
- [ ] `history.md`-first continuation still matches how the receiving project wants FDD to behave.
- [ ] `.current-spec.md` pointer resolution still matches how the receiving project wants feature context resolved.
- [ ] `idea.md` / `history.md` / `plan.md` / `check.md` / `optimization.md` artifact ownership still fits the receiving project.

### Things To Explicitly Not Rewrite In This Pass
- [ ] Do not rewrite stage names just because the project language changed.
- [ ] Do not redesign FDD entry/exit criteria unless the receiving project has a real workflow conflict.
- [ ] Do not expand this pass into feature work, prompt validation, or pilot implementation.

### Step 3 Exit Criteria
- [ ] The team has a clear list of which copied files remain authoritative without local rewriting.
- [ ] The team has a clear list of which files were project-bound and have now been rewritten.

## Output Of This First Migration Pass
- [ ] Workspace rules are aligned to the receiving project.
- [ ] Prompt entry points are aligned to the receiving project.
- [ ] The receiving project knows which core FDD files stayed unchanged.

## Related Documents
- [fdd_porting_guide.md](fdd_porting_guide.md)
- [../flow.md](../flow.md)
- [../flow.llm.md](../flow.llm.md)