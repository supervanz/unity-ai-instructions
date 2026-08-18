---
id: unity-ai-agent-instructions-unity-skills
title: Unity 공식 AI skills
version: 1
parent: 상위 지침 문서 (6의 분리본)
---

# Unity 공식 AI skills

**로드 조건**: 패키지 관리, UI(UGUI/UITK/IMGUI), 빌드/배포, IAP, LevelPlay 연동, 신규 프로젝트 초기화 등 Unity 공식 skill이 다루는 영역의 작업을 시작할 때만 이 문서를 읽는다.

이 문서는 상위 지침 문서(프로젝트 루트: `AGENTS.md`/`CLAUDE.md`, .unity-kb 원본: `HARNESS.md`) §1~4의 행동 규칙 아래에서 적용되는 도메인 절차다. 충돌 시 그 문서(§0~4)가 우선한다.

`Unity-Technologies/skills`(Unity 공식 Claude Code Skill 모음)를 이 저장소의 `vendor/unity-technologies-skills/skills/`에 벤더링해 두었다. 프로젝트의 `.claude/skills/`에 필요한 스킬 폴더가 설치되어 있으면 `/스킬이름`으로 직접 호출한다(예: `unity-package-management`, `unity-cli`, `new-unity-project`, `ui`, `ui-uitk`, `ui-ugui`, `ui-imgui`, `build-live-game`, `implement-in-app-purchases`, `levelplay-unity-integration`). 설치/갱신 절차는 이 저장소의 `README.md` 참고.
