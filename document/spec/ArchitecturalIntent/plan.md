# ArchitecturalIntent Plan

## Purpose
- 將 `idea.md` 的架構註解移植構想拆成可承接的最小 stage。
- 確保後續工作優先處理核心類別與紅線約束，而不是散彈式補註解。
- 讓後續文件同步、跨語言移植與 LLM 使用都有穩定基準。

## Plan Basis

本計畫直接沿用 `idea.md` 已確定的結論，不重開以下議題：
- 目標是固化架構意圖，不是修改 runtime behavior
- 標的以 `libs/` 與對應核心 conventions 為主，不先擴到所有 module
- 註解必須能表達 Architecture Purpose、Design Intent、Strict Constraints、Porting Guidelines
- 重點是保留 OntoCMS 的 entity-first、FORKS 分層與 owner boundary，而不是生成一般語言層級的 API 註解
- 當 entity-first、重用便利性與 owner boundary 判斷出現拉扯時，以 FORKS 分層與 owner boundary 為優先

## Scope

第一版要完成：
- 建立核心類別註解樣板與欄位規格
- 建立核心類別內每一個函式的註解覆蓋要求與詳略規則
- 盤點第一批優先標的類別清單
- 為每個標的類別定義其 architecture purpose 與 strict constraints
- 明確定義跨語言移植時應保留的 owner boundary 與資料責任
- 將穩定規則同步到適合的 `document/` 共用文件

第一版不預設完成：
- 全 repo 所有類別全面補註解
- 業務 module 的細部商業規則說明
- 任何 runtime 邏輯重構或 API redesign

## Dependencies

- [idea.md](idea.md)
- [../../flow.md](../../flow.md)
- [../../guides/llm_dba_guide.md](../../guides/llm_dba_guide.md)
- [../../guides/sd_conventions.md](../../guides/sd_conventions.md)
- [../../guides/fdd_porting_guide.md](../../guides/fdd_porting_guide.md)
- 現有核心類別與既有 spec / guides 中已定案的 owner boundary 規則

## Stage Plan

### Stage 1: 固定註解樣板與評估基準

目標：
- 把「架構意圖註解」收斂成可重複套用的固定格式
- 明確定義什麼該寫、什麼不該寫

主要工作：
- 為核心類別定義統一的 block comment 模板
- 為核心類別內每一個函式定義最低註解覆蓋規則
- 固定最小欄位：Architecture Purpose、Design Intent、Strict Constraints、Porting Guidelines
- 補出註解與既有 spec / guides 的引用原則
- 明確排除低價值註解與 runtime 描述重複

輸出：
- 核心註解模板初版
- 函式層級註解覆蓋規則
- 註解撰寫紅線清單

驗收重點：
- 能判斷一段註解是否真的在保護架構意圖
- 能判斷每一個函式至少是否已有對應的新註解，而不是只補類別說明
- 不會退化成一般 API 文件或逐行解說

#### Stage 1 輸出草案

##### A. 核心註解模板

```php
/**
 * Architecture Purpose
 * - 說明此類別在 OntoCMS / F3CMS 分層中的定位，只描述它應該負責的層級角色。
 *
 * Design Intent
* - 說明為何這個類別以目前方式存在，尤其是它在 FORKS、module-owned boundary、entity-first 下要保留的設計意圖。
 *
 * Strict Constraints
 * - 列出移植時不可妥協的紅線，例如不得取得不屬於它的 persistence ownership、不得吞進 entity-specific business coordination、不得把 transaction 邊界推錯層。
 *
 * Porting Guidelines
 * - 說明跨語言重構時建議如何對應，例如可對應成 runtime service、repository base、request orchestrator、view adapter；必要時引用 `document/` 中已穩定的規則來源。
 */
```

##### A-1. 函式層級覆蓋規則

- 納入本計畫的核心類別，其內每一個函式都必須補上新的註解。
- 不是每一個函式都要同樣長，但不能沒有：
	- 核心流程函式至少要說明它在 FORKS / owner boundary 中的責任、不可跨越的紅線、必要時補 porting note。
	- 較薄的 wrapper、dispatch、helper 也至少要說明它只是邊界轉送、格式整理或 orchestration 節點，不能只剩舊式 `@param` / `@return`。
- 若函式只保留舊式 PHPDoc 或完全無註解，視為本 spec 尚未完成該函式承接。

##### B. 註解撰寫紅線

- 不重述函式簽名、參數或 return type 已能直接看懂的內容。
- 不把暫時性的實作細節、局部 bug 修法或 screen-specific 流程寫成架構原則。
- 不因為抽象化或共用看起來方便，就把 owner-side coordination 推進 shared `libs/`；遇到拉扯時，以 FORKS owner boundary 為優先。
- 不在 `libs/` 類別註解中默認它擁有 module 資料真實來源、entity writeback 或 owner-side duty judgment。
- 不把 module-owned 規則抽象成看似通用但其實只服務單一 entity 的 generic helper 契約。
- 不把 transaction ownership、audit log ownership、workflow runtime ownership 寫成 libs-level convenience。

##### C. `document/` 引用原則

- 若規則已在 `document/guides/` 或其他 spec 穩定存在，註解以短句摘要加相對路徑引用，不把完整背景全文塞進原始碼。
- 若某段背景只在特定 spec 有效，引用該 spec，而不是把 feature-specific 假設偽裝成全域慣例。
- 只有在沒有穩定文件可引用、且此紅線若不寫在原始碼就容易在移植時遺失時，才把規則直接寫進類別註解。

### Stage 2: 盤點第一批核心標的

目標：
- 確定第一批最值得補註解的核心類別
- 用 owner boundary 與移植風險排序，而不是憑直覺挑檔案

主要工作：
- 列出第一批 5 到 10 個核心類別或介面
- 為每個標的標示其架構角色、風險與優先順序
- 辨識哪些規則已在 `document/` 中穩定存在，哪些仍只存在於程式脈絡

輸出：
- 第一批標的清單
- 優先順序與原因

驗收重點：
- 標的清單能覆蓋 Feed、Reaction、Workflow 或其他核心 owner boundary
- 優先順序能說明「為何先補這些，不是先補別的」

#### Stage 2 候選標的草案

1. `Module`
	- 優先順序：P0
	- 風險理由：它是 layer shift、request normalization 與共用入口的底座，若移植時把它誤解成 generic utility bin，後續 Feed / Reaction / Outfit / Kit 的責任會一起漂移。
2. `Feed`
	- 優先順序：P0
	- 風險理由：它直接承接 entity lifecycle、lang/meta/relation save flow 與資料分解慣例，最容易在跨語言重寫時被扁平成一般 repository 而失去 OntoCMS 的 entity-first 結構。
3. `Reaction`
	- 優先順序：P0
	- 風險理由：它是 request handling、permission、validation orchestration 的主要邊界，若沒有紅線，移植時很容易把 persistence 或 workflow writeback 塞回 controller 層。
4. `WorkflowEngine`
	- 優先順序：P0
	- 風險理由：它已明確被收斂成 runtime evaluator；若註解不保護這點，重構時極容易再次被塞進 shared workflow runtime table、transaction ownership 或 module-specific persistence。
5. `Smoke`
	- 優先順序：P0
	- 風險理由：它是 FORKS smoke contract dispatch 的共享底座，若沒有註解保護，移植時很容易把 module-owned assertion、context loading 或 fallback routing 錯塞回 shared base。
6. `Kit`
	- 優先順序：P1
	- 風險理由：它常承接 module-owned rule 與驗證策略，若沒有清楚邊界，最容易在 reusable 與 owner-specific logic 之間混層。
7. `Outfit`
	- 優先順序：P0
	- 風險理由：它位在前台 route / rendering 邊界，若定位不清，常會把 page orchestration、session/context 與 entity persistence 混在一起。
8. `EventRuleEngine`
	- 優先順序：P1
	- 風險理由：它和 WorkflowEngine 一樣屬於 shared runtime evaluator，若沒有註解保護，很容易被錯誤擴張成 owner-side context loader 或 business coordinator。
9. `Utils.php`
	- 優先順序：P1
	- 風險理由：它雖然不是 class，而是 shared global runtime surface，但裡面直接定義 `f3()`、`mh()`、`rc()` 這類 service-locator / runtime entry helpers；若沒有註解保護，移植時很容易把它擴張成 generic utility bin，進一步加深對全域 helper 的耦合。
10. `Autoload`
	- 優先順序：P1
	- 風險理由：它直接承接 FORKS type-prefix 與 layer-shift 的 class-path resolution；若沒有註解保護，移植時很容易被誤擴張成任意 runtime bootstrap coordinator，進一步模糊 shared loader 與 owner-side wiring 的界線。
11. `Belong`
	- 優先順序：P1
	- 風險理由：它是 shared relation bind / count update trait，若沒有註解保護，移植時很容易把 entity-owned relation policy、counter semantics 或 relation duty judgment 錯塞回 generic trait。
12. `Ression`
	- 優先順序：P1
	- 風險理由：它是 Redis-backed shared session/security runtime handler；若沒有註解保護，移植時很容易把 session fingerprint、防護策略與 owner-side auth/business flow 混成同一層。
13. `Mession`
	- 優先順序：P1
	- 風險理由：它是 DB-backed shared session/security runtime handler，風險與 `Ression` 類似；若沒有註解保護，移植時容易把 storage adapter、suspect handling 與業務登入流程誤綁在一起。

#### 下一批重要 module feed 候選草案

這一批不把所有 `www/f3cms/modules/*/feed.php` 全數展開，而是直接收斂到使用者指定的五個 feed：`fPress`、`fStaff`、`fRole`、`fMenu`、`fTag`。其餘 module feed 本輪明確略過。

1. `fPress`
	- 優先順序：P0
	- 風險理由：它不只是內容 entity feed，還直接承接 published status、workflow trace log、author/tag/related/book relation writeback、AI draft import 與鄰近內容讀取；若沒有註解保護，很容易在移植時把 entity-owned content lifecycle 與 workflow/log ownership 拆散或錯推回 generic service。
2. `fStaff`
	- 優先順序：P1
	- 風險理由：它承接 staff current-session snapshot、sudo trail 與 role privilege bridge；若沒有註解保護，移植時容易把 backend identity truth、role projection 與 session snapshot 混回 shared session/runtime surface。
3. `fRole`
	- 優先順序：P1
	- 風險理由：它承接 backend role / privilege mapping，若沒有註解保護，移植時很容易把角色權限語意降格為一般 lookup 資料，或把 auth projection 錯推到 Reaction / session helper。
4. `fMenu`
	- 優先順序：P2
	- 風險理由：它有 tree sorting、parent update、orphan cleanup 等結構性規則，但 owner boundary 明顯度低於前述目標；除非下一輪要專處理 hierarchical content/tree ownership，否則不需先於 `Press`/`Duty`/`Task`/`Member`。
5. `fTag`
	- 優先順序：P2
	- 風險理由：它雖然相對薄，但直接位在內容 relation 與標記語意支點；若沒有註解保護，移植時容易被當成純 lookup table，忽略它在內容分類／關聯中的 owner-side語意。

本輪明確略過的 feed：
- `fDuty`、`fTask`、`fMember`、`fManaccount`、`fCampaign`、`fDoorman`、`fDraft` 等，並非不重要，而是本輪先尊重使用者指定範圍，不擴張到未點名模組。
- `fPost`、`fMedia`、`fOption`、`fSearch`、`fMeta`、`fGenus` 等維持略過，避免 scope 滑回全面盤點。

#### 下一批重要 module reaction 候選草案

使用者已把 module reaction 範圍明確收斂為六個 target：`Press/reaction.php`、`Draft/reaction.php`、`Staff/reaction.php`、`Crontab/reaction.php`、`Menu/reaction.php`、`Tag/reaction.php`。其餘 reaction 本輪明確略過。

1. `Press/reaction.php`
	- 優先順序：P0
	- 風險理由：它直接承接 publish workflow transition、workflow trace、operator role 檢查、seen completion 與前台內容載入 shaping；若沒有註解保護，很容易把 workflow orchestration、Feed ownership 與 operator gate 混回 generic controller/service。
2. `Draft/reaction.php`
	- 優先順序：P0
	- 風險理由：它集中 draft import、translate、SEO/i18n 生成與 Press document lifecycle 協調；若沒有註解保護，很容易把跨 content lifecycle orchestration 錯推到 generic helper 或 background worker。
3. `Staff/reaction.php`
	- 優先順序：P0
	- 風險理由：它承接 backend login、session snapshot、sudo、CSRF/auth flow 與 security 協調；若沒有註解保護，很容易把 backend identity orchestration 與 shared session/runtime surface 混層。
4. `Crontab/reaction.php`
	- 優先順序：P0
	- 風險理由：它有反射型 worker dispatch、security check 排程與跨 module job orchestration；若沒有註解保護，移植時很容易模糊 scheduler gateway、module-owned job logic 與 authorization 邊界。
5. `Menu/reaction.php`
	- 優先順序：P1
	- 風險理由：它直接承接 tree editing、structure validation 與全域 navigation orchestration；若沒有註解保護，hierarchical UI orchestration 很容易漂回 generic tree helper。
6. `Tag/reaction.php`
	- 優先順序：P1
	- 風險理由：它雖較薄，但直接位在 tag relation、lookup 與內容分類反應邊界；若沒有註解保護，容易被降格為純 transport wrapper，忽略 owner-side分類語意。

本輪明確略過的 reaction：
- `Webhook`、`Media`、`Campaign`、`Adv` 等，並非不重要，而是本輪先尊重使用者指定範圍，不擴張到未點名模組。
- `User`、`Doorman`、`Excel`、`Search`、`Shorten`、`Dictionary`、`Stream`、`Yell` 等空 reaction 與其它薄 wrapper / lookup reaction 維持略過，避免 scope 滑回全面 rollout。

#### 下一批重要 module outfit 候選草案

使用者已把 module outfit 範圍明確收斂為兩個 target：`Press/outfit.php`、`Post/outfit.php`。其餘 outfit 本輪明確略過。

1. `Press/outfit.php`
	- 優先順序：P0
	- 風險理由：它是 Press 前台文章頁面的主 rendering / caching / page-shaping boundary，直接組裝文章、分類、標籤、作者、相關文、媒體、SEO 與 ld+json；若沒有註解保護，很容易把 page orchestration、content shaping 與 Feed / Kit owner boundary 混回 generic page helper 或 controller。
2. `Post/outfit.php`
	- 優先順序：P1
	- 風險理由：它是站點級 frontdoor outfit，承接首頁、robots、sitemap、rss、LINE XML、靜態頁與 404/coming soon/maintenance 等前台入口；若沒有註解保護，很容易被誤解成零散頁面集合，忽略它其實是 site-wide rendering/orchestration boundary。

本輪明確略過的 outfit：
- `Member/outfit.php`、`Staff/outfit.php`、`Draft/outfit.php`、`Edm/outfit.php`、`Contact/outfit.php` 並非不重要，而是本輪先尊重使用者指定範圍，不擴張到未點名模組。
- `Role/outfit.php`、`Media/outfit.php`、`Stats/outfit.php`、`Search/outfit.php`、`User/outfit.php` 先略過，因為幾乎空殼，沒有足夠 owner-boundary 行為可寫成高價值架構註解。
- `Webhook/outfit.php`、`Yell/outfit.php`、`Adv/outfit.php`、`Shorten/outfit.php`、`Subscription/outfit.php` 先略過，因為主要是 transport wrapper、counter / reroute 或單一步驟 action wrapper，架構風險低於前段候選。
- `Author/outfit.php`、`Category/outfit.php`、`Tag/outfit.php`、`Dictionary/outfit.php` 先略過，因為主要是 slug 或 id lookup 後 render 單一模板，較接近 lookup/view helper，不是高風險 orchestration boundary。

#### 下一批重要 module kit 候選草案

使用者已把 module kit 範圍明確收斂為四個 target：`Staff/kit.php`、`Member/kit.php`、`Adv/kit.php`、`Draft/kit.php`。其餘 kit 本輪明確略過。

1. `Staff/kit.php`
	- 優先順序：P1
	- 風險理由：它承接 backend staff invite、account uniqueness rule、save/login/reset validation 與後台 login gate；若沒有註解保護，移植時很容易把 account uniqueness、invite flow 與 backend gate 錯塞回 generic form validation 或 shared auth helper。
2. `Member/kit.php`
	- 優先順序：P0
	- 風險理由：它同時碰 member identity truth、OAuth binding snapshot、register 後 task trigger 與 session writeback；若沒有註解保護，移植時很容易把 auth/session truth、EventRule context preload 或 register side effect 混回 shared auth helper、controller 或 generic social-login service。
3. `Adv/kit.php`
	- 優先順序：P1
	- 風險理由：它不是單純 cache helper，而是把廣告版位資源與 Press/Category 內容投影綁在同一個 kit surface；若沒有註解保護，很容易把 ad-slot shaping、content enrichment 與 cache ownership 混成 generic board helper。
4. `Draft/kit.php`
	- 優先順序：P2
	- 風險理由：它雖然偏外部 MPThelper 的 transport bridge，但仍定義了 Draft 對 AI writing、SEO、guideline、translate 與 quicktrans 的 intent shaping 與 payload 契約；若沒有註解保護，很容易被擴張成 generic AI helper，侵蝕 Draft module 的 owner-side workflow 邊界。

本輪明確略過的 kit：
- `Duty/kit.php`、`Campaign/kit.php`、`Doorman/kit.php` 並非不重要，而是本輪先尊重使用者指定範圍，不擴張到未點名模組。
- `Webhook/kit.php`、`Yell/kit.php`、`Lab/kit.php` 先略過，因為幾乎空殼，沒有足夠 owner-boundary 行為可寫成高價值架構註解。
- `Post/kit.php`、`Shorten/kit.php`、`Press/kit.php` 先略過，因為主要是薄 wrapper、present/decorate helper、lang check 或 reroute/callback orchestration，owner-boundary 低於前段候選。
- `Excel/kit.php`、`Crontab/kit.php` 先略過，因為主要偏 export/render transport helper 或 ops/security CLI helper，不是目前這輪要先保護的 module-owned business truth 邊界。
- `Contact/kit.php` 並非不重要，但目前只剩 captcha 與 add_new rule，責任面較小，先不列入第一批 kit 註解標的。

### Stage 3: 補第一批類別的架構意圖註解

目標：
- 在最核心的類別上落地第一版註解
- 確保移植工程師或 LLM 能從原始碼直接看到紅線與定位

主要工作：
- 逐一補上第一批類別的高階 block comment
- 逐一補上這些類別內每一個函式的新註解
- 若標的是 `Utils.php` 這類 shared global runtime surface，則以檔案層級定位加上每個共享函式的新註解取代 class-level 註解
- 對齊每個類別的 owner boundary 與資料責任
- 在必要處補上對 `document/` 的相對路徑引用

輸出：
- 第一批核心類別註解實作

驗收重點：
- 註解不改變 runtime behavior
- 納入範圍的函式不可只剩 class-level 註解，必須完成函式層級覆蓋
- 若標的是 shared global runtime surface，必須有檔案層級定位與函式層級覆蓋，不能只留傳統 utility docblock
- 註解能直接阻止常見移植誤解，例如把 workflow 持久化責任塞回 engine，或把 entity-specific 邏輯推進 generic helper

### Stage 4: 文件同步與封存前整理

目標：
- 將已穩定的規則回寫到共用文件
- 降低未來 handoff 成本

主要工作：
- 將穩定術語或紅線回寫到 glossary / guides / reference
- 在 `history.md`、`plan.md`、`check.md` 中同步目前完成狀態
- 判斷是否可進入 `(Optimization)` 或直接封存

輸出：
- 文件同步結果
- 封存前整理清單

驗收重點：
- 稳定規則不只存在於程式碼註解
- 後續 handoff 不需要重新從 `idea.md` 推理一次