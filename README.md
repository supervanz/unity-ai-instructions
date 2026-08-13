# unity-ai-instructions

여러 Unity 프로젝트(그리고 여러 PC/Mac)에서 공통으로 쓰는 AI 에이전트 작업 규칙/지침을 모아두는 **중앙 저장소**다. 개별 프로젝트에 흩어져 있던 `AGENTS.md`, `.unity-kb` 하네스 지침, 공유 패키지 시스템 배경 문서를 여기로 통합했다.

## 이 저장소가 유일한 원본이다

**규칙을 고칠 때는 이 저장소에서 고치고 push한다. 각 프로젝트에 있는 로컬 사본(`AGENTS.md`, `.unity-kb/`)을 직접 고치지 않는다.** 로컬 사본은 이 저장소의 복사본/체크아웃일 뿐이다.

머신이나 프로젝트가 바뀌어도 항상 다음 순서를 따른다:
1. 작업 시작 전: 이 저장소를 최신으로 pull한다.
2. 프로젝트의 `.unity-kb/`가 이 저장소의 git 체크아웃이면 그 폴더 안에서 `git pull`.
3. 프로젝트의 `AGENTS.md`가 이 저장소의 `AGENTS.md`보다 오래됐으면 덮어써서 갱신한다.
4. 규칙을 바꿔야 하면, 로컬 사본이 아니라 이 저장소를 고친 뒤 commit/push하고, 그다음에 각 프로젝트로 다시 동기화한다.

## 구조

```
unity-ai-instructions/
├── AGENTS.md                                    # 유일한 원본 지침 문서(§0~4, 항상 적용되는 행동 규칙만). 각 프로젝트에 AGENTS.md와 CLAUDE.md 두 파일명으로 동일하게 배포된다
├── agents-reference/                            # AGENTS.md §5가 가리키는 도메인별 참고 문서. 해당 작업일 때만 로드하는 용도 — 항상 읽는 문서가 아니다
│   ├── 3d-asset-pipeline.md                     # 3D 모델 생성/배치 작업 절차
│   ├── shared-packages.md                       # 알려진 공유 UPM 패키지 목록/재사용 규칙
│   ├── unity-skills.md                          # Unity 공식 skills(vendor/) 사용법
│   └── kb-management.md                         # .unity-kb 문서 관리 규칙
├── articles/
│   └── integrated-ai-harness-instructions.md    # (deprecated) 예전 하네스 문서 — 내용은 AGENTS.md에 흡수됨, 이력 참고용
├── packages/
│   └── ARCHITECTURE.md                          # 공유 UPM 패키지 시스템 배경 문서
└── vendor/
    └── unity-technologies-skills/               # Unity-Technologies/skills 저장소를 git subtree로 벤더링한 사본
        └── skills/<skill-name>/SKILL.md         # 각 스킬 (Claude Code Skill 포맷과 동일한 SKILL.md)
```

### 왜 `AGENTS.md`와 `CLAUDE.md` 두 파일로 배포하는가

프로젝트 루트에서 각 AI 코딩 툴은 자기가 아는 파일명만 자동으로 읽는다 — Claude Code는 `CLAUDE.md`, 그 외 다수의 에이전트(Cursor, Copilot, Codex CLI 등)는 관례적으로 `AGENTS.md`를 읽는다. 그래서 이 저장소는 지침을 **하나만** 관리하고(`AGENTS.md`), 프로젝트에 반영할 때 **같은 내용을 두 파일명으로 복사**해서 어느 툴을 쓰든 자동으로 규칙이 적용되게 한다. 심볼릭 링크로 파일 하나만 두는 방법도 가능하지만, Windows에서 심볼릭 링크는 권한/설정에 따라 깨지기 쉬워 그냥 내용이 같은 파일 두 개를 두는 쪽을 택했다.

## 이 저장소를 프로젝트에 반영하는 방법

**어떤 Unity 프로젝트든 다음 절차로 이 저장소의 규칙을 반영한다:**

```bash
# 프로젝트 루트에서 실행
# 1. .unity-kb를 이 저장소의 git 체크아웃으로 설정
git clone https://github.com/supervanz/unity-ai-instructions.git .unity-kb

# 2. AGENTS.md를 프로젝트 루트에 AGENTS.md와 CLAUDE.md 두 파일명으로 복사
cp .unity-kb/AGENTS.md ./AGENTS.md
cp .unity-kb/AGENTS.md ./CLAUDE.md

# 3. AGENTS.md §5가 가리키는 참고 문서도 함께 복사 (없으면 §5의 링크가 깨짐)
cp -r .unity-kb/agents-reference ./agents-reference
```

이렇게 하면 프로젝트의 `.unity-kb` 폴더 자체가 이 저장소의 독립적인 git 체크아웃이 된다. 이후 규칙이 갱신되면 그 폴더 안에서 `git pull` 한 번으로 최신화되고, `AGENTS.md`/`CLAUDE.md`/`agents-reference/`는 필요할 때 다시 복사해서 맞추면 된다.

새 시스템(공유 패키지 등)이 추가되면 `AGENTS.md`의 해당 표에 항목을 추가하고, 이 저장소에 commit/push한 뒤 각 프로젝트에 반영한다.

## Unity 공식 AI skills (`Unity-Technologies/skills` 벤더링)

`https://github.com/Unity-Technologies/skills` — Unity가 공식 배포하는 Claude Code 호환 Skill(`SKILL.md`) 모음. `unity-package-management`, `unity-cli`, `new-unity-project`, `ui`/`ui-uitk`/`ui-ugui`/`ui-imgui`, `build-live-game`, `implement-in-app-purchases`, `levelplay-unity-integration` 등 10개 스킬을 포함한다.

이 저장소의 원본 대신 **git subtree**로 `vendor/unity-technologies-skills/`에 통째로 들여왔다(참고 문서가 아니라 실제로 프로젝트에 설치해서 `/스킬이름`으로 바로 호출하는 실행 가능한 Skill로 쓰기 위함).

**프로젝트에 설치하는 방법** (원하는 스킬만 골라서 프로젝트의 `.claude/skills/`로 복사):

```bash
# 프로젝트 루트에서, .unity-kb가 이미 이 저장소의 체크아웃이라고 가정
mkdir -p .claude/skills
cp -r .unity-kb/vendor/unity-technologies-skills/skills/unity-package-management .claude/skills/
cp -r .unity-kb/vendor/unity-technologies-skills/skills/unity-cli .claude/skills/
# 필요한 스킬 폴더만 반복해서 복사, 또는 skills/ 전체를 통째로 복사
```

**원본이 업데이트됐을 때 반영하는 방법** (이 저장소를 고치는 사람만 실행):

```bash
git subtree pull --prefix=vendor/unity-technologies-skills https://github.com/Unity-Technologies/skills.git main --squash
git push origin master
```

그 뒤 각 프로젝트는 `.claude/skills/`에 복사해둔 스킬 폴더를 다시 덮어써서 최신화한다.

## 이력

- 초기 통합: 여러 프로젝트에 개별적으로 존재하던 `AGENTS.md`/`.unity-kb` 지침을 이 저장소로 통합. 이전에 `.unity-kb/.kb-sync`를 관리하던 외부 동기화 도구는 더 이상 쓰이지 않는 것으로 확인되어 git으로 완전히 대체.
- `Unity-Technologies/skills`를 `vendor/unity-technologies-skills/`에 git subtree로 벤더링. 공유 UPM 패키지 시스템(런타임 코드/에셋 재사용)과는 별개로, "AI 에이전트의 작업 절차/워크플로 재사용"을 위한 시스템.
- `AGENTS.md`와 `.unity-kb/articles/integrated-ai-harness-instructions.md`(하네스 문서)가 별도 파일로 나뉘어 있어, Claude Code가 자동으로 읽는 `CLAUDE.md`에는 이 지침들이 전혀 반영되지 않는 문제가 발견됨(한 프로젝트에서 `CLAUDE.md`가 이 시스템과 무관하게 별도로 존재 — 출처 불명, 내용 폐기). 두 문서를 `AGENTS.md` 하나로 완전히 병합하고(하네스 문서는 deprecated 표시 후 이력 참고용으로만 보존), 프로젝트에 반영할 때 `AGENTS.md`와 `CLAUDE.md` 두 파일명으로 동일하게 복사하도록 절차를 바꿔서 재발을 방지함.
- `AGENTS.md`(v1)가 195줄까지 길어져, 단순 작업에서도 매 턴 §2.4(3D 에셋 생성)·§5(공유 패키지)·§6(Unity skills)·§7(KB 관리) 전체가 컨텍스트에 얹혀 토큰을 불필요하게 소모하는 문제가 한 프로젝트(`D:\UnityProject\My project`)에서 실측 확인됨(패키지 컴포넌트 하나 붙이는 세션에서, AGENTS.md 전체를 1회 읽은 것이 대화 전체 비용 중 상위 1위 항목으로 남음). §0~4(모든 작업에 항상 적용되는 행동 규칙)만 `AGENTS.md`에 남기고, §2.4·§5·§6·§7은 `agents-reference/`의 개별 파일로 분리(v2). 각 참고 문서 상단에 로드 조건을 명시하고, `AGENTS.md` §5에 표로만 인덱싱해서 해당 작업일 때만 그 문서를 읽도록 함.
