# Gene Panel HTML 元件參考

## 文件範圍
本文件描述 **Gene Panel** 的 HTML 元件結構與使用模式。Gene Panel 是可與既有應用程式整合、用來產生後台介面的**獨立前端套件**；它不屬於整合它的應用程式。

本文以目前整合專案中的 `www/tmpls` 模板為盤點來源，因此範例會出現整合端的模組名稱、資料欄位與 API 路徑；這些是整合層的使用情境，不代表元件屬於整合端程式。

## 元件類別
1. **搜尋元件**：建立列表篩選與關鍵字查詢條件。
2. **清單元件**：載入並呈現資料列、卡片與操作入口。
3. **欄位元件**：編輯表單中的資料輸入與關聯控制項。
4. **按鈕元件**：建立、儲存、查看與觸發工作流的操作入口。

## 模板命名慣例（`www/tmpls`）

Gene Panel 的模板命名是依 **實體 / 畫面型態** 來組織，而不是依任意功能名稱或 `sms-admin` 這種空泛命名。實務上，通常採用以下慣例：

- `www/tmpls/{entity}/list.html`：列表頁，通常包含搜尋、狀態篩選與資料表格。
- `www/tmpls/{entity}/editor.html`：完整表單頁，適合單頁編輯與完整資訊編輯。
- `www/tmpls/{entity}/modal.html`：跳出式表單，適合新增 / 編輯時以 modal 方式呈現。
- `www/tmpls/{entity}/simple.html`：右側小表單或簡化編輯區，適合快速新增或關聯資料。

### 命名規則

1. `list.html` 是列表頁入口，不應當成一個自訂的管理頁面名稱。
2. 如果頁面是「搜尋 + 清單」，通常使用 `list.html`。
3. 如果頁面是「全頁編輯表單」，通常使用 `editor.html`。
4. 如果頁面是「彈出表單」，通常使用 `modal.html`。
5. 如果頁面是「右側小表單 / 側邊編輯面板」，通常使用 `simple.html`。
6. 模板名稱應與主體實體對齊，例如 `mobile/list.html`、`phonebook/list.html`、`campaign/list.html`。
7. 不能用 `sms-mobile-admin.html` 這種功能型命名，因為它不符合 `www/tmpls/{entity}/...` 的常規和後續上層協作方式。

### 關於 Reaction / CRUD 的實作原則

只在父類 `Reaction` 中不存在的 action 才應額外實作。例如：

- `do_list`、`do_save`、`do_delete` 等常見 CRUD 行為，通常由父類提供共用實作；
- 若某模組的實際需求明確需要自訂邏輯，才在子類補上專屬 method。
- 不要因為「想先快速做出功能」就直接在 `rMobile` 補一份全新的 `do_list` / `do_save` / `do_delete`，而忽略既有共用 Reaction boundary。

這一原則的目的是保持：
- UI 只負責模板與表單交互
- request orchestration 保持在 `Reaction`
- 實體資料屬於 `Feed` / owner module
- 只有真正缺失的業務邏輯才補在特定 module

## 第一類 - 搜尋元件

### 元件定位
這是 Gene Panel 後台/管理頁面中最常見的第一類 HTML 元件：搜尋 / 篩選條（search bar / filter bar）。

它的核心目的是讓列表頁可以快速做到：
- 依狀態切換：全部 / 已發佈 / 草稿 / 排程中 / 已下架
- 依欄位查詢：標題 / 內容 / 編號 / 標籤 / 作者
- 依關鍵字搜尋：輸入關鍵字後觸發查詢
- 保存查詢條件：將條件以 tag 形式呈現，方便再次查看與重設

這個元件並不是單一頁面的特例，而是整個 `www/tmpls` 目錄最常重用的 UI 模式之一。

### 核心模板
這是完整的搜尋元件範本，出現在 `www/tmpls/press/list.html`，也是本類元件最標準的版本：

```html
<nav class="list-filter level">
  <div class="level-left">
    <div class="level-item">
      <div class="control">
        <div class="select">
          <select class="dropdownQuery gee" data-gene="change:dropdownQuery">
            <option value="">全部狀態</option>
            <option value="m.status=Published">已發佈</option>
            <option value="m.status=Draft">草稿</option>
            <option value="m.status=Scheduled">排程中</option>
            <option value="m.status=Offlined">已下架</option>
          </select>
        </div>
      </div>
    </div>
    <div class="level-item query-box">
      <p class="control">
        <div class="select" >
          <select name="query" class="gee" data-gene="change:checkOption">
            <optgroup label="資料">
              <option value="l.title~">文章標題</option>
              <option value="l.content~">文章內文</option>
              <option value="m.id:">文章編號</option>
              <option value="tag:">標籤</option>
              <option value="author:">作者</option>
            </optgroup>
          </select>
        </div>
      </p>
    </div>
    <div class="level-item">
      <div class="field has-addons">
        <p class="control">
          <input class="input" type="text" placeholder="Find a option">
        </p>
        <p class="control">
          <button class="button is-expanded gee" data-gene="init:initQueryForm,click:combineQuery" type="button">查詢</button>
        </p>
      </div>
    </div>
    <p class="level-item is-hidden">搜尋條件：</p>
    <div class="tags js-query-list level-item"></div>
  </div>
</nav>
```

### 元件拆解

#### 狀態篩選區
```html
<select class="dropdownQuery gee" data-gene="change:dropdownQuery">
  <option value="">全部狀態</option>
  <option value="m.status=Published">已發佈</option>
  <option value="m.status=Draft">草稿</option>
  <option value="m.status=Scheduled">排程中</option>
  <option value="m.status=Offlined">已下架</option>
</select>
```

用途：
- 快速切換列表狀態
- 直接拼接查詢條件，例如 `m.status=Published`
- 常見於文章 / 聯絡 / 會員等管理頁

#### 欄位選擇器
```html
<select name="query" class="gee" data-gene="change:checkOption">
  <optgroup label="資料">
    <option value="l.title~">文章標題</option>
    <option value="l.content~">文章內文</option>
    <option value="m.id:">文章編號</option>
    <option value="tag:">標籤</option>
    <option value="author:">作者</option>
  </optgroup>
</select>
```

用途：
- 指定要查詢哪個欄位
- 例如 `title`, `content`, `id`, `tag`, `author`
- 這個 `name="query"` 是基礎搜尋條件組成的入口

#### 關鍵字輸入區
```html
<input class="input" type="text" placeholder="Find a option">
```

用途：
- 接收使用者輸入的關鍵字
- 通常與欄位選擇器搭配使用
- 值不會直接送出，需由 `combineQuery` 觸發

#### 提交搜尋
```html
<button class="button is-expanded gee" data-gene="init:initQueryForm,click:combineQuery" type="button">查詢</button>
```

用途：
- 啟動查詢條件組裝
- 將 `dropdownQuery` + `query` + `input` 合併成一組查詢字串
- 常會在點擊後生成 tag 條件

#### 查詢條件標籤
```html
<div class="tags js-query-list level-item"></div>
```

用途：
- 顯示目前已使用的搜尋條件
- 讓使用者知道目前在查哪些資料
- 使用者可直接看到「已套用條件」而不是只看結果表格

### 行為語意
這類元件大多依賴 `data-gene` 事件：

- `change:dropdownQuery`
  - 狀態下拉選單發生變更時觸發
  - 例如切換「已發佈」「草稿」

- `change:checkOption`
  - 改變查詢欄位時觸發
  - 例如從「文章標題」切到「作者」

- `init:initQueryForm`
  - 初始化查詢表單狀態

- `click:combineQuery`
  - 取得目前的狀態與關鍵字，組合查詢條件並送出

- `js-query-list`
  - 顯示已套用條件 tag 列表

### 所有應用位置
已掃描出這個搜尋元件在 `www/tmpls` 內的實際應用，總共 21 個檔案：

- `www/tmpls/adv/list.html`
- `www/tmpls/author/list.html`
- `www/tmpls/category/simple.html`
- `www/tmpls/contact/simple.html`
- `www/tmpls/contrib/list.html`
- `www/tmpls/dictionary/list.html`
- `www/tmpls/draft/list.html`
- `www/tmpls/edm/list.html`
- `www/tmpls/genus/simple.html`
- `www/tmpls/media/gallery.html`
- `www/tmpls/meta/list.html`
- `www/tmpls/post/list.html`
- `www/tmpls/press/list.html`
- `www/tmpls/shorten/simple.html`
- `www/tmpls/staff/simple.html`
- `www/tmpls/stats/simple.html`
- `www/tmpls/stream/simple.html`
- `www/tmpls/subscription/simple.html`
- `www/tmpls/tag/simple.html`
- `www/tmpls/webhook/simple.html`
- `www/tmpls/yell/simple.html`

這表示它不是某單一模組專屬元件，而是全站共用的 list-page search pattern。

### 典型應用場景

#### 文章類型列表
例如：
- [www/tmpls/press/list.html](../../www/tmpls/press/list.html)
- [www/tmpls/post/list.html](../../www/tmpls/post/list.html)
- [www/tmpls/draft/list.html](../../www/tmpls/draft/list.html)

這類頁面可查：
- 狀態：已發佈 / 草稿 / 排程 / 下架
- 關鍵字：標題 / 內容 / 編號 / 標籤 / 作者

#### 後台資料管理列表
例如：
- [www/tmpls/author/list.html](../../www/tmpls/author/list.html)
- [www/tmpls/category/simple.html](../../www/tmpls/category/simple.html)
- [www/tmpls/meta/list.html](../../www/tmpls/meta/list.html)
- [www/tmpls/tag/simple.html](../../www/tmpls/tag/simple.html)

這類頁面通常是：
- 先選狀態，例如啟用 / 未啟用
- 再選查詢欄位，例如名稱 / URL / 編號
- 最後輸入關鍵字進行查詢

#### 會員 / 訊息 / 互動型列表
例如：
- [www/tmpls/contact/simple.html](../../www/tmpls/contact/simple.html)
- [www/tmpls/staff/simple.html](../../www/tmpls/staff/simple.html)
- [www/tmpls/subscription/simple.html](../../www/tmpls/subscription/simple.html)
- [www/tmpls/webhook/simple.html](../../www/tmpls/webhook/simple.html)

這類頁面常見：
- 狀態篩選（New / Process / Done / Enabled / Disabled）
- 依姓名、Email、標題、類型進行檢索

### 共同規範
這個元件的共同規範很明確：

1. 一律放在 `nav.list-filter level` 內
2. 左邊通常第一個欄位是 `dropdownQuery` 狀態篩選
3. 第二個欄位是 `select[name=query]` 查詢欄位選擇器
4. 第三個欄位是文字輸入框 + 查詢按鈕
5. 最後會有 `div.tags.js-query-list` 顯示目前條件
6. 所有欄位與操作都採用 `gee` + `data-gene` 事件掛載

### 使用建議
如果要沿用這個元件，最穩妥的做法是：

- 狀態下拉用 `dropdownQuery`
- 欄位選擇用 `select[name=query]`
- 關鍵字 input 保持 `input.input`
- 查詢按鈕使用 `data-gene="init:initQueryForm,click:combineQuery"`
- 條件展示區用 `.tags.js-query-list`

### 結論
這個搜尋元件可以視為 Gene Panel 後台最基本、最常用的 UITable filter pattern。

它的特徵是：
- 低耦合
- 一致性高
- 便於跨模組重用
- 可直接支援狀態篩選 + 關鍵字搜查 + 條件回顯

因此，若要新增新的後台列表頁，最直接的做法就是直接套用這個元件骨架，而不是重新設計一套查詢 UI。

## 第二類 - 清單元件（List Item / Table Row）

### 元件定位
第二類元件是列表內容本體，也就是資料列表 row 的渲染模板。它通常不會自己決定「怎麼查」，而是接收 `loadList` 載入的資料後，將每一筆資料渲染成一列 `tr`。

這類元件的定位是：
- 列出資料的主要內容
- 讓每一筆資料在列表中具體呈現
- 提供單筆操作，例如編輯 / 查看 / 預覽 / 更多動作
- 常常直接承接 `data-tmpl="...List"` 的 response data

它是 Gene Panel 後台最核心的展示元件之一，幾乎所有資料管理頁面都會用到。

### 核心模板
這是最完整的展示型列表 row 範本，出自 [www/tmpls/press/list.html](../../www/tmpls/press/list.html)：

```html
<tbody class="gee" data-gene="init:loadList,click:reactList" data-tmpl="pressList" data-nopde="1">
  <tr>
    <td><figure class="image is-marginless"> <img pre-src="{{:~loadPic(prop.cover, 'sm')}}" onerror="app.defaultPic()" > </figure></td>
    <td>
      {{if prop.status == 'Published' }}
      <a href="{{:~fixLink('p/'+prop.id+'/'+prop.slug)}}" target="_blank" class="is-pulled-right"> 查看 <span class="icon"><i class="fa fa-share-square-o"></i></span> </a>
      {{else}}
      <a href="{{:~fixLink('tw/preview/p/'+prop.id)}}" target="_blank" class="is-pulled-right"> 預覽 <span class="icon"><i class="fa fa-share-square-o"></i></span> </a>
      {{/if}}
      <div>
        <a href="javascript:;" data-func="press.loadRow" data-tmpl="pressForm" data-src="editor" data-id="{{:prop.id}}" class="line-clamp press-title engrossed-btn" title="{{:prop.title}}">#{{:prop.id}} {{:prop.title}} <span class="icon"><i class="fa fa-pencil"></i></span></a>
      </div>
      <div>{{:~formatDate(prop.online_date, 'YY-MM-DD HH:mm')}}
        <span class="tag {{if prop.status == 'Scheduled' || prop.status == 'Draft' }}is-warning{{/if}}">
          {{:~txtLabel(prop.status, {'Published': '已發佈', 'Draft': '草稿', 'Scheduled': '排程中', 'Offlined': '已下架'})}}</span>
      </div>
    </td>
    <td class="is-hidden-mobile"><div class="ellipsis" style="width: 80px;">{{props prop.authors}}
          {{if #getIndex() != 0 }} & {{/if}}
          <a href="javascript:;" data-func="loadQuery" data-query="author:{{:prop.id}}" data-mode="Add" class="author-id"> {{:prop.title}} </a>
        {{/props}}</div></td>
    <td>
      <div class="tags"> <span class="tag is-warning"> {{:prop.category}} </span> {{props prop.tags}} <span class="tag is-info"> {{:prop.title}} </span> {{/props}} </div>
      <nav class="navbar is-right is-transparent" role="navigation" aria-label="dropdown navigation">
        <div class="navbar-item has-dropdown has-dropdown-up is-hoverable">
          <a class="navbar-link is-arrowless"><span class="icon"><i class="fa fa-cog"></i></span></a>
          <div class="navbar-dropdown is-boxed is-right is-arrow">
            <a class="navbar-item" href="javascript:;" data-func="arena/touch" data-confirm="建文章廣告？ 點擊【確定】後請至廣告頁完成設定!!" data-endpoint="adv/push" data-params='{"pid":"{{:prop.id}}"}'> 廣告推播 </a>
            <a class="navbar-item" href="javascript:;" data-func="arena/touch" data-confirm="建立 SEO 草稿？ 點擊【確定】後請至草稿頁查看!!" data-endpoint="draft/genSeo" data-params='{"pid":"{{:prop.id}}"}'> SEO 助手 </a>
            <a class="navbar-item" href="javascript:;" data-func="arena/touch" data-confirm="建立翻譯草稿？ 點擊【確定】後請至草稿頁查看!!" data-endpoint="draft/genI18n" data-params='{"pid":"{{:prop.id}}","original":"tw"}'> 翻譯助手 </a>
          </div>
        </div>
      </nav>
    </td>
  </tr>
</tbody>
```

### 元件拆解

#### 1) 首圖 / 封面欄位
```html
<td><figure class="image is-marginless"><img pre-src="{{:~loadPic(prop.cover, 'sm')}}" onerror="app.defaultPic()"></figure></td>
```

用途：
- 顯示列表項目的縮圖
- 常見於文章 / 產品 / 封面型資料
- 支援 `cover` 欄位產生預覽圖

#### 2) 主標題 + 狀態 + 外部連結
```html
<div>
  <a href="javascript:;" data-func="press.loadRow" data-tmpl="pressForm" data-src="editor" data-id="{{:prop.id}}" class="line-clamp press-title engrossed-btn">
    #{{:prop.id}} {{:prop.title}}
  </a>
</div>
<div>{{:~formatDate(prop.online_date, 'YY-MM-DD HH:mm')}}
  <span class="tag {{if prop.status == 'Scheduled' || prop.status == 'Draft' }}is-warning{{/if}}">
    {{:~txtLabel(prop.status, {'Published': '已發佈', 'Draft': '草稿', 'Scheduled': '排程中', 'Offlined': '已下架'})}}
  </span>
</div>
```

用途：
- 呈現主資訊：標題、時間、狀態
- `data-func="press.loadRow"` 通常會打開編輯 modal
- `fixLink` 可用來產生前台預覽連結

#### 3) 作者 / 關聯資料欄位
```html
<td class="is-hidden-mobile">
  <div class="ellipsis" style="width: 80px;">
    {{props prop.authors}}
      {{if #getIndex() != 0 }} & {{/if}}
      <a href="javascript:;" data-func="loadQuery" data-query="author:{{:prop.id}}" data-mode="Add" class="author-id"> {{:prop.title}} </a>
    {{/props}}
  </div>
</td>
```

用途：
- 顯示關聯對象，如作者、成員、標籤物件
- 常與 `loadQuery` 組合成「點一下即篩選」的動作

#### 4) 分類 / 標籤欄位
```html
<div class="tags">
  <span class="tag is-warning"> {{:prop.category}} </span>
  {{props prop.tags}}
    <span class="tag is-info"> {{:prop.title}} </span>
  {{/props}}
</div>
```

用途：
- 顯示分類與標籤
- 讓一列內容在一眼之內有「主題 + 分類 + 標籤」資訊

#### 5) 更多操作 menu
```html
<nav class="navbar is-right is-transparent" role="navigation" aria-label="dropdown navigation">
  <div class="navbar-item has-dropdown has-dropdown-up is-hoverable">
    <a class="navbar-link is-arrowless"><span class="icon"><i class="fa fa-cog"></i></span></a>
    <div class="navbar-dropdown is-boxed is-right is-arrow">
      <a class="navbar-item" href="javascript:;" data-func="arena/touch" data-endpoint="adv/push"> 廣告推播 </a>
      <a class="navbar-item" href="javascript:;" data-func="arena/touch" data-endpoint="draft/genSeo"> SEO 助手 </a>
      <a class="navbar-item" href="javascript:;" data-func="arena/touch" data-endpoint="draft/genI18n"> 翻譯助手 </a>
    </div>
  </div>
</nav>
```

用途：
- 在每一筆資料後方放置快速操作
- 這是列表頁常見的「更多操作」模式
- 適合接續進階流程：廣告、SEO、翻譯、匯出等

### 行為語意
這類 `tbody` 的常見 `data-gene` 行為：

- `init:loadList`
  - 初始化時從後端載入資料列表

- `click:reactList`
  - 列表項目被點擊時觸發互動

- `data-func="loadRow"` / `data-func="press.loadRow"`
  - 進入編輯 modal

- `data-func="loadQuery"`
  - 將某個欄位值轉成 query 條件

- `data-func="arena/touch"`
  - 觸發一個後續流程，如廣告 / SEO / 翻譯

### 實際應用位置
已掃描出這種「表格型資料列」放在以下模組：

- [www/tmpls/press/list.html](../../www/tmpls/press/list.html)
- [www/tmpls/post/list.html](../../www/tmpls/post/list.html)
- [www/tmpls/contact/simple.html](../../www/tmpls/contact/simple.html)
- [www/tmpls/category/simple.html](../../www/tmpls/category/simple.html)
- [www/tmpls/draft/list.html](../../www/tmpls/draft/list.html)
- [www/tmpls/meta/list.html](../../www/tmpls/meta/list.html)
- [www/tmpls/edm/list.html](../../www/tmpls/edm/list.html)
- [www/tmpls/genus/simple.html](../../www/tmpls/genus/simple.html)
- [www/tmpls/shorten/simple.html](../../www/tmpls/shorten/simple.html)
- [www/tmpls/staff/simple.html](../../www/tmpls/staff/simple.html)
- [www/tmpls/subscription/simple.html](../../www/tmpls/subscription/simple.html)
- [www/tmpls/stream/simple.html](../../www/tmpls/stream/simple.html)
- [www/tmpls/yell/simple.html](../../www/tmpls/yell/simple.html)
- [www/tmpls/contrib/list.html](../../www/tmpls/contrib/list.html)
- [www/tmpls/webhook/simple.html](../../www/tmpls/webhook/simple.html)
- [www/tmpls/role/simple.html](../../www/tmpls/role/simple.html)

另外也有卡片型延伸版本，例如：
- [www/tmpls/author/list.html](../../www/tmpls/author/list.html)
- [www/tmpls/media/gallery.html](../../www/tmpls/media/gallery.html)
- [www/tmpls/tag/simple.html](../../www/tmpls/tag/simple.html)

這些位於同一類列表展示模式的不同呈現方式。

### 常見應用場景

#### 文章 / 內容管理
- 文章標題、狀態、發布時間、作者、標籤
- 具備前台連結與預覽連結
- 常見於 [www/tmpls/press/list.html](../../www/tmpls/press/list.html) 與 [www/tmpls/post/list.html](../../www/tmpls/post/list.html)

#### 資料表管理
- ID、名稱、分類、狀態、說明、編輯操作
- 常見於 [www/tmpls/category/simple.html](../../www/tmpls/category/simple.html) 與 [www/tmpls/meta/list.html](../../www/tmpls/meta/list.html)

#### 會員 / 訊息 / 訂閱
- 姓名、Email、狀態、最後更新時間、操作列
- 常見於 [www/tmpls/contact/simple.html](../../www/tmpls/contact/simple.html) 與 [www/tmpls/staff/simple.html](../../www/tmpls/staff/simple.html)

### 規範特徵
這種列表行元件通常具備以下一致性：

1. `tbody.gee` 負責資料渲染
2. `data-gene="init:loadList,click:reactList"` 為標準掛載方式
3. 一列資料固定以 `tr` 包裝，用 `td` 分欄
4. 第一欄常是封面 / 圖片 / 狀態
5. 第二欄是主要資訊（標題、時間、狀態）
6. 後續欄位放作者、分類、標籤、操作
7. 操作列常出現 `data-func` 與 `data-endpoint` 的功能入口

### 建議套用方式
若要新建一個列表頁，最直接的套用方式是：

- 先保留 `tbody.gee` 與 `data-gene` 結構
- 依欄位實際需求排序：封面 → 標題/狀態 → 作者/分類 → 操作
- 讓 `tr` 的各欄位保留一致的資訊密度
- 將所有單筆操作維持在 `data-func` / `data-endpoint` 的命名方式

### 結論
第二類元件是 Gene Panel 列表頁的核心內容層。它不只是「表格」而已，而是每一筆資料的實際展示與最終操作入口。

它的特徵是：
- 以 `tbody` 和 `tr` 為實體結構
- 以 `data-gene` 驅動動態載入與行為回應
- 以欄位分工呈現封面、標題、狀態、作者、標籤與操作
- 以 `data-func` 提供單筆編輯 / 查看 / 進階流程

如果說第一類元件是「查詢入口」，那第二類元件就是「資料展示與操作主體」。

## 第三類 - 欄位元件（Form Field）

### 元件定位
第三類元件是新增、修改與設定畫面中的資料輸入欄位。與第一類搜尋元件不同，本節**不包含** `nav.list-filter`、`dropdownQuery`、`select[name="query"]` 與列表搜尋輸入框。

欄位元件的共同外層通常是：

```html
<div class="field">
  <label class="label">欄位名稱</label>
  <p class="control">
    <!-- input、textarea 或 Gee 自訂欄位 -->
  </p>
</div>
```

其中 `name` 或 `data-param` 是資料綁定鍵；`label`、`placeholder`、`info-text` 則是介面提示，不應當作資料鍵。

### 文字欄位（Text input）

```html
<div class="field">
  <p class="control">
    <input class="input" name="lang[tw][title]" type="text" placeholder="Title" maxwidth="70">
  </p>
</div>
```

用途：
- 輸入短文字，如標題、網址 slug、名稱、職稱、Slogan、Email、帳號、排序與權重。
- 多語系資料以 `lang[語系][欄位]` 命名，例如 `lang[tw][title]`。
- URL、密碼、Email、數字、日期時間亦使用原生 `input`，只改變 `type`。

常見變體：

```html
<input class="input" name="uri" type="text" placeholder="輸入完整網址">
<input class="password input" name="pwd" type="password" autocomplete="new-password">
<input class="input" name="email" type="email" placeholder="Email">
<input type="datetime-local" class="datetime-local" name="start_date" required>
```

實際應用：
- 多語系標題與內容屬性：[www/tmpls/press/editor.html](../../www/tmpls/press/editor.html)、[www/tmpls/author/modal.html](../../www/tmpls/author/modal.html)、[www/tmpls/adv/editor.html](../../www/tmpls/adv/editor.html)
- 帳號、密碼、Email、備註：[www/tmpls/staff/editor.html](../../www/tmpls/staff/editor.html)
- 聯絡與帳號資料：[www/tmpls/contact/modal.html](../../www/tmpls/contact/modal.html)、[www/tmpls/staff/editor.html](../../www/tmpls/staff/editor.html)、[www/tmpls/staff/mine.html](../../www/tmpls/staff/mine.html)、[www/tmpls/login-modal.html](../../www/tmpls/login-modal.html)、[www/tmpls/register-modal.html](../../www/tmpls/register-modal.html)
- 分類、選單、字典與設定資料：[www/tmpls/category/simple.html](../../www/tmpls/category/simple.html)、[www/tmpls/menu/simple.html](../../www/tmpls/menu/simple.html)、[www/tmpls/dictionary/list.html](../../www/tmpls/dictionary/list.html)、[www/tmpls/option/simple.html](../../www/tmpls/option/simple.html)、[www/tmpls/genus/simple.html](../../www/tmpls/genus/simple.html)、[www/tmpls/role/simple.html](../../www/tmpls/role/simple.html)、[www/tmpls/stats/mine.html](../../www/tmpls/stats/mine.html)
- 其他內容管理表單：[www/tmpls/draft/modal.html](../../www/tmpls/draft/modal.html)、[www/tmpls/draft/new.html](../../www/tmpls/draft/new.html)、[www/tmpls/edm/modal.html](../../www/tmpls/edm/modal.html)、[www/tmpls/media/modal.html](../../www/tmpls/media/modal.html)、[www/tmpls/meta/modal.html](../../www/tmpls/meta/modal.html)、[www/tmpls/post/modal.html](../../www/tmpls/post/modal.html)、[www/tmpls/press/media.html](../../www/tmpls/press/media.html)、[www/tmpls/shorten/simple.html](../../www/tmpls/shorten/simple.html)、[www/tmpls/subscription/simple.html](../../www/tmpls/subscription/simple.html)、[www/tmpls/tag/modal.html](../../www/tmpls/tag/modal.html)

### 多行文字欄位（Textarea）

```html
<div class="field">
  <label class="label">簡介</label>
  <p class="control">
    <textarea name="lang[tw][summary]" class="textarea" placeholder="一百字內之簡介"></textarea>
  </p>
</div>
```

用途：
- 輸入摘要、說明、備註、純文字內容與短文案。
- 適合不需要 HTML 格式化工具列的內容。

實際應用：
- 多語系摘要或簡介：[www/tmpls/press/editor.html](../../www/tmpls/press/editor.html)、[www/tmpls/author/modal.html](../../www/tmpls/author/modal.html)、[www/tmpls/adv/editor.html](../../www/tmpls/adv/editor.html)、[www/tmpls/edm/modal.html](../../www/tmpls/edm/modal.html)
- 基礎資料與描述：[www/tmpls/category/simple.html](../../www/tmpls/category/simple.html)、[www/tmpls/contact/modal.html](../../www/tmpls/contact/modal.html)、[www/tmpls/dictionary/list.html](../../www/tmpls/dictionary/list.html)、[www/tmpls/genus/simple.html](../../www/tmpls/genus/simple.html)、[www/tmpls/menu/simple.html](../../www/tmpls/menu/simple.html)、[www/tmpls/meta/modal.html](../../www/tmpls/meta/modal.html)、[www/tmpls/option/simple.html](../../www/tmpls/option/simple.html)、[www/tmpls/role/simple.html](../../www/tmpls/role/simple.html)、[www/tmpls/shorten/simple.html](../../www/tmpls/shorten/simple.html)、[www/tmpls/tag/modal.html](../../www/tmpls/tag/modal.html)
- 草稿、媒體與文章輔助資料：[www/tmpls/draft/modal.html](../../www/tmpls/draft/modal.html)、[www/tmpls/draft/new.html](../../www/tmpls/draft/new.html)、[www/tmpls/media/modal.html](../../www/tmpls/media/modal.html)、[www/tmpls/press/media.html](../../www/tmpls/press/media.html)

### HTML 編輯器欄位（`gee:editor`）

```html
<div class="field">
  <p class="control">
    <gee:editor data-param="lang[ko][content]" data-inline="0"></gee:editor>
  </p>
</div>
```

用途：
- 編輯需要 HTML 格式的長文內容。
- `data-param` 是內容欄位資料鍵；`data-inline="0"` 表示使用區塊型而非 inline 編輯模式。
- 應使用於文章內文、作者介紹、EDM 內容等，而不是摘要欄位。

實際應用：
- [www/tmpls/press/editor.html](../../www/tmpls/press/editor.html)
- [www/tmpls/author/modal.html](../../www/tmpls/author/modal.html)
- [www/tmpls/edm/modal.html](../../www/tmpls/edm/modal.html)
- [www/tmpls/post/modal.html](../../www/tmpls/post/modal.html)

### 拖放上傳欄位（`gee-uploadDnD`）

```html
<gee-uploadDnD module-name="press" multiple="true" data-param="banner" info-text="最大寬度 1440px"></gee-uploadDnD>
```

用途：
- 以 drag-and-drop 上傳一或多個檔案。
- `module-name` 指定所屬模組；`data-param` 指定儲存欄位；`multiple="true"` 允許多檔。
- `info-text` 用於顯示檔案尺寸或規格提示。

實際應用：
- [www/tmpls/press/editor.html](../../www/tmpls/press/editor.html)

### Suggestion 欄位（`multipleSelect`）

```html
<div class="field no-kol">
  <label class="label">作者</label>
  <div class="control">
    <input type="text" multiple class="multipleSelect" data-sortable="1" name="authors" placeholder="請輸入字詞查詢" data-url="author/get_opts">
  </div>
</div>
```

用途：
- `multipleSelect` 是 Suggestion 欄位：使用者輸入關鍵字後，從 `data-url` 的候選資料中選擇關聯項目。
- 有 `multiple` 屬性時為**多選**；未設定 `multiple` 時為**單選**。
- `data-sortable="1"` 允許排序已選項目；`name` 是儲存關聯值的鍵。
- 雖有輸入文字行為，但它是**表單關聯欄位**，不是第一類的列表搜尋元件。

實際應用：
- 作者 / 標籤 /推薦文章：[www/tmpls/press/editor.html](../../www/tmpls/press/editor.html)、[www/tmpls/author/modal.html](../../www/tmpls/author/modal.html)、[www/tmpls/post/modal.html](../../www/tmpls/post/modal.html)、[www/tmpls/tag/modal.html](../../www/tmpls/tag/modal.html)
- 分類、選單與 meta 關聯：[www/tmpls/category/simple.html](../../www/tmpls/category/simple.html)、[www/tmpls/menu/simple.html](../../www/tmpls/menu/simple.html)、[www/tmpls/meta/modal.html](../../www/tmpls/meta/modal.html)
- 草稿關聯：[www/tmpls/draft/modal.html](../../www/tmpls/draft/modal.html)

### 模組選項下拉欄位（`gee:set-option`）

```html
<div class="field">
  <label class="label">分類</label>
  <p class="control">
    <span class="select"><gee:set-option module="category" name="cate_id" params='{"group":"press"}'></gee:set-option></span>
  </p>
</div>
```

用途：
- 動態載入其他模組的資料，作為單選下拉選項。
- `module` 是來源模組；`name` 是選取值欄位；`params` 可限制來源資料，例如分類群組。
- 適合分類、角色、版位、父節點與其他外鍵欄位。

實際應用：
- [www/tmpls/press/editor.html](../../www/tmpls/press/editor.html)
- [www/tmpls/adv/editor.html](../../www/tmpls/adv/editor.html)
- [www/tmpls/menu/simple.html](../../www/tmpls/menu/simple.html)
- [www/tmpls/meta/modal.html](../../www/tmpls/meta/modal.html)
- [www/tmpls/role/simple.html](../../www/tmpls/role/simple.html)
- [www/tmpls/staff/editor.html](../../www/tmpls/staff/editor.html)
- [www/tmpls/tag/simple.html](../../www/tmpls/tag/simple.html)

### 圖片 / 檔案上傳欄位（`gee-upload`）

```html
<div class="field">
  <label class="label">文章單頁大圖</label>
  <gee-upload module-name="press" data-param="banner" info-text="1600x900"></gee-upload>
</div>
```

用途：
- 上傳單一圖片或檔案，常用於封面、Banner、人物照與媒體素材。
- `module-name` 應與 owner module 一致；`data-param` 對應資料欄位；`info-text` 宣告建議尺寸。
- 若需多檔拖放，使用 `gee-uploadDnD`，不要以此欄位取代。

實際應用：
- 文章與固定頁：[www/tmpls/press/editor.html](../../www/tmpls/press/editor.html)、[www/tmpls/post/modal.html](../../www/tmpls/post/modal.html)、[www/tmpls/press/media.html](../../www/tmpls/press/media.html)
- 作者、廣告與媒體：[www/tmpls/author/modal.html](../../www/tmpls/author/modal.html)、[www/tmpls/adv/editor.html](../../www/tmpls/adv/editor.html)、[www/tmpls/media/modal.html](../../www/tmpls/media/modal.html)
- 分類、字典與標籤：[www/tmpls/category/simple.html](../../www/tmpls/category/simple.html)、[www/tmpls/dictionary/list.html](../../www/tmpls/dictionary/list.html)、[www/tmpls/tag/modal.html](../../www/tmpls/tag/modal.html)

### 單選欄位（Radio）

```html
<div class="field">
  <label class="label">狀態</label>
  <input type="radio" class="is-checkradio" name="status" value="Enabled" id="status-enabled">
  <label class="radio" for="status-enabled">啟用</label>
  <input type="radio" class="is-checkradio" name="status" value="Disabled" id="status-disabled">
  <label class="radio" for="status-disabled">停用</label>
</div>
```

用途：
- 在互斥選項中選擇一項，例如狀態、是否 AI 產生、可見性或寄送狀態。
- 同一組選項必須共用相同 `name`，每個 `id` 必須唯一並由 label 的 `for` 對應。

實際應用：
- 狀態及多語系 AI 標記：[www/tmpls/press/editor.html](../../www/tmpls/press/editor.html)、[www/tmpls/author/modal.html](../../www/tmpls/author/modal.html)、[www/tmpls/adv/editor.html](../../www/tmpls/adv/editor.html)
- 內容與設定表單：[www/tmpls/category/simple.html](../../www/tmpls/category/simple.html)、[www/tmpls/contact/modal.html](../../www/tmpls/contact/modal.html)、[www/tmpls/dictionary/list.html](../../www/tmpls/dictionary/list.html)、[www/tmpls/draft/modal.html](../../www/tmpls/draft/modal.html)、[www/tmpls/draft/new.html](../../www/tmpls/draft/new.html)、[www/tmpls/edm/modal.html](../../www/tmpls/edm/modal.html)、[www/tmpls/genus/simple.html](../../www/tmpls/genus/simple.html)、[www/tmpls/media/modal.html](../../www/tmpls/media/modal.html)、[www/tmpls/menu/simple.html](../../www/tmpls/menu/simple.html)、[www/tmpls/meta/modal.html](../../www/tmpls/meta/modal.html)、[www/tmpls/option/simple.html](../../www/tmpls/option/simple.html)、[www/tmpls/post/modal.html](../../www/tmpls/post/modal.html)、[www/tmpls/press/media.html](../../www/tmpls/press/media.html)、[www/tmpls/role/simple.html](../../www/tmpls/role/simple.html)、[www/tmpls/shorten/simple.html](../../www/tmpls/shorten/simple.html)、[www/tmpls/staff/editor.html](../../www/tmpls/staff/editor.html)、[www/tmpls/subscription/simple.html](../../www/tmpls/subscription/simple.html)、[www/tmpls/tag/simple.html](../../www/tmpls/tag/simple.html)

### 其他原生欄位

#### Checkbox
用於可複選或布林設定；例如「記住帳號密碼」與 EDM 寄送選取。

實際應用：
- [www/tmpls/login-modal.html](../../www/tmpls/login-modal.html)
- [www/tmpls/edm/sent.html](../../www/tmpls/edm/sent.html)
- [www/tmpls/role/simple.html](../../www/tmpls/role/simple.html)

#### Hidden input
用於傳遞不讓使用者直接修改的資料鍵，例如 `id`、`parent_id`、`group`；不應取代可編輯欄位。

實際應用：幾乎所有新增/修改表單都包含 `name="id"`，例如 [www/tmpls/press/editor.html](../../www/tmpls/press/editor.html)、[www/tmpls/author/modal.html](../../www/tmpls/author/modal.html)、[www/tmpls/staff/editor.html](../../www/tmpls/staff/editor.html)、[www/tmpls/tag/modal.html](../../www/tmpls/tag/modal.html)。

#### Meta 編輯器
`gee:meta-editor` 是模組擴充 metadata 的自訂欄位容器，出現在 [www/tmpls/adv/editor.html](../../www/tmpls/adv/editor.html)。

### 欄位組裝規範

1. 每個可見欄位以 `div.field` 包裝。
2. 有欄位名稱時使用 `label.label`；每個 label 應清楚說明使用者可輸入的資料。
3. 原生欄位使用 `name`，Gee 自訂欄位依元件使用 `data-param` 或 `name`。
4. 多語系欄位維持 `lang[locale][field]` 命名，不混用其他結構。
5. 關聯單選用 `gee:set-option`；Suggestion 欄位用 `multipleSelect`，以 `multiple` 屬性決定單選或多選。
6. 單檔上傳用 `gee-upload`；多檔拖放才用 `gee-uploadDnD`。
7. 摘要用 `textarea`，需要 HTML 結構化內容才用 `gee:editor`。
8. radio 的同組 `name` 相同，但每個 `id` 必須唯一；不要複製既有元件後保留重複 `id`。

### 結論
第三類欄位元件負責將表單 UI 對應到模組資料欄位。選擇欄位類型時，應依資料所有權與資料形態決定：短文字用 `input`、摘要用 `textarea`、HTML 長文用 `gee:editor`、關聯資料用 `multipleSelect` 或 `gee:set-option`、媒體用 `gee-upload` 或 `gee-uploadDnD`。

## 第四類 - 按鈕元件（Button / Action）

### 元件定位
按鈕元件是列表、表單與 modal 的動作入口。原生 `<button>` 與具備 `button` / `btn` class 的 `<a>` 都可能承擔按鈕角色；實際行為由 `data-gene`、`data-func` 或 `data-endpoint` 定義。

```html
<button type="button" class="button is-primary pre-gee" data-gene="click:setRow">送出</button>
<a href="javascript:;" class="button is-info" data-func="loadRow" data-tmpl="postForm" data-src="modal" data-id="{{:prop.id}}">編輯</a>
```

- `button` / `btn`：視覺按鈕樣式。
- `type="button"`：避免在表單內意外觸發原生 submit。
- `gee` / `pre-gee`：由 Gene event handler 掛載行為。
- `data-gene`：以事件名稱指定動作。
- `data-func`：由列表或模組行為處理單筆動作。
- `data-endpoint`：指定後續 API/流程端點；常搭配 `data-confirm` 與 `data-params`。

### 新增與開啟按鈕

```html
<a class="button is-primary modal-btn gee" data-gene="click:showModal" data-tmpl="postForm" data-src="modal" data-size="lg" data-id="0">新增</a>
```

用途：
- 建立新資料，通常以 `data-id="0"` 表示新增模式。
- 開啟 modal 或 editor，並用 `data-tmpl` 指定表單模板、`data-src` 指定載入目標。

實際應用：
- [www/tmpls/post/list.html](../../www/tmpls/post/list.html)
- [www/tmpls/author/list.html](../../www/tmpls/author/list.html)
- [www/tmpls/press/list.html](../../www/tmpls/press/list.html)
- [www/tmpls/category/simple.html](../../www/tmpls/category/simple.html)
- [www/tmpls/adv/list.html](../../www/tmpls/adv/list.html)
- [www/tmpls/draft/list.html](../../www/tmpls/draft/list.html)
- [www/tmpls/edm/list.html](../../www/tmpls/edm/list.html)
- [www/tmpls/meta/list.html](../../www/tmpls/meta/list.html)
- [www/tmpls/media/gallery.html](../../www/tmpls/media/gallery.html)
- [www/tmpls/staff/simple.html](../../www/tmpls/staff/simple.html)
- [www/tmpls/tag/simple.html](../../www/tmpls/tag/simple.html)

### 儲存、取消與重設按鈕

```html
<div class="field is-grouped">
  <p class="control">
    <button type="button" class="button is-primary pre-gee" data-gene="click:setRow">送出</button>
  </p>
  <p class="control">
    <button type="button" class="button pre-gee" data-gene="click:hideModal">取消</button>
  </p>
</div>
```

用途：
- `click:setRow`、`click:setDetailRow`：儲存新增或更新資料。
- `click:press.setRow`、`click:media.setRow`、`click:staff.setMine`：模組專屬儲存。
- `click:hideModal`、`click:cancelForm`：關閉或取消。
- `click:press.reset`、`click:press.flush`：重設或清理文章編輯狀態。

實際應用：所有新增/編輯表單都有這個類型；代表範例為 [www/tmpls/staff/editor.html](../../www/tmpls/staff/editor.html)、[www/tmpls/tag/modal.html](../../www/tmpls/tag/modal.html)、[www/tmpls/author/modal.html](../../www/tmpls/author/modal.html)、[www/tmpls/press/editor.html](../../www/tmpls/press/editor.html)、[www/tmpls/media/modal.html](../../www/tmpls/media/modal.html)。

### 編輯、查看與預覽按鈕

```html
<a href="javascript:;" class="button is-info" data-func="loadRow" data-tmpl="categoryForm" data-id="{{:prop.id}}">編輯</a>
<a href="{{:~fixLink('p/'+prop.id+'/'+prop.slug)}}" target="_blank">查看</a>
```

用途：
- `data-func="loadRow"` 或模組化的 `data-func="press.loadRow"`、`media.loadRow` 開啟指定資料的編輯畫面。
- `fixLink(...)` 生成前台查看或預覽連結；已發布內容與未發布內容可使用不同路徑。

實際應用：
- [www/tmpls/press/list.html](../../www/tmpls/press/list.html)
- [www/tmpls/post/list.html](../../www/tmpls/post/list.html)
- [www/tmpls/category/simple.html](../../www/tmpls/category/simple.html)
- [www/tmpls/contact/simple.html](../../www/tmpls/contact/simple.html)
- [www/tmpls/author/list.html](../../www/tmpls/author/list.html)
- [www/tmpls/edm/list.html](../../www/tmpls/edm/list.html)
- [www/tmpls/meta/list.html](../../www/tmpls/meta/list.html)
- [www/tmpls/media/gallery.html](../../www/tmpls/media/gallery.html)

### 狀態、批次與清單操作按鈕

```html
<button type="button" class="button" data-gene="click:press.online">上線</button>
<button type="button" class="button" data-gene="click:press.offline">下線</button>
<button type="button" class="button" data-gene="click:selAll">全選</button>
```

用途：
- 對單筆或已選資料進行上線、下線、全選、寄送或刪除等動作。
- 刪除動作常使用 `data-func="delRow"`；必須由 UI/handler 提供確認，避免不可逆操作誤觸。

實際應用：
- 文章狀態：[www/tmpls/press/editor.html](../../www/tmpls/press/editor.html)
- EDM 選取與寄送：[www/tmpls/edm/sent.html](../../www/tmpls/edm/sent.html)、[www/tmpls/edm/list.html](../../www/tmpls/edm/list.html)
- 其他資料列表：[www/tmpls/adv/list.html](../../www/tmpls/adv/list.html)、[www/tmpls/contrib/list.html](../../www/tmpls/contrib/list.html)、[www/tmpls/draft/list.html](../../www/tmpls/draft/list.html)

### 進階流程與工具按鈕

```html
<button type="button" class="button is-warning pre-gee" data-gene="click:arena/touch"
  data-confirm="建立 SEO 草稿？" data-endpoint="draft/genSeo" data-params='{"pid":"{{:item.id}}"}'>產生 SEO 資訊</button>
```

用途：
- 觸發非 CRUD 的後續流程，如 AI 翻譯、SEO 草稿、廣告推播與重新載入。
- `data-confirm` 顯示確認訊息；`data-endpoint` 是流程端點；`data-params` 傳入該資料的識別參數。

實際應用：
- AI 翻譯、SEO、廣告與內容工具：[www/tmpls/press/editor.html](../../www/tmpls/press/editor.html)、[www/tmpls/press/list.html](../../www/tmpls/press/list.html)
- EDM 寄送：[www/tmpls/edm/sent.html](../../www/tmpls/edm/sent.html)
- 其他後台工作流：[www/tmpls/draft/new.html](../../www/tmpls/draft/new.html)、[www/tmpls/dashboard/advanced.html](../../www/tmpls/dashboard/advanced.html)

### 登入與前台入口按鈕

```html
<button type="button" class="btn btn-primary submit-btn login-btn gee" data-gene="click:login">登入</button>
<button class="btn facebook-auth-btn"><i class="fa fa-facebook" aria-hidden="true"></i></button>
```

用途：
- 前台表單使用 Bootstrap 風格的 `btn` class，而後台主要使用 Bulma 的 `button` class。
- 登入按鈕以 `click:login` 觸發；社群登入按鈕作為第三方驗證入口。

實際應用：
- [www/tmpls/login-modal.html](../../www/tmpls/login-modal.html)
- [www/tmpls/register-modal.html](../../www/tmpls/register-modal.html)

### 盤點範圍與規範
以 `<button>` 或 `button` / `btn` class 掃描，完整應用位置如下：

- 列表、儀表板與後台工作區：[www/tmpls/adv/list.html](../../www/tmpls/adv/list.html)、[www/tmpls/author/list.html](../../www/tmpls/author/list.html)、[www/tmpls/contact/simple.html](../../www/tmpls/contact/simple.html)、[www/tmpls/contrib/list.html](../../www/tmpls/contrib/list.html)、[www/tmpls/dashboard/advanced.html](../../www/tmpls/dashboard/advanced.html)、[www/tmpls/dashboard/collections.html](../../www/tmpls/dashboard/collections.html)、[www/tmpls/dictionary/list.html](../../www/tmpls/dictionary/list.html)、[www/tmpls/draft/list.html](../../www/tmpls/draft/list.html)、[www/tmpls/edm/list.html](../../www/tmpls/edm/list.html)、[www/tmpls/edm/sent.html](../../www/tmpls/edm/sent.html)、[www/tmpls/media/gallery.html](../../www/tmpls/media/gallery.html)、[www/tmpls/meta/list.html](../../www/tmpls/meta/list.html)、[www/tmpls/post/list.html](../../www/tmpls/post/list.html)、[www/tmpls/press/list.html](../../www/tmpls/press/list.html)、[www/tmpls/staff/simple.html](../../www/tmpls/staff/simple.html)、[www/tmpls/stats/simple.html](../../www/tmpls/stats/simple.html)、[www/tmpls/stream/simple.html](../../www/tmpls/stream/simple.html)、[www/tmpls/subscription/simple.html](../../www/tmpls/subscription/simple.html)、[www/tmpls/tag/simple.html](../../www/tmpls/tag/simple.html)、[www/tmpls/webhook/simple.html](../../www/tmpls/webhook/simple.html)、[www/tmpls/yell/simple.html](../../www/tmpls/yell/simple.html)
- 表單與 modal：[www/tmpls/adv/editor.html](../../www/tmpls/adv/editor.html)、[www/tmpls/author/modal.html](../../www/tmpls/author/modal.html)、[www/tmpls/category/simple.html](../../www/tmpls/category/simple.html)、[www/tmpls/contact/modal.html](../../www/tmpls/contact/modal.html)、[www/tmpls/draft/modal.html](../../www/tmpls/draft/modal.html)、[www/tmpls/draft/new.html](../../www/tmpls/draft/new.html)、[www/tmpls/edm/modal.html](../../www/tmpls/edm/modal.html)、[www/tmpls/genus/simple.html](../../www/tmpls/genus/simple.html)、[www/tmpls/media/modal.html](../../www/tmpls/media/modal.html)、[www/tmpls/menu/simple.html](../../www/tmpls/menu/simple.html)、[www/tmpls/meta/modal.html](../../www/tmpls/meta/modal.html)、[www/tmpls/option/simple.html](../../www/tmpls/option/simple.html)、[www/tmpls/post/modal.html](../../www/tmpls/post/modal.html)、[www/tmpls/press/editor.html](../../www/tmpls/press/editor.html)、[www/tmpls/press/media.html](../../www/tmpls/press/media.html)、[www/tmpls/role/simple.html](../../www/tmpls/role/simple.html)、[www/tmpls/shorten/simple.html](../../www/tmpls/shorten/simple.html)、[www/tmpls/staff/editor.html](../../www/tmpls/staff/editor.html)、[www/tmpls/staff/mine.html](../../www/tmpls/staff/mine.html)、[www/tmpls/stats/mine.html](../../www/tmpls/stats/mine.html)、[www/tmpls/tag/modal.html](../../www/tmpls/tag/modal.html)
- 前台入口：[www/tmpls/login-modal.html](../../www/tmpls/login-modal.html)、[www/tmpls/register-modal.html](../../www/tmpls/register-modal.html)

新增按鈕時，應：

1. 依功能使用 `button` 或具明確按鈕語意的 `<a>`，不要只以一般文字連結承載破壞性操作。
2. 表單非原生送出流程一律加上 `type="button"`。
3. 新增 / 編輯動作明確設定 `data-tmpl`、`data-id` 與必要的 `data-src`。
4. 需要後端工作流的按鈕使用 `data-endpoint`、`data-params`；影響資料的動作加上 `data-confirm`。
5. 不要把 `data-gene` 或 `data-func` 的模組邏輯搬到泛用模板；維持 owner module 的動作命名。
