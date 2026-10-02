# unity-ai-instructions

여러 Unity 프로젝트(그리고 여러 PC/Mac)에서 공통으로 쓰는 AI 에이전트 작업 규칙/지침을 모아두는 **중앙 저장소**다. 개별 프로젝트에 흩어져 있던 `AGENTS.md`, `.unity-kb` 하네스 지침, 공유 패키지 시스템 배경 문서를 여기로 통합했다.

## 이 저장소가 유일한 원본이다

**규칙을 고칠 때는 이 저장소에서 고치고 push한다. 각 프로젝트에 있는 로컬 사본(`AGENTS.md`, `.unity-kb/`)을 직접 고치지 않는다.** 로컬 사본은 이 저장소의 복사본/체크아웃일 뿐이다.

머신이나 프로젝트가 바뀌어도 항상 다음 순서를 따른다:
1. 작업 시작 전: 이 저장소를 최신으로 pull한다.
2. 프로젝트의 `.unity-kb/`가 이 저장소의 git 체크아웃이면 그 폴더 안에서 `git pull`.
3. 프로젝트의 `AGENTS.md`/`CLAUDE.md`가 이 저장소의 `HARNESS.md`보다 오래됐으면 프로젝트 루트에서 `.unity-kb/sync.sh`(또는 `.unity-kb/sync.ps1`)를 실행해 갱신한다.
4. 규칙을 바꿔야 하면, 로컬 사본이 아니라 이 저장소를 고친 뒤 commit/push하고, 그다음에 각 프로젝트로 다시 동기화한다.

## 구조

```
unity-ai-instructions/
├── HARNESS.md                                   # 유일한 원본 지침 문서(§0~4, 항상 적용되는 행동 규칙만). 각 프로젝트에 AGENTS.md와 CLAUDE.md 두 파일명으로 동일하게 배포된다 — 원본과 배포 사본의 이름을 다르게 두어 혼동을 없앤다(이력 참고)
├── sync.sh / sync.ps1                           # 프로젝트 루트에서 실행하는 동기화 스크립트: .unity-kb pull → HARNESS.md를 AGENTS.md/CLAUDE.md로 복사 → agents-reference/ 복사
├── agents-reference/                            # HARNESS.md §5가 가리키는 도메인별 참고 문서. 해당 작업일 때만 로드하는 용도 — 항상 읽는 문서가 아니다
│   ├── 3d-asset-pipeline.md                     # 3D 모델 생성/배치 작업 절차
│   ├── shared-packages.md                       # 알려진 공유 UPM 패키지 목록/재사용 규칙
│   ├── unity-skills.md                          # Unity 공식 skills(vendor/) 사용법
│   ├── kb-management.md                         # .unity-kb 문서 관리 규칙
│   ├── ai-generation.md                         # AI 생성 서비스 호출 메커니즘
│   ├── animation-pose.md                        # 애니메이션(동작)·포즈(정지 자세) 생성 작업 절차
│   └── scene-save-modal.md                      # 씬 저장 상태·모달 대화상자 대응 절차(HARNESS §2.0.5 상세)
├── articles/
│   └── integrated-ai-harness-instructions.md    # (deprecated) 예전 하네스 문서 — 내용은 HARNESS.md에 흡수됨, 이력 참고용
├── packages/
│   └── ARCHITECTURE.md                          # 공유 UPM 패키지 시스템 배경 문서
└── vendor/
    └── unity-technologies-skills/               # Unity-Technologies/skills 저장소를 git subtree로 벤더링한 사본
        └── skills/<skill-name>/SKILL.md         # 각 스킬 (Claude Code Skill 포맷과 동일한 SKILL.md)
```

### 왜 `AGENTS.md`와 `CLAUDE.md` 두 파일로 배포하는가

프로젝트 루트에서 각 AI 코딩 툴은 자기가 아는 파일명만 자동으로 읽는다 — Claude Code는 `CLAUDE.md`, 그 외 다수의 에이전트(Cursor, Copilot, Codex CLI 등)는 관례적으로 `AGENTS.md`를 읽는다. 그래서 이 저장소는 지침을 **하나만** 관리하고(`HARNESS.md`), 프로젝트에 반영할 때 **같은 내용을 두 파일명으로 복사**해서 어느 툴을 쓰든 자동으로 규칙이 적용되게 한다. 심볼릭 링크로 파일 하나만 두는 방법도 가능하지만, Windows에서 심볼릭 링크는 권한/설정에 따라 깨지기 쉬워 그냥 내용이 같은 파일 두 개를 두는 쪽을 택했다.

## 이 저장소를 프로젝트에 반영하는 방법

**어떤 Unity 프로젝트든 다음 절차로 이 저장소의 규칙을 반영한다:**

```bash
# 프로젝트 루트에서 실행
# 1. .unity-kb를 이 저장소의 git 체크아웃으로 설정
git clone https://github.com/supervanz/unity-ai-instructions.git .unity-kb

# 2. sync 스크립트 실행 — HARNESS.md를 AGENTS.md/CLAUDE.md로 복사하고 agents-reference/도 함께 맞춘다
bash .unity-kb/sync.sh
# Windows PowerShell에서는:
# .unity-kb\sync.ps1
```

`sync.sh`/`sync.ps1`이 하는 일은 다음 3단계와 동일하다 — 스크립트 없이 손으로 할 수도 있다:

```bash
cp .unity-kb/HARNESS.md ./AGENTS.md
cp .unity-kb/HARNESS.md ./CLAUDE.md
cp -r .unity-kb/agents-reference ./agents-reference
```

이렇게 하면 프로젝트의 `.unity-kb` 폴더 자체가 이 저장소의 독립적인 git 체크아웃이 된다. 이후 규칙이 갱신되면 그 폴더 안에서 `git pull` 한 번으로 최신화되고, `sync.sh`/`sync.ps1`을 다시 실행하면 `AGENTS.md`/`CLAUDE.md`/`agents-reference/`가 맞춰진다. 손으로 `cp`하다 보면 어느 한쪽만 갱신하고 잊어버리는 표류가 생기기 쉬우므로, 스크립트 실행을 기본으로 한다.

새 시스템(공유 패키지 등)이 추가되면 `HARNESS.md`의 해당 표에 항목을 추가하고, 이 저장소에 commit/push한 뒤 각 프로젝트에 반영한다.

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
- §2.0의 CLI 강제 범위를 좁힘(v3). Unity CLI/Pipeline은 살아있는 Editor 프로세스의 상태를 읽거나 바꾸는 작업에만 강제하고, 디스크의 정적 파일만으로 답이 되는 조회(패키지 소스/README, 문서, git 이력, 설정 파일 내용)는 셸/파일 도구를 그대로 쓰도록 허용함. 모든 Unity 관련 조회를 CLI로 강제하던 이전 범위가 불필요하게 호출 횟수를 늘려 토큰을 소모시킨다는 점이 실측으로 확인됨.
- §5에 "전수 확인 원칙"을 추가(v4). 실제 사례에서 요청("스노우글로브 생성")이 §5 표의 두 행(3d-asset-pipeline, shared-packages)에 동시에 해당했으나, 첫 매칭(3d-asset-pipeline) 이후 나머지 행 확인 없이 진행하여 이미 등록된 공유 패키지(`com.custom.snowglobe`)를 두고 프리미티브로 새로 제작하는 결과가 발생함.
- AI 생성 서비스 실호출로 확인된 14건 중, 도메인과 무관하게 항상 적용되는 5건만 본문(§1.3, §2.0, §3.2)에 넣고 생성 고유 절차는 `agents-reference/ai-generation.md`로 분리(v5). 전부 본문에 넣으면 v2의 분리 취지를 되돌리는 분량이었음.
- §2.0에 호출 계층 함정 4건을 추가(v6) — 선행 슬래시 인자의 Git Bash 경로 변환, 인라인 `--code`의 따옴표 유실, `SessionState` 결과 절단, 버전별 API 오타 지점. 모두 실제 세션에서 시간을 소모한 지점이고 도메인과 무관하게 모든 Editor 작업에 적용되어 본문에 남김.
- §1.2에 "임의 재사용 금지"를, §5에 전수 확인 원칙의 "적용 범위"를 추가(v7). 실제 사례: 레퍼런스 사진 1장을 주며 신규 씬 제작을 요청했는데, 이름이 유사한 기존 씬을 찾아내 재활용을 제안함 — 비례·용도가 다른 별개 공간이라 사용자가 작업을 중단시킴. 원인은 v4의 전수 확인 원칙(공유 패키지 재사용 검토)을 씬·레이아웃에까지 확대 적용한 것이며, 적용 범위를 명시해 재발을 막음.
- 원본 파일명을 `AGENTS.md`에서 `HARNESS.md`로 개명(v8). 각 프로젝트 루트의 배포 사본(`AGENTS.md`/`CLAUDE.md`)과 이 저장소의 원본이 같은 이름 `AGENTS.md`를 쓰고 있어 편집 대상과 배포 사본을 혼동하기 쉬웠고, 실제로 한 프로젝트에서 배포 사본 두 파일(`AGENTS.md`/`CLAUDE.md`)이 서로 다른 버전으로 표류한 채 방치된 사례가 나왔다. 원본에는 이 저장소가 이미 쓰던 '하네스'라는 용어를 살려 `HARNESS.md`로 개명하고, 손으로 `cp`하다 생기는 표류를 줄이도록 `sync.sh`/`sync.ps1`을 추가했다.
- 프리미티브 구조물 + 생성 AI 인물 2체를 통합하는 실제 테스트(사막 바 씬)를 완주(v9). 메커닉 자체(접지 오차 0, 관통 0)는 검증됨. §2.0의 `GetInstanceID()` 서술을 대체 수단(`GetEntityId()` 파싱)으로 구체화. 생성 파이프라인 호출 규약 정정과 배치 절차 보강은 `ai-generation.md` v4·`3d-asset-pipeline.md` v5에 반영.
- `agents-reference/animation-pose.md` §2.5 추가(v2, HARNESS.md 버전 변경 없음). `durationInSeconds`를 지정하지 않으면 클립이 기본 10초로 생성되어 의도한 동작이 체감상 2배 느리게 재생되는 문제를 실측(5초로 지정 시 길이가 정확히 반영되고 seamless loop 일치도도 개선됨). 이 프로젝트의 기본값을 `durationInSeconds: 5`로 고정.
- `agents-reference/animation-pose.md`를 신설하고 §5 표에 등록(v11). T-Pose 캐릭터 생성 → `RigMesh` → `GenerateHumanoidAnimation` → Humanoid 리타겟 파이프라인을 실제로 완주한 시범(디저트 바 씬)에서, 정지 포즈(앉기) 생성 시 프롬프트에 "seamless loop"를 텍스트로 명시해야 시작-끝 포즈가 일치한다는 것을 실측함(JSON `loop:true` 파라미터만으로는 무릎 회전 차이 66.5°로 불일치, 프롬프트 텍스트에 명시하면 1.02°로 개선). 원거리 스크린샷만으로 포즈를 판정하다 오판한 사례, `RigMesh` 결과물의 `isHuman=True`가 본 매핑 해부학적 정확도를 보장하지 않는다는 실측, MCP 툴 이름 해시 접미사 함정도 함께 반영.
- §1.1을 단순화(v10) — 규모 기준(파일 3개 초과/API 시그니처 변경/신규 의존성 추가/아키텍처 변경)을 삭제하고 §1.3(재시도 한계·재시도 0회 예외)에 앵커링한 "규모와 무관하게 대체 경로 도입이 필요해진 시점" 하나로 좁힘 — 규모 기준으로는 작은 대체 경로가 상의 없이 진행되는 gap이 있었음. §2.5.1·§2.5.2에서 Custom Inspector 금지를 제거 — 씬 세부값 조정에 쓰이는 통상적 방법이라 MenuItem/EditorWindow의 지연실행·잔재누적 문제와 무관함. 또한 본문(§0~4)에 있던 버전별 변경 로그 문단(v2~v9)을 이 이력 절로 옮기고 `HARNESS.md` 본문에서 제거함 — 매 세션 항상 로드되는 문서에 누적 서술형 변경 로그를 두는 것 자체가 상시 토큰 비용이었음.
- §5의 "전수 확인 원칙"이라는 이름을 버리고 "행은 서로 배타적이지 않다"는 평서문으로 바꿈(v13). 규칙의 내용(첫 매칭에서 멈추지 말 것, 로드 조건 문구만으로 판정할 것, 애매하면 그때 문서를 열 것)은 그대로 유지. 이름이 규칙 범위보다 넓어서 v7 사고(전수 확인을 씬·레이아웃 재사용까지 확대 적용)를 유발했고, 그것을 막으려고 붙인 "적용 범위" 문단이 규칙 본문보다 길어져 있었음. 이름을 없애 과일반화 경로를 제거하고, 재사용 범위 규정은 이미 같은 내용을 더 자세히 담고 있는 §1.2로 위임해 §5에는 한 줄 포인터만 남김.
- `agents-reference/local-comfyui-stack.md` 추가(v13). 특정 PC(로컬 RTX 5090 + `H:/source/ComfyUI`)에만 있는 로컬 생성 스택 — Chroma 이미지 → TRELLIS2 메시 → MIA 리깅 → HY-Motion 모션 → Unity 프리팹·컨트롤러·씬까지 한 명령으로 도는 파이프라인 — 을 클라우드 생성 경로(`ai-generation.md`)의 대안으로 등재. 로드 조건을 **① 사용자가 "로컬"·"ComfyUI"를 명시했고 ② `H:/source/ComfyUI/CLAUDE.md` 파일이 존재하는 PC일 것** 두 조건의 AND로 걸었다. §5 판정은 문서 본문을 열지 않고 조건 문구만으로 해야 하므로, 경로 판정 기준을 호스트명이나 GPU가 아니라 파일 존재 여부로 삼았다. **자동 라우팅은 두지 않았다** — 작업 성격만 보고 로컬로 넘기면 §1.2(임의 대체 금지)와 같은 문제가 되고, 반대로 키워드를 잊었을 때 크레딧이 나가는 쪽은 사용자가 감수하기로 함. 대신 로컬로 갈 때는 착수 전 한 줄 고지(승인 아님)를, 로컬이 유리한데 지정이 없을 때는 보고에 대안 한 줄 언급을 의무화했다. `ai-generation.md` 행에는 "에셋 생성의 기본 경로"임과 제외 조건을 명시해 두 행이 동시에 매칭되는 것을 막았다. 문서 본문은 진입점 역할만 하고 명령 인자·실측 수치·실패 기록은 스택 리포(`H:/source/ComfyUI/CLAUDE.md` 및 `docs/`)를 원본으로 참조하게 해서 두 개의 원본이 생기지 않게 함. 배치·검증 규약은 `3d-asset-pipeline.md`·`animation-pose.md`가 계속 상위임을 명시.
- §2.0.5 "씬 저장 상태와 모달 대화상자"를 신설하고 상세를 `agents-reference/scene-save-modal.md`로 분리(v16). 한 프로젝트(`D:\UnityProject\MechShooter`)에서 여러 에이전트 세션이 Editor 하나를 공유하며 생긴 문제가 계기였다. 테스트 실행 중 "Scene(s) Have Been Modified" 저장 확인창이 메인 스레드를 점유해 live 명령이 타임아웃되고, 출처를 알 수 없는 dirty 변경이 반복됐다. 모달을 닫는 요령보다 모달이 생기는 작업 순서를 없애는 쪽을 우선했다. 미저장 변경 보존, 코드→반영→ready→씬 순서, `save_all`·"Don't Save"·포커스+Enter 방식 금지, 자동 Save의 6개 조건을 정리했다. 본문에 전부 두면 매 세션 약 4,300자가 늘어나므로, 항상 지켜야 할 4줄만 본문에 두고 나머지는 해당 작업일 때만 읽게 했다. 예상하지 못한 모달처럼 미리 읽을 틈이 없는 상황 때문에 요약 4줄은 본문에 남겼다.
- §2.7 "컨텍스트 및 도구 사용 효율"과 §2.8 "다중 에이전트 작업 공유"를 신설(v17). 둘 다 같은 프로젝트(`D:\UnityProject\MechShooter`)에서 로컬 실험으로 시험한 절을 일반화해 올린 것이다. 로컬로 두면 `sync.ps1`이 덮어써서 사라지는 문제도 있었다.
  - §2.7: 측정해 보니 `unity command` 전체 목록(약 2.6만 자)이 매 Editor 작업마다 지침 본문보다 큰 출력을 만들고 있었다. 이름만 보면 약 2,700자, 상세는 `--query <이름>`으로 보면 약 1천 자다. §2.0.2에 "출력 범위는 §2.7" 포인터를 달았다.
  - §2.8: Claude Code와 Cline(GPT-6) 두 에이전트가 3주간 한 프로젝트에 투입됐는데, 한쪽만 아는 결정(구매 에셋 커밋 금지, 이동 사양 개편, 폴더 이전 등)이 생기고 상대의 미커밋 변경이 내 커밋에 섞였다. 그래서 공유 인계 문서(기본 `Docs/AgentHandoff.md`)의 시작·종료 시 읽기·기록 규칙을 두었다. 인계 문서의 형식·크기 제한은 프로젝트 문서가 정하도록 지침에는 넣지 않았다.
