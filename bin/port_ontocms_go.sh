#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

usage() {
	cat <<'EOF'
Usage: ./bin/port_ontocms_go.sh <target-directory>

Copy the FDD core bundle plus the GoRefactor feature basis into the target
directory, and initialize document/spec/OntoCms_go as the active spec.
EOF
}

if [ "$#" -ne 1 ]; then
	usage >&2
	exit 1
fi

TARGET_ROOT=$1

if [ -e "$TARGET_ROOT" ] && [ ! -d "$TARGET_ROOT" ]; then
	echo "Target exists but is not a directory: $TARGET_ROOT" >&2
	exit 1
fi

mkdir -p "$TARGET_ROOT"

copy_file() {
	REL_PATH=$1
	SRC_PATH="$REPO_ROOT/$REL_PATH"
	DEST_PATH="$TARGET_ROOT/$REL_PATH"

	if [ ! -f "$SRC_PATH" ]; then
		echo "Missing source file: $REL_PATH" >&2
		exit 1
	fi

	if [ -e "$DEST_PATH" ]; then
		echo "Skipped existing $REL_PATH"
		return
	fi

	mkdir -p "$(dirname -- "$DEST_PATH")"
	cp "$SRC_PATH" "$DEST_PATH"
	echo "Copied $REL_PATH"
}

copy_as() {
	SRC_REL_PATH=$1
	DEST_REL_PATH=$2
	SRC_PATH="$REPO_ROOT/$SRC_REL_PATH"
	DEST_PATH="$TARGET_ROOT/$DEST_REL_PATH"

	if [ ! -f "$SRC_PATH" ]; then
		echo "Missing source file: $SRC_REL_PATH" >&2
		exit 1
	fi

	if [ -e "$DEST_PATH" ]; then
		echo "Skipped existing $DEST_REL_PATH"
		return
	fi

	mkdir -p "$(dirname -- "$DEST_PATH")"
	cp "$SRC_PATH" "$DEST_PATH"
	echo "Copied $SRC_REL_PATH -> $DEST_REL_PATH"
}

copy_dir() {
	REL_DIR=$1
	SRC_DIR="$REPO_ROOT/$REL_DIR"
	DEST_DIR="$TARGET_ROOT/$REL_DIR"

	if [ ! -d "$SRC_DIR" ]; then
		echo "Missing source directory: $REL_DIR" >&2
		exit 1
	fi

	if [ -e "$DEST_DIR" ]; then
		echo "Skipped existing $REL_DIR/"
		return
	fi

	mkdir -p "$(dirname -- "$DEST_DIR")"
	cp -R "$SRC_DIR" "$DEST_DIR"
	echo "Copied $REL_DIR/"
}

copy_dir_as() {
	SRC_REL_DIR=$1
	DEST_REL_DIR=$2
	SRC_DIR="$REPO_ROOT/$SRC_REL_DIR"
	DEST_DIR="$TARGET_ROOT/$DEST_REL_DIR"

	if [ ! -d "$SRC_DIR" ]; then
		echo "Missing source directory: $SRC_REL_DIR" >&2
		exit 1
	fi

	if [ -e "$DEST_DIR" ]; then
		echo "Skipped existing $DEST_REL_DIR/"
		return
	fi

	mkdir -p "$(dirname -- "$DEST_DIR")"
	cp -R "$SRC_DIR" "$DEST_DIR"
	echo "Copied $SRC_REL_DIR/ -> $DEST_REL_DIR/"
}

ensure_dir() {
	REL_DIR=$1
	DEST_DIR="$TARGET_ROOT/$REL_DIR"

	mkdir -p "$DEST_DIR"
	echo "Initialized $REL_DIR/"
}

FILES_TO_COPY='document/flow.md
document/flow.llm.md
document/glossary.md
document/spec/prompts.md
document/guides/index.md
document/guides/fdd_porting_guide.md
document/guides/overall.md
document/guides/data_modeling.md
document/guides/module_design.md
document/guides/feed_guide.md
document/guides/sd_conventions.md
document/guides/llm_dba_guide.md
document/guides/sa_requirement_breakdown.md
document/reference/Gene Panel.md
document/reference/ontocms_go_stack_directory_reference.md
.github/copilot-instructions.md
.github/prompts/fdd-focus.prompt.md
.github/prompts/fdd-sprint.prompt.md
.github/prompts/fdd-review.prompt.md
.github/prompts/fdd-refactor.prompt.md
.github/prompts/fdd-retrospective.prompt.md
.github/prompts/fdd-flow-llm-align.prompt.md'

BIN_FILES_TO_COPY='bin/build.sh
bin/up.sh
bin/down.sh
bin/clear.sh'

printf '%s
' "$FILES_TO_COPY" | while IFS= read -r REL_PATH; do
	[ -n "$REL_PATH" ] || continue
	copy_file "$REL_PATH"
done

printf '%s
' "$BIN_FILES_TO_COPY" | while IFS= read -r REL_PATH; do
	[ -n "$REL_PATH" ] || continue
	copy_file "$REL_PATH"
done

copy_dir "document/sql"
copy_dir_as "www/backend" "src/public/wwwroot/backend"
copy_dir_as "www/tmpls" "src/public/wwwroot/tmpls"

copy_as "document/spec/GoRefactor/idea.md" "document/spec/OntoCms_go/idea.md"
copy_as "document/spec/GoRefactor/plan.md" "document/spec/OntoCms_go/plan.md"

GO_SCAFFOLD_DIRS='conf/postgresql
src/public/wwwroot
src/conventions
src/app
src/infra
src/theme/default/layouts
src/theme/default/partials
src/theme/default/pages
src/theme/default/assets
src/tests/integration
src/tests/smoke
src/tests/fixtures'

printf '%s
' "$GO_SCAFFOLD_DIRS" | while IFS= read -r REL_DIR; do
	[ -n "$REL_DIR" ] || continue
	ensure_dir "$REL_DIR"
done

mkdir -p "$TARGET_ROOT/document/spec/OntoCms_go"

CURRENT_SPEC_PATH="$TARGET_ROOT/document/spec/.current-spec.md"
if [ ! -f "$CURRENT_SPEC_PATH" ]; then
	cat > "$CURRENT_SPEC_PATH" <<'EOF'
# FDD Current Spec

active_spec: OntoCms_go
spec_path: document/spec/OntoCms_go
history_path: document/spec/OntoCms_go/history.md
plan_path: document/spec/OntoCms_go/plan.md
check_path: document/spec/OntoCms_go/check.md
EOF
	echo "Initialized document/spec/.current-spec.md -> OntoCms_go"
else
	echo "Skipped existing document/spec/.current-spec.md"
fi

HISTORY_PATH="$TARGET_ROOT/document/spec/OntoCms_go/history.md"
if [ ! -f "$HISTORY_PATH" ]; then
	cat > "$HISTORY_PATH" <<'EOF'
# OntoCms_go History

## 2026-05-23

### Stage
- `plan`

### Summary
- `idea.md` 與 `plan.md` 已從原始 `GoRefactor` spec 搬入 `OntoCms_go`。
- 此版本已改為 Go 專屬初始化骨架，不再直接沿用 .NET spec，但後續仍需依新 repo 的實際 runtime 與目錄結構做 project-bound rewrite。
- 原始 spec 不含 `history.md` 與 `check.md`，因此本檔為新專案初始化的第一版 handoff。
- 目前尚未有 implementation 或 validation evidence，下一輪應先確認新 repo 的實際資料夾、驗證環境與 Go project-bound rewrite。

### Drift
- 原始文件仍帶有 F3CMS 與舊 repo 的命名、路徑與驗證假設，搬入新 repo 後應先做 project-bound rewrite。
- `check.md` 目前仍是 placeholder，不能拿來宣告任何驗收已完成。

### Next Step
- 在 `OntoCms_go` repo 內確認文件 root、validation path、DB source of truth、Go 專案結構與 build/run 方式後，再從 `plan` 階段正式承接下一輪重寫。
EOF
	echo "Initialized document/spec/OntoCms_go/history.md"
fi

CHECK_PATH="$TARGET_ROOT/document/spec/OntoCms_go/check.md"
if [ ! -f "$CHECK_PATH" ]; then
	cat > "$CHECK_PATH" <<'EOF'
# OntoCms_go Check

## Current Stage
- `plan`

## Check Basis
- 本檔為新專案初始化 placeholder。
- 在真正開始 implementation 之前，不應用此檔宣告任何驗收完成。

## Open Items
- [ ] 確認 `idea.md` 與 `plan.md` 中的專案名稱、路徑、驗證環境與 source-of-truth 規則已改寫為 `OntoCms_go`
- [ ] 依新 repo 的實際 Go runtime、toolchain 與目錄結構再做 project-bound rewrite
- [ ] 建立第一輪 implementation 後的正式 `check` 驗收項
EOF
	echo "Initialized document/spec/OntoCms_go/check.md"
fi

OPTIMIZATION_PATH="$TARGET_ROOT/document/spec/OntoCms_go/optimization.md"
if [ ! -f "$OPTIMIZATION_PATH" ]; then
	cat > "$OPTIMIZATION_PATH" <<'EOF'
# OntoCms_go Optimization
EOF
	echo "Initialized document/spec/OntoCms_go/optimization.md"
fi

BOOTSTRAP_HINT_PATH="$TARGET_ROOT/document/spec/OntoCms_go/bootstrap_hint.md"
if [ ! -f "$BOOTSTRAP_HINT_PATH" ]; then
	cat > "$BOOTSTRAP_HINT_PATH" <<'EOF'
# OntoCms_go Bootstrap Hint

## Initialized By Port Script
- `conf/postgresql/`
- `src/public/wwwroot/`
- `src/conventions/`
- `src/app/`
- `src/infra/`
- `src/theme/default/layouts/`
- `src/theme/default/partials/`
- `src/theme/default/pages/`
- `src/theme/default/assets/`
- `src/tests/integration/`
- `src/tests/smoke/`
- `src/tests/fixtures/`

## Immediate Follow-up
- Add Go module files such as `go.mod` and `go.sum`.
- Create `src/public/main.go`, `bootstrap.go`, `routes.go`, and `server.go`.
- Decide the actual PostgreSQL container config and place repo-specific files under `conf/postgresql/`.
- Start the first owner module under `src/app/` using the OntoCMS convention: `feed.go`, `reaction.go`, `outfit.go`, `kit.go`.
- Align the generated folders with the actual runtime, docker, and deployment plan of the new repo.
EOF
	echo "Initialized document/spec/OntoCms_go/bootstrap_hint.md"
fi

echo
echo "OntoCms_go bundle copied to: $TARGET_ROOT"
echo "Next steps:"
echo "1. Rewrite project-bound rules in copied guides, prompts, and .github/copilot-instructions.md."
echo "2. Rewrite copied bin/*.sh scripts so docker service names, env vars, and project name fit OntoCms_go."
echo "3. Verify src/public/wwwroot/backend and src/public/wwwroot/tmpls against the new repo's static file path and auth flow."
echo "4. Align idea.md and plan.md with the actual Go runtime, project layout, and validation path in the new repo."
echo "5. Fill in conf/postgresql/ and the generated src/ scaffold with repo-specific implementation files."
echo "6. Confirm the new repo's actual document root, validation environment, and DB source-of-truth."
echo "7. Continue FDD from document/spec/OntoCms_go/history.md after the Go rewrite baseline is established."