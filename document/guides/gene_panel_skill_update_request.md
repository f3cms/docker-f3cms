### Step 1: 澄清與定義 (Clarify & Define)

**改寫目標重述**：
將原本的 `gene-panel-scaffold_SKILL.md` 從傳統的「手動複製 HTML 範本與佔位符替換」模式，全面升級為以 **「Data-Driven Schema-First Pipeline (資料驅動型 Schema 優先管線)」** 為核心的新版 `SKILL.md` 規範文件。

**核心改進效益**：
1. **工作流升級**：確立 **「1. 範例 JSON 數據 ➔ 2. AI 自動推導 SQL DDL ➔ 3. 工程師審核 (Review Gate) ➔ 4. Skill 解析 SQL 自動生成 GP HTML」** 的 4 階段 Pipeline。
2. **元件對映自動化**：內建完整的「SQL 型態/關鍵字 ➔ GP 專屬 UI 元件 (`gee:editor`, `gee-upload`, `gee-uploadDnD`, `gee:set-option`, `multipleSelect`)」映射矩陣。
3. **契約對齊保障**：強制將資料庫欄位名稱 (`name="..."`) 與後端 Reaction/Feed 邊界對齊，徹底消除前後端命名分歧。

---

### Step 2: 拆解與規劃 (Decompose & Plan - 新版 SKILL.md 完整文檔內容)

以下為正式產出的 **新版 `gene-panel-scaffold/SKILL.md` 重構版本**：

```markdown
---
name: gene-panel-scaffold
description: "Generate Gene Panel CRUD HTML scaffolds under www/tmpls/{entity}/ using a Schema-First Pipeline (JSON -> SQL DDL -> Review -> HTML). Use when building or updating backoffice templates."
argument-hint: "Provide entity name, sample JSON or SQL DDL, and form mode: full (list+editor), modal (list+modal), or simple"
---

# Gene Panel Scaffold Skill (Schema-First Pipeline)

Generate standard Gene Panel HTML scaffold files under `www/tmpls/{entity}/` for CRUD backoffice pages, driven directly by SQL DDL schemas to guarantee 100% backend contract alignment.

---

## 1. Core Operating Pipeline (4-Stage Flow)

When asked to generate templates for a new or existing entity, follow this 4-stage pipeline:

```
[Stage 1: Sample JSON Payload]
        ↓
[Stage 2: AI-Synthesized SQL DDL]
        ↓
[Stage 3: Engineer Review & Refinement Gate (Human-in-the-Loop)]
        ↓
[Stage 4: Skill AST Execution → www/tmpls/{entity}/[list|editor|modal|simple].html]
```

1. **Stage 1 (Payload Input)**: Accept example JSON payload(s) from user or notebook sources.
2. **Stage 2 (Schema Synthesis)**: Infer data shapes, types, relationships, and i18n arrays to generate a normalized MySQL/MariaDB DDL snippet.
3. **Stage 3 (Review Gate)**: Present the generated SQL DDL to the engineer for review/refinement (e.g., verifying `COMMENT` flags and module relations).
4. **Stage 4 (HTML Generation)**: Parse the approved SQL DDL and generate standardized `list.html`, `editor.html`, `modal.html`, and/or `simple.html` files.

---

## 2. SQL Column to Gene Panel UI Component Mapping Rules

The AST parser maps SQL data types and `COMMENT` directives to specific Gene Panel HTML components:

| SQL Column Pattern | Target GP Component | Generated HTML Code Snippet |
| :--- | :--- | :--- |
| `INT PRIMARY KEY` / `id` | Hidden Field | `<input type="hidden" name="id">` |
| `VARCHAR(100~255)` (default) | Input Text | `<input class="input" name="{col}" type="text">` |
| `VARCHAR` (name contains `email`) | Email Input | `<input class="input" name="email" type="email">` |
| `VARCHAR` (name contains `pwd`/`password`) | Password Input | `<input class="password input" name="pwd" type="password">` |
| `DATETIME` / `TIMESTAMP` | Datetime Picker | `<input type="datetime-local" class="datetime-local input" name="{col}">` |
| `TEXT` / `MEDIUMTEXT` | Textarea | `<textarea name="{col}" class="textarea"></textarea>` |
| `LONGTEXT` / COMMENT contains `editor` | Rich Editor | `<gee:editor data-param="{col}" data-inline="0"></gee:editor>` |
| `INT` (suffix `*_id`, e.g., `cate_id`) | Option Dropdown | `<gee:set-option module="{entity}" name="{col}"></gee:set-option>` |
| `VARCHAR` (suffix `*_ids`, e.g., `tag_ids`) | Multiple Selector | `<input type="text" multiple class="multipleSelect" name="{col}">` |
| `VARCHAR` (name contains `cover`/`avatar` / `upload`) | Single Upload | `<gee-upload module-name="{entity}" data-param="{col}"></gee-upload>` |
| `VARCHAR`/`TEXT` (contains `banner`/`gallery` / `uploadDnD`) | Drag-n-Drop Upload | `<gee-uploadDnD module-name="{entity}" multiple="true" data-param="{col}"></gee-uploadDnD>` |
| `ENUM('Enabled','Disabled')` / `TINYINT(1)` | Radio Status | `<input type="radio" class="is-checkradio" name="status" value="Enabled">` |
| `lang[locale][field]` (Multilingual Table) | i18n Field Block | Grouped inside multilingual `<div class="box">` blocks |

---

## 3. Directory & Naming Conventions

Templates MUST strictly align with the directory hierarchy:

```
www/tmpls/{entity}/
├── list.html      # Main listing & filter bar
├── editor.html    # Full-page CRUD form
├── modal.html     # Popup modal form
└── simple.html    # Compact side-by-side form
```

---

## 4. Execution Procedure

1. **Identify Inputs**: Confirm `entity` name, target `mode` (`full`, `modal`, or `simple`), and input data payload/SQL.
2. **Schema Gate Check**: If only JSON is provided, output the inferred SQL DDL first and wait for engineer confirmation.
3. **Parse & Assemble**:
   - Extract primary keys, multilingual fields (`lang`), metadata fields (`meta`), and relations (`*_ids`).
   - Map each database column to its respective GP component using the Mapping Rules matrix.
4. **Write Output Files**:
   - Save target template files directly under `www/tmpls/{entity}/`.
5. **Contract Verification**:
   - Ensure every `input[name]`, `textarea[name]`, and `gee:editor[data-param]` strictly matches the SQL DDL column names.
   - Verify that all business logic remains in backend Reaction/Feed modules; HTML templates must handle presentation and event bindings only.

---

## 5. End-to-End Practical Example (Press Entity)

### Input SQL DDL (Post-Review Gate)
```sql
CREATE TABLE `gp_press` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `cate_id` INT NOT NULL COMMENT '分類|module:press_category',
  `status` ENUM('Draft', 'Published') DEFAULT 'Published' COMMENT '發布狀態',
  `online_date` DATETIME COMMENT '上線時間',
  `cover` VARCHAR(255) COMMENT '封面圖|upload',
  `banner` VARCHAR(255) COMMENT '橫幅大圖|uploadDnD',
  `author_ids` VARCHAR(255) COMMENT '作者|module:author',
  `tag_ids` VARCHAR(255) COMMENT '標籤|module:tag'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `gp_press_lang` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `press_id` INT NOT NULL,
  `lang` VARCHAR(10) NOT NULL,
  `title` VARCHAR(255) NOT NULL COMMENT '文章標題',
  `info` TEXT COMMENT '摘要說明',
  `content` LONGTEXT COMMENT '詳細內文|editor'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### Generated `www/tmpls/press/editor.html`
```html
<form class="gee" data-gene="init:loadRow,submit:setRow" data-tmpl="pressForm">
  <input type="hidden" name="id">

  <!-- Multilingual Content Block -->
  <div class="box">
    <h3 class="title is-4">文章內容 (繁體中文)</h3>
    <div class="field">
      <label class="label">文章標題</label>
      <p class="control">
        <input class="input" name="lang[tw][title]" type="text" placeholder="請輸入標題" required>
      </p>
    </div>

    <div class="field">
      <label class="label">摘要說明</label>
      <p class="control">
        <textarea name="lang[tw][info]" class="textarea" placeholder="摘要說明"></textarea>
      </p>
    </div>

    <div class="field">
      <label class="label">詳細內文</label>
      <p class="control">
        <gee:editor data-param="lang[tw][content]" data-inline="0"></gee:editor>
      </p>
    </div>
  </div>

  <!-- Settings Block -->
  <div class="box">
    <h3 class="title is-4">屬性與分類</h3>
    <div class="field">
      <label class="label">分類</label>
      <p class="control">
        <span class="select">
          <gee:set-option module="press_category" name="cate_id"></gee:set-option>
        </span>
      </p>
    </div>

    <div class="field">
      <label class="label">發布狀態</label>
      <input type="radio" class="is-checkradio" name="status" value="Published" id="press-status-pub" checked>
      <label class="radio" for="press-status-pub">發布</label>
      <input type="radio" class="is-checkradio" name="status" value="Draft" id="press-status-draft">
      <label class="radio" for="press-status-draft">草稿</label>
    </div>

    <div class="field">
      <label class="label">上線時間</label>
      <p class="control">
        <input type="datetime-local" class="datetime-local input" name="online_date">
      </p>
    </div>
  </div>

  <!-- Media Upload Block -->
  <div class="box">
    <h3 class="title is-4">圖片與媒體</h3>
    <div class="field">
      <label class="label">封面圖</label>
      <gee-upload module-name="press" data-param="cover"></gee-upload>
    </div>

    <div class="field">
      <label class="label">橫幅大圖</label>
      <gee-uploadDnD module-name="press" multiple="false" data-param="banner"></gee-uploadDnD>
    </div>
  </div>

  <!-- Relations Block -->
  <div class="box">
    <h3 class="title is-4">關聯設定</h3>
    <div class="field">
      <label class="label">作者選擇</label>
      <div class="control">
        <input type="text" multiple class="multipleSelect" name="author_ids" placeholder="搜尋作者" data-url="author/get_opts">
      </div>
    </div>

    <div class="field">
      <label class="label">標籤選擇</label>
      <div class="control">
        <input type="text" multiple class="multipleSelect" name="tag_ids" placeholder="搜尋標籤" data-url="tag/get_opts">
      </div>
    </div>
  </div>

  <!-- Action Controls -->
  <div class="field is-grouped">
    <p class="control">
      <button class="button is-primary" type="submit">儲存</button>
    </p>
    <p class="control">
      <button class="button is-light gee" data-gene="click:closeModal" type="button">取消</button>
    </p>
  </div>
</form>
```
```

---

### Step 3: 風險與緩解 (Risks & Mitigation)

1. **舊專案相容性 (Backward Compatibility)**：
   * **風險**：若開發者未提供 JSON 或 SQL，僅給出實體名稱（如 `mobile`），直接套用新管線可能會中斷。
   * **緩解計畫**：在 `Execution Procedure` 預留降級機制 (Fallback)：若完全無數據結構輸入，Skill 會回歸基礎骨架 (Base Shell)，生成僅包含預設 `#`, `title`, `actions` 的 minimal HTML。

2. **跨專案模組命名失配 (Module Path Mismatch)**：
   * **風險**：`cate_id` 推導出 `module="cate"`，但某些 legacy 專案使用 `category`。
   * **緩解計畫**：允許工程師在 Stage 3 (Review Gate) 的 SQL `COMMENT` 中加入提示標籤（如 `COMMENT '分類|module:category'`），Skill 將優先採用指定的模組名稱。

---

### Step 4: 執行與溝通 (Execution & Communication)

**Stakeholder Update (TL;DR)**：

> **TL;DR - 新版 `gene-panel-scaffold/SKILL.md` 改寫完成摘要**
> 
> * **改寫核心**：正式將 Skill 升級為 **「JSON ➔ SQL DDL ➔ Review Gate ➔ GP HTML Generation」** 的自動化 4 階段 Pipeline。
> * **規範亮點**：
>   1. **精準元件對映**：內建 SQL 型態/關鍵字至 `gee:editor`、`gee-upload`、`gee-uploadDnD` 與 `multipleSelect` 的映射表。
>   2. **多語系與關聯支援**：原生處理 `lang[locale][field]` 命名空間與多對多關聯欄位。
>   3. **完整實例收錄**：將 `press_sample.md` 的真實演練代碼完整收錄至 Skill 的範例章節中，作為標準參考標桿。