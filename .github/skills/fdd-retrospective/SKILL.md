---
name: fdd-retrospective
description: "Use when finishing a Flow Driven Development feature by syncing stable rules into glossary, guides, references, and optimization artifacts without reopening implementation scope."
disable-model-invocation: true
argument-hint: "Describe the feature path and the retrospective or documentation sync work"
---
Execute the user's request as Flow Driven Development `(Optimization)` work.

Before doing any work, apply these rules:

1. Treat [document/flow.llm.md](../../document/flow.llm.md) as the primary low-token optimization contract for Flow Driven Development.
2. Treat [document/flow.md](../../document/flow.md) as the full engineer-oriented reference when more detail or rationale is needed.
3. Treat [copilot-instructions.md](../copilot-instructions.md) as the workspace-level always-on ruleset.
4. Treat [document/spec/.current-spec.xml](../../document/spec/.current-spec.xml) as the single source of truth for the current target spec.
5. If [document/spec/.current-spec.xml](../../document/spec/.current-spec.xml) is missing, unreadable, or does not point to a valid spec folder, stop immediately and tell the user to run the appropriate `FDD Focus` command first.
6. Treat the files under [document](../../document) as the primary source of truth for F3CMS architecture, terminology, process, glossary, guides, and references.
7. After reading [document/spec/.current-spec.xml](../../document/spec/.current-spec.xml), read the resolved target spec's `history.xml` first, then use `plan.xml` and `check.xml` to confirm that the feature is actually ready for `(Optimization)`.
8. Treat `history.xml` as structured XML with `<history><round index="...">`; each round should include `current_focus`, `ai_actions`, and `next_steps`.
9. Do not reopen feature implementation scope during `(Optimization)` unless the documents show that a prerequisite for completion is still missing.
10. If validation is needed while closing out documentation, prefer the project's existing Docker-based verification routes.

Required execution order:

1. First read [document/spec/.current-spec.xml](../../document/spec/.current-spec.xml).
2. If the pointer file is missing or invalid, stop immediately instead of guessing a spec.
3. State which files you need to read from the resolved target spec.
4. Confirm whether the resolved target spec meets the minimum entry criteria for `(Optimization)`.
5. Identify which stable rules, terminology, or references should be backfilled into shared documents such as glossary, guides, references, sidebar, or `optimization.md`.
6. Keep the work focused on documentation sync, rule distillation, and archive preparation.
7. After finishing, state what archive or closeout gaps still remain, if any.

Response expectations:

- Start by confirming which spec folder was resolved from [document/spec/.current-spec.xml](../../document/spec/.current-spec.xml).
- Then state whether the target is ready for `(Optimization)`.
- Name the shared documents you plan to update and why.
- Avoid expanding scope back into feature implementation unless a completion prerequisite is demonstrably missing.
- After finishing, say whether `history.xml`, `check.xml`, or `optimization.md` should be updated further.

User retrospective task:

{{input}}