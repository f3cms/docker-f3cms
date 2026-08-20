#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

usage() {
	cat <<'EOF'
Usage: ./bin/port_ontocms_net.sh <target-directory>

Copy the FDD core bundle plus the NetRefactor feature basis into the target
directory, and initialize document/spec/OntoCms_net as the active spec.
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

copy_as "document/spec/NetRefactor/idea.md" "document/spec/OntoCms_net/idea.md"
copy_as "document/spec/NetRefactor/plan.md" "document/spec/OntoCms_net/plan.md"

mkdir -p "$TARGET_ROOT/document/spec/OntoCms_net"

CURRENT_SPEC_PATH="$TARGET_ROOT/document/spec/.current-spec.md"
if [ ! -f "$CURRENT_SPEC_PATH" ]; then
	cat > "$CURRENT_SPEC_PATH" <<'EOF'
# FDD Current Spec

active_spec: OntoCms_net
spec_path: document/spec/OntoCms_net
history_path: document/spec/OntoCms_net/history.md
plan_path: document/spec/OntoCms_net/plan.md
check_path: document/spec/OntoCms_net/check.md
EOF
	echo "Initialized document/spec/.current-spec.md -> OntoCms_net"
else
	echo "Skipped existing document/spec/.current-spec.md"
fi

HISTORY_PATH="$TARGET_ROOT/document/spec/OntoCms_net/history.md"
if [ ! -f "$HISTORY_PATH" ]; then
	cat > "$HISTORY_PATH" <<'EOF'
# OntoCms_net History

## 2026-05-23

### Stage
- `plan`

### Summary
- `idea.md` 與 `plan.md` 已從原始 `NetRefactor` spec 搬入 `OntoCms_net`。
- 原始 spec 不含 `history.md` 與 `check.md`，因此本檔為新專案初始化的第一版 handoff。
- 目前尚未有 implementation 或 validation evidence，下一輪應先確認新 repo 的實際資料夾、驗證環境與 project-bound rewrite。

### Drift
- 原始文件仍帶有 F3CMS 與舊 repo 的命名、路徑與驗證假設，搬入新 repo 後應先做 project-bound rewrite。
- `check.md` 目前仍是 placeholder，不能拿來宣告任何驗收已完成。

### Next Step
- 在 `OntoCms_net` repo 內確認文件 root、validation path、DB source of truth 與 .NET 專案結構後，再從 `plan` 階段正式承接 Stage 0。
EOF
	echo "Initialized document/spec/OntoCms_net/history.md"
fi

CHECK_PATH="$TARGET_ROOT/document/spec/OntoCms_net/check.md"
if [ ! -f "$CHECK_PATH" ]; then
	cat > "$CHECK_PATH" <<'EOF'
# OntoCms_net Check

## Current Stage
- `plan`

## Check Basis
- 本檔為新專案初始化 placeholder。
- 在真正開始 implementation 之前，不應用此檔宣告任何驗收完成。

## Open Items
- [ ] 確認 `idea.md` 與 `plan.md` 中的專案名稱、路徑、驗證環境與 source-of-truth 規則已改寫為 `OntoCms_net`
- [ ] 建立第一輪 implementation 後的正式 `check` 驗收項
EOF
	echo "Initialized document/spec/OntoCms_net/check.md"
fi

OPTIMIZATION_PATH="$TARGET_ROOT/document/spec/OntoCms_net/optimization.md"
if [ ! -f "$OPTIMIZATION_PATH" ]; then
	cat > "$OPTIMIZATION_PATH" <<'EOF'
# OntoCms_net Optimization
EOF
	echo "Initialized document/spec/OntoCms_net/optimization.md"
fi

echo
echo "OntoCms_net bundle copied to: $TARGET_ROOT"
echo "Next steps:"
echo "1. Rewrite project-bound rules in copied guides, prompts, and .github/copilot-instructions.md."
echo "2. Rewrite copied bin/*.sh scripts so docker service names, env vars, and project name fit OntoCms_net."
echo "3. Verify src/public/wwwroot/backend and src/public/wwwroot/tmpls against the new repo's static file path and auth flow."
echo "4. Confirm the new repo's actual document root, validation environment, and DB source-of-truth."
echo "5. Continue FDD from document/spec/OntoCms_net/history.md and Stage 0 of plan.md."