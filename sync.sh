#!/usr/bin/env bash
# unity-ai-instructions 동기화 스크립트.
# 프로젝트 루트에서 실행한다 (예: bash .unity-kb/sync.sh).
# .unity-kb를 최신으로 pull한 뒤, 원본 HARNESS.md를 프로젝트 루트에
# AGENTS.md / CLAUDE.md 두 파일명으로 복사하고, agents-reference/도 맞춘다.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
KB_DIR="$(pwd)"
ROOT_DIR="$(dirname "$KB_DIR")"

if [ ! -f "$KB_DIR/HARNESS.md" ]; then
  echo "오류: $KB_DIR/HARNESS.md 를 찾을 수 없다. .unity-kb가 unity-ai-instructions 저장소의 체크아웃인지 확인." >&2
  exit 1
fi

echo "1. .unity-kb pull"
git -C "$KB_DIR" pull --ff-only

echo "2. HARNESS.md -> AGENTS.md / CLAUDE.md"
cp "$KB_DIR/HARNESS.md" "$ROOT_DIR/AGENTS.md"
cp "$KB_DIR/HARNESS.md" "$ROOT_DIR/CLAUDE.md"

echo "3. agents-reference/ 동기화"
rm -rf "$ROOT_DIR/agents-reference"
cp -r "$KB_DIR/agents-reference" "$ROOT_DIR/agents-reference"

echo "완료. 프로젝트 루트의 AGENTS.md / CLAUDE.md / agents-reference/ 가 $KB_DIR/HARNESS.md 기준으로 갱신됨."
