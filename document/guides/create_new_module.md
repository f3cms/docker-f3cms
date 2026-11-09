# F3CMS Create New Module Guide

## Purpose
- Provide the practical execution path for creating a new module after the design has already been validated.
- Translate entity, schema, and layer decisions into concrete files and SQL.
- Keep new module implementation consistent with the newer guide system.

## Primary Readers
- SD
- Backend programmers
- LLMs generating module scaffolds after design is confirmed

## Scope
- preconditions before module creation
- new module decision sequence
- schema scaffolding
- Feed, Reaction, Outfit, and Kit scaffolding
- implementation handoff from design to code

## LLM Reading Contract
- Do not use this file as the first source for deciding whether a new module should exist.
- Use this guide only after entity boundary, schema shape, and naming direction are already clear.
- When this file overlaps with design rules, prefer data_modeling.md, module_design.md, and sd_conventions.md.

## Inputs
- [index.md](index.md)
- [data_modeling.md](data_modeling.md)
- [module_design.md](module_design.md)
- [feed_guide.md](feed_guide.md)
- [sd_conventions.md](sd_conventions.md)
- [data_architecture_checklist.md](data_architecture_checklist.md)

## Core Thesis
- A new module should be created only after the entity is clear.
- This guide is an execution guide, not an architecture arbitration guide.
- The correct order is: identify entity, confirm module boundary, shape schema, then generate module files.

## When to Use This Guide
- the business object has been identified as a stable entity
- the decision to create a new module has already been justified
- the main table and supporting tables are conceptually clear
- naming is expected to follow normal F3CMS conventions

Do not use this guide when the real question is still one of the following:
- is this actually a new entity
- should this extend an existing module instead
- should this field live in main, `_lang`, `_meta`, or a relation table

For those earlier decisions, read:
- [module_design.md](module_design.md)
- [data_modeling.md](data_modeling.md)
- [sd_conventions.md](sd_conventions.md)

## Recommended Decision Order Before Writing Code
Follow this order before creating files.

### Step 0: Confirm That a New Module Is Justified
Ask:
- can the business object be named independently
- does it have its own lifecycle or status
- does it need its own main table
- does it need separate backend actions or list behavior

If the answers are weak or mixed, stop here and return to [module_design.md](module_design.md).

### Step 1: Identify the Entity Contract

Write down the minimum stable definition of the entity:
- entity name
- purpose
- ownership
- status model
- key relations
- whether it is multilingual
- whether it has optional metadata

This step prevents the common mistake of generating files before the entity model is stable.

### Step 2: Shape the Schema

Decide:
- main table fields
- `_lang` table fields if multilingual
- `_meta` usage if optional extension attributes exist
- relation tables if the entity links to other entities

Use [data_architecture_checklist.md](data_architecture_checklist.md) before moving on.

### Step 3: Define Layer Responsibilities

Decide what the module actually needs:
- Feed is required for entity data lifecycle
- Reaction is required when backend interaction or JSON actions exist
- Outfit is required when page rendering or frontend routing behavior exists
- Kit is required when module-owned validation or reusable helper rules exist, including rules that other modules may call through this module boundary

Not every module needs all four files immediately, but the naming model remains the same.

### Step 3.5: Check Parent Extension Points Before Overriding

Before writing or overriding module methods, always check whether the parent class already provides a suitable extension point.

Required rule:
- first use a parent extension point when it fits
- only override parent CRUD/action methods when no suitable extension point exists

Practical order:
1. Read parent class hooks/seams for the target layer (`Reaction`, `Feed`, `Outfit`, `Kit`).
2. Confirm whether the requirement can be completed through those hooks.
3. Override parent methods only when step 2 is not sufficient, and document why.

This protects owner boundaries and avoids duplicate flow logic such as reimplementing shared `do_save`/`do_list` paths without necessity.

### Step 4: Only Then Generate the Module Skeleton

At this point the practical implementation work begins.

## Running Example
This guide uses `Draft` as an example module.

Example requirement:
- create a `Draft` entity to store LLM-generated working drafts
- track ownership, status, language, method, input intent, guideline, and generated content
- support later retrieval and management as an independent business object

This is a reasonable module example because `Draft` is not just one page field bundle. It has its own identity, lifecycle, and persistence boundary.

## Step 1: Describe the Entity Before SQL

Before writing SQL, describe the intended entity shape in a compact structured form.

This can be JSON, YAML, or a short table. The important part is not the format. The important part is that field meaning is discussed before schema is frozen.

### Example JSON
```json
{
   "press_id": 0,
   "owner_id": 3,
   "status": "New",
   "lang": "tw",
   "method": "gen_guideline",
   "intent": "...",
   "guideline": "",
   "content": ""
}
```

### What to Validate Before Moving On
- `press_id` is a real relation to another entity
- `owner_id` is ownership, not display-only metadata
- `status` is part of the entity lifecycle
- `lang` belongs in the main table only if language is an operational attribute of the row rather than localized content storage
- `guideline` and `content` are part of the core entity payload rather than optional `_meta` extensions

If any field placement is unclear at this stage, stop and re-check [data_modeling.md](data_modeling.md).

## Step 2: Generate the SQL Schema

After the entity structure is clear, generate SQL that matches F3CMS naming and table decomposition rules.

### Naming Rules to Preserve

#### Table Naming
- always use the `tbl_` prefix
- use lowercase with underscores
- the main table base should align with the module Feed `MTB`
- language tables use `${base}_lang`
- metadata tables use `${base}_meta`
- relation tables use `tbl_{entity_a}_{entity_b}`

#### Field Naming
- primary key is `id`
- foreign keys use `${target}_id`
- subordinate extension rows use `parent_id`
- audit fields use `insert_ts`, `last_ts`, `insert_user`, `last_user`
- sorter fields use `sorter`

#### Schema Consistency Rules
- avoid inventing one-off suffixes when `_lang`, `_meta`, or relation tables already fit
- avoid storing real relations in JSON
- avoid storing localized content in the main table
- avoid using `_meta` to postpone a real schema decision

### Draft Main Table Example
```sql
CREATE TABLE `tbl_draft` (
   `id` INT AUTO_INCREMENT PRIMARY KEY,
   `press_id` INT NOT NULL DEFAULT 0 COMMENT 'Related press entity id',
   `owner_id` INT NOT NULL DEFAULT 0 COMMENT 'Draft owner id',
   `status` ENUM('New', 'Waiting', 'Done', 'Invalid') DEFAULT 'New' COMMENT 'Draft lifecycle status',
   `lang` ENUM('tw', 'en', 'jp') DEFAULT 'tw' COMMENT 'Operational language code',
   `method` VARCHAR(50) NOT NULL DEFAULT '' COMMENT 'LLM method name',
   `intent` TEXT NOT NULL COMMENT 'Original user intent',
   `guideline` TEXT NOT NULL COMMENT 'Prompt guideline or operator instruction',
   `content` LONGTEXT NOT NULL COMMENT 'Generated draft content',
   `insert_ts` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
   `last_ts` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `insert_user` INT NOT NULL DEFAULT 0,
   `last_user` INT NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='LLM draft entity';
```

### Review Before Applying SQL
- Can the table be inferred from the entity name?
- Does every field belong in the main table for a clear reason?
- Would any field be better modeled as `_lang`, `_meta`, or a relation?
- Are audit and ownership fields aligned with existing conventions?

## Step 3: Create the Module Folder

Create the module folder under `www/f3cms/modules/` using PascalCase.

### Example
- folder: `www/f3cms/modules/Draft/`
- Feed class: `fDraft`
- Reaction class: `rDraft`
- Outfit class: `oDraft`
- Kit class if needed: `kDraft`

The folder name, class names, and Feed `MTB` must point to the same entity concept.

## Step 4: Scaffold Feed First

Feed is the minimum required layer because it defines the entity data lifecycle.

### Draft Feed Example
```php
<?php

namespace F3CMS;

class fDraft extends Feed
{
   public const MTB = 'draft';
   public const MULTILANG = 0;

   public const ST_NEW = 'New';
   public const ST_WAITING = 'Waiting';
   public const ST_DONE = 'Done';
   public const ST_INVALID = 'Invalid';

   public const BE_COLS = 'm.id,m.press_id,m.owner_id,m.status,m.lang,m.method,m.intent,m.insert_ts,m.last_ts,m.last_user,m.insert_user';
}
```

### What to Check in Feed
- `MTB` aligns with the table base name
- `MULTILANG` reflects actual schema design
- status constants match the lifecycle model
- `BE_COLS` supports the expected backend read model

Do not turn Feed into a thin placeholder if the entity already needs explicit lifecycle handling. Add the necessary save, read, relation, or helper behavior here as the entity requires.

## Step 5: Add Reaction If Backend Interaction Exists

Add Reaction when the module needs backend request handling, JSON responses, permission orchestration, or management actions.

### Draft Reaction Example
```php
<?php

namespace F3CMS;

class rDraft extends Reaction
{
   public static function handleRow($row = [])
   {
      $row['press_id'] = ($row['press_id'] > 0) ? [fPress::oneOpt($row['press_id'])] : [[]];
      $row['owner_id'] = ($row['owner_id'] > 0) ? [fStaff::oneOpt($row['owner_id'])] : [[]];

      return $row;
   }
}
```

### Reaction Responsibility Reminder
- Reaction handles request and response flow
- Reaction can call Feed and option helpers
- Reaction should not become the primary home of schema logic or persistence rules

If a reviewer sees complex data lifecycle logic accumulating here, move that logic back into Feed.

## Step 6: Add Outfit If Frontend or Page Rendering Exists

Add Outfit when the module needs page routes, frontend rendering orchestration, or view-facing data preparation.

### Draft Outfit Example
```php
<?php

namespace F3CMS;

class oDraft extends Outfit
{
}
```

### Outfit Responsibility Reminder
- Outfit coordinates rendering or page flow
- Outfit should not become a substitute write path for entity persistence

If the module is backend-only or integration-only, Outfit may remain minimal or be omitted until actually needed.

## Step 7: Add Kit When Module-Owned Rules Should Be Encapsulated

Create `kit.php` when the module has validation rules or reusable helper logic that belongs to the module but not to Feed persistence semantics. This logic may still be called by other modules when they need this module's rules, and should not be pushed into `libs` only to avoid duplication.

Use Kit for:
- validation rules
- reusable module-owned helpers
- small utilities used by Reaction or Outfit

Do not create Kit just because every layer name exists. Create it when the module actually needs it.

## Step 8: Final Validation Before Calling the Module Complete

Before considering the module scaffold complete, verify the following.

### Entity and Boundary
- the module still represents one entity
- the module was not created only because one screen needed special behavior

### Schema and Naming
- table names, field names, and class names align
- main table versus `_lang`, `_meta`, and relation placement still looks correct

### Layer Integrity
- Feed owns data lifecycle
- Reaction owns backend interaction
- Outfit owns rendering flow
- Kit is used when module-owned rules or utilities justify encapsulation and possible cross-module reuse
- Parent extension points are checked before any parent-method override

## Common Extension Points (Hook/Override Seam) Snapshot

The formal framework term for this kind of "切入點" is **extension point** (also commonly called a **hook** or **override seam**).

### Extension Point Naming Rules

Use these naming rules when introducing new extension points:

- Use verb-first names that describe intent (`before*`, `after*`, `handle*`, `build*`, `adjust*`, `map*`, `render*`).
- Use domain scope in the name when needed (`*Save*`, `*List*`, `*Filter*`, `*Option*`) so callers can identify lifecycle position quickly.
- Prefer hook names for customization seams; keep shared action entry functions (`do_*`) as orchestration endpoints.
- Do not use `_` prefix to imply extension semantics. In this codebase, `_` is legacy naming style, not a reliable visibility/hook marker.
- For new names, prefer clear hook naming over abbreviations (`gen*`), unless keeping backward compatibility.

Recommended review checklist for naming:
1. Is this method an extension point (hook/seam) or a shared action entry?
2. Can a new contributor infer timing and scope from the name alone?
3. Does the name avoid encoding transport concerns when the behavior is domain-side?

The following counts are from current `www/f3cms/modules/*` implementations (snapshot at 2026-11-09):

### Reaction common extension points
- `handleRow` — 9 modules — shape a single-row payload before returning it to backend edit/get flows
- `handleIteratee` — 2 modules — shape each row in list responses after Feed retrieval
- `beforeSave` — 1 module — normalize/prepare request payload before delegating to Feed save

Reaction note:
- `do_*` methods (for example `do_list`, `do_save`, `do_upload`, `do_get_opts`) are shared action entry functions, not extension points by default.
- In Reaction, extension-point style customization should prioritize hook methods such as `handleRow`, `handleIteratee`, and `beforeSave`.

### Feed common extension points
- `genOrder` — 8 modules — define entity-specific list sorting policy
- `genJoin` — 6 modules — define required joins for list/search/read projections
- `genQuery` — 5 modules — define filter query mapping from request intent to SQL conditions
- `getOpts` — 4 modules — provide entity-specific option lookup output
- `_handleColumn` — 3 modules — split/normalize incoming save payload into main-row and subordinate data
- `adjustFilter` — 2 modules — adjust list/filter conditions before execution

### Outfit common extension points
- `show` — 6 modules — orchestrate page-level rendering and view-model preparation for frontend entry routes

### Kit common extension points
- `rules` — 8 modules — declare module-owned validation contracts used by Reaction save/login/action flows

### Existing Extension Points: Suggested New Names (for future alias/migration)

These are naming suggestions to improve discoverability. They are not mandatory immediate renames.

| Layer | Current name | Suggested name | Reason |
|---|---|---|---|
| Reaction | `handleRow` | `mapDetailRow` | Clarifies this is row shaping for single-row/detail flow. |
| Reaction | `handleIteratee` | `mapListRow` | Clarifies this is list-row mapping, not generic iteratee logic. |
| Reaction | `beforeSave` | `normalizeBeforeSave` | Makes "pre-save normalization hook" explicit. |
| Feed | `genOrder` | `buildListOrder` | `build*` is clearer than `gen*` and anchors to list flow. |
| Feed | `genJoin` | `buildListJoin` | Clarifies join composition role for list/read projection. |
| Feed | `genQuery` | `buildListQuery` | Clarifies query-condition construction. |
| Feed | `getOpts` | `listOptions` | Improves readability and aligns with option endpoint intent. |
| Feed | `_handleColumn` | `normalizeSavePayload` | Describes payload normalization/decomposition directly; removes ambiguous `_`. |
| Feed | `adjustFilter` | `adjustListFilter` | Makes adjustment scope explicit. |
| Outfit | `show` | `renderPage` | Clarifies page-render orchestration role. |
| Kit | `rules` | `validationRules` | Makes validation contract purpose explicit. |

When adding a new module, prefer these extension points first. If none can satisfy the requirement, then proceed with a targeted parent-method override.

### Review Path
- run [data_architecture_checklist.md](data_architecture_checklist.md)
- run [pr_review_checklist.md](pr_review_checklist.md) before merge if the module is already being reviewed in code

## Common Mistakes When Creating a New Module

### Mistake 1: Starting with Files Instead of Entity
This usually produces a folder quickly but a poor boundary.

Correct approach:
- confirm the entity first
- then confirm whether a new module is really needed

### Mistake 2: Putting Too Much in Reaction
New modules often accumulate logic in Reaction because it is easy to start from request handlers.

Correct approach:
- keep persistence and entity lifecycle in Feed

### Mistake 3: Creating a Table Without Table Decomposition Thinking
This often leads to localized content in the main table or relation data in JSON.

Correct approach:
- apply the main, `_lang`, `_meta`, and relation model before writing SQL

### Mistake 4: Treating Kit as a Dumping Ground
Kit should not become a place to hide unclear ownership.

Correct approach:
- move logic into Kit when it is owned by the module's rules and may need reuse, even across modules; move it to `libs` only when it becomes generic infrastructure

## Related Documents
- [module_design.md](module_design.md)
- [data_modeling.md](data_modeling.md)
- [feed_guide.md](feed_guide.md)
- [sd_conventions.md](sd_conventions.md)
- [data_architecture_checklist.md](data_architecture_checklist.md)
- [pr_review_checklist.md](pr_review_checklist.md)

## Status
- Draft v1 aligned with guide system
