---
id: unity-ai-agent-instructions-kb-management
title: 문서 관리 (Knowledge Base Registration)
version: 1
parent: AGENTS.md (7의 분리본)
---

# 문서 관리 (Knowledge Base Registration)

**로드 조건**: `.unity-kb/`에 새 문서를 추가하거나 기존 KB 문서를 수정/삭제하는 작업일 때만 이 문서를 읽는다.

이 문서는 [AGENTS.md](../AGENTS.md) §1~4의 행동 규칙 아래에서 적용되는 도메인 절차다. 충돌 시 AGENTS.md가 우선한다.

## 포맷 및 위치
- 포맷: .md
- 위치:
  - 개인용: `.unity-kb/articles/private/`
  - 프로젝트 공유용: `.unity-kb/articles/projects/<project_id>/`
  - 조직 공유용: `.unity-kb/articles/orgs/<org_id>/`

## YAML Front-matter
- 모든 문서 상단에 id, title, version 포함.

## 색인 등록
- 해당 Scope 루트의 index.md에 상대 경로, 제목, 한 줄 설명 추가.

## 관리 주체
- KB 문서(AGENTS.md, 하네스 문서, 패키지/skills 목록 등) 추가/수정/삭제는 사용자가 직접 수행하거나 승인한 것만 반영한다. AI는 [shared-packages.md](shared-packages.md)의 규칙(사용자 승인을 받은 패키지 등록)처럼 명시적으로 허용된 범위 밖에서는 KB 문서를 임의로 고치지 않는다.
