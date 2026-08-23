---
id: unity-ai-agent-instructions-unity-skills
title: Unity 공식 AI skills
version: 3
parent: 상위 지침 문서 (6의 분리본)
---

# Unity 공식 AI skills

**로드 조건**: 패키지 관리, UI(UGUI/UITK/IMGUI), 빌드/배포, IAP, LevelPlay 연동, 신규 프로젝트 초기화 등 Unity 공식 skill이 다루는 영역의 작업을 시작할 때만 이 문서를 읽는다.

이 문서는 상위 지침 문서(프로젝트 루트: `AGENTS.md`/`CLAUDE.md`, .unity-kb 원본: `HARNESS.md`) §1~4의 행동 규칙 아래에서 적용되는 도메인 절차다. 충돌 시 그 문서(§0~4)가 우선한다.

`Unity-Technologies/skills`(Unity 공식 Claude Code Skill 모음)를 이 저장소의 `vendor/unity-technologies-skills/skills/`에 벤더링해 두었다. 프로젝트의 `.claude/skills/`에 필요한 스킬 폴더가 설치되어 있으면 `/스킬이름`으로 직접 호출한다(예: `unity-package-management`, `unity-cli`, `new-unity-project`, `ui`, `ui-uitk`, `ui-ugui`, `ui-imgui`, `build-live-game`, `implement-in-app-purchases`, `levelplay-unity-integration`). 설치/갱신 절차는 이 저장소의 `README.md` 참고.

## 벤더 스냅샷에 없는 스킬 자동 설치

벤더 스냅샷은 저장소 관리자가 주기적으로만 `git subtree pull`로 갱신하므로, `Unity-Technologies/skills`에 최근 추가된 스킬(예: `urp-postprocessing`, `shader-graph-create-custom-node`, `setup-multiplayer-services`, `localization`, `optimize-audio`, `optimize-text-mesh-pro`, `optimize-web`, `physics-3d-collision`, `initialize-ai-navigation`, `sprite-editor`, `setup-vivox-voice-chat` 등)가 몇 세대씩 누락될 수 있다.

필요한 스킬이 `.claude/skills/<name>/`에도, 이 저장소의 `vendor/unity-technologies-skills/skills/<name>/`에도 없으면, HARNESS.md §5 예외 조항에 따라 §1.1/1.4 승인 게이트 없이 GitHub에서 그 스킬 폴더만 받아 즉시 설치한다:

```bash
# 프로젝트 루트에서 (설치 전 .claude/skills/<name>이 이미 있는지 먼저 확인 — 중복 설치 방지)
tmp=$(mktemp -d)
git clone --depth 1 --filter=blob:none --sparse https://github.com/Unity-Technologies/skills.git "$tmp"
git -C "$tmp" sparse-checkout set "skills/<skill-name>"
mkdir -p .claude/skills
cp -r "$tmp/skills/<skill-name>" .claude/skills/
rm -rf "$tmp"
```

- 이 절차는 이 저장소(`unity-ai-instructions`)의 벤더 스냅샷(`vendor/unity-technologies-skills/`)을 갱신하지 않는다 — 그건 여전히 저장소 관리자만 `git subtree pull`로 한다(`README.md` 참고). 여기서는 개별 프로젝트가 필요한 스킬 하나를 직접, 즉시 받아 쓰는 별도 경로다.
- 설치 후 `/스킬이름`으로 호출해 실제로 트리거되는지 확인한다.
- 스킬 폴더 안의 지침·코드는 외부 저장소 콘텐츠이므로, 프로젝트 고유의 비공개 정보(내부 URL·자격증명 등)를 그 위에 덧쓰지 않는다.
- **Why**: 하네스·스킬셋을 시스템화하는 현재 단계에서는 최신 스킬을 즉시 활용하는 이득이 승인 대기 비용보다 크다고 판단해 예외를 둠. 실 프로덕션 프로젝트에 투입하기 전 이 예외 자체를 재검토해야 한다(예: 승인 게이트 재적용, 또는 벤더 스냅샷 갱신 주기 단축으로 대체).

### 실측: 설치 후 트리거 반영 시점

`.claude/skills/<name>/`에 새로 설치한 스킬은 **설치 직후 같은 턴에서는 호출되지 않는다.** 설치 직후 `Skill` 도구로 그 스킬을 직접 호출하면 `Unknown skill` 에러가 나고, 스킬 목록 조회 도구도 빈 결과를 반환한다(`urp-postprocessing` 설치 직후 실측).

다만 **완전히 새 세션을 열어야 하는 것도 아니다.** 같은 세션에서 몇 턴이 지난 뒤 다시 확인하니 `urp-postprocessing`이 스킬 목록에 나타났고 정상 트리거됐다(같은 세션, 새 세션 둘 다에서 트리거 성공 실측함). 즉 스킬 디렉터리 재스캔은 파일 쓰기 직후 즉시가 아니라 **약간의 지연을 두고** 일어나는 것으로 보이며, 정확한 트리거 조건(경과 시간 기준인지 턴 수 기준인지)은 아직 특정하지 못했다.

**How to apply**: 스킬을 새로 설치한 바로 그 턴에 곧바로 호출해서 실패하더라도 그 스킬이 없다고 단정하지 않는다. 몇 턴 뒤 다시 시도하거나, 급하면 새 세션을 열어 확인한다. 설치 직후 1회 호출 실패만으로 "이 스킬은 못 쓴다"고 사용자에게 보고하지 않는다.
