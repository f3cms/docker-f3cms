---
name: fdd-sprint
description: "Use when executing a task under Flow Driven Development with Docker-first validation, .env-based DB verification, document-first reading, and history-first feature continuation."
disable-model-invocation: true
argument-hint: "Describe the feature path and the concrete task to execute"
---
Execute the user's request under Flow Driven Development.

Before doing any work, apply these rules:

1. Treat [document/flow.llm.md](../../document/flow.llm.md) as the primary low-token execution contract for Flow Driven Development.
2. Treat [document/flow.md](../../document/flow.md) as the full engineer-oriented reference when more detail or rationale is needed.
3. Treat [copilot-instructions.md](../copilot-instructions.md) as the workspace-level always-on ruleset.
4. Treat [document/spec/.current-spec.xml](../../document/spec/.current-spec.xml) as the single source of truth for the current target spec.
5. If [document/spec/.current-spec.xml](../../document/spec/.current-spec.xml) is missing, unreadable, or does not point to a valid spec folder, stop immediately and tell the user to run the appropriate `FDD Focus` command first.
6. If the task involves F3CMS architecture, terminology, process, or feature continuation, treat the files under [document](../../document) as the primary source of truth instead of making generic framework assumptions.
7. After reading [document/spec/.current-spec.xml](../../document/spec/.current-spec.xml), read the resolved target spec's `history.xml` first, then use its `plan.xml` and `check.xml` to determine the next step. Do not restart from `idea.md` unless the documents show the earlier stages are incomplete.
8. Treat `history.xml` as structured XML with `<history><round index="...">`; each round should include `current_focus`, `ai_actions`, and `next_steps`.
9. If the task involves validation, smoke scripts, PHP script execution, workflow verification, or post-change runtime checks, prefer the project's existing Docker environment before local PHP.
10. If the task involves database verification, use the database connection credentials defined in `.env` as the default source of truth. Do not guess, hardcode, or substitute credentials when `.env` already provides the validation target.
11. Treat the spec as persistent: do not assume it is closed/archived by default. If the latest `history.xml` round indicates "無下一步計畫", recheck `idea.md`, `plan.xml`, and `check.xml` before deciding whether Sprint should stop or continue.

Required execution order:

1. First read [document/spec/.current-spec.xml](../../document/spec/.current-spec.xml).
2. If the pointer file is missing or invalid, stop immediately instead of guessing a spec.
3. State which files you need to read from the resolved target spec and which validation environment you will use.
4. Identify the current flow stage from the resolved `history.xml` before proposing or making changes.
5. If the latest `history.xml` round says "無下一步計畫", recheck `idea.md`, `plan.xml`, and `check.xml`:
   - If there is no requirement drift and no unfinished requirement/checklist, stop Sprint.
   - If there are unfinished requirements/checklists, add a new `history.xml` round with explicit next steps, then continue Sprint.
6. If the current stage is `(Optimization)`, immediately recheck `idea.md`, `plan.xml`, and `check.xml` to confirm there is no missing requirement, validation gap, or unclosed drift before treating the feature as complete.
7. If you detect drift between the resolved `history.xml`, `plan.xml`, `check.xml`, and current code, point it out before changing direction.
8. If you update `idea.md` at any point, remove any current `(Optimization)` wording immediately and restart the flow from the stage-consistency check, because the requirement set has changed and the prior optimization state no longer holds.
9. Keep the work to the smallest valid next step unless the user explicitly asks for a broader scope.
10. When validation is needed, prefer existing Docker compose services, container paths, smoke scripts, and existing verification routes.
11. After finishing, state whether the resolved target spec's `history.xml`, `plan.xml`, or `check.xml` should be updated.

Response expectations:

- Start by confirming which spec folder was resolved from [document/spec/.current-spec.xml](../../document/spec/.current-spec.xml).
- Then summarize the current stage and the concrete next step.
- If relevant, mention the Docker-based validation path you will use.
- If relevant, mention that database verification is based on `.env`.
- Do not skip directly to generic implementation if the document flow requires history-first or drift handling.

User task:

{{input}}