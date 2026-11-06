---
name: gene-panel-scaffold
description: "Generate Gene Panel CRUD HTML scaffolds under www/tmpls/{entity}/ using a Schema-First Pipeline (JSON -> SQL DDL -> Review -> HTML). Use when building or updating backoffice templates."
argument-hint: "Provide entity name, sample JSON or SQL DDL, and form mode: full (list+editor), modal (list+modal), or simple"
---

# Gene Panel Scaffold Skill (Schema-First Pipeline)

Generate standard Gene Panel HTML scaffold files under `www/tmpls/{entity}/` for CRUD backoffice pages, driven directly by SQL DDL schemas to keep backend contract alignment.

## 1. Core Operating Pipeline (4-Stage Flow)

When asked to generate templates for a new or existing entity, follow this pipeline:

```text
[Stage 1: Sample JSON Payload]
        ↓
[Stage 2: AI-Synthesized SQL DDL]
        ↓
[Stage 3: Engineer Review & Refinement Gate (Human-in-the-Loop)]
        ↓
[Stage 4: Skill AST Execution → www/tmpls/{entity}/[list|editor|modal|simple].html]
```

1. **Stage 1 (Payload Input)**: Accept JSON payload(s) from user or docs.
2. **Stage 2 (Schema Synthesis)**: Infer data shapes/types/relations and output normalized MySQL/MariaDB DDL.
3. **Stage 3 (Review Gate)**: Present generated SQL DDL for engineer review (especially `COMMENT` hints and module mapping).
4. **Stage 4 (HTML Generation)**: Parse approved SQL DDL and generate `list.html`, `editor.html`, `modal.html`, and/or `simple.html`.

## 2. SQL Column to Gene Panel UI Component Mapping Rules

Map SQL types and `COMMENT` hints to Gene Panel components:

| SQL Column Pattern | Target GP Component | Generated HTML Snippet |
| :--- | :--- | :--- |
| `INT PRIMARY KEY` / `id` | Hidden Field | `<input type="hidden" name="id">` |
| `VARCHAR(100~255)` (default) | Input Text | `<input class="input" name="{col}" type="text">` |
| `VARCHAR` with `email` | Email Input | `<input class="input" name="email" type="email">` |
| `VARCHAR` with `pwd`/`password` | Password Input | `<input class="password input" name="pwd" type="password">` |
| `DATETIME` / `TIMESTAMP` | Datetime Picker | `<input type="datetime-local" class="datetime-local input" name="{col}">` |
| `TEXT` / `MEDIUMTEXT` | Textarea | `<textarea name="{col}" class="textarea"></textarea>` |
| `LONGTEXT` or `COMMENT` has `editor` | Rich Editor | `<gee:editor data-param="{col}" data-inline="0"></gee:editor>` |
| `INT` suffix `*_id` | Option Dropdown | `<gee:set-option module="{option_source_entity}" name="{col}"></gee:set-option>` |
| `VARCHAR` suffix `*_ids` | Multiple Selector | `<input type="text" multiple class="multipleSelect" name="{col}">` |
| `VARCHAR` with `cover`/`avatar`/`upload` | Single Upload | `<gee-upload module-name="{entity}" data-param="{col}"></gee-upload>` |
| `VARCHAR`/`TEXT` with `banner`/`gallery`/`uploadDnD` | Drag-n-Drop Upload | `<gee-uploadDnD module-name="{entity}" multiple="true" data-param="{col}"></gee-uploadDnD>` |
| `ENUM(...)` / `TINYINT(1)` status-like field | Radio Status | `<input type="radio" class="is-checkradio" name="status" value="Enabled">` |
| `lang[locale][field]` | i18n Field Block | Grouped multilingual blocks (`<div class="box">`) |

## 3. Directory & Naming Conventions

Output must align to:

```text
www/tmpls/{entity}/
├── list.html
├── editor.html
├── modal.html
└── simple.html
```

## 4. Execution Procedure

1. **Identify Inputs**
   - Confirm `entity`, target `mode` (`full`, `modal`, `simple`), and source data (JSON or SQL).
2. **Schema Gate Check**
   - If only JSON is provided, generate SQL DDL first and wait for engineer confirmation before generating HTML.
3. **Parse & Assemble**
   - Extract PK, multilingual (`lang`), relation (`*_ids`), and metadata fields.
   - Apply mapping rules to produce GP components.
   - Populate standard slots in assets: multilingual slot, settings slot, media slot, relation slot.
4. **Write Output Files**
   - `full` → `list.html` + `editor.html`
   - `modal` → `list.html` + `modal.html`
   - `simple` → `simple.html`
5. **Contract Verification**
   - Every `input[name]`, `textarea[name]`, and `gee:editor[data-param]` must match SQL column names.
   - Keep business logic in backend Reaction/Feed boundaries; templates only handle presentation/bindings.
6. **Fallback**
   - If neither JSON nor SQL is provided, generate base shell only (minimal list/form skeleton) and request schema input.

## 5. End-to-End Practical Example (Press Entity)

Use [gene_panel_skill_use_sample.md](../../../document/guides/gene_panel_skill_use_sample.md) as the canonical benchmark example.

### Input SQL DDL (post-review gate)

```sql
CREATE TABLE `tbl_press` (
  `id` INT AUTO_INCREMENT PRIMARY KEY COMMENT '文章ID',
  `cate_id` INT NOT NULL COMMENT '分類|module:category',
  `status` ENUM('Draft', 'Published', 'Archived') DEFAULT 'Published' COMMENT '發布狀態',
  `online_date` DATETIME COMMENT '上線時間',
  `cover` VARCHAR(255) COMMENT '封面圖|upload',
  `banner` VARCHAR(255) COMMENT '橫幅大圖|uploadDnD',
  `author_ids` VARCHAR(255) COMMENT '作者選擇|module:author',
  `tag_ids` VARCHAR(255) COMMENT '標籤選擇|module:tag'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tbl_press_lang` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `press_id` INT NOT NULL,
  `lang` VARCHAR(10) NOT NULL,
  `title` VARCHAR(255) NOT NULL COMMENT '文章標題',
  `info` TEXT COMMENT '摘要說明',
  `content` LONGTEXT COMMENT '詳細內文|editor'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### Generated `www/tmpls/press/editor.html` (key parts)

```html
<input type="hidden" name="id">
<input class="input" name="lang[tw][title]" type="text" required>
<textarea name="lang[tw][info]" class="textarea"></textarea>
<gee:editor data-param="lang[tw][content]" data-inline="0"></gee:editor>
<gee:set-option module="category" name="cate_id"></gee:set-option>
<input type="radio" class="is-checkradio" name="status" value="Published">
<input type="datetime-local" class="datetime-local input" name="online_date">
<gee-upload module-name="press" data-param="cover"></gee-upload>
<gee-uploadDnD module-name="press" multiple="false" data-param="banner"></gee-uploadDnD>
<input type="text" multiple class="multipleSelect" name="author_ids" data-url="author/get_opts">
<input type="text" multiple class="multipleSelect" name="tag_ids" data-url="tag/get_opts">
```

## 6. Notes

- Follow GP component and naming conventions in [gene_panel_component_list.md](../../../document/reference/gene_panel_component_list.md).
- For `gee:set-option`, `module` means the option-source entity (for example `cate_id` should use `module="category"`).
- If module inference is ambiguous (`cate_id` -> `cate` vs `category`), prefer explicit SQL `COMMENT` hints like `module:category`.
- If mode is unclear, ask:
  - full-page CRUD form → `editor.html`
  - popup form → `modal.html`
  - compact side form → `simple.html`
